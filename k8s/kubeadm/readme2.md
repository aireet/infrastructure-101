```
[root@localhost kubeadm]# kubectl get nodes
NAME            STATUS     ROLES           AGE   VERSION
192.168.6.149   NotReady   control-plane   38m   v1.28.12

[root@localhost kubeadm]# kubectl get po -A
NAMESPACE      NAME                                    READY   STATUS     RESTARTS   AGE
kube-flannel   kube-flannel-ds-d5q79                   0/1     Init:1/2   0          8s
kube-system    coredns-66f779496c-ggsmf                0/1     Pending    0          37m
kube-system    coredns-66f779496c-qvnbm                0/1     Pending    0          37m
kube-system    etcd-192.168.6.149                      1/1     Running    2          38m
kube-system    kube-apiserver-192.168.6.149            1/1     Running    2          38m
kube-system    kube-controller-manager-192.168.6.149   1/1     Running    0          38m
kube-system    kube-proxy-hq829                        1/1     Running    0          37m
kube-system    kube-scheduler-192.168.6.149            1/1     Running    2          38m

```

在cni就绪之前 node 不是就绪的 coredns是pending的