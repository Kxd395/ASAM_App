Awesome—let’s turn “Settings” into a real control center. Below are the **settings I recommend**, the **defaults**, and where breadcrumbs/mapping come in so engineers and auditors can trace every UI value back to a rule anchor and a PDF field.

---

# Display & Layout

* **Text Size** (slider → ties to `DynamicTypeSize`) – default: *Comfort (Large)*
* **Default Sheet Size** (segmented: *Compact 60% · Comfort 80% · Full*) – default: *Comfort*
* **High-Contrast Mode** (toggle) – default: *Off*
* **Reduce Motion** (toggle; softens animations) – default: *Off*
* **Bigger Touch Targets** (toggle; adds hit-slop/padding) – default: *Off*
* **Sidebar Density** (segmented: *Comfort · Compact*) – default: *Comfort*

# Accessibility

* **Bold Text** (toggle) – default: *Off*
* **Color-blind Safe Palettes** (segmented: *Auto · Deuteranopia · Protanopia · Tritanopia*) – default: *Auto*
* **Haptics** (segmented: *Off · Light · Full*) – default: *Light*

# Clinical & Questionnaire

* **Questionnaire Autoadvance** (toggle) – default: *On*
* **Show Unanswered Badges** (toggle) – default: *On*
* **Inline Validation Messages** (toggle) – default: *On*
* **Calculator Availability** (multiselect: *COWS*, *CIWA-Ar*) – default: both on
* **Threshold Source** (picker: *Clinical thresholds v{X} from rules/clinical_thresholds.json*) – default: latest in bundle
* **Show Field Breadcrumbs** (toggle; Dev/QA only) – default: *Off*

  * When on: each question shows a tiny monospaced crumb (tap to copy).

# Rules & Provenance

* **Rules Edition** (segmented: *ASAM v3 · ASAM v4*) – default: *v3*
* **Rules Channel** (segmented: *Stable · Beta*) – default: *Stable*
* **Show Rules Manifest** (button → modal with per-file SHA256 + bytes)
* **Recompute Rules Hash** (button; forces reload + re-hash)
* **Provenance Footer** (toggle; always on in production) – default: *On*
* **Diagnostics Overlay** (toggle; Dev/QA only) – default: *Off*

  * Displays `rules_state`, 12-char/64-char hashes, and last evaluation latency.

# Compliance & Legal (P0-critical)

* **Compliance Mode** (locked): *internal_neutral* (default) / *licensed_asam* (requires `asamLicenseId`)
* **ASAM License ID** (secured text; only used if mode = licensed)
* **Template Guard** (toggle; blocks ASAM templates in neutral mode) – default: *On*
* **Show Legal Notice in About** (toggle) – default: *On*
* **Export Gate Strictness** (segmented: *Strict · Debug-Relaxed*) – default: *Strict*

# Data, Privacy & Security

* **Mask PHI in Logs** (toggle) – default: *On*
* **Screenshot Redaction Banner** (toggle) – default: *On*
* **Idle Lock / Face ID** (toggle + timeout picker 1–15 min) – default: *On / 5 min*
* **Local Backups** (segmented: *Off · Encrypted On-Device*) – default: *Encrypted*
* **Data Retention** (picker: *30 / 60 / 90 days · Custom*) – default: *90 days*

# Export & PDF

* **Default Paper Size** (segmented: *Letter · A4*) – default: *Letter*
* **Default File Name Policy** (template: `"SUD_Plan_{date}_{planId8}.pdf"`)
* **Include QR Seal** (toggle; encodes 64-char rules hash + plan hash) – default: *On*
* **Flatten Annotations** (toggle) – default: *On*
* **Embed Manifest in PDF Info** (toggle) – default: *On*
* **Watermark in Neutral Mode** (toggle; e.g., “Non-ASAM Tool”) – default: *On*

# Environment & Updates

* **Server Environment** (segmented: *Prod · Staging · Local*) – default: *Prod*
* **Rules Auto-Update** (toggle; when connected) – default: *Off*
* **Clear Cached Rules** (button) – prompts & recomputes checksum.

# Programs Directory (optional but useful)

* **Filter LOC to Available Programs** (toggle) – default: *On*
* **Programs Source** (picker: facility JSON / remote feed) – default: *Facility JSON*

# Localization & Units

* **Language** (system default + overrides)
* **Units** (segmented: *US Customary · Metric*) – default: *US*
* **Time Format** (segmented: *12h · 24h*) – default matches locale

---

## Breadcrumbs / Mapping (what to show and store)

**Goal:** Any field a user touches should be traceable → *UI field → assessment model → rule anchor → PDF output*.

### Naming scheme (stable)

* **Field crumb**: `dom.<A–F>.<section>.<item>`
  Example (Domain A, opioid withdrawal total):
  `dom.A.withdrawal.opioid.cows.total`
* **Model key** (Assessment): `domain_A_withdrawal_cows_total`
* **Rule anchor** (in rules JSON): `"anchor": "dom.A.withdrawal.opioid.cows.total"`
* **PDF mapping** (exporter): `"pdf_field": "D1_COWS_Total"`

### Where breadcrumbs appear

