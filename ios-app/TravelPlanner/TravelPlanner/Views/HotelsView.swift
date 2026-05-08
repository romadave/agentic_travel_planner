//
//  HotelsView.swift
//  TravelPlanner
//

import SwiftUI

struct HotelsView: View {
    let hotelStops: [HotelStop]
    let destination: String
    let departureDate: String
    let returnDate: String
    let hasKids: Bool

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias S = DesignTokens.Spacing

    @Environment(\.dismiss) private var dismiss
    @State private var selectedHotel: HotelOption? = nil
    @State private var expandedHotel: String? = nil

    private var allHotels: [HotelOption] {
        hotelStops.flatMap(\.hotels)
    }

    private var totalNights: Int {
        hotelStops.reduce(0) { $0 + $1.nights }
    }

    private var dateRange: String {
        let start = formattedShortDate(departureDate)
        let end = formattedShortDate(returnDate)
        return "\(start) – \(end)"
    }

    private var familyTip: String? {
        guard hasKids else { return nil }
        let withCribs = allHotels.filter { $0.amenities.contains(where: { $0.localizedCaseInsensitiveContains("crib") }) }.count
        let withKitchen = allHotels.filter { $0.amenities.contains(where: { $0.localizedCaseInsensitiveContains("kitchen") }) }.count
        if withCribs > 0 || withKitchen > 0 {
            var parts: [String] = []
            if withCribs == allHotels.count {
                parts.append("All \(withCribs) have cribs & quiet hours")
            } else if withCribs > 0 {
                parts.append("\(withCribs) have cribs")
            }
            if withKitchen > 0 {
                parts.append("Kitchen in #\(allHotels.firstIndex(where: { $0.amenities.contains(where: { $0.localizedCaseInsensitiveContains("kitchen") }) }).map { $0 + 1 } ?? 1)")
            }
            return parts.joined(separator: ". ") + "."
        }
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            C.screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: S.lg) {
                    header
                    if let tip = familyTip {
                        tipBanner(tip)
                    }
                    hotelCards
                }
                .padding(.horizontal, S.md)
                .padding(.bottom, 100)
            }

            if selectedHotel != nil {
                selectButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("STAYS · \(destination.uppercased())")
                    .font(T.labelUpper)
                    .tracking(1.2)
                    .foregroundColor(C.textSecondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "map")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(C.textPrimary)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Where you'll")
                    .font(T.headlineXL)
                    .foregroundColor(C.textPrimary)
                Text("rest.")
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(C.textPrimary)
            }
            .padding(.top, S.sm)

            Text("\(allHotels.count) stays · \(totalNights) nights · \(dateRange)")
                .font(T.captionMd)
                .foregroundColor(C.textSecondary)
        }
    }

    // MARK: - Family Tip

    private func tipBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.and.child.holdinghands")
                .font(.system(size: 14))
                .foregroundColor(C.tipIcon)

            Text(text)
                .font(T.captionMd)
                .foregroundColor(C.textPrimary)
        }
        .padding(S.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(C.tipBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.inner))
    }

    // MARK: - Hotel Cards

    private var hotelCards: some View {
        VStack(spacing: S.md) {
            ForEach(Array(allHotels.enumerated()), id: \.element.name) { index, hotel in
                hotelCard(hotel, isTopPick: index == 0)
            }
        }
    }

    private func hotelCard(_ hotel: HotelOption, isTopPick: Bool) -> some View {
        let isSelected = selectedHotel == hotel
        let isExpanded = expandedHotel == hotel.name

        return VStack(alignment: .leading, spacing: 12) {
            // Stripe pattern hero
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .topTrailing) {
                    DiagonalStripePattern()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.inner))

                    // Rating badge
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", hotel.rating))
                            .font(T.bodyMedium)
                    }
                    .foregroundColor(C.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(10)
                }

                // Tags overlay
                VStack(alignment: .leading, spacing: 6) {
                    if isTopPick {
                        Text("TOP PICK")
                            .font(T.captionSm)
                            .tracking(0.8)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(C.buttonPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    if let type = hotel.type {
                        let typeLabel = hotel.amenities.contains(where: { $0.localizedCaseInsensitiveContains("2BR") || $0.localizedCaseInsensitiveContains("bedroom") })
                            ? "\(type.uppercased()) · 2BR"
                            : type.uppercased()
                        Text(typeLabel)
                            .font(T.captionSm)
                            .tracking(0.6)
                            .foregroundColor(C.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(10)
            }

            // Meta line + name + price
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    let meta = [hotel.type?.uppercased(), hotel.area.uppercased()]
                        .compactMap { $0 }
                        .joined(separator: " · ")
                    if !meta.isEmpty {
                        Text(meta)
                            .font(T.captionSm)
                            .tracking(0.6)
                            .foregroundColor(C.textSecondary)
                    }

                    Text(hotel.name + " · " + hotel.area)
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .foregroundColor(C.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(hotel.pricePerNight))")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(C.textPrimary)
                    Text("/ NIGHT")
                        .font(T.captionSm)
                        .tracking(0.6)
                        .foregroundColor(C.textSecondary)
                }
            }

            // Expandable details
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    // Cost breakdown
                    VStack(alignment: .leading, spacing: 6) {
                        Text("COST")
                            .font(T.captionSm)
                            .tracking(0.8)
                            .foregroundColor(C.textSecondary)

                        HStack {
                            Text("$\(Int(hotel.pricePerNight)) × \(totalNights) nights")
                                .font(T.body)
                                .foregroundColor(C.textPrimary)
                            Spacer()
                            Text("$\(Int(hotel.totalPrice))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(C.textPrimary)
                        }
                    }

                    // Amenities
                    if !hotel.amenities.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AMENITIES")
                                .font(T.captionSm)
                                .tracking(0.8)
                                .foregroundColor(C.textSecondary)

                            FlowLayout(spacing: 8) {
                                ForEach(hotel.amenities, id: \.self) { amenity in
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

                    // Reason
                    if !hotel.reason.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("WHY WE PICKED THIS")
                                .font(T.captionSm)
                                .tracking(0.8)
                                .foregroundColor(C.textSecondary)
                            Text(hotel.reason)
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
                        expandedHotel = isExpanded ? nil : hotel.name
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
                        selectedHotel = hotel
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
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.card))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radii.card)
                .stroke(isSelected ? C.buttonPrimary : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Select Button

    private var selectButton: some View {
        Button(action: {}) {
            Text("Select this stay")
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

    private func formattedShortDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let output = DateFormatter()
        output.dateFormat = "MMM d"
        return output.string(from: date)
    }
}

// MARK: - Preview

#Preview("Hotels") {
    let hotelStops = [
        HotelStop(area: "Príncipe Real", nights: 7, hotels: [
            HotelOption(name: "Casa Boma", type: "Apartment", area: "Príncipe Real", rating: 4.9, pricePerNight: 285, totalPrice: 1995, amenities: ["Crib on request", "Childproof locks", "Playground 2min"], score: 98, reason: "Perfect for families with toddlers", bookingUrl: nil),
            HotelOption(name: "The Vintage Lisbon", type: "Boutique Hotel", area: "Avenida da Liberdade", rating: 4.8, pricePerNight: 340, totalPrice: 2380, amenities: ["Connecting rooms", "Kids menu", "Stroller loan"], score: 92, reason: "Central luxury with family amenities", bookingUrl: nil),
            HotelOption(name: "Martinhal Chiado", type: "Apart-Hotel", area: "Chiado", rating: 4.7, pricePerNight: 310, totalPrice: 2170, amenities: ["Kids club", "Kitchen", "Baby equipment"], score: 90, reason: "Purpose-built for families", bookingUrl: nil),
        ])
    ]

    NavigationStack {
        HotelsView(
            hotelStops: hotelStops,
            destination: "Lisbon",
            departureDate: "2026-07-12",
            returnDate: "2026-07-19",
            hasKids: true
        )
    }
}
