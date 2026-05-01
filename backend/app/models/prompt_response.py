from pydantic import BaseModel
from typing import Optional, List


# ── Existing parse-trip models (unchanged) ───────────────────────────

class ParsedPromptRoute(BaseModel):
    originText: Optional[str] = None
    destinationText: Optional[str] = None
    stops: Optional[List[str]] = None

class ParsedPromptSchedule(BaseModel):
    departureDateText: Optional[str] = None
    returnDateText: Optional[str] = None
    numberOfDays: Optional[int] = None
    dateText: Optional[str] = None

class LodgingPreferences(BaseModel):
    hotel: Optional[bool] = None
    airbnb: Optional[bool] = None
    isFamilyFriendly: Optional[bool] = None

class TransportPreferences(BaseModel):
    flightSelected: Optional[bool] = None
    roadSelected: Optional[bool] = None
    trainSelected: Optional[bool] = None
    redEye: Optional[bool] = None
    budgetFlight: Optional[bool] = None
    layoversAllowed: Optional[bool] = None
    budgetTrain: Optional[bool] = None
    privateCabinPreferred: Optional[bool] = None

class TravelerInfo(BaseModel):
    travelerCount: Optional[int] = None
    hasKids: Optional[bool] = None
    youngestTravelerAge: Optional[int] = None

class ParsedPromptResult(BaseModel):
    route: ParsedPromptRoute = ParsedPromptRoute()
    schedule: ParsedPromptSchedule = ParsedPromptSchedule()
    lodgingPreferences: LodgingPreferences = LodgingPreferences()
    transportPreferences: TransportPreferences = TransportPreferences()
    travelerInfo: TravelerInfo = TravelerInfo()

class ParseTripPromptResponse(BaseModel):
    prompt: str
    parsedPromptResult: ParsedPromptResult