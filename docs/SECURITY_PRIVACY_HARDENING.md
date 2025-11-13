# ASAM App: Security, Privacy & Production Hardening - Implementation Guide

**Created**: November 13, 2025  
**Status**: Critical Additions to Master TODO  
**Priority**: P0+ (Security & Compliance)  
**Effort**: 16-20 hours (add to 4-day sprint)

---

## 🔒 CRITICAL SECURITY GAPS (Add to P0)

### Gap 1: Encrypted Local Storage
**Status**: ❌ MISSING - Security Risk  
**Effort**: 3-4 hours  
**Blocking**: Demo deployment

**Implementation**:

```swift
// File: ios/ASAMAssessment/ASAMAssessment/Services/SecureStore.swift
import Foundation
import Security

final class SecureStore {
    static let shared = SecureStore()
    private let keyTag = "org.asam.demo.local.aeskey"
    
    func aesKey() throws -> Data {
        if let existing = try? readKey() { return existing }
        var key = Data(count: 32) // AES-256
        _ = key.withUnsafeMutableBytes { 
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) 
        }
        try writeKey(key)
        return key
    }
    
    private func writeKey(_ key: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: key
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { 
            throw NSError(domain: "Keychain", code: Int(status)) 
        }
    }
    
    private func readKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { 
            throw NSError(domain: "Keychain", code: Int(status)) 
        }
        return data
    }
}

extension URL {
    func markNoBackup() {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? self.setResourceValues(values)
    }
}

// Usage in StorageExporter:
func setupStorageDirectory() throws {
    let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("ASAM")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    url.markNoBackup() // Exclude from iCloud backup
}
```

**Tasks**:
- [ ] Create `SecureStore.swift`
- [ ] Generate AES-256 key on first launch
- [ ] Store in Keychain with `.afterFirstUnlockThisDeviceOnly`
- [ ] Mark storage folder `.isExcludedFromBackup = true`
- [ ] Add "Purge All PHI" button in Settings
- [ ] Test: Verify no iCloud backup, key survives app restart

---

### Gap 2: Audit Log (Append-Only)
**Status**: ❌ MISSING - Compliance Risk  
**Effort**: 2-3 hours  
**Blocking**: Emergency banner compliance

**Implementation**:

```swift
// File: ios/ASAMAssessment/ASAMAssessment/Services/AuditLog.swift
import Foundation

struct AuditEvent: Codable {
    let timestamp: Date
    let sessionId: String
    let userId: String // clinicianName from header
    let action: String // "field_change", "emergency_open", "emergency_dismiss", "severity_override"
    let target: String // field path or banner ID
    let oldValue: String?
    let newValue: String?
    let metadata: [String: String]? // extra context
}

final class AuditLog {
    static let shared = AuditLog()
    
    func append(_ event: AuditEvent, for assessmentId: String) {
        let url = logURL(for: assessmentId)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let json = try? encoder.encode(event),
              let line = String(data: json, encoding: .utf8) else { return }
        
        let lineWithNewline = line + "\n"
        
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(lineWithNewline.data(using: .utf8)!)
                handle.closeFile()
            }
        } else {
            try? lineWithNewline.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    private func logURL(for assessmentId: String) -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ASAM/assessments/\(assessmentId)/audit.log")
    }
}

// Usage examples:
// 1. Field change
AuditLog.shared.append(AuditEvent(
    timestamp: Date(),
    sessionId: assessment.id,
    userId: assessment.header.clinicianName,
    action: "field_change",
    target: "d3.suicidalIdeation.value",
    oldValue: "false",
    newValue: "true",
    metadata: nil
), for: assessment.id)

// 2. Emergency banner
AuditLog.shared.append(AuditEvent(
    timestamp: Date(),
    sessionId: assessment.id,
    userId: assessment.header.clinicianName,
    action: "emergency_open",
    target: "d3_suicidal_today",
    oldValue: nil,
    newValue: "banner_shown",
    metadata: ["minSeverity": "3"]
), for: assessment.id)

// 3. Severity override
AuditLog.shared.append(AuditEvent(
    timestamp: Date(),
    sessionId: assessment.id,
    userId: assessment.header.clinicianName,
    action: "severity_override",
    target: "d3.severity.chosen",
    oldValue: "3",
    newValue: "4",
    metadata: ["rationale": "Active SI with plan + access to means"]
), for: assessment.id)
```

**Tasks**:
- [ ] Create `AuditLog.swift` with JSONL append
- [ ] Log all field changes (old → new)
- [ ] Log emergency banner open/dismiss
- [ ] Log severity overrides with rationale
- [ ] Add to export bundle
- [ ] Test: Verify append-only, survives crashes

---

### Gap 3: Ruleset Versioning
**Status**: ❌ MISSING - Export Reproducibility Risk  
**Effort**: 1-2 hours  
**Blocking**: PDF export compliance

**Implementation**:

```swift
// File: ios/ASAMAssessment/ASAMAssessment/Models/Assessment.swift
struct Assessment: Codable {
    let id: String
    let createdAt: Date
    let appVersion: String // "1.3.0"
    let build: String       // "2025.11.13.1"
    let ruleset: String     // "v2.0.0" ← NEW
    
    var header: IntakeHeader
    var domains: [Domain]
    // ... rest of model
}

// File: ios/ASAMAssessment/ASAMAssessment/Services/StorageExporter.swift
struct ExportEnvelope: Codable {
    let id: String
    let createdAt: Date
    let appVersion: String
    let build: String
    let ruleset: String           // ← Persist for reproducibility
    let rulesetChecksum: String   // SHA-256 of ValidationMatrix.rules
    let header: IntakeHeader
    let answers: [String: CodableValue]
    let computed: ComputedBundle
    let audit: [AuditEvent]
}

// Checksum helper
extension ValidationMatrix {
    static var checksum: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try! encoder.encode(rules.map { String(describing: $0) })
        return data.sha256Hex
    }
}
```

**Tasks**:
- [ ] Add `ruleset` field to Assessment
- [ ] Set to `"v2.0.0"` on creation
- [ ] Add `rulesetChecksum` (SHA-256 of rules)
- [ ] Include in export envelope
- [ ] Add to frozen bundle.json
- [ ] Test: Verify PDF reproducibility after rule changes

---

## 🔐 ENHANCED INTAKE HEADER

### Updated Model with Rigor

