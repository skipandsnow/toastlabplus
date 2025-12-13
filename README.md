# Toastlabplus Project

Flutter 跨平台會議管理 App + Google Cloud 後端服務

## 專案結構

```
toastlabplus/
├── backend/
│   ├── mcp-server/       # Spring Boot MCP Server
│   └── chat-backend/     # Python Chat Backend (FastAPI)
├── mobile/
│   └── toastlabplus_app/ # Flutter App
├── infrastructure/
│   ├── terraform/        # GCP IaC
│   └── scripts/          # 部署腳本
└── docs/
    └── implementation_plan/
```

## 快速開始

### Flutter App
```bash
cd mobile/toastlabplus_app
flutter run -d chrome
```

### MCP Server (Spring Boot)
```bash
cd backend/mcp-server
./mvnw spring-boot:run
```

### Chat Backend (Python)
```bash
cd backend/chat-backend
pip install -r requirements.txt
uvicorn src.main:app --reload
```

## 文件

- [實作計畫](./docs/implementation_plan/README.md)