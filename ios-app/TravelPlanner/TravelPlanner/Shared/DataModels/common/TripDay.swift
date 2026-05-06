//
//  TripDay.swift
//  TravelPlanner
//

import Foundation

struct TripDay: Codable, Equatable, Sendable {
    let dayNumber: Int
    let date: String            // "2026-09-05"
    let area: String            // "Lahaina"
    let morning: PartOfDay?
    let afternoon: PartOfDay?
    let evening: PartOfDay?
}
