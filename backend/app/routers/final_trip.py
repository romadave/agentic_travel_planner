from fastapi import APIRouter, HTTPException
from app.models.final_trip_request import FinalTripRequest, FinalTripResponse
from app.agents.trip_planner_agent import plan_trip

router = APIRouter()

@router.post("/finalTripRequest", response_model=FinalTripResponse)
async def final_trip_request(request: FinalTripRequest) -> FinalTripResponse:
    try:
        return await plan_trip(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
