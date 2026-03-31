//
//  Screen1View.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/16/26.
//

import SwiftUI

struct Screen1View: View {
    // Holds the user's freeform trip description typed into the TextEditor.
    // Using @State so the view updates as the user types.
    @StateObject private var viewModel = TripDraftViewModel()
    @State private var showError = false
    @State private var goToScreen2 = false
    
    var body: some View {
        ZStack {
            // Solid background color for the whole screen.
            // Using a ZStack lets the background sit behind all content.
            Color(red: 248/255, green:243/255, blue:248/255)
                // Extend color behind safe areas (e.g., under the notch/home indicator)
                // while keeping actual content padded as needed elsewhere.
                .ignoresSafeArea()
            
            VStack {
                // Adds some initial top breathing room before the main card.
                Spacer(minLength: 30)
                
                mainCard
                
                // Pushes the card upward slightly and keeps bottom area airy.
                Spacer()
            }
            // Horizontal margin between the card and the screen edges.
            // Prefer outer padding on the container to keep a consistent screen margin.
            .padding(.horizontal,20)
        }
    }
    
    // MARK: - Main Card
    // A tall, rounded rectangle container with sections inside.
    private var mainCard: some View {
        VStack (spacing: 0) {
            // spacing: 0 means no uniform gaps between these children.
            // We’ll control spacing precisely with targeted paddings on each section.
            headerSection
            
            // Extra space above the prompt area for visual hierarchy.
            promptSection.padding(.top, 36)
            
            // Spacer creates flexible empty space.
            // Here it pushes the button and voice section toward the bottom of the card,
            // giving the upper content more breathing room.
            Spacer(minLength: 120)
            
            // Custom PrimaryButton stretches horizontally (maxWidth: .infinity inside it).
            // We add horizontal padding so it aligns with the card’s inner margins.
            PrimaryButton(
                action: {
                    guard viewModel.validatePrompt() else {
                        showError = true
                        return
                    }
                    viewModel.screen2State = .loading
                    goToScreen2 = true
                    Task {
                        await viewModel.submitPrompt()
                    }
                },
                content: {
                    Text("Start Planning")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                },
                buttonClicked: viewModel.screen2State == .loading || goToScreen2
            )
            .padding(.horizontal, 28)
            
            NavigationLink (destination: FollowUpQuestionsView(viewModel: viewModel), isActive: $goToScreen2) {
                EmptyView()
            }
            
            // A divider to separate the button from the voice prompt affordance.
            Divider()
                .padding(.horizontal, 28) // Align divider with button edges for a clean column
                .padding(.top, 24)        // Breathing room above the divider
            
            if showError {
                Text("Please enter a trip prompt.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // A tappable-looking voice prompt hint area.
            voiceSection
                .padding(.top, 18)
                .padding(.bottom, 28) // Space at the bottom of the card
        }
        .frame(maxWidth: .infinity) // Let the card expand to fill horizontally within its parent
        .frame(height: 700)         // Fixed card height for a consistent “sheet” appearance
        // Alternative: consider .frame(minHeight: 600) if you want flexibility on larger screens.
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(red: 244/255, green: 236/255, blue: 247/255))
        )
        .shadow(color: Color.purple.opacity(0.08), radius: 20, x: 0, y: 8)
    }

    // MARK: - Header
    // Title and subtitle at the top of the card.
    private var headerSection : some View {
        VStack(spacing:16) {
            Text("AI Travel\n Planner")
                // Rounded design for a friendly, approachable feel.
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(Color.purple.opacity(0.95))
                .padding(.top, 56) // Push title down from the card’s top edge
            
            Text("Plan unforgettable trips\nwith an AI travel assistant")
                .font(.system(size: 16, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(Color.black.opacity(0.65))
                .lineSpacing(4) // Improve readability with extra line spacing
        }
        // Keep the header text away from card edges.
        .padding(.horizontal,20)
    }

    // MARK: - Prompt Section
    // Label + TextEditor with a custom placeholder.
    private var promptSection: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10){
                Text("Where would you like to go?")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.6))
                
                promptEditor
            }
            // Inner padding gives the section comfortable margins inside the card.
            .padding(.horizontal,16)
            .padding(.vertical, 16)
            // This wrapper gives the prompt area a subtle card-within-card feel.
            .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.purple.opacity(0.10), lineWidth: 1)
            )
        }
        // Align the prompt section’s outer edge with other card content (button/divider).
        .padding(.horizontal, 20)
    }
    
    // MARK: - Prompt Editor
    private var promptEditor : some View {
        ZStack(alignment: .topLeading) {
            // TextEditor expands vertically based on frame constraints.
            // We keep the style plain for a minimal look.
            TextEditor(text: $viewModel.userPrompt)
                .font(.system(size: 17))
                .textFieldStyle(.plain)
                // Tiny horizontal padding so text doesn’t touch the border.
                .padding(.horizontal, 4)
                // Provide a reasonable minimum height for multi-line input.
                .frame(minHeight: 140)
            
            // Manual placeholder: shown only when tripPrompt is empty.
            // ZStack with alignment lets us place it at the top-left.
            if viewModel.userPrompt.isEmpty {
                Text("Or describe your trip")
                    .font(.system(size: 17))
                    .foregroundColor(Color.black.opacity(0.3))
                    .padding(.top, 8)
                    .padding(.leading, 8)
                    // Prevents capturing taps; lets the TextEditor receive focus.
                    .allowsHitTesting(false)
            }
        }
        // White field background with subtle border to resemble an input.
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1))
        )
    }
    
    // MARK: - Voice Section
    // A compact row suggesting voice input as an alternative.
    private var voiceSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "mic.fill")
                .font(.system(size: 18))
                .foregroundColor(Color.purple.opacity(0.5))

            Text("Or speak your trip")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color.purple.opacity(0.65))
        }
        // If you later want this tappable, wrap HStack in a Button and keep spacing/padding.
    }
}

#Preview {
    Screen1View()
}
