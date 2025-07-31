# Envoy 代理 api-service

基于 Envoy 代理k8s api-service ，专注于 Kubernetes API 服务的负载均衡和故障转移。

## 📋 项目概述

本项目提供了完整的 Envoy 代理解决方案，主要用于：

- **多集群 Kubernetes API 代理**: 通过单个 Envoy 实例代理多个 K8s 集群的控制面API
- **智能负载均衡**: 支持轮询、健康检查、故障转移等高级特性
- **高可用性**: 内置故障检测和自动恢复机制
- **监控管理**: 提供 Web 管理界面和详细的访问日志

## 🏗️ 项目架构

```
Client 1 ──┐
           ├── Envoy Proxy ──┐
Client 2 ──┘                 ├── K8s Cluster 1 (192.168.1.19:6443, 192.168.1.20:6443)
                             └── K8s Cluster 2 (192.168.1.21:6443)
```

### 端口映射
- **6443**: 访问第一个 Kubernetes 集群 (k8s_cluster1)
- **6444**: 访问第二个 Kubernetes 集群 (k8s_cluster2)  
- **10000**: Envoy 管理界面

## 📁 项目结构

```
envoy/
├── Makefile                    # 下载 Envoy 二进制文件
└── stand-alone/
    └── envoy_as_k8s_api_service/
        ├── envoy.yaml          # 主配置文件
        ├── lds.yaml            # 监听器配置
        ├── cds.yaml            # 集群配置
        ├── eds_cluster1.yaml   # 集群1端点配置
        ├── eds_cluster2.yaml   # 集群2端点配置
        ├── Makefile            # 服务管理工具
        ├── envoy-k8s-proxy.service  # Systemd 服务文件
        └── README.md           # 详细使用说明
```

## 🚀 快速开始

### 1. 环境准备

```bash
# 进入项目目录
cd envoy

# 下载 Envoy 二进制文件
make download
```

### 2. 配置端点

编辑 `stand-alone/envoy_as_k8s_api_service/` 目录下的端点配置文件：

#### eds_cluster1.yaml
```yaml
resources:
- "@type": type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment
  cluster_name: k8s_cluster1
  endpoints:
  - lb_endpoints:
    - endpoint:
        address:
          socket_address:
            address: YOUR_K8S_CLUSTER1_IP1
            port_value: 6443
    - endpoint:
        address:
          socket_address:
            address: YOUR_K8S_CLUSTER1_IP2
            port_value: 6443
```

#### eds_cluster2.yaml
```yaml
resources:
- "@type": type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment
  cluster_name: k8s_cluster2
  endpoints:
  - lb_endpoints:
    - endpoint:
        address:
          socket_address:
            address: YOUR_K8S_CLUSTER2_IP
            port_value: 6443
```

### 3. 启动服务

#### 方法一：手动运行（开发/测试）
```bash
cd stand-alone/envoy_as_k8s_api_service
make run-envoy
```

#### 方法二：Systemd 服务（生产环境推荐）
```bash
cd stand-alone/envoy_as_k8s_api_service

# 安装服务
make install-service

# 启动服务
make start-service

# 检查状态
make status-service
```

### 4. 验证部署

```bash
# 访问第一个集群
kubectl --server=https://localhost:6443 get nodes

# 访问第二个集群
kubectl --server=https://localhost:6444 get nodes

# 查看管理界面
curl http://localhost:10000/stats
```

## 🔧 配置详解

### 1. 主配置文件 (envoy.yaml)

```yaml
node:
  cluster: k8s_cluster_proxy
  id: k8s_cluster_proxy

dynamic_resources:
  lds_config:
    path_config_source:
      path: "./lds.yaml"
  cds_config:
    path_config_source:
      path: "./cds.yaml"

admin:
  access_log_path: "/dev/null"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 10000
```

**配置说明**:
- `dynamic_resources`: 启用动态配置加载
- `lds_config`: 监听器发现服务配置
- `cds_config`: 集群发现服务配置
- `admin`: 管理界面配置

### 2. 监听器配置 (lds.yaml)

定义了两个 TCP 代理监听器：

```yaml
resources:
- "@type": type.googleapis.com/envoy.config.listener.v3.Listener
  name: k8s_cluster1
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 6443
  filter_chains:
  - filters:
    - name: envoy.filters.network.tcp_proxy
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
        stat_prefix: k8s_cluster1
        cluster: k8s_cluster1
```

**特性**:
- TCP 代理模式，适用于 Kubernetes API 服务
- 支持访问日志记录
- 统计信息收集

