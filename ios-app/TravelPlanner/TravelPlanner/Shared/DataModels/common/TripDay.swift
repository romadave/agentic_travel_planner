//
//  TripDay.swift
//  TravelPlanner
//
//  Created by Roma Dave on 4/4/26.
//

import Foundation

struct TripDay : Codable, Equatable {
    let morning: PartOfDay
    let afternoon : PartOfDay
    let evening: PartOfDay
}

struct PartOfDay : Codable, Equatable {
    let foodOptions: [String]?
    let placesToVisitDistance: [String: Float]
    let includeNap: Bool
}
