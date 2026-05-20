import json
from app.client.gemini_client import gemini_client
from app.models.final_trip_request import FinalTripRequest, ItineraryDraft

# TODO : make dynamic user prompt based on user context and not a static one. lets start with this first
SYSTEM_PROMPT = """
You are an expert family travel planner specializing in trips with young children and toddlers.

Your job is to generate 2-3 distinct itinerary options for a family trip.
Each option should reflect a different travel style so the family can choose what suits them.

Rules:
1. Consider toddler needs: nap windows (typically after lunch), stroller accessibility, short activity durations.
2. Each option must have a clearly different travel style (e.g. "Base Camp" = stay in one place, "Island Explorer" = move between areas).
3. Every day must belong to a geographic area that matches a stop.
4. stops[] must list every unique area with the correct number of nights — this drives hotel search.
5. area names in stops[] must be specific enough for a hotel search (e.g. "Lahaina, Maui" not just "Maui").
6. Return valid JSON only. No markdown, no explanation.

JSON schema:
{
  "itinerary_options": [
    {
      "optionNumber": 1,
      "style": "Base Camp",
      "description": "Why this style suits this family",
      "days": [
        {
          "dayNumber": 1,
          "date": "YYYY-MM-DD",
          "area": "Area name",
          "morning": {
            "activity": "What to do",
            "place": "Specific place name or null",
            "foodSuggestion": "Where/what to eat or null",
            "notes": "Toddler tips or null",
            "includeNap": false
          },
          "afternoon": { ... },
          "evening": { ... }
        }
      ],
      "stops": [
        { "area": "Lahaina, Maui", "nights": 5 }
      ]
    }
  ]
}
"""

def _build_user_prompt(request: FinalTripRequest) -> str:
    from datetime import date
    origin = request.route.origin or "unknown origin"
    destination = request.route.resolvedDestination or request.route.destination or "unknown destination"
    departure = request.schedule.departureDate or "TBD"
    returning = request.schedule.returnDate or "TBD"

    if request.schedule.numberOfDays:
        num_days = request.schedule.numberOfDays
    elif request.schedule.departureDate and request.schedule.returnDate:
        dep = date.fromisoformat(request.schedule.departureDate)
        ret = date.fromisoformat(request.schedule.returnDate)
        num_days = (ret - dep).days
    else:
        num_days = 7
    traveler_count = request.travelerInfo.travelerCount or 2
    youngest_age = request.travelerInfo.youngestTravelerAge
    has_kids = request.travelerInfo.hasKids
    layovers_ok = request.transportPreferences.layoversAllowed
    family_friendly = request.lodgingPreferences.isFamilyFriendly

    toddler_note = f"youngest traveler is {youngest_age} years old" if youngest_age is not None else "traveling with young children"
    layover_note = "layovers are acceptable" if layovers_ok else "prefers direct flights"

    return f"""
Plan a {num_days}-day family trip with the following details:

- Origin: {origin}
- Destination: {destination}
- Departure: {departure}
- Return: {returning}
- Travelers: {traveler_count} people, {toddler_note}
- Has kids: {has_kids}
- Flight preference: {layover_note}
- Family-friendly lodging required: {family_friendly}

Generate 2-3 distinct itinerary options. Make the styles clearly different.
"""

def _parse_response(raw: str) -> list[dict]:
    raw = raw.strip()
    start = raw.find("{")
    end = raw.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("No JSON found in Gemini itinerary response")
    parsed = json.loads(raw[start:end + 1])
    return parsed["itinerary_options"]

async def generate_itinerary_options(request: FinalTripRequest) -> list[ItineraryDraft]:
    user_prompt = _build_user_prompt(request)
    raw = gemini_client.generate_text(
        model="gemini-flash-latest",
        user_prompt=user_prompt,
        system_prompt=SYSTEM_PROMPT,
    )
    options_data = _parse_response(raw)
    return [ItineraryDraft(**option) for option in options_data]
