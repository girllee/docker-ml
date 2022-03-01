# MySQL

## Install

```sh
docker search mysql
docker pull mysql:lastest
```


## Run MySQL

```sh
docker run -itd --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysql@2022.03 mysql

docker run --name some-mysql -v /my/custom:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql

docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

docker run --name some-mysql -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root -d mysql

```

## Data dir


```sh
docker run --name some-mysql -v /my/own/datadir:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag
```

The -v /my/own/datadir:/var/lib/mysql part of the command mounts the /my/own/datadir directory from the underlying host system as /var/lib/mysql inside the container, where MySQL by default will write its data files.

## Dump and Restore

```sh
docker exec some-mysql sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > /some/path/on/your/host/all-databases.sql

docker exec -i some-mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < /some/path/on/your/host/all-databases.sql
```

## Run as an arbitrary user

```sh
$ mkdir .mydb
$ ls -lnd .mydb
drwxr-xr-x 2 1000 1000 4096 Aug 27 15:54 data
$ mkdir -p .mydb/conf
$ mkdir -p .mydb/data

docker run -d --name mysql -v "$PWD/.mydb/conf":/etc/mysql/conf.d -v "$PWD/.mydb/data":/var/lib/mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysql@2022.03 mysql --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci 

# --user 1000:1000 后需要解决 mysqld: Can't create/write to file '/var/lib/mysql/is_writable' (OS errno 13 - Permission denied)

docker run -d --user 1000:1000 --name mysql -v "$PWD/.mydb/conf":/etc/mysql/conf.d -v "$PWD/.mydb/data":/var/lib/mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysql@2022.03 mysql --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci 

$ docker run -v "$PWD/.mydb":/var/lib/mysql --user 1000:1000 --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag

docker run --name some-mysql -v /my/custom:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag


```

## Check

```sh
docker ps | grep mysql
```

## Connect

```sh
mysql -h localhost -u root -p 
```

```sh
docker exec -it mysql bash
```

## Connect to MySQL from the MySQL command line client

```sh
docker run -it --network some-network --rm mysql mysql -hsome-mysql -uexample-user -p
```

This image can also be used as a client for non-Docker or remote instances:

```sh
$ docker run -it --rm mysql mysql -hsome.mysql.host -usome-mysql-user -p
```

## Docker statck deploy OR docker-compose

Example stack.yml for mysql:

-- # Use root/example as user/password credentials

```yml
version: '3.1'

services:

  db:
    image: mysql
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example

  adminer:
    image: adminer
    restart: always
    ports:
      - 8080:8080
```
Run docker stack deploy -c stack.yml mysql (or docker-compose -f stack.yml up), wait for it to initialize completely, and visit http://swarm-ip:8080, http://localhost:8080, or http://host-ip:8080 (as appropriate).

