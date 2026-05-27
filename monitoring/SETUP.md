# Monitoring Setup — Prometheus & Grafana

A beginner-friendly local monitoring stack for the Banking Platform microservices using Docker Compose.

---

## Overview

| Component | Port | Purpose |
|-----------|------|---------|
| **Prometheus** | 9090 | Scrapes metrics from Spring Boot Actuator endpoints |
| **Grafana** | 3000 | Visualizes metrics collected by Prometheus |

---

## Prerequisites

- **Docker** (v20.10+) and **Docker Compose** (v1.29+)
- Spring Boot microservices with **Actuator** dependency
- Services running and reachable by Prometheus

---

## Quick Start

### 1. Add Actuator Dependency

Ensure each Spring Boot microservice has the actuator dependency in `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### 2. Configure Spring Boot Actuator

Add the following to `application.yml` or `application.properties` in each microservice:

**application.yml:**
```yaml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health,info
  metrics:
    export:
      prometheus:
        enabled: true
```

**application.properties:**
```properties
management.endpoints.web.exposure.include=prometheus,health,info
management.metrics.export.prometheus.enabled=true
```

### 3. Verify Actuator Endpoint

Start a microservice on port 8080 and check the metrics endpoint:

```bash
curl http://localhost:8080/actuator/prometheus
```

You should see Prometheus-formatted metrics (lines starting with `#` are comments, followed by metric lines).

### 4. Start Prometheus & Grafana

Navigate to the `monitoring/` directory and start the stack:

```bash
cd monitoring
docker-compose up -d
```

Check the status:

```bash
docker-compose ps
```

### 5. Update Service Targets (If Running on Host)

If your Spring Boot services are running on your **host machine** (not in Docker Compose), edit `prometheus.yml`:

```yaml
- job_name: 'payment-service'
  static_configs:
    - targets: ['localhost:8080']  # Change from payment-service:8080
```

**Why?** Docker containers can't reach `localhost`; they need the host IP. On **Linux/WSL**, use the host IP; on **Docker Desktop (Windows/Mac)**, use `host.docker.internal`:

```yaml
- targets: ['host.docker.internal:8080']
```

Then restart Prometheus:

```bash
docker-compose restart prometheus
```

---

## Accessing the UIs

### Prometheus

1. Open **http://localhost:9090** in your browser
2. Click **Status → Targets** to verify all services are reachable (green ✓ = UP, red ✗ = DOWN)
3. Try a query: Go to **Graph** and type `up` to see which targets are alive

### Grafana

1. Open **http://localhost:3000** in your browser
2. Log in with **admin / admin**
3. You will be prompted to change the password on first login (optional)
4. Add a **Data Source**:
   - Click **Connections → Data sources**
   - Click **Add data source**
   - Select **Prometheus**
   - Set **URL** to `http://prometheus:9090` (Docker Compose network)
   - Click **Save & Test**

---

## Sample Metrics to Monitor

Once Prometheus starts scraping, you can query these metrics in Grafana:

### JVM Metrics

```promql
jvm_memory_used_bytes          # JVM heap memory usage
jvm_threads_live               # Active thread count
process_cpu_usage              # CPU usage percentage
```

### HTTP Metrics

```promql
http_server_requests_seconds_count     # Total HTTP requests
http_server_requests_seconds_max       # Slowest response time
spring_http_requests_total             # Alternative counter
```

### Custom Business Metrics

If your Spring Boot app defines custom metrics:

```promql
banking_transactions_total             # Total transactions processed
banking_payment_processing_seconds     # Payment processing time
```

---

## Creating a Simple Dashboard

1. In Grafana, click **+ → Dashboard** (or **Dashboards → New dashboard**)
2. Click **Add panel**
3. Select **Prometheus** as the data source
4. In the **Metrics** field, type `up` and press Enter
5. Choose a visualization (Graph, Gauge, Stat, etc.)
6. Click **Save**

---

## Troubleshooting

### Targets show "DOWN" in Prometheus

**Symptom:** http://localhost:9090 → Status → Targets shows red ✗

**Cause:** Prometheus cannot reach the service

**Fix:**
- Verify the service is running on the expected port
- If on host machine, update `prometheus.yml` to use `localhost` or `host.docker.internal`
- Check firewall: `curl http://localhost:8080/actuator/prometheus`

### Grafana cannot connect to Prometheus

**Symptom:** "Failed to query datasource" in Grafana

**Cause:** URL is incorrect or Prometheus is not running

**Fix:**
- In Grafana Data Source settings, use `http://prometheus:9090` (not `localhost`)
- Run `docker-compose ps` to verify Prometheus container is UP
- Restart: `docker-compose restart grafana`

### High memory usage

**Symptom:** Docker processes consume 1GB+

**Cause:** Prometheus or Grafana has no memory limits

**Fix:**
- Edit `docker-compose.yml`
- Uncomment the `deploy.resources.limits` section
- Reduce `memory` values if needed

### Metrics not appearing

**Symptom:** Prometheus scrapes successfully but no metric data in Grafana

**Cause:** Actuator endpoint returns empty or incorrect format

**Fix:**
- Verify Spring Boot app exposes Actuator: `curl http://localhost:8080/actuator/prometheus`
- Check app logs for errors
- Ensure `spring-boot-starter-actuator` and `micrometer-registry-prometheus` are in dependencies

---

## Stopping the Stack

```bash
docker-compose down
```

Data persists in Docker volumes; to also remove data:

```bash
docker-compose down -v
```

---

## Production Considerations (Not Implemented)

- **Authentication:** Prometheus and Grafana have no password protection by default
- **Persistence:** Data is stored locally; consider external storage for production
- **Scaling:** Add a reverse proxy (nginx) and load balancer for multiple Prometheus instances
- **Alerting:** Configure AlertManager for email/Slack notifications
- **Retention:** Adjust `--storage.tsdb.retention.time` in docker-compose.yml

---

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Micrometer Prometheus Registry](https://micrometer.io/docs/registry/prometheus)
