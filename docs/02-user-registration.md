# 2. 使用者註冊與身分選擇

[← 返回目錄](../README.md) | [← 上一章](./01-architecture.md)

---

## 2.1 註冊流程

系統支援多種身分註冊，確保不同角色的使用者能獲得對應的權限與功能。

**註冊步驟**:

1. **註冊入口**: 使用者下載 App 後，可選擇「註冊新帳號」

2. **身分選擇**:
   - **Guest (來賓)**: 適用於非 Toastmasters 會員或參觀者
     - 僅需填寫基本姓名與 Email
     - 註冊後可瀏覽公開會議資訊
     - 無法報名角色
   
   - **Member (會員)**: 適用於正式會員
     - 註冊時需選擇所屬分會 (Club)
     - 提交後狀態為 `PENDING`
     - 需等待分會管理員審核通過後才能啟用完整功能（如報名角色）

3. **平台管理員**: 系統預設一組最高權限帳號，用於建立分會與指派初始管理員

## 2.2 註冊流程圖

```mermaid
sequenceDiagram
    actor User
    participant App
    participant Server
    participant DB
    
    User->>App: 開啟 App
    App->>User: 顯示登入/註冊頁
    User->>App: 點選「註冊」
    App->>User: 顯示身分選擇 (Guest / Member)
    
    alt 選擇 Guest (來賓)
        User->>App: 選擇 Guest
        App->>User: 顯示基本資料表單 (Name, Email)
        User->>App: 提交資料
        App->>Server: POST /api/guests
        Server->>DB: Insert Guest Record
        Server-->>App: Return Token (Guest Role)
        App->>User: 進入首頁 (僅查看權限)
        
    else 選擇 Member (會員)
        User->>App: 選擇 Member
        App->>Server: GET /api/clubs (取得分會列表)
        Server-->>App: Return Club List
        App->>User: 顯示資料表單 + 分會選單
        User->>App: 填寫資料 + 選擇分會
        App->>Server: POST /api/members
        Server->>DB: Insert Member (Status: PENDING)
        Server-->>App: Return Success
        App->>User: 顯示「待審核」畫面
    end
```

## 2.3 會員審核狀態機

```mermaid
stateDiagram-v2
    [*] --> PENDING: 會員提交註冊
    PENDING --> APPROVED: Club Admin 審核通過
    PENDING --> REJECTED: Club Admin 拒絕
    APPROVED --> SUSPENDED: 違規停權
    SUSPENDED --> APPROVED: 恢復權限
    REJECTED --> [*]: 帳號刪除
    APPROVED --> [*]: 會員離會
```

## 2.4 審核操作流程

```mermaid
sequenceDiagram
    actor CA as Club Admin
    participant App
    participant Server
    participant DB
    participant FCM as Firebase Cloud Messaging
    
    CA->>App: 進入「會員審核」頁面
    App->>Server: GET /api/clubs/{clubId}/pending-members
    Server->>DB: 查詢該分會待審核會員
    DB-->>Server: 待審核列表
    Server-->>App: 返回列表 (含申請資料)
    
    App->>CA: 顯示待審核列表
    CA->>App: 點選會員 → 查看詳情
    
    alt 審核通過
        CA->>App: 點擊「通過」
        App->>Server: PATCH /api/members/{id}/approve
        Server->>DB: UPDATE status = 'APPROVED'
        Server->>DB: INSERT notification
        Server->>FCM: 發送 Push 通知
        Server-->>App: 200 OK
        App->>CA: 顯示成功訊息
        
    else 審核拒絕
        CA->>App: 點擊「拒絕」+ 輸入原因
        App->>Server: PATCH /api/members/{id}/reject
        Server->>DB: UPDATE status = 'REJECTED'
        Server->>DB: INSERT notification (含原因)
        Server->>FCM: 發送 Push 通知
        Server-->>App: 200 OK
        App->>CA: 顯示已拒絕
    end
```

## 2.5 審核通知機制

| 事件 | 通知對象 | 通知方式 | 內容 |
|:---|:---|:---|:---|
| 新申請提交 | Club Admin | App 通知 + Push | 「有新會員申請加入」 |
| 審核通過 | 申請者 | App 通知 + Push | 歡迎訊息 + 功能導覽 |
| 審核拒絕 | 申請者 | App 通知 + Push | 拒絕原因 + 重新申請引導 |
| 審核超時 (7天未處理) | Club Admin | App 通知 + Push | 提醒處理待審核申請 |

---

[下一章：角色權限設計 →](./03-permissions.md)
