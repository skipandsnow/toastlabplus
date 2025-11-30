# Toastlabplus : The most powerful officer tool
# 目的
建立一個幫助Toastmaster club officer/member/guests的chatbot(default line)以及Officer管理後台mobile app

本專案共有兩個專案內容:
1. Toastlabplus Linebot: 透過建立一個Line官方帳號讓每個Toastmaster club officer/member/guests能夠加入好友，提供各種功能，詳細功能參照規格說明。
2. Toastlab Mobile App: 提供一個app能夠跨平台(ios/android)，讓officer可以登入管理角色登記資訊，並且產生meeting agenda，同時間這個app可以顯示透過Toastlabplus Linebot註冊的角色資訊，並且提供linebot相關的資料可以讓linebot進行詢問以及紀錄

以及一個提供資料服務MCP server
3. Toastlabplus backend MCP server


# 詳細規格說明：
## 1. Toastlabplus linebot

### 功能說明
1. 主動詢問toastmasters guests以及member是否要擔任角色
   如果他們要take role則詢問他們想要擔任什麼角色，toastmasters角色會記錄在Officer app管理後台上，officer管理後台會maintain這樣的角色資訊，每次的對話如果需要使用者回覆選項必須要透過line的點選template，讓使用者點擊增加使用者體驗。
2. 取消擔任角色
   判斷使用者是否要取消擔任角色，透過對話式的方式引導使用者來取消角色，確認toastmaster要取消角色後，以MCP的方式officer管理後台取消該角色的註冊
3. 主動詢問每次toastmaster meeting會議日期與時間

### 系統條件
1. line bot跟app後端服務可以架設在雲端服務上(GCP or Azure)
2. 能夠被打包佈屬於Azure AIF / Container Apps /Azure functions 或是在GCP上對應功能
3. 可以透過line官方帳號進行串接
4. 框架採用OpenAI ADK or Google ADK進行構建
5. 所有參數必須 

## 2. Toastlabplus Mobile App
### 系統要求:
1. 考慮透過Flutter進行構建
2. 效能能夠接近native app
3. 採用Azure進行建置

### 系統功能:
1. 會員階級:
    a. 平台管理員: 管理所有的分會，能夠指定分會管理員
    b. 分會管理員: 每個分會有一名，能夠管理分會中的所有會員並且指派分會角色
    c. 分會會員: 每個分會可以有多名會員
2. 分會角色:
    a. 由平台管理員新增維護(e.g. 分會會長(President)、分會教育副會長(Vice President of Education, VPE)...etc)
    b. 分會角色包含3個資訊: 角色id(系統自動產生)、角色中文名稱、角色英文名稱、角色英文簡稱
    c. 一個分會的分會角色只能夠被授予一個會員
3. 會員階級與角色:
    a. 分會
5. 會有個系統管理員，系統管理員可以新增Club並且指定Club officers
6. 每個人登入會有自己的Club center
7. 會議角色選單維護
    a. 新建會議角色(e.g. Ah counter/TME/Table topic master...etc) 
    b. 修改已指派會議角色: 修改時必須能夠顯示已註冊會員


## 3. Toastlabplus backend MCP server
### 系統要求:
1. 採用Spring boot進行構建
2. 儲存Toastlabplus linebot app建立的資料
3. 相關的變數以及連線參數必須拉至properties中
4. 提供給Toastlabplus linebot app進行呼叫主要有以下功能包含但不限於(請參照Toastlabplus linebot app以及Toastlabplus Mobile App章節所需功能進行設計)
5. 須能打包能一個container image，部屬至Azure 或是 GCP



# 初始設定

## 1. 在ToastLab+ App首頁會有一個Setting Button有以下兩個功能:
1. 設定每個月固定會議日期
    a.點選之後會出現一個月曆，可以設定固定每月星期幾＆隔幾週有toastmaster meeting
    b.例如點選週三設定會議，會出現選項每個月第幾個週三，可以複選第1、2、3、4個週三
    c.點選完成之後可以儲存設定或取消設定
2. 預設會議每個流程＆時間＆負責人
    a. 點選之後出現Default預設會議每個流程＆時間＆負責人頁面如下:
    | Agenda Item                          | Duration |
    |-------------------------------------|----------|
    | Preperation                         | 20 min   |
    | Call Meeting to Order (SAA)         | 1 min    |
    | Toastmaster of the Evening Intro    | 3 min    |
    | Ah Counter Rules                    | 2 min    |
    | Variety Session                     | 10 min   |
    | Speaker #1                          | 5–7 min  |
    | Speaker #3                          | 5–7 min  |
    | Intermission & Group Photo          | 10 min   |
    | Evaluation Session                  | 3 min    |
    | Individual Evaluator #2             | 2–3 min  |
    | 2nd Timer & Ah Counter Report       | 2 min    |
    | General Evaluation Session          | 4–6 min  |
    | Awarding & Appreciation             | 5 min    |
    | Meeting Adjourn                     | 1 min    |

    b. 表格中的Content和時間都是點選之後可以編輯與儲存設定或取消設定
    c. 每一個Speakers會有對應一個的Evaluators，兩者數量對應
    d. 可以新增或刪除Speakers跟Evaluators


# 使用流程

1. ToastLab+ App首頁會有Make Agenda的按鈕，跟ToastLab+ LOGO 圖示。
2. 點擊Make Agenda 的按鈕之後會進入到Function Menu Page，有八個方塊sections包含
    (1)Club Info 
    (2)Theme&Questions
    (3)Roles Sign Up
    (4)Club Contact Info
    (5)Roles Question Reply
    (6)Voting Page 
    (7)Share Agenda&Theme Reply Link 
    (8)Certificates