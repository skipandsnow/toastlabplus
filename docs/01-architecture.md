# 1. 系統架構與資料流

[← 返回目錄](../README.md)

---

## 1.1 架構概述

本系統採用前後端分離架構，以 Google Cloud Platform 為核心雲端平台。

**核心組件**:
- **Client Side**: 使用 Flutter 建構跨平台 App，包含標準 UI 操作介面與 In-App Chat 聊天介面
- **AI Service**: 透過 Google Generative AI SDK 建構 Chat Backend，連接 Gemini Developer API，負責理解用戶自然語言指令並調度 MCP Server
- **Core Backend**: Spring Boot MCP Server 作為核心資料服務，處理所有業務邏輯與資料庫存取
- **Database**: 使用 Cloud SQL (PostgreSQL)，兼顧效能與成本效益

## 1.2 系統架構圖

```mermaid
flowchart TB
    subgraph ClientSide ["Client Side (Flutter App)"]
        UI["UI Screens"]
        ChatUI["In-App Chat UI"]
        State["State Management<br/>Provider"]
    end
    
    subgraph External ["External Service"]
        GeminiAPI["Gemini Developer API<br/>(Google AI Studio)"]
    end
    
    subgraph GCP ["Google Cloud Platform"]
        subgraph CloudRun ["Cloud Run"]
            ChatBackend["Chat Backend<br/>Generative AI SDK"]
            MCP["MCP Server<br/>Spring Boot"]
        end
        
        DB[("Cloud SQL<br/>PostgreSQL")]
    end
    
    UI -->|"REST API"| MCP
    ChatUI -->|"SSE Stream"| ChatBackend
    ChatBackend -->|"Gemini API"| GeminiAPI
    ChatBackend -->|"MCP Protocol"| MCP
    MCP -->|"JPA / SQL"| DB
    
    State <--> UI
    State <--> ChatUI
```

---

[下一章：使用者註冊與身分選擇 →](./02-user-registration.md)
