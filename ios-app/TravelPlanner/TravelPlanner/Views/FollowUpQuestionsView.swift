//
//  Screen2View.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/18/26.
//
import SwiftUI

struct FollowUpQuestionsView : View {
    @ObservedObject var viewModel: TripDraftViewModel
    @State private var isLoading = true
    //tracks current Index
    @State private var currentIndex: Int = 0
    @State private var textAnswer: String = ""
    @State private var boolAnswer: Bool = false
    @State private var departureDate: Date = .now
    @State private var returnDate: Date = .now
    @State private var travelerCount: Int = 1
    @State private var youngestAge: Int = 5
    @State private var flightSelected: Bool = false
    @State private var roadSelected: Bool = false
    @State private var trainSelected: Bool = false
    @State private var hotelSelected: Bool = false
    @State private var airbnbSelected: Bool = false
    
    var body : some View {
        VStack {
            switch viewModel.screen2State {
            case .idle:
                Text("Ready to plan your trip.")
                                    .font(.headline)
            case .loading:
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Analyzing your trip request...")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .loaded(let tripEvaluation):
                loadedView(evaluation: tripEvaluation)
            
            case .submittingFinal:
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Building your trip plan...")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            case .finalResult(let response):
                finalResultView(response: response)
            
            case .failed(let errorMessage):
                VStack(alignment: .leading, spacing: 12) {
                    Text("Something went wrong")
                        .font(.headline)
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        Task {
                            await viewModel.submitPrompt()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .navigationTitle("Planning")
    }
    
    @ViewBuilder
        private func loadedView(evaluation: TripEvaluation) -> some View {
            stepperView(evaluation: evaluation)
        }
    
    @ViewBuilder
    private func stepperView(evaluation: TripEvaluation) -> some View {
        let questions = evaluation.missingRequirements
        // Clamp index to valid range to prevent out-of-bounds crash
        let safeIndex = questions.isEmpty ? 0 : min(currentIndex, questions.count - 1)

        if questions.isEmpty {
            VStack(spacing: 16) {
                Text("We have enough information to continue.")
                    .foregroundStyle(.secondary)
                Button(viewModel.evaluation?.isReadyForSubmission == true ? "Submit Trip" : "Get Plan") {
                    if viewModel.evaluation?.isReadyForSubmission == true {
                        Task { await viewModel.submitFinalDraft() }
                    } else {
                        viewModel.reevaluateDraft()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            VStack(alignment: .leading, spacing: 20) {
                ProgressView(value: Double(safeIndex + 1), total: Double(questions.count))
                Text("Question \(safeIndex + 1) of \(questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ZStack {
                    singleQuestionView(for: questions[safeIndex])
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(questions[safeIndex].rawValue)
                }
                .animation(.easeInOut, value: safeIndex)

                HStack {
                    if safeIndex > 0 {
                        Button("Back") { withAnimation { currentIndex = safeIndex - 1 } }
                    }
                    Spacer()
                    if safeIndex < questions.count - 1 || viewModel.evaluation?.isReadyForSubmission == false {
                        Button("Next") {
                            persistAnswer(for: questions[safeIndex])
                            viewModel.reevaluateDraft()
                            withAnimation {
                                let newCount = viewModel.evaluation?.missingRequirements.count ?? questions.count
                                currentIndex = min(safeIndex + 1, max(0, newCount - 1))
                                resetAnswerState()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Get Plan") {
                            persistAnswer(for: questions[safeIndex])
                            viewModel.reevaluateDraft()
                            if viewModel.evaluation?.isReadyForSubmission == true {
                                Task { await viewModel.submitFinalDraft() }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .onAppear {
                // Sync currentIndex if it drifted out of range
                if currentIndex >= questions.count {
                    currentIndex = max(0, questions.count - 1)
                }
            }
        }
    }
    
    @ViewBuilder
    private func singleQuestionView(for requirement: TripRequirement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(questionText(for: requirement))
                .font(.title3.weight(.semibold))

            switch requirement {
            case .destination, .origin:
                TextField("Type your answer", text: $textAnswer)
                    .textFieldStyle(.roundedBorder)

            case .travelerCount:
                Stepper("Travelers: \(travelerCount)", value: $travelerCount, in: 1...20)

            case .youngestTravelerAge:
                Stepper("Age: \(youngestAge)", value: $youngestAge, in: 1...17)

            case .hasKids:
                Toggle("Traveling with kids", isOn: $boolAnswer)

            case .travelDates:
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker("Departure", selection: $departureDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("Return", selection: Binding(
                        get: { max(returnDate, departureDate) },
                        set: { newValue in
                            returnDate = max(newValue, departureDate)
                        }
                    ), in: departureDate..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                }

            case .transportMode:
                HStack(spacing: 12) {
                    toggleButton(title: "Flight", isSelected: $flightSelected)
                    toggleButton(title: "Road", isSelected: $roadSelected)
                    toggleButton(title: "Train", isSelected: $trainSelected)
                }

            case .lodgingPreferences:
                HStack(spacing: 12) {
                    toggleButton(title: "Hotel", isSelected: $hotelSelected)
                    toggleButton(title: "Airbnb", isSelected: $airbnbSelected)
                }
            }
        }
    }

    @ViewBuilder
    private func toggleButton(title: String, isSelected: Binding<Bool>) -> some View {
        Button {
            isSelected.wrappedValue.toggle()
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected.wrappedValue ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected.wrappedValue ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Final Result
    @ViewBuilder
    private func finalResultView(response: FinalTripResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Itinerary header
                Text(response.itinerary.title)
                    .font(.title2.weight(.bold))
                
                Text(response.itinerary.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                // Day-by-day breakdown
                ForEach(Array(response.itinerary.days.enumerated()), id: \.offset) { index, day in
                    dayCard(day: day, dayNumber: index + 1)
                }
                
                // Flight options
                if !response.flightOptions.isEmpty {
                    sectionHeader("Flights")
                    ForEach(Array(response.flightOptions.enumerated()), id: \.offset) { _, flight in
                        flightCard(flight: flight)
                    }
                }
                
                // Hotel options
                if !response.hotelOptions.isEmpty {
                    sectionHeader("Hotels")
                    ForEach(Array(response.hotelOptions.enumerated()), id: \.offset) { _, hotel in
                        hotelCard(hotel: hotel)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .padding(.top, 8)
    }
    
    private func dayCard(day: TripDay, dayNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Day \(dayNumber)")
                .font(.headline)
            
            partOfDayView(label: "Morning", part: day.morning)
            partOfDayView(label: "Afternoon", part: day.afternoon)
            partOfDayView(label: "Evening", part: day.evening)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    private func partOfDayView(label: String, part: PartOfDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.weight(.semibold))
            
            if let foods = part.foodOptions, !foods.isEmpty {
                Text("Eat: \(foods.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !part.placesToVisitDistance.isEmpty {
                ForEach(Array(part.placesToVisitDistance.keys.sorted()), id: \.self) { place in
                    let dist = part.placesToVisitDistance[place] ?? 0
                    Text("\(place) — \(String(format: "%.1f", dist)) km")
                        .font(.caption)
                }
            }
            
            if part.includeNap {
                Text("Nap time scheduled")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
    
    private func flightCard(flight: FlightOption) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(flight.airline)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let price = flight.price {
                    Text("$\(price)")
                        .font(.subheadline.weight(.bold))
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
            .foregroundStyle(.secondary)
            
            if !flight.layovers.isEmpty {
                Text("Layovers: \(flight.layovers.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(flight.reason)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    private func hotelCard(hotel: HotelOption) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(String(format: "%.0f", hotel.price)) total")
                    .font(.subheadline.weight(.semibold))
                Text("\(hotel.numberOfDays) nights · \(hotel.numberOfRooms) room(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(String(format: "%.1f", hotel.distanceFromAirport)) km from airport")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
    
    private func persistAnswer(for requirement: TripRequirement) {
        switch requirement {
        case .destination:
            viewModel.updateDestination(textAnswer)
        case .origin:
            viewModel.updateOrigin(textAnswer)
        case .travelDates:
            viewModel.updateTravelDates(departure: departureDate, returnDate: returnDate)
        case .travelerCount:
            viewModel.updateTravelerCount(travelerCount)
        case .hasKids:
            viewModel.updateHasKids(boolAnswer)
        case .youngestTravelerAge:
            viewModel.updateYoungestTravelerAge(youngestAge)
        case .transportMode:
            viewModel.setTransportModes(flight: flightSelected, road: roadSelected, train: trainSelected)
        case .lodgingPreferences:
            viewModel.updateLodgingHotel(hotelSelected)
            viewModel.updateLodgingAirbnb(airbnbSelected)
        }
    }
    
    private func resetAnswerState() {
        textAnswer = ""
        boolAnswer = false
        travelerCount = 1
        youngestAge = 5
        flightSelected = false
        roadSelected = false
        trainSelected = false
        hotelSelected = false
        airbnbSelected = false
    }

    private func questionText(for requirement: TripRequirement) -> String {
        switch requirement {
        case .destination:
            return "Where are you traveling to?"
        case .origin:
            return "Where are you traveling from?"
        case .travelDates:
            return "What are your travel dates?"
        case .travelerCount:
            return "How many travelers are going?"
        case .hasKids:
            return "Are you traveling with kids?"
        case .youngestTravelerAge:
            return "How old is the youngest traveler?"
        case .transportMode:
            return "How would you like to travel?"
        case .lodgingPreferences:
            return "Where would you like to stay?"
        }
    }
    
}

#Preview("Loaded with missing requirements") {
    let vm = TripDraftViewModel()
    // Seed draft with partial data to trigger follow-up questions
    vm.updateDestination("Paris")
    vm.updateOrigin("NYC")
    vm.updateDepartureDate(Date().addingTimeInterval(60 * 60 * 24 * 30)) // 30 days out
    vm.updateReturnDate(Date().addingTimeInterval(60 * 60 * 24 * 37))    // 37 days out
    vm.updateTravelerCount(2)
    vm.updateLodgingHotel(true)
    // Don't set hasKids or transport mode to force missing requirements
    vm.reevaluateDraft()

    return FollowUpQuestionsView(viewModel: vm)
}