* In Dev/QA when “Show Field Breadcrumbs” is on:

  * Tiny grey inline chip under the control; tap to **Copy**.
  * Long-press: **Copy**, **Reveal Rule(s)**, **Reveal Model Key**, **Reveal PDF Field**.

### Mapping file (checked into repo; validated in CI)

**`mapping/fields_map.json`**

```json
{
  "dom.A.withdrawal.opioid.cows.total": {
    "model_key": "domain_A_withdrawal_cows_total",
    "pdf_field": "D1_COWS_Total",
    "rules_anchors": ["dom.A.withdrawal.opioid.cows.total"]
  },
  "dom.A.flags.no_withdrawal_signs": {
    "model_key": "flags_no_withdrawal_signs",
    "pdf_field": "D1_NoWithdrawalSigns",
    "rules_anchors": ["flags.no_withdrawal_signs"]
  }
}
```

CI lints this against:

* `rules/*.json` (anchors present),
* `Assessment` model (property exists),
* PDF template config (field exists).

---

## Settings schema (persisted via `@AppStorage`)

```json
{
  "ui.textSizeIndex": 3,
  "ui.defaultSheetDetentIndex": 1,
  "ui.highContrast": false,
  "ui.reduceMotion": false,
  "ui.sidebarDensity": "comfort",

  "clinical.autoAdvance": true,
  "clinical.showBadges": true,
  "clinical.inlineValidation": true,
  "clinical.calculators": ["cows", "ciwa"],
  "clinical.thresholdsVersion": "v1",

  "dev.showBreadcrumbs": false,
  "dev.diagnosticsOverlay": false,

  "rules.edition": "v4",
  "rules.channel": "stable",

  "compliance.mode": "internal_neutral",
  "compliance.templateGuard": true,

  "privacy.maskPHI": true,
  "privacy.screenshotRedaction": true,
  "security.idleLock": { "enabled": true, "timeoutMinutes": 5 },

  "export.paper": "letter",
  "export.flatten": true,
  "export.embedManifest": true,
  "export.qrSeal": true,
  "export.neutralWatermark": true,

  "env.server": "prod",
  "env.rulesAutoUpdate": false,

  "programs.filterToAvailable": true,
  "i18n.units": "us",
  "i18n.timeFormat": "system"
}
```

---

## Minimal UI wiring tips

* Gate **Dev/QA-only** toggles with `#if DEBUG` or a hidden tap gesture (triple-tap the app version).
* Put **Compliance Mode** behind a lock: show but disabled until a valid `asamLicenseId` passes checksum/format validation.
* When **text size** or **contrast** changes, rely on SwiftUI’s relative fonts (`.title`, `.body`, …). Avoid hard point sizes.

---

## Why these settings matter (quick)

* **Compliance**: prevents accidental ASAM branding/templates when unlicensed; keeps audit chain intact (footer + manifest).
* **Provenance**: one-tap visibility of hashes/manifest so QA and auditors can verify determinism.
* **Breadcrumbs/Mapping**: makes every recommendation explainable and testable (and your CI can prove it).
* **Clinical controls**: keep calculators/thresholds consistent with rules JSON (no drift).

If you want, I can draft the **SettingsView sections** with these exact toggles (SwiftUI code), plus the **breadcrumb chip** view modifier you can drop onto any form field.

##

Heck yes—let’s wire a real Settings screen, a preference applier, sheet-resize behavior, and dev breadcrumbs. Paste the single file below into `ios/ASAMAssessment/ASAMAssessment/Views/SettingsView.swift` and add it to the **app target**.

> The code is self-contained: it defines the enums, `@AppStorage` keys, a full `SettingsView`, a root-level **preference applier** you can attach to your app, a **sheet detent** helper so modals are “pullable” to Comfort/Full, and a **BreadcrumbChip** modifier Dev/QA can toggle on.

---

