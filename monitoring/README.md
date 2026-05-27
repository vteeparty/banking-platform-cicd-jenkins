# Monitoring — Prometheus & Grafana

Local monitoring stack for the Banking Platform microservices using Docker Compose.

---

## What's Included

This directory contains everything needed to run Prometheus and Grafana locally for monitoring Spring Boot microservices.

| File | Purpose |
|------|---------|
| **docker-compose.yml** | Defines Prometheus and Grafana containers, ports, volumes |
| **prometheus.yml** | Configures which services to scrape metrics from |
| **SETUP.md** | Comprehensive step-by-step setup guide (start here!) |
| **QUICK-REFERENCE.md** | Common commands and troubleshooting |
| **application-example.yml** | Example Spring Boot Actuator configuration |
| **pom-dependencies-example.xml** | Required Maven dependencies for metrics |
| **verify-monitoring.sh** | Bash script to verify the setup |
| **verify-monitoring.ps1** | PowerShell script for Windows users |

---

## Quick Start (30 seconds)

### Prerequisites
- Docker & Docker Compose installed
- Spring Boot services with Actuator dependency

### Start monitoring
```bash
cd monitoring
docker-compose up -d
```

### Access
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (login: admin/admin)

### Verify
```bash
# Windows users
./verify-monitoring.ps1

# Linux/Mac users
bash verify-monitoring.sh
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Banking Platform Microservices                         │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Payment    │  │ Transaction  │  │ Notification │  │
│  │   Service    │  │   Service    │  │   Service    │  │
│  │  :8080       │  │  :8081       │  │  :8082       │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                  │          │
│         └─────────────────┼──────────────────┘          │
│                           │                             │
│                /actuator/prometheus                     │
└─────────────────────────────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   Prometheus   │
                    │    :9090       │
                    │   (scraper)    │
                    └────────┬───────┘
                             │
                             │ stores metrics
                             │
                    ┌────────▼────────┐
                    │  Time-Series DB │
                    │  (prometheus-   │
                    │   data volume)  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    Grafana      │
                    │    :3000        │
                    │ (visualization) │
                    └─────────────────┘
```

---

## How It Works

1. **Spring Boot Apps** expose metrics via Spring Boot Actuator at `/actuator/prometheus`
2. **Prometheus** periodically scrapes (reads) metrics from each app
3. **Prometheus** stores metrics in a time-series database (TSDB)
4. **Grafana** queries Prometheus and displays beautiful dashboards

---

## Key Microservices Being Monitored

| Service | Port | Metrics Endpoint |
|---------|------|------------------|
| payment-service | 8080 | http://payment-service:8080/actuator/prometheus |
| transaction-service | 8081 | http://transaction-service:8081/actuator/prometheus |
| notification-service | 8082 | http://notification-service:8082/actuator/prometheus |

All three services are scraped every 30 seconds by Prometheus.

---

## Monitored Metrics

### JVM & System
- Memory usage (heap, non-heap)
- Thread count
- CPU usage
- Garbage collection

### HTTP
- Request count
- Response times
- Error rates
- Status codes

### Spring Boot
- Application startup time
- Configuration properties
- Log messages

### Custom Business Metrics (if defined in app)
- Transaction count
- Payment processing time
- Error rates by type

---

## Next Steps

### 1. Read the Full Setup Guide
```bash
cat SETUP.md
```

### 2. Prepare Your Spring Boot Apps
Add to each microservice's `pom.xml`:
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

### 3. Add Actuator Config
Add to each microservice's `application.yml`:
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

### 4. Start Monitoring
```bash
docker-compose up -d
```

### 5. Verify Setup
```bash
# Windows
.\verify-monitoring.ps1

# Linux/Mac
bash verify-monitoring.sh
```

### 6. Create Dashboards
Log into Grafana and create custom dashboards for your KPIs.

---

## Environment

| Component | Exposed Port | Docker Network |
|-----------|------|-------------|
| Prometheus | 9090 | banking-monitoring |
| Grafana | 3000 | banking-monitoring |

Both containers run in the same Docker network (`banking-monitoring`) so they can communicate via service names (e.g., `prometheus:9090`).

---

## Local vs. Docker Compose Services

### If your Spring Boot services run in Docker Compose
Use service names in `prometheus.yml`:
```yaml
- targets: ['payment-service:8080']
```

### If your Spring Boot services run on your host machine
Use localhost or host.docker.internal:
```yaml
- targets: ['localhost:8080']
# OR for Docker Desktop on Windows/Mac:
- targets: ['host.docker.internal:8080']
```

---

## Troubleshooting

### Services show as DOWN in Prometheus
1. Verify services are running: `curl http://localhost:8080/actuator/prometheus`
2. Update `prometheus.yml` to use correct host/port
3. Restart: `docker-compose restart prometheus`

### No metrics appearing in Grafana
1. Verify Prometheus can reach services (check Targets in http://localhost:9090/targets)
2. Ensure Grafana data source URL is `http://prometheus:9090`
3. Check Spring Boot app logs for Actuator errors

### Port already in use
```bash
# Find process using port 9090
lsof -i :9090  # Linux/Mac
netstat -ano | findstr :9090  # Windows

# Change ports in docker-compose.yml and prometheus.yml
```

See [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for more troubleshooting steps.

---

## Stopping the Stack

```bash
# Stop containers (keep data)
docker-compose stop

# Stop and remove containers (keep data)
docker-compose down

# Stop, remove everything including data
docker-compose down -v
```

---

## Production Considerations

This setup is **local and development-only**. For production:

- ✅ Done: Beginner-friendly local setup
- ❌ Not included: Authentication/Authorization
- ❌ Not included: Persistent storage (external volumes)
- ❌ Not included: Alerting via Slack/Email
- ❌ Not included: High availability (multiple Prometheus instances)
- ❌ Not included: Backup and disaster recovery

---

## References

- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Micrometer Prometheus Registry](https://micrometer.io/docs/registry/prometheus)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)

---

## Support

For issues:
1. Check [QUICK-REFERENCE.md](QUICK-REFERENCE.md) troubleshooting section
2. Review Docker logs: `docker-compose logs -f`
3. Verify endpoints: `curl http://localhost:8080/actuator/prometheus`
4. Check [SETUP.md](SETUP.md) for detailed step-by-step guidance
