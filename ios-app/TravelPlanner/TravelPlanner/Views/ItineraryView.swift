//
//  ItineraryView.swift
//  TravelPlanner
//

import SwiftUI

struct ItineraryView: View {
    @ObservedObject var resultVM: TripResultViewModel
    let optionNumber: Int
    let destination: String
    var travelerCount: Int = 1

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias S = DesignTokens.Spacing

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ItineraryTab = .dayByDay
    @State private var showShareSheet = false

    private enum ItineraryTab: String, CaseIterable {
        case dayByDay = "Day By Day"
        case map = "Map"
        case budget = "Budget"
    }

    // Reactive derived values — these update when resultVM publishes changes
    private var itinerary: ItineraryOption {
        resultVM.itineraryOptions.first(where: { $0.optionNumber == optionNumber })
            ?? ItineraryOption(optionNumber: optionNumber, style: "", description: "", days: [], hotelStops: nil)
    }

    private var flights: [FlightOption] { resultVM.flights }

    private var topFlight: FlightOption? {
        flights.min(by: { $0.rank < $1.rank })
    }

    private var topHotel: HotelOption? {
        (itinerary.hotelStops ?? []).flatMap(\.hotels).first
    }

    private var dateRange: String {
        guard let first = itinerary.days.first, let last = itinerary.days.last else { return "" }
        let start = formattedShortDate(first.date)
        let end = formattedShortDate(last.date)
        return "\(start) – \(end)"
    }

