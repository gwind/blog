---
date: "2021-01-07"
title: 在 Istio 环境里如何配置双 https / tls 的路由规则
tags: [istio, tls, https]
---

![Publish ports behind the NAT](/post/computer/istio/attachment/tls-origination-for-egress-traffic.png)

上面是一个常见的服务路由配置需求：

1. 公网上使用 Let's Encrypt ( cert manager ) 申请域名证书，使用 https 协议
2. K8S 内部的 CockroachDB UI ( 默认 8080 端口 ）使用的是 https 协议（会自动重定向到 https ）

```yaml
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: crdb.c3.nlzqtcp.develop.ooclab.com-cert
spec:
  secretName: crdb.c3.nlzqtcp.develop.ooclab.com-cert
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  dnsNames:
  - crdb.c3.nlzqtcp.develop.ooclab.com


---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: crdb
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: crdb.c3.nlzqtcp.develop.ooclab.com-cert # must be the same as secret
    hosts:
    - crdb.c3.nlzqtcp.develop.ooclab.com


---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: crdb
spec:
  hosts:
  - crdb.c3.nlzqtcp.develop.ooclab.com
  gateways:
  - crdb
  http:
  - route:
    - destination:
        host: cockroachdb-public.c3.svc.cluster.local
        port:
          number: 8080

---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
# 此处的 TLS Origination 规则会让从外部来的 https （使用 Let's Encrypt证书）
# 在 TLS Termination 后，内部使用 TLS Client 方式再请求最终的 upstream
# 参考：
# 1. Double TLS (TLS origination for a TLS request)
# https://istio.io/latest/docs/ops/common-problems/network-issues/#double-tls
# 2. Egress TLS Origination
# https://istio.io/latest/docs/tasks/traffic-management/egress/egress-tls-origination/
metadata:
  name: originate-tls
spec:
  host: cockroachdb-public.c3.svc.cluster.local
  trafficPolicy:
    tls:
      mode: SIMPLE
```

参考

1. [Double TLS (TLS origination for a TLS request)](https://istio.io/latest/docs/ops/common-problems/network-issues/#double-tls)
2. [Egress TLS Origination](https://istio.io/latest/docs/tasks/traffic-management/egress/egress-tls-origination/)
