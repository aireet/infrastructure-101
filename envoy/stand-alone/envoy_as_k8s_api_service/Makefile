

run-envoy:
	/root/envoy-1.35.0-linux-x86_64 -l debug -c ./envoy.yaml

help:
	@echo "Usage:"
	@echo "  make run-envoy    - Start Envoy proxy with debug logging"
	@echo ""
	@echo "Configuration:"
	@echo "  - Cluster 1: localhost:6443 -> k8s_cluster1 endpoints"
	@echo "  - Cluster 2: localhost:6444 -> k8s_cluster2 endpoints"
	@echo "  - Admin UI: localhost:10000"
	@echo ""
	@echo "Edit eds_cluster1.yaml and eds_cluster2.yaml to configure your endpoints"