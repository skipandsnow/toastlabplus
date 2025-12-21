# 4. 會議管理細部流程

[← 返回目錄](../README.md) | [← 上一章](./03-permissions.md)

---

> ✅ **實作狀態**: 已於 v0.1.6 (2025-12-22) 更新

## 目前已實作功能

| 功能 | 狀態 | 說明 |
|------|------|------|
| **Meeting Schedule** | ✅ 完成 | 定義重複規律（每月第 N 週星期 X） |
| **編輯排程** | ✅ 完成 | 修改現有的會議排程設定 |
| **刪除排程** | ✅ 完成 | 刪除排程（不影響已產生的會議） |
| **自動產生會議** | ✅ 完成 | 根據 Schedule 批次產生未來 N 個月的會議 |
| **動態月數選擇** | ✅ 完成 | 可選擇 1-12 個月的產生範圍 |
| **刪除會議** | ✅ 完成 | Club Admin 可刪除會議 |
| **批量刪除會議** | ✅ 完成 | 多選模式，一次刪除多個會議 |
| **編輯會議主題** | ✅ 完成 | 可編輯 Meeting Theme 並套用至 Agenda |
| **會議詳情** | ✅ 完成 | 顯示會議時間、地點、角色報名狀態 |
| **Template-Based Role Slots** | ✅ 完成 | 新 Meeting 根據模板建立角色 |

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