### 3. 集群配置 (cds.yaml)

每个集群包含以下高级特性：

#### 负载均衡
```yaml
lb_policy: ROUND_ROBIN  # 轮询负载均衡
```

#### 健康检查
```yaml
health_checks:
- timeout: {seconds: 3}
  interval: {seconds: 10}
  unhealthy_threshold: {value: 3}
  healthy_threshold: {value: 2}
  http_health_check:
    path: "/healthz"
    expected_statuses:
    - start: 200
      end: 299
  tcp_health_check: {}
```

#### 故障转移
```yaml
outlier_detection:
  consecutive_5xx: {value: 5}
  base_ejection_time: {seconds: 30}
  max_ejection_percent: 50
  min_health_percent: 50
```

#### 重试策略
```yaml
retry_policy:
  retry_on: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
  num_retries: 3
  per_try_timeout: {seconds: 5}
  retriable_status_codes: [500, 502, 503, 504]
```

## 🛠️ 服务管理

### Makefile 命令

```bash
# 手动运行
make run-envoy

# 服务管理
make install-service    # 安装服务
make start-service      # 启动服务
make stop-service       # 停止服务
make restart-service    # 重启服务
make status-service     # 查看状态
make logs-service       # 查看日志
make uninstall-service  # 卸载服务

# 帮助信息
make help
```

### Systemd 服务

服务文件位置：`/etc/systemd/system/envoy-k8s-proxy.service`

```bash
# 直接使用 systemctl
sudo systemctl start envoy-k8s-proxy.service
sudo systemctl status envoy-k8s-proxy.service
sudo systemctl stop envoy-k8s-proxy.service
```

## 📊 监控和调试

### 1. 管理界面

访问 `http://localhost:10000` 查看 Envoy 管理界面：

- **/stats**: 统计信息
- **/clusters**: 集群状态
- **/listeners**: 监听器状态
- **/config_dump**: 配置转储

### 2. 日志查看

```bash
# 查看服务日志
make logs-service

# 或者直接查看
sudo journalctl -u envoy-k8s-proxy.service -f
```

### 3. 配置验证

```bash
# 验证配置文件语法
./envoy-1.35.0-linux-x86_64 --mode validate -c ./envoy.yaml
```

## 🔍 故障排除

### 常见问题

#### 1. 连接被拒绝
```bash
# 检查端点是否可达
telnet YOUR_K8S_CLUSTER_IP 6443

# 检查防火墙设置
sudo iptables -L
```

#### 2. 健康检查失败
```bash
# 检查 Kubernetes API 健康端点
curl -k https://YOUR_K8S_CLUSTER_IP:6443/healthz

# 查看 Envoy 日志
make logs-service
```

#### 3. 负载均衡不工作
```bash
# 检查集群状态
curl http://localhost:10000/clusters

# 验证端点配置
cat eds_cluster1.yaml
```

### 调试命令

```bash
# 检查端口监听
netstat -tlnp | grep envoy

# 检查进程状态
ps aux | grep envoy

# 测试连接
curl -v http://localhost:10000/stats
```

## 📚 高级配置

### 1. 自定义负载均衡策略

修改 `cds.yaml` 中的 `lb_policy`：

```yaml
# 最少连接
lb_policy: LEAST_REQUEST

# 随机
lb_policy: RANDOM

# 加权轮询
lb_policy: ROUND_ROBIN
```

### 2. 连接池优化

```yaml
upstream_connection_options:
  tcp_keepalive:
    keepalive_probes: 3
    keepalive_time: 300
    keepalive_interval: 10
```

### 3. 访问日志配置

```yaml
access_log:
- name: envoy.access_loggers.file
  typed_config:
    "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
    path: "/var/log/envoy/access.log"
    format: "[%START_TIME%] %REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL% %RESPONSE_CODE% %RESPONSE_FLAGS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% %DOWNSTREAM_REMOTE_ADDRESS_WITHOUT_PORT% %UPSTREAM_HOST% %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS_WITHOUT_PORT% %REQ(X-FORWARDED-FOR)% %REQ(USER-AGENT)% %REQ(X-REQUEST-ID)% %REQ(:AUTHORITY)% %UPSTREAM_TRANSPORT_FAILURE_REASON%\n"
```

## 🔗 相关资源

- [Envoy 官方文档](https://www.envoyproxy.io/docs/)
- [Envoy 配置参考](https://www.envoyproxy.io/docs/envoy/latest/configuration/configuration)
- [Kubernetes API 文档](https://kubernetes.io/docs/reference/kubernetes-api/)

