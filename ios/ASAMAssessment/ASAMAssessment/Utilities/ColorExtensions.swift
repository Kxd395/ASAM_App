//
//  ColorExtensions.swift
//  ASAMAssessment
//
//  Color extensions for ASAM severity ratings and UI theming
//  WCAG AA compliant colors for accessibility
//

import SwiftUI

extension Color {
    // MARK: - Dimension 1 Severity Colors (Adaptive for Light/Dark Mode)
    
    /// 0 - None: Green indicating no severity
    static let d1None = Color("D1None", bundle: nil)
    static let d1NoneBorder = Color("D1NoneBorder", bundle: nil)
    static let d1NoneSwatch = Color("D1NoneSwatch", bundle: nil)
    
    /// 1 - Mild: Light green indicating mild severity
    static let d1Mild = Color("D1Mild", bundle: nil)
    static let d1MildBorder = Color("D1MildBorder", bundle: nil)
    static let d1MildSwatch = Color("D1MildSwatch", bundle: nil)
    
    /// 2 - Moderate: Yellow indicating moderate severity
    static let d1Moderate = Color("D1Moderate", bundle: nil)
    static let d1ModerateBorder = Color("D1ModerateBorder", bundle: nil)
    static let d1ModerateSwatch = Color("D1ModerateSwatch", bundle: nil)
    
    /// 3 - Severe: Orange indicating severe severity
    static let d1Severe = Color("D1Severe", bundle: nil)
    static let d1SevereBorder = Color("D1SevereBorder", bundle: nil)
    static let d1SevereSwatch = Color("D1SevereSwatch", bundle: nil)
    
    /// 4 - Very Severe: Red indicating critical severity
    static let d1VerySevere = Color("D1VerySevere", bundle: nil)
    static let d1VerySevereBorder = Color("D1VerySevereBorder", bundle: nil)
    static let d1VerySevereSwatch = Color("D1VerySevereSwatch", bundle: nil)
    
    // MARK: - Severity Card Colors with Adaptive Brightness
    
    /// Card background with automatic dark mode adaptation
    static func severityCardBackground(colorHex: String) -> Color {
        // Use Color(hex:) with a fallback - will be brighter in dark mode via system adaptation
        return Color(lightHex: colorHex, darkMultiplier: 0.3)
    }
    
    /// Card border with automatic dark mode adaptation  
    static func severityCardBorder(colorHex: String) -> Color {
        return Color(lightHex: colorHex, darkMultiplier: 1.4)
    }
    
    // MARK: - Severity Card Text Colors
    
    static let cardText = Color.primary // Adapts automatically
    static let cardTitle = Color.primary // Adapts automatically
    static let cardDisposition = Color.secondary // Adapts automatically
    static let chipTextOn = Color.white
    static let chipTextOff = Color.primary
    
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
    
    /// Initialize with adaptive brightness for dark mode
    /// - Parameters:
    ///   - lightHex: Hex color for light mode
    ///   - darkMultiplier: Brightness multiplier for dark mode (>1 = brighter, <1 = darker)
    init(lightHex: String, darkMultiplier: Double = 1.0) {
        let baseColor = Color(hex: lightHex)
        
        // In dark mode, adjust brightness
        if darkMultiplier != 1.0 {
            #if os(iOS)
            self = Color(uiColor: UIColor { traitCollection in
                let uiColor = UIColor(baseColor)
                if traitCollection.userInterfaceStyle == .dark {
                    // Adjust brightness for dark mode
                    var hue: CGFloat = 0
                    var saturation: CGFloat = 0
                    var brightness: CGFloat = 0
                    var alpha: CGFloat = 0
                    uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                    return UIColor(hue: hue, saturation: saturation * 0.8, brightness: min(1.0, brightness * darkMultiplier), alpha: alpha)
                }
                return uiColor
            })
            #else
            self = baseColor
            #endif
        } else {
            self = baseColor
        }
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
