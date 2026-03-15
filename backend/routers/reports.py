import os
from fastapi import APIRouter
from fastapi.responses import FileResponse
from pydantic import BaseModel
from dotenv import load_dotenv
from google import genai

from backend.agents.flight_agent import rank_flights_with_gemini
from backend.agents.hotel_agent import fetch_hotels
from backend.services.excel_writer import add_multiple_sheets_to_excel, create_data_frame

router = APIRouter(tags=["Reports"])

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


@router.post("/generate-report")
def generate_report(trip_request: TripRequest):
    ranked_flights = rank_flights_with_gemini(
        trip_request=trip_request.model_dump(),
        client=client
    )

    ranked_hotels = fetch_hotels()

    flights_df = create_data_frame(ranked_flights)
    hotels_df = create_data_frame(ranked_hotels)

    output_file = add_multiple_sheets_to_excel(
        trip_request=trip_request.model_dump(),
        sheets_data={
            "Flights": flights_df,
            "Hotels": hotels_df
        }
    )

    return FileResponse(
        path=output_file,
        filename=output_file,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )