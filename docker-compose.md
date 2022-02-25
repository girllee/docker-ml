# docker-compose

## 安装


```sh
sudo apt install curl -y
```

```sh
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/
docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

```sh
sudo chmod +x /usr/local/bin/docker-compose
```

```sh
docker-compose version
```

## 多行command

使用 bash -c

```yaml
command: bash -c "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"
```
或者

```yaml
command: >
    bash -c "python manage.py migrate
    && python manage.py runserver 0.0.0.0:8000"
```
或者 

```yaml
command: bash -c "
    python manage.py migrate
    && python manage.py runserver 0.0.0.0:8000
  "
```

## Example 

```yaml
db:
  image: postgres
web:
  build: .
  #command: python manage.py migrate
  #command: python manage.py runserver 0.0.0.0:8000
  command: bash -c "python manage.py migrate && python manage.py runserver 0.0.0.0:8000"
  volumes:
    - .:/code
  ports:
    - "8000:8000"
  links:
    - db
```

## ports 与 