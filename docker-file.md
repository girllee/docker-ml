
# Dockerfile

## 编写.dockerignore文件

构建镜像时，Docker需要先准备context ，将所有需要的文件收集到进程中。默认的context包含Dockerfile目录中的所有文件，但是实际上，我们并不需要.git目录，node_modules目录等内容。 .dockerignore 的作用和语法类似于 .gitignore，可以忽略
一些不需要的文件，这样可以有效加快镜像构建时间，同时减少Docker镜像的大小。
示例如下:

```.dockerignore
.git/
node_modules/
```

## 将多个RUN指令合并为一个

Docker镜像是分层的，下面这些知识点非常重要:

Dockerfile中的每个指令都会创建一个新的镜像层。镜像层将被缓存和复用,当Dockerfile的指令修改了，复制的文件变化了，或者构建镜像时指定的变量不同了，对应的镜像层缓存就会失效,某一层的镜像缓存失效之后，它之后的镜像层缓存都会失效.镜像层是不可变的，如果我们再某一层中添加一个文件，然后在下一层中删除它，则镜像中依然会包含该文件(只是这个文件在Docker容器中不可见了)。
Docker镜像类似于洋葱。它们都有很多层。为了修改内层，则需要将外面的层都删掉。记住这一点的话，其他内容就很好理解了。

现在，我们将所有的RUN指令合并为一个。同时把apt-get upgrade删除，因为它会使得镜像构建非常不确定(我们只需要依赖基础镜像的更新就好了)

```dockerfile
FROM ubuntu

ADD . /app

RUN apt-get update \
  && apt-get install -y nodejs \
  && cd /app \
  && npm install

CMD npm start
```

记住一点，我们**只能将变化频率一样的指令合并在一起**。将node.js安装与npm模块安装放在一起的话，则每次修改源代码，都需要重新安装node.js，
这显然不合适。
因此，正确的写法是这样的:

```dockerfile
FROM ubuntu

RUN apt-get update && apt-get install -y nodejs
ADD . /app
RUN cd /app && npm install

CMD npm start
```

## 设置WORKDIR和 CMD

WORKDIR指令可以设置默认目录，也就是运行RUN / CMD / ENTRYPOINT指令的地方。
CMD指令可以设置容器创建时执行的默认命令。另外，你应该将命令写在一个数组中，数组中每个元素为命令的每个单词(参考官方文档)。

```Dockerfile
FROM node:7-alpine

WORKDIR /app
ADD . /app
RUN npm install

CMD ["npm", "start"]
```

## 使用ENTRYPOINT (可选)

ENTRYPOINT指令并不是必须的，因为它会增加复杂度。ENTRYPOINT是一个脚本，它会默认执行，并且将指定的命令错误其参数。它通常用于构建可执行的Docker镜像。
entrypoint.sh如下:

```sh
#!/usr/bin/env sh
# $0 is a script name,
# $1, $2, $3 etc are passed arguments
# $1 is our command
CMD=$1

case "$CMD" in
 "dev" )
  npm install
  export NODE_ENV=development
  exec npm run dev
  ;;

 "start" )
  # we can modify files here, using ENV variables passed in 
  # "docker create" command. It can't be done during build process.
  echo "db: $DATABASE_ADDRESS" >> /app/config.yml
  export NODE_ENV=production
  exec npm start
  ;;

  * )
  # Run custom command. Thanks to this line we can still use 
  # "docker run our_image /bin/bash" and it will work
  exec $CMD ${@:2}
  ;;
esac
```

示例Dockerfile:

```dockerfile
FROM node:7-alpine

WORKDIR /app
ADD . /app
RUN npm install

ENTRYPOINT ["./entrypoint.sh"]
CMD ["start"]
```

可以使用如下命令运行该镜像:

```sh
# 运行开发版本
docker run our-app dev

# 运行生产版本
docker run our-app start

# 运行bash
docker run -it our-app /bin/bash
```

## 在entrypoint脚本中使用exec

在前文的entrypoint脚本中，我使用了exec命令运行node应用。不使用exec的话，我们则不能顺利地关闭容器，因为SIGTERM信号会被bash脚本进程吞没。exec命令启动的进程可以取代脚本进程，因此所有的信号都会正常工作。

## 合理调整COPY与RUN的顺序

我们应该把变化最少的部分放在Dockerfile的前面，这样可以充分利用镜像缓存。

