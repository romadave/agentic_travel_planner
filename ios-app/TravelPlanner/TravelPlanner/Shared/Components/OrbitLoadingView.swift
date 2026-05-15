//
//  OrbitLoadingView.swift
//  TravelPlanner
//
//  Reusable loading screen with orbit spinner animation and step checklist.
//

import SwiftUI

struct OrbitLoadingView: View {
    let topLabel: String
    let headline: String
    let subheadline: String
    let steps: [String]

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias S = DesignTokens.Spacing

    @State private var currentStepIndex: Int = 0
    @State private var orbitAngle: Double = 0
    @State private var pulseScale: Double = 1.0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(topLabel)
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(C.textSecondary)
            }
            .padding(.horizontal, S.md)
            .padding(.top, 12)

            Spacer()

            spinnerView
                .padding(.bottom, 40)

            headlineView
                .padding(.horizontal, S.md)

            Spacer()

            stepChecklist
                .padding(.horizontal, S.md)
                .padding(.bottom, S.lg)
        }
        .onAppear {
            startOrbitAnimation()
            startStepProgression()
        }
    }

    // MARK: - Spinner

    private var spinnerView: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                .frame(width: 120, height: 120)
                .foregroundColor(C.patternLine)

            orbitDot(offset: 0, color: C.tipIcon, size: 8)
            orbitDot(offset: .pi * 0.6, color: C.textSecondary.opacity(0.5), size: 6)
            orbitDot(offset: .pi * 1.2, color: C.textSecondary.opacity(0.3), size: 5)

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
            Text(headline)
                .font(T.headlineLG)
                .foregroundColor(C.textPrimary)

            Text(subheadline)
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
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(C.tipIcon)
        } else if index == currentStepIndex {
            Circle()
                .fill(C.textPrimary)
                .frame(width: 8, height: 8)
        } else {
            Circle()
                .fill(C.patternLine)
                .frame(width: 8, height: 8)
        }
    }

    private func stepTextColor(for index: Int) -> Color {
        index <= currentStepIndex ? C.textPrimary : C.textSecondary.opacity(0.5)
    }

    private func stepOpacity(for index: Int) -> Double {
        if index <= currentStepIndex { return 1.0 }
        if index == currentStepIndex + 1 { return 0.5 }
        return 0.3
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
}
