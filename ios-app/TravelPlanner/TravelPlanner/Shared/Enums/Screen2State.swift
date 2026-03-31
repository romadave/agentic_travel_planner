//
//  Screen2State.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/31/26.
//

import Foundation
enum Screen2State: Equatable {
    case idle
    case loading
    case loaded(TripEvaluation)
    case failed(String)
}
