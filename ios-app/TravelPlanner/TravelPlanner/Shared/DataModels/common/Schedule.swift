//
//  Schedule.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

import Foundation

struct Schedule: Codable, Equatable, Sendable {
    var departureDate: Date? = nil
    var returnDate: Date? = nil
    var numberOfDays: Int? = nil
}

struct ParsedPromptSchedule : Codable, Equatable, Sendable {
    var departureDateText: String?
    var returnDateText: String?
    var numberOfDays: Int?
    var dateText: String? //example: In June, next summer etc
}
