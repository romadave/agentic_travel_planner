//
//  FollowUpQuestionsView.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/18/26.
//
import SwiftUI

struct FollowUpQuestionsView: View {
    @ObservedObject var viewModel: TripDraftViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex: Int = 0
    @State private var textAnswer: String = ""
    @State private var departureDate: Date = .now
    @State private var returnDate: Date = .now
    @State private var adultCount: Int = 2
    @State private var childCount: Int = 0
    @State private var childAge: Int = 3
    @State private var flightSelected = false
    @State private var roadSelected = false
    @State private var trainSelected = false
    @State private var hotelSelected = false
    @State private var airbnbSelected = false

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias S = DesignTokens.Spacing
    private typealias R = DesignTokens.Radii

    var body: some View {
        ZStack {
            C.screenBg.ignoresSafeArea()

            switch viewModel.screen2State {
            case .idle:
                Text("Ready to plan your trip.")
                    .font(T.body)
                    .foregroundColor(C.textSecondary)

            case .loading:
                VStack(spacing: S.sm) {
                    ProgressView()
                    Text("Analyzing your trip request...")
                        .font(T.body)
                        .foregroundColor(C.textSecondary)
                }

            case .loaded(let evaluation):
                loadedView(evaluation: evaluation)

            case .submittingFinal:
                VStack(spacing: S.sm) {
                    ProgressView()
                    Text("Building your trip plan...")
                        .font(T.body)
                        .foregroundColor(C.textSecondary)
                }

            case .finalResult(let response):
                finalResultView(response: response)

            case .failed(let errorMessage):
                VStack(alignment: .leading, spacing: 12) {
                    Text("Something went wrong")
                        .font(T.headlineLG)
                        .foregroundColor(C.textPrimary)
                    Text(errorMessage)
                        .font(T.body)
                        .foregroundColor(C.textSecondary)
                    PrimaryButton(
                        action: { Task { await viewModel.submitPrompt() } },
                        content: {
                            Text("Try Again")
                                .font(T.bodyMedium)
                        },
                        buttonClicked: false,
                        icon: "arrow.clockwise"
                    )
                }
                .padding(.horizontal, S.md)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Loaded (stepper) view

    @ViewBuilder
    private func loadedView(evaluation: TripEvaluation) -> some View {
        let questions = evaluation.missingRequirements
        let safeIndex = questions.isEmpty ? 0 : min(currentIndex, questions.count - 1)
        let isLastStep = !questions.isEmpty && safeIndex == questions.count - 1
        let totalSteps = questions.count

        VStack(spacing: 0) {
            // -- Top nav bar --
            topBar(current: safeIndex, total: totalSteps)

            // -- Segmented progress --
            segmentedProgress(current: safeIndex, total: totalSteps)
                .padding(.top, 4)

            // -- Summary banner (only on first step) --
            if safeIndex == 0, !evaluation.tripSummary.isEmpty {
                summaryBanner(evaluation.tripSummary)
                    .padding(.horizontal, S.md)
                    .padding(.top, S.md)
            }

            // -- Scrollable question content --
            ScrollView {
                VStack(alignment: .leading, spacing: S.sm) {
                    if !questions.isEmpty {
                        questionContent(for: questions[safeIndex])
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(questions[safeIndex].rawValue)
                    } else {
                        Text("We have everything we need.")
                            .font(T.headlineLG)
                            .foregroundColor(C.textPrimary)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: safeIndex)
                .padding(.horizontal, S.md)
                .padding(.top, S.lg)
                .padding(.bottom, 100) // room for bottom button
            }

            Spacer(minLength: 0)

            // -- Bottom button --
            bottomButton(
                questions: questions,
                safeIndex: safeIndex,
                isLastStep: isLastStep
            )
            .padding(.horizontal, S.md)
            .padding(.bottom, S.sm)
        }
        .onAppear {
            if currentIndex >= questions.count, !questions.isEmpty {
                currentIndex = max(0, questions.count - 1)
            }
        }
    }

    // MARK: - Top bar

    private func topBar(current: Int, total: Int) -> some View {
        HStack {
            Button { goBack(total: total) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(C.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(C.cardBg))
            }

            Spacer()

            if total > 0 {
                Text(String(format: "%02d / %02d", current + 1, total))
                    .font(T.stepCounter)
                    .foregroundColor(C.textSecondary)
            }

            Spacer()

            Button("Skip") {
                advanceOrSubmit(questions: currentQuestions, safeIndex: current, skipPersist: true)
            }
            .font(T.bodyMedium)
            .foregroundColor(C.textSecondary)
        }
        .padding(.horizontal, S.md)
        .padding(.top, 8)
    }

    // MARK: - Segmented progress bar

    private func segmentedProgress(current: Int, total: Int) -> some View {
        GeometryReader { geo in
            HStack(spacing: 4) {
                ForEach(0..<max(total, 1), id: \.self) { i in
                    Capsule()
                        .fill(i <= current ? C.progressFill : C.progressTrack)
                        .frame(height: 3)
                }
            }
        }
        .frame(height: 3)
        .padding(.horizontal, S.md)
    }

    // MARK: - Summary banner ("WE UNDERSTOOD")

    private func summaryBanner(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WE UNDERSTOOD")
                .font(T.labelUpper)
                .tracking(1.2)
                .foregroundColor(C.textSecondary)
            Text(summary)
                .font(T.body)
                .foregroundColor(C.textPrimary)
        }
        .padding(S.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                .fill(C.cardBg)
        )
    }

    // MARK: - Question content (headline + subtitle + controls)

    @ViewBuilder
    private func questionContent(for requirement: TripRequirement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Headline
            Text(questionTitle(for: requirement))
                .font(T.headlineLG)
                .foregroundColor(C.textPrimary)

            // Subtitle
            Text(questionSubtitle(for: requirement))
                .font(T.body)
                .foregroundColor(C.textSecondary)
                .padding(.bottom, 4)

            // Controls
            questionControls(for: requirement)
        }
    }

    @ViewBuilder
    private func questionControls(for requirement: TripRequirement) -> some View {
        switch requirement {
        case .destination, .origin:
            StyledTextField(
                text: $textAnswer,
                hint: requirement == .origin ? "City or airport" : "Where to?",
                icon: "mappin.circle"
            )

            // Quick-pick chips
            let suggestions = requirement == .origin
                ? ["San Francisco", "New York", "London", "Toronto"]
                : ["Paris", "Tokyo", "Rome", "Barcelona"]
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { city in
                    ChipButton(
                        title: city,
                        isSelected: Binding(
                            get: { textAnswer == city },
                            set: { selected in textAnswer = selected ? city : "" }
                        )
                    )
                }
            }

        case .travelDates:
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("", selection: $departureDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(C.buttonPrimary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                            .fill(Color.white)
                    )
            }

        case .travelerCount, .hasKids, .youngestTravelerAge:
            VStack(spacing: 0) {
                StepperRow(
                    label: "Adults",
                    subtitle: "13+ years",
                    icon: "person.crop.circle",
                    value: $adultCount,
                    range: 1...20
                )
                .padding(.vertical, 14)

                Divider()

                StepperRow(
                    label: "Toddler",
                    subtitle: "\(childAge) years",
                    icon: "person.crop.circle",
                    value: $childCount,
                    range: 0...10
                )
                .padding(.vertical, 14)
            }
            .padding(.horizontal, S.sm)
            .background(
                RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                    .stroke(C.patternLine, lineWidth: 1)
            )

        case .transportMode:
            FlowLayout(spacing: 10) {
                ChipButton(title: "Flight", icon: "airplane", isSelected: $flightSelected)
                ChipButton(title: "Road", icon: "car", isSelected: $roadSelected)
                ChipButton(title: "Train", icon: "tram", isSelected: $trainSelected)
            }

        case .lodgingPreferences:
            FlowLayout(spacing: 10) {
                ChipButton(title: "Hotel", icon: "bed.double", isSelected: $hotelSelected)
                ChipButton(title: "Apartment w/ kitchen", icon: "bed.double", isSelected: $airbnbSelected)
            }
        }
    }

    // MARK: - Bottom button

    @ViewBuilder
    private func bottomButton(questions: [TripRequirement], safeIndex: Int, isLastStep: Bool) -> some View {
        let buttonTitle = isLastStep || questions.isEmpty ? "Build my itineraries" : "Continue"
        PrimaryButton(
            action: {
                advanceOrSubmit(questions: questions, safeIndex: safeIndex, skipPersist: false)
            },
            content: {
                Text(buttonTitle)
                    .font(T.bodyMedium)
            },
            buttonClicked: false,
            icon: "arrow.right"
        )
    }

    // MARK: - Navigation helpers

    private var currentQuestions: [TripRequirement] {
        if case .loaded(let eval) = viewModel.screen2State {
            return eval.missingRequirements
        }
        return []
    }

    private func goBack(total: Int) {
        if currentIndex > 0 {
            withAnimation { currentIndex -= 1 }
        } else {
            dismiss()
        }
    }

    private func advanceOrSubmit(questions: [TripRequirement], safeIndex: Int, skipPersist: Bool) {
        let isLastStep = !questions.isEmpty && safeIndex == questions.count - 1

        if !skipPersist && !questions.isEmpty {
            persistAnswer(for: questions[safeIndex])
        }

        viewModel.reevaluateDraft()

        if isLastStep || questions.isEmpty {
            if viewModel.evaluation?.isReadyForSubmission == true {
                Task { await viewModel.submitFinalDraft() }
            }
        } else {
            withAnimation {
                let newCount = viewModel.evaluation?.missingRequirements.count ?? questions.count
                currentIndex = min(safeIndex + 1, max(0, newCount - 1))
                resetAnswerState()
            }
        }
    }

    // MARK: - Persist & reset

    private func persistAnswer(for requirement: TripRequirement) {
        switch requirement {
        case .destination:
            viewModel.updateDestination(textAnswer)
        case .origin:
            viewModel.updateOrigin(textAnswer)
        case .travelDates:
            viewModel.updateTravelDates(departure: departureDate, returnDate: returnDate)
        case .travelerCount, .hasKids, .youngestTravelerAge:
            viewModel.updateTravelerCount(adultCount + childCount)
            viewModel.updateHasKids(childCount > 0)
            if childCount > 0 {
                viewModel.updateYoungestTravelerAge(childAge)
            }
        case .transportMode:
            viewModel.setTransportModes(flight: flightSelected, road: roadSelected, train: trainSelected)
        case .lodgingPreferences:
            viewModel.updateLodgingHotel(hotelSelected)
            viewModel.updateLodgingAirbnb(airbnbSelected)
        }
    }

    private func resetAnswerState() {
        textAnswer = ""
        adultCount = 2
        childCount = 0
        childAge = 3
        flightSelected = false
        roadSelected = false
        trainSelected = false
        hotelSelected = false
        airbnbSelected = false
    }

    // MARK: - Question copy

    private func questionTitle(for requirement: TripRequirement) -> String {
        switch requirement {
        case .origin:       return "Where are you flying from?"
        case .destination:  return "Where are you headed?"
        case .travelDates:  return "When works best?"
        case .travelerCount, .hasKids, .youngestTravelerAge:
            return "Who's traveling?"
        case .transportMode:
            return "How do you want to get there?"
        case .lodgingPreferences:
            return "Where should we stay?"
        }
    }

    private func questionSubtitle(for requirement: TripRequirement) -> String {
        switch requirement {
        case .origin:       return "We'll use this to find the best flight options."
        case .destination:  return "We'll build your itinerary around this."
        case .travelDates:  return "We can nudge dates ±3 days to save up to 40%."
        case .travelerCount, .hasKids, .youngestTravelerAge:
            return "We'll tailor activities for everyone."
        case .transportMode:
            return "Pick all that work for you."
        case .lodgingPreferences:
            return "Pick any that feel right."
        }
    }

    // MARK: - Final Result

    @ViewBuilder
    private func finalResultView(response: FinalTripResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: S.md) {
                Text(response.itinerary.title)
                    .font(T.headlineLG)
                    .foregroundColor(C.textPrimary)

                Text(response.itinerary.summary)
                    .font(T.body)
                    .foregroundColor(C.textSecondary)

                ForEach(Array(response.itinerary.days.enumerated()), id: \.offset) { index, day in
                    dayCard(day: day, dayNumber: index + 1)
                }

                if !response.flightOptions.isEmpty {
                    sectionHeader("Flights")
                    ForEach(Array(response.flightOptions.enumerated()), id: \.offset) { _, flight in
                        flightCard(flight: flight)
                    }
                }

                if !response.hotelOptions.isEmpty {
                    sectionHeader("Hotels")
                    ForEach(Array(response.hotelOptions.enumerated()), id: \.offset) { _, hotel in
                        hotelCard(hotel: hotel)
                    }
                }
            }
            .padding(.horizontal, S.md)
            .padding(.vertical, S.lg)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .semibold, design: .serif))
            .foregroundColor(C.textPrimary)
            .padding(.top, 8)
    }

    private func dayCard(day: TripDay, dayNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Day \(dayNumber)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(C.textPrimary)

            partOfDayView(label: "Morning", part: day.morning)
            partOfDayView(label: "Afternoon", part: day.afternoon)
            partOfDayView(label: "Evening", part: day.evening)
        }
        .padding(S.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                .fill(Color.white)
        )
    }

    private func partOfDayView(label: String, part: PartOfDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(C.textPrimary)

            if let foods = part.foodOptions, !foods.isEmpty {
                Text("Eat: \(foods.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(C.textSecondary)
            }

            if !part.placesToVisitDistance.isEmpty {
                ForEach(Array(part.placesToVisitDistance.keys.sorted()), id: \.self) { place in
                    let dist = part.placesToVisitDistance[place] ?? 0
                    Text("\(place) — \(String(format: "%.1f", dist)) km")
                        .font(.caption)
                        .foregroundColor(C.textPrimary)
                }
            }

            if part.includeNap {
                Text("Nap time scheduled")
                    .font(.caption)
                    .foregroundColor(C.tipIcon)
            }
        }
    }

    private func flightCard(flight: FlightOption) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(flight.airline)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if let price = flight.price {
                    Text("$\(price)")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            Text("\(flight.origin) → \(flight.destination)")
                .font(.caption)
            HStack {
                Text("Departs: \(flight.departureTime)")
                Spacer()
                Text("Returns: \(flight.returnTime)")
            }
            .font(.caption)
            .foregroundColor(C.textSecondary)

            if !flight.layovers.isEmpty {
                Text("Layovers: \(flight.layovers.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(C.textSecondary)
            }

            Text(flight.reason)
                .font(.caption2)
                .foregroundColor(C.textSecondary)
        }
        .padding(S.sm)
        .background(
            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                .fill(Color.white)
        )
    }

    private func hotelCard(hotel: HotelOption) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(String(format: "%.0f", hotel.price)) total")
                    .font(.system(size: 14, weight: .semibold))
                Text("\(hotel.numberOfDays) nights · \(hotel.numberOfRooms) room(s)")
                    .font(.caption)
                    .foregroundColor(C.textSecondary)
            }
            Spacer()
            Text("\(String(format: "%.1f", hotel.distanceFromAirport)) km from airport")
                .font(.caption)
                .foregroundColor(C.textSecondary)
        }
        .padding(S.sm)
        .background(
            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                .fill(Color.white)
        )
    }
}

// MARK: - FlowLayout (wrapping horizontal layout for chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview("Loaded with missing requirements") {
    let vm = TripDraftViewModel()
    vm.updateDestination("Paris")
    vm.updateOrigin("NYC")
    vm.updateTravelerCount(2)
    vm.updateLodgingHotel(true)
    vm.reevaluateDraft()

    return NavigationStack {
        FollowUpQuestionsView(viewModel: vm)
    }
}

