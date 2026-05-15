# How to Run the Backend

## 1. Activate the virtual environment
Every time you open a new terminal, run this first:
```
source .venv/bin/activate
```
You'll see (.venv) appear at the start of your terminal prompt.
This means Python is now using the packages installed in this project, not your system Python.

Why: Python projects use virtual environments to isolate dependencies.
Each project gets its own sandbox so packages don't conflict across projects.
Think of it like a Flutter pubspec.yaml — but at the Python level.

## 2. Install dependencies (first time only, or after adding new packages)
```
pip install -r requirements.txt
```
This reads requirements.txt and installs every listed package.
After adding a new package with pip install <package>, run:
```
pip freeze > requirements.txt
```
This saves the updated list back to requirements.txt so teammates can install the same versions.

## 3. Set up your .env file
Create a file called .env in the backend/ folder (same level as requirements.txt).
Add your API keys:
```
GEMINI_API_KEY=your_gemini_key_here
SERP_API_KEY=your_serpapi_key_here
```
This file is in .gitignore — it will never be committed to git.
python-dotenv reads this file automatically when the server starts.

## 4. Start the server
```
uvicorn app.main:app --reload
```
Breaking this down:
- uvicorn       → the ASGI server that runs FastAPI apps
- app.main      → the Python module path (backend/app/main.py)
- :app          → the FastAPI instance inside main.py (the variable named "app")
- --reload      → auto-restarts the server when you save a file (dev mode only)

The server runs at: http://127.0.0.1:8000

## 5. Test your endpoints

Option A — Swagger UI (recommended for learning):
Open http://127.0.0.1:8000/docs in your browser.
FastAPI auto-generates an interactive playground for every endpoint.
You can paste JSON, hit Send, and see the response — no Postman needed.

Option B — curl from terminal:
```
curl -X POST http://127.0.0.1:8000/finalTripRequest \
  -H "Content-Type: application/json" \
  -d '{
    "route": { "originText": "SFO", "destinationText": "Maui" },
    "schedule": {
      "departureDateText": "2026-09-05",
      "returnDateText": "2026-09-10",
      "numberOfDays": 5
    },
    "travelerInfo": { "travelerCount": 2, "hasKids": true, "youngestTravelerAge": 2 },
    "transportPreferences": { "layoversAllowed": false, "budgetFlight": false },
    "lodgingPreferences": { "hotel": true, "isFamilyFriendly": true }
  }'
```

## 6. Stop the server
Press Ctrl+C in the terminal where uvicorn is running.

## Troubleshooting
- "SERP_API_KEY is not set" → your .env file is missing the key or you forgot to save it
- "ModuleNotFoundError" → your venv is not activated, run source .venv/bin/activate
- "Address already in use" → another process is on port 8000, run: lsof -i :8000 then kill <PID>

---

# Debugging External API Responses

When an external API (SerpAPI, Gemini, etc.) returns unexpected data — wrong fields, zeros, nulls — the fastest way to debug is to write a small throwaway script that calls the API directly and prints the raw response.

## Why this works
You can't trust assumptions about what an API returns. The only way to know the real shape of the data is to print it and look. Field names, nesting, and data types often differ from documentation.

## The pattern
Create a file like debug_hotels.py in your backend/ folder:

```python
import asyncio
import json
from dotenv import load_dotenv
load_dotenv()

from app.client.serp_client import serp_client

async def main():
    raw = await serp_client.search_hotels(
        location="Kaanapali, Maui",
        check_in_date="2026-09-05",
        check_out_date="2026-09-10",
        adults=2,
    )
    # Print first 2 results only so it's readable
    props = raw.get("properties", [])[:2]
    print(json.dumps(props, indent=2))

asyncio.run(main())
```

Run it — but always activate the venv first so Python can find your project packages:
```
source .venv/bin/activate
python3 debug_hotels.py
```

Why source first: your project packages (serpapi, google-genai, etc.) are installed inside .venv, not in your system Python. Without activating, python3 debug_hotels.py will fail with ModuleNotFoundError because it can't find app.client.serp_client or any other local imports.

Read the output and find the real field paths. Example of what we discovered:
- We assumed: prices[0].rate_per_night.extracted_lowest
- Reality:     prop.rate_per_night.extracted_lowest  ← one level up
- We assumed: prices[0].link
- Reality:     prop.link  ← directly on the property

Then fix your extraction code to use the real paths, and delete the debug file.

## Key rules
- Slice the results ([:2]) — printing 10 hotels with full image arrays is unreadable
- Use json.dumps(data, indent=2) — raw dict output is hard to scan
- Delete the debug file after — it's a throwaway tool, not production code
- The debug file lives in backend/ (same level as requirements.txt), not inside app/

---

# Fast API:
FastAPI is extremely popular for AI backends because:

• built for Python
• extremely fast
• automatic documentation
• strong typing
• simple JSON APIs

It’s used widely in:

LLM services
AI agents
ML inference servers
data APIs

# Pydantic
defines and validate data structures
basically you define the shape of incoming data and pydantic ensures its correct
so when someone sends a JSON to my API -> pydantic converts into a class object -> and then you can access fields like this: object.<field>

# model_dump()
model_dump() converts pydantic object into python dictionary -> as the function expects a python dictionary

# load_dotenv
loads the .env file and accesses the important keys

# http://127.0.0.1:8000/docs : 
This is great -> Fast API automatically generates OpenAI spec and Swagger UI -> helps in visualizing the endpoints.
Basically a built-in testing tool for our endpoints
An interactive API playground.

# CORS support
CORS = Cross origin resource sharing
browser security rule that controls which apps are allowed to call our API
If the origins are different, the browser blocks the request unless the server explicitly allows it.

What is "origin"?
protocal + domain + port
Example : 
http://localhost:3000
http://127.0.0.1:8000
https://example.com

When we add these CORS support -> essentially we are saying this origin is allowed to access our API
FastAPI handles this using CORS middleware.
Middleware is simply code that runs before requests reach your endpoints.

# routers
mini-collection of our endpoints
# services
# schemas
# agents
# ASGI server


# Server Side Events:
What is Server-Side Streaming (SSE)?                  
Right now your endpoint does all the work, then sends one big response. Streaming (specifically Server-Sent Events / SSE) lets the server push data to the client in chunks over a single HTTP connection as each piece becomes ready — the client doesn't wait.                                                                                                                                                                              

Think of it like a restaurant: currently you wait 30 minutes for all three courses to be plated at once. Streaming means the appetizer comes out as soon as it's ready, then the main, then dessert.                   
                                                       
# Key Concepts to Know Before You Start                              
async def vs async def with yield: When Python sees a yield inside an async def, it becomes an async generator. Instead of calling result = await plan_trip(request), the router iterates it: async for chunk in plan_trip (request).      

StreamingResponse in FastAPI: Takes a generator and media_type="text/event-stream". FastAPI handles pushing each yielded value to the client as it's produced.                                                         
                                                                                                                                                                                                                       
# SSE format rules:                        
  - Each message: data: <your JSON string>\n\n (exactly two newlines at the end)                                                                                                                                       
  - The \n\n is what tells the browser "this event is complete, process it"                                                                                                                                              
   