from fastapi import APIRouter
from fastapi.responses import FileResponse
from pydantic import BaseModel

from app.agents.flight_agent import rank_flights_with_gemini
from app.agents.hotel_agent import fetch_hotels
from app.services.excel_writer import add_multiple_sheets_to_excel, create_data_frame

router = APIRouter(tags=["Reports"])

class TripRequest(BaseModel):
    origin: str
    destination: str
    departure_date: str
    return_date: str
    toddler_age: int


@router.post("/generate-report")
def generate_report(trip_request: TripRequest):
    ranked_flights = rank_flights_with_gemini(
        trip_request=trip_request.model_dump())

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