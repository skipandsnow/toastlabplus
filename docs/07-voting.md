# 7. 會議投票機制 (Voting System)

[← 返回目錄](../README.md) | [← 上一章](./06-agenda.md)

---

會議進行中的即時投票功能，由 TME 控制投票流程，所有會議參與者皆可投票。

## 7.1 投票流程概述

```mermaid
sequenceDiagram
    actor TME
    actor Participants as 參與者 (Member/Guest)
    participant App
    participant Server
    participant SSE as SSE Stream
    
    Note over TME,SSE: 會議進行中...
    
    Participants->>Server: GET /api/meetings/{id}/voting/stream
    Server-->>SSE: 建立 SSE 連線
    
    TME->>App: 點擊「開始投票」
    App->>Server: POST /api/meetings/{id}/voting/start
    Server->>SSE: 推送 VOTING_STARTED
    SSE-->>Participants: 收到投票開始通知
    
    Note over App: 所有人 App 顯示投票介面
    
    loop 每位參與者投票
        Participants->>App: 選擇各角色的票選
        App->>Server: POST /api/votes
        Server-->>App: 投票成功 (不顯示當前票數)
    end
    
    TME->>App: 點擊「結束投票」
    App->>Server: POST /api/meetings/{id}/voting/end
    Server->>Server: 計算投票結果
    Server->>SSE: 推送 VOTING_ENDED + Results
    SSE-->>Participants: 收到結果通知
    
    Note over App: 所有人 App 顯示投票結果
```

## 7.2 投票狀態機

```mermaid
stateDiagram-v2
    [*] --> NOT_STARTED: 會議開始
    NOT_STARTED --> VOTING: TME 啟動投票
    VOTING --> ENDED: TME 結束投票
    ENDED --> [*]: 結果已顯示
```

## 7.3 投票類別與獎項

| 投票類別 | 對象 | 說明 |
|:---|:---|:---|
| **Best Speaker** | 所有 Speaker | 最佳演講者 |
| **Best Evaluator** | 所有 Evaluator | 最佳講評者 |
| **Best Table Topic** | Table Topic 回答者 | 最佳即席演講 |
| **Best Support Role** | Timer, AH Counter, Grammarian | 最佳輔助角色 |

## 7.4 投票權限

| 角色 | 操作 | 說明 |
|:---|:---|:---|
| **TME** | ✅ 啟動/結束投票 | 唯一控制者 |
| **Member (APPROVED)** | ✅ 投票 | 需為會議參與者 |
| **Guest** | ✅ 投票 | 需為會議參與者 |
| **Role Taker** | ❌ 自己類別 | 不能投票給自己 |

## 7.5 投票介面流程

```mermaid
flowchart TD
    subgraph TMEView ["TME 視角"]
        T1["會議進行中"] --> T2["點擊「開始投票」"]
        T2 --> T3["監控投票進度<br/>已投票 X/Y 人"]
        T3 --> T4["點擊「結束投票」"]
        T4 --> T5["顯示結果 + 宣布得獎者"]
    end
    
    subgraph ParticipantView ["參與者視角"]
        P1["收到投票開始通知"] --> P2["App 跳出投票浮層"]
        P2 --> P3["選擇各類別得獎者"]
        P3 --> P4["提交投票"]
        P4 --> P5["等待結果..."]
        P5 --> P6["顯示投票結果"]
    end
```

## 7.6 投票 API 設計

| Method | Endpoint | 說明 | 權限 |
|:---|:---|:---|:---|
| `GET` | `/api/meetings/{id}/voting/stream` | SSE 連線（即時推送） | 參與者 |
| `POST` | `/api/meetings/{id}/voting/start` | 啟動投票 | TME only |
| `POST` | `/api/meetings/{id}/voting/end` | 結束投票 | TME only |
| `GET` | `/api/meetings/{id}/voting/status` | 查詢投票狀態 | 參與者 |
| `POST` | `/api/votes` | 提交投票 | 參與者 |
| `GET` | `/api/meetings/{id}/voting/results` | 查詢結果 | 投票結束後 |

## 7.7 即時通訊設計 (Server-Sent Events)

使用 SSE 實現即時推送，由 Server 向 Client 單向傳送事件：

```mermaid
flowchart LR
    subgraph SSE_Flow ["通訊流程"]
        Client["App"] -->|"GET /voting/stream"| Server
        Server -->|"SSE Connection"| Stream["Event Stream"]
    end
    
    subgraph Events ["SSE Events"]
        E1["event: VOTING_STARTED"] --> D1["data: {meetingId, categories}"]
        E2["event: VOTE_COUNT_UPDATE"] --> D2["data: {count} (僅 TME)"]
        E3["event: VOTING_ENDED"] --> D3["data: {results, winners}"]
    end
```

**SSE 特點**：
- 單向通訊（Server → Client）
- HTTP 原生支援，簡化實作
- 自動重連機制
- Spring Boot 內建 `SseEmitter` 支援

## 7.8 資料庫設計

```mermaid
erDiagram
    MEETING ||--o| VOTING_SESSION : has
    VOTING_SESSION ||--o{ VOTE : contains
    
    VOTING_SESSION {
        bigint id PK
        bigint meeting_id FK
        string status "NOT_STARTED, VOTING, ENDED"
        timestamp started_at
        timestamp ended_at
        bigint started_by FK
    }
    
    VOTE {
        bigint id PK
        bigint session_id FK
        bigint voter_id FK
        string category "BEST_SPEAKER, BEST_EVALUATOR..."
        bigint voted_for FK
        timestamp created_at
    }
    
    VOTE_RESULT {
        bigint id PK
        bigint session_id FK
        string category
        bigint winner_id FK
        int vote_count
    }
```

---

[下一章：通知系統設計 →](./08-notification.md)
