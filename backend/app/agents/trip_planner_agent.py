import asyncio
from app.agents.itinerary_agent import generate_itinerary_options
from app.agents.flight_agent import fetch_flights
from app.agents.hotel_agent import fetch_hotels_for_itineraries
from app.agents.ranking_agent import rank_flights_and_hotels
from app.models.final_trip_request import FinalTripRequest, FinalTripResponse

async def plan_trip(request: FinalTripRequest) -> FinalTripResponse:
    # Step 1: Build itinerary options first — drives everything else
    itinerary_drafts = await generate_itinerary_options(request)

    # Step 2: Fetch flights + hotels in parallel
    flights_raw, hotels_by_area = await asyncio.gather(
        fetch_flights(request),
        fetch_hotels_for_itineraries(itinerary_drafts, request),
    )

    # Step 3: Rank flights and match + rank hotels to each itinerary option
    ranked_flights, itinerary_options = await rank_flights_and_hotels(
        request=request,
        flights=flights_raw,
        itinerary_drafts=itinerary_drafts,
        hotels_by_area=hotels_by_area,
    )

    return FinalTripResponse(
        flights=ranked_flights,
        itineraryOptions=itinerary_options,
    )
