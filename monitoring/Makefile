# ============================================================
# Makefile — Monitoring Stack Commands
# ============================================================
#
# Run: make help
# All targets work on Windows (PowerShell), Linux, and Mac.
#
# ============================================================

.PHONY: help up down logs ps verify clean restart test

help:
	@echo "Banking Platform Monitoring — Available Commands"
	@echo ""
	@echo "  make up              Start Prometheus and Grafana (docker-compose up -d)"
	@echo "  make down            Stop containers and remove network (docker-compose down)"
	@echo "  make restart         Restart all containers"
	@echo "  make logs            Show live logs from all containers (docker-compose logs -f)"
	@echo "  make logs-prom       Show Prometheus logs only"
	@echo "  make logs-grafana    Show Grafana logs only"
	@echo "  make ps              Show container status (docker-compose ps)"
	@echo "  make verify          Verify setup (runs verify script)"
	@echo "  make clean           Stop containers and remove volumes (WARNING: deletes data!)"
	@echo "  make test            Test Prometheus and Grafana endpoints"
	@echo "  make help            Show this help message"
	@echo ""

up:
	@echo "Starting Prometheus and Grafana..."
	docker-compose up -d
	@echo "✓ Stack started!"
	@echo ""
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000 (admin/admin)"

down:
	@echo "Stopping monitoring stack..."
	docker-compose down
	@echo "✓ Stack stopped!"

restart:
	@echo "Restarting monitoring stack..."
	docker-compose restart
	@echo "✓ Stack restarted!"

logs:
	docker-compose logs -f

logs-prom:
	docker-compose logs -f prometheus

logs-grafana:
	docker-compose logs -f grafana

ps:
	docker-compose ps

verify:
	@echo "Verifying monitoring setup..."
	@if exist verify-monitoring.ps1 ( \
		powershell -NoProfile -ExecutionPolicy Bypass -File verify-monitoring.ps1 \
	) else if exist verify-monitoring.sh ( \
		bash verify-monitoring.sh \
	) else ( \
		echo "Error: verify script not found" && exit 1 \
	)

clean:
	@echo "WARNING: This will delete all monitoring data!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@timeout /t 5 /nobreak 2>nul || sleep 5
	docker-compose down -v
	@echo "✓ Stack removed and data deleted!"

test:
	@echo "Testing Prometheus endpoint..."
	@curl -s http://localhost:9090/-/healthy > /dev/null && echo "✓ Prometheus is UP" || echo "✗ Prometheus is DOWN"
	@echo ""
	@echo "Testing Grafana endpoint..."
	@curl -s http://localhost:3000/api/health > /dev/null && echo "✓ Grafana is UP" || echo "✗ Grafana is DOWN"
	@echo ""
	@echo "Checking Prometheus targets..."
	@curl -s http://localhost:9090/api/v1/targets | grep -q "up" && echo "✓ Targets found" || echo "✗ No targets"

shell-prometheus:
	docker-compose exec prometheus sh

shell-grafana:
	docker-compose exec grafana bash

# Development targets
dev: up verify
	@echo "✓ Development environment ready!"

stop: down

reset: clean up
	@echo "✓ Stack reset!"
