//
//  PrimaryButton.swift
//  TravelPlanner
//
//  Created by Roma Dave on 3/16/26.
//

import SwiftUI

struct PrimaryButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let buttonClicked: Bool
    let backgroundColor: Color
    let icon: String?
    
    private static var defaultColor: Color {
        DesignTokens.Colors.buttonPrimary
    }
    
    init(
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        buttonClicked: Bool,
        backgroundColor: Color? = nil,
        icon: String? = nil
    ) {
        self.action = action
        self.content = content()
        self.buttonClicked = buttonClicked
        self.backgroundColor = backgroundColor ?? Self.defaultColor
        self.icon = icon
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                content
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(.white)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(buttonClicked)
    }
}