    private var totalPrice: Int {
        let flightPrice = topFlight?.price ?? 0
        let hotelPrice = Int(topHotel?.totalPrice ?? 0)
        return flightPrice + hotelPrice
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            C.screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: S.lg) {
                    heroCard
                    quickAccessRow
                    tabBar
                    tabContent
                }
                .padding(.horizontal, S.md)
                .padding(.bottom, 100)
            }

            // Bottom CTA
            bookButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ITINERARY")
                    .font(T.labelUpper)
                    .tracking(1.2)
                    .foregroundColor(C.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showShareSheet = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(C.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareResultView(
                itinerary: itinerary,
                flights: flights,
                destination: destination,
                origin: topFlight?.origin ?? "",
                travelerCount: travelerCount,
                onStartNewTrip: {
                    // V0: dismiss back to root — V2 will handle saved trips
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            DiagonalStripePattern()
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.card))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(dateRange) · \(destination.uppercased())")
                    .font(T.captionSm)
                    .tracking(0.8)
                    .foregroundColor(C.textSecondary)

                Text("\(destination), \(itinerary.style)")
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundColor(C.textPrimary)
            }
            .padding(S.md)
        }
    }

    // MARK: - Quick Access Buttons

    private var quickAccessRow: some View {
        HStack(spacing: 12) {
            if let flight = topFlight {
                NavigationLink {
                    FlightsView(flights: flights, origin: flight.origin, destination: flight.destination, departureDate: flight.departureDate, hasKids: topHotel?.amenities.isEmpty == false)
                } label: {
                    quickAccessLabel(
                        icon: "sparkles",
                        title: "Flights",
                        subtitle: "$\(flight.price) · \(flight.airline)"
                    )
                }
                .buttonStyle(.plain)
            } else if !resultVM.isLoadingFlights {
                quickAccessLabel(icon: "sparkles", title: "Flights", subtitle: "No flights found")
            } else {
                quickAccessLabel(icon: "sparkles", title: "Flights", subtitle: "Loading...")
            }

            if let hotel = topHotel {
                NavigationLink {
                    HotelsView(
                        hotelStops: itinerary.hotelStops ?? [],
                        destination: destination,
                        departureDate: itinerary.days.first?.date ?? "",
                        returnDate: itinerary.days.last?.date ?? "",
                        hasKids: (itinerary.hotelStops ?? []).flatMap(\.hotels).contains(where: { !$0.amenities.isEmpty })
                    )
                } label: {
                    quickAccessLabel(
                        icon: "bed.double",
                        title: "Stay",
                        subtitle: hotel.name
                    )
                }
                .buttonStyle(.plain)
            } else if !resultVM.isLoadingHotels {
                quickAccessLabel(icon: "bed.double", title: "Stay", subtitle: "No hotels found")
            } else {
                quickAccessLabel(icon: "bed.double", title: "Stay", subtitle: "Loading...")
            }
        }
    }

    private func quickAccessLabel(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(C.textSecondary)
                .frame(width: 32, height: 32)
                .background(C.iconBg)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(T.bodyMedium)
                    .foregroundColor(C.textPrimary)
                Text(subtitle)
                    .font(T.captionMd)
                    .foregroundColor(C.textSecondary)
            }

            Spacer()

            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(C.textSecondary)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.inner))
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: S.lg) {
            ForEach(ItineraryTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(T.bodyMedium)
                            .foregroundColor(selectedTab == tab ? C.textPrimary : C.textSecondary)
                        Rectangle()
                            .fill(selectedTab == tab ? C.textPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .dayByDay:
            dayByDayContent
        case .map:
            Text("Map coming soon")
                .font(T.body)
                .foregroundColor(C.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 200)
        case .budget:
            Text("Budget breakdown coming soon")
                .font(T.body)
                .foregroundColor(C.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 200)
        }
    }

    // MARK: - Day By Day Timeline

    private var dayByDayContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(itinerary.days.enumerated()), id: \.element.dayNumber) { index, day in
                daySection(day: day, isLast: index == itinerary.days.count - 1)
            }
        }
    }

    private func daySection(day: TripDay, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day number + date + area title
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(String(format: "%02d", day.dayNumber))
                    .font(.system(size: 36, weight: .light, design: .default).monospacedDigit())
                    .foregroundColor(C.textPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDayDate(day.date).uppercased())
                        .font(T.captionSm)
                        .tracking(0.8)
                        .foregroundColor(C.textSecondary)
                    Text("\(day.area)")
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(C.textPrimary)
                }
            }

            // Activities timeline
            VStack(alignment: .leading, spacing: 0) {
                if let morning = day.morning {
                    activityRow(time: "09:00", type: morning.activity ?? "Morning", place: morning.place ?? "", showLine: day.afternoon != nil || day.evening != nil, notes: morning.notes)
                }
                if let afternoon = day.afternoon {
                    activityRow(time: "14:00", type: afternoon.activity ?? "Afternoon", place: afternoon.place ?? "", showLine: day.evening != nil, notes: afternoon.notes)
                }
                if let evening = day.evening {
                    activityRow(time: "19:00", type: evening.activity ?? "Evening", place: evening.place ?? "", showLine: false, notes: evening.notes)
                }
            }

            if !isLast {
                Divider()
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }

    private func activityRow(time: String, type: String, place: String, showLine: Bool, notes: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline dot + line
            VStack(spacing: 0) {
                Circle()
                    .stroke(C.textSecondary.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 10, height: 10)
                if showLine {
                    Rectangle()
                        .fill(C.patternLine)
                        .frame(width: 1)
                        .frame(minHeight: 40)
                }
            }
            .frame(width: 10)

            // Time
            Text(time)
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundColor(C.textSecondary)
                .frame(width: 40, alignment: .leading)

            // Content card
            VStack(alignment: .leading, spacing: 4) {
                Text(type.uppercased())
                    .font(T.captionSm)
                    .tracking(0.6)
                    .foregroundColor(C.textSecondary)

                Text(place)
                    .font(T.bodyMedium)
                    .foregroundColor(C.textPrimary)

                if let notes, !notes.isEmpty {
                    let tips = splitNotes(notes)
                    ForEach(tips, id: \.self) { tip in
                        Text(tip)
                            .font(T.captionMd)
                            .foregroundColor(C.textSecondary)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Pin icon
            Image(systemName: "mappin")
                .font(.system(size: 12))
                .foregroundColor(C.tipIcon)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Book Button

    private var bookButton: some View {
        Button(action: { showShareSheet = true }) {
            HStack {
                Text("Share this trip — $\(totalPrice)")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, S.lg)
            .padding(.vertical, 16)
            .background(C.buttonPrimary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.pill))
        }
        .padding(.horizontal, S.md)
        .padding(.bottom, S.lg)
    }

    // MARK: - Helpers

    /// Splits a notes string into separate tips.
    /// Looks for known prefixes like "Age 3:", "Traveler Tip:", "Insider Tip:", "Adults:" etc.
    /// and splits at each occurrence so each tip gets its own line.
    private func splitNotes(_ notes: String) -> [String] {
        // Pattern: split before known tip prefixes
        // Matches: "Age \d+:", "Traveler Tip:", "Insider Tip:", "Adults:", "Toddler Tip:", "Family Tip:"
        let pattern = #"(?=(?:Age \d+|Traveler Tip|Insider Tip|Adults?|Toddler Tip|Family Tip|Kids? Tip)\s*:)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [notes]
        }

        let nsString = notes as NSString
        let range = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: notes, range: range)

        // If no tip prefixes found, return as-is
        if matches.isEmpty { return [notes.trimmingCharacters(in: .whitespaces)] }

        var tips: [String] = []
        var lastStart = 0

        for match in matches {
            let matchLocation = match.range.location
            if matchLocation > lastStart {
                let chunk = nsString.substring(with: NSRange(location: lastStart, length: matchLocation - lastStart))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !chunk.isEmpty { tips.append(chunk) }
            }
            lastStart = matchLocation
        }

        // Grab the last segment
        let remaining = nsString.substring(from: lastStart)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !remaining.isEmpty { tips.append(remaining) }

        return tips
    }

    private func formattedShortDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let output = DateFormatter()
        output.dateFormat = "MMM d"
        return output.string(from: date)
    }

    private func formattedDayDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let output = DateFormatter()
        output.dateFormat = "EEE, MMM d"
        return output.string(from: date)
    }
}