```swift
// File: ios/ASAMAssessment/ASAMAssessment/Models/IntakeHeader.swift
import Foundation

struct IntakeHeader: Codable, Equatable {
    // Patient Identifiers
    var patientName: String = ""
    var dob: Date? = nil
    var sexAtBirth: String = ""      // "M", "F", "Other"
    var sexAtBirthOther: String? = nil
    
    // Medical Record Numbers
    var mrn: String = ""             // Medical Record Number
    var fin: String = ""             // Financial/Encounter ID
    var encounterId: String? = nil   // Separate from FIN when both exist
    
    // Session Metadata
    var sessionId: String             // Auto-generated: "ASAM_20251113_143022"
    var encounterDateTime: Date = Date()
    var timezone: String = TimeZone.current.identifier // "America/New_York"
    
    // Facility & Clinician
    var location: String = ""
    var facility: String = ""
    var clinicianName: String = ""
    var clinicianCredentials: String = ""
    var clinicianNPI: String? = nil
    
    // Consent
    var consentSigned: Bool = false
    var consentTimestamp: Date? = nil
    var consentMethod: String? = nil  // "verbal", "written", "electronic"
    
    init() {
        self.sessionId = Self.generateSessionId()
    }
    
    static func generateSessionId() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "ASAM_\(formatter.string(from: Date()))"
    }
}

extension IntakeHeader {
    var isComplete: Bool {
        guard let _ = dob else { return false }
        
        let requiredFieldsPresent = !patientName.isEmpty && 
                                    !sexAtBirth.isEmpty && 
                                    !mrn.isEmpty && 
                                    !fin.isEmpty &&
                                    !location.isEmpty && 
                                    !clinicianName.isEmpty && 
                                    !clinicianCredentials.isEmpty && 
                                    consentSigned
        
        // If "Other" selected, require specification
        if sexAtBirth == "Other" && (sexAtBirthOther?.isEmpty ?? true) {
            return false
        }
        
        return requiredFieldsPresent
    }
    
    // Validation helpers
    func validateMRN() -> ValidationError? {
        // Normalize: remove spaces, hyphens
        let normalized = mrn.replacingOccurrences(of: "[\\s-]", with: "", options: .regularExpression)
        if normalized.isEmpty { return ValidationError(field: "mrn", message: "MRN required") }
        // Add facility-specific MRN format validation here
        return nil
    }
    
    func validateDOB() -> ValidationError? {
        guard let dob = dob else { return ValidationError(field: "dob", message: "DOB required") }
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        if age < 0 { return ValidationError(field: "dob", message: "DOB cannot be in future") }
        if age > 120 { return ValidationError(field: "dob", message: "DOB seems invalid (age > 120)") }
        return nil
    }
}
```

**Tasks**:
- [ ] Add `encounterId` separate from `fin`
- [ ] Add `sessionId` auto-generation
- [ ] Add `timezone` capture
- [ ] Add MRN/FIN normalization and validation
- [ ] Add DOB range validation
- [ ] Add facility and NPI fields
- [ ] Test: Verify all validations work

---

## 📐 COMPACT PATIENT HEADER (Sticky)

**Show above every dimension form**:

```swift
// File: ios/ASAMAssessment/ASAMAssessment/Views/CompactPatientHeader.swift
import SwiftUI

struct CompactPatientHeader: View {
    let header: IntakeHeader
    
    var body: some View {
        HStack(spacing: 16) {
            // Patient Name + Icon
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text(header.patientName)
                    .font(.headline)
            }
            
            Divider()
            
            // DOB + Age
            if let dob = header.dob {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DOB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(dob.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                    Text("Age \(age(from: dob))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // MRN
            VStack(alignment: .leading, spacing: 2) {
                Text("MRN")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(header.mrn)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Divider()
            
            // Session ID
            VStack(alignment: .leading, spacing: 2) {
                Text("Session")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(header.sessionId)
                    .font(.system(.caption, design: .monospaced))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    private func age(from dob: Date) -> Int {
        Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }
}

// Usage in QuestionnaireRenderer:
VStack(spacing: 0) {
    CompactPatientHeader(header: assessment.header)
        .accessibilityAddTraits(.isHeader)
    
    ScrollView {
        // ... existing questionnaire content
    }
}
```

**Tasks**:
- [ ] Create `CompactPatientHeader.swift`
- [ ] Show above all dimension forms
- [ ] Make sticky (stays visible on scroll)
- [ ] Test: Verify always visible, compact layout

---

## ⚙️ COMPREHENSIVE SETTINGS MODEL

```swift
// File: ios/ASAMAssessment/ASAMAssessment/Models/AppSettings.swift
import Foundation

struct AppSettings: Codable {
    // Privacy & Security
    var privacy = PrivacySettings()
    
    // Storage & Persistence
    var storage = StorageSettings()
    
    // Export & PDF
    var export = ExportSettings()
    
    // UI & Display
    var ui = UISettings()
    
    // Input & Accessibility
    var input = InputSettings()
    
    // Telemetry & Analytics
    var telemetry = TelemetrySettings()
    
    // About (read-only)
    var about: AboutInfo
}

struct PrivacySettings: Codable {
    var appLock = false
    var lockTimeoutSeconds = 300          // 5 minutes
    var blurInSwitcher = true
    var excludeFromBackup = true
    var redactScreenshots = false
}

struct StorageSettings: Codable {
    var backend = "local"                 // "local", "cloud" (future)
    var autosaveSeconds = 30
    var retentionDays = 90
    var backupPath: String? = nil
    var allowImport = false
}

struct ExportSettings: Codable {
    var includeIdentifiers = true
    var redactFreeText = false
    var watermarkDraft = true
    var includeRationale = true
    var pdfTemplateVersion = "v1.0"
}

struct UISettings: Codable {
    var density = "comfortable"           // "compact", "comfortable", "spacious"
    var showGuidance = true
    var showFieldKeys = false             // Dev mode: show field paths
    var haptics = true
    var reduceMotion = false
    var highContrast = false
}

struct InputSettings: Codable {
    var bigNumberPad = false              // Larger number input
    var dateFormat = "MM/DD/YYYY"
    var timeFormat = "12h"                // "12h", "24h"
    var units = "imperial"                // "imperial", "metric"
}

struct TelemetrySettings: Codable {
    var analyticsOptIn = false
    var sendLogs = false
}

struct AboutInfo: Codable {
    let version: String                   // "1.3.0"
    let build: String                     // "2025.11.13.1"
    let ruleset: String                   // "v2.0.0"
    let copyright: String
    let license: String
}

// Persistence
extension AppSettings {
    static let shared = AppSettings.load()
    
    private static let fileURL: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ASAM/AppSettings.json")
    }()
    
    static func load() -> AppSettings {
        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings.default
        }
        return settings
    }
    
    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }
    
    static var `default`: AppSettings {
        AppSettings(about: AboutInfo(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            build: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
            ruleset: "v2.0.0",
            copyright: "© 2025 ASAM Project",
            license: "MIT"
        ))
    }
}
```

