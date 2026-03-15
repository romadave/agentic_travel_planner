import os
from dotenv import load_dotenv
from google import genai
from trip_loader import load_trip_request
from excel_writer import create_data_frame, add_multiple_sheets_to_excel
from flight_agent import rank_flights_with_gemini
from hotel_agent import fetch_hotels

# reads the .env file in your project and loads the values inside it into environment variables.
load_dotenv()
api_key = os.getenv('GEMINI_API_KEY')

if not api_key:
    raise ValueError('Gemini API key not found in .env')

client = genai.Client(api_key=api_key)

trip_request = load_trip_request()

# finds flights/hotels and then gemini ranks them
ranked_flights = rank_flights_with_gemini(trip_request=trip_request, client=client)
ranked_hotels = fetch_hotels()

# this converts my dictionary into table format
flights_df = create_data_frame(information=ranked_flights)
hotel_df = create_data_frame(information=ranked_hotels)

add_multiple_sheets_to_excel(
    trip_request=trip_request,
    sheets_data={
        "Flights": flights_df,
        "Hotels": hotel_df
    }
)
