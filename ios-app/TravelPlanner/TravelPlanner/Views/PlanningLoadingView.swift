//
//  PlanningLoadingView.swift
//  TravelPlanner
//

import SwiftUI

struct PlanningLoadingView: View {
    let draft: TripRequestDraft

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias S = DesignTokens.Spacing

    @State private var currentStepIndex: Int = 0
    @State private var orbitAngle: Double = 0
    @State private var pulseScale: Double = 1.0

    private var steps: [String] {
        buildSteps(from: draft)
    }

    var body: some View {
        ZStack {
            C.screenBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top-right "PLANNING..." label
                HStack {
                    Spacer()
                    Text("PLANNING...")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(C.textSecondary)
                }
                .padding(.horizontal, S.md)
                .padding(.top, 12)

                Spacer()

                // Animated spinner
                spinnerView
                    .padding(.bottom, 40)

                // Headline
                headlineView
                    .padding(.horizontal, S.md)

                Spacer()

                // Step checklist at bottom
                stepChecklist
                    .padding(.horizontal, S.md)
                    .padding(.bottom, S.lg)
            }
        }
        .onAppear {
            startOrbitAnimation()
            startStepProgression()
        }
    }

    // MARK: - Spinner

    private var spinnerView: some View {
        ZStack {
            // Outer dashed orbit ring
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                .frame(width: 120, height: 120)
                .foregroundColor(C.patternLine)

            // Orbiting dots
            orbitDot(offset: 0, color: C.tipIcon, size: 8)
            orbitDot(offset: .pi * 0.6, color: C.textSecondary.opacity(0.5), size: 6)
            orbitDot(offset: .pi * 1.2, color: C.textSecondary.opacity(0.3), size: 5)

            // Center dark circle with icon
            Circle()
                .fill(C.buttonPrimary)
                .frame(width: 56, height: 56)
                .scaleEffect(pulseScale)
                .overlay(
                    Image(systemName: "asterisk")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                )
        }
    }

    private func orbitDot(offset: Double, color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: 60 * cos(orbitAngle + offset), y: 60 * sin(orbitAngle + offset))
    }

    // MARK: - Headline

    private var headlineView: some View {
        VStack(spacing: 4) {
            Text("Dreaming up")
                .font(T.headlineLG)
                .foregroundColor(C.textPrimary)

            Text("your \(seasonWord).")
                .font(.system(size: 30, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(C.textPrimary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Step Checklist

    private var stepChecklist: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 12) {
                    stepIndicator(for: index)
                    Text(step)
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(stepTextColor(for: index))
                }
                .opacity(stepOpacity(for: index))
                .animation(.easeInOut(duration: 0.4), value: currentStepIndex)
            }
        }
    }

    @ViewBuilder
    private func stepIndicator(for index: Int) -> some View {
        if index < currentStepIndex {
            // Completed: checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(C.tipIcon)
        } else if index == currentStepIndex {
            // Current: filled dot
            Circle()
                .fill(C.textPrimary)
                .frame(width: 8, height: 8)
        } else {
            // Upcoming: empty/faint dot
            Circle()
                .fill(C.patternLine)
                .frame(width: 8, height: 8)
        }
    }

    private func stepTextColor(for index: Int) -> Color {
        if index < currentStepIndex {
            return C.textPrimary
        } else if index == currentStepIndex {
            return C.textPrimary
        } else {
            return C.textSecondary.opacity(0.5)
        }
    }

    private func stepOpacity(for index: Int) -> Double {
        if index <= currentStepIndex {
            return 1.0
        } else if index == currentStepIndex + 1 {
            return 0.5
        } else {
            return 0.3
        }
    }

    // MARK: - Animations

    private func startOrbitAnimation() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            orbitAngle = .pi * 2
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.06
        }
    }

    private func startStepProgression() {
        for i in 1..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 2.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentStepIndex = i
                }
            }
        }
    }

    // MARK: - Contextual Steps Builder

    private func buildSteps(from draft: TripRequestDraft) -> [String] {
        var result: [String] = []

        result.append("Reading your request...")

        // Destination-aware step
        let dest = draft.route.destination
        if !dest.isEmpty {
            result.append("Scanning \(dest) destinations...")
        } else {
            result.append("Scanning destinations...")
        }

        // Kid-aware step
        if draft.travelerInfo.hasKids == true {
            if let age = draft.travelerInfo.youngestTravelerAge, age <= 5 {
                result.append("Filtering for toddler-friendly...")
            } else {
                result.append("Filtering for family-friendly...")
            }
        } else {
            result.append("Curating top experiences...")
        }

        // Flight-aware step
        let origin = draft.route.origin
        if draft.transportPreferences.flightSelected == true && !origin.isEmpty {
            result.append("Pricing flights from \(origin)...")
        } else if draft.transportPreferences.flightSelected == true {
            result.append("Pricing flight options...")
        } else {
            result.append("Finding transport options...")
        }

        // Lodging-aware step
        if draft.lodgingPreferences.hotel == true && draft.lodgingPreferences.isFamilyFriendly == true {
            result.append("Matching stays with cribs & kitchens...")
        } else if draft.lodgingPreferences.hotel == true {
            result.append("Finding the best hotel deals...")
        } else if draft.lodgingPreferences.airbnb == true {
            result.append("Browsing top-rated rentals...")
        } else {
            result.append("Finding places to stay...")
        }

        // Count-aware final step
        result.append("Drafting 3 itineraries...")

        return result
    }

    // MARK: - Helpers

    private var seasonWord: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "spring"
        case 6...8: return "summer"
        case 9...11: return "autumn"
        default: return "winter"
        }
    }
}

#Preview("Default") {
    let calendar = Calendar.current
    let departure = calendar.date(from: DateComponents(year: 2026, month: 5, day: 10))
    let returnDate = calendar.date(from: DateComponents(year: 2026, month: 5, day: 20))
    
    let draft = TripRequestDraft(
        route: Route(origin: "SFO", destination: "Paris"),
        schedule: Schedule(departureDate: departure, returnDate: returnDate),
        travelerInfo: TravelerInfo(travelerCount: 3, hasKids: true, youngestTravelerAge: 3),
        transportPreferences: TransportPreferences(),
        lodgingPreferences: LodgingPreferences(hotel: true)
    )
    
    NavigationStack {
        PlanningLoadingView(draft: draft)
    }
}
