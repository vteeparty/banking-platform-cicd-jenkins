@echo off
REM ============================================================
REM Monitoring Stack Verification Script (Windows PowerShell)
REM ============================================================
REM
REM This script checks if your Prometheus and Grafana setup is
REM working correctly.
REM
REM Usage:
REM   .\verify-monitoring.ps1
REM
REM ============================================================

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Banking Platform Monitoring — Setup Verification" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Check Docker ─────────────────────────────────────
Write-Host "[ 1/5 ] Checking Docker..." -ForegroundColor Yellow
$dockerVersion = docker --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Docker is not installed. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host ""

# ── Step 2: Check if containers are running ──────────────────
Write-Host "[ 2/5 ] Checking if Prometheus and Grafana are running..." -ForegroundColor Yellow

$prometheusRunning = docker ps --filter "name=prometheus" --format "{{.Names}}" 2>&1
if ($prometheusRunning -match "prometheus") {
    Write-Host "✓ Prometheus container is running" -ForegroundColor Green
} else {
    Write-Host "❌ Prometheus container is not running." -ForegroundColor Red
    Write-Host "   Start with: cd monitoring; docker-compose up -d" -ForegroundColor Red
    exit 1
}

$grafanaRunning = docker ps --filter "name=grafana" --format "{{.Names}}" 2>&1
if ($grafanaRunning -match "grafana") {
    Write-Host "✓ Grafana container is running" -ForegroundColor Green
} else {
    Write-Host "❌ Grafana container is not running." -ForegroundColor Red
    Write-Host "   Start with: cd monitoring; docker-compose up -d" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ── Step 3: Check Prometheus web UI ──────────────────────────
Write-Host "[ 3/5 ] Checking Prometheus web UI (http://localhost:9090)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9090/-/healthy" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Prometheus is responding" -ForegroundColor Green
} catch {
    Write-Host "❌ Prometheus is not responding on port 9090." -ForegroundColor Red
    Write-Host "   Check: docker-compose logs prometheus" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ── Step 4: Check Grafana web UI ────────────────────────────
Write-Host "[ 4/5 ] Checking Grafana web UI (http://localhost:3000)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Grafana is responding" -ForegroundColor Green
} catch {
    Write-Host "❌ Grafana is not responding on port 3000." -ForegroundColor Red
    Write-Host "   Check: docker-compose logs grafana" -ForegroundColor Red
    exit 1
}
Write-Host ""

# ── Step 5: Check Prometheus targets ─────────────────────────
Write-Host "[ 5/5 ] Checking Prometheus scrape targets..." -ForegroundColor Yellow
try {
    $targetsJson = Invoke-WebRequest -Uri "http://localhost:9090/api/v1/targets" -TimeoutSec 5 | ConvertFrom-Json
    $upCount = ($targetsJson.data.activeTargets | Where-Object { $_.health -eq "up" } | Measure-Object).Count
    $downCount = ($targetsJson.data.activeTargets | Where-Object { $_.health -eq "down" } | Measure-Object).Count
    
    Write-Host "✓ Prometheus targets: $upCount UP, $downCount DOWN" -ForegroundColor Green
    
    if ($downCount -gt 0) {
        Write-Host ""
        Write-Host "⚠️  WARNING: Some targets are DOWN." -ForegroundColor Yellow
        Write-Host "   • Ensure Spring Boot microservices are running" -ForegroundColor Yellow
        Write-Host "   • If services are on your host machine:" -ForegroundColor Yellow
        Write-Host "     - Edit monitoring\prometheus.yml" -ForegroundColor Yellow
        Write-Host "     - Replace service names with 'localhost' or 'host.docker.internal'" -ForegroundColor Yellow
        Write-Host "   • View all targets: http://localhost:9090/targets" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Could not retrieve targets from Prometheus" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "✓ Setup Verification Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open Prometheus: http://localhost:9090" -ForegroundColor Cyan
Write-Host "  2. Open Grafana:    http://localhost:3000 (admin/admin)" -ForegroundColor Cyan
Write-Host "  3. Add Prometheus as a data source in Grafana:" -ForegroundColor Cyan
Write-Host "     Data Source URL: http://prometheus:9090" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
