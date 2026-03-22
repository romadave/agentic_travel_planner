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
// travelerCount
// hasKids
// youngestTravelerAge
// transportMode
enum TripRequirement: String, CaseIterable {
    case destination
    case origin
    case travelDates
    case travelerCount
    case hasKids
    case youngestTravelerAge
    case transportMode
}

struct TripEvaluation {
    let missingRequirements : [TripRequirement]
    let nextRequirement : TripRequirement?
    let isReadyForSubmission : Bool
    let tripSummary : String
}

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

        if draft.travelers.travelerCount == nil || (draft.travelers.travelerCount ?? 0) <= 0 {
            missing.append(.travelerCount)
        }

        if draft.travelers.hasKids == nil {
            missing.append(.hasKids)
        }

        if (draft.travelers.hasKids ?? false) && draft.travelers.youngestTravelerAge == nil {
            missing.append(.youngestTravelerAge)
        }

        let hasAnyTransportMode =
        draft.transportPreferences.flightSelected ||
                    draft.transportPreferences.roadSelected ||
                    draft.transportPreferences.trainSelected
        
        if !hasAnyTransportMode {
                    missing.append(.transportMode)
                }
        let nextRequirement = missing.first
        let isReady = missing.isEmpty

        let summary = buildSummary(from: draft)

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
