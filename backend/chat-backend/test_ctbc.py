import requests
import json

url = "http://127.0.0.1:8000/chat"
payload = {
    "message": "CTBC Toastmasters 最近有會議嗎？如果有，請列出角色空缺並產生報名按鈕。",
    "user_email": "test@example.com"
}

print("Searching for CTBC meetings and role slots...")
try:
    response = requests.post(url, json=payload, timeout=90)
    print(f"Status: {response.status_code}")
    data = response.json()
    print("Response text:", data.get("response"))
    print("Actions found:", json.dumps(data.get("actions"), indent=2, ensure_ascii=False))
except Exception as e:
    print(f"Error: {e}")
