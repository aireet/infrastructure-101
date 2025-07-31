# Envoy as Kubernetes API Service Proxy (Multi-Cluster)

这个项目演示如何使用单个 Envoy 代理来负载均衡多个 Kubernetes 集群的 API 服务。

## 架构

```
Client 1 ──┐
           ├── Envoy Proxy ──┐
Client 2 ──┘                 ├── K8s Cluster 1 (192.168.1.19:6443, 192.168.1.20:6443)
                             └── K8s Cluster 2 (192.168.1.21:6443, 192.168.1.22:6443)
```

## 配置说明

### 端口映射
- **6443**: 访问第一个 Kubernetes 集群 (k8s_cluster1)
- **6444**: 访问第二个 Kubernetes 集群 (k8s_cluster2)
- **10000**: Envoy 管理界面

### 配置文件

1. **envoy.yaml**: 主配置文件，定义动态资源配置
2. **lds.yaml**: 监听器配置，定义两个监听端口
3. **cds.yaml**: 集群配置，定义两个集群
4. **eds_cluster1.yaml**: 第一个集群的端点配置
5. **eds_cluster2.yaml**: 第二个集群的端点配置

## 使用方法

### 1. 配置端点
编辑 `eds_cluster1.yaml` 和 `eds_cluster2.yaml` 文件，将 IP 地址替换为您的实际 Kubernetes API 服务器地址：

```yaml
# eds_cluster1.yaml
resources:
- "@type": type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment
  cluster_name: k8s_cluster1
  endpoints:
  - lb_endpoints:
    - endpoint:
        address:
          socket_address:
            address: YOUR_K8S_CLUSTER1_IP
            port_value: 6443
```

### 2. 启动 Envoy
```bash
make run-envoy
```

### 3. 访问集群
```bash
# 访问第一个集群
kubectl --server=https://localhost:6443 get nodes

# 访问第二个集群
kubectl --server=https://localhost:6444 get nodes
```

### 4. 查看管理界面
访问 http://localhost:10000 查看 Envoy 管理界面

## 负载均衡

每个集群都配置了轮询负载均衡策略，Envoy 会在多个端点之间分发请求。

## 故障排除

1. 检查端点配置是否正确
2. 确保 Kubernetes API 服务器可访问
3. 查看 Envoy 日志获取详细信息
4. 使用管理界面检查集群状态 