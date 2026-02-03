
import json

def calculate_estimate(vision_json, catalog_prices):
    """
    Calculates the cost estimate based on the vision extracted JSON and catalog prices.
    
    Args:
        vision_json (dict): The JSON output from the vision agent.
        catalog_prices (dict): The catalog prices for items.
        
    Returns:
        dict: A dictionary containing itemized costs, subtotals, and totals for each tier.
    """
    
    estimates = {
        "economy": {"items": [], "subtotal": 0, "labor": 0, "contingency": 0, "total": 0},
        "standard": {"items": [], "subtotal": 0, "labor": 0, "contingency": 0, "total": 0},
        "premium": {"items": [], "subtotal": 0, "labor": 0, "contingency": 0, "total": 0}
    }

    items = vision_json.get("items", [])
    complexity_flags = vision_json.get("complexity_flags", {})
    
    # Calculate base item costs
    for item in items:
        # Normalize item name to match catalog keys (simple mapping for demo)
        # In a real app, this would be more robust (fuzzy match or LLM mapping)
        catalog_key = _map_item_to_catalog(item.get("name"))
        quantity = item.get("quantity", 1)
        
        if catalog_key and catalog_key in catalog_prices:
            prices = catalog_prices[catalog_key]
            
            for tier in ["economy", "standard", "premium"]:
                cost = prices.get(tier, 0) * quantity
                estimates[tier]["items"].append({
                    "name": item.get("name"),
                    "quantity": quantity,
                    "unit_price": prices.get(tier, 0),
                    "cost": cost
                })
                estimates[tier]["subtotal"] += cost
        else:
             # Item not in catalog, maybe log or add a default placeholder?
             # For now, just adding with 0 cost but listing it
             for tier in ["economy", "standard", "premium"]:
                estimates[tier]["items"].append({
                    "name": item.get("name") + " (Not in catalog)",
                    "quantity": quantity,
                    "unit_price": 0,
                    "cost": 0
                })

    # Calculate Labor & Contingency
    # Labor: 10-25% based on complexity
    labor_percent = 0.10
    if complexity_flags.get("false_ceiling"): labor_percent += 0.05
    if complexity_flags.get("built_in_storage"): labor_percent += 0.05
    if complexity_flags.get("custom_carpentry"): labor_percent += 0.05
    
    # Cap at 25%
    labor_percent = min(labor_percent, 0.25)
    
    # Contingency: 5-10% (Using 10% for safety)
    contingency_percent = 0.10
    
    for tier in ["economy", "standard", "premium"]:
        subtotal = estimates[tier]["subtotal"]
        
        labor_cost = int(subtotal * labor_percent)
        contingency_cost = int(subtotal * contingency_percent)
        
        estimates[tier]["labor"] = labor_cost
        estimates[tier]["contingency"] = contingency_cost
        estimates[tier]["total"] = subtotal + labor_cost + contingency_cost
        estimates[tier]["labor_percent"] = labor_percent # Store for display
        estimates[tier]["contingency_percent"] = contingency_percent

    return estimates

def _map_item_to_catalog(item_name):
    """
    Simple helper to map extracted names to catalog structure.
    In a real app, use fuzzy matching or embedding search.
    """
    item_name = item_name.lower()
    
    # Check for specific hardware first to avoid matching "door" in "door handle"
    if "closer" in item_name: return "door_closer"
    if "handle" in item_name or "pull" in item_name: return "hardware_set"
    
    # Room elements
    if "sofa" in item_name: return "sofa_3_seater"
    if "table" in item_name and "coffee" in item_name: return "coffee_table"
    if "rug" in item_name or "carpet" in item_name: return "area_rug"
    if "curtain" in item_name: return "curtains_set"
    if "light" in item_name or "lamp" in item_name: return "ceiling_light"
    if "floor" in item_name: return "flooring_sqft"
    
    # Commercial specific
    if "door" in item_name: return "commercial_door"
    if "panel" in item_name and ("wall" in item_name or "cladding" in item_name): return "wall_paneling_sqft"
    if "ceiling" in item_name: return "acoustic_ceiling_sqft"
    if "screen" in item_name and "projection" in item_name: return "projector_screen"
    if "speaker" in item_name or "sensor" in item_name or "device" in item_name: return "sensor_device"
    
    return None
