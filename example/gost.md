# Gost

## 拉取 Gost 镜像

```sh
docker pull ginuerzh/gost
```

## 安装证书

安装 [acme.sh](https://github.com/Neilpang/acme.sh)，用于申请证书，申请证书的过程参见 README，写的很详细，RSA 或者 ECC 证书都是可以的

申请完证书后安装证书，这里将证书安装在 `/etc/gost/`，这个路径在使用 docker 运行 Gost 时会用到

```sh
acme.sh --install-cert -d "domain.com" --fullchain-file /etc/gost/cert.pem --key-file /etc/gost/key.pem
```

## 创建认证文件

创建 secrets.txt 文件，用于多用户认证，格式为一行一对用户名密码，空格隔开，如

```conf
user0 pass0
user1 pass1
```
这里为了方便将 secrets.txt 文件也放在 /etc/gost/，方便挂载，可以根据自己情况修改.

## 运行gost

```sh
[sudo] docker run -d -p 8888:8888 --name gost -v /etc/gost/:/mnt ginuerzh/gost -L="socks5+tls://:8888?cert=/mnt/cert.pem&key=/mnt/key.pem&secrets=/mnt/secrets.txt"
```

其中 -v 参数用于挂载当前用户的 `/etc/gost/` 到 Gost 运行环境的 `/mnt` 目录，这样 Gost 程序就可以读取证书和用户信息文件，8888 是端口，这个根据自己的情况适当修改即可

运行后查看 Gost 运行状态，如果出现以下提示，就运行成功了.


运行后查看 Gost 运行状态，如果出现以下提示，就运行成功了

~ docker ps -a

```output
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                   PORTS                    NAMES
0b95ed614bb1        ginuerzh/gost       "/bin/gost -L=socks5…"   21 minutes ago      Up 21 minutes            0.0.0.0:5877->5877/tcp   gost
```

无证书时使用如下方式：

```sh
docker run -d -p 8888:8888 --name gost -v /etc/gost/:/mnt ginuerzh/gost -L="socks5://:8888"
```

## Proxy 示例

以下配置可能有错误

内网代理上网
以我的配置为例，由于跳板机使用的是Ubuntu Server 20.04 LTS，在配置的时候已经安装好了Docker，便直接使用Docker。

一行命令完成：

docker run -d -p 1080:1080/tcp -p 8080:8080/tcp ginuerzh/gost -L http://:8080 -L gost -L socks5://:1080


docker run -d -p 1080:1080/tcp ginuerzh/gost -L gost -L socks5://:1080 --name gost

然后就可以使用HTTP或者SOCKS5代理了。经过实测，浏览器和各类App都能够正常上网。

GOST
GOST绝不仅仅只有搭建内网代理服务器这一个功能。对于其他功能，我们可以打开 GOST Wiki 查看。

从GOST的全名，GO Simple Tunnel，我们可以知道，GOST本质上是一个在互联网上建立传输隧道的工具。不仅可以实现代理外访，还可以实现跳板链、内网穿透等多种强大功能（据说内网穿透性能比FRP更好），并且支持很多很多的传输协议——包括但不限于HTTP、HTTPS、SOCKS、Websocket、SSH、QUIC等。

简单的配置，请参考 快速开始


参考链接：

https://github.com/ginuerzh/gost
https://docs.ginuerzh.xyz/gost/

[docker](https://imciel.com/2018/04/29/create-gost-socks5-over-tls-proxy/)

[apt](https://getzhuji.com/3818.html)