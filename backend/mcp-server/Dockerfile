# ============================================
# Toastlabplus MCP Server - Dockerfile
# Multi-stage build for Spring Boot 3.x
# With LibreOffice for PDF conversion
# ============================================

# Stage 1: Build
FROM eclipse-temurin:25-jdk AS build

WORKDIR /app

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Copy pom.xml and download dependencies (leverage Docker cache)
COPY pom.xml ./
RUN mvn dependency:go-offline -B

# Copy source and build
COPY src src
RUN mvn package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:25-jre

WORKDIR /app

# Install LibreOffice headless for Excel to PDF conversion
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libreoffice-calc \
    libreoffice-writer \
    fonts-dejavu \
    fonts-noto-cjk && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -m appuser

# Copy jar from build stage
COPY --from=build /app/target/*.jar app.jar

# Create temp directory for PDF conversion
RUN mkdir -p /tmp/agenda && chown -R appuser:appgroup /tmp/agenda

# Set permissions
RUN chown -R appuser:appgroup /app
USER appuser

# Cloud Run uses PORT env variable
ENV PORT=8080
EXPOSE 8080

# JVM optimization for container environment
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar --server.port=${PORT}"]
