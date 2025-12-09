# 4. 會議管理細部流程

[← 返回目錄](./README.md) | [← 上一章](./03-permissions.md)

---

## 4.1 會議生命週期

```mermaid
stateDiagram-v2
    [*] --> DRAFT: 建立會議
    DRAFT --> OPEN: 開放報名
    OPEN --> CLOSED: 截止報名
    CLOSED --> FINALIZED: 確認 Agenda
    FINALIZED --> COMPLETED: 會議結束
    
    DRAFT --> CANCELLED: 取消會議
    OPEN --> CANCELLED: 取消會議
    CLOSED --> CANCELLED: 取消會議
```

## 4.2 會議建立流程

```mermaid
sequenceDiagram
    actor VPE
    participant App
    participant Server
    participant DB
    
    VPE->>App: 點擊「建立會議」
    App->>VPE: 顯示會議建立表單
    
    Note over App: 必填欄位：<br/>- 會議日期<br/>- 開始時間<br/>- 會議類型<br/>- 可選模板
    
    VPE->>App: 填寫資料並提交
    App->>Server: POST /api/meetings
    
    Server->>DB: 驗證無衝突日期
    
    alt 日期可用
        Server->>DB: INSERT meeting (status: DRAFT)
        Server->>DB: 根據模板建立角色空缺
        DB-->>Server: 建立成功
        Server-->>App: 201 Created + meeting_id
        App->>VPE: 跳轉至會議詳情頁
    else 日期衝突
        Server-->>App: 409 Conflict
        App->>VPE: 提示「該日期已有會議」
    end
```

## 4.3 會議編輯權限

| 操作 | DRAFT | OPEN | CLOSED | FINALIZED |
|:---|:---:|:---:|:---:|:---:|
| 修改日期/時間 | ✅ | ⚠️ 需通知 | ❌ | ❌ |
| 修改會議類型 | ✅ | ❌ | ❌ | ❌ |
| 增減角色 | ✅ | ✅ | ⚠️ 需確認 | ❌ |
| 開放報名 | ✅ | - | - | - |
| 截止報名 | - | ✅ | - | - |
| 產生 Agenda | - | - | ✅ | ✅ (微調) |
| 取消會議 | ✅ | ✅ 需通知 | ✅ 需確認 | ❌ |

---

[下一章：會議角色註冊流程 →](./05-role-registration.md)
