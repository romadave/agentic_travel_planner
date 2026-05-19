from pydantic import BaseModel
from typing import Optional, List
from app.models.prompt_response import TravelerInfo, TransportPreferences, LodgingPreferences

# ── /finalTripRequest — Input model ──────────────────────────────────
# Mirrors TripRequestDraft from iOS

class Route(BaseModel):
    originText: Optional[str] = None
    destinationText: Optional[str] = None

class Schedule(BaseModel):
    departureDateText: Optional[str] = None
    returnDateText: Optional[str] = None
    numberOfDays: Optional[int] = None

class FinalTripRequest(BaseModel):
    route: Route = Route()
    schedule: Schedule = Schedule()
    travelerInfo: TravelerInfo = TravelerInfo()
    transportPreferences: TransportPreferences = TransportPreferences()
    lodgingPreferences: LodgingPreferences = LodgingPreferences()


# ── /finalTripRequest — Output models ────────────────────────────────

class DestinationInfo(BaseModel):
    country: str
    tagline: str
    weather: str
    timezone: str

class PartOfDay(BaseModel):
    activity: Optional[str] = None
    place: Optional[str] = None
    foodSuggestion: Optional[str] = None
    notes: Optional[str] = None
    includeNap: bool = False

class TripDay(BaseModel):
    dayNumber: int
    date: str                   # "2026-09-05"
    area: str                   # "Lahaina"
    morning: Optional[PartOfDay] = None
    afternoon: Optional[PartOfDay] = None
    evening: Optional[PartOfDay] = None

class ItineraryStop(BaseModel):
    area: str                   # "Lahaina, Maui" — used for hotel search
    nights: int

class ItineraryDraft(BaseModel):
    optionNumber: int
    style: str                  # "Base Camp" | "Island Explorer"
    description: str
    days: List[TripDay]
    stops: List[ItineraryStop]  # extracted stops for hotel search

class FlightOption(BaseModel):
    rank: int
    airline: str
    flightNumber: Optional[str] = None
    score: int                  # 1–10, Gemini-assigned
    origin: str
    destination: str
    reason: str
    price: int
    duration: float             # hours
    layovers: List[str]
    departureDate: str
    departureTime: str
    returnDate: str
    returnTime: str
    bookingUrl: Optional[str] = None
    familyAmenities: Optional[List[str]] = None

class HotelOption(BaseModel):
    name: str
    type: Optional[str] = None  # "Apartment", "Boutique Hotel", etc.
    area: str
    rating: float
    pricePerNight: float
    totalPrice: float
    amenities: List[str]
    score: int                  # 1–10, Gemini-assigned
    reason: str
    bookingUrl: Optional[str] = None

class HotelStop(BaseModel):
    area: str
    nights: int
    hotels: List[HotelOption]

class ItineraryOption(BaseModel):
    optionNumber: int
    style: str
    description: str
    days: List[TripDay]
    hotelStops: List[HotelStop]

class FinalTripResponse(BaseModel):
    flights: List[FlightOption]
    itineraryOptions: List[ItineraryOption]
    cannotGenerate: bool = False
    reason: Optional[str] = None