import asyncio
import json
from typing import AsyncGenerator
from app.agents.itinerary_agent import generate_itinerary_options
from app.agents.flight_agent import fetch_flights
from app.agents.hotel_agent import fetch_hotels_for_itineraries
from app.agents.ranking_agent import rank_flights
from app.agents.ranking_agent import rank_hotels
from app.models.final_trip_request import FinalTripRequest

async def plan_trip(request: FinalTripRequest) -> AsyncGenerator[str, None]:
    # Step 1: Build itinerary options first — yeild them immediately.
    itinerary_drafts = await generate_itinerary_options(request)
    yield json.dumps({
        "type":"itineraries", 
        "itineraryOptions":[d.model_dump() for d in itinerary_drafts]
    })

    # Step 2: Rank flights and match
    async def fetch_and_rank_flights():                                                                                                                                                                                
          flights_raw = await fetch_flights(request)
          return await rank_flights(request, flights_raw)                                                                                                                                                                

    # Step 3:  rank hotels to each itinerary option
    async def fetch_and_rank_hotels():
          hotels_by_area = await fetch_hotels_for_itineraries(itinerary_drafts, request)
          return await rank_hotels(request, itinerary_drafts, hotels_by_area)                                                                                                                                            
   
    flight_task = asyncio.create_task(fetch_and_rank_flights())                                                                                                                                                        
    hotel_task = asyncio.create_task(fetch_and_rank_hotels())

    ranked_flights = await flight_task                                                                                                                                                                               
    yield json.dumps({
          "type": "flights",
          "flights": [f.model_dump() for f in ranked_flights]
        })

    itinerary_options = await hotel_task                                                                                                                                                                               
    yield json.dumps({                                                                                                                                                                                               
          "type": "hotels",
          "itineraryOptions": [o.model_dump() for o in itinerary_options]
        })                                                                                                                                                                                                                 
   
    yield json.dumps({"type": "done"})
