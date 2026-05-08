//
//  Screen2State.swift
//  TravelPlanner
//

import Foundation
enum Screen2State: Equatable {
    case idle
    case loading
    case loaded(TripEvaluation)
    case failed(String)
}
