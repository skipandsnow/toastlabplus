import requests
import json

url = "http://127.0.0.1:8000/chat"
payload = {
    "message": "列出現在有哪些分會？",
    "user_email": "test@example.com"
}

try:
    response = requests.post(url, json=payload)
    print(f"Status Code: {response.status_code}")
    print("Response JSON:")
    print(json.dumps(response.json(), indent=2, ensure_ascii=False))
except Exception as e:
    print(f"Error: {e}")
