//
//  ItineraryOption.swift
//  TravelPlanner
//

import Foundation

struct ItineraryOption: Codable, Equatable, Sendable {
    let optionNumber: Int
    let style: String           // "Base Camp", "Island Explorer", etc.
    let description: String
    let days: [TripDay]
    let hotelStops: [HotelStop]?
}
