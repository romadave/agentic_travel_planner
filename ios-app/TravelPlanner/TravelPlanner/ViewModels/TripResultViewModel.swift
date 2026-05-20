//
//  TripResultViewModel.swift
//  TravelPlanner
//
//  Created by Roma Dave on 5/20/26.
//

import Foundation
import Combine

@MainActor
final class TripResultViewModel : ObservableObject {
    @Published var destinationInfo: DestinationInfo?
    @Published var itineraryOptions: [ItineraryOption] = []
    @Published var flights: [FlightOption] = []
    @Published var isLoadingFlights: Bool = true
    @Published var isLoadingHotels: Bool = true
}
