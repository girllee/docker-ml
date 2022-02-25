# Docker Debug

## 『重用』容器名

编写/调试Dockerfile的时候我们经常会重复之前的command，比如这种docker run --name jstorm-zookeeper zookeeper:3.4，然后就容器名就冲突了。可以在运行 docker run 时候加上--rm flag, 容器将在退出之后销毁。无需手动docker rm CONTAINER

## logs 查看 stdout

所有容器内写到stdout的内容都会被捕获到host中的一个history文件中, 可以通过 docker logs CONTAINER 查看。

即使是容器已经退出的也可以看到，所以可以通过这种方式来分析非预期的退出。这些文件一直保存着，直到通过docker rm把容器删除。文件的具体路径可以通过docker inspect CONTAINER 获得。
（然后osx上你并找不到这些文件，因为其实osx的docker实际是运行在"VM"中，具体就不展开了，但是可以通过 screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty touch上"VM"的tty）

在使用docker logs 的时候加一些参数来过滤log，默认输出所有log。

    Options:
        --details        Show extra details provided to logs  
        -f, --follow     Follow log output  
        --help           Print usage  
        --since string   Show logs since timestamp  
        --tail string    Number of lines to show from the end of the logs (default "all")  
        -t, --timestamps     Show timestamps

## attach 实时查看stdout

如果你想实时查看容器的输出你可以用 docker attach CONTAINER 命令。

默认会绑定stdin，代理signals， 所以如果你 ctrl-c 容器通常会退出。很多时候大家并不想这样，只是想分离开，可以ctrl-p ctrl-q。

## 执行任意command

可以通过docker exec CONTAINER COMMAND，来在容器内执行任意 command，比如 cat 一些东西来debug。
也可以直接通过 exec 在容器内启动一个 shell 更方便地调试容器，不必一条条执行docker exec。
docker exec 只能在正在运行的容器上使用，如果已经停止了退出了就不行了，就只好用 docker logs 了。

## 重写entrypoint和cmd

每个Docker镜像都有 entrypoint 和 cmd , 可以定义在 Dockerfile 中，也可以在运行时指定。这两个概念很容易混淆，而且它们的使用方式也不同。

entrypoint 比 cmd 更"高级"，entrypoint 作为容器中pid为1的进程运行（docker不是虚拟机，只是隔离的进程。真正的linux中pid为1的是init）。
cmd 只是 entrypoint的参数:

> `<ENTRYPOINT> "<CMD>"`

当我们没有指定 entrypoint 时缺省为 /bin/sh -c。所以其实 entrypoint 是真正表达这个docker应该干什么的，通常大家有一个shell 脚本来代理。
entrypoint 和 cmd 都可以在运行的时候更改，通过更改来看这样设置entrypoint是否优雅合理。

    ```sh
    docker run -it --name jstorm-zookeeper --entrypoint /bin/bash zookeeper:3.4
    ```

任何 docker run 命令中在image名后的内容都作为cmd的内容传给 entrypoint当参数。

## 暂停容器

使用 docker pause 可以暂停容器中所有进程。这非常有用。

    ```sh
    docker run -d --name jstorm-zk zookeeper:3.4 && sleep 0.1 && docker pause jstorm-zk && docker logs jstorm-zk
    ```

### top 和 stats 获得容器中进程的状态

docker top CONTAINER 和在容器里执行 top 的效果类似。

    ```sh
    docker top jstorm-zookeeper
    ```

## 通过 inspect 查看容器的详细信息

docker inspect CONTAINER 饭后镜像和容器的详细信息。比如：

* State —— 容器的当先状态
* LogPath —— history(stdout) file 的路径
* Config.Env —— 环境变量
* NetworkSettings.Ports —— 端口的映射关系

环境变量非常有用,很多问题都是环境变量引起的。

## history 查看 image layers

可以看到各层创建的指令，大小和哈希。可以用来检查这个image是否符合你的预期。