**Tasks**:
- [ ] Create `AppSettings.swift`
- [ ] Create `SettingsView.swift` with 7 sections
- [ ] Persist to Application Support (NOT Documents)
- [ ] Wire privacy settings (app lock, blur, backup exclusion)
- [ ] Wire UI settings (density, guidance, haptics)
- [ ] Add "Purge All PHI" button in Privacy section
- [ ] Test: All settings persist and apply correctly

---

## 🎨 SETTINGS UI SECTIONS

```swift
// File: ios/ASAMAssessment/ASAMAssessment/Views/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    
    var body: some View {
        Form {
            // 1. Privacy & Security
            Section("Privacy & Security") {
                Toggle("App Lock", isOn: $settings.privacy.appLock)
                if settings.privacy.appLock {
                    Picker("Lock Timeout", selection: $settings.privacy.lockTimeoutSeconds) {
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                        Text("15 minutes").tag(900)
                    }
                }
                Toggle("Blur in App Switcher", isOn: $settings.privacy.blurInSwitcher)
                Toggle("Exclude from Backup", isOn: $settings.privacy.excludeFromBackup)
                Toggle("Redact Screenshots", isOn: $settings.privacy.redactScreenshots)
                
                Button("Purge All PHI", role: .destructive) {
                    // Confirm + delete all assessments
                }
            }
            
            // 2. Storage & Persistence
            Section("Storage & Persistence") {
                Picker("Autosave Interval", selection: $settings.storage.autosaveSeconds) {
                    Text("15 seconds").tag(15)
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                }
                Picker("Retention", selection: $settings.storage.retentionDays) {
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                    Text("1 year").tag(365)
                }
                Toggle("Allow Import", isOn: $settings.storage.allowImport)
            }
            
            // 3. Export & PDF
            Section("Export & PDF") {
                Toggle("Include Identifiers", isOn: $settings.export.includeIdentifiers)
                Toggle("Redact Free Text", isOn: $settings.export.redactFreeText)
                Toggle("Watermark Drafts", isOn: $settings.export.watermarkDraft)
                Toggle("Include Rationale", isOn: $settings.export.includeRationale)
            }
            
            // 4. Display & UI
            Section("Display & UI") {
                Picker("Density", selection: $settings.ui.density) {
                    Text("Compact").tag("compact")
                    Text("Comfortable").tag("comfortable")
                    Text("Spacious").tag("spacious")
                }
                Toggle("Show Guidance", isOn: $settings.ui.showGuidance)
                Toggle("Show Field Keys", isOn: $settings.ui.showFieldKeys)
                Toggle("Haptic Feedback", isOn: $settings.ui.haptics)
                Toggle("Reduce Motion", isOn: $settings.ui.reduceMotion)
                Toggle("High Contrast", isOn: $settings.ui.highContrast)
            }
            
            // 5. Input & Accessibility
            Section("Input & Accessibility") {
                Toggle("Large Number Pad", isOn: $settings.input.bigNumberPad)
                Picker("Date Format", selection: $settings.input.dateFormat) {
                    Text("MM/DD/YYYY").tag("MM/DD/YYYY")
                    Text("DD/MM/YYYY").tag("DD/MM/YYYY")
                    Text("YYYY-MM-DD").tag("YYYY-MM-DD")
                }
                Picker("Time Format", selection: $settings.input.timeFormat) {
                    Text("12-hour").tag("12h")
                    Text("24-hour").tag("24h")
                }
            }
            
            // 6. Analytics & Telemetry
            Section("Analytics & Telemetry") {
                Toggle("Analytics Opt-In", isOn: $settings.telemetry.analyticsOptIn)
                Toggle("Send Logs", isOn: $settings.telemetry.sendLogs)
            }
            
            // 7. About
            Section("About") {
                LabeledContent("Version", value: settings.about.version)
                LabeledContent("Build", value: settings.about.build)
                LabeledContent("Ruleset", value: settings.about.ruleset)
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                Link("Open Source Licenses", destination: URL(string: "https://example.com/licenses")!)
            }
        }
        .navigationTitle("Settings")
        .onChange(of: settings) { _, newSettings in
            newSettings.save()
        }
    }
}
```

---

## 🧪 ADDITIONAL TEST COVERAGE

### 1. FORM_FIELD_MAP Coverage Test

```swift
// File: ios/ASAMAssessment/ASAM_IOS_APPTests/FormFieldMapCoverageTests.swift
import XCTest
@testable import ASAMAssessment

final class FormFieldMapCoverageTests: XCTestCase {
    func testAllFieldPathsHaveMapping() throws {
        // Load FORM_FIELD_MAP.json
        let mapURL = Bundle.main.url(forResource: "FORM_FIELD_MAP", withExtension: "json")!
        let mapData = try Data(contentsOf: mapURL)
        let map = try JSONDecoder().decode([String: String].self, from: mapData)
        
        // Get all field paths from Assessment
        let fieldPaths = Assessment.allFieldPaths()
        
        // Check coverage
        let unmapped = fieldPaths.filter { !map.keys.contains($0) && !isExplicitlyIgnored($0) }
        
        XCTAssertTrue(unmapped.isEmpty, """
        Found \(unmapped.count) unmapped field paths:
        \(unmapped.joined(separator: "\n"))
        
        Add to FORM_FIELD_MAP.json or mark as ignored.
        """)
    }
    
    private func isExplicitlyIgnored(_ path: String) -> Bool {
        let ignored = ["id", "createdAt", "appVersion", "build", "ruleset"]
        return ignored.contains(path)
    }
}
```

### 2. Storage Corruption Test

```swift
// File: ios/ASAMAssessment/ASAM_IOS_APPTests/StorageCorruptionTests.swift
import XCTest
@testable import ASAMAssessment

final class StorageCorruptionTests: XCTestCase {
    func testCorruptedJSONRecovery() throws {
        // Create valid assessment
        let assessment = Assessment.fixture()
        let exporter = StorageExporter()
        try exporter.export(assessment, to: testDirectory)
        
        // Corrupt answers.json
        let answersURL = testDirectory.appendingPathComponent("\(assessment.id)/answers.json")
        try "{ corrupt json".write(to: answersURL, atomically: true, encoding: .utf8)
        
        // Attempt to load
        let result = try? Assessment.load(from: testDirectory.appendingPathComponent(assessment.id))
        
        XCTAssertNil(result, "Should fail gracefully on corrupted JSON")
        
        // Verify error message is user-friendly
        // (Test UI error handling here)
    }
    
    func testLowStorageHandling() throws {
        // Mock low storage condition
        // Verify graceful degradation
    }
}
```

