//
//  ItinerariesView.swift
//  TravelPlanner
//

import SwiftUI

struct ItinerariesView: View {
    @ObservedObject var resultVM: TripResultViewModel
    let draft: TripRequestDraft

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias S = DesignTokens.Spacing

    @Environment(\.dismiss) private var dismiss
    @State private var toddlerFriendly: Bool = false

    // MARK: - Derived properties

    private var destination: String { draft.route.destination }
    private var country: String { resultVM.destinationInfo?.country ?? ""}
    private var tagline: String { resultVM.destinationInfo?.tagline  ?? ""}
    private var weather: String { resultVM.destinationInfo?.weather ?? "" }
    private var timezone: String { resultVM.destinationInfo?.timezone ?? "" }
    private var itineraryOptions: [ItineraryOption] { resultVM.itineraryOptions }
    private var flights: [FlightOption] { resultVM.flights }
    private var hasKids: Bool { draft.travelerInfo.hasKids ?? false }

    private var flightSummary: String {
        guard let top = flights.min(by: { $0.rank < $1.rank }) else { return "" }
        let hours = Int(top.duration)
        let minutes = Int((top.duration - Float(hours)) * 60)
        let stops = top.layovers.count
        let stopText = stops == 0 ? "direct" : "\(stops) stop\(stops > 1 ? "s" : "")"
        return "\(hours)h \(minutes)m (\(stopText))"
    }

    var body: some View {
        ZStack {
            C.screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: S.lg) {
                    destinationHeader
                    infoRow
//                    if hasKids {
//                        toddlerToggle
//                    }
                    itineraryCards
                }
                .padding(.horizontal, S.md)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(itineraryOptions.count) ITINERARIES · \(destination.uppercased())")
                    .font(T.labelUpper)
                    .tracking(1.2)
                    .foregroundColor(C.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(C.textPrimary)
                }
            }
        }
    }

    // MARK: - Destination Header

    private var destinationHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESTINATION · MATCHED")
                .font(T.labelUpper)
                .tracking(1.2)
                .foregroundColor(C.tipIcon)
                .padding(.top, S.sm)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(destination),")
                    .font(T.headlineXL)
                    .foregroundColor(C.textPrimary)
                Text(country + ".")
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(C.textPrimary)
            }

            Text(tagline)
                .font(T.body)
                .foregroundColor(C.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Info Row

    private var infoRow: some View {
        HStack(spacing: S.lg) {
            infoColumn(label: "WEATHER", value: weather)
            infoColumn(label: "FLIGHT", value: flightSummary)
            infoColumn(label: "TIMEZONE", value: timezone)
        }
    }

    private func infoColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(T.captionSm)
                .tracking(0.8)
                .foregroundColor(C.textSecondary)
            Text(value)
                .font(T.bodyMedium)
                .foregroundColor(C.textPrimary)
        }
    }

//    // MARK: - Toddler Toggle
//
//    private var toddlerToggle: some View {
//        HStack(spacing: 12) {
//            Circle()
//                .fill(C.tipIcon.opacity(0.15))
//                .frame(width: 40, height: 40)
//                .overlay(
//                    Image(systemName: "figure.and.child.holdinghands")
//                        .font(.system(size: 16))
//                        .foregroundColor(C.tipIcon)
//                )
//
//            VStack(alignment: .leading, spacing: 2) {
//                Text("Toddler-friendly mode")
//                    .font(T.bodyMedium)
//                    .foregroundColor(C.textPrimary)
//                Text("Naps, strollers, calm beaches, short walks")
//                    .font(T.captionMd)
//                    .foregroundColor(C.textSecondary)
//            }
//
//            Spacer()
//
//            Toggle("", isOn: $toddlerFriendly)
//                .labelsHidden()
//                .tint(C.tipIcon)
//        }
//        .padding(S.sm)
//        .background(C.cardBg)
//        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.inner))
//    }

    // MARK: - Itinerary Cards

    private var itineraryCards: some View {
        VStack(spacing: S.md) {
            ForEach(Array(itineraryOptions.enumerated()), id: \.element.optionNumber) { _, option in
                NavigationLink {
                    ItineraryView(
                        resultVM: resultVM,
                        optionNumber: option.optionNumber,
                        destination: destination,
                        travelerCount: draft.travelerInfo.travelerCount ?? 1
                    )
                } label: {
                    itineraryCard(option)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func itineraryCard(_ option: ItineraryOption) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pattern hero area
            ZStack(alignment: .topTrailing) {
                DiagonalStripePattern()
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.inner))

                // Score badge
                let topHotel = option.hotelStops?.flatMap(\.hotels).max(by: { $0.score < $1.score })
                if let score = topHotel?.score {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.and.child.holdinghands")
                            .font(.system(size: 10))
                        Text("\(score)")
                            .font(T.bodyMedium)
                    }
                    .foregroundColor(C.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(10)
                }

                // Style tag bottom-left
                VStack {
                    Spacer()
                    HStack {
                        Text(option.style.uppercased().replacingOccurrences(of: " ", with: "-"))
                            .font(T.captionSm)
                            .tracking(0.8)
                            .foregroundColor(C.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }
                    .padding(10)
                }
            }

            // Meta line + price
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    let stopsPerDay = option.days.isEmpty ? 0 : max(1, 3) // placeholder heuristic
                    Text("RELAXED · \(stopsPerDay) STOPS/DAY")
                        .font(T.captionSm)
                        .tracking(0.6)
                        .foregroundColor(C.textSecondary)

                    Text(option.style)
                        .font(T.headlineLG)
                        .foregroundColor(C.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    let hotelPrice = option.hotelStops?.flatMap(\.hotels).first.map {
                        Int($0.totalPrice)
                    } ?? 0
                    let flightPrice = flights.min(by: { $0.rank < $1.rank })?.price ?? 0
                    let totalPrice = hotelPrice + flightPrice
                    Text(totalPrice > 0 ? "$\(totalPrice)" : "—")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundColor(C.textPrimary)
                    Text("TOTAL · \(option.days.count)N")
                        .font(T.captionSm)
                        .tracking(0.6)
                        .foregroundColor(C.textSecondary)
                }
            }

            // Description
            Text(option.description)
                .font(T.body)
                .foregroundColor(C.textSecondary)
                .lineLimit(2)

            // Tag chips — use area names from stops
            let tags = (option.hotelStops ?? []).map(\.area)
            if !(tags.isEmpty) {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(T.captionMd)
                            .foregroundColor(C.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(C.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.card))
    }
}

// MARK: - Diagonal Stripe Pattern

struct DiagonalStripePattern: View {
    private typealias C = DesignTokens.Colors

    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 8
            let gap: CGFloat = 8
            let step = stripeWidth + gap
            let count = Int((size.width + size.height) / step) + 1

            for i in 0..<count {
                let offset = CGFloat(i) * step
                var path = Path()
                path.move(to: CGPoint(x: offset, y: 0))
                path.addLine(to: CGPoint(x: offset - size.height, y: size.height))
                context.stroke(path, with: .color(Color(red: 212/255, green: 204/255, blue: 196/255)), lineWidth: stripeWidth)
            }
        }
        .background(C.patternBg)
    }
}

