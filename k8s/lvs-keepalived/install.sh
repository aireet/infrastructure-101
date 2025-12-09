#!/bin/bash
# LVS + Keepalived 安装脚本

set -e

echo "开始安装LVS + Keepalived..."

# 检测操作系统
if [[ -f /etc/redhat-release ]]; then
    OS="centos"
elif [[ -f /etc/debian_version ]]; then
    OS="ubuntu"
else
    echo "不支持的操作系统"
    exit 1
fi

# 安装软件包
if [[ $OS == "centos" ]]; then
    yum install -y ipvsadm keepalived
elif [[ $OS == "ubuntu" ]]; then
    apt-get update
    apt-get install -y ipvsadm keepalived
fi

# 加载内核模块
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack_ipv4

# 设置内核模块自启动
cat > /etc/modules-load.d/ipvs.conf << EOF
ip_vs
ip_vs_lc
ip_vs_wlc
ip_vs_rr
ip_vs_wrr
ip_vs_lblc
ip_vs_lblcr
ip_vs_dh
ip_vs_sh
ip_vs_fo
ip_vs_nq
ip_vs_sed
ip_vs_ftp
nf_conntrack_ipv4
EOF

# 创建目录
mkdir -p /etc/keepalived

echo "安装完成！"
echo "请根据节点角色复制相应的配置文件："
echo "  Master节点: cp keepalived-master.conf /etc/keepalived/keepalived.conf"
echo "  Backup节点: cp keepalived-backup.conf /etc/keepalived/keepalived.conf"
echo "  健康检查脚本: cp check_apiserver.sh /etc/keepalived/"
echo "  设置执行权限: chmod +x /etc/keepalived/check_apiserver.sh"