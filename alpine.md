# alpine

## 进入到shell中

老版本

```sh
docker run -it --rm alpine /bin/ash
```

上面使用的选项:

/bin/ash是Ash(Almquist Shell)由BusyBox提供
--rm退出时自动删除容器(docker run --help)
-i 交互模式(即使没有附加也保持STDIN打开)
-t 分配伪TTY

当然，也可以将docker run -it --rm alpine /bin/ash
替换为:
docker run -it --rm alpine /bin/sh



新版本

如今，/bin/sh默认情况下，Alpine映像将直接启动，而无需指定要执行的shell：

```sh
sudo docker run -it --rm alpine  
/ # echo $0  
/bin/sh  
```

这是因为alpine镜像Dockerfile现在包含一个CMD命令，该命令指定了在容器启动时要执行的shell ： CMD ["/bin/sh"]。

在较旧的Alpine映像版本（2017之前）中，未使用CMD命令，因为Docker曾为CMD创建一个额外的层，这导致映像大小增加。这是Alpine Image开发人员想要避免的事情。在最新的Docker版本（1.10+）中，CMD不再占据一层，因此已将其添加到alpine映像中。因此，只要不覆盖CMD，最近的Alpine映像都将启动/bin/sh。