//
//  TripDraftViewModel.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

import Foundation
import Combine
@MainActor
final class TripDraftViewModel : ObservableObject {
    @Published var userPrompt: String = ""
    @Published var isLoading: Bool = false
    @Published var tripDraft : TripRequestDraft?
    @Published var evaluation: TripEvaluation?
    @Published var errorMessage : String?
    
    private let apiService = TripAPIService()
    private let draftBuilder = TripDraftBuilder()
    private let evaluator = TripRequestEvaluator()
    
    func submitPrompt() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // send the user prompt to LLM
            let getResponse = try await apiService.parseTripPrompt(userPrompt)
            
            // get Parsed Response
            let parsed = getResponse.parsedPromptResult
            
            // build the draft from parsed response
            let draft = draftBuilder.build(from: parsed)
            self.tripDraft = draft
            
            // evaluate the result and find missing questions
            let evaluateResult = evaluator.evaluate(draft: draft)
            self.evaluation = evaluateResult
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

