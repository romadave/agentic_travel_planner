import json
from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from app.models.final_trip_request import FinalTripRequest
from app.agents.trip_planner_agent import plan_trip

router = APIRouter()

async def event_stream(request: FinalTripRequest):
    try:
        async for chunk in plan_trip(request):
            yield f"data: {chunk}\n\n"
    except Exception as e:
        yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

@router.post("/finalTripRequest")
async def final_trip_request(request: FinalTripRequest):
    return StreamingResponse(
        event_stream(request),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
