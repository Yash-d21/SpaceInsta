import os
import sys
import json
import argparse
from dotenv import load_dotenv

# Load env before imports that might need it
load_dotenv()

# Verify API Key
if not os.getenv("GOOGLE_API_KEY"):
    print("Error: GOOGLE_API_KEY not found in .env file.")
    print("Please get a key from https://aistudio.google.com/ and add it to .env")
    sys.exit(1)

from agent.vision_reader import analyze_image
from utils.pricing_utils import calculate_estimate

def load_catalog():
    catalog_path = os.path.join(os.path.dirname(__file__), "data", "catalog_prices.json")
    try:
        with open(catalog_path, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading catalog: {e}")
        return {}

def print_estimates(estimates):
    print("\n" + "="*50)
    print("ESTIMATED COST BREAKDOWN")
    print("="*50)
    
    for tier in ["economy", "standard", "premium"]:
        data = estimates[tier]
        print(f"\n--- {tier.upper()} TIER ---")
        print(f"{'Item':<30} | {'Qty':<5} | {'Unit':<10} | {'Total':<10}")
        print("-" * 65)
        
        for item in data["items"]:
            print(f"{item['name'][:30]:<30} | {item['quantity']:<5} | INR {item['unit_price']:<9} | INR {item['cost']:<9}")
            
        print("-" * 65)
        print(f"{'Subtotal':<48} : INR {data['subtotal']}")
        print(f"{'Labor (' + str(int(data['labor_percent']*100)) + '%)':<48} : INR {data['labor']}")
        print(f"{'Contingency (' + str(int(data['contingency_percent']*100)) + '%)':<48} : INR {data['contingency']}")
        print(f"{'TOTAL ESTIMATE':<48} : INR {data['total']}")

def main():
    parser = argparse.ArgumentParser(description="AI Interior Design Estimator Agent")
    parser.add_argument("image_path", help="Path to the interior design image file")
    parser.add_argument("--provider", choices=["gemini", "hf"], default="gemini", help="AI Provider to use (gemini or hf)")
    parser.add_argument("--output", help="Optional path to save results as JSON")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.image_path):
        print(f"Error: File not found at {args.image_path}")
        return
    
    if args.provider == "hf":
        from agent.vision_reader import analyze_image_hf
        vision_data = analyze_image_hf(args.image_path)
    else:
        vision_data = analyze_image(args.image_path)
    
    if not vision_data:
        print("Failed to analyze image.")
        return
        
    print("\nVision Extraction Successful!")
    print(f"Room Type: {vision_data.get('room_type', 'Unknown')}")
    print(f"Style: {vision_data.get('style_guess', 'Unknown')}")
    print(f"Quality Tier Guess: {vision_data.get('quality_tier_guess', {}).get('tier', 'Unknown')} (Conf: {vision_data.get('quality_tier_guess', {}).get('confidence', 0)})")
    
    print("\nCalculated Complexity Flags:")
    for flag, value in vision_data.get("complexity_flags", {}).items():
        print(f"- {flag}: {value}")

    print("\n" + "-"*30)
    print("COST SAVING ADVICE (What to eliminate/simplify):")
    for point in vision_data.get("cost_saving_points", []):
        print(f"• {point}")
    
    print("\nBUYING RECOMMENDATIONS (Affordable Stores):")
    for rec in vision_data.get("buying_recommendations", []):
        cat = rec.get("item_category", "General")
        store = rec.get("store_suggestion", "N/A")
        tip = rec.get("price_tip", "")
        print(f"• {cat}: Buy at {store}. Tip: {tip}")
    print("-" * 30)

    print("\nCalculating estimates...")
    catalog = load_catalog()
    estimates = calculate_estimate(vision_data, catalog)
    
    # Save to JSON if requested
    if args.output:
        output_data = {
            "vision_analysis": vision_data,
            "cost_estimates": estimates
        }
        try:
            with open(args.output, "w") as f:
                json.dump(output_data, f, indent=4)
            print(f"\nResults saved to: {args.output}")
        except Exception as e:
            print(f"Error saving JSON: {e}")

    print_estimates(estimates)
    print("\n" + "="*50)
    
if __name__ == "__main__":
    main()
