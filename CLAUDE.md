# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an infrastructure reference/tutorial repository covering Kubernetes cluster setup, service mesh (Istio/Envoy), and high-availability patterns. It contains shell scripts, YAML configs, and documentation — no application code or build system.

## Repository Structure

- `k8s/kubeadm/` — Scripts and configs for bootstrapping a K8s cluster with kubeadm. Numbered scripts (000–011) run in order on each node.
- `k8s/lvs-keepalived/` — LVS + Keepalived HA setup for the K8s API server VIP.
- `istio/` — IstioOperator manifests and gateway configs for a production service mesh deployment.
- `envoy/` — Envoy proxy tutorials: static config (k8s api-server load balancing) and dynamic XDS control plane.

## Key Architectural Decisions

**K8s cluster setup sequence:**
1. `000-init_network.sh` — kernel/network prerequisites
2. `001-install-containerd.sh` — installs containerd 2.1.4 from the bundled tarball (`containerd-2.1.4-linux-amd64.tar.gz`)
3. `002-install-kubeadm.sh` — installs kubeadm/kubelet/kubectl
4. `011-install-nvidia-containerd.sh` — GPU node setup (optional)
5. Apply `kubeadm.yaml` to init the control plane

**Networking defaults in `kubeadm.yaml`:**
- podSubnet: `172.31.0.0/16`, serviceSubnet: `172.32.0.0/16`
- KubeProxy mode: `ipvs`
- CNI: Flannel with vxlan backend (`030-vxlan-flannel.yaml`) or standard (`030-flannel.yaml`)

**Istio deployment** uses `istioctl` with `IstioOperator` manifests. Three separate ingress gateways are defined (HTTP, gRPC, WebSocket), all in the `ingress-istio` namespace, deployed only to nodes labeled `echolab/ingress: enabled`. Service discovery is scoped to namespaces labeled `istio-discovery: enabled`.

**Envoy** is downloaded directly from GitHub releases (see `envoy/Makefile`):
```bash
make download  # fetches envoy-1.35.0-linux-x86_64
```

## Common Commands

### Istio
```bash
# Validate manifest
istioctl manifest generate -f istio/cluster_01.yaml

# Install/upgrade
istioctl install -f istio/cluster_01.yaml
istioctl upgrade -f istio/cluster_01.yaml

# Verify
istioctl verify-install
istioctl analyze -f istio/cluster_01.yaml
```

### K8s cluster bootstrap (run on each node as root)
```bash
bash k8s/kubeadm/000-init_network.sh
bash k8s/kubeadm/001-install-containerd.sh
bash k8s/kubeadm/002-install-kubeadm.sh
# Then on control plane:
kubeadm init --config k8s/kubeadm/kubeadm.yaml
```

### LVS + Keepalived HA
```bash
bash k8s/lvs-keepalived/install.sh          # on LVS nodes
bash k8s/lvs-keepalived/realserver.sh       # on each K8s master
```
