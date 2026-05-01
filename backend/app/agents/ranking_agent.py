import json
from app.client.gemini_client import gemini_client
from app.models.final_trip_request import (
    FinalTripRequest,
    ItineraryDraft,
    FlightOption,
    HotelOption,
    HotelStop,
    ItineraryOption,
)

SYSTEM_PROMPT = """
You are a family travel expert ranking flights and hotels for a trip with young children.

You will receive:
1. A list of raw flights
2. A list of itinerary options, each with stops and available hotels per stop

Your job:
- Rank and score each flight 1-10. Higher = better for a family with a toddler.
  Prefer: direct flights, morning departures, shorter total duration, reasonable price.
- For each itinerary option, rank and score the hotels at each stop 1-10.
  Prefer: family-friendly amenities, good ratings, proximity to that stop's activities, cribs/family rooms.
- Sort flights and hotels best-first.

Rules:
1. Return valid JSON only. No markdown, no explanation.
2. Keep all original flight fields. Add "rank", "score", "reason".
3. Keep all original hotel fields. Add "score", "reason", "totalPrice" (pricePerNight * nights).
4. If a stop has no hotels, return an empty hotels array for it.

JSON schema:
{
  "rankedFlights": [
    {
      "rank": 1,
      "airline": "...",
      "score": 9,
      "reason": "...",
      "origin": "...",
      "destination": "...",
      "price": 850,
      "duration": 5.5,
      "layovers": [],
      "departureDate": "...",
      "departureTime": "...",
      "returnDate": "...",
      "returnTime": "...",
      "bookingUrl": "..."
    }
  ],
  "rankedItineraryOptions": [
    {
      "optionNumber": 1,
      "hotelStops": [
        {
          "area": "Lahaina, Maui",
          "nights": 5,
          "hotels": [
            {
              "name": "...",
              "area": "...",
              "rating": 4.5,
              "pricePerNight": 300.0,
              "totalPrice": 1500.0,
              "amenities": ["Pool", "Beach access"],
              "score": 9,
              "reason": "...",
              "bookingUrl": "..."
            }
          ]
        }
      ]
    }
  ]
}
"""

def _build_user_prompt(
    request: FinalTripRequest,
    flights: list[dict],
    itinerary_drafts: list[ItineraryDraft],
    hotels_by_area: dict[str, list[dict]],
) -> str:
    youngest_age = request.travelerInfo.youngestTravelerAge
    traveler_count = request.travelerInfo.travelerCount or 2
    toddler_note = f"{youngest_age} years old" if youngest_age is not None else "young child"

    options_with_hotels = []
    for draft in itinerary_drafts:
        stops_with_hotels = []
        for stop in draft.stops:
            stops_with_hotels.append({
                "area": stop.area,
                "nights": stop.nights,
                "availableHotels": hotels_by_area.get(stop.area, []),
            })
        options_with_hotels.append({
            "optionNumber": draft.optionNumber,
            "stops": stops_with_hotels,
        })

    return f"""
Family trip details:
- Travelers: {traveler_count} people, youngest is a {toddler_note}
- Origin: {request.route.originText}
- Destination: {request.route.destinationText}
- Layovers allowed: {request.transportPreferences.layoversAllowed}
- Budget flight preferred: {request.transportPreferences.budgetFlight}

FLIGHTS TO RANK:
{json.dumps(flights, indent=2)}

ITINERARY OPTIONS WITH HOTELS TO RANK:
{json.dumps(options_with_hotels, indent=2)}
"""

def _parse_response(raw: str) -> dict:
    raw = raw.strip()
    start = raw.find("{")
    end = raw.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("No JSON found in Gemini ranking response")
    return json.loads(raw[start:end + 1])

def _build_flight_options(ranked_flights: list[dict]) -> list[FlightOption]:
    return [FlightOption(**f) for f in ranked_flights]

def _build_itinerary_options(
    ranked_options: list[dict],
    itinerary_drafts: list[ItineraryDraft],
) -> list[ItineraryOption]:
    draft_map = {d.optionNumber: d for d in itinerary_drafts}
    result = []

    for option in ranked_options:
        draft = draft_map.get(option["optionNumber"])
        if not draft:
            continue

        hotel_stops = [
            HotelStop(
                area=stop["area"],
                nights=stop["nights"],
                hotels=[HotelOption(**h) for h in stop.get("hotels", [])],
            )
            for stop in option.get("hotelStops", [])
        ]

        result.append(ItineraryOption(
            optionNumber=draft.optionNumber,
            style=draft.style,
            description=draft.description,
            days=draft.days,
            hotelStops=hotel_stops,
        ))

    return result

async def rank_flights_and_hotels(
    request: FinalTripRequest,
    flights: list[dict],
    itinerary_drafts: list[ItineraryDraft],
    hotels_by_area: dict[str, list[dict]],
) -> tuple[list[FlightOption], list[ItineraryOption]]:
    user_prompt = _build_user_prompt(request, flights, itinerary_drafts, hotels_by_area)
    raw = gemini_client.generate_text(
        model="gemini-2.5-pro",
        user_prompt=user_prompt,
        system_prompt=SYSTEM_PROMPT,
    )
    parsed = _parse_response(raw)

    flight_options = _build_flight_options(parsed["rankedFlights"])
    itinerary_options = _build_itinerary_options(parsed["rankedItineraryOptions"], itinerary_drafts)

    return flight_options, itinerary_options
