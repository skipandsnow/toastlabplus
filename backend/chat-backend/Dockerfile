# ============================================
# Toastlabplus Chat Backend - Dockerfile
# Python 3.11 FastAPI Application
# ============================================

FROM python:3.11-slim

WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 建立非 root 用戶
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -s /bin/bash appuser

# 複製並安裝 Python 依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 複製應用程式碼
COPY src/ ./src/

# 設定權限
RUN chown -R appuser:appgroup /app
USER appuser

# Cloud Run 使用 PORT 環境變數
ENV PORT=8000
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# 啟動 uvicorn（Cloud Run 會設定 PORT）
CMD ["sh", "-c", "uvicorn src.main:app --host 0.0.0.0 --port ${PORT}"]
