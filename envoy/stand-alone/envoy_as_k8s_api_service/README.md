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

- **10000**: Envoy 管理界面

### 配置文件


## 使用方法

### 方法一：手动运行（开发/测试）

```bash
# 直接运行
make run-envoy

# 或者手动运行
/root/envoy-1.35.0-linux-x86_64 -l debug -c ./envoy.yaml
```

### 方法二：作为 Systemd 服务运行（生产环境推荐）

#### 1. 安装服务

```bash
# 使用安装脚本（推荐）
sudo ./install-envoy-service.sh

# 或者使用 Makefile
make install-service
```

#### 2. 配置端点
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

#### 3. 启动服务

```bash
# 启动服务
make start-service
# 或者
sudo systemctl start envoy-k8s-proxy.service

# 检查状态
make status-service
# 或者
sudo systemctl status envoy-k8s-proxy.service

# 查看日志
make logs-service
# 或者
sudo journalctl -u envoy-k8s-proxy.service -f
```

#### 4. 服务管理命令

```bash
# 停止服务
make stop-service

# 重启服务
make restart-service

# 卸载服务
make uninstall-service
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

### 服务相关故障排除

```bash
# 检查服务状态
sudo systemctl status envoy-k8s-proxy.service

# 查看详细日志
sudo journalctl -u envoy-k8s-proxy.service -n 50

# 检查配置文件语法
/root/envoy-1.35.0-linux-x86_64 --mode validate -c ./envoy.yaml

# 重新加载配置（如果使用 systemd）
sudo systemctl reload envoy-k8s-proxy.service
``` 