示例中，源代码会经常变化，则每次构建镜像时都需要重新安装NPM模块，这显然不是我们希望看到的。因此我们可以先拷贝package.json，然后安装NPM模块，最后才拷贝其余的源代码。这样的话，即使源代码变化，也不需要重新安装NPM模块。

```dockerfile
FROM node:7-alpine

WORKDIR /app

COPY package.json /app
RUN npm install
COPY . /app

ENTRYPOINT ["./entrypoint.sh"]
CMD ["start"]
```

## 添加HEALTHCHECK

运行容器时，可以指定--restart always选项。这样的话，容器崩溃时，Docker守护进程(docker daemon)会重启容器。对于需要长时间运行的容器，这个选项非常有用。但是，如果容器的确在运行，但是不可(陷入死循环，配置错误)用怎么办？使用HEALTHCHECK指令可以让Docker周期性的检查容器的健康状况。我们只需要指定一个命令，如果一切正常的话返回0，否则返回1。
示例如下:

```dockerfile
FROM node:7-alpine
LABEL maintainer "jakub.skalecki@example.com"

ENV PROJECT_DIR=/app
WORKDIR $PROJECT_DIR

COPY package.json $PROJECT_DIR
RUN npm install
COPY . $PROJECT_DIR

ENV MEDIA_DIR=/media \
  NODE_ENV=production \
  APP_PORT=3000

VOLUME $MEDIA_DIR
EXPOSE $APP_PORT
HEALTHCHECK CMD curl --fail http://localhost:$APP_PORT || exit 1

ENTRYPOINT ["./entrypoint.sh"]
CMD ["start"]
```

当请求失败时，curl --fail 命令返回非0状态。

## 使用LABEL设置镜像元数据

使用LABEL指令，可以为镜像设置元数据，例如镜像创建者或者镜像说明。旧版的Dockerfile语法使用MAINTAINER指令指定镜像创建者，但是它已经被弃用了。有时，一些外部程序需要用到镜像的元数据，例如nvidia-docker需要用到com.nvidia.volumes.needed。示例如下:

```dockerfile
FROM node:7-alpine
LABEL maintainer "jakub.skalecki@example.com"
...
```

## 设置默认的环境变量，映射端口和数据卷

运行Docker容器时很可能需要一些环境变量。在Dockerfile设置默认的环境变量是一种很好的方式。另外，我们应该在Dockerfile中设置映射端口和数据卷。示例如下:

```dockerfile
FROM node:7-alpine

ENV PROJECT_DIR=/app

WORKDIR $PROJECT_DIR

COPY package.json $PROJECT_DIR
RUN npm install
COPY . $PROJECT_DIR

ENV MEDIA_DIR=/media \
  NODE_ENV=production \
  APP_PORT=3000

VOLUME $MEDIA_DIR
EXPOSE $APP_PORT

ENTRYPOINT ["./entrypoint.sh"]
CMD ["start"]
```

*ENV指令指定的环境变量在容器中可以使用。如果你只是需要指定构建镜像时的变量，你可以使用ARG指令。
*

## 使用自签名证书

```dockerfile
ADD your_ca_root.crt /usr/local/share/ca-certificates/foo.crt
RUN update-ca-certificates
```

## 换源加速

可以使用shell生成souces.list文件，如果使用的是https的连接，可能要安装apt-transport-https.
通过试验可知，在安装之前要求先安装`ca-certificates`, 但是此包需要在执行apt-get update之后才
可以安装，apt-get update需要依赖于sources.list中https请求，这些请求又依赖于`ca-certificates`,
所以现在一个办法是不要使用https的sources.list。
虽然清华官网建议先安装apt-transport-https,但在使用debian:buster-slim还是行不通的。

```dockerfile
FROM debian:buster-slim as build

ADD sources.list /etc/apt/

RUN apt-get install apt-transport-https

RUN apt-get update \
    && set -x \
    ...

```

## Multi-stage

示例：

```dockerfile
# Buster version of debian
FROM debian:buster-slim as build

# Innstall packages
RUN set -x \
    && mkdir mm \
    && cd /mm \
    && echo "Hello world "> h.txt

FROM debian:buster-slim
WORKDIR /mnt
VOLUME /mnt
COPY --from=build /mm/h.txt .

CMD ["cat", "./h.txt"]
```