// MARK: - Preview

#Preview("Itinerary Detail") {
    let sampleDays = [
        TripDay(dayNumber: 1, date: "2026-07-12", area: "Alfama",
                morning: PartOfDay(activity: "Check-in", place: "Boutique apt · Príncipe Real", foodSuggestion: nil, notes: "Age 3: Nap in the car. Adults : beautiful scenary", includeNap: false),
                afternoon: PartOfDay(activity: "Walk", place: "Miradouro de São Pedro sunset", foodSuggestion: nil, notes: "Wonderful place to walk", includeNap: false),
                evening: PartOfDay(activity: "Dinner", place: "Tasca Zé dos Cornos (kid-friendly)", foodSuggestion: nil, notes: nil, includeNap: false)),
        TripDay(dayNumber: 2, date: "2026-07-13", area: "Belém",
                morning: PartOfDay(activity: "Visit", place: "Jerónimos Monastery", foodSuggestion: nil, notes: nil, includeNap: true),
                afternoon: PartOfDay(activity: "Beach", place: "Cascais beach day", foodSuggestion: nil, notes: nil, includeNap: false),
                evening: PartOfDay(activity: "Dinner", place: "Time Out Market", foodSuggestion: nil, notes: nil, includeNap: false)),
        TripDay(dayNumber: 3, date: "2026-07-14", area: "Sintra",
                morning: PartOfDay(activity: "Day trip", place: "Pena Palace", foodSuggestion: nil, notes: nil, includeNap: false),
                afternoon: PartOfDay(activity: "Explore", place: "Quinta da Regaleira", foodSuggestion: nil, notes: nil, includeNap: false),
                evening: PartOfDay(activity: "Dinner", place: "Incomum by Luís Santos", foodSuggestion: nil, notes: nil, includeNap: false)),
    ]

    let sampleHotelStops = [
        HotelStop(area: "Príncipe Real", nights: 7, hotels: [
            HotelOption(name: "Casa Boma", type: "Apartment", area: "Príncipe Real", rating: 4.5, pricePerNight: 180, totalPrice: 3960, amenities: ["Pool", "Kitchen", "Crib"], score: 98, reason: "Great for families", bookingUrl: nil)
        ])
    ]

    let vm: TripResultViewModel = {
        let v = TripResultViewModel()
        v.itineraryOptions = [
            ItineraryOption(
                optionNumber: 1,
                style: "Balanced",
                description: "A mix of culture, food, and relaxation.",
                days: sampleDays,
                hotelStops: sampleHotelStops
            )
        ]
        v.flights = [
            FlightOption(rank: 1, airline: "TAP", flightNumber: "TP 206", score: 9, origin: "SFO", destination: "LIS", reason: "Direct route", price: 1180, duration: 11.3, layovers: ["JFK"], departureDate: "2026-07-12", departureTime: "18:30", returnDate: "2026-07-19", returnTime: "10:00", bookingUrl: nil, familyAmenities: ["Bassinet available"])
        ]
        v.isLoadingFlights = false
        v.isLoadingHotels = false
        return v
    }()

    NavigationStack {
        ItineraryView(
            resultVM: vm,
            optionNumber: 1,
            destination: "Lisbon",
            travelerCount: 3
        )
    }
}
