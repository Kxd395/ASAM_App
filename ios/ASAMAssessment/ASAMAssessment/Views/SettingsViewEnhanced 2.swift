//
//  SettingsViewEnhanced.swift
//  ASAMAssessment
//
//  Comprehensive app-wide settings with clinical, compliance, and dev/QA controls
//

import SwiftUI

// MARK: - Enhanced Settings View

struct SettingsViewEnhanced: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var rulesService: RulesServiceWrapper
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                displaySection
                clinicalSection
                rulesSection
                complianceSection
                privacySection
                exportSection
                environmentSection
                programsSection
                localizationSection
                
                #if DEBUG
                developerSection
                #endif
                
                aboutSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Display & Layout
    
    private var displaySection: some View {
        Section {
            Picker("Text Size", selection: $settings.textSizeIndex) {
                ForEach(0..<9) { idx in
                    Text(textSizeLabel(for: idx)).tag(idx)
                }
            }
            
            Picker("Default Sheet Size", selection: $settings.defaultSheetDetentIndex) {
                Text("Compact (60%)").tag(0)
                Text("Comfort (80%)").tag(1)
                Text("Full").tag(2)
            }
            .pickerStyle(.segmented)
            
            Toggle("High-Contrast Mode", isOn: $settings.highContrast)
            Toggle("Reduce Motion", isOn: $settings.reduceMotion)
            Toggle("Bigger Touch Targets", isOn: $settings.biggerTargets)
            
            Picker("Sidebar Density", selection: $settings.sidebarDensity) {
                Text("Comfort").tag("comfort")
                Text("Compact").tag("compact")
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Display & Layout")
        } footer: {
            Text("Text size and contrast apply across the entire app. Sheet size sets default height for review screens.")
        }
    }
    
    // MARK: - Clinical & Questionnaire
    
    private var clinicalSection: some View {
        Section {
            Toggle("Auto-Advance Questions", isOn: $settings.autoAdvance)
            Toggle("Show Unanswered Badges", isOn: $settings.showBadges)
            Toggle("Inline Validation Messages", isOn: $settings.inlineValidation)
            
            Toggle("Enable COWS Calculator", isOn: $settings.calcCOWS)
            Toggle("Enable CIWA-Ar Calculator", isOn: $settings.calcCIWA)
            
            LabeledContent("Threshold Source") {
                Text(settings.thresholdsVersion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Clinical & Questionnaire")
        } footer: {
            Text("Controls questionnaire behavior and available clinical calculators (COWS/CIWA-Ar).")
        }
    }
    
    // MARK: - Rules & Provenance
    
    private var rulesSection: some View {
        Section {
            Picker("Rules Edition", selection: $settings.rulesEdition) {
                Text("ASAM v3").tag("ASAM v3")
                Text("ASAM v4").tag("ASAM v4")
            }
            
            Picker("Rules Channel", selection: $settings.rulesChannel) {
                Text("Stable").tag("stable")
                Text("Beta").tag("beta")
            }
            .pickerStyle(.segmented)
            
            Button("Show Rules Manifest") {
                // Placeholder: show rules manifest modal
                print("📋 Show rules manifest: \(rulesService.provenance?.sha256Truncated ?? "N/A")")
            }
            
            Button("Recompute Rules Hash") {
                // Placeholder: force rules recompute
                print("♻️ Recompute rules hash")
            }
        } header: {
            Text("Rules & Provenance")
        } footer: {
            Text("Controls rules engine version and channel. Manifest shows per-file SHA256 hashes for audit trail.")
        }
    }
    
    // MARK: - Compliance & Legal
    
    private var complianceSection: some View {
        Section {
            Picker("Compliance Mode", selection: $settings.complianceMode) {
                Text("Internal Neutral").tag("internal_neutral")
                Text("Licensed ASAM").tag("licensed_asam")
            }
            
            SecureField("ASAM License ID", text: $settings.asamLicenseID)
                .textInputAutocapitalization(.characters)
                .disabled(settings.complianceMode == "internal_neutral")
            
            Toggle("Template Guard (Block ASAM in Neutral)", isOn: $settings.templateGuard)
            
            Picker("Export Gate Strictness", selection: $settings.exportStrictness) {
                Text("Strict").tag("strict")
                Text("Debug-Relaxed").tag("debugRelaxed")
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Compliance & Legal")
        } footer: {
            Text("⚠️ CRITICAL: Compliance mode controls ASAM trademark usage. Template guard prevents unlicensed ASAM branding.")
        }
    }
    
    // MARK: - Privacy & Security
    
    private var privacySection: some View {
        Section {
            Toggle("Mask PHI in Logs", isOn: $settings.maskPHI)
            Toggle("Screenshot Redaction Banner", isOn: $settings.screenshotRedaction)
            Toggle("Idle Lock / Face ID", isOn: $settings.idleLockEnabled)
            
            if settings.idleLockEnabled {
                Stepper(value: $settings.idleLockTimeoutMin, in: 1...15) {
                    Text("Timeout: \(settings.idleLockTimeoutMin) min")
                }
            }
        } header: {
            Text("Data, Privacy & Security")
        } footer: {
            Text("PHI masking and screenshot redaction protect patient data. Idle lock adds device-level security.")
        }
    }
    
    // MARK: - Export & PDF
    
    private var exportSection: some View {
        Section {
            Picker("Default Paper Size", selection: $settings.paper) {
                Text("Letter").tag("Letter")
                Text("A4").tag("A4")
            }
            .pickerStyle(.segmented)
            
            TextField("Filename Template", text: $settings.fileNameTemplate)
                .textInputAutocapitalization(.never)
                .font(.caption.monospaced())
            
            Toggle("Flatten Annotations", isOn: $settings.flattenPDF)
            Toggle("Embed Rules Manifest in PDF Info", isOn: $settings.embedManifest)
            Toggle("Include QR Seal", isOn: $settings.qrSeal)
            Toggle("Neutral Watermark (Internal Mode)", isOn: $settings.neutralWatermark)
        } header: {
            Text("Export & PDF")
        } footer: {
            Text("PDF export settings. QR seal embeds 64-char rules hash for verification. Watermark applies in neutral mode only.")
        }
    }
    
    // MARK: - Environment & Updates
    
    private var environmentSection: some View {
        Section {
            Picker("Server Environment", selection: $settings.serverEnv) {
                Text("Production").tag("prod")
                Text("Staging").tag("staging")
                Text("Local").tag("local")
            }
            
            Toggle("Auto-Update Rules When Online", isOn: $settings.rulesAutoUpdate)
            
            Button("Clear Cached Rules") {
                print("🧹 Clear cached rules")
            }
        } header: {
            Text("Environment & Updates")
        } footer: {
            Text("⚠️ Change server environment only if directed. Auto-update downloads latest rules when connected.")
        }
    }
    
    // MARK: - Programs Directory
    
    private var programsSection: some View {
        Section {
            Toggle("Filter LOC to Available Programs", isOn: $settings.filterPrograms)
        } header: {
            Text("Programs Directory")
        } footer: {
            Text("When enabled, LOC recommendations show only programs available in your facility directory.")
        }
    }
    
    // MARK: - Localization & Units
    
    private var localizationSection: some View {
        Section {
            Picker("Units", selection: $settings.units) {
                Text("US Customary").tag("us")
                Text("Metric").tag("metric")
            }
            .pickerStyle(.segmented)
            
            Picker("Time Format", selection: $settings.timeFormat) {
                Text("System").tag("system")
                Text("12-hour").tag("h12")
                Text("24-hour").tag("h24")
            }
        } header: {
            Text("Localization & Units")
        }
    }
    
    // MARK: - Developer / QA (DEBUG only)
    
    #if DEBUG
    private var developerSection: some View {
        Section {
            Toggle("Show Field Breadcrumbs", isOn: $settings.showBreadcrumbs)
            Toggle("Diagnostics Overlay", isOn: $settings.diagnosticsOverlay)
            
            NavigationLink("Field Mapping Inspector") {
                Text("Field Mapping Inspector")
                    .font(.title3)
                    .padding()
            }
        } header: {
            Text("Developer / QA")
        } footer: {
            Text("⚠️ Dev-only: Breadcrumbs show field → model → PDF mappings. Diagnostics overlay shows rules state.")
        }
    }
    #endif
    
    // MARK: - About
    
    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Build", value: "001")
            LabeledContent("Rules Version", value: rulesService.provenance?.sha256Truncated ?? "N/A")
            
            if let loadedAt = rulesService.loadedAt {
                LabeledContent("Rules Loaded") {
                    Text(loadedAt, style: .relative)
                        .font(.caption)
                }
            }
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Helpers
    
    private func textSizeLabel(for index: Int) -> String {
        let labels = ["Extra Small", "Small", "Medium", "Large", "Extra Large", "2X Large", "3X Large", "Accessibility 1", "Accessibility 2"]
        return labels[min(index, labels.count - 1)]
    }
}

// MARK: - Preview

#Preview {
    SettingsViewEnhanced()
        .environmentObject(AppSettings())
        .environmentObject(RulesServiceWrapper())
}
