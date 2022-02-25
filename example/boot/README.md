# Spring boot docker 

## 内存的设置 

The InitialRAMPercentage JVM parameter allows us to `configure the initial heap size` of the Java application. It's a `percentage of the total memory of a physical server or container`, passed as a double value.

For instance, if we set-XX:InitialRAMPercentage=50.0 for a physical server of 1 GB full memory, then the initial heap size will be around 500 MB (50% of 1 GB).

To start with, let's check the default value of the IntialRAMPercentage in the JVM:

```sh

$ docker run openjdk:8 java -XX:+PrintFlagsFinal -version | grep -E "InitialRAMPercentage"
   double InitialRAMPercentage                      = 1.562500                            {product}

openjdk version "1.8.0_292"
OpenJDK Runtime Environment (build 1.8.0_292-b10)

```

Then, let's set the initial heap size of 50% for a JVM:


```sh
$ docker run -m 1GB openjdk:8 java -XX:InitialRAMPercentage=50.0 -XX:+PrintFlagsFinal -version | grep -E "InitialRAMPercentage"
   double InitialRAMPercentage                     := 50.000000                           {product}

openjdk version "1.8.0_292"
OpenJDK Runtime Environment (build 1.8.0_292-b10)

```

It's important to note that the `JVM ignores InitialRAMPercentage when we configure the -Xms option`.

