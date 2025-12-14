# 9. 資料庫設計

[← 返回目錄](../README.md) | [← 上一章](./08-notification.md)

---

## 9.1 主要實體

- **CLUB**: 分會基本資料
- **MEMBER**: 會員資料，包含權限角色（Role）與狀態
- **MEETING**: 會議主檔，包含日期、主題
- **ROLE_ASSIGNMENT**: 記錄誰在該次會議擔任什麼角色
- **AGENDA_TEMPLATE**: 儲存議程結構的 JSON 定義
- **AGENDA_ITEM**: 議程項目明細
- **NOTIFICATION**: 通知記錄

## 9.2 實體關係圖

```mermaid
erDiagram
    CLUB ||--o{ MEMBER : has
    CLUB ||--o{ AGENDA_TEMPLATE : owns
    CLUB ||--o{ MEETING : schedules
    
    CLUB {
        bigint id PK
        string name
        string description
        string location
        string meeting_day
        string meeting_time
        time meeting_end_time
        string contact_email
        string contact_phone
        string contact_person
        timestamp created_at
        timestamp updated_at
    }

    MEMBER {
        bigint id PK
        string email
        string password_hash
        string role "PLATFORM_ADMIN, CLUB_ADMIN..."
        string status "ACTIVE, PENDING, REJECTED, SUSPENDED"
        boolean notification_push
        boolean notification_email
        bigint approved_by FK
        timestamp approved_at
        text rejection_reason
    }

    MEETING {
        bigint id PK
        date meeting_date
        time start_time
        string status "DRAFT, OPEN, CLOSED, FINALIZED, COMPLETED, CANCELLED"
    }

    ROLE_ASSIGNMENT {
        bigint id PK
        bigint meeting_id FK
        bigint member_id FK
        string role_name "TME, Timer..."
        bigint assigned_by FK
        timestamp assigned_at
        boolean is_admin_assigned
    }

    AGENDA_TEMPLATE {
        bigint id PK
        string name "Standard Meeting..."
        json structure "時段設定 JSON"
    }
    
    AGENDA_ITEM {
        bigint id PK
        bigint meeting_id FK
        string title
        int duration_min
        string assigned_person_name
    }
    
    NOTIFICATION {
        bigint id PK
        bigint user_id FK
        string type
        string title
        text body
        timestamp read_at
        timestamp created_at
    }

    MEETING ||--o{ ROLE_ASSIGNMENT : has
    MEETING ||--o{ AGENDA_ITEM : contains
    MEMBER ||--o{ NOTIFICATION : receives
```

---

[下一章：技術棧與部署 →](./10-deployment.md)
