//
//  DestinationInfo.swift
//  TravelPlanner
//

import Foundation

struct DestinationInfo: Codable, Equatable, Sendable {
    let country: String             // "Portugal"
    let tagline: String             // "Seven tiled hills, sea-breeze mornings..."
    let weather: String             // "26° · Sunny"
    let timezone: String            // "GMT+1"
}
