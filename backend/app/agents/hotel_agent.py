import asyncio
import logging
from urllib.parse import quote_plus
from app.client.serp_client import serp_client
from app.models.final_trip_request import FinalTripRequest, ItineraryDraft

logger = logging.getLogger(__name__)

MAX_HOTELS_PER_AREA = 5

def _google_search_url(name: str, area: str) -> str:
    query = quote_plus(f"{name} {area} hotel booking")
    return f"https://www.google.com/search?q={query}"

def _extract_hotels(raw: dict, area: str) -> list[dict]:
    results = []

    for prop in raw.get("properties", [])[:MAX_HOTELS_PER_AREA]:
        name = prop.get("name", "Unknown Hotel")
        price_per_night = prop.get("rate_per_night", {}).get("extracted_lowest", 0.0)
        total_price = prop.get("total_rate", {}).get("extracted_lowest", 0.0)
        booking_url = prop.get("link") or _google_search_url(name, area)

        results.append({
            "name": name,
            "area": area,
            "rating": prop.get("overall_rating") or prop.get("rating", 0.0),
            "pricePerNight": price_per_night,
            "totalPrice": total_price,
            "amenities": prop.get("amenities", []),
            "bookingUrl": booking_url,
        })

    return results

async def _search_area(area: str, request: FinalTripRequest) -> tuple[str, list[dict]]:
    adults = request.travelerInfo.resolved_traveler_count or 1
    children = len(request.travelerInfo.kidsAges or [])
    check_in = request.schedule.departureDate or ""
    check_out = request.schedule.returnDate or ""

    logger.info("[hotel_agent] Searching SerpAPI hotels: '%s' | check-in: %s | check-out: %s | adults: %d | children: %d",
                area, check_in, check_out, adults, children)

    raw = await serp_client.search_hotels(
        location=area,
        check_in_date=check_in,
        check_out_date=check_out,
        adults=adults,
        children=children,
    )

    hotels = _extract_hotels(raw, area)
    logger.info("[hotel_agent] SerpAPI returned %d hotels for '%s'", len(hotels), area)
    return area, hotels

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
