import os
import requests
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("STABLE_AUDIO_API_KEY")
URL = "https://api.stability.ai/v2beta/stable-audio/generate"

def test_v2_multipart():
    if not API_KEY:
        print("❌ SKIPPING: API Key missing")
        return

    print(f"Testing Stability V2beta (Multipart) with Key: {API_KEY[:5]}...")
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Accept": "audio/*"
    }
    
    # Multipart data
    data = {
        "prompt": "1 second of silence",
        "seconds_total": "1"
    }
    
    try:
        response = requests.post(URL, headers=headers, data=data, files={}) # Empty files dict to force multipart if requests supports it, or just data
        # Requests 'data' param sends form-encoded by default? 
        # For multipart, we usually need to provide files or explicitly set boundary?
        # Actually, requests sends multipart/form-data if 'files' is provided.
        # If we only have text fields, 'data' sends application/x-www-form-urlencoded.
        # Stability API might need multipart even for text fields? Docs say "multipart/form-data".
        
        # Force multipart by providing a dummy file or using a specific setup?
        # Let's try sending data as files tuples for fields
        
        files_payload = {
            "prompt": (None, "1 second of silence"),
            "seconds_total": (None, "1")
        }
        
        print("📨 Sending Multipart Request...")
        response = requests.post(URL, headers=headers, files=files_payload)
        
        print(f"📥 Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ SUCCESS! Got Audio.")
            with open("test_stable_v2.mp3", "wb") as f:
                f.write(response.content)
        else:
            print(f"❌ ERROR: {response.text}")

    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    test_v2_multipart()
