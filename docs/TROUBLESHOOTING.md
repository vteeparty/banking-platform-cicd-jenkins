# Troubleshooting Guide

Common issues encountered when running the Banking Platform Jenkins environment locally.

---

## 1. Jenkins container fails to start

**Symptom:** `docker run` exits immediately or `docker ps` shows the container as `Exited`.

**Diagnosis:**
```bash
docker logs jenkins-banking
```

**Common causes and fixes:**

| Log message | Fix |
|-------------|-----|
| `Permission denied` on `/var/jenkins_home` | Run `docker volume rm jenkins-banking-home` then recreate with `docker volume create jenkins-banking-home` |
| `Port 8080 already in use` | Stop whatever is using port 8080: `netstat -ano \| findstr :8080` (Windows) or `lsof -i :8080` (macOS/Linux), then stop that process |
| `Address already in use` on port 50000 | Add `--publish 50001:50000` and adjust your agent config |

---

## 2. Cannot retrieve the initial admin password

**Symptom:** `docker exec jenkins-banking cat /var/jenkins_home/secrets/initialAdminPassword` returns an error.

**Fixes:**
- Wait 30–60 seconds after starting the container for Jenkins to fully initialise, then retry.
- Check that the container is actually running: `docker ps --filter "name=jenkins-banking"`
- If the container has exited, check logs: `docker logs jenkins-banking`

---

## 3. Jenkins UI is not accessible at http://localhost:8080

**Checks:**
1. Confirm the container is running: `docker ps`
2. Confirm port mapping: `docker inspect jenkins-banking --format '{{json .NetworkSettings.Ports}}'`
3. On Windows, ensure Docker Desktop is running (system tray icon).
4. Try `http://127.0.0.1:8080` instead of `localhost` if DNS resolution differs.
5. Temporarily disable your firewall / antivirus to rule out port blocking.

---

## 4. Plugin installation fails or hangs

**Symptom:** Plugins show "Failed" status or the plugin manager spins indefinitely.

**Fixes:**
- Go to **Manage Jenkins → Plugin Manager → Advanced** and click **Check now** to refresh the update centre.
- If behind a corporate proxy, configure it under **Manage Jenkins → Manage Plugins → Advanced → HTTP Proxy Configuration**.
- Restart Jenkins after a failed install: `docker restart jenkins-banking`
- If a specific plugin repeatedly fails, download the `.hpi` file manually from https://plugins.jenkins.io and upload via **Advanced → Deploy Plugin**.

---

## 5. Docker socket permission denied inside a pipeline

**Symptom:**
```
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
```

**Fix (Linux / macOS):**
```bash
# Find the docker group GID on the host
getent group docker | cut -d: -f3   # e.g. 993

# Re-run the container with the matching group
docker run --detach \
  --name jenkins-banking \
  --restart unless-stopped \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --group-add 993 \
  --volume jenkins-banking-home:/var/jenkins_home \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17
```

**Fix (Windows Docker Desktop):** The Docker socket is exposed over a named pipe. Use the `docker:dind` sidecar pattern or run builds on a Linux WSL2 agent instead.

---

## 6. SonarQube quality gate times out

**Symptom:** Pipeline hangs at `waitForQualityGate` for more than 5 minutes.

**Fixes:**
- Ensure the SonarQube webhook is configured: **SonarQube → Administration → Webhooks → Create** with URL `http://host.docker.internal:8080/sonarqube-webhook/`.
- Verify the Jenkins SonarQube server name in **Manage Jenkins → System** matches the name used in `withSonarQubeEnv('SonarQube-Local')`.
- Increase the timeout in `commonPipeline.enforceQualityGate(10)` for slow analysis runs.

---

## 7. Git checkout fails with SSL or authentication error

**Symptom:**
```
fatal: unable to access 'https://...': SSL certificate problem
```
or
```
Authentication failed for 'https://...'
```

**Fixes:**
- Add a valid **Username/Password** or **SSH Key** credential in **Jenkins → Manage Credentials** and reference it in the pipeline SCM configuration.
- For self-signed certificates, add the certificate to the JVM trust store inside the container:
  ```bash
  docker exec -u root jenkins-banking \
    keytool -import -trustcacerts -alias internal-ca \
    -file /path/to/ca.crt \
    -keystore $JAVA_HOME/lib/security/cacerts \
    -storepass changeit -noprompt
  ```

---

## 8. OutOfMemoryError / Jenkins becomes unresponsive

**Symptom:** Builds fail with `java.lang.OutOfMemoryError: Java heap space` or the UI freezes.

**Fix:** Increase the JVM heap by passing `JAVA_OPTS`:
```bash
docker stop jenkins-banking
docker rm jenkins-banking

docker run --detach \
  --name jenkins-banking \
  --restart unless-stopped \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --env JAVA_OPTS="-Xmx2g -Xms512m -XX:+UseG1GC" \
  --volume jenkins-banking-home:/var/jenkins_home \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17
```

> The volume is preserved — all jobs and configuration remain intact.

---

## 9. Shared library not found

**Symptom:**
```
org.codehaus.groovy.control.MultipleCompilationErrorsException:
  unable to resolve class commonPipeline
```

**Fix:**
1. Go to **Manage Jenkins → System → Global Pipeline Libraries**.
2. Add a library entry:
   - **Name:** `banking-shared-library`
   - **Default version:** `main`
   - **Source:** Git → URL of this repository
   - **Load implicitly:** optional
3. Ensure pipelines that use it declare `@Library('banking-shared-library') _` at the top.

---

## 10. Reset Jenkins completely

> **Warning:** This deletes all jobs, credentials, and build history.

```bash
docker stop jenkins-banking
docker rm jenkins-banking
docker volume rm jenkins-banking-home
```

Then follow the [SETUP.md](SETUP.md) Quick Start from step 1.
