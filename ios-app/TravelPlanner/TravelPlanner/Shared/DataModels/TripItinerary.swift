//
//  TripItinerary.swift
//  TravelPlanner
//
//  Created by Roma Dave on 4/4/26.
//


struct TripItinerary : Codable, Equatable {
    let title: String
    let summary : String
    let days : [TripDay]
}
