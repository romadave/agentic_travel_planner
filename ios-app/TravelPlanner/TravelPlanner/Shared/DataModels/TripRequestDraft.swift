//
//  TripRequestDraft.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/19/26.
//

//• Codable: You can serialize Trip​Request​Draft and its nested structs to/from JSON (good for persistence and networking).
//• Equatable: You can compare two drafts to detect changes (great for detecting unsaved edits).
//• Sendable: Safe to pass Trip​Request​Draft between tasks/actors in concurrent code.

import Foundation

// basically this is created based on the user prompt
// then we use this and send it to the evaluator
// evaluator figures out what we have / missing
// helps forms the next 2-4 screens
struct TripRequestDraft: Codable, Equatable, Sendable {
    var route = Route()
    var schedule = Schedule()
    var travelers = Travelers()
    var transportPreferences = TransportPreferences()
    var lodgingPreferences = LodgingPreferences()
}

extension TripRequestDraft {
    struct Route: Codable, Equatable, Sendable {
        var origin: String = ""
        var destination: String = ""
        var stops: [String] = []
    }

    struct Schedule: Codable, Equatable, Sendable {
        var departureDate: Date? = nil
        var returnDate: Date? = nil
    }

    struct Travelers: Codable, Equatable, Sendable {
        var travelerCount: Int? = nil
        var hasKids: Bool? = nil
        var youngestTravelerAge: Int? = nil
    }

    struct TransportPreferences: Codable, Equatable, Sendable {
        var flightSelected: Bool? = nil
        var roadSelected: Bool? = nil
        var trainSelected: Bool? = nil
        var redEye: Bool? = nil
        var budgetFlight: Bool? = nil
    }

    struct LodgingPreferences: Codable, Equatable, Sendable {
        var hotel: Bool? = nil
        var airbnb: Bool? = nil
        var both: Bool? = nil
    }
}
