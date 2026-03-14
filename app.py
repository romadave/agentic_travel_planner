import os
from dotenv import load_dotenv
from google import genai
import json
import pandas as pd

# reads the .env file in your project and loads the values inside it into environment variables.
load_dotenv()
api_key = os.getenv('GEMINI_API_KEY')

if not api_key:
    raise ValueError('Gemini API key not found in .env')

client = genai.Client(api_key=api_key)

def parse_json_response(text):
    cleaned = text.strip()

    if cleaned.startswith("```"):
        lines = cleaned.splitlines()

        if lines and lines[0].startswith("```"):
            lines = lines[1:]

        if lines and lines[-1].startswith("```"):
            lines = lines[:-1]

        cleaned = "\n".join(lines).strip()
    
    return json.loads(cleaned)

with open("trip_request.json", "r") as file:
    trip_request = json.load(file)

flights = [
    {
        "airline": "Swiss Air",
        "price": 1080,
        "duration_hours": 11.0,
        "layovers": 0,
        "departure_date": "2026-09-05",
        "departure_time": "13:10",
        "arrival_date": "2026-09-06",
        "arrival_time": "18:10"
    },
    {
        "airline": "Lufthansa",
        "price": 890,
        "duration_hours": 14.2,
        "layovers": 1,
        "departure_date": "2026-09-05",
        "departure_time": "10:00",
        "arrival_date": "2026-09-06",
        "arrival_time": "21:45"
    },
    {
        "airline": "British Airways",
        "price": 830,
        "duration_hours": 15.5,
        "layovers": 1,
        "departure_date": "2026-09-05",
        "departure_time": "16:30",
        "arrival_date": "2026-09-06",
        "arrival_time": "23:50"
    }
]

hotels = [
    {
        "hotel_name": "Central Family Suites",
        "price_per_night": 260,
        "rating": 9.1,
        "distance_to_center_km": 0.4,
        "crib_available": True,
        "kitchen": True
    },
    {
        "hotel_name": "Budget City Stay",
        "price_per_night": 155,
        "rating": 7.8,
        "distance_to_center_km": 3.8,
        "crib_available": False,
        "kitchen": False
    },
    {
        "hotel_name": "Parkside Aparthotel",
        "price_per_night": 220,
        "rating": 8.8,
        "distance_to_center_km": 1.2,
        "crib_available": True,
        "kitchen": True
    }
]

prompt = f"""
You are a travel planning assistant for parents traveling with a toddler.

Trip details:
- Origin: {trip_request["origin"]}
- Destination: {trip_request["destination"]}
- Departure date: {trip_request["departure_date"]}
- Return date: {trip_request["return_date"]}
- Toddler age: {trip_request["toddler_age"]}

Rank these outbound flights from best to worst.

Preferences:
- Prefer direct flights
- Prefer shorter travel time
- Avoid late arrivals
- Fewer layovers are better
- Lower price is helpful, but convenience matters more when traveling with a toddler

Return the result as valid JSON with this shape:
{{
  "ranked_flights": [
    {{
      "rank": 1,
      "airline": "airline name",
      "score": 1-10,
      "reason": "short explanation"
    }}
  ]
}}

Flights:
{json.dumps(flights, indent=2)}
"""

response = client.models.generate_content(model='gemini-2.5-flash', contents=prompt)
parsed = parse_json_response(response.text)

flight_lookup = {f["airline"]: f for f in flights}

#making a dictionary from json
combined_results = []

for ranked in parsed["ranked_flights"]:
    airline = ranked["airline"]
    original = flight_lookup.get(airline, {})

    merged = {
        "trip_origin": trip_request["origin"],
        "trip_destination": trip_request["destination"],
        "trip_departure_date": trip_request["departure_date"],
        "trip_return_date": trip_request["return_date"],
        "rank": ranked["rank"],
        "airline": airline,
        "score": ranked["score"],
        "reason": ranked["reason"],
        "price": original.get("price"),
        "duration_hours": original.get("duration_hours"),
        "layovers": original.get("layovers"),
        "departure_date": original.get("departure_date"),
        "departure_time": original.get("departure_time"),
        "arrival_date": original.get("arrival_date"),
        "arrival_time": original.get("arrival_time")
    }

    combined_results.append(merged)

# this converts my dictionary into table format
flights_df = pd.DataFrame(combined_results)
hotel_df = pd.DataFrame(hotels)

output_file = f"Trip_{trip_request['origin']}_to_{trip_request['destination']}_{trip_request['departure_date']}.xlsx"

# index=False prevents pandas from adding an unnecessary index column.
with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
    flights_df.to_excel(writer, sheet_name='Flights', index=False)
    hotels_df.to_excel(writer, sheet_name='Hotels', index=False)
    
print(f"\nExcel file created: {output_file}")
