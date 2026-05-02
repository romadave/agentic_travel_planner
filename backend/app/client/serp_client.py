import os
import httpx
from dotenv import load_dotenv

load_dotenv()

SERP_BASE_URL = "https://serpapi.com/search"

class SerpAPIClient:
    def __init__(self) -> None:
        api_key = os.getenv("SERP_API_KEY")
        if not api_key:
            raise ValueError("SERP_API_KEY is not set in .env")
        self.api_key = api_key

    async def search_flights(
        self,
        origin: str,
        destination: str,
        outbound_date: str,
        return_date: str,
        adults: int,
        children: int = 0,
    ) -> dict:
        params = {
            "engine": "google_flights",
            "departure_id": origin,
            "arrival_id": destination,
            "outbound_date": outbound_date,
            "return_date": return_date,
            "adults": adults,
            "children": children,
            "currency": "USD",
            "hl": "en",
            "api_key": self.api_key,
        }
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.get(SERP_BASE_URL, params=params)
            response.raise_for_status()
            return response.json()

    async def search_hotels(
        self,
        location: str,
        check_in_date: str,
        check_out_date: str,
        adults: int,
        children: int = 0,
    ) -> dict:
        params = {
            "engine": "google_hotels",
            "q": f"Hotels in {location}",
            "check_in_date": check_in_date,
            "check_out_date": check_out_date,
            "adults": adults,
            "currency": "USD",
            "hl": "en",
            "api_key": self.api_key,
        }
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.get(SERP_BASE_URL, params=params)
            response.raise_for_status()
            return response.json()


serp_client = SerpAPIClient()
