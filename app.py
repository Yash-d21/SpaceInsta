
import os
import shutil
import json
from fastapi import FastAPI, UploadFile, File, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load env variables AT THE TOP
load_dotenv()

from agent.vision_reader import analyze_image
from utils.pricing_utils import calculate_estimate
from main import load_catalog
from utils.classifier import classify_project

app = FastAPI(
    title="Interior Estimator & Classifier API", 
    version="1.1",
    description="REST API for AI-powered interior design analysis, cost estimation, and business classification."
)

# Allow CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure temp directory exists (Vercel uses /tmp for writes)
TEMP_DIR = "/tmp" if os.getenv("VERCEL") else "temp"
os.makedirs(TEMP_DIR, exist_ok=True)

# Health check endpoint
@app.get("/health", include_in_schema=False)
@app.get("/api/v1/health")
def health_check():
    api_key_status = "configured" if os.getenv("GOOGLE_API_KEY") else "missing"
    return {
        "status": "online",
        "api_key": api_key_status,
        "environment": "vercel" if os.getenv("VERCEL") else "local"
    }

@app.get("/", include_in_schema=False)
def read_root():
    return {
        "status": "online", 
        "version": "1.1",
        "message": "Welcome to InstaSpace AI API!",
        "interactive_docs": "/docs",
        "how_to_use": {
            "step_1_health": {
                "url": "/api/v1/health",
                "method": "GET",
                "purpose": "Check if API and Keys are ready"
            },
            "step_2_analyze": {
                "url": "/api/v1/full-analysis",
                "method": "POST",
                "body": "form-data (file=@image.jpg)",
                "curl_example": "curl -X POST -F 'file=@room.jpg' https://insta-space-seven.vercel.app/api/v1/full-analysis"
            }
        }
    }

@app.get("/api/v1/estimate", include_in_schema=False)
@app.get("/estimate", include_in_schema=False)
def estimate_get_info():
    return {
        "error": "Method Not Allowed",
        "message": "This endpoint requires a POST request with an image file.",
        "usage": "Use curl -F 'file=@your_image.jpg' http://localhost:8000/api/v1/estimate",
        "documentation": "/docs"
    }

@app.post("/api/v1/estimate")
@app.post("/estimate", include_in_schema=False)
async def estimate_design_cost(provider: str = "gemini", file: UploadFile = File(...)):
    """
    Step 1 & 2: Upload an image to extract vision data and calculate cost estimates.
    Returns the vision_analysis and cost_estimates structure.
    """
    temp_file_path = os.path.join(TEMP_DIR, file.filename)
    
    try:
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        vision_data = None
        if provider == "hf":
             from agent.vision_reader import analyze_image_hf
             vision_data = analyze_image_hf(temp_file_path)
        else:
            vision_data = analyze_image(temp_file_path)
        
        if not vision_data:
            raise HTTPException(status_code=400, detail="Vision extraction failed.")
            
        catalog = load_catalog()
        estimates = calculate_estimate(vision_data, catalog)
        
        return {
            "vision_analysis": vision_data,
            "cost_estimates": estimates
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(temp_file_path): os.remove(temp_file_path)

@app.get("/api/v1/classify", include_in_schema=False)
@app.get("/classify", include_in_schema=False)
def classify_get_info():
    return {
        "error": "Method Not Allowed",
        "message": "This endpoint requires a POST request with JSON data.",
        "usage": "Use curl -X POST -H 'Content-Type: application/json' -d '{\"vision_analysis\":{...}}' https://insta-space-seven.vercel.app/api/v1/classify",
        "documentation": "/docs"
    }

@app.post("/api/v1/classify")
@app.post("/classify", include_in_schema=False)
async def classify_results(data: dict = Body(...)):
    """
    Step 3: Provide the vision_analysis JSON to get business classification levels.
    """
    vision_analysis = data.get("vision_analysis", data)
    classification = classify_project(vision_analysis)
    return classification

@app.get("/api/v1/full-analysis", include_in_schema=False)
@app.get("/full-analysis", include_in_schema=False)
def full_analysis_get_info():
    return {
        "error": "Method Not Allowed",
        "message": "This endpoint requires a POST request with an image file.",
        "usage": "Use curl -F 'file=@your_image.jpg' http://localhost:8000/api/v1/full-analysis",
        "documentation": "/docs"
    }

@app.post("/api/v1/full-analysis")
@app.post("/full-analysis", include_in_schema=False)
async def full_analysis(provider: str = "gemini", file: UploadFile = File(...)):
    """
    Complete Flow: Image Upload -> Extraction -> Pricing -> Classification.
    Returns a unified response object.
    """
    temp_file_path = os.path.join(TEMP_DIR, file.filename)
    
    try:
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        vision_data = analyze_image(temp_file_path) if provider == "gemini" else None
        if provider == "hf":
            from agent.vision_reader import analyze_image_hf
            vision_data = analyze_image_hf(temp_file_path)

        if not vision_data:
            raise HTTPException(status_code=400, detail="Analysis failed.")

        catalog = load_catalog()
        estimates = calculate_estimate(vision_data, catalog)
        classification = classify_project(vision_data)

        return {
            "vision_analysis": vision_data,
            "cost_estimates": estimates,
            "business_classification": classification
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(temp_file_path): os.remove(temp_file_path)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
