// AppSettings.swift
// Global app display preferences (text size, sheet sizes, etc.)
// Uses @AppStorage for persistence across launches

import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    // Display & Layout
    @AppStorage("ui.textSizeIndex") var textSizeIndex: Int = 3 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("ui.defaultSheetDetentIndex") var defaultSheetDetentIndex: Int = 1 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("ui.appearanceMode") var appearanceMode: String = "system" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("ui.highContrast") var highContrast: Bool = false {
        didSet { objectWillChange.send() }
    }
    @AppStorage("ui.reduceMotion") var reduceMotion: Bool = false {
        didSet { objectWillChange.send() }
    }
    @AppStorage("ui.biggerTargets") var biggerTargets: Bool = false {
        didSet { objectWillChange.send() }
    }
    @AppStorage("ui.sidebarDensity") var sidebarDensity: String = "comfort" {
        didSet { objectWillChange.send() }
    }
    
    // Clinical & Questionnaire
    @AppStorage("clinical.autoAdvance") var autoAdvance: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("clinical.showBadges") var showBadges: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("clinical.inlineValidation") var inlineValidation: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("clinical.calc.cows") var calcCOWS: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("clinical.calc.ciwa") var calcCIWA: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("clinical.thresholdsVersion") var thresholdsVersion: String = "latest" {
        didSet { objectWillChange.send() }
    }
    
    // Dev / QA
    @AppStorage("dev.showBreadcrumbs") var showBreadcrumbs: Bool = false {
        didSet { objectWillChange.send() }
    }
    @AppStorage("dev.diagnosticsOverlay") var diagnosticsOverlay: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    // Rules & Provenance
    @AppStorage("rules.edition") var rulesEdition: String = "ASAM v4" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("rules.channel") var rulesChannel: String = "stable" {
        didSet { objectWillChange.send() }
    }
    
    // Compliance / Legal
    @AppStorage("compliance.mode") var complianceMode: String = "internal_neutral" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("compliance.asamLicenseId") var asamLicenseID: String = "" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("compliance.templateGuard") var templateGuard: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("compliance.export.strictness") var exportStrictness: String = "strict" {
        didSet { objectWillChange.send() }
    }
    
    // Privacy / Security
    @AppStorage("privacy.maskPHI") var maskPHI: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("privacy.screenshotRedaction") var screenshotRedaction: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("security.idleLock.enabled") var idleLockEnabled: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("security.idleLock.timeoutMinutes") var idleLockTimeoutMin: Int = 5 {
        didSet { objectWillChange.send() }
    }
    
    // Export / PDF
    @AppStorage("export.paper") var paper: String = "Letter" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("export.fileNameTemplate") var fileNameTemplate: String = "SUD_Plan_{date}_{planId8}.pdf" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("export.flatten") var flattenPDF: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("export.embedManifest") var embedManifest: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("export.qrSeal") var qrSeal: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("export.neutralWatermark") var neutralWatermark: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    // Environment
    @AppStorage("env.server") var serverEnv: String = "prod" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("env.rulesAutoUpdate") var rulesAutoUpdate: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    // Programs
    @AppStorage("programs.filterToAvailable") var filterPrograms: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    // Localization
    @AppStorage("i18n.units") var units: String = "us" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("i18n.timeFormat") var timeFormat: String = "system" {
        didSet { objectWillChange.send() }
    }
    
    /// Map textSizeIndex to DynamicTypeSize for app-wide scaling
    var dynamicType: DynamicTypeSize {
        let steps: [DynamicTypeSize] = [
            .xSmall,        // 0
            .small,         // 1
            .medium,        // 2
            .large,         // 3 (default iOS size)
            .xLarge,        // 4
            .xxLarge,       // 5
            .xxxLarge,      // 6
            .accessibility1, // 7
            .accessibility2, // 8
            .accessibility3  // 9
        ]
        let clampedIndex = min(max(textSizeIndex, 0), steps.count - 1)
        return steps[clampedIndex]
    }
    
    /// Map defaultSheetDetentIndex to PresentationDetent
    var defaultSheetDetent: PresentationDetent {
        switch defaultSheetDetentIndex {
        case 0: return .fraction(0.6)   // Compact
        case 1: return .fraction(0.8)   // Comfort (default)
        default: return .large          // Full
        }
    }
    
    /// Map appearanceMode to ColorScheme preference
    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // System default
        }
    }
    
    /// Human-readable text size label for current index
    var textSizeLabel: String {
        let labels = [
            "Extra Small",  // 0
            "Small",        // 1
            "Medium",       // 2
            "Large",        // 3 (default)
            "Extra Large",  // 4
            "2X Large",     // 5
            "3X Large",     // 6
            "Accessibility 1", // 7
            "Accessibility 2", // 8
            "Accessibility 3"  // 9
        ]
        let clampedIndex = min(max(textSizeIndex, 0), labels.count - 1)
        return labels[clampedIndex]
    }
}
