# Istio 集群配置说明文档

## 概述

**官方文档参考：** https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/

## 配置文件结构

### 基础信息
```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: example
  namespace: istio-system
spec:
  revision: 1-21-0  # Istio 版本
```

## 主要配置组件

### 1. 基础组件 (Base Components)

#### 1.1 Base 组件
```yaml
components:
  base:
    enabled: true  # 启用基础组件
```
- **作用**: 提供 Istio 的基础功能支持
- **包含**: CRD、命名空间、服务账户等基础资源

#### 1.2 Pilot 控制平面
```yaml
components:
  pilot:
    enabled: true
    k8s:
      env:
      - name: "PILOT_ENABLE_HEADLESS_SERVICE_POD_LISTENERS"
        value: "true"
```
- **作用**: Istio 的核心控制平面，负责服务发现、配置分发
- **关键配置**: 
  - `PILOT_ENABLE_HEADLESS_SERVICE_POD_LISTENERS=true`: 启用无头服务的 Pod 监听器支持

### 2. 入口网关配置 (Ingress Gateways)

#### 2.1 HTTP 入口网关
```yaml
- name: ingress-http
  namespace: ingress-istio
  enabled: true
  label:
    app: ingress-http
  k8s:
    nodeSelector:
      echolab/ingress: enabled
    replicaCount: 3
    resources:
      requests:
        cpu: "1"
        memory: 500Mi
      limits:
        cpu: "4"
        memory: 2Gi
    hpaSpec:
      minReplicas: 3
      maxReplicas: 6
      metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 100
    service:
      type: NodePort
      externalTrafficPolicy: Local
      ports:
      - name: http
        protocol: TCP
        port: 80
        targetPort: 8080
```

**配置说明：**
- **命名空间**: `ingress-istio` - 专门的入口网关命名空间
- **节点选择器**: 只部署在标记了 `echolab/ingress: enabled` 的节点上
- **副本数**: 3个副本，支持 HPA 自动扩缩容（3-6个副本）
- **资源限制**: CPU 1-4核，内存 500Mi-2Gi
- **服务类型**: NodePort，外部流量策略为 Local（保持源 IP）

#### 2.2 gRPC 入口网关
```yaml
- name: ingress-grpc
  # 配置与 HTTP 网关类似，专门处理 gRPC 流量
```

#### 2.3 WebSocket 入口网关
```yaml
- name: ingress-websocket
  # 配置与 HTTP 网关类似，专门处理 WebSocket 连接
```

### 3. 代理配置 (Proxy Configuration)

#### 3.1 统计指标收集配置
```yaml
podAnnotations:
  proxy.istio.io/config: |-
    proxyStatsMatcher:
      inclusionSuffixes:
      - cx_http1_total      # HTTP/1.1 连接总数
      - cx_http2_total      # HTTP/2 连接总数  
      - cx_http1_active     # 当前活跃的 HTTP/1.1 连接数
      - cx_http2_active     # 当前活跃的 HTTP/2 连接数
      - cx_rx_bytes_total   # 接收的总字节数
      - cx_tx_bytes_total   # 发送的总字节数
      - rq_total            # 总请求数
      - rq_time             # 请求处理时间
      - rq_pending_total    # 总待处理请求数
      - rq_pending_active   # 当前活跃的待处理请求数
    concurrency: 4          # 并发处理数
```

**proxyStatsMatcher 配置说明：**
- **作用**: 控制 Envoy 代理统计指标的收集，优化性能
- **inclusionSuffixes**: 只收集以指定后缀结尾的指标
- **性能优势**: 减少默认 1000+ 个指标到 10 个关键指标
- **监控聚焦**: 专注于连接状态、流量统计、请求处理等关键指标

**concurrency 配置说明：**
- **作用**: 控制每个代理实例的并发处理能力
- **值**: 4，表示每个代理可以同时处理 4 个请求

### 4. 网格配置 (Mesh Configuration)

#### 4.1 基础网格设置
```yaml
meshConfig:
  accessLogEncoding: JSON           # 访问日志格式：JSON
  enableTracing: true               # 启用分布式追踪
  protocolDetectionTimeout: 0.3s    # 协议检测超时时间
```

#### 4.2 代理默认配置
```yaml
meshConfig:
  defaultConfig:
    extraStatTags:                   # 额外的统计标签
    - method                         # HTTP 方法
    - authority                      # 请求权威
    holdApplicationUntilProxyStarts: true  # 等待代理启动后再启动应用
    tracing:
      zipkin:
        address: opentelemetry-collector.monitor.svc.cluster.local:9411
    gatewayTopology:
      numTrustedProxies: 1          # 信任的代理数量
    proxyMetadata:
      ISTIO_META_DNS_CAPTURE: "true"        # 启用 DNS 代理
      ISTIO_META_DNS_AUTO_ALLOCATE: "true"  # 自动地址分配
```

