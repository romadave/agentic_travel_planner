//
//  PartOfDay.swift
//  TravelPlanner
//

import Foundation

struct PartOfDay: Codable, Equatable, Sendable {
    let activity: String?
    let place: String?
    let foodSuggestion: String?
    let notes: String?
    let includeNap: Bool?
}
