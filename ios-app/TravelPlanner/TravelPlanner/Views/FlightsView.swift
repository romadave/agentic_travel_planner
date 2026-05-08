//
//  FlightsView.swift
//  TravelPlanner
//

import SwiftUI

struct FlightsView: View {
    let flights: [FlightOption]
    let origin: String
    let destination: String
    let departureDate: String
    let hasKids: Bool

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias S = DesignTokens.Spacing

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: FlightFilter = .best
    @State private var selectedFlight: FlightOption? = nil
    @State private var expandedFlight: Int? = nil // track by rank

    private enum FlightFilter: String, CaseIterable {
        case best = "Best"
        case cheapest = "Cheapest"
        case fastest = "Fastest"
        case family = "Family"
    }

    private var sortedFlights: [FlightOption] {
        switch selectedFilter {
        case .best:
            return flights.sorted { $0.rank < $1.rank }
        case .cheapest:
            return flights.sorted { $0.price < $1.price }
        case .fastest:
            return flights.sorted { $0.duration < $1.duration }
        case .family:
            return flights
                .filter { !($0.familyAmenities ?? []).isEmpty }
                .sorted { $0.rank < $1.rank }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            C.screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: S.lg) {
                    routeHeader
                    filterChips
                    flightCards
                }
                .padding(.horizontal, S.md)
                .padding(.bottom, 100)
            }

            if selectedFlight != nil {
                selectButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("FLIGHTS")
                    .font(T.labelUpper)
                    .tracking(1.2)
                    .foregroundColor(C.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(C.textPrimary)
                }
            }
        }
    }

    // MARK: - Route Header

    private var routeHeader: some View {
        VStack(spacing: 12) {
            Text("OUTBOUND · \(formattedHeaderDate)")
                .font(T.labelUpper)
                .tracking(1.0)
                .foregroundColor(C.textSecondary)

            HStack {
                VStack(spacing: 4) {
                    Text(origin)
                        .font(.system(size: 32, weight: .regular, design: .serif))
                        .foregroundColor(C.textPrimary)
                    Text(originCityName)
                        .font(T.captionMd)
                        .foregroundColor(C.textSecondary)
                }

                Spacer()

                Image(systemName: "airplane")
                    .font(.system(size: 16))
                    .foregroundColor(C.textSecondary)

                Spacer()

                VStack(spacing: 4) {
                    Text(destination)
                        .font(.system(size: 32, weight: .regular, design: .serif))
                        .foregroundColor(C.textPrimary)
                    Text(destinationCityName)
                        .font(T.captionMd)
                        .foregroundColor(C.textSecondary)
                }
            }
        }
        .padding(.top, S.sm)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(FlightFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    HStack(spacing: 4) {
                        if filter == .family {
                            Image(systemName: "figure.and.child.holdinghands")
                                .font(.system(size: 11))
                        }
                        Text(filter.rawValue)
                            .font(T.bodyMedium)
                    }
                    .foregroundColor(selectedFilter == filter ? C.chipSelectedFg : C.chipUnselectedFg)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selectedFilter == filter ? C.chipSelectedBg : C.chipUnselectedBg)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.pill))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radii.pill)
                            .stroke(selectedFilter == filter ? Color.clear : C.chipBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Flight Cards

    private var flightCards: some View {
        VStack(spacing: S.sm) {
            ForEach(Array(sortedFlights.enumerated()), id: \.element.rank) { index, flight in
                flightCard(flight, isTopRanked: index == 0 && selectedFilter == .best)
            }
        }
    }

    private func flightCard(_ flight: FlightOption, isTopRanked: Bool) -> some View {
        let isSelected = selectedFlight == flight
        let isExpanded = expandedFlight == flight.rank

        return VStack(alignment: .leading, spacing: 14) {
            // Airline + flight number + badge
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.airline)
                        .font(T.bodyMedium)
                        .foregroundColor(C.textPrimary)
                    if let flightNum = flight.flightNumber {
                        Text(flightNum)
                            .font(T.captionMd)
                            .foregroundColor(C.textSecondary)
                    }
                }
                Spacer()
                if isTopRanked {
                    Text("BEST MATCH")
                        .font(T.captionSm)
                        .tracking(0.6)
                        .foregroundColor(C.tipIcon)
                }
            }

            // Times row
            HStack(alignment: .top) {
                // Departure
                VStack(alignment: .leading, spacing: 2) {
                    Text(flight.departureTime)
                        .font(.system(size: 24, weight: .regular, design: .default).monospacedDigit())
                        .foregroundColor(C.textPrimary)
                    Text(flight.origin)
                        .font(T.captionMd)
                        .foregroundColor(C.textSecondary)
                }

                Spacer()

                // Duration + stops
                VStack(spacing: 4) {
                    Text(durationText(flight.duration))
                        .font(T.captionMd)
                        .foregroundColor(C.textSecondary)

                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(C.patternLine)
                            .frame(height: 1)
                        Circle()
                            .fill(C.textSecondary)
                            .frame(width: 5, height: 5)
                        Rectangle()
                            .fill(C.patternLine)
                            .frame(height: 1)
                    }

                    if !flight.layovers.isEmpty {
                        Text("\(flight.layovers.count) stop · \(flight.layovers.joined(separator: ", "))")
                            .font(T.captionSm)
                            .foregroundColor(C.textSecondary)
                    } else {
                        Text("direct")
                            .font(T.captionSm)
                            .foregroundColor(C.textSecondary)
                    }
                }

                Spacer()

                // Arrival
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(flight.returnTime)
                            .font(.system(size: 24, weight: .regular, design: .default).monospacedDigit())
                            .foregroundColor(C.textPrimary)
                        if isNextDay(departure: flight.departureTime, arrival: flight.returnTime) {
                            Text("+1")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(C.textSecondary)
                        }
                    }
                    Text(flight.destination)
                        .font(T.captionMd)
                        .foregroundColor(C.textSecondary)
                }
            }

            // Family amenities + price
            HStack(alignment: .bottom) {
                if let amenities = flight.familyAmenities, !amenities.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.and.child.holdinghands")
                            .font(.system(size: 11))
                            .foregroundColor(C.tipIcon)
                        Text(amenities.joined(separator: " · "))
                            .font(T.captionMd)
                            .foregroundColor(C.tipIcon)
                    }
                }

                Spacer()

                Text("$\(flight.price)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(C.textPrimary)
            }

            // Expandable details
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    // Layover details
                    if !flight.layovers.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LAYOVERS")
                                .font(T.captionSm)
                                .tracking(0.8)
                                .foregroundColor(C.textSecondary)
                            ForEach(flight.layovers, id: \.self) { layover in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(C.patternLine)
                                        .frame(width: 6, height: 6)
                                    Text(airportCityName(layover) + " (\(layover))")
                                        .font(T.body)
                                        .foregroundColor(C.textPrimary)
                                }
                            }
                        }
                    }

                    // Family amenities
                    if let amenities = flight.familyAmenities, !amenities.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FAMILY AMENITIES")
                                .font(T.captionSm)
                                .tracking(0.8)
                                .foregroundColor(C.textSecondary)
                            FlowLayout(spacing: 8) {
                                ForEach(amenities, id: \.self) { amenity in
                                    Text(amenity)
                                        .font(T.captionMd)
                                        .foregroundColor(C.tipIcon)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(C.tipBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                    }

                    // Why we picked this
                    if !flight.reason.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("WHY WE PICKED THIS")
                                .font(T.captionSm)
                                .tracking(0.8)
                                .foregroundColor(C.textSecondary)
                            Text(flight.reason)
                                .font(T.body)
                                .foregroundColor(C.textPrimary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Action row: chevron + select
            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedFlight = isExpanded ? nil : flight.rank
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                        Text(isExpanded ? "Less" : "Details")
                            .font(T.bodyMedium)
                    }
                    .foregroundColor(C.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(C.iconBg)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.pill))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFlight = flight
                    }
                } label: {
                    Text("Select")
                        .font(T.bodyMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSelected ? C.buttonPrimary : C.accentTan)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.pill))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(S.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radii.inner, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radii.inner, style: .continuous)
                .stroke(isSelected ? C.buttonPrimary : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Select Button

    private var selectButton: some View {
        Button(action: {}) {
            Text("Select this flight")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(C.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.pill))
        }
        .padding(.horizontal, S.md)
        .padding(.bottom, S.lg)
    }

    // MARK: - Helpers

    private var formattedHeaderDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: departureDate) else { return departureDate }
        let output = DateFormatter()
        output.dateFormat = "MMM d"
        return output.string(from: date).uppercased()
    }

    private var originCityName: String {
        airportCityName(origin)
    }

    private var destinationCityName: String {
        airportCityName(destination)
    }

    private func airportCityName(_ code: String) -> String {
        let map = [
            "SFO": "San Francisco", "JFK": "New York", "LAX": "Los Angeles",
            "ORD": "Chicago", "LIS": "Lisbon", "CDG": "Paris",
            "LHR": "London", "FCO": "Rome", "NRT": "Tokyo",
            "BCN": "Barcelona", "AMS": "Amsterdam", "FRA": "Frankfurt",
        ]
        return map[code.uppercased()] ?? code
    }

    private func durationText(_ hours: Float) -> String {
        let h = Int(hours)
        let m = Int((hours - Float(h)) * 60)
        return "\(h)h \(m)m"
    }

    private func isNextDay(departure: String, arrival: String) -> Bool {
        // Simple heuristic: if arrival hour < departure hour, it's next day
        guard let depHour = Int(departure.prefix(2)),
              let arrHour = Int(arrival.prefix(2)) else { return false }
        return arrHour < depHour
    }
}

