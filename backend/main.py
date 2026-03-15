import os
from google import genai
from dotenv import load_dotenv
from fastapi import FastAPI
from pydantic import BaseModel
from flight_agent import rank_flights_with_gemini
from hotel_agent import fetch_hotels
from excel_writer import add_multiple_sheets_to_excel, create_data_frame
from fastapi.responses import FileResponse

app = FastAPI()

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

@app.post("/rank-flights")
def rank_flights(trip_request:TripRequest):
    ranked_flights = rank_flights_with_gemini(trip_request=trip_request.model_dump(), client=client)

    return {
        "trip_request":trip_request.model_dump(),
        "ranked_flights":ranked_flights
    }

# TODO : accept trip request as part of the prompt
@app.post("/rank-hotels")
def rank_hotels(trip_request:TripRequest):
    ranked_hotels = fetch_hotels(trip_request=trip_request.model_dump())

    return {
        "trip_request":trip_request.model_dump(),
        "ranked_hotels":ranked_hotels
    }

@app.post("/generate-report")
def generate_report(trip_request:TripRequest):
    ranked_flights = rank_flights_with_gemini(trip_request=trip_request.model_dump(), client=client)
    ranked_hotels = fetch_hotels()

    flights_df = create_data_frame(ranked_flights)
    hotels_df = create_data_frame(ranked_hotels)

    output_file = add_multiple_sheets_to_excel(trip_request=trip_request.model_dump(), sheets_data={
        "Flights":flights_df,
        "Hotels":hotels_df
    })

    return FileResponse(
        path = output_file,
        filename = output_file,
        media_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )