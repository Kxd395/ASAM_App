//
//  ColorExtensions.swift
//  ASAMAssessment
//
//  Color extensions for ASAM severity ratings and UI theming
//  WCAG AA compliant colors for accessibility
//

import SwiftUI

extension Color {
    // MARK: - Dimension 1 Severity Colors (WCAG AA Compliant)
    
    /// 0 - None: Green indicating no severity
    static let d1None = Color(hex: "#9AD07D")
    static let d1NoneBorder = Color(hex: "#5AA03A")
    
    /// 1 - Mild: Light green indicating mild severity
    static let d1Mild = Color(hex: "#7CC46B")
    static let d1MildBorder = Color(hex: "#4F9A3A")
    
    /// 2 - Moderate: Yellow indicating moderate severity
    static let d1Moderate = Color(hex: "#F6C74A")
    static let d1ModerateBorder = Color(hex: "#C89E24")
    
    /// 3 - Severe: Orange indicating severe severity
    static let d1Severe = Color(hex: "#F59E3A")
    static let d1SevereBorder = Color(hex: "#C7771D")
    
    /// 4 - Very Severe: Red indicating critical severity
    static let d1VerySevere = Color(hex: "#E9544A")
    static let d1VerySevereBorder = Color(hex: "#B3382D")
    
    // MARK: - Severity Card Text Colors
    
    static let cardText = Color(hex: "#1F2937")
    static let cardTitle = Color(hex: "#111827")
    static let chipTextOn = Color.white
    static let chipTextOff = Color(hex: "#111827")
    
    // MARK: - Safety Banner Colors
    
    static let safetyBannerWarning = Color(hex: "#FEF3C7")
    static let safetyBannerWarningBorder = Color(hex: "#F59E0B")
    static let safetyBannerCritical = Color(hex: "#FEE2E2")
    static let safetyBannerCriticalBorder = Color(hex: "#DC2626")
    
    // MARK: - Helper Initializer for Hex Colors
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Severity Rating Helper
    
    /// Get background color for a severity rating (0-4)
    static func severityBackground(for rating: Int) -> Color {
        switch rating {
        case 0: return .d1None
        case 1: return .d1Mild
        case 2: return .d1Moderate
        case 3: return .d1Severe
        case 4: return .d1VerySevere
        default: return .gray
        }
    }
    
    /// Get border color for a severity rating (0-4)
    static func severityBorder(for rating: Int) -> Color {
        switch rating {
        case 0: return .d1NoneBorder
        case 1: return .d1MildBorder
        case 2: return .d1ModerateBorder
        case 3: return .d1SevereBorder
        case 4: return .d1VerySevereBorder
        default: return .gray
        }
    }
}
