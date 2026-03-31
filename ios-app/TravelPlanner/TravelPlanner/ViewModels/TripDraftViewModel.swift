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
    @Published var tripDraft : TripRequestDraft?
    @Published var screen2State: Screen2State = .idle
    
    private let apiService = TripAPIService()
    private let draftBuilder = TripDraftBuilder()
    private let evaluator = TripRequestEvaluator()
    
    func submitPrompt() async {
        screen2State = .loading
        print("Loading now")
        do {
            print("sending" ,userPrompt)
            // send the user prompt to LLM
            let parsed = try await fetchParsedPrompt(from: userPrompt)
            
            // build the draft from parsed response
            let draft = draftBuilder.build(from: parsed)
            self.tripDraft = draft
            print("DRAFT : ", tripDraft.self)
            
            // evaluate the result and find missing questions
            let evaluateResult = evaluator.evaluate(draft: draft)
            print("RESULT" , evaluateResult.self)
            screen2State = .loaded(evaluateResult)
            
        } catch {
            screen2State = .failed(error.localizedDescription)
        }
    }
    
    private func fetchParsedPrompt(from prompt: String) async throws -> ParsedPromptResult {
        // Replace with your real API call
        let response = try await apiService.parseTripPrompt(prompt)
        
        print("response", response.parsedPromptResult.self)
        return response.parsedPromptResult
    }
    
    func validatePrompt() -> Bool {
        !userPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

