from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import parse_trip, final_trip

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "Travel Planner API is running"}

app.include_router(parse_trip.router, tags=["parse-trip"])
app.include_router(final_trip.router, tags=["final-trip"])