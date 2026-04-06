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
    @Published var evaluation: TripEvaluation?
    
    private let apiService = TripAPIService()
    private let draftBuilder = TripDraftBuilder()
    private let evaluator = TripRequestEvaluator()
    
    init(
            draft: TripRequestDraft = TripRequestDraft(),
        ) {
            self.tripDraft = draft
        }
    
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
            print("DRAFT : ", tripDraft)
            
            // evaluate the result and find missing questions
            let evaluateResult = evaluator.evaluate(draft: draft)
            self.evaluation = evaluateResult
            print("RESULT" , evaluateResult.self)
            screen2State = .loaded(evaluateResult)
            
        } catch {
            screen2State = .failed(error.localizedDescription)
        }
    }
    
    func submitFinalDraft() async {
        do {
            if(tripDraft == nil) {
                print("no draft found")
                return;
            }
            
            print("fetching itinaray")
            
            // TODO : figure out how to send a non-null value
            let tripResponse = try await fetchItinaray(from: tripDraft)
            
            print("itinaray", tripResponse.itinerary.summary)
        } catch {
            
        }
    }
    
    private func fetchItinaray(from draft: TripRequestDraft) async throws -> FinalTripResponse {
        let response = try await apiService.submitFinalDraft(draft)
        
        print("response", response.itinerary.summary)
        
        return response.self
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

extension TripDraftViewModel {
    // MARK: - Route updates
    func updateDestination(_ value: String) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.route.destination = value
    }

    func updateOrigin(_ value: String) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.route.origin = value
    }

    // MARK: - Schedule (Dates)
    func updateTravelDates(departure: Date?, returnDate: Date?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.schedule.departureDate = departure
        tripDraft?.schedule.returnDate = returnDate
    }

    func updateDepartureDate(_ date: Date?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.schedule.departureDate = date
    }

    func updateReturnDate(_ date: Date?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.schedule.returnDate = date
    }

    // MARK: - Traveler Info
    func updateTravelerCount(_ count: Int?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        if tripDraft?.travelerInfo == nil {
            tripDraft?.travelerInfo = TravelerInfo()
        }
        tripDraft?.travelerInfo.travelerCount = count
    }

    func updateHasKids(_ hasKids: Bool?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.travelerInfo.hasKids = hasKids
    }

    func updateYoungestTravelerAge(_ age: Int?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.travelerInfo.youngestTravelerAge = age
    }

    // MARK: - Transport Preferences
    /// Accepts a human-friendly mode and maps it into boolean preferences.
    /// Supported values: "flight" (air/plane), "road" (car/drive), "train" (rail)
    func updateTransportMode(_ mode: String) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        let lower = mode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var flight = false
        var road = false
        var train = false
        switch lower {
        case "flight", "plane", "air", "airplane":
            flight = true
        case "road", "car", "drive", "driving":
            road = true
        case "train", "rail":
            train = true
        default:
            break
        }
        tripDraft?.transportPreferences.flightSelected = flight
        tripDraft?.transportPreferences.roadSelected = road
        tripDraft?.transportPreferences.trainSelected = train
    }

    /// If your UI collects transport booleans directly, use this instead.
    func setTransportModes(flight: Bool?, road: Bool?, train: Bool?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.transportPreferences.flightSelected = flight
        tripDraft?.transportPreferences.roadSelected = road
        tripDraft?.transportPreferences.trainSelected = train
    }

    // MARK: - Lodging Preferences
    
    func updateLodging(_ mode: String) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        let lower = mode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var airbnb = false
        var hotel = false
        var isChildFriendly = false
        switch lower {
        case "airbnb", "vrbo", "vacationrentals":
            airbnb = true
        case "hotel", "suite":
            hotel = true
        default:
            break
        }
        tripDraft?.lodgingPreferences.airbnb = airbnb
        tripDraft?.lodgingPreferences.hotel = hotel
        tripDraft?.lodgingPreferences.isFamilyFriendly = tripDraft?.travelerInfo.hasKids
    }

    
    func updateLodgingHotel(_ value: Bool?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.lodgingPreferences.hotel = value
    }
    func updateLodgingAirbnb(_ value: Bool?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.lodgingPreferences.airbnb = value
    }

    func updateLodgingIsFamilyFriendly(_ value: Bool?) {
        if tripDraft == nil { tripDraft = TripRequestDraft() }
        tripDraft?.lodgingPreferences.isFamilyFriendly = value
    }
    
    func reevaluateDraft() {
        let draft = tripDraft ?? TripRequestDraft()
        let result = evaluator.evaluate(draft: draft)
        self.evaluation = result
        self.screen2State = .loaded(result)
    }
}

