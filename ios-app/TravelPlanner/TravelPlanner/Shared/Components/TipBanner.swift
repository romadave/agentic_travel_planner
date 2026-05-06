//
//  TipBanner.swift
//  TravelPlanner
//
//  Created by Roma Dave on 5/5/26.
//

import SwiftUI

/// A tinted banner with a leading icon and message text.
/// Used for contextual suggestions (e.g. "With a 3-year-old, we suggest Balanced…").
struct TipBanner: View {
    let icon: String
    let message: String

    private typealias C = DesignTokens.Colors
    private typealias R = DesignTokens.Radii

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(C.tipIcon)
                .padding(.top, 2)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(C.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: R.inner, style: .continuous)
                .fill(C.tipBg)
        )
    }
}
