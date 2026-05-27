# ============================================================
# Quick Reference — Monitoring Commands
# ============================================================

## Docker Compose Commands

# Start the monitoring stack (Prometheus + Grafana)
docker-compose up -d

# View logs
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Stop the stack (keep data)
docker-compose stop

# Stop and remove containers (keep data)
docker-compose down

# Stop and remove everything including volumes (WARNING: deletes data!)
docker-compose down -v

# Check container status
docker-compose ps

# Restart a specific service
docker-compose restart prometheus
docker-compose restart grafana

---

## Accessing Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Prometheus | http://localhost:9090 | None |
| Grafana | http://localhost:3000 | admin/admin |
| Actuator (Payment Service) | http://localhost:8080/actuator/prometheus | None |
| Actuator (Transaction Service) | http://localhost:8081/actuator/prometheus | None |
| Actuator (Notification Service) | http://localhost:8082/actuator/prometheus | None |

---

## Prometheus Queries

### System Metrics
```promql
up                                    # Target status (1=UP, 0=DOWN)
node_cpu_seconds_total               # CPU time by mode
node_memory_MemAvailable_bytes       # Available memory
process_resident_memory_bytes        # Process memory usage
```

### JVM Metrics
```promql
jvm_memory_used_bytes                # Heap memory usage
jvm_memory_max_bytes                 # Heap memory maximum
jvm_threads_live                     # Active thread count
jvm_gc_memory_promoted_bytes_total   # GC promoted bytes
```

### HTTP Metrics
```promql
http_server_requests_seconds_count              # Total requests
http_server_requests_seconds_sum                # Sum of request times
http_server_requests_seconds_bucket             # Request duration histogram
rate(http_server_requests_seconds_count[5m])   # Requests per second
```

### Rate of Change (5-minute window)
```promql
rate(jvm_memory_used_bytes[5m])     # Memory usage trend
rate(http_server_requests_seconds_count[5m])   # Requests per second
```

---

## Grafana Setup

### Add Prometheus Data Source
1. Click **Connections → Data sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Set URL to `http://prometheus:9090`
5. Click **Save & Test**

### Create a Simple Graph
1. Click **+ → Dashboard**
2. Click **Add panel**
3. Select **Prometheus** data source
4. Enter query: `up`
5. Click **Save**

### Create a Gauge Panel
1. Click **+ → Dashboard**
2. Click **Add panel**
3. Select **Prometheus** data source
4. Enter query: `jvm_memory_used_bytes / jvm_memory_max_bytes`
5. Under **Visualization**, select **Gauge**
6. Set **Value** range to 0-1 or 0-100%
7. Click **Save**

---

## Troubleshooting

### Prometheus Targets are DOWN
```bash
# Check if services are running
curl http://localhost:8080/actuator/prometheus

# Edit prometheus.yml to use localhost instead of service names
vi monitoring/prometheus.yml

# Restart Prometheus
docker-compose restart prometheus

# Verify targets
curl http://localhost:9090/api/v1/targets | jq .
```

### Grafana Cannot Connect to Prometheus
```bash
# Verify Prometheus is running
docker-compose ps prometheus

# Use correct URL: http://prometheus:9090 (not localhost)

# Check Prometheus logs
docker-compose logs prometheus
```

### No Metrics in Grafana
```bash
# Verify Actuator endpoint works
curl http://localhost:8080/actuator/prometheus | head -20

# Check application.yml has management endpoints exposed
# Should include: management.endpoints.web.exposure.include: prometheus

# Restart the Spring Boot app
```

### Delete All Data and Start Fresh
```bash
# WARNING: This removes all volumes and data!
docker-compose down -v
docker-compose up -d
```

---

## File Locations

```
monitoring/
├── docker-compose.yml          # Docker Compose configuration
├── prometheus.yml              # Prometheus scrape config
├── SETUP.md                    # Detailed setup guide
├── application-example.yml     # Example Spring Boot config
├── pom-dependencies-example.xml # Required Maven dependencies
├── verify-monitoring.sh        # Bash verification script
└── verify-monitoring.ps1       # PowerShell verification script
```

---

## Performance Tips

1. **Adjust Scrape Interval** (prometheus.yml)
   - Increase from 30s to 60s to reduce storage
   - Decrease from 30s to 15s for faster updates

2. **Increase Memory Limits** (docker-compose.yml)
   - Prometheus: Increase `memory` to 1G for large clusters
   - Grafana: Usually 512M is sufficient

3. **Configure Data Retention** (docker-compose.yml)
   - Add `--storage.tsdb.retention.time=30d` to Prometheus command
   - Default is 15d

---

## Environment-Specific Configurations

### For Host-Based Services (not in Docker Compose)
Edit `prometheus.yml`:
```yaml
- job_name: 'payment-service'
  static_configs:
    - targets: ['localhost:8080']  # Use localhost
    # OR for Docker Desktop on Windows/Mac:
    # - targets: ['host.docker.internal:8080']
```

### For Docker Compose Services
Use service names (already configured):
```yaml
- job_name: 'payment-service'
  static_configs:
    - targets: ['payment-service:8080']  # Use service name
```

---

## Further Reading

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Getting Started](https://grafana.com/docs/grafana/latest/getting-started/)
- [Spring Boot Actuator Guide](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Micrometer Metrics](https://micrometer.io/docs/concepts)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
