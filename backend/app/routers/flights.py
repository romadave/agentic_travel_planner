from fastapi import APIRouter
from pydantic import BaseModel

from app.agents.flight_agent import rank_flights_with_gemini

router = APIRouter(tags=["Flights"])

class TripRequest(BaseModel):
    origin: str
    destination: str
    departure_date: str
    return_date: str
    toddler_age: int


@router.post("/rank-flights")
def rank_flights(trip_request: TripRequest):
    ranked_flights = rank_flights_with_gemini(
        trip_request=trip_request.model_dump())

    return {
        "trip_request": trip_request.model_dump(),
        "ranked_flights": ranked_flights
    }