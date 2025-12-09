# LVS + Keepalived 高可用 Kubernetes API Server

本配置实现基于LVS + Keepalived的Kubernetes API Server高可用负载均衡方案。

## 架构说明

本方案采用LVS + Keepalived实现Kubernetes API Server的高可用性，架构如下：

## 配置文件说明

### 1. keepalived-master.conf
- **用途**: Keepalived Master节点配置
- **优先级**: 110（高优先级）
- **状态**: MASTER
- **VIP**: 10.120.100.100
- **健康检查**: 每3秒检查API Server状态

### 2. keepalived-backup.conf
- **用途**: Keepalived Backup节点配置
- **优先级**: 100（低优先级）
- **状态**: BACKUP
- **VIP**: 10.120.100.100
- **故障转移**: Master节点故障时自动接管

### 3. check_apiserver.sh
- **用途**: API Server健康检查脚本
- **检查频率**: 每3秒
- **检查内容**: 
  - 本地6443端口连通性
  - VIP 10.120.100.100:6443连通性
- **故障处理**: 连续10次失败后降低权重

### 4. realserver.sh
- **用途**: Real Server VIP配置脚本
- **功能**: 在K8s Master节点配置VIP回环地址

### 5. install.sh
- **用途**: 自动安装脚本
- **支持系统**: CentOS/RHEL、Ubuntu/Debian
- **安装内容**: Keepalived、IPVS工具

## 部署步骤

### 1. 环境准备

```bash
# 确保所有节点间网络互通
ping 10.120.100.6
ping 10.120.100.3
ping 10.120.100.5

# 检查6443端口状态
netstat -tlnp | grep 6443
```

### 2. 安装Keepalived

在LVS Master和Backup节点执行：
```bash
# 运行安装脚本
bash install.sh

# 或手动安装（CentOS）
yum install -y keepalived ipvsadm

# 或手动安装（Ubuntu）
apt-get update
apt-get install -y keepalived ipvsadm
```

### 3. 配置LVS Master节点

```bash
# 复制配置文件
cp keepalived-master.conf /etc/keepalived/keepalived.conf
cp check_apiserver.sh /etc/keepalived/
chmod +x /etc/keepalived/check_apiserver.sh

# 启动服务
systemctl enable keepalived
systemctl start keepalived
systemctl status keepalived
```

### 4. 配置LVS Backup节点

```bash
# 复制配置文件
cp keepalived-backup.conf /etc/keepalived/keepalived.conf
cp check_apiserver.sh /etc/keepalived/
chmod +x /etc/keepalived/check_apiserver.sh

# 启动服务
systemctl enable keepalived
systemctl start keepalived
systemctl status keepalived
```

### 5. 配置Real Server（所有K8s Master节点）

在每个K8s Master节点执行：
```bash
# 运行Real Server配置脚本
bash realserver.sh

# 验证VIP配置
ip addr show lo
```

### 6. 更新kubeadm配置

修改kubeadm配置文件，将controlPlaneEndpoint指向VIP：
```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
controlPlaneEndpoint: "10.120.100.100:6443"
```

## 验证部署

### 1. 检查VIP状态
```bash
# 查看VIP绑定情况
ip addr show | grep 10.120.100.100

# 检查VRRP状态
journalctl -u keepalived -f
```

### 2. 测试API Server连通性
```bash
# 测试VIP连通性
curl -k https://10.120.100.100:6443/version

# 测试kubectl连接
kubectl --server=https://10.120.100.100:6443 get nodes
```

### 3. 故障转移测试
```bash
# 在Master节点停止keepalived服务
systemctl stop keepalived

# 检查VIP是否转移到Backup节点
ip addr show | grep 10.120.100.100

# 验证API Server仍可访问
curl -k https://10.120.100.100:6443/version
```

## 监控和日志

### 查看Keepalived日志
```bash
# 实时查看日志
journalctl -u keepalived -f

# 查看历史日志
journalctl -u keepalived --since="1 hour ago"
```

### 查看LVS状态
```bash
# 查看虚拟服务器状态
ipvsadm -ln

# 查看连接状态
ipvsadm -lnc
```

## 故障排除

### 1. VIP无法绑定
- 检查网络接口名称（eth0）是否正确
- 确认防火墙规则允许VRRP协议
- 检查virtual_router_id是否冲突

### 2. 健康检查失败
- 验证check_apiserver.sh脚本权限
- 检查API Server证书配置
- 确认6443端口监听状态

### 3. 故障转移异常
- 检查Master和Backup节点时间同步
- 验证VRRP组播通信
- 调整priority和advert_int参数

## 配置参数说明

| 参数 | 描述 | Master值 | Backup值 |
|------|------|----------|----------|
| state | 节点状态 | MASTER | BACKUP |
| priority | 优先级 | 110 | 100 |
| virtual_router_id | 虚拟路由ID | 51 | 51 |
| advert_int | 广播间隔(秒) | 1 | 1 |
| interface | 网络接口 | eth0 | eth0 |

## 高级配置

### 1. 调整负载均衡算法
在LVS配置中可以使用以下调度算法：
- **rr**: 轮询（默认）
- **wrr**: 加权轮询
- **lc**: 最少连接
- **wlc**: 加权最少连接
- **sh**: 源地址哈希

### 2. 启用认证
```bash
# 在vrrp_instance中添加认证
authentication {
    auth_type PASS
    auth_pass your_password
}
```

### 3. 邮件通知
```bash
# 配置SMTP服务器实现故障邮件通知
smtp_server your.smtp.server
notification_email {
    admin@yourcompany.com
}
```

## 性能优化

1. **调整内核参数**：
   ```bash
   echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
   echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.conf
   sysctl -p
   ```

2. **优化Keepalived参数**：
   - 减少advert_int提高故障检测速度
   - 调整vrrp_garp_interval减少网络抖动

3. **监控资源使用**：
   - CPU使用率
   - 网络带宽
   - 连接数统计

## 注意事项

1. **网络要求**：确保LVS节点间支持组播通信
2. **时间同步**：所有节点必须时间同步
3. **防火墙配置**：开放VRRP协议（IP协议号112）
4. **备份配置**：定期备份Keepalived配置文件
5. **版本兼容性**：确保Keepalived版本支持所使用的特性

## 维护操作

### 计划内维护
```bash
# 优雅切换到Backup节点
systemctl stop keepalived  # 在Master节点执行

# 维护完成后恢复
systemctl start keepalived
```

### 配置更新
```bash
# 重新加载配置
systemctl reload keepalived

# 或重启服务
systemctl restart keepalived
```

---

**版本信息**：
- Keepalived: 2.0+
- Kubernetes: 1.20+
- 操作系统: CentOS 7+, Ubuntu 18.04+

d