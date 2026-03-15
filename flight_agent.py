
import json

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


def fetch_flights():
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

    return flights


def get_prompt(trip_request, flights):
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

    return prompt


def rank_flights_with_gemini(trip_request, client):
    flights = fetch_flights()
    prompt = get_prompt(trip_request=trip_request, flights=flights)
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

    return combined_results
