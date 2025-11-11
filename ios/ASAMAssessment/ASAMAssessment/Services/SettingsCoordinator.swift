//
//  SettingsCoordinator.swift
//  ASAMAssessment
//
//  Coordinates settings changes with app behavior:
//  - Reloads rules engine when edition/channel changes
//  - Triggers provenance events for audit trail
//  - Emits settings breadcrumbs
//

import Foundation
import Combine

final class SettingsCoordinator {
    private var cancellables = Set<AnyCancellable>()
    private let settings: SettingsStore
    
    init(settings: SettingsStore) {
        self.settings = settings
        wireWatchers()
    }
    
    private func wireWatchers() {
        // Watch rules edition/channel changes
        Publishers.Merge(
            settings.$rules_edition.map { _ in () },
            settings.$rules_channel.map { _ in () }
        )
        .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.handleRulesConfigurationChange()
        }
        .store(in: &cancellables)
        
        // Watch compliance mode changes
        settings.$compliance_mode
            .removeDuplicates()
            .dropFirst() // Skip initial value
            .sink { [weak self] newMode in
                self?.handleComplianceModeChange(newMode)
            }
            .store(in: &cancellables)
        
        // Watch export settings changes
        Publishers.Merge4(
            settings.$export_flattenPDF.map { _ in () },
            settings.$export_embedProvenance.map { _ in () },
            settings.$export_attachOriginalJSON.map { _ in () },
            settings.$export_filenameTemplate.map { _ in () }
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.handleExportSettingsChange()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Rules Configuration Change
    private func handleRulesConfigurationChange() {
        print("🔄 Rules configuration changed:")
        print("   Edition: \(settings.rules_edition)")
        print("   Channel: \(settings.rules_channel)")
        
        // TODO: Implement rules reload
        // Task { @MainActor in
        //     await RulesServiceWrapper.shared.reload()
        // }
        
        // Emit breadcrumb for audit
        emitSettingsBreadcrumb(
            key: "rules.configuration",
            value: "\(settings.rules_edition):\(settings.rules_channel)"
        )
        
        // TODO: Write provenance event
        // RulesProvenanceTracker.recordRulesLoaded(
        //     edition: settings.rules_edition,
        //     channel: settings.rules_channel,
        //     checksum: computedChecksum
        // )
    }
    
    // MARK: - Compliance Mode Change
    private func handleComplianceModeChange(_ newMode: String) {
        print("⚠️ Compliance mode changed to: \(newMode)")
        
        // Emit breadcrumb
        emitSettingsBreadcrumb(key: "compliance.mode", value: newMode)
        
        // TODO: Trigger export preflight re-evaluation
        // ExportPreflightService.shared.revalidate()
        
        #if DEBUG
        if newMode == "licensed" && settings.compliance_asamLicenseId.isEmpty {
            print("⚠️ WARNING: Licensed mode without license ID")
        }
        #endif
    }
    
    // MARK: - Export Settings Change
    private func handleExportSettingsChange() {
        print("📄 Export settings changed")
        
        // Validate export policy conflicts
        if settings.export_flattenPDF && settings.export_embedProvenance {
            print("⚠️ Note: Flattened PDFs embed provenance in Info dictionary")
        }
        
        if settings.export_flattenPDF && settings.export_attachOriginalJSON {
            print("⚠️ Note: Cannot attach JSON to flattened PDF; will use XMP metadata")
        }
        
        // Sanitize filename template
        let sanitized = settings.export_filenameTemplate.sanitizedFilename
        if sanitized != settings.export_filenameTemplate {
            print("⚠️ Filename template sanitized: \(settings.export_filenameTemplate) → \(sanitized)")
        }
        
        emitSettingsBreadcrumb(key: "export.policy", value: "updated")
    }
    
    // MARK: - Breadcrumb Emission
    private func emitSettingsBreadcrumb(key: String, value: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let breadcrumb = [
            "namespace": "settings",
            "key": key,
            "value": value,
            "timestamp": timestamp,
            "actor": "user"
        ]
        
        print("🧭 Settings breadcrumb: \(breadcrumb)")
        
        // TODO: Write to audit_events with HMAC chain
        // AuditTracker.shared.recordEvent(.settingsChanged(breadcrumb))
    }
}
