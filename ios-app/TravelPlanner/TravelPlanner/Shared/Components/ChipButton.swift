//
//  ChipButton.swift
//  TravelPlanner
//
//  Created by Roma Dave on 5/5/26.
//

import SwiftUI

/// A pill-shaped toggle chip with optional leading SF Symbol.
/// Selected = dark fill + white text; unselected = white fill + dark text + border.
struct ChipButton: View {
    let title: String
    var icon: String? = nil
    @Binding var isSelected: Bool

    private typealias C = DesignTokens.Colors
    private typealias R = DesignTokens.Radii

    var body: some View {
        Button {
            isSelected.toggle()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? C.chipSelectedFg : C.chipUnselectedFg)
            .background(
                Capsule()
                    .fill(isSelected ? C.chipSelectedBg : C.chipUnselectedBg)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : C.chipBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
