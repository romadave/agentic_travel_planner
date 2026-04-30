//
//  TripEvaluation.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

import Foundation

enum TripRequirement: String, Codable, CaseIterable {
    case destination
    case origin
    case travelDates
    case travelerCount
    case hasKids
    case youngestTravelerAge
    case transportMode
    case lodgingPreferences
}

struct TripEvaluation : Codable, Equatable {
    let missingRequirements : [TripRequirement]
    let nextRequirement : TripRequirement?
    let isReadyForSubmission : Bool
    let tripSummary : String
}
