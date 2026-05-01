from app.client.serp_client import serp_client
from app.models.final_trip_request import FinalTripRequest

MAX_FLIGHTS = 6  # how many raw flights to pass to the ranking agent

def _parse_time(datetime_str: str) -> tuple[str, str]:
    """Split "2026-09-05 08:30" into ("2026-09-05", "08:30")."""
    parts = datetime_str.split(" ")
    if len(parts) == 2:
        return parts[0], parts[1]
    return datetime_str, ""

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
    origin = request.route.originText or ""
    destination = request.route.destinationText or ""
    departure = request.schedule.departureDateText or ""
    returning = request.schedule.returnDateText or ""
    adults = request.travelerInfo.travelerCount or 1
    children = 1 if request.travelerInfo.hasKids else 0

    raw = await serp_client.search_flights(
        origin=origin,
        destination=destination,
        outbound_date=departure,
        return_date=returning,
        adults=adults,
        children=children,
    )

    return _extract_flights(raw)
