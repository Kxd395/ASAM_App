//
//  SettingsStore.swift
//  ASAMAssessment
//
//  Unified settings store with @Published properties and UserDefaults bridge.
//  Replaces fragmented AppSettings/UserPrefs approach.
//  Observes external changes and provides migration support.
//

import Foundation
import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Display & Layout
    @Published var ui_textSizeIndex: Int = 3
    @Published var ui_defaultSheetDetentIndex: Int = 1
    @Published var ui_highContrast: Bool = false
    @Published var ui_reduceMotion: Bool = false
    @Published var ui_largerHitTargets: Bool = false
    @Published var ui_sidebarDensity: String = "comfortable" // "comfortable", "compact"
    
    // MARK: - Clinical & Questionnaire
    @Published var clinical_showCalculators: Bool = true
    @Published var clinical_autoAdvanceAfterReview: Bool = false
    @Published var clinical_confirmBeforeSubmit: Bool = true
    @Published var clinical_allowSkipOptional: Bool = true
    @Published var clinical_symptomSeverityThreshold: Int = 3
    @Published var clinical_riskScoringAlgorithm: String = "standard" // "standard", "conservative"
    
    // MARK: - Rules & Provenance
    @Published var rules_edition: String = "v3.2"
    @Published var rules_channel: String = "stable" // "stable", "beta", "local"
    @Published var rules_autoUpdate: Bool = false
    @Published var rules_showProvenance: Bool = true
    
    // MARK: - Compliance & Legal (P0-critical)
    @Published var compliance_mode: String = "internal_neutral"
    @Published var compliance_asamLicenseId: String = ""
    @Published var compliance_templateGuard: Bool = true
    @Published var compliance_exportStrictness: String = "strict" // "strict", "permissive"
    
    // MARK: - Privacy & Security
    @Published var privacy_maskPHI: Bool = false
    @Published var privacy_redactScreenshots: Bool = true
    @Published var privacy_requireFaceID: Bool = false
    @Published var privacy_idleLockMinutes: Int = 5
    
    // MARK: - Export & PDF
    @Published var export_paperSize: String = "letter"
    @Published var export_includeWatermark: Bool = false
    @Published var export_flattenPDF: Bool = true
    @Published var export_embedProvenance: Bool = true
    @Published var export_attachOriginalJSON: Bool = false
    @Published var export_filenameTemplate: String = "ASAMPlan_{planId8}_{date}"
    
    // MARK: - Environment & Updates
    @Published var env_apiEndpoint: String = "production"
    @Published var env_checkForUpdates: Bool = true
    
    // MARK: - Programs
    @Published var programs_filterToAvailable: Bool = true
    
    // MARK: - Localization
    @Published var localization_language: String = "en"
    @Published var localization_measurementSystem: String = "imperial"
    
    // MARK: - Developer (DEBUG only)
    #if DEBUG
    @Published var dev_showBreadcrumbs: Bool = false
    @Published var dev_diagnosticsOverlay: Bool = false
    #endif
    
    // MARK: - Versioning
    @Published private(set) var settingsVersion: Int = 2
    
    // MARK: - Computed Properties
    var dynamicType: DynamicTypeSize {
        let sizes: [DynamicTypeSize] = [
            .xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge,
            .accessibility1, .accessibility2
        ]
        return sizes[max(0, min(ui_textSizeIndex, sizes.count - 1))]
    }
    
    var defaultSheetDetent: PresentationDetent {
        switch ui_defaultSheetDetentIndex {
        case 0: return .fraction(0.6)
        case 2: return .large
        default: return .fraction(0.8)
        }
    }
    
    var textSizeLabel: String {
        let labels = ["Tiny", "Extra Small", "Small", "Default", "Medium", 
                      "Large", "Extra Large", "Huge", "Maximum"]
        return labels[max(0, min(ui_textSizeIndex, labels.count - 1))]
    }
    
    var isLicensedMode: Bool {
        compliance_mode == "licensed"
    }
    
    // MARK: - Initialization
    private init() {
        registerDefaults()
        migrateIfNeeded()
        pullFromDefaults()
        observeExternalChanges()
        wireSaves()
    }
    
    // MARK: - Defaults Registration
    private func registerDefaults() {
        defaults.register(defaults: [
            // Display
            "ui.textSizeIndex": 3,
            "ui.defaultSheetDetentIndex": 1,
            "ui.highContrast": false,
            "ui.reduceMotion": false,
            "ui.largerHitTargets": false,
            "ui.sidebarDensity": "comfortable",
            
            // Clinical
            "clinical.showCalculators": true,
            "clinical.autoAdvanceAfterReview": false,
            "clinical.confirmBeforeSubmit": true,
            "clinical.allowSkipOptional": true,
            "clinical.symptomSeverityThreshold": 3,
            "clinical.riskScoringAlgorithm": "standard",
            
            // Rules
            "rules.edition": "v3.2",
            "rules.channel": "stable",
            "rules.autoUpdate": false,
            "rules.showProvenance": true,
            
            // Compliance
            "compliance.mode": "internal_neutral",
            "compliance.asamLicenseId": "",
            "compliance.templateGuard": true,
            "compliance.export.strictness": "strict",
            
            // Privacy
            "privacy.maskPHI": false,
            "privacy.redactScreenshots": true,
            "privacy.requireFaceID": false,
            "privacy.idleLockMinutes": 5,
            
            // Export
            "export.paperSize": "letter",
            "export.includeWatermark": false,
            "export.flattenPDF": true,
            "export.embedProvenance": true,
            "export.attachOriginalJSON": false,
            "export.filenameTemplate": "ASAMPlan_{planId8}_{date}",
            
            // Environment
            "env.apiEndpoint": "production",
            "env.checkForUpdates": true,
            
            // Programs
            "programs.filterToAvailable": true,
            
            // Localization
            "localization.language": "en",
            "localization.measurementSystem": "imperial",
            
            // Versioning
            "settings.version": 2
        ])
        
        // Add DEBUG-only defaults separately (can't use #if inside dictionary literal)
        #if DEBUG
        defaults.setValuesForKeys([
            "dev.showBreadcrumbs": false,
            "dev.diagnosticsOverlay": false
        ])
        #endif
    }
    
    // MARK: - Migration
    func migrateIfNeeded() {
        let currentVersion = defaults.integer(forKey: "settings.version")
        
        if currentVersion < 1 {
            // V1 migration: Initial settings
            print("⬆️ Migrating settings to v1")
            defaults.set(1, forKey: "settings.version")
        }
        
        if currentVersion < 2 {
            // V2 migration: New export and privacy settings
            print("⬆️ Migrating settings to v2")
            
            // Set secure defaults for new privacy settings
            if defaults.object(forKey: "privacy.redactScreenshots") == nil {
                defaults.set(true, forKey: "privacy.redactScreenshots")
            }
            if defaults.object(forKey: "export.flattenPDF") == nil {
                defaults.set(true, forKey: "export.flattenPDF")
            }
            if defaults.object(forKey: "compliance.templateGuard") == nil {
                defaults.set(true, forKey: "compliance.templateGuard")
            }
            
            defaults.set(2, forKey: "settings.version")
        }
        
        settingsVersion = defaults.integer(forKey: "settings.version")
    }
    
    // MARK: - UserDefaults Sync
    private func pullFromDefaults() {
        // Display
        ui_textSizeIndex = defaults.integer(forKey: "ui.textSizeIndex")
        ui_defaultSheetDetentIndex = defaults.integer(forKey: "ui.defaultSheetDetentIndex")
        ui_highContrast = defaults.bool(forKey: "ui.highContrast")
        ui_reduceMotion = defaults.bool(forKey: "ui.reduceMotion")
        ui_largerHitTargets = defaults.bool(forKey: "ui.largerHitTargets")
        ui_sidebarDensity = defaults.string(forKey: "ui.sidebarDensity") ?? "comfortable"
        
        // Clinical
        clinical_showCalculators = defaults.bool(forKey: "clinical.showCalculators")
        clinical_autoAdvanceAfterReview = defaults.bool(forKey: "clinical.autoAdvanceAfterReview")
        clinical_confirmBeforeSubmit = defaults.bool(forKey: "clinical.confirmBeforeSubmit")
        clinical_allowSkipOptional = defaults.bool(forKey: "clinical.allowSkipOptional")
        clinical_symptomSeverityThreshold = defaults.integer(forKey: "clinical.symptomSeverityThreshold")
        clinical_riskScoringAlgorithm = defaults.string(forKey: "clinical.riskScoringAlgorithm") ?? "standard"
        
        // Rules
        rules_edition = defaults.string(forKey: "rules.edition") ?? "v3.2"
        rules_channel = defaults.string(forKey: "rules.channel") ?? "stable"
        rules_autoUpdate = defaults.bool(forKey: "rules.autoUpdate")
        rules_showProvenance = defaults.bool(forKey: "rules.showProvenance")
        
        // Compliance - Check MDM first
        let managed = UserDefaults(suiteName: "com.apple.configuration.managed")
        compliance_mode = managed?.string(forKey: "compliance.mode") 
                         ?? defaults.string(forKey: "compliance.mode") 
                         ?? "internal_neutral"
        compliance_asamLicenseId = managed?.string(forKey: "compliance.asamLicenseId")
                                  ?? defaults.string(forKey: "compliance.asamLicenseId")
                                  ?? ""
        compliance_templateGuard = managed?.bool(forKey: "compliance.templateGuard")
                                  ?? defaults.bool(forKey: "compliance.templateGuard")
        compliance_exportStrictness = defaults.string(forKey: "compliance.export.strictness") ?? "strict"
        
        // Privacy
        privacy_maskPHI = defaults.bool(forKey: "privacy.maskPHI")
        privacy_redactScreenshots = defaults.bool(forKey: "privacy.redactScreenshots")
        privacy_requireFaceID = defaults.bool(forKey: "privacy.requireFaceID")
        privacy_idleLockMinutes = defaults.integer(forKey: "privacy.idleLockMinutes")
        
        // Export
        export_paperSize = defaults.string(forKey: "export.paperSize") ?? "letter"
        export_includeWatermark = defaults.bool(forKey: "export.includeWatermark")
        export_flattenPDF = defaults.bool(forKey: "export.flattenPDF")
        export_embedProvenance = defaults.bool(forKey: "export.embedProvenance")
        export_attachOriginalJSON = defaults.bool(forKey: "export.attachOriginalJSON")
        export_filenameTemplate = defaults.string(forKey: "export.filenameTemplate") ?? "ASAMPlan_{planId8}_{date}"
        
        // Environment
        env_apiEndpoint = defaults.string(forKey: "env.apiEndpoint") ?? "production"
        env_checkForUpdates = defaults.bool(forKey: "env.checkForUpdates")
        
        // Programs
        programs_filterToAvailable = defaults.bool(forKey: "programs.filterToAvailable")
        
        // Localization
        localization_language = defaults.string(forKey: "localization.language") ?? "en"
        localization_measurementSystem = defaults.string(forKey: "localization.measurementSystem") ?? "imperial"
        
        // Developer
        #if DEBUG
        dev_showBreadcrumbs = defaults.bool(forKey: "dev.showBreadcrumbs")
        dev_diagnosticsOverlay = defaults.bool(forKey: "dev.diagnosticsOverlay")
        #endif
        
        // Versioning
        settingsVersion = defaults.integer(forKey: "settings.version")
    }
    
    // MARK: - Save Watchers
    private func wireSaves() {
        // Display
        $ui_textSizeIndex.sink { [weak self] v in self?.defaults.set(v, forKey: "ui.textSizeIndex") }.store(in: &cancellables)
        $ui_defaultSheetDetentIndex.sink { [weak self] v in self?.defaults.set(v, forKey: "ui.defaultSheetDetentIndex") }.store(in: &cancellables)
        $ui_highContrast.sink { [weak self] v in self?.defaults.set(v, forKey: "ui.highContrast") }.store(in: &cancellables)
        $ui_reduceMotion.sink { [weak self] v in self?.defaults.set(v, forKey: "ui.reduceMotion") }.store(in: &cancellables)
        $ui_largerHitTargets.sink { [weak self] v in self?.defaults.set(v, forKey: "ui.largerHitTargets") }.store(in: &cancellables)
        $ui_sidebarDensity.sink { [weak self] v in self?.defaults.set(v, forKey: "ui.sidebarDensity") }.store(in: &cancellables)
        
        // Clinical
        $clinical_showCalculators.sink { [weak self] v in self?.defaults.set(v, forKey: "clinical.showCalculators") }.store(in: &cancellables)
        $clinical_autoAdvanceAfterReview.sink { [weak self] v in self?.defaults.set(v, forKey: "clinical.autoAdvanceAfterReview") }.store(in: &cancellables)
        $clinical_confirmBeforeSubmit.sink { [weak self] v in self?.defaults.set(v, forKey: "clinical.confirmBeforeSubmit") }.store(in: &cancellables)
        $clinical_allowSkipOptional.sink { [weak self] v in self?.defaults.set(v, forKey: "clinical.allowSkipOptional") }.store(in: &cancellables)
        $clinical_symptomSeverityThreshold.sink { [weak self] v in self?.defaults.set(v, forKey: "clinical.symptomSeverityThreshold") }.store(in: &cancellables)
        $clinical_riskScoringAlgorithm.sink { [weak self] v in self?.defaults.set(v, forKey: "clinical.riskScoringAlgorithm") }.store(in: &cancellables)
        
        // Rules
        $rules_edition.sink { [weak self] v in self?.defaults.set(v, forKey: "rules.edition") }.store(in: &cancellables)
        $rules_channel.sink { [weak self] v in self?.defaults.set(v, forKey: "rules.channel") }.store(in: &cancellables)
        $rules_autoUpdate.sink { [weak self] v in self?.defaults.set(v, forKey: "rules.autoUpdate") }.store(in: &cancellables)
        $rules_showProvenance.sink { [weak self] v in self?.defaults.set(v, forKey: "rules.showProvenance") }.store(in: &cancellables)
        
        // Compliance (only save if not MDM-managed)
        $compliance_mode.sink { [weak self] v in
            let managed = UserDefaults(suiteName: "com.apple.configuration.managed")
            if managed?.string(forKey: "compliance.mode") == nil {
                self?.defaults.set(v, forKey: "compliance.mode")
            }
        }.store(in: &cancellables)
        
        $compliance_asamLicenseId.sink { [weak self] v in self?.defaults.set(v, forKey: "compliance.asamLicenseId") }.store(in: &cancellables)
        $compliance_templateGuard.sink { [weak self] v in self?.defaults.set(v, forKey: "compliance.templateGuard") }.store(in: &cancellables)
        $compliance_exportStrictness.sink { [weak self] v in self?.defaults.set(v, forKey: "compliance.export.strictness") }.store(in: &cancellables)
        
        // Privacy
        $privacy_maskPHI.sink { [weak self] v in self?.defaults.set(v, forKey: "privacy.maskPHI") }.store(in: &cancellables)
        $privacy_redactScreenshots.sink { [weak self] v in self?.defaults.set(v, forKey: "privacy.redactScreenshots") }.store(in: &cancellables)
        $privacy_requireFaceID.sink { [weak self] v in self?.defaults.set(v, forKey: "privacy.requireFaceID") }.store(in: &cancellables)
        $privacy_idleLockMinutes.sink { [weak self] v in self?.defaults.set(v, forKey: "privacy.idleLockMinutes") }.store(in: &cancellables)
        
        // Export
        $export_paperSize.sink { [weak self] v in self?.defaults.set(v, forKey: "export.paperSize") }.store(in: &cancellables)
        $export_includeWatermark.sink { [weak self] v in self?.defaults.set(v, forKey: "export.includeWatermark") }.store(in: &cancellables)
        $export_flattenPDF.sink { [weak self] v in self?.defaults.set(v, forKey: "export.flattenPDF") }.store(in: &cancellables)
        $export_embedProvenance.sink { [weak self] v in self?.defaults.set(v, forKey: "export.embedProvenance") }.store(in: &cancellables)
        $export_attachOriginalJSON.sink { [weak self] v in self?.defaults.set(v, forKey: "export.attachOriginalJSON") }.store(in: &cancellables)
        $export_filenameTemplate.sink { [weak self] v in self?.defaults.set(v, forKey: "export.filenameTemplate") }.store(in: &cancellables)
        
        // Environment
        $env_apiEndpoint.sink { [weak self] v in self?.defaults.set(v, forKey: "env.apiEndpoint") }.store(in: &cancellables)
        $env_checkForUpdates.sink { [weak self] v in self?.defaults.set(v, forKey: "env.checkForUpdates") }.store(in: &cancellables)
        
        // Programs
        $programs_filterToAvailable.sink { [weak self] v in self?.defaults.set(v, forKey: "programs.filterToAvailable") }.store(in: &cancellables)
        
        // Localization
        $localization_language.sink { [weak self] v in self?.defaults.set(v, forKey: "localization.language") }.store(in: &cancellables)
        $localization_measurementSystem.sink { [weak self] v in self?.defaults.set(v, forKey: "localization.measurementSystem") }.store(in: &cancellables)
        
        // Developer
        #if DEBUG
        $dev_showBreadcrumbs.sink { [weak self] v in self?.defaults.set(v, forKey: "dev.showBreadcrumbs") }.store(in: &cancellables)
        $dev_diagnosticsOverlay.sink { [weak self] v in self?.defaults.set(v, forKey: "dev.diagnosticsOverlay") }.store(in: &cancellables)
        #endif
    }
    
    // MARK: - External Changes Observer
    private func observeExternalChanges() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.pullFromDefaults()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - MDM Check
    var isMDMManaged: Bool {
        let managed = UserDefaults(suiteName: "com.apple.configuration.managed")
        return managed?.string(forKey: "compliance.mode") != nil
    }
}

// MARK: - Filename Sanitization
extension String {
    var sanitizedFilename: String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "._-"))
        return self.unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "_" }
            .reduce("") { $0 + String($1) }
    }
}
