# PARSER_SYSTEM_PROMPT = 
import json
from typing import Any, Dict
from app.client.gemini_client import gemini_client

SYSTEM_PROMPT = """
You are a travel prompt parser.

Your job is to extract structured travel information from a user's free-text prompt.

Return only valid JSON matching the schema exactly.

Rules:
1. Extract only information that is explicitly stated or strongly implied.
2. Do not invent or guess missing values.
3. Use null for unknown scalar values.
4. Use an empty array only when a list is clearly present but empty is appropriate; otherwise null is acceptable if unknown.
5. If the user mentions vague date information like "in June" or "next summer", put that in schedule.dateText.
6. If exact departure or return dates are not given, keep departureDateText and returnDateText as null.
7. If the user mentions duration like "for 5 days", populate numberOfDays if clear.
8. If the user mentions children or a toddler, set travelers.hasKids = true.
9. If the age of the child is not explicitly stated, keep youngestTravelerAge as null.
10. Do not include any keys outside the schema.
11. Output JSON only. No markdown, no explanation.

JSON schema:
{{
  "route": {
    "originText": "string | null",
    "destinationText": "string | null",
    "stops": ["string"] | null
  },
  "schedule": {
    "departureDateText": "string | null",
    "returnDateText": "string | null",
    "numberOfDays": "integer | null",
    "dateText": "string | null"
  },
  "lodgingPreferences": {
    "hotel": "boolean | null",
    "airbnb": "boolean | null",
    "isFamilyFriendly": "boolean | null"
  },
  "transportPreferences": {
    "flightSelected": "boolean | null",
    "roadSelected": "boolean | null",
    "trainSelected": "boolean | null",
    "redEye": "boolean | null",
    "budgetFlight": "boolean | null",
    "layoversAllowed": "boolean | null",
    "budgetTrain": "boolean | null",
    "privateCabinPreferred": "boolean | null"
  },
  "travelers": {
    "travelerCount": "integer | null",
    "hasKids": "boolean | null",
    "youngestTravelerAge": "integer | null"
  }
}}
"""

def get_user_prompt(user_prompt):
    return f"User travel prompt: {user_prompt}"

def extract_json_from_text(raw_text: str) -> Dict[str, Any]:
    raw_text = raw_text.strip()

    if raw_text.startswith("```"):
        raw_text = raw_text.strip("`")
        if raw_text.startswith("json"):
            raw_text = raw_text[4:].strip()

    start = raw_text.find("{")
    end = raw_text.rfind("}")

    if start == -1 or end == -1:
        raise ValueError("No JSON object found in Gemini response.")

    json_str = raw_text[start:end + 1]
    return json.loads(json_str)

def parse_trip_prompt(user_prompt:str) -> Dict[str, Any]:
    prompt = get_user_prompt(user_prompt=user_prompt)
    response = gemini_client.generate_text(model='gemini-2.5-flash', user_prompt=prompt, system_prompt=SYSTEM_PROMPT)
    return extract_json_from_text(response)


