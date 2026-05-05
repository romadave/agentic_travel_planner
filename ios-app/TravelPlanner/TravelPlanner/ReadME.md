# Trip Planner – Intelligent Travel Planning Pipeline

Excalidraw Link : https://excalidraw.com/#json=Jlz6wVJ5NnkrPLAq7jh5l,TLo0LQVwbnhNTSo2K2pXnw

An end-to-end system that turns an open-ended travel prompt into a structured trip plan with flights, stays, and a concise itinerary. The app guides the user from an initial idea to a shareable result (including CSV export), using an evaluation loop to fill in missing details and improve the plan.
## Overview
- Input: An open-ended prompt from the user (e.g., "Weekend in Paris in June, budget-conscious, prefer museums and walkable neighborhoods").
- Processing: We parse the prompt, build a draft request, evaluate gaps, enrich the draft, and finalize the trip by querying flight/hotel agents.
- Output: A response containing a high-level itinerary, scored flight options, and scored stay options. The user can edit their prompt or export results as CSV.

## Key Features
- Open-ended prompt ingestion and parsing
- Iterative trip request drafting and evaluation
- Finalization via backend endpoint that orchestrates external agents (flights, hotels, LLMs)
- Clear, scored options for flights and stays
- CSV export via backend
- UI to review, refine, and share results

## Architecture
- TripRequestDraft: Intermediate representation of the user’s trip request.
- TripEvaluator: Evaluates the draft to identify missing or ambiguous details; returns a TripEvaluation.
- Backend API: `/finalTripRequest` endpoint aggregates data from hotel and flight agents and trip intelligence (e.g., LLM/Gemini) and returns a consolidated result.

## End-to-End Workflow
1. User provides an open-ended prompt.
2. The prompt is sent to the server, which returns a `parsedPromptResult`.
3. Convert the parsed result into a `TripRequestDraft`.
4. Send the draft to the `TripEvaluator`.
5. Receive a `TripEvaluation` that identifies missing or unclear options.
6. Use the evaluation to enrich and complete the `TripRequestDraft`.
7. Submit the completed draft to the backend endpoint `POST /finalTripRequest`.
   - The backend orchestrates hotel and flight agents and trip intelligence (e.g., Gemini/LLM) to produce final options.
8. Receive the consolidated response containing:
   - High-level itinerary
   - Flight options with scores (plus tabular presentation data)
   - Stay options with scores (plus tabular presentation data)
9. Present results in the UI and allow the user to:
   - Edit the original prompt and re-run the flow
   - Export results as CSV via the backend
10. If exporting:
    - Backend builds the CSV and emails it to the user
    - The user can optionally iterate by adjusting the prompt and repeating from step 2

## API
- `POST /finalTripRequest`
  - Request: Completed `TripRequestDraft`
  - Response: Object containing itinerary, scored flight options, and scored stay options (plus any metadata needed for UI tables)

## Data Models (Conceptual)
- `parsedPromptResult`: Structured extraction of entities and preferences from the user’s freeform prompt.
- `TripRequestDraft`: Normalized request containing destinations, dates, budget, preferences, constraints, and any known traveler info.
- `TripEvaluation`: Feedback on missing fields, ambiguities, and recommended defaults or ranges.
- `FinalTripResponse`: High-level itinerary + ranked/ scored options for flights and stays, suitable for rendering and CSV export.

## Getting Started (Developer)
- Wire the UI to send the user prompt to the parsing service.
- Transform the `parsedPromptResult` into a `TripRequestDraft`.
- Call the `TripEvaluator` and merge its feedback.
- Submit the enriched draft to `POST /finalTripRequest`.
- Render the returned itinerary and options; provide controls for prompt editing and CSV export.

## Roadmap
- Add user profiles and saved preferences.
- Improve scoring models for flights and stays.
- Support multi-city itineraries and complex constraints.
- Add localization and currency handling.
- Enhance CSV export with richer formatting and attachments.

## Notes
- Terminology: CSV (not CVS), Evaluation (not Evaulation).
- The pipeline is designed to be iterative—users can refine prompts and re-run quickly.