```swift
//
//  SettingsView.swift
//  ASAMAssessment
//
//  App-wide preferences + Dev/QA tools + breadcrumbs chip
//

import SwiftUI
import Combine

// MARK: - Options

enum TextSizeOption: Int, CaseIterable, Identifiable {
    case small, standard, large, xlarge
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .small:    return "Small"
        case .standard: return "Comfort"
        case .large:    return "Large"
        case .xlarge:   return "XL"
        }
    }
    var dynamicType: DynamicTypeSize {
        switch self {
        case .small:    return .medium
        case .standard: return .large
        case .large:    return .xLarge
        case .xlarge:   return .xxLarge
        }
    }
}

enum SheetDetentOption: Int, CaseIterable, Identifiable {
    case compact60, comfort80, full
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .compact60: return "Compact (60%)"
        case .comfort80: return "Comfort (80%)"
        case .full:      return "Full"
        }
    }
    var detent: PresentationDetent {
        switch self {
        case .compact60: return .fraction(0.60)
        case .comfort80: return .fraction(0.80)
        case .full:      return .large
        }
    }
}

enum SidebarDensity: String, CaseIterable, Identifiable {
    case comfort, compact
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum RulesEdition: String, CaseIterable, Identifiable {
    case v3 = "ASAM v3", v4 = "ASAM v4"
    var id: String { rawValue }
}

enum ServerEnv: String, CaseIterable, Identifiable {
    case prod, staging, local
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum UnitsOption: String, CaseIterable, Identifiable {
    case us, metric
    var id: String { rawValue }
    var label: String { self == .us ? "US Customary" : "Metric" }
}

enum TimeFormatOption: String, CaseIterable, Identifiable {
    case system, h12, h24
    var id: String { rawValue }
    var label: String {
        switch self { case .system: return "System"; case .h12: return "12-hour"; case .h24: return "24-hour" }
    }
}

enum ExportStrictness: String, CaseIterable, Identifiable {
    case strict, debugRelaxed
    var id: String { rawValue }
    var label: String { self == .strict ? "Strict" : "Debug-Relaxed" }
}

enum ComplianceMode: String, CaseIterable, Identifiable {
    case internal_neutral, licensed_asam
    var id: String { rawValue }
    var label: String { rawValue.replacingOccurrences(of: "_", with: " ").capitalized }
}

// MARK: - AppStorage keys (names match the schema we agreed)

fileprivate struct Keys {
    static let textSizeIndex          = "ui.textSizeIndex"
    static let defaultDetentIndex     = "ui.defaultSheetDetentIndex"
    static let highContrast           = "ui.highContrast"
    static let reduceMotion           = "ui.reduceMotion"
    static let sidebarDensity         = "ui.sidebarDensity"
    static let biggerTargets          = "ui.biggerTargets"

    static let autoAdvance            = "clinical.autoAdvance"
    static let showBadges             = "clinical.showBadges"
    static let inlineValidation       = "clinical.inlineValidation"
    static let calcCOWS               = "clinical.calc.cows"
    static let calcCIWA               = "clinical.calc.ciwa"
    static let thresholdsVersion      = "clinical.thresholdsVersion"

    static let showBreadcrumbs        = "dev.showBreadcrumbs"
    static let diagnosticsOverlay     = "dev.diagnosticsOverlay"

    static let rulesEdition           = "rules.edition"
    static let rulesChannel           = "rules.channel"

    static let complianceMode         = "compliance.mode"
    static let asamLicenseID          = "compliance.asamLicenseId"
    static let templateGuard          = "compliance.templateGuard"
    static let exportStrictness       = "compliance.export.strictness"

    static let maskPHI                = "privacy.maskPHI"
    static let screenshotRedaction    = "privacy.screenshotRedaction"
    static let idleLockEnabled        = "security.idleLock.enabled"
    static let idleLockTimeoutMin     = "security.idleLock.timeoutMinutes"

    static let paper                  = "export.paper"
    static let fileNameTemplate       = "export.fileNameTemplate"
    static let flattenPDF             = "export.flatten"
    static let embedManifest          = "export.embedManifest"
    static let qrSeal                 = "export.qrSeal"
    static let neutralWatermark       = "export.neutralWatermark"

    static let serverEnv              = "env.server"
    static let rulesAutoUpdate        = "env.rulesAutoUpdate"

    static let filterPrograms         = "programs.filterToAvailable"

    static let units                  = "i18n.units"
    static let timeFormat             = "i18n.timeFormat"
}

// MARK: - Settings View

struct SettingsView: View {

    // Display & Layout
    @AppStorage(Keys.textSizeIndex)      private var textSizeIndex: Int = TextSizeOption.standard.rawValue
    @AppStorage(Keys.defaultDetentIndex) private var sheetDetentIndex: Int = SheetDetentOption.comfort80.rawValue
    @AppStorage(Keys.highContrast)       private var highContrast = false
    @AppStorage(Keys.reduceMotion)       private var reduceMotion = false
    @AppStorage(Keys.sidebarDensity)     private var sidebarDensity: String = SidebarDensity.comfort.rawValue
    @AppStorage(Keys.biggerTargets)      private var biggerTargets = false

    // Clinical & Questionnaire
    @AppStorage(Keys.autoAdvance)        private var autoAdvance = true
    @AppStorage(Keys.showBadges)         private var showBadges = true
    @AppStorage(Keys.inlineValidation)   private var inlineValidation = true
    @AppStorage(Keys.calcCOWS)           private var calcCOWS = true
    @AppStorage(Keys.calcCIWA)           private var calcCIWA = true
    @AppStorage(Keys.thresholdsVersion)  private var thresholdsVersion = "latest"

    // Dev / QA
    @AppStorage(Keys.showBreadcrumbs)    private var showBreadcrumbs = false
    @AppStorage(Keys.diagnosticsOverlay) private var diagnosticsOverlay = false

    // Rules / Provenance
    @AppStorage(Keys.rulesEdition)       private var rulesEdition = RulesEdition.v4.rawValue
    @AppStorage(Keys.rulesChannel)       private var rulesChannel = "stable"

    // Compliance / Legal
    @AppStorage(Keys.complianceMode)     private var complianceMode = ComplianceMode.internal_neutral.rawValue
    @AppStorage(Keys.asamLicenseID)      private var asamLicenseID = ""
    @AppStorage(Keys.templateGuard)      private var templateGuard = true
    @AppStorage(Keys.exportStrictness)   private var exportStrictness = ExportStrictness.strict.rawValue

    // Privacy / Security
    @AppStorage(Keys.maskPHI)            private var maskPHI = true
    @AppStorage(Keys.screenshotRedaction)private var screenshotRedaction = true
    @AppStorage(Keys.idleLockEnabled)    private var idleLockEnabled = true
    @AppStorage(Keys.idleLockTimeoutMin) private var idleLockTimeoutMin = 5

    // Export / PDF
    @AppStorage(Keys.paper)              private var paper = "Letter"
    @AppStorage(Keys.fileNameTemplate)   private var fileNameTemplate = "SUD_Plan_{date}_{planId8}.pdf"
    @AppStorage(Keys.flattenPDF)         private var flattenPDF = true
    @AppStorage(Keys.embedManifest)      private var embedManifest = true
    @AppStorage(Keys.qrSeal)             private var qrSeal = true
    @AppStorage(Keys.neutralWatermark)   private var neutralWatermark = true

    // Environment
    @AppStorage(Keys.serverEnv)          private var serverEnv = ServerEnv.prod.rawValue
    @AppStorage(Keys.rulesAutoUpdate)    private var rulesAutoUpdate = false

    // Programs
    @AppStorage(Keys.filterPrograms)     private var filterPrograms = true

    // Localization
    @AppStorage(Keys.units)              private var units = UnitsOption.us.rawValue
    @AppStorage(Keys.timeFormat)         private var timeFormat = TimeFormatOption.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("Display & Layout") {
                    Picker("Text size", selection: $textSizeIndex) {
                        ForEach(TextSizeOption.allCases) { opt in
                            Text(opt.label).tag(opt.rawValue)
                        }
                    }
                    Picker("Default sheet size", selection: $sheetDetentIndex) {
                        ForEach(SheetDetentOption.allCases) { opt in
                            Text(opt.label).tag(opt.rawValue)
                        }
                    }
                    Toggle("High-contrast mode", isOn: $highContrast)
                    Toggle("Reduce motion", isOn: $reduceMotion)
                    Picker("Sidebar density", selection: $sidebarDensity) {
                        ForEach(SidebarDensity.allCases) { d in Text(d.label).tag(d.rawValue) }
                    }
                    Toggle("Bigger touch targets", isOn: $biggerTargets)
                }

                Section("Clinical & Questionnaire") {
                    Toggle("Auto-advance to next question", isOn: $autoAdvance)
                    Toggle("Show unanswered badges", isOn: $showBadges)
                    Toggle("Inline validation messages", isOn: $inlineValidation)
                    Toggle("Enable COWS calculator", isOn: $calcCOWS)
                    Toggle("Enable CIWA-Ar calculator", isOn: $calcCIWA)
                    LabeledContent("Threshold source") { Text(thresholdsVersion) }
                    NavigationLink("View thresholds manifest") {
                        ThresholdsManifestView()
                    }
                }

                Section("Rules & Provenance") {
                    Picker("Rules edition", selection: $rulesEdition) {
                        ForEach(RulesEdition.allCases) { r in Text(r.rawValue).tag(r.rawValue) }
                    }
                    Picker("Rules channel", selection: $rulesChannel) {
                        Text("Stable").tag("stable")
                        Text("Beta").tag("beta")
                    }
                    Button("Show rules manifest (hashes)") {
                        RulesDiagnostics.presentManifest()
                    }
                    Button("Recompute rules hash") {
                        RulesDiagnostics.recompute()
                    }
                }

                Section("Compliance & Legal") {
                    Picker("Compliance mode", selection: $complianceMode) {
                        ForEach(ComplianceMode.allCases) { m in Text(m.label).tag(m.rawValue) }
                    }
                    .disabled(ComplianceMode(rawValue: complianceMode) != .licensed_asam && !asamLicenseID.isEmpty)

                    SecureField("ASAM License ID (if licensed)", text: $asamLicenseID)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)

                    Toggle("Block ASAM templates in neutral mode", isOn: $templateGuard)
                    Picker("Export gate strictness", selection: $exportStrictness) {
                        ForEach(ExportStrictness.allCases) { s in Text(s.label).tag(s.rawValue) }
                    }
                }

                Section("Data, Privacy & Security") {
                    Toggle("Mask PHI in logs", isOn: $maskPHI)
                    Toggle("Screenshot redaction banner", isOn: $screenshotRedaction)
                    Toggle("Idle lock / Face ID", isOn: $idleLockEnabled)
                    Stepper(value: $idleLockTimeoutMin, in: 1...15) {
                        Text("Idle lock timeout: \(idleLockTimeoutMin) min")
                    }
                }

                Section("Export & PDF") {
                    Picker("Default paper size", selection: $paper) {
                        Text("Letter").tag("Letter"); Text("A4").tag("A4")
                    }
                    TextField("Default filename template", text: $fileNameTemplate)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Toggle("Flatten annotations", isOn: $flattenPDF)
                    Toggle("Embed rules manifest in PDF Info", isOn: $embedManifest)
                    Toggle("Include QR seal", isOn: $qrSeal)
                    Toggle("Neutral watermark (internal mode)", isOn: $neutralWatermark)
                }

                Section("Environment & Updates") {
                    Picker("Server", selection: $serverEnv) {
                        ForEach(ServerEnv.allCases) { e in Text(e.label).tag(e.rawValue) }
                    }
                    Toggle("Auto-update rules when online", isOn: $rulesAutoUpdate)
                    Button("Clear cached rules") { RulesDiagnostics.clearCache() }
                }

                Section("Programs Directory") {
                    Toggle("Filter LOC to available programs", isOn: $filterPrograms)
                    NavigationLink("Manage programs source") { ProgramsSourceView() }
                }

                Section("Localization & Units") {
                    Picker("Units", selection: $units) {
                        ForEach(UnitsOption.allCases) { u in Text(u.label).tag(u.rawValue) }
                    }
                    Picker("Time format", selection: $timeFormat) {
                        ForEach(TimeFormatOption.allCases) { t in Text(t.label).tag(t.rawValue) }
                    }
                }

                #if DEBUG
                Section("Developer / QA") {
                    Toggle("Show field breadcrumbs", isOn: $showBreadcrumbs)
                    Toggle("Diagnostics overlay", isOn: $diagnosticsOverlay)
                    NavigationLink("Field mapping inspector") { FieldMapInspector() }
                }
                #endif
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preference Applier (attach to app root)

struct AppPreferencesModifier: ViewModifier {
    @AppStorage(Keys.textSizeIndex) private var textSizeIndex: Int = TextSizeOption.standard.rawValue
    @AppStorage(Keys.highContrast)   private var highContrast = false
    @AppStorage(Keys.reduceMotion)   private var reduceMotion = false
    @AppStorage(Keys.biggerTargets)  private var biggerTargets = false

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(TextSizeOption(rawValue: textSizeIndex)?.dynamicType ?? .large)
            .accessibilityReduceMotion(reduceMotion)
            .environment(\.legibilityWeight, highContrast ? .bold : .regular)
            .environment(\.controlSize, biggerTargets ? .large : .regular)
    }
}

extension View {
    /// Apply global visual preferences (text size, contrast, motion, hit targets)
    func applyAppPreferences() -> some View {
        modifier(AppPreferencesModifier())
    }
}

// MARK: - Sheet detents helper (drag-to-resize behavior for sheets)

struct PreferredSheetDetents: ViewModifier {
    @AppStorage(Keys.defaultDetentIndex) private var detentIndex: Int = SheetDetentOption.comfort80.rawValue
    @State private var selection: PresentationDetent = .fraction(0.80)

    func body(content: Content) -> some View {
        let detents: [PresentationDetent] = [.fraction(0.60), .fraction(0.80), .large]
        let chosen = SheetDetentOption(rawValue: detentIndex)?.detent ?? .fraction(0.80)
        return content
            .presentationDetents(Set(detents), selection: $selection)
            .presentationDragIndicator(.visible)
            .onAppear { selection = chosen }
    }
}

extension View {
    /// Use inside `.sheet { ... }` to enable pullable Comfort/Full sizes based on settings.
    func applySheetPreferences() -> some View { modifier(PreferredSheetDetents()) }
}

// MARK: - Breadcrumb chip + modifier (Dev/QA)

struct BreadcrumbChip: View {
    let crumb: String
    let detail: FieldMapEntry?

    @State private var copied = false

    var body: some View {
        HStack(spacing: 6) {
            Text(crumb)
                .textSelection(.enabled)
            if let d = detail {
                Spacer(minLength: 4)
                Text(d.model_key).foregroundStyle(.secondary)
                if let pdf = d.pdf_field {
                    Text("• \(pdf)").foregroundStyle(.secondary)
                }
            }
        }
        .font(.system(.caption2, design: .monospaced))
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule().strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .onTapGesture {
            UIPasteboard.general.string = crumb
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { copied = false }
        }
        .overlay(alignment: .trailing) {
            if copied {
                Text("Copied").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.thinMaterial).clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
}

struct BreadcrumbModifier: ViewModifier {
    @AppStorage(Keys.showBreadcrumbs) private var show = false
    let crumb: String

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            content
            if show {
                BreadcrumbChip(crumb: crumb, detail: FieldMap.shared.entry(for: crumb))
            }
        }
    }
}

extension View {
    /// Adds a small monospaced crumb under a control in Dev/QA.
    func breadcrumb(_ crumb: String) -> some View {
        modifier(BreadcrumbModifier(crumb: crumb))
    }
}

// MARK: - Field map loader (mapping/fields_map.json)

struct FieldMapEntry: Codable, Identifiable {
    var id: String { anchor }
    let anchor: String
    let model_key: String
    let pdf_field: String?
    let rules_anchors: [String]
}

final class FieldMap {
    static let shared = FieldMap()
    private var table: [String: FieldMapEntry] = [:]

    private init() {
        guard let url = Bundle.main.url(forResource: "fields_map", withExtension: "json", subdirectory: "mapping"),
              let data = try? Data(contentsOf: url) else {
            // No mapping file yet – fine for early builds.
            return
        }
        if let dict = try? JSONDecoder().decode([String: FieldMapEntry].self, from: data) {
            table = dict
        }
    }

    func entry(for anchor: String) -> FieldMapEntry? { table[anchor] }
}

// MARK: - Stub views for detail pages referenced in Settings

struct ThresholdsManifestView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Clinical thresholds manifest")
                .font(.title3.bold())
            Text("Loaded from rules/clinical_thresholds.json")
                .foregroundStyle(.secondary)
            Spacer()
            Text("This page will list versions and the active range mappings used for reconciliation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct ProgramsSourceView: View {
    var body: some View {
        Form {
            Section("Programs source") {
                Text("Facility JSON (default)")
                Text("Remote directory feed (future)")
            }
        }
        .navigationTitle("Programs Source")
    }
}

// MARK: - Minimal Rules diagnostics hooks (safe even if services not linked)

enum RulesDiagnostics {
    static func presentManifest() {
        print("ℹ️ Show rules manifest UI (implement where RulesProvenance is available).")
    }
    static func recompute() {
        print("♻️ Recompute rules hash (call RulesChecksum.compute + RulesProvenanceTracker.recordRulesLoaded).")
    }
    static func clearCache() {
        print("🧹 Clear any cached rules data if you add caching later.")
    }
}
```

