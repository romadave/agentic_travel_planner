from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List

from app.models.final_trip_request import ItineraryOption, FlightOption
from app.utils.excel_generator import generate_itinerary_excel
from app.utils.pdf_generator import generate_itinerary_pdf
from app.utils.email_sender import send_itinerary_email

router = APIRouter()


class ShareItineraryRequest(BaseModel):
    email: str
    itinerary: ItineraryOption
    flights: List[FlightOption]


@router.post("/share-itinerary")
async def share_itinerary(request: ShareItineraryRequest):
    try:
        destination = request.itinerary.days[0].area if request.itinerary.days else "your destination"
        excel_bytes = generate_itinerary_excel(request.itinerary, request.flights)
        pdf_bytes = generate_itinerary_pdf(request.itinerary, request.flights)
        await send_itinerary_email(request.email, excel_bytes, pdf_bytes, destination)
        return {"success": True}
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")
