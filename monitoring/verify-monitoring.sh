#!/bin/bash
# ============================================================
# Monitoring Stack Verification Script
# ============================================================
#
# This script checks if your Prometheus and Grafana setup is
# working correctly.
#
# Usage:
#   ./verify-monitoring.sh
#
# ============================================================

set -e  # Exit on error

echo "================================================================"
echo "Banking Platform Monitoring — Setup Verification"
echo "================================================================"
echo ""

# ── Step 1: Check Docker and Docker Compose ──────────────────
echo "[ 1/5 ] Checking Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop."
    exit 1
fi
echo "✓ Docker found: $(docker --version)"

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose."
    exit 1
fi
echo "✓ Docker Compose found: $(docker-compose --version)"
echo ""

# ── Step 2: Check if containers are running ──────────────────
echo "[ 2/5 ] Checking if Prometheus and Grafana are running..."
if ! docker ps | grep -q prometheus; then
    echo "❌ Prometheus container is not running."
    echo "   Start with: cd monitoring && docker-compose up -d"
    exit 1
fi
echo "✓ Prometheus container is running"

if ! docker ps | grep -q grafana; then
    echo "❌ Grafana container is not running."
    echo "   Start with: cd monitoring && docker-compose up -d"
    exit 1
fi
echo "✓ Grafana container is running"
echo ""

# ── Step 3: Check Prometheus web UI ──────────────────────────
echo "[ 3/5 ] Checking Prometheus web UI (http://localhost:9090)..."
if curl -s http://localhost:9090/-/healthy &> /dev/null; then
    echo "✓ Prometheus is responding"
else
    echo "❌ Prometheus is not responding on port 9090."
    echo "   Check: docker-compose logs prometheus"
    exit 1
fi
echo ""

# ── Step 4: Check Grafana web UI ────────────────────────────
echo "[ 4/5 ] Checking Grafana web UI (http://localhost:3000)..."
if curl -s http://localhost:3000/api/health &> /dev/null; then
    echo "✓ Grafana is responding"
else
    echo "❌ Grafana is not responding on port 3000."
    echo "   Check: docker-compose logs grafana"
    exit 1
fi
echo ""

# ── Step 5: Check Prometheus targets ─────────────────────────
echo "[ 5/5 ] Checking Prometheus scrape targets..."
TARGETS=$(curl -s http://localhost:9090/api/v1/targets | grep -o '"state":"[^"]*"')
UP_COUNT=$(echo "$TARGETS" | grep -c "up" || true)
DOWN_COUNT=$(echo "$TARGETS" | grep -c "down" || true)

echo "✓ Prometheus targets: $UP_COUNT UP, $DOWN_COUNT DOWN"

if [ "$DOWN_COUNT" -gt 0 ]; then
    echo ""
    echo "⚠️  WARNING: Some targets are DOWN."
    echo "   • Ensure Spring Boot microservices are running"
    echo "   • If services are on your host machine:"
    echo "     - Edit monitoring/prometheus.yml"
    echo "     - Replace service names with 'localhost' or 'host.docker.internal'"
    echo "   • View all targets: http://localhost:9090/targets"
fi
echo ""

echo "================================================================"
echo "✓ Setup Verification Complete!"
echo ""
echo "Next steps:"
echo "  1. Open Prometheus: http://localhost:9090"
echo "  2. Open Grafana:    http://localhost:3000 (admin/admin)"
echo "  3. Add Prometheus as a data source in Grafana:"
echo "     Data Source URL: http://prometheus:9090"
echo "================================================================"
