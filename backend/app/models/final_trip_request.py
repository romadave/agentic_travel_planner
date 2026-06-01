from pydantic import BaseModel, field_validator
from typing import Optional, List
from app.models.prompt_response import TravelerInfo, TransportPreferences, LodgingPreferences

# ── /finalTripRequest — Input model ──────────────────────────────────
# Mirrors TripRequestDraft from iOS

class Route(BaseModel):
    origin: Optional[str] = None
    destination: Optional[str] = None
    resolvedDestination: Optional[str] = None  # normalized city/region after AI lookup
    gatewayAirport: Optional[str] = None        # IATA code of nearest major airport

class Schedule(BaseModel):
    departureDate: Optional[str] = None
    returnDate: Optional[str] = None
    numberOfDays: Optional[int] = None

class FinalTripRequest(BaseModel):
    route: Route = Route()
    schedule: Schedule = Schedule()
    travelerInfo: TravelerInfo = TravelerInfo()
    transportPreferences: TransportPreferences = TransportPreferences()
    lodgingPreferences: LodgingPreferences = LodgingPreferences()
    tripPreferences: Optional[str] = None


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

    @field_validator('score', 'rank', 'price', mode='before')
    @classmethod
    def coerce_to_int(cls, v):
        return round(float(v))

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

    @field_validator('score', mode='before')
    @classmethod
    def coerce_to_int(cls, v):
        return round(float(v))

class HotelStop(BaseModel):
    area: str
    nights: int
    hotels: List[HotelOption]

    @field_validator('nights', mode='before')
    @classmethod
    def coerce_to_int(cls, v):
        return round(float(v))

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