### 3. Property-Based Tests for ValidationMatrix

```swift
// File: ios/ASAMAssessment/ASAM_IOS_APPTests/ValidationMatrixPropertyTests.swift
import XCTest
@testable import ASAMAssessment

final class ValidationMatrixPropertyTests: XCTestCase {
    func testRuleEvaluationIdempotent() {
        // Property: Applying same state twice should yield same result
        let assessment = Assessment.fixture()
        let matrix = ValidationMatrix()
        
        let result1 = matrix.apply(to: assessment, from: assessment)
        let result2 = matrix.apply(to: assessment, from: assessment)
        
        XCTAssertEqual(result1, result2, "Rule evaluation must be idempotent")
    }
    
    func testTTLMonotonicDecay() {
        // Property: TTL never increases, only decreases or expires
        // Test with multiple time points
    }
}
```

---

## 📱 LEFT RAIL & SESSIONS UX

### Acceptance Criteria

```swift
// File: ios/ASAMAssessment/ASAMAssessment/Views/MainNavigationView.swift
import SwiftUI

struct MainNavigationView: View {
    @State private var selectedSession: Assessment?
    @State private var selectedDimension: Int?
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // Column 1: Sessions List
            SessionsListView(selection: $selectedSession)
                .frame(minWidth: 280)
                .navigationTitle("Sessions")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            // New session
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .searchable(text: .constant(""))
        } content: {
            // Column 2: Assessment Navigator
            if let session = selectedSession {
                AssessmentNavigatorView(
                    assessment: session,
                    selectedDimension: $selectedDimension
                )
                .frame(minWidth: 240)
            }
        } detail: {
            // Column 3: Form
            if let dimension = selectedDimension {
                QuestionnaireRenderer(dimension: dimension)
                    .frame(minWidth: 600)
            }
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        // Cmd+J: Jump to Sessions
        // Cmd+1..8: Jump to dimension
        // Cmd+E: Export
    }
}

struct SessionsListView: View {
    @Binding var selection: Assessment?
    @State private var searchText = ""
    @State private var filter: FilterOption = .all
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case inProgress = "In Progress"
        case complete = "Complete"
        case flagged = "Flagged"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $filter) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Sessions List
            List(filteredSessions, selection: $selection) { session in
                SessionRowView(session: session)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            // Delete session
                        }
                        Button("Export") {
                            // Export PDF
                        }
                        .tint(.blue)
                    }
            }
        }
        .searchable(text: $searchText, prompt: "Search by name, MRN, or date")
    }
    
    private var filteredSessions: [Assessment] {
        // Filter logic
        []
    }
}

struct SessionRowView: View {
    let session: Assessment
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress Ring
            ProgressRing(progress: session.progress)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.header.patientName)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text("MRN: \(session.header.mrn)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Severity Dot
            if let maxSeverity = session.maxSeverity {
                Circle()
                    .fill(severityColor(maxSeverity))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 4: return .red
        case 3: return .orange
        case 2: return .yellow
        case 1: return .blue
        default: return .gray
        }
    }
}
---

## 11. Severity Auto-Calculation + Clinician Override (P0+)

### Problem
- No automatic severity calculation from questionnaire answers
- No structured override system with audit trail
- Risk of inconsistent severity assignments
- No emergency floor constraints

### Solution: Auto-Calculate + Override with Attestation

**Data Model Additions:**

```swift
// MARK: - Severity Override
struct SeverityOverride: Codable, Identifiable {
    var id: UUID = .init()
    var enabled: Bool
    var value: Int             // 0...4
    var reason: String         // min 15 chars
    var category: OverrideCategory
    var createdBy: UserRef
    var createdAt: Date
    var acknowledgesEmergency: Bool // must be true if any emergency floors apply
}

enum OverrideCategory: String, Codable, CaseIterable {
    case clinicalJudgment = "Clinical Judgment"
    case incompleteData = "Incomplete Data"
    case falsePositiveTrigger = "False Positive Trigger"
    case patientSafety = "Patient Safety"
    case other = "Other"
}

struct UserRef: Codable {
    var userId: String
    var name: String
    var role: String
}

// MARK: - Domain State
struct DomainState: Codable {
    var computedSeverity: Int? // auto-calculated from answers
    var minFloor: Int?         // from Emergency + ValidationMatrix
    var override: SeverityOverride? // nil if none
    
    var finalSeverity: Int {   // read-only derived
        let base = max(computedSeverity ?? 0, minFloor ?? 0)
        if let o = override, o.enabled {
            return max(o.value, minFloor ?? 0)
        }
        return base
    }
}

// MARK: - Assessment Severity
struct AssessmentSeverity: Codable {
    var domains: [DomainState] // D1...D6
    var computedOverall: Int   // policy: max of domain finals, or custom rubric
    var overallOverride: SeverityOverride? // same rules as above
    
    var finalOverall: Int {
        if let o = overallOverride, o.enabled { 
            return max(o.value, computedOverall) 
        }
        return computedOverall
    }
}
```

**Severity Calculation Logic:**

```swift
// MARK: - Severity Calculator
class SeverityCalculator {
    
    /// Calculate severity for a dimension based on answers
    func calculateSeverity(for dimension: Domain) -> Int {
        var severity = 0
        
        switch dimension.type {
        case .d1_acute_intox_withdrawal:
            severity = calculateD1Severity(dimension)
        case .d2_biomedical:
            severity = calculateD2Severity(dimension)
        case .d3_emotional:
            severity = calculateD3Severity(dimension)
        case .d4_readiness:
            severity = calculateD4Severity(dimension)
        case .d5_relapse:
            severity = calculateD5Severity(dimension)
        case .d6_recovery_environment:
            severity = calculateD6Severity(dimension)
        }
        
        return min(max(severity, 0), 4) // clamp 0-4
    }
    
