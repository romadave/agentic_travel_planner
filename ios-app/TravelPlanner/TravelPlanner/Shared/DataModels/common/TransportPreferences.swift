//
//  TransportPreferences.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

struct TransportPreferences: Codable, Equatable, Sendable {
    var flightSelected: Bool? = nil
    var roadSelected: Bool? = nil
    var trainSelected: Bool? = nil
    var redEye: Bool? = nil
    var budgetFlight: Bool? = nil
    var budgetTrain: Bool? = nil
    var layoversAllowed: Bool? = nil
    var privateCabinPreferred: Bool? = nil
}