// MARK: - Preview

#Preview("Flights") {
    let flights = [
        FlightOption(rank: 1, airline: "TAP Portugal", flightNumber: "TP 206", score: 9, origin: "SFO", destination: "LIS", reason: "Best overall match for families", price: 1180, duration: 11.17, layovers: ["LHR"], departureDate: "2026-07-12", departureTime: "18:40", returnDate: "2026-07-19", returnTime: "14:50", bookingUrl: nil, familyAmenities: ["Bassinet available", "priority boarding"]),
        FlightOption(rank: 2, airline: "United + Lufthansa", flightNumber: "UA 900 · LH 1166", score: 8, origin: "SFO", destination: "LIS", reason: "Good connection via Frankfurt", price: 1090, duration: 13.33, layovers: ["FRA"], departureDate: "2026-07-12", departureTime: "15:20", returnDate: "2026-07-19", returnTime: "13:40", bookingUrl: nil, familyAmenities: ["Seat selection extra"]),
        FlightOption(rank: 3, airline: "Delta + KLM", flightNumber: "DL 166 · KL 1695", score: 7, origin: "SFO", destination: "LIS", reason: "Affordable option via Amsterdam", price: 1340, duration: 15.08, layovers: ["AMS"], departureDate: "2026-07-12", departureTime: "13:05", returnDate: "2026-07-19", returnTime: "15:10", bookingUrl: nil, familyAmenities: ["Child meals", "stroller at gate"]),
    ]

    NavigationStack {
        FlightsView(
            flights: flights,
            origin: "SFO",
            destination: "LIS",
            departureDate: "2026-07-12",
            hasKids: true
        )
    }
}
