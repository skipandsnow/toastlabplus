import requests
import json

url = "http://127.0.0.1:8000/chat"
# Step 1: Query meetings to get a meetingId
payload_meetings = {
    "message": "查詢 Good Life Toastmasters 最近的會議",
    "user_email": "test@example.com"
}

print("Searching for meetings...")
response = requests.post(url, json=payload_meetings)
print(f"Status: {response.status_code}")
print(response.json().get("response"))

# Note: In a real test, the LLM would help us. 
# Here I will try to trigger get_role_slots directly or via a specific prompt.
payload_slots = {
    "message": "列出 Good Life Toastmasters 最近一場會議的角色空缺並幫我生成報名按鈕",
    "user_email": "test@example.com"
}
print("\nSearching for role slots...")
response = requests.post(url, json=payload_slots)
print(f"Status: {response.status_code}")
data = response.json()
print("Response text:", data.get("response"))
print("Actions found:", json.dumps(data.get("actions"), indent=2, ensure_ascii=False))
