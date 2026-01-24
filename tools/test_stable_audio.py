import os
import requests
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("STABLE_AUDIO_API_KEY")
URL = "https://api.stableaudio.com/v1/generation"

def test_connection():
    if not API_KEY:
        print("❌ SKIPPING: STABLE_AUDIO_API_KEY is not set.")
        return

    print(f"🔑 Key length: {len(API_KEY)}")
    print(f"🔑 Key prefix: {API_KEY[:5]}...")
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    # Short test generation
    payload = {
        "prompt": "1 second of silence",
        "seconds_total": 1
    }
    
    try:
        print("📨 Sending request...")
        response = requests.post(URL, headers=headers, json=payload)
        
        print(f"📥 Status Code: {response.status_code}")
        print(f"📥 Response Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            print("✅ SUCCESS: API Key is valid.")
            # Check content type
            ct = response.headers.get('content-type', '')
            print(f"   Content-Type: {ct}")
            if 'audio' in ct:
                print("   Got Audio Data!")
            else:
                print("   Got JSON/Other:", response.text[:100])
        else:
            print(f"❌ ERROR: {response.text}")
            
    except Exception as e:
        print(f"❌ EXCEPTION: {e}")

if __name__ == "__main__":
    test_connection()
