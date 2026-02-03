import os
import shutil
import json
from flask import Flask, request, jsonify, render_template, send_from_directory
from flask_cors import CORS
from dotenv import load_dotenv
from typing import Optional
import threading
import google.generativeai as genai
import requests
import time
import urllib.parse

# Load env variables
load_dotenv()

from agent.vision_reader import analyze_image, get_model
from utils.pricing_utils import calculate_estimate
from main import load_catalog
from utils.classifier import classify_project
from utils.supabase_handler import save_analysis

app = Flask(__name__, template_folder='templates', static_folder='static')
CORS(app)

# Ensure temp and img directories exist
# Ensure temp and img directories exist
if os.environ.get('VERCEL') or os.path.exists('/tmp'):
    TEMP_DIR = "/tmp"
else:
    TEMP_DIR = "temp"
    os.makedirs(TEMP_DIR, exist_ok=True)

# For IMG_OUTPUT_DIR, in Vercel we can't write to static, so we will use /tmp for temp generation
# and return base64. But local run needs standard dir.
IMG_OUTPUT_DIR = os.path.join("static", "img")
if not os.environ.get('VERCEL'):
    os.makedirs(IMG_OUTPUT_DIR, exist_ok=True)

import base64

def generate_image_via_gemini(prompt, index):
    """
    Generates an image using Google's native 'Nano Banana' (gemini-2.5-flash-image).
    Falls back to Pollinations AI if Gemini fails.
    """
    try:
        print(f"🍌 NANO BANANA: Generating image for spec {index}...")
        print(f"📝 Prompt: {prompt[:100]}...")
        
        # Configure model
        model = genai.GenerativeModel("models/gemini-2.5-flash-image")
        
        # Call generation
        response = model.generate_content(prompt)
        
        # Extract image bytes from the first candidate
        for candidate in response.candidates:
            for part in candidate.content.parts:
                if part.inline_data:
                    image_bytes = part.inline_data.data
                    
                    # If on Vercel, return base64 data URI directly to avoid disk write issues
                    if os.environ.get('VERCEL'):
                        b64_string = base64.b64encode(image_bytes).decode('utf-8')
                        print(f"✅ SUCCESS: Generated base64 image for spec {index}")
                        return f"data:image/png;base64,{b64_string}"
                    
                    # Local env: Save to disk
                    filename = f"banana_{int(time.time())}_{index}.png"
                    filepath = os.path.join(IMG_OUTPUT_DIR, filename)
                    with open(filepath, "wb") as f:
                        f.write(image_bytes)
                    print(f"✅ SUCCESS: Saved Banana image as {filename}")
                    return f"/static/img/{filename}"
        
        print(f"❌ FAILED: No image data returned from Nano Banana, trying fallback...")
        return generate_image_fallback(prompt, index)
        
    except Exception as e:
        print(f"❌ ERROR: Nano Banana generation failed: {e}")
        print(f"🔄 Falling back to Pollinations AI...")
        return generate_image_fallback(prompt, index)

def generate_image_fallback(prompt, index):
    """
    Fallback image generation using Pollinations AI.
    """
    try:
        # Clean prompt for URL
        clean_prompt = urllib.parse.quote(prompt[:500])
        pollinations_url = f"https://image.pollinations.ai/prompt/{clean_prompt}?width=800&height=600&nologo=true&seed={index}"
        
        print(f"🎨 POLLINATIONS: Generating fallback image {index}...")
        
        # Download the image
        response = requests.get(pollinations_url, timeout=30)
        if response.status_code == 200:
            # If on Vercel, return base64
            if os.environ.get('VERCEL'):
                b64_string = base64.b64encode(response.content).decode('utf-8')
                print(f"✅ SUCCESS: Generated fallback base64 image")
                return f"data:image/png;base64,{b64_string}"
            
            # Local: save to disk
            filename = f"fallback_{int(time.time())}_{index}.png"
            filepath = os.path.join(IMG_OUTPUT_DIR, filename)
            with open(filepath, "wb") as f:
                f.write(response.content)
            print(f"✅ SUCCESS: Saved fallback image as {filename}")
            return f"/static/img/{filename}"
        else:
            print(f"❌ Pollinations failed with status {response.status_code}")
            return None
            
    except Exception as e:
        print(f"❌ ERROR: Fallback generation failed: {e}")
        return None

