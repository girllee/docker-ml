# Dockerfile 要注意的问题

## 减少构建的层数

```docker 
LABEL vendor=ACME\ Incorporated \
        cn.bittx.production="trade" \
        cn.bittx.version="1.0.0" \
        cn.bittx.release-date="2021-07-07" 

```

## 防止重复的包导入

使用将包名称按照字母表顺序排列来防止包的重复导入

```docker
RUN apt update && apt install -y \
        aufs-tools \
        automake \
        build-essential \
        curl \
        dpkg-sig \
        libcap-dev \
        libsqlite-dev \ 

```

## 删除无用的包信息

清理掉apt缓存/var/lib/apt/lists可以减少包镜相的大小，
因为RUN 指令开头为apt update,包缓存总会在apt install之前刷新

```docker 
RUN apt update && apt install -y --no-install-recommends  \
        aufs-tools \
        automake \
        build-essential \
        curl \
        dpkg-sig \
        libcap-dev \
        libsqlite-dev \ 
    && rm -rf /var/lib/apt/list/*
```
必要时使用.dockerignore文件,忽略掉不需要提交构建的文件，此文件指定
在构建目录下不想加入到上下文的文件或者目录

## 缓存

单行或者多行,docker 通过文本比对来确定此层是否已缓存，
只有一行的文本发生变化时，此层才会被重新构建，否则直接
使用缓存，可以通过--no-cache 方式显示指定不使用缓存。

```docker
# 此方式会产生两层，每行一层
RUN apt update 
# 由于docker使用的是文本方式确定层，所以会使用缓存
# 即第2次构建时直接使用上层缓存，不会执行apt update
RUN apt install -y nginx
``` 

```docker 
# 此行构建成一层
RUN apt -y update && apt install -y ngix
```


## ADD COPY

docker 会检查每个文件的内容校验和，如果不一致(不包括最后修改时间和最后访问时间)，就不会使用缓存.


## 多阶段构建

将变动的和不变动的分在两个阶段，


## 建议不使用ADD，而要使用管道

```docker
# 替代ADD
RUN mkdir -p /usr/src/app \
        && curl -SL https://www.apache.org/app.tar.gz \
        | tar -xJC /usr/src/app \
        && make -C /usr/src/app  all
```

注意： 带管道的命令返回的是最后一个命令的返回值。所以如果管道前的命令
出错，而管道后的命令正常执行，docker不会认为这条指令有问题。如果需要
所有的管道命令都正常执行，可以增加 set -o pipefail 

```docker
RUN set -o pipefail && wget -O - http://www.apache.org/a.zip | wc -l > /num
```

部分shell不支持 set -o pipefail 

```docker
RUN ["/bin/bash", "-c", "set -o pipefail && wget -O - http://www.apache.org/a.zip | wc -l > /num"]
```

## 新用户

```docker
RUN groupadd -r postgres && useradd -r -g postgres postgres
```

注意uid/gid是顺着镜相中已存在的uid/gid创建的，如果对这个有严格要求，应该自己显式定义。
不要在镜相中安装或者使用sudo, 可以使用gosu来实现，也不要来回的切换用户，这样会增加镜
相的层数.