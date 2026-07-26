import os
import json
import urllib.request
import urllib.error

# إعدادات مسار الحفظ لملفات AtlaHub
OUTPUT_DIR = r"C:\Users\crock\OneDrive\Documents\AtlaHub\Releases"
# ضع مفتاح Gemini API الخاص بك هنا
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "YOUR_GEMINI_API_KEY_HERE")
LAST_PROCESSED_FILE = os.path.join(OUTPUT_DIR, ".last_release.txt")

def fetch_latest_chatwoot_release():
    url = "https://api.github.com/repos/chatwoot/chatwoot/releases/latest"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            return data['tag_name'], data['body'], data['name']
    except Exception as e:
        print(f"Error fetching Github release: {e}")
        return None, None, None

def generate_atlahub_content_gemini(release_notes):
    prompt = """
You are a technical translator. We are rebranding an open source project to our own brand called "AtlaHub". 
Please translate the following release notes into both English and Arabic.
IMPORTANT RULES:
1. Completely remove any mention of the word "Chatwoot". Replace it with "AtlaHub".
2. Remove any links to Chatwoot's website, policies, or trackers.
3. Format the output in Markdown.
4. Output exactly as a JSON object with this format:
{
  "en": { "title": "AtlaHub Release ...", "body": "Markdown body..." },
  "ar": { "title": "تحديث AtlaHub ...", "body": "Markdown body in Arabic..." }
}
Do not return anything except the JSON.

Release Notes to Process:
""" + release_notes

    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={GEMINI_API_KEY}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}]
    }
    
    req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            text = result['candidates'][0]['content']['parts'][0]['text']
            
            # Clean markdown code block from JSON
            if text.startswith('```json'):
                text = text[7:-3]
            elif text.startswith('```'):
                text = text[3:-3]
            
            return json.loads(text.strip())
    except Exception as e:
        print(f"Error calling Gemini API: {e}")
        return None

def main():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    last_release = ""
    if os.path.exists(LAST_PROCESSED_FILE):
        with open(LAST_PROCESSED_FILE, "r") as f:
            last_release = f.read().strip()

    print("Checking for new releases...")
    tag_name, body, name = fetch_latest_chatwoot_release()
    
    if not tag_name:
        return
        
    if tag_name == last_release:
        print(f"Release {tag_name} has already been processed.")
        return

    print(f"New release found: {tag_name}. Generating AtlaHub release notes...")
    content = generate_atlahub_content_gemini(body)
    
    if not content:
        print("Failed to generate content.")
        return

    # Save English Version
    en_path = os.path.join(OUTPUT_DIR, f"{tag_name}_en.md")
    with open(en_path, "w", encoding="utf-8") as f:
        f.write(f"# {content['en']['title']}\n\n{content['en']['body']}")
    
    # Save Arabic Version
    ar_path = os.path.join(OUTPUT_DIR, f"{tag_name}_ar.md")
    with open(ar_path, "w", encoding="utf-8") as f:
        f.write(f"# {content['ar']['title']}\n\n{content['ar']['body']}")

    # Mark as processed
    with open(LAST_PROCESSED_FILE, "w") as f:
        f.write(tag_name)
        
    print(f"Successfully created AtlaHub release notes for {tag_name} in {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
