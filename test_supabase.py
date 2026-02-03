
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")

print(f"URL: {url}")
print(f"Key starts with: {key[:10]}...")

try:
    supabase = create_client(url, key)
    print("Client initialized.")
    
    # Try a simple fetch
    print("Testing connection...")
    response = supabase.table("analyses").select("*").limit(1).execute()
    print("Connection successful! Table exists.")
    print(f"Data: {response.data}")
    
except Exception as e:
    print(f"FATAL ERROR: {e}")
