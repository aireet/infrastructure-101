### 创建了  networking.istio.io/v1beta1 Gateway 后, ingress的 envoy 里发生了什么

在部署完ingress-istio 后 我们创建Gateway对象
```
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: http-router
  namespace: ingress-istio
spec:
  selector:
    app: istio-ingressgateway-http
  servers:
    - hosts:
        - api.echolab.com
      port:
        name: http
        number: 8080
        protocol: HTTP
```
