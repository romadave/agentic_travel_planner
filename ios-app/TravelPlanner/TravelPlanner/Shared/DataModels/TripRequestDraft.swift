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
    var route: Route = Route()
    var schedule: Schedule = Schedule()
    var travelerInfo: TravelerInfo = TravelerInfo()
    var transportPreferences: TransportPreferences = TransportPreferences()
    var lodgingPreferences: LodgingPreferences = LodgingPreferences()
    var tripPreferences: String?
}








