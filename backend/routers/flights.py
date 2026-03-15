import os
from fastapi import APIRouter
from pydantic import BaseModel
from dotenv import load_dotenv
from google import genai

from backend.agents.flight_agent import rank_flights_with_gemini

router = APIRouter(tags=["Flights"])

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("GEMINI_API_KEY not found in .env")

client = genai.Client(api_key=api_key)


class TripRequest(BaseModel):
    origin: str
    destination: str
    departure_date: str
    return_date: str
    toddler_age: int


@router.post("/rank-flights")
def rank_flights(trip_request: TripRequest):
    ranked_flights = rank_flights_with_gemini(
        trip_request=trip_request.model_dump(),
        client=client
    )

    return {
        "trip_request": trip_request.model_dump(),
        "ranked_flights": ranked_flights
    }