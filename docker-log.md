# Docker log 的最佳实践

日志分为引擎日志(即dockerd运行时日志)和容器的日志。

## 引擎日志

引擎日志一般交给了Upstart(Ubuntu 14.04)或者systemd(CentOS7,Ubuntu16.04). 
前者一般位于/var/log/upstart/docker.log，后者我们一般使用journalctl -u docker
来进行查看。

例如：

Debian 10系统(buster)中

```sh
journalctl -u docker.service
# 也可以使用
journalctl -u docker
```


## 容器日志

docker logs CONTAINER顯示當前運行的容器的日志信息，UNIX和Linux的命令有三種輸入輸出，
分別是STDIN(標準輸入)、STDOUT(標準輸出)、STDERR(標準錯誤輸出)，docker logs顯示的內
容包含STOUT和STDERR。在生產環境，我們的應用一般會寫入我們的日志文件裏，所以我們在使用
docker logs 一般收集不到太多重要的日志信息。

只有使用了'local','json-file','journaId'的日志驅動的容器才可以使用docker logs捕獲
日志，使用其它日志驅動無法使用‘docker logs’

當日志量比較大時，使用docker logs 查看日志，會對docker daemon造成比較大的壓力，容器
導致容器創建慢等一系統問題。


## 不同应用的实例分析

Nginx 官方鏡像，使用了一種方式，讓日志輸出到STDOUT, 也就是創建一個符號鏈接
/var/log/nginx/access.log 到/dev/stdout，在其Dockerfile中我們可以看到

```dockerfile
  RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
```

Httpd 使用的是讓其輸出到指定的文件，正常日志輸出到/proc/self/fd/1 (STDOUT),
錯誤日志輸出到/proc/self/fd/2


## 日志驅動 

Docker 提供了兩種模式用於將消息從容器到日志驅動 

1. (默認)拒絕，阻塞從容器到容器驅動
2. 非阻塞傳遞，將日志存儲在容器的緩衝區

當緩衝區満，舊的日志將被丟棄。


在mode日志選項控制使用blocking或者non-blocking,當設置爲non-blocking時，需要設置
max-buffer-size參數(默認爲1M)。

### 日志存儲分類

1. Docker-CE版本，docker logs命令僅僅適用於如下驅動程序:

> local             日志以自定义格式存储，旨在实现最小开销。
> json-file         日志格式为JSON。Docker的默认日志记录驱动程序。
> journald          将日志消息写入journald。该journald守护程序必须在主机上运行。

2. 當前使用的是哪種驅動可以使用如下查詢

```sh
 docker info | grep 'Logging Driver'
 # 或者使用
 docker info --format '{{.LoggingDriver}}'

```

3. 查看單個容器的日志驅動

```sh
  docker inspect -f '{{.HostConfig.LogConfig.Type}}' containerID
```

4. 修改日志驅動(對所有容器設置)

修改/etc/docker/daemon.json文件即可。

```json
{
    "log-driver":"syslog"
}
```

5. 對單個容器設置

在運行容器時指定日志驅動 --log-driver

```sh
# 指定日志驅動爲none
docker run -itd --log-driver none alipine ash
```


#### 日志驅動之local

local日志驅動記錄從容器的STDOUT/STDERR的輸出，並寫到宿主機的磁盤。
默認情況下，local日志驅動爲每一個容器保留100MB的日志信息(未壓縮)，並啓用自
動壓縮來保存。

local日志驅動的儲存位置/var/lib/docker/containers/容器id/local-logs/container.log

local日志驅動的三個選項：
> max-size      --log-opt max-size=10m          切分日志的最大大小，默認20M，單位爲(k,m,g)

> max-file      --log-opt max-file=3            保存的日志文件最大數，超過後刪除舊文件

> compress      --log-opt compress=false        是否啓用壓縮，默認true

可以看出這是一個滾動日志，如果單個設置過大，會出問題，比如設置最大max-size爲90M, 那麼下次滾動就會
刪除掉這個，最終你只可以看到最後10M的日志。

全局設定需修改/etc/docker/daemon.json

```json

{
    "log-driver":"local",
    "log_opts":{
        "max-size":"10m"
    }
}
```

對指定的container設置

```sh
# 設置local驅動
docker run -itd --log-driver local alpine ping www.baidu.com

3795b6483534961c1d5223359ad1106433ce2bf25e18b981a47a2d79ad7a3156
```

查看運行的容器的日志驅動

```sh
docker inspect -f '{{.HostConfig.LogConfig.Type}}'
```

查看日志的輸出

```sh
tail -f /var/lib/docker/container/3795b64XXXX/local-logs/container.log
```

#### 日志驅動之Journald

journald日志驱动程序将容器的日志发送到 systemd journal, 可以使用 journal API或者使用 docker logs来查日志。

除了日志本身以外， journald日志驱动还会在日志加上下面的数据与消息一起储存。

