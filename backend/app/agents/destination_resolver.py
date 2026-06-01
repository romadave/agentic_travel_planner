import json
import logging
from app.client.gemini_client import gemini_client

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """
You are a travel destination normalizer. Given any destination description — a landmark, national park, neighborhood, city, or region — resolve it to a proper travel destination a trip planner can use.

Return a JSON object with exactly these two fields:
- "resolvedDestination": the proper city or region for trip planning (e.g. "Banff, Alberta, Canada")
- "gatewayAirport": the nearest major commercial IATA airport code for flying there (e.g. "YYC")

Rules:
1. Landmark → resolve to the city it's in. ("Eiffel Tower" → "Paris, France", gateway "CDG")
2. National park or remote area → resolve to the nearest gateway town and nearest major airport. ("Banff National Park" → "Banff, Alberta, Canada", gateway "YYC")
3. Already a city → keep it, pick the best main airport.
4. Return valid JSON only. No markdown, no explanation.

Examples:
- "Eiffel Tower" → {"resolvedDestination": "Paris, France", "gatewayAirport": "CDG"}
- "Banff national park in Canada" → {"resolvedDestination": "Banff, Alberta, Canada", "gatewayAirport": "YYC"}
- "Yosemite" → {"resolvedDestination": "Yosemite, California, USA", "gatewayAirport": "FAT"}
- "Times Square" → {"resolvedDestination": "New York City, USA", "gatewayAirport": "JFK"}
- "Tokyo" → {"resolvedDestination": "Tokyo, Japan", "gatewayAirport": "NRT"}
"""

async def resolve_destination(raw_destination: str) -> dict:
    logger.info("[destination_resolver] Resolving: '%s'", raw_destination)
    raw = await gemini_client.generate_text(
        model="gemini-flash-latest",
        user_prompt=f"Destination: {raw_destination}",
        system_prompt=SYSTEM_PROMPT,
    )
    raw = raw.strip()
    start = raw.find("{")
    end = raw.rfind("}")
    if start == -1 or end == -1:
        logger.warning("[destination_resolver] No JSON in Gemini response, using raw input as fallback")
        return {"resolvedDestination": raw_destination, "gatewayAirport": ""}
    try:
        result = json.loads(raw[start:end + 1])
        logger.info("[destination_resolver] Resolved to: '%s' (airport: %s)",
                    result.get("resolvedDestination"), result.get("gatewayAirport"))
        return result
    except json.JSONDecodeError:
        logger.error("[destination_resolver] JSON parse failed. Raw response: %s", raw)
        return {"resolvedDestination": raw_destination, "gatewayAirport": ""}
