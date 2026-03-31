//
//  DateCompletenessEvaluator.swift
//  TravelPlanner
//
//  Created by Assistant on 3/23/26.
//

import Foundation

/// Represents how complete the user's date information is for a trip.
enum DateCompleteness: Equatable {
    /// No valid date info could be determined.
    case none
    /// Only a single departure date is present.
    case oneWay(departure: Date)
    /// Round trip with both departure and return dates. Return must be after departure.
    case roundTrip(departure: Date, `return`: Date)
    /// Dates are present but ambiguous (e.g., same day for return, or return before departure).
    case ambiguous(reason: String)
}

/// Evaluates whether the provided dates are sufficient for planning.
struct DateCompletenessEvaluator {
    /// Evaluates date completeness using optional departure/return values.
    /// - Parameters:
    ///   - departure: An optional departure date.
    ///   - returnDate: An optional return date.
    /// - Returns: A `DateCompleteness` value describing sufficiency.
    func evaluate(departure: Date?, returnDate: Date?) -> DateCompleteness {
        let cal = Calendar.current

        switch (departure, returnDate) {
        case (nil, nil):
            return .none

        case (let d?, nil):
            // Normalize to the start of the day for date-only semantics
            let startD = cal.startOfDay(for: d)
            return .oneWay(departure: startD)

        case (let d?, let r?):
            let startD = cal.startOfDay(for: d)
            let startR = cal.startOfDay(for: r)

            if startR < startD {
                return .ambiguous(reason: "Return date is before departure date (by day)")
            }

            // Same-day return is allowed when we don't care about time; treat as round trip
            return .roundTrip(departure: startD, return: startR)

        case (nil, let r?):
            // Normalize but still ambiguous because we lack a departure day
            _ = cal.startOfDay(for: r)
            return .ambiguous(reason: "Return date provided without a departure date")
        }
    }
}