---

## How to wire it up

1. **Show Settings**
   Where you have your gear button:

```swift
@State private var showSettings = false

Button {
    showSettings = true
} label: {
    Image(systemName: "gearshape")
}
.sheet(isPresented: $showSettings) {
    SettingsView()
        .applySheetPreferences()      // ← pullable detents driven by settings
        .applyAppPreferences()        // ← respects text size, contrast, motion
}
```

2. **Apply global preferences to your whole app** (recommended)
   In `ASAMAssessmentApp` root:

```swift
var body: some Scene {
    WindowGroup {
        ContentView()
            .applyAppPreferences()    // text size / contrast / motion / target size
    }
}
```

3. **Use breadcrumbs on form fields** (Dev/QA only)

```swift
Stepper(value: $assessment.domainASeverity, in: 0...4) {
    Text("Adjust Severity")
}
.breadcrumb("dom.A.severity")   // shows crumb chip when Dev toggle is on
```

---

## Notes on your “pullable/resizable” ask

* iPad sheets can’t be resized by grabbing a corner, but **dragging the sheet** between detents is the native pattern.
* The modifier `.applySheetPreferences()` sets the detents (**60%**, **80%**, **Full**) **and shows the drag indicator**. The default detent (Comfort 80%) is stored in Settings and used for every sheet.

