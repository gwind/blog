---
date: "2020-10-12"
title: 搭建容器镜像仓库用于缓存或FQ
tags: [docker, registry]
---

由于众所周知的原因，我们的网络环境不是很稳定。外网的资源获取可能会比较曲折，内网的资源有时也会访问比较慢。
虽然有多个国内可以访问的公网容器镜像仓库( Docker Registry Mirror)可用，但是通常只支持 docker hub 官方的镜像，对于 quay.io , gcr.io 等目前没有可用方案。且稳定性不一定都很好。

说明：之前 azure 有官方支持，但是今年 (2020年4月) 已经停止对外访问，仅限 azure china 内部使用。

对于团队内部使用，无论是加速拉取速度，还是 FQ 拉取不可直接访问的 image ，最稳定的方案还是自己可以随时搭建一个私有部署的 mirror 。

搭建过程大多类似，下面仅以 gcr.io 为例详细介绍，其他类似。

## 搭建 gcr.io

**前提** ：

1. 请在一个可以正常访问 https://gcr.io 的服务器搭建，这里假设该服务器名为 `HK-1`
2. 准备好 docker 和 docker-compose

创建实验目录，如 `/srv/production/registry-cache/gcrio` ，进入该目录，创建下面 2 个文件。

`docker-compose.yml` 文件内容：

```yaml
version: '3'
services:
    mirror:
        image: registry
        volumes:
            - "/data/production/registry-cache/gcrio/data:/var/lib/registry"
            - "./config.yml:/etc/docker/registry/config.yml"
        ports:
            - "5002:5000"
```

`config.yml` 文件内容：

```yaml
# https://docs.docker.com/registry/configuration/
version: 0.1
storage:
  filesystem:
    rootdirectory: /var/lib/registry
    maxthreads: 100
http:
  addr: 0.0.0.0:5000
proxy:
  remoteurl: https://gcr.io
```

启动服务：

```shell
docker-compose up -d
```

在任何可以访问服务器 `HK-1` （假设其 IP 为 6.6.6.6） 的另外一台服务器里配置 docker ，编辑 `/etc/docker/daemon.json` ，添加配置：

```json
{"insecure-registries":["6.6.6.6:5002"]}
```

重新加载 docker 配置：

```shell
systemctl reload docker
```

测试拉取一个 image ，比如我们需要拉取 `gcr.io/google_containers/pause-amd64:3.1` ，可以修改地址为 `6.6.6.6:5002/google_containers/pause-amd64:3.1` ，执行拉取：

```shell
# docker pull 6.6.6.6:5002/google_containers/pause-amd64:3.1
3.1: Pulling from google_containers/pause-amd64
Digest: sha256:59eec8837a4d942cc19a52b8c09ea75121acc38114a2c68b98983ce9356b8610
Status: Image is up to date for 6.6.6.6:5002/google_containers/pause-amd64:3.1
6.6.6.6:5002/google_containers/pause-amd64:3.1
```

## 其他常见 docker registry 说明

### docker hub

```yaml
remoteurl: https://registry-1.docker.io
```

### quay.io

```yaml
remoteurl: https://quay.io
```

## 参考

- [如何搭建一个安全的私有网络环境](https://gwind.me/post/computer/wireguard-network/)
