# 附錄

[← 返回目錄](../README.md) | [← 上一章](./11-ui-mockups.md)

---

## 版本歷史

- **v1.0** (2025-12-06): 初版完成，包含完整系統架構與功能設計
- **v1.1** (2025-12-06): 新增細部流程設計
  - 新增 Club Admin 可視權限詳細矩陣
  - 新增 API 資料過濾機制
  - 新增會員審核狀態機與操作流程
  - 新增審核通知機制
  - 新增會議生命週期與編輯權限
  - 新增角色類型與衝突規則
  - 新增管理員代理報名流程
  - 新增模板結構設計（JSON 格式）
  - 新增 Agenda 狀態與權限
  - 新增通知系統設計
  - 更新資料庫設計（補充欄位）
- **v1.2** (2025-12-06): 新增會議投票機制
  - 新增第 7 章 Voting System
  - 新增 TME 控制的投票流程
  - 新增投票狀態機與權限設計
  - 新增即時 SSE（Server-Sent Events）通訊設計
  - 新增投票相關資料表（VOTING_SESSION, VOTE, VOTE_RESULT）
- **v1.3** (2025-12-06): 新增基礎設施與部署策略（Azure 版本）
  - 新增 In-App Chat SSE 串流通訊設計
  - 新增 MCP Server 功能清單（17 個 Tools + REST API）
  - 新增 Azure AI Foundry 設定指南
  - 新增 Azure 環境建置圖與資源清單
  - 新增 CI/CD 部署策略（GitHub Actions）
  - 新增建置檢查清單
- **v1.4** (2025-12-09): 遷移至 Google Cloud Platform
  - 更新系統架構圖（GCP：Cloud Run、Cloud SQL）
  - Container 部署改用 Cloud Run
  - Database 改用 Cloud SQL (PostgreSQL)
  - 新增 `.github/workflows/deploy.yml` CI/CD workflow
  - 更新建置檢查清單為 GCP 服務
- **v1.5** (2025-12-09): 改用 Gemini Developer API
  - AI Model 改用 Gemini Developer API（Google AI Studio）
  - 移除 Vertex AI 依賴，使用現有 Google AI Pro 訂閱
  - 更新月費估算（~$25-50 USD，Gemini API 費用 $0）
  - 更新建置檢查清單（簡化 API Key 設定）
- **v1.6** (2025-12-10): 文件拆分
  - 將單一大檔案拆分為 12 個章節檔案
  - 改善 VS Code 預覽效能問題
- **v1.7** (2025-12-10): 功能細節完善與 UI 更新
  - 通知系統改用 Firebase Cloud Messaging (FCM) + App 內通知
  - 新增 FCM 前置作業設定指南（5 個步驟）
  - AI 模型升級至 Gemini 3 Pro Preview
  - 更新 Gemini API 定價說明（Pay-as-you-go）
  - Agenda 模板設計新增原始 Excel 檔案儲存功能
  - PDF 產生改為基於原始 Excel 模板填入資料
  - 簡化 GCP 環境建置圖
  - 新增 6 個 UI 雛型畫面（使用者註冊、會員審核、會議列表、投票、通知中心、議程模板管理）
  - UI 風格統一為宮崎駿風格（奶油色水彩背景、粉彩配色）

