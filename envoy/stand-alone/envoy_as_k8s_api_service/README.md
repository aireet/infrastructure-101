# Envoy as Kubernetes API Service Proxy (Multi-Endpoint)


istio 的学习曲线时陡峭的, 在学习istio的过程中, 我们应该分成两个东西来学, 一个是envoy,  一个是istio的控制面,数据面,sidecar来学习, 但不巧的是, envoy的学习曲线也是陡峭的.


来看看gpt 对比envoy和 nginx 怎么说
```
核心优势概述：

云原生和微服务适配：Envoy为云原生设计，与Kubernetes等容器编排平台深度集成，适合微服务场景下的服务治理和动态流量控制[Nginx更通用，Envoy专注于云原生]。

动态配置和自动化管理：Envoy原生支持动态配置（如通过xDS API），可以实时在线调整路由、策略等，无需重启进程，这对于敏捷开发和持续部署场景极为重要；Nginx的配置主要是静态且层级复杂，灵活性较低。

可扩展性与插件机制：Envoy架构高度模块化，支持自定义过滤器和插件，并暴露了丰富的API，方便与Istio等服务网格控制平面集成；其插件多为动态加载，而Nginx插件需静态编译，扩展点较为有限。

可观测性与治理：Envoy内置全面的监控、日志和分布式追踪功能，指标体系更丰富，有利于问题定位及与AIOps等体系集成；Nginx原生可观测性较弱，仅提供基础日志和指标，需依赖第三方扩展增强。

负载均衡与健康检查：Envoy支持多种复杂负载均衡算法，能够基于服务健康状态动态调整流量分配，灵活性高于Nginx。
```

envoy的功能是丰富且复杂的, 是动态且灵活的, 所以一开始我们先抛开他作为云原生serviceMesh balaba的概念, 我们使用静态配置,用一个最简单常见的例子: 高可用反向代理 来开始第一步envoy之旅

这个项目演示如何使用 Envoy 代理来负载均衡多个 Kubernetes API 服务器的访问。


## 架构

```
Client ─── Envoy Proxy (6443) ───┐
         │                       ├── K8s API Server 1 (192.168.6.149:6443) 
         │                       ├── K8s API Server 2 (192.168.6.150:6443)
         │                       └── K8s API Server 3 (192.168.6.151:6443)   
         │ 
         │ 
         │ 
         └── Admin Interface (9901) 
                                   
```

## 配置说明

### 端口映射
- **6443**: 客户端访问 Kubernetes API 的端口
- **9901**: Envoy 管理界面端口

### 负载均衡
- 使用轮询（ROUND_ROBIN）负载均衡策略
- 支持 TCP 健康检查
- 连接超时：5秒
- 健康检查间隔：10秒
- 支持多个 Kubernetes API 服务器端点

### 当前配置的端点
- `192.168.6.149:6443` - Kubernetes API Server 1
- `192.168.6.150:6443` - Kubernetes API Server 2  
- `192.168.6.151:6443` - Kubernetes API Server 3

## 使用方法

### 方法一：直接运行（开发/测试）

```bash
# 直接运行 Envoy
envoy -c envoy.yaml --log-level info

```

### 方法二：作为 Systemd 服务运行（生产环境推荐）

#### 1. 安装服务

```bash
# 复制服务文件到 systemd 目录
sudo cp envoy-k8s-proxy.service /etc/systemd/system/

# 重新加载 systemd 配置
sudo systemctl daemon-reload

# 启用服务（开机自启）
sudo systemctl enable envoy-k8s-proxy.service
```

#### 2. 配置 Kubernetes API 服务器地址

编辑 `envoy.yaml` 文件，在 `load_assignment` 部分配置您的 Kubernetes API 服务器地址：

