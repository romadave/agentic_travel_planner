//
//  HotelOptions.swift
//  TravelPlanner
//
//  Created by Roma Dave on 4/6/26.
//

struct HotelOption : Codable, Sendable, Equatable {
    let price: Float
    let numberOfDays : Int
    let distanceFromAirport: Float
    let numberOfRooms : Int
}
