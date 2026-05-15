//
//  FinalTripResponse.swift
//  TravelPlanner
//

import Foundation

struct FinalTripResponse: Codable, Equatable, Sendable {
    let destinationInfo: DestinationInfo
    let flights: [FlightOption]
    let itineraryOptions: [ItineraryOption]
    let cannotGenerate: Bool
    let reason: String?
}
