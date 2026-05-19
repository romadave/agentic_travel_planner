//
//  TripStreamEvent.swift
//  TravelPlanner
//
//  Created by Roma Dave on 5/15/26.
//

import Foundation

// MARK: - Stream Event Enum
// Each case represents one type of SSE chunk from the backend.
// The associated value carries the already-decoded data.

enum TripStreamEvent {
    case destinationInfo(DestinationInfo)
    case itineraries([ItineraryOption])
    case flights([FlightOption])
    case hotels([ItineraryOption])   // itineraries updated with hotels attached
    case done
    case error(String)

    // MARK: - Decode from raw JSON Data

    /// Takes the raw JSON bytes from one SSE line and returns the typed event.
    /// Steps:
    ///   1. Peek at the "type" field using TypeWrapper
    ///   2. Switch on the type string
    ///   3. Decode the full payload for that event type
    static func decode(from data: Data) throws -> TripStreamEvent {
        let typeWrapper = try JSONDecoder().decode(TypeWrapper.self, from: data)

        switch typeWrapper.type {
        case "destinationInfo":
            // Backend sends: {"type": "destinationInfo", "country": "...", "tagline": "...", ...}
            // DestinationInfoPayload wraps the fields we need
            let payload = try JSONDecoder().decode(DestinationInfoPayload.self, from: data)
            return .destinationInfo(payload.toDestinationInfo())

        case "itineraries":
            // Backend sends: {"type": "itineraries", "itineraryOptions": [...]}
            let payload = try JSONDecoder().decode(ItinerariesPayload.self, from: data)
            return .itineraries(payload.itineraryOptions)

        case "flights":
            // Backend sends: {"type": "flights", "flights": [...]}
            let payload = try JSONDecoder().decode(FlightsPayload.self, from: data)
            return .flights(payload.flights)

        case "hotels":
            // Backend sends: {"type": "hotels", "itineraryOptions": [...]}
            // These are the same itineraries but now with hotel data attached
            let payload = try JSONDecoder().decode(HotelsPayload.self, from: data)
            return .hotels(payload.itineraryOptions)

        case "done":
            return .done

        case "error":
            let payload = try JSONDecoder().decode(ErrorPayload.self, from: data)
            return .error(payload.message)

        default:
            return .error("Unknown stream event type: \(typeWrapper.type)")
        }
    }
}

// MARK: - Helper Structs for Decoding

/// Peeks at just the "type" field without decoding the rest
private struct TypeWrapper: Decodable {
    let type: String
}

/// Payload for destinationInfo event
/// Backend sends fields flat: {"type": "destinationInfo", "country": "...", "tagline": "...", ...}
private struct DestinationInfoPayload: Decodable {
    let country: String
    let tagline: String
    let weather: String
    let timezone: String

    func toDestinationInfo() -> DestinationInfo {
        DestinationInfo(country: country, tagline: tagline, weather: weather, timezone: timezone)
    }
}

/// Payload for itineraries event
private struct ItinerariesPayload: Decodable {
    let itineraryOptions: [ItineraryOption]
}

/// Payload for flights event
private struct FlightsPayload: Decodable {
    let flights: [FlightOption]
}

/// Payload for hotels event (itineraries updated with hotels)
private struct HotelsPayload: Decodable {
    let itineraryOptions: [ItineraryOption]
}

/// Payload for error event
private struct ErrorPayload: Decodable {
    let message: String
}
