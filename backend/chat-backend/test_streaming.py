import requests
import json
import sys

# Force UTF-8 encoding for stdout (Windows issue fix)
sys.stdout.reconfigure(encoding='utf-8')

url = "http://127.0.0.1:8000/chat"
payload = {
    "message": "列出現在有哪些分會？只需要名稱",
    "user_email": "test-stream@example.com"
}

print("Sending streaming request...")
try:
    response = requests.post(url, json=payload, stream=True, timeout=60)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        print("\n=== Streaming content ===")
        for line in response.iter_lines():
            if line:
                decoded_line = line.decode('utf-8')
                print(f"[RAW] {decoded_line}")
                try:
                    data = json.loads(decoded_line)
                    print(f"  -> Type: {data.get('type')}")
                    if data.get('type') == 'thought_start':
                        print(f"     Tool: {data.get('tool')}")
                    elif data.get('type') == 'text':
                        print(f"     Content: {data.get('content')}")
                except json.JSONDecodeError:
                    print(f"  [WARN] Invalid JSON line")
    else:
        print(f"Error Response: {response.text}")

except Exception as e:
    print(f"Request failed: {e}")
