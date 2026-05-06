//
//  HotelStop.swift
//  TravelPlanner
//

import Foundation

struct HotelStop: Codable, Equatable, Sendable {
    let area: String
    let nights: Int
    let hotels: [HotelOption]
}
