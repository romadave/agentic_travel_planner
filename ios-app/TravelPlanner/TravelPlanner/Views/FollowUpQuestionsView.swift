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
            VStack(alignment: .leading, spacing: 16) {
                Text("Here’s what I still need")
                    .font(.title3.weight(.semibold))

                if evaluation.missingRequirements.isEmpty {
                    Text("We have enough information to continue.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(evaluation.missingRequirements, id: \.rawValue) { requirement in
                        Text("• \(questionText(for: requirement))")
                    }
                }
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
        }
    }
}
