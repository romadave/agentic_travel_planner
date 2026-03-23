from fastapi import APIRouter
from pydantic import BaseModel

from app.agents.hotel_agent import fetch_hotels

router = APIRouter(tags=["Hotels"])


class TripRequest(BaseModel):
    origin: str
    destination: str
    departure_date: str
    return_date: str
    toddler_age: int


@router.post("/rank-hotels")
def rank_hotels(trip_request: TripRequest):
    ranked_hotels = fetch_hotels()

    return {
        "trip_request": trip_request.model_dump(),
        "ranked_hotels": ranked_hotels
    }