Field	| Deion
-|-
CONTAINER_ID|	容器ID,为 12个字符
CONTAINER_ID_FULL|	完整的容器ID，为64个字符
CONTAINER_NAME|	启动时容器的名称，如果容器后面更改了名称，日志中的名称不会更改。
CONTAINER_TAG, SYSLOG_IDENTIFIER|	容器的tag.
CONTAINER_PARTIAL_MESSAGE|	当日志比较长的时候使用标记来表示(显示日志的大小)
选项

选项 |	是否必须 |	描述
-|-|-
tag|	可选的|	指定要在日志中设置CONTAINER_TAG和SYSLOG_IDENTIFIER值的模板。
labels|	可选的|	以逗号分隔的标签列表，如果为容器指定了这些标签，则应包含在消息中。
env|	可选的|	如果为容器指定了这些变量，则以逗号分隔的环境变量键列表（应包含在消息中）。
env-regex|	可选的|	与env类似并兼容。用于匹配与日志记录相关的环境变量的正则表达式 。


##### journald 日志驱动全局配置

编辑 /etc/docker/daemon.json文件

{
"log-driver": "journald"
}

单个容器日志驱动设置为—journald

```sh
  docker run -d -it --log-driver=journald
  --log-opt labels=location
  --log-opt env=TEST
  --env "TEST=false"
  --label location=china
  --name nginx-journald
  -p 80:80
  nginx
```


查看日志 journalctl

```sh
# 只查询指定容器的相关消息
journalctl CONTAINER_NAME=webserver
# -b 指定从上次启动以来的所有消息
journalctl -b CONTAINER_NAME=webserver
# -o 指定日志消息格式，-o json 表示以json 格式返回日志消息
journalctl -o json CONTAINER_NAME=webserver
# -f 一直捕获日志输出
journalctl -f CONTAINER_NAME=webserver
```

如果我们的容器在启动的时候加了 -t 参数，启用了 TTY 的话，那么我查看日志是会像下面一样:

May 17 17:19:26 localhost.localdomain 2a338e4631fe[6141]: [104B blob data]
May 17 17:19:32 localhost.localdomain 2a338e4631fe[6141]: [104B blob data]
显示[104B blob data]而不是完整日志原因是因为有 r的存在，如果我们要完整显示，需要加上参数 --all。





## Spring boot 多日志文件的的思考

在使用spring的项目中，一般都会将日志通过网络写入到一个日志系统中，如ELK等，
此种情况在Docker中较简单，我们在此要讨论的是写入日志文件的情况。

### 文本文件日志方案一 掛載目錄 bind

創建一個目錄，將目錄掛載到容器中產生日志的目錄。

--mount type=bind,src=/opt/logs/, dst=/usr/local/tomcat/logs/

e.g.

```sh
## Create mount folder

mkdir /opt/logs

# 創建容器app並將/opt/logs掛載至/usr/local/app/logs
docker run -d --name app type=bind, src=/opt/logs/, dst=/usr/local/app/logs/ app
ls -l /opt/logs/
```

### 文本文件日志方案二 使用數據卷 volume

創建數據卷，創建容器時綁定該數據卷

--mount type=volume src=volume_name dst=/usr/local/tomcat/logs/

創建容器時指定此卷

e.g.

```sh
# 創建app應用數據卷名爲app
docker volume create vol-app
# 創建容器app並指定數據卷爲vol-app,綁定到/usr/log/app/logs
docker run -d --name app -P --mount type=volume, src=vol-app, dst=/usr/local/app/logs spring-boot
```

查看此數據卷中的內容

```sh
  ls -l /var/lib/docker/volumes/app/_data/
```

### 日志方案三 計算容器rootfs掛載點

和容器rootfs密不可分的一個概念是storage driver,實際使用過程中，用戶會根據linux版本、文件系統類型，容器讀寫情況
選擇合適的storage driver.不同的 storage driver下，容器的rootfs的遁形點有規律，所以可以依據storage driver
的類型計算出容器的rootfs的掛載點，進而採集容器內部日志。

Storage driver                      rootfs掛載點
aufs                                /var/lib/docker/aufs/mnt/
overlay                             /var/lib/docker/overlay//merged
overlay2                            /var/lib/docker/overlay2//merged
devicemapper                        /var/lib/docker/devicemapper/mnt//rootfs

e.g.

```sh
# 創建容器app-test

docker run -d --name app-test -P app

# 查看app-test容器掛載點的位置 
docker inspect -f '{{.GraphDriver.Data.MergedDir}}' app-test
# 可以看到輸出： /var/lib/docker/overlay2/b1cbc85ad7f7abfe79ec909358375fe48b6fadf011a1017186abae8d16136193/merged

# 當容器運行時(如果容器已退出，則不可列示)，執行如下查看命令
docker inspect -f '{{.GraphDriver.Data.MergedDir}}' app-test | xargs ls -l
# 也可以使用

ls -l $(docker inspect -f '{{.GraphDriver.Data.MergedDir}}' app-test)
```

