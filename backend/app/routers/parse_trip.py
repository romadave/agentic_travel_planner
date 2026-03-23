from fastapi import APIRouter, HTTPException
from app.models.prompt_request import ParseTripPromptRequest
from app.models.prompt_response import ParsedPromptResult, ParseTripPromptResponse
from app.agents.trip_prompt_parser_agent import parse_trip_prompt

router = APIRouter(tags=["parse-trip"])

@router.post("/parse-trip-prompt", response_model=ParseTripPromptResponse)
async def parse_trip_prompt(request: ParseTripPromptRequest) -> ParseTripPromptResponse:
    prompt = request.prompt.strip()

    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty.")

    try:
        parsed_result_dict = await parse_trip_prompt(prompt)
        parsed_result = ParsedPromptResult.model_validate(parsed_result_dict)

        return ParseTripPromptResponse(
            prompt=prompt,
            parsedPromptResult=parsed_result,
        )

    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to parse trip prompt: {str(exc)}"
        )