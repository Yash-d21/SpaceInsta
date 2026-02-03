import google.generativeai as genai
import os
import json
import typing_extensions as typing

# Initialize Model - will be deferred or checked in functions
model = None

def get_model():
    global model
    api_key = os.getenv("GOOGLE_API_KEY")
    
    # If not in env, try reloading .env just in case we are in a sub-process
    if not api_key:
        from dotenv import load_dotenv
        load_dotenv()
        api_key = os.getenv("GOOGLE_API_KEY")

    if not api_key:
        raise ValueError("GOOGLE_API_KEY is missing. Check your .env file or Vercel environment variables.")

    # Re-configure ensures the key sticks in every request thread
    genai.configure(api_key=api_key)
    
    if model is None:
        model = genai.GenerativeModel("models/gemini-flash-latest")
    
    return model

SYSTEM_PROMPT = """
You are a cost-estimation vision agent for interior designs.
Look at the uploaded interior design image and extract ALL visible elements into structured JSON.
Be precise. If unsure, mark confidence low.
Output MUST be valid JSON only. No extra text.
"""

USER_PROMPT_TEMPLATE = """
Extract from this image: furniture, lighting, materials, decor, special construction work, and estimated quantities.
Also infer a finish quality tier (budget/mid/premium) with confidence.

Expert Task:
1. Identify elements that are "nice to have" but can be ELIMINATED or substituted to significantly reduce costs without losing core functionality.
2. Provide specific recommendations for where to buy these items at affordable/budget prices (e.g., specific retail chains, marketplaces, or second-hand platforms).

JSON schema:

{
  "room_type": "",
  "style_guess": "",
  "quality_tier_guess": {"tier":"", "confidence": 0.0},
  "items": [
    {"category":"furniture|lighting|materials|decor|construction",
     "name":"",
     "quantity": 1,
     "material_guess":"",
     "notes":"",
     "confidence": 0.0}
  ],
  "complexity_flags": {
    "false_ceiling": false,
    "wall_paneling": false,
    "built_in_storage": false,
    "custom_carpentry": false
  },
  "cost_saving_points": [
    "Item to eliminate or simplify and why"
  ],
  "buying_recommendations": [
    {"item_category": "", "store_suggestion": "", "price_tip": ""}
  ]
}
"""

def analyze_image(image_path):
    """
    Sends the image to Gemini Vision to extract structured data.
    """
    try:
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image not found at {image_path}")

        # specific mime type detection could be added, defaulting to png/jpeg logic handled by genai usually
        # but helper wants data.
        
        with open(image_path, "rb") as f:
            image_data = f.read()

        # Simple mime type guess based on extension
        mime_type = "image/jpeg"
        if image_path.lower().endswith(".png"):
            mime_type = "image/png"
            
        generation_config = genai.GenerationConfig(
            response_mime_type="application/json"
        )

        response = get_model().generate_content(
            [
                SYSTEM_PROMPT,
                USER_PROMPT_TEMPLATE,
                {"mime_type": mime_type, "data": image_data}
            ],
            generation_config=generation_config
        )
        
        # Clean up response text if necessary
        try:
            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:-3].strip()
            return json.loads(text)
        except ValueError as ve:
             # This happens if Gemini returns an error message instead of JSON (like 429)
             print(f"Gemini API Error: {response.candidates[0].safety_ratings}")
             return {"error": "API_LIMIT_REACHED", "message": "Gemini rate limit exceeded. Please wait 60s."}

    except Exception as e:
        error_msg = str(e)
        if "429" in error_msg:
            return {"error": "RATE_LIMIT", "message": "Gemini Free Tier limit reached. Try again in 1 minute."}
        print(f"Error in Vision Agent (Gemini): {e}")
        return None

def analyze_image_hf(image_path, model_id="Qwen/Qwen2-VL-7B-Instruct"):
    """
    Uses Hugging Face Inference API for vision extraction.
    default model: meta-llama/Llama-3.2-11B-Vision-Instruct (or Qwen/Qwen2-VL-72B-Instruct if available)
    """
    try:
        from huggingface_hub import InferenceClient
        
        if not os.getenv("HF_TOKEN"):
             print("Error: HF_TOKEN not found in .env")
             return None
             
        client = InferenceClient(api_key=os.getenv("HF_TOKEN"))
        
        with open(image_path, "rb") as f:
            image_data = f.read()

        # Update prompt for HF models (they might need simpler prompting or chat format)
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "image"},
                    {"type": "text", "text": USER_PROMPT_TEMPLATE}
                ]
            }
        ]
        
        # For Llama 3.2 Vision or similar
        response = client.chat_completion(
            model=model_id,
            messages=messages,
            max_tokens=1000
        )
        
        text = response.choices[0].message.content
        
        # Clean up code blocks
        text = text.strip()
        if text.startswith("```json"):
            text = text[7:-3].strip()
        elif text.startswith("```"):
            text = text[3:-3].strip()
            
        return json.loads(text)
        
    except Exception as e:
        print(f"Error in Vision Agent (HF): {e}")
        return None
