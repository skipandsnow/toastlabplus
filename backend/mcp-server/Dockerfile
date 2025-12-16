# ============================================
# Toastlabplus MCP Server - Dockerfile
# Multi-stage build for Spring Boot 3.x
# ============================================

# Stage 1: Build
FROM eclipse-temurin:17-jdk-alpine AS build

# 安裝 Maven
RUN apk add --no-cache maven

WORKDIR /app

# 複製 pom.xml 並下載依賴（利用 Docker cache）
COPY pom.xml ./
RUN mvn dependency:go-offline -B

# 複製原始碼並建置
COPY src src
RUN mvn package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# 建立非 root 用戶
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 從 build stage 複製 jar
COPY --from=build /app/target/*.jar app.jar

# 設定權限
RUN chown -R appuser:appgroup /app
USER appuser

# Cloud Run 使用 PORT 環境變數
ENV PORT=8080
EXPOSE 8080

# JVM 優化參數（適合 container 環境）
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar --server.port=${PORT}"]