def generate_specs_data(image_path, preset, budget, zone, api_key_override=None):
    """
    Uses Gemini to generate 3 distinct 'Build Specs' and then generates images for them.
    """
    model = get_model(api_key_override)
    
    # Prompting for VERY specific visual details for the image generator
    prompt = f"""
    Look at this image of a {zone} and user preferences:
    - Preset Style: {preset}
    - Budget Range: {budget}

    Task: Generate 3 distinct design directions (one standard, one mid, one ultra-premium).
    For each, provide:
    1. Title: Creative name.
    2. Description: 2 sentences on materials/furniture.
    3. Vibe: 1-2 words.
    4. Image Prompt: A high-detail prompt for an AI image generator. 
       Focus on: {zone} interior, {preset} style, specific textures (wood, marble, fabric), 
       lighting (sunlight, warm LEDs), and high-end photographic quality (8k, architectural photography).
       DO NOT mention "rendering" or "cgi", use "photorealistic", "architectural photography".

    Return ONLY a JSON array of 3 objects with keys: "title", "description", "vibe", "image_prompt".
    """

    with open(image_path, "rb") as f:
        image_data = f.read()

    mime_type = "image/jpeg"
    if image_path.lower().endswith(".png"):
        mime_type = "image/png"

    generation_config = genai.GenerationConfig(response_mime_type="application/json")
    
    try:
        response = model.generate_content(
            [prompt, {"mime_type": mime_type, "data": image_data}],
            generation_config=generation_config
        )
        specs = json.loads(response.text)
        
        # Sequentially generate images
        for i, spec in enumerate(specs):
            spec["id"] = i + 1
            img_prompt = spec.get("image_prompt", f"A beautiful {preset} {zone} interior design.")
            
            # Combine preset and custom prompt for maximum quality
            final_prompt = f"Professional architectural photography of a {zone}, {preset} style interior. {img_prompt}. High-end lighting, photorealistic, 8k, ultra-detailed."
            
            image_url = generate_image_via_gemini(final_prompt, i+1)
            # If generation fails, we return a blank placeholder instead of text-based one
            spec["image_url"] = image_url or "https://placehold.co/800x600/1a1c23/1a1c23?text=Generating..."
            
        return specs
    except Exception as e:
        print(f"GenAI Error: {e}")
        # Return empty data instead of text-heavy fallbacks
        return [
            {"id": 1, "title": "Design Concept A", "description": "Processing your room vision...", "vibe": "Standard", "image_url": "https://placehold.co/800x600/1a1c23/1a1c23"},
            {"id": 2, "title": "Design Concept B", "description": "Designing custom elements...", "vibe": "Midrange", "image_url": "https://placehold.co/800x600/1a1c23/1a1c23"},
            {"id": 3, "title": "Design Concept C", "description": "Applying premium finishes...", "vibe": "Premium", "image_url": "https://placehold.co/800x600/1a1c23/1a1c23"}
        ]

def background_save(vision_data, estimates, classification=None):
    try:
        save_analysis(vision_data, estimates, classification)
    except Exception as e:
        print(f"Background Save Error: {e}")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/v1/health')
def health_check():
    from utils.supabase_handler import supabase
    api_key_status = "configured" if os.getenv("GOOGLE_API_KEY") else "missing"
    supabase_status = "connected" if supabase else "missing/not_configured"
    return jsonify({"status": "online", "api_key": api_key_status, "supabase": supabase_status})

@app.route('/api/v1/generate-specs', methods=['POST'])
def generate_specs():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    preset = request.form.get('preset', 'Modern')
    budget = request.form.get('budget', '9L-15L')
    zone = request.form.get('zone', 'Living')
    x_key = request.headers.get('X-Gemini-API-Key')

    temp_path = os.path.join(TEMP_DIR, f"usr_{int(time.time())}.jpg")
    file.save(temp_path)

    try:
        specs = generate_specs_data(temp_path, preset, budget, zone, x_key)
        return jsonify({"specs": specs, "temp_file": temp_path})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/v1/analyze-selected', methods=['POST'])
def analyze_selected():
    data = request.json
    temp_path = data.get('temp_file')
    spec_data = data.get('spec')
    x_key = request.headers.get('X-Gemini-API-Key')

    if not temp_path or not os.path.exists(temp_path):
        return jsonify({"error": "Session expired, please upload again"}), 400

    try:
        vision_data = analyze_image(temp_path, api_key_override=x_key)
        if not vision_data:
            return jsonify({"error": "Analysis failed"}), 400

        catalog = load_catalog()
        estimates = calculate_estimate(vision_data, catalog)
        classification = classify_project(vision_data, api_key_override=x_key)

        threading.Thread(target=background_save, args=(vision_data, estimates, classification)).start()

        return jsonify({
            "vision_analysis": vision_data,
            "cost_estimates": estimates,
            "business_classification": classification,
            "selected_spec": spec_data
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
