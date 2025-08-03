#!/bin/bash
set -e

# 🎨 日志颜色和 emoji 函数
log_info() {
    echo -e "ℹ️  [INFO] $1"
}

log_success() {
    echo -e "✅ [SUCCESS] $1"
}

log_warning() {
    echo -e "⚠️  [WARNING] $1"
}

log_error() {
    echo -e "❌ [ERROR] $1"
}

log_step() {
    echo -e "🚀 [STEP] $1"
}


# 🔧 设置全局 PATH 环境变量
log_step "配置全局 PATH 环境变量..."
# 检查 /usr/bin 是否已在 PATH 中
if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
    log_info "将 /usr/bin 添加到全局 PATH 中..."
    
    # 添加到 /etc/profile
    if ! grep -q "/usr/bin" /etc/profile; then
        echo 'export PATH="/usr/bin:$PATH"' >> /etc/profile
        log_success "已添加到 /etc/profile"
    fi
    
    # 添加到当前会话
    export PATH="/usr/bin:$PATH"
    log_success "已添加到当前会话"
else
    log_info "/usr/bin 已在 PATH 中，无需添加"
fi

# 🎯 版本定义
K8S_VERSION=1.28
K8S_CNI_VERSION=1.2.0
CRI_TOOLS_VERSION=1.28.0
KUBECTL_VERSION=1.28.0
KUBELET_VERSION=1.28.12

# 🌐 下载地址前缀
BASE_URL="https://mirrors.aliyun.com/kubernetes-new/core/stable/v${K8S_VERSION}/rpm/x86_64"

# 📦 需要安装的包及其版本（保持顺序）
PKG_NAMES=(
  kubernetes-cni
  cri-tools
  kubectl
  kubelet
  kubeadm
)

declare -A PKG_VERSIONS=(
  [kubernetes-cni]="${K8S_CNI_VERSION}-150500.2.1"
  [cri-tools]="${CRI_TOOLS_VERSION}-150500.1.1"
  [kubectl]="${KUBECTL_VERSION}-150500.1.1"
  [kubelet]="${KUBELET_VERSION}-150500.1.1"
  [kubeadm]="${KUBELET_VERSION}-150500.1.1"
)

# 🔍 检查 yum 是否可用
log_step "检查系统环境..."
if ! command -v yum &>/dev/null; then
    log_error "yum 未找到。此脚本适用于 CentOS/RHEL 系统。"
    exit 1
fi
log_success "系统环境检查通过"

# 📥 下载并安装 rpm 包
log_step "开始下载和安装 Kubernetes 组件..."
for pkg in "${PKG_NAMES[@]}"; do
    rpm_file="${pkg}-${PKG_VERSIONS[$pkg]}.x86_64.rpm"
    url="${BASE_URL}/${rpm_file}"
    
    log_info "正在下载 ${pkg}..."
    if ! wget -q "$url"; then
        log_error "下载失败: $url"
        exit 2
    fi
    log_success "下载完成: ${pkg}"
    
    log_info "正在安装 ${pkg}..."
    if ! yum install -y "$rpm_file"; then
        log_error "安装失败: ${pkg}"
        exit 3
    fi
    log_success "安装完成: ${pkg}"
    
    # 🧹 清理临时文件
    rm -f "$rpm_file"
    log_info "清理临时文件: ${rpm_file}"
done

# 🔧 安装 conntrack
log_step "安装网络工具..."
log_info "正在安装 conntrack..."
if yum install -y conntrack; then
    log_success "conntrack 安装完成"
else
    log_warning "conntrack 安装失败，但继续执行"
fi

# 🚀 启动并设置 kubelet 开机自启
log_step "配置 kubelet 服务..."
log_info "启用并启动 kubelet 服务..."
if systemctl enable --now kubelet; then
    log_success "kubelet 服务启动成功"
else
    log_error "kubelet 服务启动失败"
    exit 4
fi

# 🎉 完成提示
echo ""
log_success "🎉 Kubernetes 组件安装完成！"
log_info "📋 已安装的组件:"
echo "   • kubernetes-cni: ${K8S_CNI_VERSION}"
echo "   • cri-tools: ${CRI_TOOLS_VERSION}"
echo "   • kubectl: ${KUBECTL_VERSION}"
echo "   • kubelet: ${KUBELET_VERSION}"
echo "   • kubeadm: ${KUBELET_VERSION}"
echo ""
log_info "🔗 下一步: 运行 kubeadm init 初始化集群"


