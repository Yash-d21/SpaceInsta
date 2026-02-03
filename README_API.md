
# AI Interior Estimator & Classifier API

This project is now ready for deployment on **Vercel**.

## 🚀 Deployment to Vercel

1. Install Vercel CLI: `npm install -g vercel`
2. Run: `vercel`
3. Add your Environment Variables in Vercel Dashboard:
   - `GOOGLE_API_KEY`: Your Gemini API Key
   - `HF_TOKEN`: (Optional) HuggingFace Token

## 📡 REST API Endpoints

### 1. `POST /estimate`
Upload an image to get a vision analysis and cost estimation.
- **Body**: `multipart/form-data` with `file` (image)
- **Response**: JSON with `vision_analysis` and `cost_estimates`

### 2. `POST /classify`
Provide the output from the vision analysis to get business classification.
- **Body**: `application/json` with `vision_analysis` data.
- **Response**: JSON with `project_type`, `complexity_level`, `risk_factors`, etc.

### 3. `POST /full-analysis` (RECOMMENDED)
Does everything in one call: Image -> Analysis -> Estimate -> Classification.
- **Body**: `multipart/form-data` with `file` (image)
- **Response**: Comprehensive analysis JSON.

## 🛠 Local Usage

Run the server locally:
```bash
python app.py
```
Then access the interactive docs at: `http://localhost:8000/docs`
