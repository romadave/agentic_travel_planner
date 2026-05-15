//
//  Screen1View.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/16/26.
//

import SwiftUI

struct Screen1View: View {
    @StateObject private var viewModel = TripDraftViewModel()
    @State private var showError = false
    @State private var goToScreen2 = false

    private typealias Tokens = DesignTokens
    private typealias C = Tokens.Colors
    private typealias T = Tokens.Typography
    private typealias S = Tokens.Spacing
    private typealias R = Tokens.Radii

    private let suggestions = [
        "Weekend in Lisbon with kids",
        "10 days in Japan",
        "Travel to switzerland"
    ]

    var body: some View {
        ZStack {
            C.screenBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    mainCard
                        .padding(.top, S.md)
                }
                .padding(.horizontal, S.md)
            }
        }
        .navigationDestination(isPresented: $goToScreen2) {
            FollowUpQuestionsView(viewModel: viewModel)
        }
        .onChange(of: goToScreen2) { _, isPresented in
            if !isPresented {
                // Only fires when user navigates *back* to Screen1
                print("[Screen1] goToScreen2 became false — resetting state")
                viewModel.screen2State = .idle
            }
        }
    }

    // MARK: - Main Card
    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            decorativePattern
                .padding(.top, S.lg)
            promptSection
                .padding(.top, S.lg)
            suggestionsSection
                .padding(.top, S.md)
        }
        .padding(S.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: R.card, style: .continuous)
                .fill(C.cardBg)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 8)
    }

    // MARK: - Section 1: Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: S.sm) {
            Text("Plan\n\(Text("somewhere").font(T.headlineXLBold).italic())\nnew.")
                .font(T.headlineXL)
                .foregroundColor(C.textPrimary)
                .lineSpacing(2)

            Text("Tell us in a sentence. We'll sketch three itineraries, pick flights, find stays. You tweak until it's yours.")
                .font(T.body)
                .foregroundColor(C.textSecondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Section 2: Decorative Pattern
    private var decorativePattern: some View {
        ZStack(alignment: .bottomLeading) {
            Canvas { context, size in
                let spacing: CGFloat = 12
                var path = Path()
                var x: CGFloat = -size.height
                while x < size.width + size.height {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    x += spacing
                }
                x = 0
                while x < size.width + size.height {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x - size.height, y: size.height))
                    x += spacing
                }
                context.stroke(path, with: .color(C.patternLine), lineWidth: 0.8)
            }
            .frame(height: 140)
            .background(C.patternBg)
            .clipShape(RoundedRectangle(cornerRadius: R.inner, style: .continuous))

            Text("COASTAL VILLAGE  ·  SUMMER")
                .font(T.captionSm)
                .tracking(1.2)
                .foregroundColor(C.accentTan)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Section 3: Prompt + Button
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where do you want to go?")
                .font(T.label)
                .foregroundColor(C.accentTan)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 12) {
                StyledTextField(
                    text: $viewModel.userPrompt,
                    hint: "I want to go to...",
                    multiline: true,
                    minHeight: 60,
                    isDisabled: goToScreen2
                )

                if showError {
                    Text("Please enter a trip description.")
                        .foregroundColor(.red)
                        .font(.caption)
                }

                HStack {
                    HStack(spacing: S.xs) {
                        ForEach(["square.grid.2x2", "sparkles", "arrow.triangle.swap"], id: \.self) { icon in
                            Image(systemName: icon)
                                .font(T.icon)
                                .foregroundColor(C.accentTan)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(C.iconBg)
                                )
                        }
                    }

                    Spacer()

                    PrimaryButton(
                        action: {
                            print("[Screen1] 🔘 Start Planning tapped")
                            guard viewModel.validatePrompt() else {
                                print("[Screen1] ❌ Validation failed — prompt is empty")
                                showError = true
                                return
                            }
                            print("[Screen1] ✅ Prompt validated: \(viewModel.userPrompt)")
                            showError = false
                            viewModel.screen2State = .loading
                            print("[Screen1] screen2State -> .loading")
                            goToScreen2 = true
                            print("[Screen1] goToScreen2 -> true (navigation should fire)")
                            Task {
                                await viewModel.submitPrompt()
                            }
                        },
                        content: {
                            Text("Start planning")
                                .font(T.bodyMedium)
                        },
                        buttonClicked: viewModel.screen2State == .loading || goToScreen2,
                        icon: "arrow.right"
                    )
                    .frame(width: 160)
                }
            }
            .padding(S.sm)
            .background(
                RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                    .fill(C.inputBg)
            )


        }
    }

    // MARK: - Section 4: Suggestions
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    viewModel.userPrompt = suggestion
                } label: {
                    HStack {
                        Text(suggestion)
                            .font(T.suggestion)
                            .foregroundColor(C.textSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)

                if suggestion != suggestions.last {
                    Divider()
                        .foregroundColor(Color.black.opacity(0.06))
                }
            }
        }
    }
}

#Preview("Default") {
    NavigationStack {
        Screen1View()
    }
}
