# 5. 會議角色註冊流程

[← 返回目錄](../README.md) | [← 上一章](./04-meeting-management.md)

---

> ✅ **實作狀態**: 已於 v0.1.6 (2025-12-22) 完成 Admin 代理報名功能

## 目前已實作功能

| 功能 | 狀態 | 說明 |
|------|------|------|
| **UI 角色報名** | ✅ 完成 | 會員在 Meeting Detail 頁面點擊報名/取消 |
| **Template-Based Roles** | ✅ 完成 | 只顯示模板中存在的角色 |
| **Admin 代理報名** | ✅ 完成 | Club Admin 可指派會員到角色、取消任意報名 |
| **Chat 對話報名** | 🚧 待開發 | 透過自然語言與 AI 互動報名 |

提供「Chat 對話」與「UI 介面」兩種操作方式，資料即時同步。

## 5.1 角色類型與限制

```mermaid
flowchart LR
    subgraph RoleTypes ["角色類型"]
        Single["單一角色<br/>TME, Timer, GE"]
        Multi["多人角色<br/>Speaker (1-5)"]
        Optional["選填角色<br/>IE1, IE2"]
    end
    
    subgraph Rules ["數量限制"]
        R1["TME: 1人"]
        R2["Speaker: 最多5人"]
        R3["Timer: 1人"]
        R4["Evaluator: 對應 Speaker 數"]
    end
    
    Single --> R1
    Single --> R3
    Multi --> R2
    Multi --> R4
```

## 5.2 Chat 對話式註冊

透過自然語言與 AI 互動。AI 會先檢查角色空缺狀態，若有空缺則顯示互動式按鈕（Button）供用戶確認，避免誤操作。

**功能特點**:
- **指令範例**: 「我要報名下週五的 Timer」、「取消我的 TME 角色」
- **防呆機制**: 若角色已滿，AI 會建議其他空缺角色或候補

**對話流程圖**:

```mermaid
sequenceDiagram
    actor User
    participant ChatUI
    participant ChatBackend
    participant MCP
    
    User->>ChatUI: 輸入「我要擔任 12/10 的 TME」
    ChatUI->>ChatBackend: Send Message
    ChatBackend->>MCP: Call Tool: check_role_availability
    MCP-->>ChatBackend: Return: Available
    
    ChatBackend-->>ChatUI: 回覆訊息 + Action Buttons
    Note right of ChatUI: "12/10 TME 目前空缺，確認註冊？"<br/>[✅ 確認] [❌ 取消]
    
    User->>ChatUI: 點擊 [✅ 確認]
    ChatUI->>ChatBackend: Send Action: CONFIRM_REGISTRATION
    ChatBackend->>MCP: Call Tool: register_role
    MCP-->>ChatBackend: Return: Success
    ChatBackend-->>ChatUI: 回覆: "✅ 已為您註冊 12/10 TME"
```

## 5.3 UI 介面註冊

視覺化的角色列表，提供直覺的操作體驗。

**功能特點**:
- **狀態顯示**: 每個角色卡片會顯示「空缺（可報名）」、「已額滿（顯示頭像）」或「已報名（顯示取消按鈕）」
- **操作流程**: 點擊空缺卡片 → 彈出確認窗 → 完成報名

**操作流程圖**:

```mermaid
flowchart TD
    A["進入會議列表"] --> B["選擇目標會議"]
    B --> C["進入角色報名頁"]
    C --> D{"檢查角色狀態"}
    
    D -->|"空缺"| E["顯示「報名」按鈕"]
    D -->|"已額滿"| F["顯示佔用者頭像"]
    D -->|"自己已報名"| G["顯示「取消」按鈕"]
    
    E --> H["點擊報名"]
    H --> I["彈出確認視窗"]
    I -->|"確認"| J["呼叫 API 註冊"]
    J --> K["更新 UI 顯示自己頭像"]
    
    G --> L["點擊取消"]
    L --> M["呼叫 API 取消"]
    M --> N["更新 UI 顯示空缺"]
```

## 5.4 角色報名防呆流程

```mermaid
flowchart TD
    Start["用戶點擊報名"] --> CheckAuth{"檢查身分"}
    
    CheckAuth -->|"Guest"| Deny1["❌ 拒絕：請先成為會員"]
    CheckAuth -->|"Member (PENDING)"| Deny2["❌ 拒絕：帳號審核中"]
    CheckAuth -->|"Member (APPROVED)"| CheckRole{"檢查角色狀態"}
    
    CheckRole -->|"角色已滿"| Deny3["❌ 拒絕：角色已被報名"]
    CheckRole -->|"已報名其他角色"| CheckConflict{"衝突檢查"}
    CheckRole -->|"角色空缺"| Confirm["顯示確認對話框"]
    
    CheckConflict -->|"同時段衝突"| Deny4["❌ 拒絕：與已報名角色衝突"]
    CheckConflict -->|"無衝突"| Confirm
    
    Confirm -->|"確認"| Register["執行報名"]
    Confirm -->|"取消"| End["結束"]
    
    Register --> Success["✅ 報名成功"]
```

## 5.5 角色衝突規則

| 角色 A | 可兼任 | 不可兼任 |
|:---|:---|:---|
| **TME** | - | Speaker, GE, Timer, Evaluator |
| **Speaker** | IE (非同場) | TME, Evaluator (同一人) |
| **Timer** | AH Counter, Grammarian | TME |
| **GE** | - | TME, Speaker, Evaluator |
| **Evaluator** | Timer, AH Counter | TME, GE, 對應 Speaker |

## 5.6 管理員代理報名

Club Admin 可代替會員報名或取消報名：

```mermaid
sequenceDiagram
    actor CA as Club Admin
    participant App
    participant Server
    participant DB
    
    CA->>App: 進入會議角色頁面
    App->>CA: 顯示角色列表 + 「指派」按鈕
    
    CA->>App: 點擊空缺角色的「指派」
    App->>Server: GET /api/clubs/{clubId}/members
    Server-->>App: 返回可選會員列表
    
    App->>CA: 顯示會員選擇下拉
    CA->>App: 選擇會員 + 確認
    App->>Server: POST /api/role-assignments<br/>{memberId, roleId, assignedBy}
    
    Server->>DB: INSERT 含 assigned_by_admin = true
    Server-->>App: 201 Created
    
    Note over Server: 發送通知給被指派會員
    App->>CA: 顯示「已指派」
```

---

[下一章：Agenda 模板管理與產生 →](./06-agenda.md)
