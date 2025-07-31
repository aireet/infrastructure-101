# Kubernetes kubeadm 配置指南

## 概述

本目录包含使用 kubeadm 部署 Kubernetes 集群的配置文件和相关说明。

## 配置文件说明

### kubeadm.yaml

主要的 kubeadm 配置文件，包含以下部分：

#### 1. InitConfiguration
```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  name: 192.168.6.149  # 建议使用主机名而不是IP地址
```

#### 2. ClusterConfiguration
```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.27.8
clusterName: wx-omega
networking:
  podSubnet: "172.31.0.0/16"      # Pod 网络段
  serviceSubnet: "172.32.0.0/16"  # Service 网络段
controlPlaneEndpoint: "192.168.6.159:6443"  # 控制平面端点
imageRepository: 192.168.6.164:5000/well-known  # 镜像仓库
```

#### 3. KubeletConfiguration
```yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: cgroupfs  # 建议与容器运行时保持一致
maxPods: 64            # 每个节点最大Pod数
```

#### 4. KubeProxyConfiguration
```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs  # 使用 ipvs 模式，性能更好
```

## KubeProxy Mode 详解

KubeProxy 的 `mode` 字段用于指定代理模式，主要有以下几种：

### 1. ipvs（推荐，性能最佳）

```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
```

#### 特点：
- **性能最好**：基于 Linux 内核的 IP Virtual Server
- **支持多种负载均衡算法**：rr（轮询）、wrr（加权轮询）、lc（最少连接）、wlc（加权最少连接）等
- **支持会话保持**：通过 `ipvsadm` 配置
- **支持 DSR（Direct Server Return）**：减少网络跳数
- **内核级实现**：效率高，延迟低

#### 适用场景：
- 生产环境
- 高并发场景
- 需要复杂负载均衡策略

### 2. iptables（默认，兼容性最好）

```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: iptables
```

#### 特点：
- **兼容性最好**：几乎所有 Linux 发行版都支持
- **功能完整**：支持所有 Kubernetes 网络功能
- **调试方便**：可以用 `iptables` 命令查看规则
- **性能中等**：规则数量多时性能下降明显

#### 适用场景：
- 开发测试环境
- 兼容性要求高的环境
- 需要详细调试网络规则

### 3. userspace（已废弃，不推荐）

```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: userspace
```

#### 特点：
- **用户空间实现**：性能最差
- **功能有限**：不支持高级负载均衡特性
- **已废弃**：Kubernetes 1.20+ 已标记为废弃

### 4. kernelspace（Windows 专用）

```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: kernelspace
```

#### 特点：
- **仅支持 Windows 节点**
- **基于 Windows HNS（Host Network Service）**
- **性能优于 userspace**

## KubeProxy Mode 对比表

| 模式 | 性能 | 兼容性 | 功能 | 推荐度 | 适用场景 |
|------|------|--------|------|--------|----------|
| **ipvs** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 生产环境 |
| **iptables** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 开发测试 |
| **userspace** | ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐ | 已废弃 |
| **kernelspace** | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | Windows 节点 |

## KubeProxy 配置示例

### 完整的 KubeProxyConfiguration
```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
ipvs:
  scheduler: "rr"  # 负载均衡算法：rr, wrr, lc, wlc, lblc, lblcr, dh, sh, sed, nq
  minSyncPeriod: "0s"
  syncPeriod: "30s"
  excludeCIDRs: []  # 排除的 CIDR
```

## 网络配置说明

### PodSubnet 和 ServiceSubnet

- **podSubnet**: Pod 网络段，需要与 CNI 插件配置一致
- **serviceSubnet**: Service 网络段，用于集群内部服务通信

#### 推荐配置
```yaml
networking:
  podSubnet: "10.244.0.0/16"    # Flannel 默认网段
  serviceSubnet: "10.96.0.0/12" # Kubernetes 推荐标准网段
```

#### 注意事项
- 确保网段不与物理网络冲突
- 检查网络环境：`ip route show` 和 `ip addr show`
- 建议使用标准私有网段避免冲突

## Flannel Backend 类型说明

Flannel 的 `net-conf.json` 中的 `Backend` 字段用于指定数据包转发方式：

### 1. vxlan（默认，最常用）
```json
"Backend": {
  "Type": "vxlan"
}
```
- **原理**: 使用 VXLAN 隧道封装 Pod 网络流量
- **优点**: 无需额外配置，跨主机网络兼容性好
- **缺点**: 有一定的封包/解包开销
- **适用**: 云主机/跨三层网络

### 2. host-gw
```json
"Backend": {
  "Type": "host-gw"
}
```
- **原理**: 直接通过主机路由转发 Pod 流量
- **优点**: 性能最好，延迟最低
- **缺点**: 要求所有节点在同一二层网络
- **适用**: 同一局域网/物理机环境

### 3. ipip
```json
"Backend": {
  "Type": "ipip"
}
```
- **原理**: 使用 IP-in-IP 封装
- **优点**: 兼容性好，适合跨三层网络
- **缺点**: 有一定的性能损耗
- **适用**: 特殊网络环境

### 4. udp（不推荐）
```json
"Backend": {
  "Type": "udp"
}
```
- **原理**: 使用 UDP 封装
- **优点**: 兼容性好
- **缺点**: 性能最差
- **适用**: 仅特殊兼容性需求

### 5. aws-vpc（仅限 AWS）
```json
"Backend": {
  "Type": "aws-vpc"
}
```
- **原理**: 直接将 Pod IP 分配到 AWS VPC 子网
- **优点**: Pod 可以直接访问 AWS VPC 资源
- **缺点**: 仅限 AWS 环境
- **适用**: AWS 云原生集成

## Backend 选择建议

| 环境类型 | 推荐 Backend | 原因 |
|---------|-------------|------|
| 云主机/跨三层网络 | vxlan | 兼容性最好，无需额外配置 |
| 同一局域网/物理机 | host-gw | 性能最佳 |
| 特殊网络环境 | ipip | 兼容性好 |
| AWS 环境 | aws-vpc | 原生集成 |
| 避免使用 | udp | 性能差 |

## 配置示例

### 完整的 net-conf.json 示例
```json
{
  "Network": "10.244.0.0/16",
  "Backend": {
    "Type": "vxlan"
  }
}
```

## 故障排除

### 检查网络配置
```bash
# 检查路由表
ip route show

# 检查网络接口
ip addr show

# 检查 Flannel 状态
kubectl get pods -n kube-flannel

# 查看 Flannel 日志
kubectl logs -n kube-flannel -l app=flannel
```

### 检查 KubeProxy 状态
```bash
# 查看 kube-proxy 配置
kubectl get configmap kube-proxy -n kube-system -o yaml

# 查看 kube-proxy 日志
kubectl logs -n kube-system -l k8s-app=kube-proxy

# 检查 IPVS 规则（如果使用 ipvs 模式）
sudo ipvsadm -L
```

### 常见问题
1. **网段冲突**: 确保 podSubnet 和 serviceSubnet 不与物理网络冲突
2. **Backend 不兼容**: 根据网络环境选择合适的 Backend 类型
3. **节点间通信**: 确保节点间网络连通性
4. **KubeProxy 模式选择**: 生产环境推荐 ipvs，开发测试推荐 iptables

## 相关文件

- `kubeadm.yaml`: 主配置文件
- `containerd-config.toml`: containerd 配置（如需 HTTP 镜像仓库）
- `030-flannel.yaml`: Flannel CNI 插件配置
