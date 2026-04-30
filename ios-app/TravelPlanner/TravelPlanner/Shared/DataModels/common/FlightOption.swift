//
//  FlightOptions.swift
//  TravelPlanner
//
//  Created by Roma Dave on 4/6/26.
//

import Foundation

struct FlightOption: Codable, Equatable, Sendable {
    let rank : Int?
    let airline: String
    let score: Int?
    let origin: String
    let destination: String
    let reason: String
    let price: Int?
    let duration: Float?
    let layovers: [String]
    let departureDate : Date
    let departureTime: String
    let returnDate: Date
    let returnTime: String
}
