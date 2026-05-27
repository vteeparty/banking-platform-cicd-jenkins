# ============================================================
# MONITORING SETUP — COMPLETE READY-TO-START GUIDE
# ============================================================
#
# This document walks you through starting the complete
# monitoring stack for the Banking Platform.
#
# ============================================================

## ✅ SETUP STATUS: COMPLETE

All files have been created and configured. Here's what you have:

```
monitoring/
├── docker-compose.yml              ← Main configuration
├── prometheus.yml                  ← Scrape targets
├── provisioning/
│   ├── datasources/
│   │   └── prometheus.yml          ← Auto-configures Prometheus data source
│   └── dashboards/
│       ├── dashboards.yml          ← Loads dashboards automatically
│       ├── banking-platform-metrics.json    ← Service metrics dashboard
│       └── banking-platform-jvm.json        ← JVM metrics dashboard
├── SETUP.md                        ← Detailed guide
├── QUICK-REFERENCE.md              ← Commands & troubleshooting
├── README.md                       ← Overview
├── verify-monitoring.ps1           ← Windows verification
├── verify-monitoring.sh            ← Linux/Mac verification
├── Makefile                        ← Convenient commands
└── [other config files...]
```

---

## 🚀 STEP 1: Verify Docker is Installed

Open PowerShell or Terminal and run:

```bash
docker --version
```

**Expected output:**
```
Docker version 20.10.x or higher
```

**If Docker is not installed:**
- Download Docker Desktop from https://www.docker.com/products/docker-desktop
- Install and restart your machine
- Verify again with `docker --version`

---

## 🚀 STEP 2: Start the Monitoring Stack

Navigate to the monitoring directory:

```bash
cd "c:\Users\meghareddy\OneDrive\Desktop\Pavan teeparthy\banking-platform-cicd-jenkins\monitoring"
```

Start Prometheus and Grafana:

```bash
docker compose up -d
```

**Expected output:**
```
[+] Running 3/3
 ✓ Network banking-monitoring  Created
 ✓ Container prometheus        Started
 ✓ Container grafana           Started
```

---

## 🚀 STEP 3: Verify Everything is Running

### Option A: PowerShell (Windows)

```bash
.\verify-monitoring.ps1
```

### Option B: Bash (Linux/Mac)

```bash
bash verify-monitoring.sh
```

### Option C: Docker Check

```bash
docker compose ps
```

**Expected output:**
```
NAME         IMAGE                        STATUS          PORTS
prometheus   prom/prometheus:latest       Up 1 minute     0.0.0.0:9090->9090/tcp
grafana      grafana/grafana:latest       Up 1 minute     0.0.0.0:3000->3000/tcp
```

---

## 🚀 STEP 4: Access the Web UIs

### Prometheus (Metrics Storage & Querying)

Open your browser and go to: **http://localhost:9090**

**What you'll see:**
- Top navigation with "Graph", "Targets", "Alerts"
- Empty graphs (no data yet because no services are being scraped)

