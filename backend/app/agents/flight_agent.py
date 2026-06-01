import logging
from app.client.serp_client import serp_client
from app.client.gemini_client import gemini_client
from app.models.final_trip_request import FinalTripRequest

logger = logging.getLogger(__name__)

MAX_FLIGHTS = 6  # how many raw flights to pass to the ranking agent

def _parse_time(datetime_str: str) -> tuple[str, str]:
    """Split "2026-09-05 08:30" into ("2026-09-05", "08:30")."""
    parts = datetime_str.split(" ")
    if len(parts) == 2:
        return parts[0], parts[1]
    return datetime_str, ""

async def _resolve_airport_code(location: str) -> str:
    logger.info("[flight_agent] Resolving airport code for: '%s'", location)
    raw = gemini_client.generate_text(
        model="gemini-flash-latest",
        user_prompt=f"What is the nearest major commercial IATA airport code for traveling to or from: {location}? Reply with the 3-letter code only. Example: SFO",
        system_prompt="You are an airport code lookup tool. Return only the 3-letter IATA code, nothing else. No explanation.",
    )
    code = raw.strip().upper()[:3]
    logger.info("[flight_agent] Airport code for '%s' → %s", location, code)
    return code

def _extract_flights(raw: dict) -> list[dict]:
    results = []

    # SerpAPI returns "best_flights" and "other_flights"
    candidates = raw.get("best_flights", []) + raw.get("other_flights", [])

    for option in candidates[:MAX_FLIGHTS]:
        segments = option.get("flights", [])
        if not segments:
            continue

        first_seg = segments[0]
        last_seg = segments[-1]

        dep_date, dep_time = _parse_time(first_seg.get("departure_airport", {}).get("time", ""))
        arr_date, arr_time = _parse_time(last_seg.get("arrival_airport", {}).get("time", ""))

        layover_names = [
            lv.get("name", lv.get("id", "Unknown"))
            for lv in option.get("layovers", [])
        ]

        duration_minutes = option.get("total_duration", 0)
        duration_hours = round(duration_minutes / 60, 1)

        booking_url = raw.get("search_metadata", {}).get("google_flights_url")

        results.append({
            "airline": first_seg.get("airline", "Unknown"),
            "origin": first_seg.get("departure_airport", {}).get("id", ""),
            "destination": last_seg.get("arrival_airport", {}).get("id", ""),
            "departureDate": dep_date,
            "departureTime": dep_time,
            "returnDate": arr_date,
            "returnTime": arr_time,
            "duration": duration_hours,
            "layovers": layover_names,
            "price": option.get("price", 0),
            "bookingUrl": booking_url,
        })

    return results

async def fetch_flights(request: FinalTripRequest) -> list[dict]:
    origin = await _resolve_airport_code(request.route.origin or "")
    # Use the pre-resolved gateway airport if available — avoids a redundant Gemini call
    destination = request.route.gatewayAirport or await _resolve_airport_code(request.route.destination or "")
    departure = request.schedule.departureDate or ""
    returning = request.schedule.returnDate or ""
    adults = request.travelerInfo.resolved_traveler_count or 1
    children = len(request.travelerInfo.kidsAges or [])

    logger.info("[flight_agent] Searching SerpAPI flights: %s → %s | out: %s | return: %s | adults: %d | children: %d",
                origin, destination, departure, returning, adults, children)

    raw = await serp_client.search_flights(
        origin=origin,
        destination=destination,
        outbound_date=departure,
        return_date=returning,
        adults=adults,
        children=children,
    )

    flights = _extract_flights(raw)
    logger.info("[flight_agent] SerpAPI returned %d flight options", len(flights))
    return flights
