# Envoy 动态 Endpoints 管理 Makefile

.PHONY: help list add remove update generate start stop restart status

# 默认目标
help:
	@echo "Envoy 动态 Endpoints 管理工具"
	@echo ""
	@echo "可用命令:"
	@echo "  make list                    - 列出所有 endpoints"
	@echo "  make add ID=xxx ADDR=xxx PORT=xxx - 添加 endpoint"
	@echo "  make remove ID=xxx           - 删除 endpoint"
	@echo "  make update ID=xxx [ADDR=xxx] [PORT=xxx] [WEIGHT=xxx] - 更新 endpoint"
	@echo "  make generate                - 生成新的 Envoy 配置"
	@echo "  make start                   - 启动 Envoy"
	@echo "  make stop                    - 停止 Envoy"
	@echo "  make restart                 - 重启 Envoy"
	@echo "  make status                  - 查看 Envoy 状态"
	@echo ""
	@echo "示例:"
	@echo "  make add ID=master-2 ADDR=192.168.6.150 PORT=6443"
	@echo "  make remove ID=master-2"
	@echo "  make update ID=master-1 ADDR=192.168.6.149 PORT=6443 WEIGHT=200"

# 列出所有 endpoints
list:
	@python3 manage-endpoints.py list

# 添加 endpoint
add:
	@if [ -z "$(ID)" ] || [ -z "$(ADDR)" ] || [ -z "$(PORT)" ]; then \
		echo "Error: 请提供 ID, ADDR 和 PORT 参数"; \
		echo "示例: make add ID=master-2 ADDR=192.168.6.150 PORT=6443"; \
		exit 1; \
	fi
	@python3 manage-endpoints.py add $(ID) $(ADDR) $(PORT) $(if $(WEIGHT),--weight $(WEIGHT),)
	@make generate

# 删除 endpoint
remove:
	@if [ -z "$(ID)" ]; then \
		echo "Error: 请提供 ID 参数"; \
		echo "示例: make remove ID=master-2"; \
		exit 1; \
	fi
	@python3 manage-endpoints.py remove $(ID)
	@make generate

# 更新 endpoint
update:
	@if [ -z "$(ID)" ]; then \
		echo "Error: 请提供 ID 参数"; \
		echo "示例: make update ID=master-1 ADDR=192.168.6.149 PORT=6443"; \
		exit 1; \
	fi
	@python3 manage-endpoints.py update $(ID) $(if $(ADDR),--address $(ADDR),) $(if $(PORT),--port $(PORT),) $(if $(WEIGHT),--weight $(WEIGHT),) $(if $(HEALTHY),--healthy $(HEALTHY),)
	@make generate

# 生成新的 Envoy 配置
generate:
	@python3 manage-endpoints.py generate

# 启动 Envoy
start:
	@if [ ! -f envoy.yaml ]; then \
		echo "Error: envoy.yaml 不存在，请先运行 'make generate'"; \
		exit 1; \
	fi
	@echo "启动 Envoy..."
	@envoy -c envoy.yaml --log-level info &

# 停止 Envoy
stop:
	@echo "停止 Envoy..."
	@pkill -f "envoy -c envoy.yaml" || true

# 重启 Envoy
restart: stop
	@sleep 2
	@make start

# 查看 Envoy 状态
status:
	@echo "Envoy 进程状态:"
	@ps aux | grep "envoy -c envoy.yaml" | grep -v grep || echo "Envoy 未运行"
	@echo ""
	@echo "当前 endpoints 配置:"
	@make list