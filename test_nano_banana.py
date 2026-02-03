import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()
genai.configure(api_key=os.getenv("GOOGLE_API_KEY"))

model = genai.GenerativeModel("models/gemini-2.5-flash-image")
response = model.generate_content("A futuristic aesthetic chair, minimalist design, high quality photography")

# How to handle the response? 
# Usually for image models, it contains image data.
print(f"Response: {response}")

# Save the image if possible
for i, candidate in enumerate(response.candidates):
    for part in candidate.content.parts:
        if part.inline_data:
            with open(f"test_image_{i}.png", "wb") as f:
                f.write(part.inline_data.data)
            print(f"Saved test_image_{i}.png")
        if part.file_data:
             print(f"File data found: {part.file_data}")
