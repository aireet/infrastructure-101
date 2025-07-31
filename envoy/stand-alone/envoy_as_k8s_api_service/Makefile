

run-envoy:
	/root/envoy-1.35.0-linux-x86_64 -l debug -c ./envoy.yaml

# Systemd service management
install-service:
	sudo cp envoy-k8s-proxy.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable envoy-k8s-proxy.service
	@echo "Service installed and enabled. Use 'make start-service' to start it."

uninstall-service:
	sudo systemctl stop envoy-k8s-proxy.service
	sudo systemctl disable envoy-k8s-proxy.service
	sudo rm /etc/systemd/system/envoy-k8s-proxy.service
	sudo systemctl daemon-reload
	@echo "Service uninstalled."

start-service:
	sudo systemctl start envoy-k8s-proxy.service
	@echo "Service started. Check status with 'make status-service'"

stop-service:
	sudo systemctl stop envoy-k8s-proxy.service
	@echo "Service stopped."

restart-service:
	sudo systemctl restart envoy-k8s-proxy.service
	@echo "Service restarted."

status-service:
	sudo systemctl status envoy-k8s-proxy.service

logs-service:
	sudo journalctl -u envoy-k8s-proxy.service -f

help:
	@echo "Usage:"
	@echo "  make run-envoy         - Start Envoy proxy manually with debug logging"
	@echo ""
	@echo "Systemd Service Management:"
	@echo "  make install-service   - Install and enable systemd service"
	@echo "  make uninstall-service - Stop, disable and remove systemd service"
	@echo "  make start-service     - Start the systemd service"
	@echo "  make stop-service      - Stop the systemd service"
	@echo "  make restart-service   - Restart the systemd service"
	@echo "  make status-service    - Show service status"
	@echo "  make logs-service      - Show service logs (follow mode)"
	@echo ""
	@echo "Configuration:"
	@echo "  - Cluster 1: localhost:6443 -> k8s_cluster1 endpoints"
	@echo "  - Cluster 2: localhost:6444 -> k8s_cluster2 endpoints"
	@echo "  - Admin UI: localhost:10000"
	@echo ""
	@echo "Edit eds_cluster1.yaml and eds_cluster2.yaml to configure your endpoints"