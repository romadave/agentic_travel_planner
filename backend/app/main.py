from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from app.routers import flights, hotels, reports, parse_trip

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all origins (good for development)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class TripRequest(BaseModel):
    origin:str
    destination:str
    departure_date:str
    return_date:str
    toddler_age:int

# my root endpoint
@app.get("/")
def root():
    return {"message": "Travel Planner API is running"}

app.include_router(flights.router)
app.include_router(hotels.router)
app.include_router(reports.router)
app.include_router(parse_trip.router, tags=['parse-trip'])