---

If you want, I can also drop a tiny `mapping/fields_map.json` starter and a `UnitTest` template that asserts every `rules/*.json` anchor appears in the mapping.


##

Awesome — I’ll drop the three concrete pieces you asked for:

* a **starter mapping file** (`mapping/fields_map.json`)
* a tiny **Field Map Inspector** view so Dev/QA can browse it in-app
* an **XCTest** that sanity-checks the mapping (lenient by default, strict if you flip an env var)

Add each file to your repo and the **app / test targets** as indicated.

---

# 1) `mapping/fields_map.json`  *(blue folder reference, app + tests)*

Create a folder `mapping/` at the project root (or inside `ios/ASAMAssessment/ASAMAssessment/`), then add it to Xcode as a **folder reference** (blue). Put this JSON file inside as `fields_map.json`.

```json
{
  "dom.A.severity": {
    "anchor": "dom.A.severity",
    "model_key": "assessment.domains[1].severity",
    "pdf_field": "D1.Severity",
    "rules_anchors": ["dom.A.severity"]
  },
  "dom.B.severity": {
    "anchor": "dom.B.severity",
    "model_key": "assessment.domains[2].severity",
    "pdf_field": "D2.Severity",
    "rules_anchors": ["dom.B.severity"]
  },
  "dom.C.severity": {
    "anchor": "dom.C.severity",
    "model_key": "assessment.domains[3].severity",
    "pdf_field": "D3.Severity",
    "rules_anchors": ["dom.C.severity"]
  },
  "dom.D.severity": {
    "anchor": "dom.D.severity",
    "model_key": "assessment.domains[4].severity",
    "pdf_field": "D4.Severity",
    "rules_anchors": ["dom.D.severity"]
  },
  "dom.E.severity": {
    "anchor": "dom.E.severity",
    "model_key": "assessment.domains[5].severity",
    "pdf_field": "D5.Severity",
    "rules_anchors": ["dom.E.severity"]
  },
  "dom.F.severity": {
    "anchor": "dom.F.severity",
    "model_key": "assessment.domains[6].severity",
    "pdf_field": "D6.Severity",
    "rules_anchors": ["dom.F.severity"]
  },

  "flags.vitals_unstable": {
    "anchor": "flags.vitals_unstable",
    "model_key": "assessment.flags.vitalsUnstable",
    "pdf_field": "Flags.VitalsUnstable",
    "rules_anchors": ["flags.vitals_unstable"]
  },
  "flags.pregnant": {
    "anchor": "flags.pregnant",
    "model_key": "assessment.flags.pregnant",
    "pdf_field": "Flags.Pregnant",
    "rules_anchors": ["flags.pregnant"]
  },
  "flags.no_withdrawal": {
    "anchor": "flags.no_withdrawal",
    "model_key": "assessment.flags.noWithdrawalSigns",
    "pdf_field": "Flags.NoWithdrawalSigns",
    "rules_anchors": ["flags.no_withdrawal"]
  },
  "flags.acute_psych": {
    "anchor": "flags.acute_psych",
    "model_key": "assessment.flags.acutePsych",
    "pdf_field": "Flags.AcutePsych",
    "rules_anchors": ["flags.acute_psych"]
  },

  "substance.opioid.cows": {
    "anchor": "substance.opioid.cows",
    "model_key": "assessment.substances.opioid.cowsScore",
    "pdf_field": "D1.COWS",
    "rules_anchors": ["substance.opioid.cows", "d1.withdrawal.cows"]
  },
  "substance.alcohol.ciwa": {
    "anchor": "substance.alcohol.ciwa",
    "model_key": "assessment.substances.alcohol.ciwaScore",
    "pdf_field": "D1.CIWA",
    "rules_anchors": ["substance.alcohol.ciwa", "d1.withdrawal.ciwa"]
  },
  "substance.opioid.last_use_hours": {
    "anchor": "substance.opioid.last_use_hours",
    "model_key": "assessment.substances.opioid.lastUseHours",
    "pdf_field": "D1.LastUse.Opioid.Hours",
    "rules_anchors": ["substance.opioid.last_use_hours"]
  },
  "substance.alcohol.last_use_hours": {
    "anchor": "substance.alcohol.last_use_hours",
    "model_key": "assessment.substances.alcohol.lastUseHours",
    "pdf_field": "D1.LastUse.Alcohol.Hours",
    "rules_anchors": ["substance.alcohol.last_use_hours"]
  },

  "loc.recommendation.code": {
    "anchor": "loc.recommendation.code",
    "model_key": "assessment.locRecommendation.code",
    "pdf_field": "LOC.Code",
    "rules_anchors": ["loc.recommendation.code"]
  },
  "wm.candidates": {
    "anchor": "wm.candidates",
    "model_key": "assessment.wmCandidates[]",
    "pdf_field": "WM.Candidates",
    "rules_anchors": ["wm.candidates", "wm.indicated"]
  },

  "validation.complete": {
    "anchor": "validation.complete",
    "model_key": "assessment.isComplete",
    "pdf_field": "Validation.Complete",
    "rules_anchors": []
  },

  "provenance.rules_hash": {
    "anchor": "provenance.rules_hash",
    "model_key": "provenance.rulesetHash",
    "pdf_field": "Footer.RulesHash",
    "rules_anchors": []
  },
  "provenance.legal_version": {
    "anchor": "provenance.legal_version",
    "model_key": "provenance.legalNoticeVersion",
    "pdf_field": "Footer.LegalVersion",
    "rules_anchors": []
  }
}
```

