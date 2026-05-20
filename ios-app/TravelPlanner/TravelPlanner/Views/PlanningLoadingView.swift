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

    @State private var errorMessage: String? = nil
    @State private var itinerariesReceived: Bool = false
    
    // maintaining state in the parent widget
    @State private var currentStepIndex: Int = 0
    
    @StateObject private var tripResultViewModel : TripResultViewModel = TripResultViewModel()

    private let apiService = TripAPIService()

    var body: some View {
        ZStack {
            C.screenBg.ignoresSafeArea()

            if let error = errorMessage {
                errorView(error)
            } else {
                OrbitLoadingView(
                    topLabel: "PLANNING...",
                    headline: "Dreaming up",
                    subheadline: "your \(seasonWord).",
                    steps: buildSteps(from: draft),
                    externalStepIndex: $currentStepIndex // passing down the state and is used as binding
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $itinerariesReceived) {
            ItinerariesView(resultVM: tripResultViewModel, draft: draft)
        }
        .onAppear {
            fetchTrip()
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(C.tipIcon)

            Text("Something went wrong")
                .font(T.headlineLG)
                .foregroundColor(C.textPrimary)

            Text(message)
                .font(T.body)
                .foregroundColor(C.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, S.lg)

            Button {
                errorMessage = nil
                fetchTrip()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, S.lg)
                .padding(.vertical, 14)
                .background(C.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radii.pill))
            }

            Spacer()
        }
    }

    // MARK: - API Call

    private func fetchTrip() {
        Task {
            do {
                let response = apiService.streamFinalDraft(draft)
                for try await event in response {
                    switch event {
                    case .destinationInfo(let info):
                        print("[Stream] Got destinationInfo: \(info.country)")
                        tripResultViewModel.destinationInfo = info
                        currentStepIndex += 1
                        
                    case .itineraries(let options):
                        print("[Stream] Got \(options.count) itineraries")
                        tripResultViewModel.itineraryOptions = options
                        currentStepIndex += 1
                        itinerariesReceived = true
                        
                    case .flights(let flightOptions):
                        print("[Stream] Got \(flightOptions.count) flights")
                        tripResultViewModel.flights = flightOptions
                        currentStepIndex += 1
                        tripResultViewModel.isLoadingFlights = false
                        
                    case .hotels(let options):
                        print("[Stream] Got hotels for \(options.count) itineraries")
                        tripResultViewModel.itineraryOptions = options
                        currentStepIndex += 1
                        tripResultViewModel.isLoadingHotels = false
                    
                    case .done:
                        print("[Stream] Done")
                        break
                    
                    case .error(let error):
                        print("[Stream] Server error: \(error)")
                        errorMessage = error
                    }
                }
                print("[Stream] Stream ended normally")
            } catch {
                print("[Stream] Stream threw error: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Contextual Steps Builder

    private func buildSteps(from draft: TripRequestDraft) -> [String] {
        var result: [String] = []

        result.append("Reading your request...")

        let dest = draft.route.destination
        if !dest.isEmpty {
            result.append("Scanning \(dest) destinations...")
        } else {
            result.append("Scanning destinations...")
        }

        if draft.travelerInfo.hasKids == true {
            if let age = draft.travelerInfo.youngestTravelerAge, age <= 5 {
                result.append("Filtering for toddler-friendly...")
            } else {
                result.append("Filtering for family-friendly...")
            }
        } else {
            result.append("Curating top experiences...")
        }

        let origin = draft.route.origin
        if draft.transportPreferences.flightSelected == true && !origin.isEmpty {
            result.append("Pricing flights from \(origin)...")
        } else if draft.transportPreferences.flightSelected == true {
            result.append("Pricing flight options...")
        } else {
            result.append("Finding transport options...")
        }

        if draft.lodgingPreferences.hotel == true && draft.lodgingPreferences.isFamilyFriendly == true {
            result.append("Matching stays with cribs & kitchens...")
        } else if draft.lodgingPreferences.hotel == true {
            result.append("Finding the best hotel deals...")
        } else if draft.lodgingPreferences.airbnb == true {
            result.append("Browsing top-rated rentals...")
        } else {
            result.append("Finding places to stay...")
        }

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
