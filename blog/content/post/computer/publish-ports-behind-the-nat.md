---
date: "2020-03-21"
title: 如何将私有网络的服务（端口）发布到外网
---

这个需求可能来自于以下某一点：

1. 内部有些丰富的服务器资源，部署了一些测试环境，但是需要让外部人员（或当前 COVID-19 需要的分布式协作）可以访问。

2. 云上服务器用作测试成本相对较高，我们可以在内网搭建测试环境。

由于使用各种 VPN 解决有诸多不便。我们可以通过在公网部署一台非常小的网关服务器解决这个问题。

> 说明：网关服务器配置1核0.5G内存,100M带宽(按流量计费，弹性 eip)。

参考：

- [如何搭建一个安全的私有网络环境](https://gwind.me/post/computer/wireguard-network/)
- [otunnel](https://github.com/ooclab/otunnel) - 点对点加密隧道，最简单的双向端口映射工具

## 网络拓扑

![Publish ports behind the NAT](/post/computer/attachment/publish-ports-behind-the-nat.png)

## 案例配置

我们在内网有2台服务器 `P1` 和`T1` ，在阿里云有一个公网服务器 `G1` 。

需求：

1. 我们可以从任何地通过 `G1` 访问 `P1`, `T1` 的服务端口，以 ssh 为例。

前提：

1. `G1` 与 `P1` 之间用 wireguard 打通（可以查看参考文档完成）

方案：

1. 通过 haproxy 的端口映射

### haproxy 部署方案

分别在 `G1` 和 `P1` 上通过 docker-compose 运行各自的 haproxy 服务。

```bash
mkdir -pv /srv/production/haproxy
cd /srv/production/haproxy
vi docker-compose.yml
```

docker-compose.yml 文件内容如下：

```yaml
version: '3'
services:
  haproxy:
    image: haproxy:2.1
    network_mode: "host"
    volumes:
    - "./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg"
```

在当前目录下创建 haproxy.cfg 文件，具体配置下面介绍。

### G1 haproxy.cfg

配置如下：

```
listen srvs
    bind 0.0.0.0:20000-21000
    mode tcp
    server t1 6.6.6.2
```

配置效果：

1. 将所有访问 G1 的端口 20000-21000 的请求全部映射到访问 6.6.6.2 的对应端口（该 IP 是 wireguard 提供的）

### P1 haproxy.cfg

配置如下：

```
listen t1ssh
    bind 0.0.0.0:20011
    mode tcp
    timeout connect  4000
    timeout client   180000
    timeout server   180000
    server srv1 192.168.0.3:22
```

配置效果：

1. 将所有访问 P1 的端口 20011 请求映射到 T1 (192.168.0.3) 的 22 端口。

### 测试

至此，我们访问 G1 （图中IP为 100.100.100.100） 的 20011 端口，相当于访问了 T1 的 22 端口（ssh服务）

```
ssh -v -p 20011 root@100.100.100.100
```

## FAQ

以 `CentOS 7 x86_64` 环境为例，如果配置、启动、端口等有问题，请确保：

1. selinux 已被禁用
2. firewalld 停止