#### 4.3 服务发现选择器
```yaml
meshConfig:
  discoverySelectors:
    - matchLabels:
        istio-discovery: enabled     # 只对标记了 istio-discovery: enabled 的资源启用服务发现
```

### 5. 全局配置 (Global Values)

#### 5.1 多集群配置
```yaml
values:
  global:
    meshID: cluster-01              # 网格唯一标识
    network: cluster-01             # 网络名称
    multiCluster:
      clusterName: cluster-01       # 多集群环境中的集群名称
```

#### 5.2 日志和调试配置
```yaml
values:
  global:
    logAsJson: true                 # 日志格式为 JSON
    logging:
      level: all:debug              # 日志级别：所有组件都设为 debug
```

#### 5.3 代理配置
```yaml
values:
  global:
    proxy:
      image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/istio/proxyv2:1.20.0
      logLevel: debug               # 代理日志级别
      resources:
        requests:
          cpu: 50m
          memory: 100Mi
        limits:
          cpu: 2000m
          memory: 1024Mi
```

#### 5.4 Pilot 配置
```yaml
values:
  pilot:
    image: swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/istio/pilot:1.20.0
    traceSampling: 1                # 追踪采样率：100%
    resources:
      requests:
        cpu: 100m
        memory: 1Gi
      limits:
        cpu: 500m
        memory: 2Gi
    autoscaleMin: 3                 # 最小副本数
    autoscaleMax: 5                 # 最大副本数
    cpu:
      targetAverageUtilization: 500 # CPU 目标利用率（百分比）
```

#### 5.5 遥测配置
```yaml
values:
  telemetry:
    enabled: false                  # 禁用旧版遥测
    v2:
      enabled: true                 # 启用新版遥测 v2
      prometheus:
        enabled: true               # 启用 Prometheus 指标收集
```

## 配置特点分析

### 1. 高可用性设计
- **多副本部署**: 所有网关都配置了 3 个副本
- **自动扩缩容**: 支持 HPA，根据 CPU 利用率自动调整副本数
- **节点选择器**: 确保网关只部署在专门的入口节点上

### 2. 性能优化
- **统计指标过滤**: 通过 `proxyStatsMatcher` 减少指标收集开销
- **并发控制**: 设置合理的并发处理数
- **资源限制**: 精确控制 CPU 和内存使用

### 3. 多集群支持
- **网格标识**: 明确的网格 ID 和网络名称
- **集群命名**: 支持多集群环境部署

### 4. 监控和追踪
- **分布式追踪**: 集成 Zipkin 追踪系统
- **指标收集**: 启用 Prometheus 指标
- **访问日志**: JSON 格式的结构化日志

## 部署建议

### 1. 生产环境考虑
- **资源规划**: 根据实际流量调整资源限制
- **监控配置**: 确保统计指标满足监控需求
- **安全配置**: 考虑启用 mTLS 和授权策略

### 2. 性能调优
- **统计指标**: 根据监控需求调整 `proxyStatsMatcher`
- **并发设置**: 根据节点性能调整 `concurrency`
- **HPA 配置**: 根据业务特点调整扩缩容策略

### 3. 故障排查
- **日志级别**: 生产环境建议调整为 info 或 warn
- **追踪采样**: 高流量环境可降低采样率
- **资源监控**: 关注 CPU 和内存使用情况

## 相关命令

### 1. 配置验证
```bash
# 验证配置文件语法
istioctl manifest generate -f cluster_01.yaml

# 分析配置问题
istioctl analyze -f cluster_01.yaml
```

### 2. 部署和升级
```bash
# 安装 Istio
istioctl install -f cluster_01.yaml

# 升级 Istio
istioctl upgrade -f cluster_01.yaml

# 卸载 Istio
istioctl uninstall --purge
```

### 3. 状态检查
```bash
# 检查安装状态
istioctl verify-install

# 查看网格信息
istioctl describe pod <pod-name>
```

## 参考资源

- [Istio 官方文档](https://istio.io/latest/docs/)
- [IstioOperator 配置参考](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/)
- [Istio 最佳实践](https://istio.io/latest/docs/ops/best-practices/)
- [Envoy 统计指标](https://www.envoyproxy.io/docs/envoy/latest/configuration/upstream/cluster_manager/cluster_stats)
