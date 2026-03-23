//
//  Route.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//


struct Route: Codable, Equatable, Sendable {
    var origin: String = ""
    var destination: String = ""
    var stops: [String] = []
}

struct ParsedPromptRoute : Codable, Equatable, Sendable {
    var originText: String?
    var destinationText: String?
    var stops: [String]?
}
