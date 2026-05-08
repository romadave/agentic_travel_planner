//
//  FlightOption.swift
//  TravelPlanner
//

import Foundation

struct FlightOption: Codable, Equatable, Sendable {
    let rank: Int
    let airline: String
    let flightNumber: String?       // "TP 206" or "UA 900 · LH 1166"
    let score: Int
    let origin: String
    let destination: String
    let reason: String
    let price: Int
    let duration: Float             // hours
    let layovers: [String]
    let departureDate: String
    let departureTime: String
    let returnDate: String
    let returnTime: String
    let bookingUrl: String?
    let familyAmenities: [String]?  // ["Bassinet available", "priority boarding"]
}
