//
//  Travelers.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

struct TravelerInfo: Codable, Equatable, Sendable {
    var travelerCount: Int? = nil
    var hasKids: Bool? = nil
    var youngestTravelerAge: Int? = nil
}
