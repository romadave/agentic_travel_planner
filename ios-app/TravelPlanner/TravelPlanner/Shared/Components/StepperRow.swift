//
//  StepperRow.swift
//  TravelPlanner
//
//  Created by Roma Dave on 5/5/26.
//

import SwiftUI

/// A row with a leading avatar circle, label/subtitle, and –/+/count controls.
/// Matches the "Who's traveling?" design.
struct StepperRow: View {
    let label: String
    var subtitle: String? = nil
    var icon: String = "person.crop.circle"
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...20

    private typealias C = DesignTokens.Colors

    var body: some View {
        HStack(spacing: 14) {
            // Avatar circle
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(C.avatarFg)
                .frame(width: 44, height: 44)
                .background(Circle().fill(C.avatarBg))

            // Label + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(C.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(C.textSecondary)
                }
            }

            Spacer()

            // Minus / count / Plus
            HStack(spacing: 16) {
                Button {
                    if value > range.lowerBound { value -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(value <= range.lowerBound ? C.patternLine : C.textPrimary)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(C.patternLine, lineWidth: 1))
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.system(size: 18, weight: .medium).monospacedDigit())
                    .foregroundColor(C.textPrimary)
                    .frame(minWidth: 20)

                Button {
                    if value < range.upperBound { value += 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(value >= range.upperBound ? C.patternLine : C.textPrimary)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(C.textPrimary, lineWidth: 1))
                }
                .disabled(value >= range.upperBound)
            }
            .buttonStyle(.plain)
        }
    }
}
