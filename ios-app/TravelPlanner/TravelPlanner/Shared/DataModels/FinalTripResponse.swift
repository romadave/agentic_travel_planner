//
//  TripFinalResult.swift
//  TravelPlanner
//
//  Created by Roma Dave on 4/4/26.
//

import Foundation

struct FinalTripResponse : Codable, Equatable {
    let itinerary : TripItinerary
    let flightOptions: [FlightOption]
    let hotelOptions: [HotelOption]
    let cannotGenerateItinerary: Bool
}
