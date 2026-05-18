# Banking Platform — Pipeline Security Policy

**Version:** 1.0  
**Last reviewed:** 2026-05-18  
**Owner:** DevOps / Security Team

---

## 1. Purpose

This document defines the mandatory security controls that every CI/CD pipeline
in the banking platform must satisfy before a build artefact is promoted to any
environment.

---

## 2. Credentials Management

| Rule | Requirement |
|------|-------------|
| **No plain-text secrets** | All passwords, tokens, and API keys must be stored as Jenkins Credentials (Secret Text or Username/Password kind). |
| **Credential binding** | Use `credentials()` or `withCredentials()` in pipelines. Never echo or print credential values. |
| **Least privilege** | Each pipeline credential must be scoped to the minimum required permissions. |
| **Rotation** | Credentials must be rotated every 90 days and immediately upon suspected compromise. |

---

## 3. Dependency Vulnerability Scanning

- **Tool:** OWASP Dependency Check (`security/dependency-check-config.xml`)
- **Threshold:** Builds with a CVSS score ≥ 7.0 (HIGH or CRITICAL) **must fail**.
- **Suppressions:** Any suppressed CVE requires a business justification comment in
  `dependency-check-config.xml` and must be reviewed within 30 days.
- **NVD API Key:** Configure `NVD_API_KEY` as a Jenkins secret to avoid rate limiting.

---

## 4. Static Code Analysis (SonarQube)

- **Quality Gate:** The default *Sonar way* gate is the minimum baseline.
- **Banking gate additions** (configure in the SonarQube server UI):
  - Code coverage ≥ 80 %
  - No new blocker or critical issues
  - Security hotspots reviewed = 0 unresolved
- Pipelines must call `waitForQualityGate(abortPipeline: true)` so a failing gate
  stops the build automatically.
- Configuration: `security/sonarqube-config.properties`

---

## 5. Docker Image Security

| Rule | Requirement |
|------|-------------|
| **Base image** | Use only official, LTS-tagged base images (e.g. `eclipse-temurin:21-jre-alpine`). |
| **No root** | The container process must not run as UID 0. Add `USER nonroot` in the Dockerfile. |
| **Image scanning** | Scan images with Trivy or Docker Scout before pushing to the registry. |
| **Registry** | Only push to the approved internal registry. Public push requires security approval. |

---

## 6. Branch & Merge Controls

- All code merged to `main` must pass:
  1. At least one peer code review approval.
  2. The full CI pipeline (compile → test → SonarQube → dependency check).
- Direct push to `main` is prohibited. Use pull requests only.

---

## 7. Pipeline Script Safety

- Shared-library code in `shared-library/vars/` is the only trusted execution context.
- `@NonCPS` annotations must be used only where required (non-serialisable objects).
- Avoid `sh("... ${userInput} ...")` patterns — always validate or escape external input
  to prevent shell injection.

---

## 8. Audit & Compliance

- Jenkins build logs are retained for **30 days** (configured via log rotation).
- All credential access events are logged by Jenkins and must not be deleted.
- Quarterly review of all pipeline jobs and credentials is mandatory.

---

## 9. Incident Response

If a security issue is detected in the pipeline or a credential is compromised:

1. Immediately revoke and rotate the affected credential in Jenkins.
2. Re-run the full pipeline to validate the fix.
3. File an incident report within 24 hours to the Security Team.
4. Update suppression notes or security policy as applicable.
