
import os
import json
import google.generativeai as genai

def classify_project(analysis_data):
    """
    Uses Gemini to classify the interior design project into business categories,
    risk tiers, and complexity levels.
    """
    try:
        if not os.getenv("GOOGLE_API_KEY"):
            return {"error": "API Key not found"}

        genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))
        model = genai.GenerativeModel("models/gemini-flash-latest")

        prompt = f"""
        Given the following interior design vision analysis, classify the project into:
        1. Project Type (e.g., Commercial, Residential, Hospitality, Industrial)
        2. Complexity Level (Low, Medium, High)
        3. Estimated Timeline (Weeks)
        4. Main Risk Factors
        5. Priority Ranking of items (Which items are critical vs optional)

        Analysis Data:
        {json.dumps(analysis_data, indent=2)}

        Output MUST be valid JSON with the following structure:
        {{
            "project_type": "",
            "complexity_level": "",
            "estimated_timeline_weeks": 0,
            "risk_factors": [],
            "item_prioritization": [
                {{"item_name": "", "priority": "Critical|High|Medium|Low", "rationale": ""}}
            ]
        }}
        """

        generation_config = genai.GenerationConfig(
            response_mime_type="application/json"
        )

        response = model.generate_content(prompt, generation_config=generation_config)
        return json.loads(response.text.strip())

    except Exception as e:
        print(f"Error in Classification: {e}")
        return {"error": str(e)}
