import asyncio
from app.client.serp_client import serp_client
from app.models.final_trip_request import FinalTripRequest, ItineraryDraft

MAX_HOTELS_PER_AREA = 5

def _extract_hotels(raw: dict, area: str) -> list[dict]:
    results = []

    for prop in raw.get("properties", [])[:MAX_HOTELS_PER_AREA]:
        prices = prop.get("prices", [])
        price_per_night = 0.0
        booking_url = None

        if prices:
            rate = prices[0].get("rate_per_night", {})
            price_per_night = rate.get("extracted_lowest", 0.0)
            booking_url = prices[0].get("link")

        results.append({
            "name": prop.get("name", "Unknown Hotel"),
            "area": area,
            "rating": prop.get("overall_rating") or prop.get("rating", 0.0),
            "pricePerNight": price_per_night,
            "amenities": prop.get("amenities", []),
            "bookingUrl": booking_url,
        })

    return results

async def _search_area(area: str, request: FinalTripRequest) -> tuple[str, list[dict]]:
    adults = request.travelerInfo.travelerCount or 1
    children = 1 if request.travelerInfo.hasKids else 0
    check_in = request.schedule.departureDateText or ""
    check_out = request.schedule.returnDateText or ""

    raw = await serp_client.search_hotels(
        location=area,
        check_in_date=check_in,
        check_out_date=check_out,
        adults=adults,
        children=children,
    )

    return area, _extract_hotels(raw, area)

async def fetch_hotels_for_itineraries(
    itinerary_drafts: list[ItineraryDraft],
    request: FinalTripRequest,
) -> dict[str, list[dict]]:
    # Collect unique areas across all itinerary options
    unique_areas = {
        stop.area
        for draft in itinerary_drafts
        for stop in draft.stops
    }

    # Search all areas in parallel
    tasks = [_search_area(area, request) for area in unique_areas]
    results = await asyncio.gather(*tasks)

    return dict(results)
