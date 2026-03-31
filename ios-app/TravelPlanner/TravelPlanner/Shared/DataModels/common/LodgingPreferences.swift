//
//  LodgingPreferences.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

struct LodgingPreferences: Codable, Equatable, Sendable {
    var hotel: Bool? = nil
    var airbnb: Bool? = nil
    var isFamilyFriendly: Bool? = nil
}