**Check Target Status:**
1. Click **Status** → **Targets**
2. You should see:
   - `prometheus` → UP (self-monitoring)
   - `payment-service` → DOWN (not running yet - that's normal)
   - `transaction-service` → DOWN (not running yet - that's normal)
   - `notification-service` → DOWN (not running yet - that's normal)

### Grafana (Dashboards & Visualization)

Open your browser and go to: **http://localhost:3000**

**Login:**
- Username: `admin`
- Password: `admin`

**First time only:** You'll be prompted to change the password (optional, skip if you want)

**Verify Dashboards Are Loaded:**
1. Click **Dashboards** (left sidebar)
2. You should see two pre-configured dashboards:
   - **Banking Platform — Service Metrics** (HTTP, requests, errors)
   - **Banking Platform — JVM & System Metrics** (Memory, CPU, GC)

**Verify Data Source is Connected:**
1. Click **Connections** → **Data sources** (left sidebar)
2. You should see **Prometheus** listed
3. Click it and verify the URL is `http://prometheus:9090`
4. Click **Save & Test** → you should see **Data source is working**

---

## 📊 STEP 5: Configure Your Spring Boot Services

For each microservice (payment, transaction, notification):

### A. Add Dependencies to pom.xml

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

See: `monitoring/pom-dependencies-example.xml`

### B. Add Configuration to application.yml

```yaml
server:
  port: 8080  # payment-service
  # OR 8081 for transaction-service
  # OR 8082 for notification-service

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

See: `monitoring/application-example.yml`

### C. Verify the Endpoint Works

Start your Spring Boot app and run:

```bash
curl http://localhost:8080/actuator/prometheus
```

You should see Prometheus-formatted metrics (lines starting with `#` followed by metric lines).

---

## 🚀 STEP 6: Start Your Microservices

Start each service on the correct port:

```bash
# Terminal 1: Payment Service (port 8080)
java -jar payment-service.jar --server.port=8080

# Terminal 2: Transaction Service (port 8081)
java -jar transaction-service.jar --server.port=8081

# Terminal 3: Notification Service (port 8082)
java -jar notification-service.jar --server.port=8082
```

**OR if using Maven:**

```bash
# Terminal 1
mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=8080"

# Terminal 2
mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=8081"

# Terminal 3
mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=8082"
```

---

## 🚀 STEP 7: Verify Prometheus is Scraping

After services start (wait 1-2 minutes for Prometheus to scrape):

1. Open http://localhost:9090
2. Click **Status** → **Targets**
3. All services should now show as **UP** (green)
4. Click any service to see scrape details

---

## 📊 STEP 8: View Dashboards in Grafana

1. Open http://localhost:3000
2. Click **Dashboards** (left sidebar)
3. Click **Banking Platform — Service Metrics**
4. You should see:
   - Service status (1=UP, 0=DOWN)
   - JVM memory gauge
   - HTTP request rates
   - Response times
   - Error rates
   - Thread counts

---

## 🛠️ USEFUL COMMANDS

### View Logs

```bash
# All containers
docker compose logs -f

# Prometheus only
docker compose logs -f prometheus

# Grafana only
docker compose logs -f grafana
```

### Stop the Stack (keep data)

```bash
docker compose stop
```

### Start the Stack Again

```bash
docker compose start
```

### Stop and Remove Everything (keep data)

```bash
docker compose down
```

### Delete Everything Including Data

```bash
docker compose down -v
```

### Using Makefile Commands (if available)

```bash
make up          # Start
make logs        # View logs
make verify      # Verify setup
make restart     # Restart
make down        # Stop
make clean       # Stop and delete data
make test        # Test endpoints
```

---

## 📊 SAMPLE QUERIES IN PROMETHEUS

After services start, try these queries in Prometheus (http://localhost:9090 → Graph tab):

### Service Status
```promql
up{job=~"payment-service|transaction-service|notification-service"}
```

### Request Rate (5-minute average)
```promql
rate(http_server_requests_seconds_count[5m])
```

### Memory Usage
```promql
jvm_memory_used_bytes / jvm_memory_max_bytes
```

### HTTP Error Rate
```promql
rate(http_server_requests_seconds_count{status=~"5.."}[5m])
```

---

## ⚠️ TROUBLESHOOTING

### Services show DOWN in Prometheus

**Problem:** Status → Targets shows all services as DOWN (red)

**Solution:**
1. Verify Spring Boot services are running: `curl http://localhost:8080/actuator/prometheus`
2. Check service ports: payment (8080), transaction (8081), notification (8082)
3. Verify network: `docker network ls` (should see `banking-monitoring`)
4. If running on host, update `prometheus.yml` to use `localhost` instead of service names
5. Restart Prometheus: `docker compose restart prometheus`

### Grafana shows "Failed to query datasource"

**Problem:** Dashboard shows red error

**Solution:**
1. Verify Prometheus is running: `docker compose ps`
2. Click **Connections** → **Data sources** → **Prometheus**
3. Verify URL is `http://prometheus:9090` (NOT `localhost`)
4. Click **Save & Test**
5. Restart Grafana: `docker compose restart grafana`

### No metrics appearing in dashboards

**Problem:** Dashboards are empty even though services are UP

**Solution:**
1. Wait 2-3 minutes for first scrape cycle
2. Verify Prometheus scraped data: http://localhost:9090 → Graph tab
3. Try a simple query: `up` should show results
4. Check service logs for Actuator errors
5. Verify `/actuator/prometheus` endpoint returns data

### Port 9090 or 3000 already in use

**Problem:** `docker compose up` fails with "port already in use"

**Solution:**
1. Find what's using the port:
   ```bash
   netstat -ano | findstr :9090  # Windows
   lsof -i :9090                  # Linux/Mac
   ```
2. Stop the other process OR
3. Edit `docker-compose.yml` to use different ports:
   ```yaml
   prometheus:
     ports:
       - "9191:9090"  # Change 9090 to 9191
   grafana:
     ports:
       - "3001:3000"  # Change 3000 to 3001
   ```

### Docker not found

**Problem:** `docker: command not found` or `not recognized`

**Solution:**
1. Docker is not installed or not in PATH
2. Download and install Docker Desktop: https://www.docker.com/products/docker-desktop
3. Restart your terminal/PowerShell
4. Verify: `docker --version`

---

## 📖 ADDITIONAL RESOURCES

- [SETUP.md](SETUP.md) — Comprehensive setup guide
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) — Commands, queries, tips
- [application-example.yml](application-example.yml) — Spring Boot config template
- [pom-dependencies-example.xml](pom-dependencies-example.xml) — Maven dependencies
- [alert-rules-example.yml](alert-rules-example.yml) — Optional alerting rules

---

## ✅ CHECKLIST

- [ ] Docker is installed (`docker --version` works)
- [ ] `docker compose up -d` succeeds with all containers running
- [ ] Prometheus is accessible at http://localhost:9090
- [ ] Grafana is accessible at http://localhost:3000
- [ ] Can log into Grafana (admin/admin)
- [ ] Prometheus data source shows as "connected" in Grafana
- [ ] Spring Boot services have Actuator dependency
- [ ] Spring Boot services have Actuator config (management.endpoints)
- [ ] Spring Boot services are running on ports 8080, 8081, 8082
- [ ] Prometheus targets show services as UP (wait 1-2 minutes)
- [ ] Grafana dashboards show data from services

---

**Everything is ready! Follow the steps above to get monitoring up and running.** 🚀
