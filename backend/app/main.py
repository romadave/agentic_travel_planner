import logging
import time
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from app.routers import parse_trip, final_trip
from app.routers import share_itinerary

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.time()
    logger.info(f"--> {request.method} {request.url.path}")
    response = await call_next(request)
    duration = round((time.time() - start) * 1000)
    logger.info(f"<-- {request.method} {request.url.path} {response.status_code} ({duration}ms)")
    return response

@app.get("/")
def root():
    return {"message": "Travel Planner API is running"}

app.include_router(parse_trip.router, tags=["parse-trip"])
app.include_router(final_trip.router, tags=["final-trip"])
app.include_router(share_itinerary.router, tags=["share-itinerary"])