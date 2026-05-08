//
//  ShareResultView.swift
//  TravelPlanner
//
//  Created by Roma Dave on 5/5/26.
//

import SwiftUI

struct ShareResultView: View {
    let itinerary: ItineraryOption
    let flights: [FlightOption]
    let destination: String
    let origin: String
    let travelerCount: Int
    let onStartNewTrip: () -> Void

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias S = DesignTokens.Spacing

    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var sendState: SendState = .idle
    @FocusState private var emailFocused: Bool

    private enum SendState: Equatable {
        case idle
        case sending
        case sent
        case failed(String)
    }

    // Derived values
    private var topFlight: FlightOption? {
        flights.min(by: { $0.rank < $1.rank })
    }

    private var topHotel: HotelOption? {
        itinerary.hotelStops.flatMap(\.hotels).first
    }

    private var totalNights: Int {
        itinerary.hotelStops.reduce(0) { $0 + $1.nights }
    }

    private var totalPrice: Int {
        let flightPrice = topFlight?.price ?? 0
        let hotelPrice = Int(topHotel?.totalPrice ?? 0)
        return flightPrice + hotelPrice
    }

    private var dateRange: String {
        guard let first = itinerary.days.first, let last = itinerary.days.last else { return "" }
        return "\(formattedShortDate(first.date)) – \(formattedShortDate(last.date))"
    }

    private var tripNumber: String {
        let hash = abs(("\(destination)\(itinerary.optionNumber)").hashValue) % 9999
        return "A-\(String(format: "%04d", hash))"
    }

    private var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    var body: some View {
        VStack(spacing: S.lg) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(C.patternLine)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ITINERARY SAVED")
                        .font(T.captionSm)
                        .tracking(1.0)
                        .foregroundColor(C.tipIcon)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(destination),")
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .foregroundColor(C.textPrimary)
                        Text(itinerary.style.lowercased())
                            .font(.system(size: 28, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(C.textPrimary)
                    }
                }

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(C.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(C.cardBg)
                        .clipShape(Circle())
                }
            }

            // Trip summary card
            tripSummaryCard

            // Email section
            emailSection

            Spacer()

            // Start new trip
            Button {
                dismiss()
                onStartNewTrip()
            } label: {
                HStack(spacing: 6) {
                    Text("Start a new trip")
                        .font(T.bodyMedium)
                        .foregroundColor(C.textPrimary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(C.textPrimary)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, S.md)
        }
        .padding(.horizontal, S.md)
        .background(Color.white)
    }

    // MARK: - Trip Summary Card

    private var tripSummaryCard: some View {
        VStack(spacing: 14) {
            // Trip number + dates
            HStack {
                Text("TRIP № \(tripNumber)")
                    .font(T.captionSm)
                    .tracking(0.8)
                    .foregroundColor(C.textSecondary)
                Spacer()
                Text(dateRange.uppercased())
                    .font(T.captionSm)
                    .tracking(0.8)
                    .foregroundColor(C.textSecondary)
            }

            // Route
            HStack {
                Text(origin)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundColor(C.textPrimary)

                Spacer()

                // Dotted line + star
                HStack(spacing: 0) {
                    dottedLine
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundColor(C.textSecondary)
                    dottedLine
                }
                .frame(maxWidth: 120)

                Spacer()

                Text(topFlight?.destination ?? destination)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundColor(C.textPrimary)
            }

            // Stats row
            HStack(spacing: 0) {
                Text("\(travelerCount) travelers")
                    .font(T.captionMd)
                    .foregroundColor(C.textSecondary)
                Text("  ·  ")
                    .foregroundColor(C.patternLine)
                Text("\(totalNights) nights")
                    .font(T.captionMd)
                    .foregroundColor(C.textSecondary)
                Text("  ·  ")
                    .foregroundColor(C.patternLine)
                Text("$\(totalPrice)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(C.textPrimary)
            }
        }
        .padding(S.sm)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.inner))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radii.inner)
                .stroke(C.patternLine, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
    }

    // MARK: - Email Section

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EMAIL YOUR ITINERARY")
                .font(T.captionSm)
                .tracking(0.8)
                .foregroundColor(C.textSecondary)

            Text("We'll convert your trip into a PDF and send it to your inbox.")
                .font(T.captionMd)
                .foregroundColor(C.textSecondary)

            HStack(spacing: 10) {
                TextField("your@email.com", text: $email)
                    .font(T.body)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($emailFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(C.screenBg)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.inner))

                Button {
                    sendEmail()
                } label: {
                    Group {
                        switch sendState {
                        case .sending:
                            ProgressView()
                                .tint(.white)
                        case .sent:
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                        default:
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(sendButtonColor)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.inner))
                }
                .buttonStyle(.plain)
                .disabled(!isValidEmail || sendState == .sending || sendState == .sent)
            }

            // Status messages
            switch sendState {
            case .sent:
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(C.tipIcon)
                    Text("Sent! Check your inbox.")
                        .font(T.captionMd)
                        .foregroundColor(C.tipIcon)
                }
            case .failed(let message):
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                    Text(message)
                        .font(T.captionMd)
                        .foregroundColor(.red.opacity(0.7))
                }
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Helpers

    private var sendButtonColor: Color {
        switch sendState {
        case .sent: return C.tipIcon
        case .sending: return C.accentTan
        default: return isValidEmail ? C.buttonPrimary : C.patternLine
        }
    }

    private var dottedLine: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(C.patternLine, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .frame(height: 1)
    }

    private func formattedShortDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let output = DateFormatter()
        output.dateFormat = "MMM d"
        return output.string(from: date)
    }

    private func sendEmail() {
        emailFocused = false
        sendState = .sending

        Task {
            do {
                let apiService = TripAPIService()
                try await apiService.shareItinerary(
                    email: email,
                    itinerary: itinerary,
                    flights: flights
                )
                sendState = .sent
            } catch {
                sendState = .failed("Could not send. Try again.")
            }
        }
    }
}

// MARK: - Preview

#Preview("Share Result") {
    let sampleDays = [
        TripDay(dayNumber: 1, date: "2026-07-12", area: "Alfama",
                morning: PartOfDay(activity: "Check-in", place: "Boutique apt", foodSuggestion: nil, notes: nil, includeNap: false),
                afternoon: nil, evening: nil),
        TripDay(dayNumber: 2, date: "2026-07-13", area: "Belém",
                morning: nil, afternoon: nil, evening: nil),
    ]

    let sampleHotelStops = [
        HotelStop(area: "Príncipe Real", nights: 7, hotels: [
            HotelOption(name: "Casa Boma", type: "Apartment", area: "Príncipe Real", rating: 4.9, pricePerNight: 285, totalPrice: 1995, amenities: ["Pool"], score: 98, reason: "Great", bookingUrl: nil)
        ])
    ]

    let itinerary = ItineraryOption(
        optionNumber: 1,
        style: "Balanced",
        description: "A mix of culture and relaxation.",
        days: sampleDays,
        hotelStops: sampleHotelStops
    )

    let flights = [
        FlightOption(rank: 1, airline: "TAP", flightNumber: "TP 206", score: 9, origin: "SFO", destination: "LIS", reason: "Direct", price: 1180, duration: 11.3, layovers: [], departureDate: "2026-07-12", departureTime: "18:30", returnDate: "2026-07-19", returnTime: "10:00", bookingUrl: nil, familyAmenities: nil)
    ]

    ShareResultView(
        itinerary: itinerary,
        flights: flights,
        destination: "Lisbon",
        origin: "SFO",
        travelerCount: 3,
        onStartNewTrip: {}
    )
    .presentationDetents([.medium, .large])
}
