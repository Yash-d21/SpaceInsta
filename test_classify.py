
import json
from utils.classifier import classify_project
from dotenv import load_dotenv

load_dotenv()

with open("results_with_advice.json", "r") as f:
    data = json.load(f)

analysis = data.get("vision_analysis")
classification = classify_project(analysis)

print(json.dumps(classification, indent=4))
