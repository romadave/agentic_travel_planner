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
    @State private var travelingWithKids: Bool = false
    @State private var numberOfKids: Int = 1
    @State private var kidsAges: [Int] = [3]
    @State private var flightSelected = false
    @State private var roadSelected = false
    @State private var trainSelected = false
    @State private var hotelSelected = false
    @State private var airbnbSelected = false
    @State private var navigateToPlanning = false

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
                    .onAppear { print("[FollowUp] 👁️ Rendering .idle state") }

            case .loading:
                OrbitLoadingView(
                    topLabel: "ANALYZING...",
                    headline: "Reading",
                    subheadline: "your adventure.",
                    steps: buildAnalyzingSteps(from: viewModel.userPrompt)
                )
                .onAppear { print("[FollowUp] ⏳ Rendering .loading state") }

            case .loaded(let evaluation):
                loadedView(evaluation: evaluation)
                    .onAppear { print("[FollowUp] ✅ Rendering .loaded — missing: \(evaluation.missingRequirements.count), ready: \(evaluation.isReadyForSubmission)") }

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
        .onAppear { print("[FollowUp] 📍 FollowUpQuestionsView appeared — screen2State: \(viewModel.screen2State)") }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToPlanning) {
            PlanningLoadingView(draft: viewModel.tripDraft ?? TripRequestDraft())
        }
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
            VStack(alignment: .leading, spacing: 16) {
                // Departure date
                VStack(alignment: .leading, spacing: 6) {
                    Text("Departure")
                        .font(T.label)
                        .foregroundColor(C.accentTan)
                        .tracking(0.5)
                    DatePicker("", selection: $departureDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(C.buttonPrimary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                                .stroke(C.patternLine, lineWidth: 1)
                        )
                }

                Text("to")
                    .font(T.body)
                    .foregroundColor(C.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Return date
                VStack(alignment: .leading, spacing: 6) {
                    Text("Return")
                        .font(T.label)
                        .foregroundColor(C.accentTan)
                        .tracking(0.5)
                    DatePicker("", selection: $returnDate, in: departureDate..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(C.buttonPrimary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                                .stroke(C.patternLine, lineWidth: 1)
                        )
                }
            }

        case .adultCount, .hasKids:
            VStack(spacing: 0) {
                StepperRow(
                    label: "Adults",
                    subtitle: "Number of adults",
                    icon: "person.crop.circle",
                    value: $adultCount,
                    range: 1...20
                )
                .padding(.vertical, 14)

                Divider()

                // Kids toggle
                HStack {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 18))
                        .foregroundColor(C.accentTan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Traveling with kids?")
                            .font(T.bodyMedium)
                            .foregroundColor(C.textPrimary)
                    }
                    Spacer()
                    Toggle("", isOn: $travelingWithKids)
                        .labelsHidden()
                        .tint(C.buttonPrimary)
                }
                .padding(.vertical, 14)

                if travelingWithKids {
                    Divider()

                    // How many kids
                    StepperRow(
                        label: "Number of kids",
                        subtitle: "\(numberOfKids) kid\(numberOfKids == 1 ? "" : "s")",
                        icon: "figure.2.and.child.holdinghands",
                        value: Binding(
                            get: { numberOfKids },
                            set: { newCount in
                                let oldCount = numberOfKids
                                numberOfKids = newCount
                                if newCount > oldCount {
                                    // Append default age (3) for each new kid
                                    for _ in oldCount..<newCount {
                                        kidsAges.append(3)
                                    }
                                } else if newCount < oldCount {
                                    // Remove from the end
                                    kidsAges = Array(kidsAges.prefix(newCount))
                                }
                            }
                        ),
                        range: 1...10
                    )
                    .padding(.vertical, 14)

                    // Age stepper for each kid
                    ForEach(0..<numberOfKids, id: \.self) { index in
                        Divider()
                        StepperRow(
                            label: "Child \(index + 1) age",
                            subtitle: "\(kidsAges[index]) years old",
                            icon: "birthday.cake",
                            value: Binding(
                                get: { kidsAges[index] },
                                set: { kidsAges[index] = $0 }
                            ),
                            range: 0...17
                        )
                        .padding(.vertical, 14)
                    }
                }

                // Total travelers summary
                if travelingWithKids {
                    Divider()
                    HStack {
                        Image(systemName: "person.3")
                            .font(.system(size: 16))
                            .foregroundColor(C.textSecondary)
                        Text("Total travelers: \(adultCount + numberOfKids)")
                            .font(T.body)
                            .foregroundColor(C.textSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
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
            .animation(.easeInOut(duration: 0.25), value: travelingWithKids)
            .animation(.easeInOut(duration: 0.25), value: numberOfKids)

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
        let buttonTitle = isLastStep || questions.isEmpty ? "Build my itineraries" : "Next"
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
        if !skipPersist && !questions.isEmpty {
            persistAnswer(for: questions[safeIndex])
        }

        viewModel.reevaluateDraft()

        // After re-evaluation, check if we're actually done
        if viewModel.evaluation?.isReadyForSubmission == true {
            navigateToPlanning = true
            return
        }

        // Not done — advance to the next missing question
        let newQuestions = viewModel.evaluation?.missingRequirements ?? []
        if !newQuestions.isEmpty {
            withAnimation {
                currentIndex = 0
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
        case .adultCount, .hasKids:
            viewModel.updateAdultCount(adultCount)
            viewModel.updateHasKids(travelingWithKids)
            if travelingWithKids {
                viewModel.updateKidsAges(kidsAges)
            } else {
                viewModel.updateKidsAges(nil)
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
        travelingWithKids = false
        numberOfKids = 1
        kidsAges = [3]
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
        case .adultCount, .hasKids:
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
        case .adultCount, .hasKids:
            return "We'll tailor activities for everyone."
        case .transportMode:
            return "Pick all that work for you."
        case .lodgingPreferences:
            return "Pick any that feel right."
        }
    }

    // MARK: - Analyzing steps (personalized from prompt)

    private func buildAnalyzingSteps(from prompt: String) -> [String] {
        let destination = extractDestination(from: prompt)

        var steps = ["Understanding your request..."]

        if let dest = destination {
            steps.append("Packing our bags for \(dest)...")
        } else {
            steps.append("Sounds like a fun getaway!")
        }

        steps.append("Picking out the best spots...")
        steps.append("Almost ready...")

        return steps
    }

    /// Simple client-side extraction: looks for a capitalized word
    /// after common travel prepositions (to, in, from).
    private func extractDestination(from prompt: String) -> String? {
        let pattern = #"(?:to|in|from)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)),
              let range = Range(match.range(at: 1), in: prompt) else {
            return nil
        }
        return String(prompt[range])
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
    vm.updateAdultCount(2)
    vm.updateLodgingHotel(true)
    vm.reevaluateDraft()

    return NavigationStack {
        FollowUpQuestionsView(viewModel: vm)
    }
}

