AI Travel Planner : 
We will start with an LLM-assisted parser, a deterministic evaluator, and validation of parser output.

The user enters a free-text prompt. TripPromptParser sends that prompt and parsing instructions to the LLM, which returns a ParsedPromptResult containing the travel details it could infer from the user’s input.

We then validate and normalize that parsed result, and map it into our app’s TripRequestDraft, which is the editable source of truth throughout the intake flow.

Next, TripRequestEvaluator inspects the draft and returns a TripEvaluation, which tells us what required information is still missing and whether the draft is ready for submission.

That TripEvaluation is then passed to QuestionMapper. For V0, QuestionMapper will generate static questions. Later, we can swap that layer with an LLM-based phrasing system to make the questions feel more personalized and context-aware without changing the evaluator logic.

Screen 2 begins with the first required question. As the user answers questions across screens, we keep updating the same TripRequestDraft.

Once the draft is complete, we create a final TripRequest and send it to the planning LLM when the user taps Create Plan. The LLM returns itinerary options. After the user approves a plan, we can support actions like emailing the itinerary or generating an Excel sheet.


Why SwiftUI uses struct for views?
- to use data driven programming model
- more performative
- when you pass in new / assign a view it creates an independent copy
- reduces / prevents side effects from shared, mutable state making the UI behaviro much easier to reason about and debug

#Views
#ViewModel
#MainActor
#Observable
#Codable
#Equatable
#Sendable
#Published - basically if the value of a property changes -> it automatically sends updates to its subscribers. 
