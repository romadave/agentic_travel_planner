//
//  TripDraftBuilder.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/23/26.
//

import Foundation

struct TripDraftBuilder {
    private let dateParser = DateParser()

    func build(from parsed: ParsedPromptResult) -> TripRequestDraft {
        print("parsed result",parsed)
        // Parse dates from strings if present
        let departureDate: Date? = {
            if let text = parsed.schedule.departureDateText, !text.isEmpty {
                return dateParser.parse(text)
            }
            return nil
        }()

        let returnDate: Date? = {
            if let text = parsed.schedule.returnDateText, !text.isEmpty {
                return dateParser.parse(text)
            }
            return nil
        }()

        let route = Route(
            origin: parsed.route.originText ?? "",
            destination: parsed.route.destinationText ?? "",
            stops: parsed.route.stops ?? []
        )

        let schedule = Schedule(
            departureDate: departureDate,
            returnDate: returnDate
        )

        let travelerInfo = TravelerInfo(
            travelerCount: parsed.travelerInfo.travelerCount,
            hasKids: parsed.travelerInfo.hasKids,
            youngestTravelerAge: parsed.travelerInfo.youngestTravelerAge
        )

        // Respect expected parameter order/labels (hotel before airbnb if the type requires it)
        let lodgingPreferences = LodgingPreferences(
            hotel: parsed.lodgingPreferences.hotel,
            airbnb: parsed.lodgingPreferences.airbnb,
            isFamilyFriendly: parsed.lodgingPreferences.isFamilyFriendly
        )

        // Transport preferences require flightSelected, roadSelected, trainSelected
        let transportPreferences = TransportPreferences(
            flightSelected: parsed.transportPreferences.flightSelected,
            roadSelected: parsed.transportPreferences.roadSelected,
            trainSelected: parsed.transportPreferences.trainSelected,
            redEye: parsed.transportPreferences.redEye,
            budgetFlight: parsed.transportPreferences.budgetFlight,
            budgetTrain: parsed.transportPreferences.budgetTrain,
            layoversAllowed: parsed.transportPreferences.layoversAllowed,
            privateCabinPreferred: parsed.transportPreferences.privateCabinPreferred,
        )

        print("DRAFT : ", route.self, schedule.self, travelerInfo.self)
        return TripRequestDraft(
            route: route,
            schedule: schedule,
            travelerInfo: travelerInfo,
            transportPreferences: transportPreferences,
            lodgingPreferences: lodgingPreferences,
        )
    }
}
