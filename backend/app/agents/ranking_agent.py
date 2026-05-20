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

FLIGHT_RANKING_PROMPT = """                                                                                                                                                                                            
  You are a family travel expert ranking flights for a trip with young children.
  Rank and score each flight 1-10. Higher = better for a family with a toddler.                                                                                                                                          
  Prefer: direct flights, morning departures, shorter total duration, reasonable price.                                                                                                                                  
  Sort flights best-first.                                                                                                                                                                                               
                                                                                                                                                                                                                         
  Rules:                                                                                                                                                                                                                 
  1. Return valid JSON only. No markdown, no explanation.                                                                                                                                                                
  2. Keep all original flight fields. Add "rank", "score", "reason".                                                                                                                                                     
                                                                                                                                                                                                                         
  JSON schema:                                                                                                                                                                                                           
  {                                                                                                                                                                                                                      
    "rankedFlights": [                                                                                                                                                                                                 
      { "rank": 1, "score": 9, "reason": "...", ...all original fields }                                                                                                                                                 
    ]                                                                                                                                                                                                                    
  }
  """  

HOTEL_RANKING_PROMPT = """
  You are a family travel expert ranking hotels for a trip with young children.                                                                                                                                          
  For each itinerary option, rank and score the hotels at each stop 1-10.
  Prefer: family-friendly amenities, good ratings, proximity to that stop's activities, cribs/family rooms.                                                                                                              
                                                                                                                                                                                                                         
  Rules:                                                                                                                                                                                                                 
  1. Return valid JSON only. No markdown, no explanation.                                                                                                                                                                
  2. Keep all original hotel fields. Add "score" and "reason".                                                                                                                                                           
  3. If a stop has no hotels, return an empty hotels array for it.
                                                                                                                                                                                                                         
  JSON schema:                                                                                                                                                                                                         
  {                                                                                                                                                                                                                      
    "rankedItineraryOptions": [                                                                                                                                                                                        
      {
        "optionNumber": 1,                                                                                                                                                                                               
        "hotelStops": [
          {                                                                                                                                                                                                              
            "area": "...",                                                                                                                                                                                             
            "nights": 5,
            "hotels": [ { "score": 9, "reason": "...", ...all original fields } ]
          }                                                                                                                                                                                                              
        ]
      }                                                                                                                                                                                                                  
    ]                                                                                                                                                                                                                  
  }
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

async def rank_flights(                                                                                                                                                                                                
      request: FinalTripRequest,
      flights: list[dict],                                                                                                                                                                                               
  ) -> list[FlightOption]:                                                                                                                                                                                             
      user_prompt = f"""
      Family trip: {request.travelerInfo.travelerCount} travelers, youngest is {request.travelerInfo.youngestTravelerAge} years old.
      Origin: {request.route.origin}, Destination: {request.route.resolvedDestination or request.route.destination}
      Layovers allowed: {request.transportPreferences.layoversAllowed}                                                                                                                                                       
      Budget flight preferred: {request.transportPreferences.budgetFlight}                                                                                                                                               
      
      FLIGHTS TO RANK:                                                                                                                                                                                                     
      {json.dumps(flights, indent=2)}
      """                                                                                                                                                                                                                    
      raw = gemini_client.generate_text(
        model="gemini-flash-latest",                                                                                                                                                                                   
        user_prompt=user_prompt,                                                                                                                                                                                     
        system_prompt=FLIGHT_RANKING_PROMPT,
      )                                                                                                                                                                                                                  
      parsed = _parse_response(raw)
      return _build_flight_options(parsed["rankedFlights"])
    
async def rank_hotels(
      request: FinalTripRequest,                                                                                                                                                                                         
      itinerary_drafts: list[ItineraryDraft],                                                                                                                                                                          
      hotels_by_area: dict[str, list[dict]],
  ) -> list[ItineraryOption]:
      options_with_hotels = []
      for draft in itinerary_drafts:                                                                                                                                                                                     
          stops_with_hotels = [
              {                                                                                                                                                                                                          
                  "area": stop.area,                                                                                                                                                                                     
                  "nights": stop.nights,
                  "availableHotels": hotels_by_area.get(stop.area, []),                                                                                                                                                  
              }                                                                                                                                                                                                          
              for stop in draft.stops
          ]                                                                                                                                                                                                              
          options_with_hotels.append({                                                                                                                                                                                 
              "optionNumber": draft.optionNumber,
              "stops": stops_with_hotels,
          })                                                                                                                                                                                                             
   
      user_prompt = f"""                                                                                                                                                                                                 
      Family trip: {request.travelerInfo.travelerCount} travelers, youngest is {request.travelerInfo.youngestTravelerAge} years old.                                                                                       
      Destination: {request.route.resolvedDestination or request.route.destination}
      
      ITINERARY OPTIONS WITH HOTELS TO RANK:
      {json.dumps(options_with_hotels, indent=2)}                                                                                                                                                                            
      """                                                                                                                                                                                                                  
      raw = gemini_client.generate_text(
        model="gemini-flash-latest",                                                                                                                                                                                   
        user_prompt=user_prompt,
        system_prompt=HOTEL_RANKING_PROMPT,                                                                                                                                                                            
      )                                                                                                                                                                                                                
      parsed = _parse_response(raw)
      return _build_itinerary_options(parsed["rankedItineraryOptions"], itinerary_drafts)
