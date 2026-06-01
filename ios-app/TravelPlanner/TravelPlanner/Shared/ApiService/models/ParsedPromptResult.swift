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
    var notes: [String]?
    var assumptions: [String]?
    var tripPreferences: String?
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.route = try container.decodeIfPresent(ParsedPromptRoute.self, forKey: .route) ?? ParsedPromptRoute()
            self.schedule = try container.decodeIfPresent(ParsedPromptSchedule.self, forKey: .schedule) ?? ParsedPromptSchedule()
            self.lodgingPreferences = try container.decodeIfPresent(LodgingPreferences.self, forKey: .lodgingPreferences) ?? LodgingPreferences()
            self.transportPreferences = try container.decodeIfPresent(TransportPreferences.self, forKey: .transportPreferences) ?? TransportPreferences()
            self.travelerInfo = try container.decodeIfPresent(TravelerInfo.self, forKey: .travelerInfo) ?? TravelerInfo()
            self.notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
            self.assumptions = try container.decodeIfPresent([String].self, forKey: .assumptions) ?? []
            self.tripPreferences = try container.decodeIfPresent(String.self, forKey: .tripPreferences)
        }
}
