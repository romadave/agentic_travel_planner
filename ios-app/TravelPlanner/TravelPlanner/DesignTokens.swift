//
//  designTokens.swift
//  TravelPlanner
//
//  Created by Roma Dave on 5/5/26.
//
import SwiftUI

struct DesignTokens {

    // MARK: - Colors

    struct Colors {
        static let screenBg = Color(red: 248/255, green: 243/255, blue: 240/255)
        static let cardBg = Color(red: 240/255, green: 235/255, blue: 229/255)
        static let textPrimary = Color(red: 26/255, green: 26/255, blue: 26/255)
        static let textSecondary = Color(red: 107/255, green: 107/255, blue: 107/255)
        static let buttonPrimary = Color(red: 44/255, green: 44/255, blue: 44/255)
        static let accentTan = Color(red: 139/255, green: 128/255, blue: 112/255)
        static let patternBg = Color(red: 232/255, green: 224/255, blue: 216/255)
        static let patternLine = Color(red: 212/255, green: 204/255, blue: 196/255)
        static let placeholder = Color.black.opacity(0.25)
        static let inputBg = Color.white.opacity(0.5)
        static let iconBg = Color.white.opacity(0.6)
    }

    // MARK: - Typography

    struct Typography {
        static let headlineXL = Font.system(size: 36, weight: .regular, design: .serif)
        static let headlineXLBold = Font.system(size: 36, weight: .bold, design: .serif)
        static let body = Font.system(size: 15)
        static let bodyMedium = Font.system(size: 14, weight: .medium)
        static let label = Font.system(size: 13, weight: .medium)
        static let captionSm = Font.system(size: 10, weight: .medium)
        static let captionMd = Font.system(size: 12, weight: .regular)
        static let userInput = Font.system(size: 15)
        static let suggestion = Font.system(size: 14)
        static let icon = Font.system(size: 14)
    }

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 10
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Radii

    struct Radii {
        static let card: CGFloat = 28
        static let inner: CGFloat = 16
    }

}
