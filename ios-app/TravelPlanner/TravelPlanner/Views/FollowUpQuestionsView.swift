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

        if questions.isEmpty {
            VStack(spacing: 16) {
                Text("We have enough information to continue.")
                    .foregroundStyle(.secondary)
                Button(viewModel.evaluation?.isReadyForSubmission == true ? "Submit Trip" : "Get Plan") {
                    if viewModel.evaluation?.isReadyForSubmission == true {
                        // TODO: Call final submission endpoint
                    } else {
                        // Fallback: still call reevaluate to ensure state is fresh
                        viewModel.reevaluateDraft()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            VStack(alignment: .leading, spacing: 20) {
                ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
                Text("Question \(currentIndex + 1) of \(questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ZStack {
                    // Only render the active question
                    singleQuestionView(for: questions[currentIndex])
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(questions[currentIndex].rawValue)
                }
                .animation(.easeInOut, value: currentIndex)

                HStack {
                    if currentIndex > 0 {
                        Button("Back") { withAnimation { currentIndex -= 1 } }
                    }
                    Spacer()
                    if currentIndex < questions.count - 1 || viewModel.evaluation?.isReadyForSubmission == false {
                        Button("Next") {
                            persistAnswer(for: questions[currentIndex])
                            viewModel.reevaluateDraft()
                            withAnimation {
                                // Clamp currentIndex to new questions count if it shrank
                                let newCount = viewModel.evaluation?.missingRequirements.count ?? questions.count
                                currentIndex = min(currentIndex + 1, max(0, newCount - 1))
                                // Reset local inputs for next question
                                textAnswer = ""
                                boolAnswer = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Get Plan") {
                            persistAnswer(for: questions[currentIndex])
                            viewModel.reevaluateDraft()
                            // If ready, proceed to final submission flow; else the UI will reflect updated questions
                            if viewModel.evaluation?.isReadyForSubmission == true {
                                // TODO: Call your final submission endpoint when implemented
                                // For now, keep the state as loaded with the latest evaluation
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
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
            case .destination, .origin, .travelerCount, .youngestTravelerAge, .transportMode, .lodgingPreferences:
                TextField("Type your answer", text: $textAnswer)
                    .textFieldStyle(.roundedBorder)
            case .hasKids:
                Toggle("Traveling with kids", isOn: $boolAnswer)
                
            case .travelDates:
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker("Departure", selection: $departureDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("Return", selection: Binding(
                        get: { max(returnDate, departureDate) },
                        set: { newValue in
                            // Ensure return is not before departure
                            returnDate = max(newValue, departureDate)
                        }
                    ), in: departureDate..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                }
            }
        }
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
            if let count = Int(textAnswer.trimmingCharacters(in: .whitespacesAndNewlines)) {
                viewModel.updateTravelerCount(count)
            }
        case .hasKids:
            viewModel.updateHasKids(boolAnswer)
        case .youngestTravelerAge:
            if let age = Int(textAnswer.trimmingCharacters(in: .whitespacesAndNewlines)) {
                viewModel.updateYoungestTravelerAge(age)
            }
        case .transportMode:
            viewModel.updateTransportMode(textAnswer)
            
        case .lodgingPreferences:
            viewModel.updateLodging(textAnswer)
        }
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
            return "How would you like to travel? (Flight, road, or train)"
        case .lodgingPreferences:
            return "Where would you like to stay? (Hotel, airbnb)?"
        }
    }
    
}

