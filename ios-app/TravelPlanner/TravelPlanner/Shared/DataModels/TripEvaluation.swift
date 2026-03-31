//
//  TripEvaluation.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

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