> This is a **starter**: add entries whenever you introduce a new anchor or PDF field. The `rules_anchors` array is where you can list any rule-side names that reference the same concept.

---

# 2) `Views/FieldMapInspector.swift`  *(app target)*

Add this file so the “Field mapping inspector” link in Settings actually shows something useful.

```swift
//
//  FieldMapInspector.swift
//  ASAMAssessment
//

import SwiftUI

struct FieldMapInspector: View {
    @State private var search = ""
    private var entries: [FieldMapEntry] {
        FieldMap.shared.all()
            .filter { e in
                guard !search.isEmpty else { return true }
                let hay = (e.anchor + " " + e.model_key + " " + (e.pdf_field ?? "") + " " + e.rules_anchors.joined(separator: " ")).lowercased()
                return hay.contains(search.lowercased())
            }
            .sorted { $0.anchor < $1.anchor }
    }

    var body: some View {
        List {
            ForEach(entries) { e in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(e.anchor).font(.system(.callout, design: .monospaced).weight(.semibold))
                        Spacer()
                        if let pdf = e.pdf_field, !pdf.isEmpty {
                            Text(pdf).foregroundStyle(.secondary).font(.caption2.monospaced())
                        }
                    }
                    Text(e.model_key).font(.caption.monospaced())
                    if !e.rules_anchors.isEmpty {
                        Text("rules: " + e.rules_anchors.joined(separator: ", "))
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .searchable(text: $search)
        .navigationTitle("Field Mapping")
    }
}

// Extend FieldMap with helpers used above
extension FieldMap {
    func all() -> [FieldMapEntry] { Array(table.values) }
}
```

