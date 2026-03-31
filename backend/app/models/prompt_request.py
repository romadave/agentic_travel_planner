from pydantic import BaseModel, Field

class ParseTripPromptRequest(BaseModel):
    prompt: str = Field(..., min_length=1)
    include_raw_llm_output: bool = False