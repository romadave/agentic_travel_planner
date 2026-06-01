import json
from app.client.gemini_client import gemini_client
from app.models.final_trip_request import FinalTripRequest, DestinationInfo

SYSTEM_PROMPT = """
You are a travel expert providing destination highlights for a family trip.

Given a destination and travel month, return a JSON object with exactly these fields:
- "country": the full country or destination name(e.g. "Portugal")
- "tagline": a short, evocative 1-line description of the destination (max 10 words, poetic tone)
- "weather": typical weather for that month as a short string (e.g. "26° · Sunny", "18° · Partly Cloudy")
- "timezone": the timezone in GMT offset format (e.g. "GMT+1", "GMT-5")

Rules:
1. Return valid JSON only. No markdown, no explanation.
2. Weather should reflect the destination's typical conditions for that specific month.
3. Tagline should be vivid and capture the spirit of the place.

JSON schema:
{
  "country": "...",
  "tagline": "...",
  "weather": "...",
  "timezone": "..."
}
"""

async def generate_destination_info(request: FinalTripRequest) -> DestinationInfo:
    destination = request.route.resolvedDestination or request.route.destination or "Unknown destination"
    departure = request.schedule.departureDate or "Unknown date"

    user_prompt = f"""
Destination: {destination}
Travel month: {departure}
"""
    raw = await gemini_client.generate_text(
        model="gemini-3.5-flash",
        user_prompt=user_prompt,
        system_prompt=SYSTEM_PROMPT,
    )
    raw = raw.strip()
    start = raw.find("{")
    end = raw.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("No JSON found in Gemini destination response")
    parsed = json.loads(raw[start:end + 1])
    return DestinationInfo(**parsed)
