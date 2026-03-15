import os
from google import genai
from dotenv import load_dotenv
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from routers import flights, hotels, reports

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all origins (good for development)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# reads the .env file in your project and loads the values inside it into environment variables.
load_dotenv()
api_key = os.getenv('GEMINI_API_KEY')

if not api_key:
    raise ValueError('Gemini API key not found in .env')

client = genai.Client(api_key=api_key)

class TripRequest(BaseModel):
    origin:str
    destination:str
    departure_date:str
    return_date:str
    toddler_age:int

# my root endpoint
@app.get("/")
def root():
    return {"message": "Travel Planner API is running"}

app.include_router(flights.router)
app.include_router(hotels.router)
app.include_router(reports.router)