//
//  StyledTextField.swift
//  TravelPlanner
//
//  Created by Roma Dave on 5/5/26.
//

import SwiftUI

/// A reusable text input that supports single-line (TextField) and
/// multiline (TextEditor) modes with optional leading icon and placeholder.
struct StyledTextField: View {
    @Binding var text: String
    var hint: String = ""
    var icon: String? = nil
    var multiline: Bool = false
    var minHeight: CGFloat = 48

    private typealias C = DesignTokens.Colors
    private typealias T = DesignTokens.Typography
    private typealias R = DesignTokens.Radii

    var body: some View {
        HStack(alignment: multiline ? .top : .center, spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(T.icon)
                    .foregroundColor(C.accentTan)
                    .padding(.top, multiline ? 14 : 0)
            }

            ZStack(alignment: .topLeading) {
                if multiline {
                    TextEditor(text: $text)
                        .font(T.userInput)
                        .foregroundColor(C.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: minHeight)
                } else {
                    TextField("", text: $text)
                        .font(T.userInput)
                        .foregroundColor(C.textPrimary)
                        .frame(minHeight: minHeight)
                }

                if text.isEmpty && !hint.isEmpty {
                    Text(hint)
                        .font(T.userInput)
                        .foregroundColor(C.placeholder)
                        .padding(.top, multiline ? 8 : 0)
                        .padding(.leading, multiline ? 5 : 0)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, multiline ? 4 : 0)
        .background(
            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                .stroke(C.patternLine, lineWidth: 1)
        )
    }
}