> **Note:** `FieldMap` was defined in the earlier `SettingsView.swift` I gave you. This inspector just reads it.

---

# 3) `ASAMAssessmentTests/FieldMappingTests.swift`  *(test target)*

This test is **lenient by default** (it guarantees core anchors exist and the JSON is valid).
Set env var `STRICT_ANCHORS=1` in the test scheme to make it **fail** if any discovered rule anchors are missing from the mapping.

```swift
//
//  FieldMappingTests.swift
//  ASAMAssessmentTests
//

import XCTest

final class FieldMappingTests: XCTestCase {

    // MARK: - Helpers

    private func loadData(resource: String, ext: String, subdir: String?, bundle: Bundle) throws -> Data {
        if let url = bundle.url(forResource: resource, withExtension: ext, subdirectory: subdir) {
            return try Data(contentsOf: url)
        }
        // Try fallback (flattened bundle)
        if let url = bundle.url(forResource: resource, withExtension: ext) {
            return try Data(contentsOf: url)
        }
        throw XCTSkip("Missing \(resource).\(ext) in bundle (subdir: \(subdir ?? "nil")).")
    }

    private func mappingDict(_ bundle: Bundle) throws -> [String: Any] {
        let data = try loadData(resource: "fields_map", ext: "json", subdir: "mapping", bundle: bundle)
        let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        XCTAssertNotNil(obj, "fields_map.json is not a dictionary at top-level.")
        return obj ?? [:]
    }

    /// Very tolerant anchor discovery: prefers rules/anchors.json if present; otherwise regex-scrapes other rule files.
    private func discoverRuleAnchors(_ bundle: Bundle) -> Set<String> {
        var anchors = Set<String>()

        // 1) Prefer explicit index
        if let url = bundle.url(forResource: "anchors", withExtension: "json", subdirectory: "rules"),
           let data = try? Data(contentsOf: url),
           let obj = try? JSONSerialization.jsonObject(with: data, options: []) {

            if let arr = obj as? [String] {
                anchors.formUnion(arr)
            } else if let dict = obj as? [String: Any] {
                anchors.formUnion(dict.keys)
                if let inner = dict["anchors"] as? [String] { anchors.formUnion(inner) }
            }
        }

        // 2) Heuristic regex across other rules files (best-effort)
        let ruleFiles = [
            ("wm_ladder","json"),
            ("loc_indication.guard","json"),
            ("validation_rules","json"),
            ("operators","json")
        ]
        let patterns = [
            #"dom\.[A-F]\.([a-zA-Z0-9_]+)"#,
            #"flags\.[a-zA-Z0-9_]+"#,
            #"substance\.[a-zA-Z0-9_\.]+"#,
            #"loc\.recommendation\.code"#,
            #"wm\.[a-zA-Z0-9_]+"#
        ]

        for (name, ext) in ruleFiles {
            if let data = try? loadData(resource: name, ext: ext, subdir: "rules", bundle: bundle),
               let str = String(data: data, encoding: .utf8) {
                for pat in patterns {
                    if let rx = try? NSRegularExpression(pattern: pat, options: []) {
                        let range = NSRange(str.startIndex..<str.endIndex, in: str)
                        for m in rx.matches(in: str, options: [], range: range) {
                            if let r = Range(m.range, in: str) {
                                anchors.insert(String(str[r]))
                            }
                        }
                    }
                }
            }
        }

        return anchors
    }

    // MARK: - Tests

    func test_mappingLoadsAndHasBaselineAnchors() throws {
        let bundle = Bundle(for: type(of: self))
        let map = try mappingDict(bundle)

        // Baseline anchors that MUST exist for our UI to map sensibly.
        let must = [
            "dom.A.severity","dom.B.severity","dom.C.severity",
            "dom.D.severity","dom.E.severity","dom.F.severity",
            "flags.vitals_unstable","flags.pregnant","flags.no_withdrawal","flags.acute_psych",
            "substance.opioid.cows","substance.alcohol.ciwa"
        ]

        for key in must {
            XCTAssertNotNil(map[key], "fields_map.json missing baseline key: \(key)")
        }
    }

    func test_discoveredAnchorsAreMostlyMapped_lenientByDefault() throws {
        let bundle = Bundle(for: type(of: self))
        let map = try mappingDict(bundle)
        let discovered = discoverRuleAnchors(bundle)

        // What the mapping currently knows:
        let mapped = Set(map.keys)

        // We allow gaps but keep an eye on them:
        let missing = discovered.subtracting(mapped)

        let strict = (ProcessInfo.processInfo.environment["STRICT_ANCHORS"] == "1")
        if strict {
            XCTAssertTrue(missing.isEmpty, "Unmapped rule anchors found: \(missing.sorted())")
        } else {
            // Lenient: don’t fail, but print a helpful note.
            if !missing.isEmpty {
                print("ℹ️ Unmapped rule anchors (lenient mode): \(missing.sorted())")
            }
            XCTAssertTrue(mapped.count >= 12, "Mapping is too small; add more anchors.")
        }
    }
}
```

---

## Wire-up checklist (super short)

1. **Add `mapping/` as a blue folder reference** (like you did for `rules/`).

   * Targets: **ASAMAssessment** and **ASAMAssessmentTests**
   * Verify it appears in “Copy Bundle Resources”.

2. **Add** `FieldMapInspector.swift` (app target).

   * Settings → Developer / QA → “Field mapping inspector” will open this.

3. **Add** `FieldMappingTests.swift` (test target).

   * Optional: in your Test scheme’s Environment, set `STRICT_ANCHORS=1` to turn on strict mode.

4. **Run tests**

   * `xcodebuild test …` or ⌘U.
   * You should see the lenient anchor report; switch to strict when the map is fleshed out.

---

## How this helps right away

* You get **visible breadcrumbs** in the UI (toggle in Settings) and a searchable **Field Mapping Inspector**.
* QA can confirm that every field has a **model → pdf → rules** thread (the “breadcrumb”).
* CI can become strict any time by flipping `STRICT_ANCHORS` to 1.
* If someone breaks the bundle layout again, tests still run (we try both subdir and fallback).

If you want, I can also add a tiny **pre-commit hook** that diffs `rules/*` and blocks commits when new anchors don’t exist in `mapping/fields_map.json`.