// MARK: - Preview

#Preview("Itineraries") {
    let sampleDays = [
        TripDay(dayNumber: 1, date: "2026-07-12", area: "Alfama", morning: PartOfDay(activity: "Check-in", place: "Boutique apt · Príncipe Real", foodSuggestion: nil, notes: nil, includeNap: false), afternoon: PartOfDay(activity: "Walk", place: "Miradouro de São Pedro sunset", foodSuggestion: nil, notes: nil, includeNap: false), evening: PartOfDay(activity: "Dinner", place: "Tasca Zé dos Cornos", foodSuggestion: "kid-friendly", notes: nil, includeNap: false)),
        TripDay(dayNumber: 2, date: "2026-07-13", area: "Belém", morning: PartOfDay(activity: "Visit", place: "Jerónimos Monastery", foodSuggestion: nil, notes: nil, includeNap: true), afternoon: PartOfDay(activity: "Beach", place: "Cascais beach day", foodSuggestion: nil, notes: nil, includeNap: false), evening: PartOfDay(activity: "Dinner", place: "Time Out Market", foodSuggestion: nil, notes: nil, includeNap: false)),
    ]

    let sampleHotelStops = [
        HotelStop(area: "Jardim da Estrela playground", nights: 4, hotels: [
            HotelOption(name: "Casa Boma", type: "Apartment", area: "Príncipe Real", rating: 4.5, pricePerNight: 180, totalPrice: 4280, amenities: ["Pool", "Kitchen"], score: 98, reason: "Great for families", bookingUrl: nil)
        ]),
        HotelStop(area: "Tram 28 slow ride", nights: 3, hotels: [
            HotelOption(name: "Hotel B", type: "Boutique Hotel", area: "Alfama", rating: 4.2, pricePerNight: 150, totalPrice: 3200, amenities: ["Breakfast"], score: 90, reason: "Central", bookingUrl: nil)
        ]),
        HotelStop(area: "Cascais beach day", nights: 2, hotels: []),
    ]

    let response = FinalTripResponse(
        destinationInfo: DestinationInfo(country: "Portugal", tagline: "Seven tiled hills, sea-breeze mornings, custard-tart afternoons.", weather: "26° · Sunny", timezone: "GMT+1"),
        flights: [
            FlightOption(rank: 1, airline: "TAP", flightNumber: "TP 206", score: 9, origin: "SFO", destination: "LIS", reason: "Direct flight", price: 1180, duration: 11.3, layovers: ["JFK"], departureDate: "2026-07-12", departureTime: "18:30", returnDate: "2026-07-19", returnTime: "10:00", bookingUrl: nil, familyAmenities: ["Bassinet available"])
        ],
        itineraryOptions: [
            ItineraryOption(optionNumber: 1, style: "Slow Lisbon", description: "Lazy mornings, shaded parks, one activity per day. Toddler-tested.", days: sampleDays, hotelStops: sampleHotelStops),
            ItineraryOption(optionNumber: 2, style: "Culture Deep-Dive", description: "Fado nights, tiled alleyways, pastéis de nata crawl across three neighborhoods.", days: sampleDays, hotelStops: sampleHotelStops),
            ItineraryOption(optionNumber: 3, style: "Coastal Explorer", description: "Day trips to Sintra and Cascais, sunset at Cabo da Roca.", days: sampleDays, hotelStops: sampleHotelStops),
        ],
        cannotGenerate: false,
        reason: nil
    )

    let draft = TripRequestDraft(
        route: Route(origin: "SFO", destination: "Lisbon"),
        schedule: Schedule(),
        travelerInfo: TravelerInfo(hasKids: true),
        transportPreferences: TransportPreferences(flightSelected: true),
        lodgingPreferences: LodgingPreferences(hotel: true)
    )

    let vm: TripResultViewModel = {
        let v = TripResultViewModel()
        v.destinationInfo = response.destinationInfo
        v.itineraryOptions = response.itineraryOptions
        v.flights = response.flights
        v.isLoadingFlights = false
        v.isLoadingHotels = false
        return v
    }()

    NavigationStack {
        ItinerariesView(resultVM: vm, draft: draft)
    }
}