    // MARK: - D1: Acute Intoxication/Withdrawal
    private func calculateD1Severity(_ domain: Domain) -> Int {
        var severity = 0
        
        // Check withdrawal symptoms
        if domain.answers["withdrawal_symptoms"] == .bool(true) {
            if domain.answers["withdrawal_severity"] == .string("Severe") {
                severity = 4
            } else if domain.answers["withdrawal_severity"] == .string("Moderate") {
                severity = 3
            } else {
                severity = 2
            }
        }
        
        // Check recent use (last 48h)
        if domain.answers["used_last_48h"] == .bool(true) {
            severity = max(severity, 2)
        }
        
        // Emergency trigger: severe withdrawal + recent use
        if severity >= 3 && domain.answers["used_last_48h"] == .bool(true) {
            severity = 4
        }
        
        return severity
    }
    
    // MARK: - D2: Biomedical Conditions
    private func calculateD2Severity(_ domain: Domain) -> Int {
        var severity = 0
        
        // Life-threatening conditions
        if domain.answers["life_threatening_condition"] == .bool(true) {
            return 4
        }
        
        // Pregnancy + substance use
        if domain.answers["pregnant"] == .bool(true) {
            if domain.answers["trimester"] == .string("Third") {
                severity = max(severity, 3)
            }
        }
        
        // Drug-drug interactions
        if domain.answers["benzo_use"] == .bool(true) && 
           domain.answers["buprenorphine_use"] == .bool(true) {
            severity = max(severity, 3)
        }
        
        // Chronic conditions with poor management
        if domain.answers["chronic_condition_unmanaged"] == .bool(true) {
            severity = max(severity, 2)
        }
        
        return severity
    }
    
    // MARK: - D3: Emotional/Behavioral/Cognitive
    private func calculateD3Severity(_ domain: Domain) -> Int {
        var severity = 0
        
        // CRITICAL: Suicide assessment
        if domain.answers["suicidal_ideation_today"] == .bool(true) {
            if domain.answers["suicide_plan"] == .bool(true) && 
               domain.answers["suicide_intent"] == .bool(true) {
                return 4 // Emergency
            } else if domain.answers["suicide_plan"] == .bool(true) {
                severity = max(severity, 3)
            } else {
                severity = max(severity, 3)
            }
        }
        
        // CRITICAL: Duty to warn
        if domain.answers["homicidal_ideation_today"] == .bool(true) {
            if domain.answers["specific_target"] == .bool(true) {
                return 4 // Emergency
            } else {
                severity = max(severity, 3)
            }
        }
        
        // Psychosis symptoms
        if domain.answers["psychosis_symptoms"] == .bool(true) {
            severity = max(severity, 3)
        }
        
        // Mental health diagnosis + functional impairment
        if domain.answers["mental_health_diagnosis"] == .bool(true) &&
           domain.answers["functional_impairment"] == .string("Severe") {
            severity = max(severity, 3)
        }
        
        return severity
    }
    
    // MARK: - D4: Readiness to Change
    private func calculateD4Severity(_ domain: Domain) -> Int {
        var severity = 0
        
        // Calculate stage of change
        let stage = calculateStageOfChange(domain)
        
        switch stage {
        case "Precontemplation":
            severity = 3
        case "Contemplation":
            severity = 2
        case "Preparation":
            severity = 2
        case "Action":
            severity = 1
        case "Maintenance":
            severity = 1
        default:
            severity = 2
        }
        
        // Adjust for external pressure (reduces motivation)
        if domain.answers["motivation_source"] == .string("External only") {
            severity = min(severity + 1, 4)
        }
        
        // Adjust for barriers
        if domain.answers["barriers_count"]?.asInt ?? 0 >= 3 {
            severity = min(severity + 1, 4)
        }
        
        return severity
    }
    
    // MARK: - D5: Relapse/Continued Use
    private func calculateD5Severity(_ domain: Domain) -> Int {
        var severity = 0
        
        // Imminent relapse risk
        if domain.answers["relapse_timeframe"] == .string("Hours/Days") {
            return 4 // Emergency
        } else if domain.answers["relapse_timeframe"] == .string("Weeks") {
            severity = max(severity, 3)
        }
        
        // High-risk environment (cannot avoid)
        if domain.answers["high_risk_environment"] == .bool(true) &&
           domain.answers["can_avoid_environment"] == .bool(false) {
            severity = max(severity, 3)
        }
        
        // Poor coping skills
        let healthySkills = domain.answers["healthy_coping_count"]?.asInt ?? 0
        let unhealthySkills = domain.answers["unhealthy_coping_count"]?.asInt ?? 0
        if healthySkills <= 1 && unhealthySkills >= 2 {
            severity = max(severity, 3)
        }
        
        // Never in recovery
        if domain.answers["ever_in_recovery"] == .bool(false) {
            severity = max(severity, 2)
        }
        
        return severity
    }
    
    // MARK: - D6: Recovery/Living Environment
    private func calculateD6Severity(_ domain: Domain) -> Int {
        var severity = 0
        
        // Homelessness
        if domain.answers["housing_status"] == .string("Homeless") {
            return 4 // Emergency
        }
        
        // Domestic violence
        if domain.answers["domestic_violence"] == .bool(true) {
            if domain.answers["lethal_threat"] == .bool(true) {
                return 4 // Emergency
            } else {
                severity = max(severity, 3)
            }
        }
        
        // Unstable housing
        if domain.answers["housing_stable"] == .bool(false) {
            severity = max(severity, 3)
        }
        
        // No support system
        if domain.answers["support_system_quality"] == .string("None") {
            severity = max(severity, 2)
        }
        
        // Legal/financial crisis
        if domain.answers["legal_crisis"] == .bool(true) ||
           domain.answers["financial_crisis"] == .bool(true) {
            severity = max(severity, 2)
        }
        
        return severity
    }
    
    // MARK: - Helpers
    private func calculateStageOfChange(_ domain: Domain) -> String {
        // Auto-set: "Can stop anytime" → Precontemplation
        if domain.answers["can_stop_anytime"] == .bool(true) {
            return "Precontemplation"
        }
        
        // Check explicit stage if set
        if let stage = domain.answers["stage_of_change"]?.asString {
            return stage
        }
        
        // Infer from motivation + action
        let motivated = domain.answers["motivated_to_change"] == .bool(true)
        let takingAction = domain.answers["taking_action"] == .bool(true)
        
        if !motivated {
            return "Precontemplation"
        } else if motivated && !takingAction {
            return "Contemplation"
        } else if motivated && takingAction {
            return "Action"
        }
        
        return "Contemplation" // default
    }
    
    /// Calculate overall severity from all domains
    func calculateOverallSeverity(_ domains: [DomainState]) -> Int {
        // Policy: max of all domain finals
        return domains.map { $0.finalSeverity }.max() ?? 0
    }
}
```

**Override Application with Validation:**

```swift
// MARK: - Override Manager
class SeverityOverrideManager {
    
