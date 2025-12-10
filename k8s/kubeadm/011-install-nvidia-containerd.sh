yum upgrade -y
yum install runc -y


tar Cxzvf /usr/local containerd-2.1.4-linux-amd64.tar.gz


mkdir -p /etc/containerd

cp containerd-nvidia-config.toml  /etc/containerd/config.toml

cp containerd.service /etc/systemd/system/containerd.service

systemctl daemon-reload

systemctl enable containerd

systemctl restart containerd

# https://github.com/TimeBye/kubeadm-ha/issues/85
echo 1 > /proc/sys/fs/may_detach_mounts