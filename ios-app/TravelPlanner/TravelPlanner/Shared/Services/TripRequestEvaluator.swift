//
//  TripRequestEvaluator.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/22/26.
//

import Foundation

// Priority Order:
// destination
// origin
// travelDates
// adultCount
// hasKids
// youngestTravelerAge
// transportMode
struct TripRequestEvaluator {
    func evaluate(draft: TripRequestDraft) -> TripEvaluation {
        var missing: [TripRequirement] = []

        // Validate required fields in priority order
        let trimmedDestination = draft.route.destination.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDestination.isEmpty {
            missing.append(.destination)
        }

        let trimmedOrigin = draft.route.origin.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedOrigin.isEmpty {
            missing.append(.origin)
        }

        if draft.schedule.departureDate == nil || draft.schedule.returnDate == nil {
            missing.append(.travelDates)
        }

        let adultCount = draft.travelerInfo.adultCount ?? 0
        let hasKidsValue = draft.travelerInfo.hasKids
        let kidAges = draft.travelerInfo.kidsAges
        // Combine adultCount, hasKids, and kidsAges into a single step
        if adultCount <= 0 || hasKidsValue == nil {
            missing.append(.adultCount)
        } else if hasKidsValue == true && (kidAges ?? []).isEmpty {
            missing.append(.adultCount)
        }

        let flightSelected = draft.transportPreferences.flightSelected ?? false
        let roadSelected = draft.transportPreferences.roadSelected ?? false
        let trainSelected = draft.transportPreferences.trainSelected ?? false
        let hasAnyTransportMode = flightSelected || roadSelected || trainSelected

        if !hasAnyTransportMode {
            missing.append(.transportMode)
        }
        
        let hotel = draft.lodgingPreferences.hotel ?? false
        let airbnb = draft.lodgingPreferences.airbnb ?? false
        let bothMissing = !hotel && !airbnb
        
        if bothMissing {
            missing.append(.lodgingPreferences)
        }
        
        let nextRequirement = missing.first
        let isReady = missing.isEmpty

        let summary = buildSummary(from: draft)

        print("TRIP EVALUATION DONE")
        return TripEvaluation(
            missingRequirements: missing,
            nextRequirement: nextRequirement,
            isReadyForSubmission: isReady,
            tripSummary: summary
        )
    }
    
    private func buildSummary(from draft: TripRequestDraft) -> String {
            let origin = draft.route.origin.trimmingCharacters(in: .whitespacesAndNewlines)
            let destination = draft.route.destination.trimmingCharacters(in: .whitespacesAndNewlines)

            if !origin.isEmpty && !destination.isEmpty {
                return "Trip from \(origin) to \(destination)"
            } else if !destination.isEmpty {
                return "Trip to \(destination)"
            } else {
                return "New trip"
            }
        }
}