    enum ValidationError: Error, LocalizedError {
        case floorViolation(Int)
        case reasonTooShort
        case emergencyAckRequired
        
        var errorDescription: String? {
            switch self {
            case .floorViolation(let floor):
                return "Severity cannot be set below \(floor) due to active safety triggers."
            case .reasonTooShort:
                return "Reason must be at least 15 characters."
            case .emergencyAckRequired:
                return "You must acknowledge emergency constraints to apply this override."
            }
        }
    }
    
    /// Apply domain override with validation
    func applyDomainOverride(
        assessment: inout Assessment,
        dimension: Int,
        value: Int,
        reason: String,
        category: OverrideCategory,
        acknowledgesEmergency: Bool,
        user: UserRef
    ) throws {
        let domainState = assessment.severity.domains[dimension]
        let floor = domainState.minFloor ?? 0
        
        // Validate floor constraint
        guard value >= floor else {
            throw ValidationError.floorViolation(floor)
        }
        
        // Validate reason length
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedReason.count >= 15 else {
            throw ValidationError.reasonTooShort
        }
        
        // Require emergency acknowledgement if floor > 0
        if floor > 0 {
            guard acknowledgesEmergency else {
                throw ValidationError.emergencyAckRequired
            }
        }
        
        // Create override
        let override = SeverityOverride(
            enabled: true,
            value: value,
            reason: trimmedReason,
            category: category,
            createdBy: user,
            createdAt: Date(),
            acknowledgesEmergency: acknowledgesEmergency
        )
        
        // Apply and audit
        let oldValue = domainState.finalSeverity
        assessment.severity.domains[dimension].override = override
        
        AuditLog.shared.append(AuditEvent(
            timestamp: Date(),
            userId: user.userId,
            action: .domainOverrideSet,
            target: "D\(dimension + 1)",
            oldValue: String(oldValue),
            newValue: String(value),
            metadata: [
                "floor": String(floor),
                "reason": trimmedReason,
                "category": category.rawValue,
                "ack_emergency": String(acknowledgesEmergency)
            ]
        ))
        
        // Persist
        try assessment.save()
    }
    
    /// Reset domain override to auto
    func resetDomainOverride(
        assessment: inout Assessment,
        dimension: Int,
        user: UserRef
    ) throws {
        let oldOverride = assessment.severity.domains[dimension].override
        assessment.severity.domains[dimension].override = nil
        
        AuditLog.shared.append(AuditEvent(
            timestamp: Date(),
            userId: user.userId,
            action: .domainOverrideCleared,
            target: "D\(dimension + 1)",
            oldValue: oldOverride.map { String($0.value) } ?? "nil",
            newValue: "auto",
            metadata: [:]
        ))
        
        try assessment.save()
        
        // Show undo option
        UndoManager.shared.showUndo(
            message: "Override removed",
            bucket: "override_reset"
        ) {
            // Restore previous override
            assessment.severity.domains[dimension].override = oldOverride
            try? assessment.save()
        }
    }
    
    /// Apply overall override
    func applyOverallOverride(
        assessment: inout Assessment,
        value: Int,
        reason: String,
        category: OverrideCategory,
        acknowledgesEmergency: Bool,
        user: UserRef
    ) throws {
        let computed = assessment.severity.computedOverall
        
        // Cannot drop below computed
        guard value >= computed else {
            throw ValidationError.floorViolation(computed)
        }
        
        // Same validation as domain override
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedReason.count >= 15 else {
            throw ValidationError.reasonTooShort
        }
        
        let override = SeverityOverride(
            enabled: true,
            value: value,
            reason: trimmedReason,
            category: category,
            createdBy: user,
            createdAt: Date(),
            acknowledgesEmergency: acknowledgesEmergency
        )
        
        let oldValue = assessment.severity.finalOverall
        assessment.severity.overallOverride = override
        
        AuditLog.shared.append(AuditEvent(
            timestamp: Date(),
            userId: user.userId,
            action: .overallOverrideSet,
            target: "Overall",
            oldValue: String(oldValue),
            newValue: String(value),
            metadata: [
                "computed": String(computed),
                "reason": trimmedReason,
                "category": category.rawValue,
                "ack_emergency": String(acknowledgesEmergency)
            ]
        ))
        
        try assessment.save()
    }
}
```

**SwiftUI Views:**

```swift
// MARK: - Severity Override Sheet
struct SeverityOverrideSheet: View {
    @Binding var domainState: DomainState
    @State private var overrideEnabled = false
    @State private var overrideValue = 0
    @State private var reason = ""
    @State private var category: OverrideCategory = .clinicalJudgment
    @State private var acknowledgesEmergency = false
    @State private var errorMessage: String?
    
    let dimension: Int
    let currentUser: UserRef
    let onApply: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                // Current state
                Section("Current Severity") {
                    HStack {
                        Text("Auto-Calculated:")
                        Spacer()
                        SeverityChip(level: domainState.computedSeverity ?? 0, label: "Auto")
                    }
                    
                    if let floor = domainState.minFloor, floor > 0 {
                        HStack {
                            Text("Minimum Floor:")
                            Spacer()
                            SeverityChip(level: floor, label: "Floor")
                        }
                        .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("Final Severity:")
                        Spacer()
                        SeverityChip(level: domainState.finalSeverity, label: "Final")
                    }
                    .font(.headline)
                }
                