```yaml
load_assignment:
  cluster_name: k8s_cluster_01_api_service
  endpoints:
  - lb_endpoints:
    - endpoint:
        address:
          socket_address:
            address: YOUR_K8S_API_SERVER_1_IP  # 替换为实际 IP
            port_value: 6443
    - endpoint:
        address:
          socket_address:
            address: YOUR_K8S_API_SERVER_2_IP  # 替换为实际 IP
            port_value: 6443
    - endpoint:
        address:
          socket_address:
            address: YOUR_K8S_API_SERVER_3_IP  # 替换为实际 IP
            port_value: 6443
```

#### 3. 启动服务

```bash
# 启动服务
sudo systemctl start envoy-k8s-proxy.service

# 检查状态
sudo systemctl status envoy-k8s-proxy.service

# 查看日志
sudo journalctl -u envoy-k8s-proxy.service -f
```

#### 4. 服务管理命令

```bash
# 停止服务
sudo systemctl stop envoy-k8s-proxy.service

# 重启服务
sudo systemctl restart envoy-k8s-proxy.service

# 重新加载配置
sudo systemctl reload envoy-k8s-proxy.service

# 禁用服务
sudo systemctl disable envoy-k8s-proxy.service
```

### 3. 访问 Kubernetes 集群

```bash
# 通过 Envoy 代理访问 Kubernetes API
kubectl --server=https://localhost:6443 get nodes

# 或者设置环境变量
export KUBECONFIG=/path/to/your/kubeconfig
kubectl config set-cluster my-cluster --server=https://localhost:6443
```

### 4. 查看管理界面

访问 http://localhost:9901 查看 Envoy 管理界面，可以监控：
- 集群健康状态
- 请求统计
- 负载均衡信息
- 各个端点的健康状态

## 动态端点管理


## 负载均衡工作原理

1. **轮询分发**：Envoy 会按照轮询策略将请求分发到三个 Kubernetes API 服务器
2. **健康检查**：每个端点都会进行 TCP 健康检查，确保服务可用性
3. **故障转移**：如果某个端点不可用，Envoy 会自动将流量路由到健康的端点
4. **负载分散**：多个端点可以分散 API 请求负载，提高整体性能

## 配置详情

### 监听器配置
- 监听地址：0.0.0.0:6443
- 过滤器：TCP 代理
- 目标集群：k8s_cluster_01_api_service

### 集群配置
- 集群名称：k8s_cluster_01_api_service
- 负载均衡策略：ROUND_ROBIN
- 健康检查：TCP 健康检查
- 连接超时：5秒
- 健康检查间隔：10秒
- 不健康阈值：3次
- 健康阈值：2次

### 端点配置
当前配置了三个 Kubernetes API 服务器端点：
- `192.168.6.149:6443`
- `192.168.6.150:6443`
- `192.168.6.151:6443`

## 故障排除

### 1. 检查服务状态

```bash
# 检查 systemd 服务状态
sudo systemctl status envoy-k8s-proxy.service

# 检查 Envoy 进程
ps aux | grep envoy

# 检查端口监听
netstat -tlnp | grep 6443
netstat -tlnp | grep 9901
```

### 2. 查看日志

```bash
# 查看 systemd 服务日志
sudo journalctl -u envoy-k8s-proxy.service -f

# 查看最近的日志
sudo journalctl -u envoy-k8s-proxy.service -n 50
```

### 3. 验证配置

```bash
# 验证 Envoy 配置文件语法
envoy --mode validate -c envoy.yaml

# 测试连接到 Kubernetes API
curl -k https://localhost:6443/healthz

# 检查各个端点的连通性
curl -k https://192.168.6.149:6443/healthz
curl -k https://192.168.6.150:6443/healthz
curl -k https://192.168.6.151:6443/healthz
```

### 4. 常见问题

1. **端口被占用**：检查 6443 和 9901 端口是否被其他服务占用
2. **权限问题**：确保服务以正确的用户权限运行
3. **网络连接**：验证 Envoy 能否访问所有 Kubernetes API 服务器


### 5. 负载均衡验证

```bash
# 多次请求测试负载均衡
for i in {1..10}; do
  echo "Request $i:"
  curl -k -s https://localhost:6443/healthz
  echo
  sleep 1
done
```

