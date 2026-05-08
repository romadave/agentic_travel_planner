//
//  HotelOption.swift
//  TravelPlanner
//

import Foundation

struct HotelOption: Codable, Equatable, Sendable {
    let name: String
    let type: String?               // "Apartment", "Boutique Hotel", etc.
    let area: String
    let rating: Float
    let pricePerNight: Float
    let totalPrice: Float
    let amenities: [String]
    let score: Int
    let reason: String
    let bookingUrl: String?
}
