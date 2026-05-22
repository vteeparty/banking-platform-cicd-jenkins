# ============================================================
# Dockerfile — Banking Platform (Spring Boot)
# Beginner-friendly, local development image
#
# HOW TO BUILD (run from the project root):
#   docker build -t banking-platform:latest .
#
# HOW TO RUN:
#   docker run -p 8080:8080 banking-platform:latest
#
# Then open http://localhost:8080 in your browser.
# ============================================================

# ── Stage 1: Build ───────────────────────────────────────────
# Use an official Maven image that already has JDK 17 bundled.
# This stage compiles the source code and produces the JAR file
# inside the container — no need to install Maven on your machine.
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Set the working directory inside the container.
# All subsequent commands run from this folder.
WORKDIR /app

# Copy the Maven project descriptor first.
# Docker caches this layer separately so dependency downloads are
# skipped on subsequent builds when pom.xml has not changed.
COPY pom.xml .

# Download all dependencies declared in pom.xml.
# '-B' = batch mode (no interactive prompts, clean log output).
# '-e' = show errors.
# 'dependency:go-offline' pre-fetches everything so the next step
# works without network access.
RUN mvn -B -e dependency:go-offline

# Copy the full source tree into the container.
COPY src ./src

# Compile, run tests, and package the application as a fat JAR.
# Remove '-DskipTests' if you want tests to run during the image build.
RUN mvn -B -e clean package -DskipTests

# ── Stage 2: Run ─────────────────────────────────────────────
# Use a minimal JRE-only image for the final runtime container.
# This is much smaller than a full JDK image (~200 MB vs ~600 MB)
# and has a smaller attack surface — important for security scans.
FROM eclipse-temurin:17-jre-alpine

# Add a non-root user to run the application.
# Running as root inside a container is a security risk;
# Trivy and most security scanners will flag it.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set the working directory for the runtime container.
WORKDIR /app

# Copy only the packaged JAR from the build stage.
# The wildcard matches any version suffix (e.g. banking-platform-1.0.jar).
COPY --from=build /app/target/*.jar app.jar

# Give ownership of the app files to the non-root user.
RUN chown appuser:appgroup app.jar

# Switch to the non-root user before starting the process.
USER appuser

# Expose the default Spring Boot port.
# This is documentation only — it does not publish the port automatically.
# Use 'docker run -p 8080:8080 ...' to publish it on the host.
EXPOSE 8080

# Start the Spring Boot application.
# Using the exec form (JSON array) so the JVM receives OS signals
# correctly (e.g. SIGTERM for graceful shutdown).
ENTRYPOINT ["java", "-jar", "app.jar"]
