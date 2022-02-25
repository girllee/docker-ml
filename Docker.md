# Docker

## Docker 的安装

在debian 10 系统上安装docker, 以下步骤如遇问题，请参考[Official Doc](https://docs.docker.com/engine/install/debian/)

1. Prepare

```sh
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common gnupg2
```

2. 使用以下curl命令导入存储库的GPG密钥：

```sh
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
```

3. 将稳定的Docker APT存储库添加到系统的软件存储库列表中

```sh
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
```

4. 更新apt软件包列表并安装最新版本的Docker CE (Community Edition)

```sh
sudo apt update
sudo apt install docker-ce
```

5. 安装完成后，Docker服务将自动启动。要验证它输入

```sh
sudo systemctl status docker
```


## 系统设置

### Adjust memory and swap accounting

When users run Docker, they may see these messages when working with an image:

WARNING: Your kernel does not support cgroup swap limit. WARNING: Your
kernel does not support swap limit capabilities. Limitation discarded.
To prevent these messages, enable memory and swap accounting on your system. To enable these on system using GNU GRUB (GNU GRand Unified Bootloader), do the following.

Log into Ubuntu as a user with sudo privileges.

Edit the /etc/default/grub file.

Set the GRUB_CMDLINE_LINUX value as follows:

GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
Save and close the file.

Update GRUB.

$ sudo update-grub
Reboot your system.

确认你的linux内核开启了如下配置：

> CONFIG_RESOURCE_COUNTERS=y
> CONFIG_MEMCG=y
> CONFIG_MEMCG_SWAP=y
> CONFIG_MEMCG_SWAP_ENABLED=y
> CONFIG_MEMCG_KMEM=y

以命令行参数方式，在内核启动时开启 memory and swap accounting 选项：

> GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"

注意：以上只适用于GRUB2。通过查看/proc/cmdline可以确认命令行参数是否已经成功.

> **Notice** *由于众所周知的原因,在中国大陆访问 [docker官网的registry](https://registry.docker.com)会出现一些问题，所以请在使用doker之前先行设置registry的mirror*

## 设置docker registry 的mirror

在debian系的系统中可以使用如下shell设置registry的mirror

```sh
sudo echo "DOCKER_OPTS=\"--registry-mirror=https://registry.docker-cn.com\"" >> /etc/default/docker
service docker restart

# 通过修改/etc/docker/daemon.json, 如果没有请新建
{
  "registry-mirrors": ["https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn","http://hub-mirror.c.163.com"]
}

systemctl daemon-reload
systemctl restart docker
```

您也可以使用[Docker CN 指引](https://www.docker-cn.com/registry-mirror)来设置您的registry mirror.

## 用户权限

```sh
# 将当前用户加入到docker组中，这们不用每次都sudo
sudo usermod -aG docker 当前用户名
```

## docker image

Docker 的image存在与本地或者是registry中，通常我们执行docker run时,会从官方的
registry中将镜像pull到本地，然后再运行。
当然你也可以搭建自已的registry服务，由于registry服务本身也是一个docker的镜像，所以搭建过程非常简单，只需要运行docker run 命令就可以：

```sh
# 这个会从https://registry.docker.com/上拉取registry镜像，并执行，启动后registry服务可用
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

```sh
# 进入docker进行测试 

d run --rm -it $imgID /bin/sh

```

### 查看所有镜像

```sh
docker images
```

### 删除所有镜像

```sh
docker rmi $(docker images | grep none | awk '{print $3}' | sort -r)
```

### 拉取镜像

```sh
docker pull <镜像名:tag>
```

e.g.

```sh
docker pull asin/redmine:latest
```

### 迁移镜像

当需要将一台机器上的镜像迁移到另一台机器上的时候，需要保存镜像与加载镜像
在机器A上

```sh
docker save busybox-1 > /home/save.tar
```

使用scp 将save.tar 拷贝到机器B上,然后：

```sh
docker load < /home/save.tar
```

### 查看image 的大小

 Docker Hub 显示的是体积是压缩后的大小,网络传输中更关心的流量大小.
 docker image ls 显示的是镜像下载到本地后，展开的大小，准确说，是展开后的各层所占空间的总和,**需要注意的是**: 体积总和并非是所有镜像实际硬盘消耗。由于 Docker 镜像是多层存储结构，并且可以继承、复用，因此不同镜像可能会因为使用相同的基础镜像，从而拥有共同的层。由于 Docker 使用 Union FS，相同的层只需要保存一份即可，因此实际镜像硬盘占用空间很可能要比这个列表镜像大小的总和要小的多。

 可以通过以下命令来便捷的查看镜像、容器、数据卷所占用的空间。

```sh
docker system df
```

### 虚悬镜像

上面的镜像列表中，还可以看到一个特殊的镜像，这个镜像既没有仓库名，也没有标签，均为 `<none>`。

这个镜像原本是有镜像名和标签的，原来为 mongo:3.2，随着官方镜像维护，发布了新版本后，重新 docker pull mongo:3.2 时，mongo:3.2 这个镜像名被转移到了新下载的镜像身上，而旧的镜像上的这个名称则被取消，从而成为了 `<none>`。除了 docker pull 可能导致这种情况，docker build 也同样可以导致这种现象。由于新旧镜像同名，旧镜像名称被取消，从而出现仓库名、标签均为 `<none>` 的镜像。这类无标签镜像也被称为 虚悬镜像(dangling image) ，可以用下面的命令专门显示这类镜像：

```sh
docker image ls -f dangling=true
```

一般来说，虚悬镜像已经失去了存在的价值，是可以随意删除的，可以用下面的命令删除。

```sh
docker image prune
```

### 中间层镜像

### 构建自己的镜像

```sh
docker build -t <镜像名> <Dockerfile路径>
```

如Dockerfile在当前路径：

```sh
docker build -t xx/gitlib .
```

### 查看镜像名为nginx的镜像历史

```sh
docker history nginx
# or
docker history --no-trunc nginx
```

### 显示nginx镜像详细信息

```sh
docker image inspect nginx
```

### 查看端口映射问题

```sh
# 查看容器nginx 的端口映射
docker port nginx
```

### 打包一个镜像

```sh
# 打包到nginx.tar
docker image save nginx >nginx.tar
# 查看打出的包的大小
du -sh nginx.tar
```

### 导入一个打包的镜像

```sh
# 导入打包的镜像
docker image load < nginx.tar
# 列出镜像，确认导入成功
docker images | grep nginx
```

### docker run

```sh
# 运行一个新容器，并为它命名、端口映射、目录映射。以redmine为例
docker run --name redmine -p 9003:80 -p 9023:22 -d -v /var/redmine/files:/redmine/files -v /var/redmine/mysql:/var/lib/mysql sameersbn/redmine

# 通常我们在pull完成之后对当前的系统环境进行确认，可以使用如下方式：
sudo docker run --rm -t -i ubuntu:14.04 /bin/bash
# Note:
# docker run 只在第一次运行时使用，将镜像放到容器中，以后再次启动这个容器时，只需要使用命令docker start 即可。
# docker run 相当于执行了两步操作：将镜像放入容器中（docker create）,然后将容器启动，使之变成运行时容器（docker start）。
```

### docker start

```sh
# 运行指定ID或者名称的镜相
docker start redmine
```

### 一个容器连接到另一个容器

```sh
docker run -i -t --name sonar -d -link mysql:db tpires/sonar-server
sonar
```

容器连接到mysql 容器，并将mysql容器重命名为db.这样,sonar 容器就可以使用db 相关的环境变量了。

### 后台运行(-d)、并暴露端口(-p)

```sh
# 此命令会从registry 上pull 下来镜像，然后执行
docker run -d -p 127.0.0.1:33301:22 centos6-ssh
```

### 从Container中拷贝文件出来

```sh
sudo docker cp 7bb0e258aefe:/etc/debian_version .
```

拷贝7bb0e258aefe中的/etc/debian_version到当前目录下。
Note: 只要7bb0e258aefe没有删除，文件命名空间就还在，可以把exit状态的container的文件拷贝出来

### 重新查看container的stdout

```sh
# 启动top命令，后台运行
$ ID=$(sudo docker run -d ubuntu /usr/bin/top -b)
# 获取正在running的container的输出
sudo docker attach $ID
```

### docker工作目录

```sh
 ls /var/lib/docker
```

## docker container

### 查看正在运行的容器

> * docker ps
> * docker ps -a 查看所有容器，包括已停止的

### 删除所有容器

```sh
docker rm ${docker ps -a -q}
```

### 删除单个容器

docker rm <容器名 or ID>

### 启动一个容器

```sh
docker start <容器名　or ID>
```

### 停止一个容器

```sh
docker stop <容器名　or ID>
```

### 杀死一个容器

```sh
docker kill <容器名　or ID>
```

### 查看容器的root的用户密码

```sh
docker log <容器　or ID>  2>&1 | grep '^User: ' | tail -n1
```

Note: 在debian系统中，需要使用sudo 运行docker 命令或者使用

```sh
# Add the docker group if it doesnt' already exist.
$ sudo groupadd docker
# 改完后需要重新登录用户
$sudo gpasswd -a ${USER} docker
```

Dockerfile中的EXPOSE docker run --expose docker run -p 之间的区别

Dockerfile的 相当于docker run --expose,提供container之间的端口访问。
docker run -p 允许container外部的主机访问container的端口。

### 查看该容器的详细信息

```sh
sudo docker inspect 44fc0f0582d9
```

## 进入到docker中去

```sh
docker ps -l
# 进入到docker内的shell 环境中
docker exec -it 775c7c9ee1e1 /bin/bash

# 使用-u root 参数可以以root身份进入到docker的shell环境中

docker exec -it -u root 775c7c9ee1e1 /bin/bash
```

## Docker 和 宿主之间文件的传输

docker cp：用于容器与主机之间的数据拷贝

```sh
# 主机./mr 拷贝到容器30026605dcfe的/home/cloudera目录下。
docker cp mr 30026605dcfe:/home/cloudera

# 将容器30026605dcfe的/home/cloudera目录拷贝到主机的/tmp目录中
docker cp 30026605dcfe:/home/cloudera /tmp/
# 示例: cp ec66b227b5e3:/opt/nifi/nifi-current/conf/flow.xml.gz /home/boot/
```

## 修改docker image存放位置

1. 创建目标目录
mkdir /data/docker

2. 停止docker 服务
service docker stop

3. 同步路径
rsync -aXS /var/lib/docker/  /data/docker/

4. 修改fstab，将存放路径加入到fstab
nano /etc/fstab

5. 加入 /data/docker /var/lib/docker none bind 0 0
6. 重新挂载
mount -a
7. 重启docker 服务

## Experimental

1. Conifg
Add a magic first line to your Dockerfile:
\# syntax=docker/dockerfile:experimental
and the RUN directive then accepts a new flag --mount. Here’s a full example:
RUN --mount=type=cache,target=/root/.m2 ./mvnw install -DskipTests
2. docker build

```sh
DOCKER_BUILDKIT=1 docker build -t myorg/myapp .
```

## Run then goto shell

```sh
docker run -it --entrypoint /bin/sh myorg/myapp
ls
```

## Run as common user

```dockerfile
FROM openjdk:8-jdk-alpine

RUN addgroup -S demo && adduser -S demo -G demo
USER demo
```


## Q&A
 1. How to fix “dial unix /var/run/docker.sock: connect: permission denied” when group permissions seem correct?
 
 ```sh
 sudo setfacl --modify user:<user name or ID>:rw /var/run/docker.sock
 ```


sudo setfacl --modify user:<user name or ID>:rw /var/run/docker.sock
It doesn't require a restart and is more secure than usermod or chown.

as @mirekphd pointed out, the user ID is required when the user name only exists inside the container, but not on the host.

2. Got permission denied while trying to connect to the Docker daemon socket at unix:
  
  ```sh
    $ sudo gpasswd -a username docker   # 将普通用户username加入到docker组,如果没有sudo 请切换到root执行！
    $ newgrp docker  #更新docker组
  ```

3. docker build --build-arg

对每个参数使用--build-arg。

如果你传递两个参数，那么为每个参数添加--build-arg，如：

```docker
docker build \
-t essearch/ess-elasticsearch:1.7.6 \
--build-arg number_of_shards=5 \
--build-arg number_of_replicas=2 \
--no-cache .
```

```dockerfile
ARG number_of_replicas
ARG number_of_shards
```

遗憾的是我们也需要多个ARG，它会导致多个层并因此减慢构建速度，并且我们想知道，目前没有办法在一行设置多个ARG。


## docker中的存儲

1. volumes

docker管理宿主机文件系统的一部分（/var/lib/docker/volumes）保存数据的最佳方式

2. bind mounts

将宿主机上的任意位置的文件或者目录挂在到容器 `（–mount type=bind,src=源目录,dst=目标目录）`

3. tmpfs

挂载存储在主机系统的内存中，而不会写入主机的文件系统。如果不希望将数据持久存储在任何位置，可以使用tmpfs，同时避免写入容器可写层提高性能。

### 注意

volume: 需要注意的是，与bind mount不同的是，如果volume是空的而container中的目录有内容，那么docker会将container目录中的内容拷贝到volume中，但是如果volume中已经有内容，则会将container中的目录覆盖。即：如果src和dst都有數據則src覆蓋dst, 如果src沒有數據，而dst有數據，則dst覆蓋src.

```sh
  docker run -itd -p 8082:80 --mount src=ngx-vol, dst=/usr/share/nginx/html --name ngx nginx
  docker run -itd -p 8081:80 -v nginx-vol:/usr/share/nginx/html --name ngx2 nginx
```

volume 是docker的宿主机文件系统一部分，只有docker可以进行更改，其他进程不能修改
bind mounts 是挂载在宿主机文件系统的任意位置，除了docker所有进程都可以进行修改




