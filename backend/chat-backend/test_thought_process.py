import requests
import json
import sys

# Force UTF-8 encoding for stdout (Windows issue fix)
sys.stdout.reconfigure(encoding='utf-8')

url = "http://127.0.0.1:8000/chat"
payload = {
    "message": "列出現在有哪些分會？",
    "user_email": "test-thought@example.com"
}

print("Sending request to test thought process...")
try:
    response = requests.post(url, json=payload, timeout=60)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print("\n=== Response ===")
        print(data.get("response"))
        
        print("\n=== Thought Process ===")
        thoughts = data.get("thought_process")
        if thoughts:
            print(json.dumps(thoughts, indent=2, ensure_ascii=False))
        else:
            print("No thought process found (None or empty).")
            
        print("\n=== Actions ===")
        actions = data.get("actions")
        if actions:
            print(json.dumps(actions, indent=2, ensure_ascii=False))
        else:
            print("No actions.")
            
    else:
        print(f"Error Response: {response.text}")

except Exception as e:
    print(f"Request failed: {e}")