                // Override controls
                Section("Override") {
                    Toggle("Override severity", isOn: $overrideEnabled)
                    
                    if overrideEnabled {
                        Picker("New Severity", selection: $overrideValue) {
                            ForEach(0...4, id: \.self) { level in
                                Text("Severity \(level)").tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Picker("Category", selection: $category) {
                            ForEach(OverrideCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reason (min 15 characters)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $reason)
                                .frame(height: 80)
                                .border(Color.gray.opacity(0.3))
                            Text("\(reason.count) characters")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if let floor = domainState.minFloor, floor > 0 {
                            Toggle("I acknowledge emergency constraints", isOn: $acknowledgesEmergency)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Warnings
                if let floor = domainState.minFloor, floor > 0, overrideEnabled {
                    Section {
                        Label("Minimum allowed is \(floor) due to active safety triggers.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("D\(dimension + 1) Severity Override")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // dismiss
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyOverride()
                    }
                    .disabled(!canApply)
                }
            }
        }
    }
    
    var canApply: Bool {
        guard overrideEnabled else { return false }
        guard reason.trimmingCharacters(in: .whitespacesAndNewlines).count >= 15 else { return false }
        if let floor = domainState.minFloor, floor > 0 {
            guard acknowledgesEmergency else { return false }
            guard overrideValue >= floor else { return false }
        }
        return true
    }
    
    func applyOverride() {
        do {
            var assessment = Assessment.current // placeholder
            try SeverityOverrideManager().applyDomainOverride(
                assessment: &assessment,
                dimension: dimension,
                value: overrideValue,
                reason: reason,
                category: category,
                acknowledgesEmergency: acknowledgesEmergency,
                user: currentUser
            )
            onApply()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Severity Chip Component
struct SeverityChip: View {
    let level: Int
    let label: String
    
    var color: Color {
        switch level {
        case 0: return .gray
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(label): \(level)")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(8)
        }
    }
}
```

**Integration into Domain Views:**

```swift
// Add to each domain summary view
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Text("Severity")
            .font(.headline)
        Spacer()
        SeverityChip(level: domainState.computedSeverity ?? 0, label: "Auto")
        if domainState.override != nil {
            SeverityChip(level: domainState.finalSeverity, label: "Final")
            Image(systemName: "pencil.circle.fill")
                .foregroundColor(.orange)
        }
    }
    
    Button("Override Severity") {
        showOverrideSheet = true
    }
    .buttonStyle(.bordered)
}
.sheet(isPresented: $showOverrideSheet) {
    SeverityOverrideSheet(
        domainState: $domainState,
        dimension: dimensionIndex,
        currentUser: currentUser,
        onApply: {
            showOverrideSheet = false
            recalculateOverall()
        }
    )
}
```

### Testing

```swift
// MARK: - SeverityCalculationTests.swift
import XCTest

class SeverityCalculationTests: XCTestCase {
    
    func testD1_SevereWithdrawal_Returns4() {
        var domain = Domain(type: .d1_acute_intox_withdrawal)
        domain.answers["withdrawal_symptoms"] = .bool(true)
        domain.answers["withdrawal_severity"] = .string("Severe")
        domain.answers["used_last_48h"] = .bool(true)
        
        let severity = SeverityCalculator().calculateSeverity(for: domain)
        XCTAssertEqual(severity, 4)
    }
    
    func testD3_SuicidePlanIntent_Returns4() {
        var domain = Domain(type: .d3_emotional)
        domain.answers["suicidal_ideation_today"] = .bool(true)
        domain.answers["suicide_plan"] = .bool(true)
        domain.answers["suicide_intent"] = .bool(true)
        
        let severity = SeverityCalculator().calculateSeverity(for: domain)
        XCTAssertEqual(severity, 4)
    }
    
    func testOverride_BelowFloor_ThrowsError() {
        var assessment = Assessment()
        assessment.severity.domains[2].minFloor = 3
        
        XCTAssertThrowsError(
            try SeverityOverrideManager().applyDomainOverride(
                assessment: &assessment,
                dimension: 2,
                value: 2,
                reason: "Trying to override below floor",
                category: .clinicalJudgment,
                acknowledgesEmergency: false,
                user: UserRef(userId: "test", name: "Test", role: "Clinician")
            )
        ) { error in
            XCTAssertTrue(error is SeverityOverrideManager.ValidationError)
        }
    }
    
    func testOverride_RequiresAcknowledgement_WhenFloorActive() {
        var assessment = Assessment()
        assessment.severity.domains[2].minFloor = 3
        
        XCTAssertThrowsError(
            try SeverityOverrideManager().applyDomainOverride(
                assessment: &assessment,
                dimension: 2,
                value: 3,
                reason: "Valid reason here that is long enough",
                category: .clinicalJudgment,
                acknowledgesEmergency: false,
                user: UserRef(userId: "test", name: "Test", role: "Clinician")
            )
        ) { error in
            guard case SeverityOverrideManager.ValidationError.emergencyAckRequired = error else {
                XCTFail("Wrong error type")
                return
            }
        }
    }
    
    func testOverride_AuditLog_RecordsChange() {
        var assessment = Assessment()
        let auditLog = AuditLog.shared
        auditLog.clear() // reset
        
        try? SeverityOverrideManager().applyDomainOverride(
            assessment: &assessment,
            dimension: 0,
            value: 4,
            reason: "Clinical judgment based on patient presentation",
            category: .clinicalJudgment,
            acknowledgesEmergency: false,
            user: UserRef(userId: "kdial", name: "Dr. Dial", role: "Clinician")
        )
        
        let events = auditLog.getEvents(for: assessment.id)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].action, .domainOverrideSet)
        XCTAssertEqual(events[0].newValue, "4")
    }
}
```

### Export Integration

Add to `computed.json`:

```json
{
  "domains": [
    {
      "dimension": 1,
      "computed": 3,
      "minFloor": 3,
      "override": {
        "enabled": true,
        "value": 4,
        "reason": "Severe psychosis with command hallucinations",
        "category": "clinicalJudgment",
        "createdBy": {"userId": "kdial", "name": "Dr. Dial", "role": "Clinician"},
        "createdAt": "2025-11-13T13:41:22Z",
        "acknowledgesEmergency": true
      },
      "final": 4
    }
  ],
  "overall": {
    "computed": 4,
    "override": null,
    "final": 4
  }
}
```

Add to PDF footer when override present:
```
"Final rating reflects clinician override by Dr. Dial on 2025-11-13 13:41 EST"
```

---

## 12. Updated 5-Day Schedule

Add to Master TODO P0 section:

### P0+: Security & Compliance (NEW)
- [ ] **SecureStore**: AES-256 encryption, Keychain storage, no iCloud backup
- [ ] **AuditLog**: Append-only JSONL per session
- [ ] **Ruleset versioning**: Include in assessment + export
- [ ] **IntakeHeader rigor**: MRN/FIN validation, timezone, session ID
- [ ] **CompactPatientHeader**: Sticky header above all forms
- [ ] **AppSettings**: Complete model + persistence
- [ ] **SettingsView**: 7 sections with all controls
- [ ] **Purge PHI**: One-tap delete in Settings
- [ ] **FORM_FIELD_MAP coverage test**: Assert all paths mapped
- [ ] **Storage corruption test**: Graceful recovery
- [ ] **Sessions primary column**: Search, filter, swipe actions
- [ ] **Keyboard shortcuts**: Cmd+J, Cmd+1..8, Cmd+E

---

## 📅 UPDATED 5-DAY SCHEDULE

### Day 0.5: Security Foundations (4 hours) ← INSERT BEFORE Day 1
**Morning (2h)**:
1. SecureStore Implementation (1.5h)
   - Create SecureStore.swift
   - Generate AES key, store in Keychain
   - Mark storage `.isExcludedFromBackup`
   - Test: Key survives restart

2. AuditLog Foundation (0.5h)
   - Create AuditLog.swift
   - Implement JSONL append
   - Test: Append works, survives crash

**Afternoon (2h)**:
3. Ruleset Versioning (1h)
   - Add `ruleset` to Assessment
   - Add checksum calculation
   - Test: Persists in export

4. Enhanced IntakeHeader (1h)
   - Add sessionId, timezone, encounterId
   - Add MRN/DOB validation
   - Test: All validations work

**Deliverables**:
- ✅ Encryption enabled
- ✅ Audit log appending
- ✅ Ruleset versioned
- ✅ Header validation working

---

### Day 1: P0 Blockers + Settings + Severity (12 hours)

**Morning (6h)**:
1. Intake Header UI (2h)
   - Blocking screen before D1 access
   - All validation from enhanced IntakeHeader
   - Error states and inline help
   
2. Severity Auto-Calculation (3h)
   - Add SeverityCalculator class with all D1-D6 logic
   - Add DomainState and AssessmentSeverity structs
   - Integrate into Domain answer changes
   - Test: All dimension calculations with test fixtures

3. Validation Matrix core (1h)
   - ValidationRule struct
   - Core validation engine
   - Hook into Domain.answers changes

**Afternoon (4h)**:
4. Emergency Banner registry (2h)
   - EmergencyTrigger registry
   - Banner UI component
   - Integration with all 6 triggers
   - Hook emergency floors into severity calculation

5. Severity Override System (2h)
   - Add SeverityOverride struct
   - Add SeverityOverrideManager with validation
   - Add SeverityOverrideSheet UI
   - Add SeverityChip component
   - Test: Floor constraints, acknowledgement, audit

**Evening (2h)**:
6. AppSettings + SettingsView (1h)
   - Paste AppSettings struct from guide
   - Paste SettingsView from guide
   - Test persistence
  
7. CompactPatientHeader (1h)
   - Paste from guide
   - Make sticky above all forms
   - Test with navigation

**Deliverables**:
- ✅ Intake header blocks D1
- ✅ All severity calculations working
- ✅ Override system with audit trail
- ✅ Emergency floors enforced
- ✅ Settings + patient header complete

---

### Day 2: Validation + Emergency + Severity Complete (8 hours)

**Morning (4h)**:
1. Complete validation matrix (all D1-D6 rules)
2. Complete emergency trigger integration
3. Test all dimension severity calculations
4. Test override floor constraints with all emergencies

**Afternoon (4h)**:
5. Integration testing (all 12 test fixtures)
6. Smoke tests passing
7. Fix edge cases
8. Documentation of severity algorithms

**Deliverables**:
- ✅ All dimension rules implemented
- ✅ All emergency triggers working
- ✅ All severity calculations verified
- ✅ Override system fully tested
- ✅ All smoke tests passing

---

### Day 3: Storage + Export (8 hours)

(No changes - proceed as planned in Master TODO)

---

### Day 4: Testing + UX Polish (10 hours)

**Morning (4h)**:
1. Severity display polish (chips, colors, badges)
2. Override UI refinement
3. Final severity integration testing
4. Test with real patient scenarios

**Afternoon (6h)**:
5. Sessions Primary Column (3h)
   - Convert drawer to primary column
   - Add search + filter
   - Add swipe actions
   - Test: Keyboard shortcuts work

6. Test Coverage Completion (3h)
   - FORM_FIELD_MAP coverage test
   - Storage corruption test
   - Property-based tests (severity idempotence)
   - Accessibility audit
   - Severity calculation tests for all dimensions

**Deliverables**:
- ✅ Severity system polished and tested
- ✅ Sessions UX complete
- ✅ All tests passing
- ✅ Production ready

---

## ✅ FINAL CHECKLIST (50+ items)

### Security & Privacy
- [ ] AES-256 encryption enabled
- [ ] No iCloud backup
- [ ] App lock with timeout
- [ ] Blur in app switcher
- [ ] Purge PHI button
- [ ] Audit log per session
- [ ] Emergency banner tracking
- [ ] Override audit trail complete

### Compliance
- [ ] Ruleset versioned
- [ ] MRN/FIN validated
- [ ] Timezone captured
- [ ] Session ID generated
- [ ] Consent timestamp
- [ ] FORM_FIELD_MAP coverage
- [ ] Export reproducibility

### Validation + Emergency + Severity
- [ ] Validation matrix enforces all D1-D6 rules
- [ ] All 6 emergency triggers functional
- [ ] Emergency banner dismissal logged
- [ ] Inline validation errors shown
- [ ] All test fixtures pass validation
- [ ] Severity auto-calculated for all dimensions (D1-D6)
- [ ] Override requires reason (min 15 chars)
- [ ] Override enforces floor constraints
- [ ] Override requires emergency acknowledgement when floor > 0
- [ ] Override audit trail complete
- [ ] Overall severity computed from domain finals
- [ ] Severity chips display baseline + final
- [ ] Reset override shows undo toast
- [ ] D3 suicide/homicide emergencies trigger floor
- [ ] D5 imminent relapse triggers floor
- [ ] D6 homelessness/DV triggers floor

### Export
- [ ] Export includes all metadata (ruleset, timezone, etc.)
- [ ] Export includes severity overrides in computed.json
- [ ] Export includes audit.log.jsonl with all override events
- [ ] PDF fills all FORM_FIELD_MAP entries
- [ ] PDF displays final severity (post-override)
- [ ] Export envelope has checksum
- [ ] PDF footer shows override attribution when present
- [ ] Signature placement correct
- [ ] File naming: ASAMPlan_<sessionId>.pdf

### UX & Accessibility
- [ ] Sessions primary column
- [ ] Search + filter
- [ ] Swipe actions
- [ ] Compact patient header
- [ ] Keyboard shortcuts
- [ ] 44pt hit targets
- [ ] VoiceOver labels
- [ ] High contrast mode
- [ ] Severity chip colors accessible
- [ ] Override sheet accessible

### Settings Complete
- [ ] Privacy (5 controls)
- [ ] Storage (4 controls)
- [ ] Export (4 controls)
- [ ] Display (6 controls)
- [ ] Input (4 controls)
- [ ] Telemetry (2 controls)
- [ ] About (6 items)

---

**Manager's Note**: Every file name, struct name, and setting key above is paste-ready. Use these scaffolds to ship production-grade security, compliance, AND clinician-grade severity assessment in 5 days.
