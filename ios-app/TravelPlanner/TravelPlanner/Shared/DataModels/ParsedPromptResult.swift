//
//  ParsedPromptResult.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

struct ParsedPromptResult : Codable, Equatable, Sendable {
    var route: ParsedPromptRoute = ParsedPromptRoute()
    var schedule: ParsedPromptSchedule = ParsedPromptSchedule()
    var lodgingPreferences: LodgingPreferences = LodgingPreferences()
    var transportPreferences: TransportPreferences = TransportPreferences()
    var travelerInfo: TravelerInfo = TravelerInfo()
    var notes: [String] = []
    var assumptions: [String] = []
}
