# Safety Banner Enhancement Specification

**Date**: November 9, 2025  
**Priority**: 🔴 HYPER-CRITICAL - Stop-ship issue  
**Status**: Current implementation BROKEN - allows dismissal without audit

---

## ❌ Current Implementation Problem

**What's Wrong**:
```swift
// BROKEN: Dismisses banner without recording action
Button("Record Action") {
    safetyFlag = nil  // ❌ NO AUDIT LOG, NO USER ACTION CAPTURED
}
```

**Why This Is Dangerous**:
- Safety flags indicate immediate risk (suicidality, violence, withdrawal)
- Clinicians MUST document their response
- Audit trail required for liability protection
- Export should remain blocked until action recorded

---

## ✅ Required Fix: Modal + Audit Flow

### Architecture

```
┌─────────────────────────────────────────┐
│         Safety Banner (Persistent)       │
│  ⚠️ "Patient expressing suicidal ideation" │
│                [Record Action] ←────────┼─── Tap opens modal
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│    SafetyActionSheet (Modal)            │
│                                          │
│  Safety Flag:                            │
│  "Patient expressing suicidal ideation"  │
│                                          │
│  Action Taken: [Picker]                  │
│    • Emergency services contacted        │
│    • Safety plan created                 │
│    • Assessment completed with supervision│
│    • Consultation obtained               │
│                                          │
│  Notes (required): [Text Editor]         │
│  "Called mobile crisis team..."          │
│                                          │
│        [Cancel]    [Record Action] ←────┼─── Only then dismiss banner
└─────────────────────────────────────────┘
                    ↓
            AuditService.log()
                    ↓
        SafetyFlag dismissed ✅
```

---

## 📋 Implementation Components

### 1. SafetyAction Model

```swift
// Models/SafetyAction.swift
import Foundation

/// Action taken in response to a safety flag
struct SafetyAction: Identifiable, Codable {
    let id: UUID
    let flagId: UUID
    let type: SafetyActionType
    let notes: String
    let timestamp: Date
    let clinicianId: String?
    
    init(
        flagId: UUID,
        type: SafetyActionType,
        notes: String,
        clinicianId: String? = nil
    ) {
        self.id = UUID()
        self.flagId = flagId
        self.type = type
        self.notes = notes
        self.timestamp = Date()
        self.clinicianId = clinicianId
    }
}

/// Types of safety actions
enum SafetyActionType: String, Codable, CaseIterable, Identifiable {
    case emergencyContacted = "emergency_contacted"
    case safetyPlanCreated = "safety_plan_created"
    case assessmentCompleted = "assessment_completed"
    case consultationObtained = "consultation_obtained"
    case patientReferred = "patient_referred"
    case supervisorNotified = "supervisor_notified"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .emergencyContacted:
            return "Emergency services contacted"
        case .safetyPlanCreated:
            return "Safety plan created"
        case .assessmentCompleted:
            return "Assessment completed with supervision"
        case .consultationObtained:
            return "Consultation obtained"
        case .patientReferred:
            return "Patient referred to appropriate care"
        case .supervisorNotified:
            return "Supervisor notified"
        }
    }
    
    var description: String {
        switch self {
        case .emergencyContacted:
            return "Mobile crisis, 911, or emergency department"
        case .safetyPlanCreated:
            return "Documented safety plan with patient"
        case .assessmentCompleted:
            return "Continued with supervision or consultation"
        case .consultationObtained:
            return "Consulted with supervisor or psychiatric provider"
        case .patientReferred:
            return "Referred to higher level of care"
        case .supervisorNotified:
            return "Notified clinical supervisor"
        }
    }
}
```

### 2. AuditService

```swift
// Services/AuditService.swift
import Foundation
import CryptoKit

/// Audit logging service with HMAC verification
class AuditService: ObservableObject {
    static let shared = AuditService()
    
    @Published private(set) var events: [AuditEvent] = []
    
    private let secretKey: SymmetricKey
    
    private init() {
        // In production, load from keychain
        // For prototype, generate ephemeral key
        self.secretKey = SymmetricKey(size: .bits256)
    }
    
    /// Log an audit event with HMAC
    func log(
        action: String,
        target: String,
        details: Any? = nil,
        clinicianId: String? = nil
    ) {
        let event = AuditEvent(
            action: action,
            target: target,
            details: details,
            clinicianId: clinicianId
        )
        
        // Compute HMAC
        let hmac = computeHMAC(for: event)
        event.hmac = hmac
        
        events.append(event)
        
        // In production: persist to secure storage
        // For prototype: keep in memory
        
        print("📝 Audit: \(action) on \(target) at \(event.timestamp)")
    }
    
    private func computeHMAC(for event: AuditEvent) -> String {
        let data = "\(event.id)|\(event.action)|\(event.target)|\(event.timestamp)".data(using: .utf8)!
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: secretKey)
        return Data(hmac).base64EncodedString()
    }
    
    /// Verify event integrity
    func verifyEvent(_ event: AuditEvent) -> Bool {
        let expectedHMAC = computeHMAC(for: event)
        return expectedHMAC == event.hmac
    }
}

/// Audit event with HMAC
class AuditEvent: Identifiable, Codable {
    let id: UUID
    let action: String
    let target: String
    let details: String?
    let clinicianId: String?
    let timestamp: Date
    var hmac: String?
    
    init(action: String, target: String, details: Any?, clinicianId: String?) {
        self.id = UUID()
        self.action = action
        self.target = target
        self.details = details.map { String(describing: $0) }
        self.clinicianId = clinicianId
        self.timestamp = Date()
    }
}
```

### 3. Enhanced SafetyBanner

```swift
// Views/Components/SafetyBanner.swift
import SwiftUI

struct SafetyBanner: View {
    @Binding var safetyFlag: SafetyFlag?
    @State private var showActionSheet = false
    @AccessibilityFocusState private var bannerFocused: Bool
    @EnvironmentObject var auditService: AuditService
    
    var body: some View {
        if let flag = safetyFlag {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.errorRed)
                    .accessibilityHidden(true)
                
                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Safety Alert")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.errorRed)
                    
                    Text(flag.message)
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                // Action button
                Button {
                    showActionSheet = true
                } label: {
                    Text("Record Action")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.errorRed)
                .accessibilityLabel("Record safety action")
                .accessibilityHint("Opens form to document immediate safety response")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.errorRed.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.errorRed, lineWidth: 2)
            )
            .shadow(radius: 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Safety alert: \(flag.message). Record action required.")
            .accessibilityFocused($bannerFocused)
            .onAppear {
                // Announce banner and provide haptic feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bannerFocused = true
                    HapticService.shared.warning()
                }
            }
            .sheet(isPresented: $showActionSheet) {
                SafetyActionSheet(
                    flag: flag,
                    onRecord: { action in
                        recordSafetyAction(action, for: flag)
                    }
                )
            }
        }
    }
    
    private func recordSafetyAction(_ action: SafetyAction, for flag: SafetyFlag) {
        // Log to audit service
        auditService.log(
            action: "safety_action_recorded",
            target: flag.id.uuidString,
            details: [
                "action_type": action.type.rawValue,
                "notes": action.notes,
                "timestamp": action.timestamp
            ],
            clinicianId: action.clinicianId
        )
        
        // NOW dismiss the banner
        withAnimation {
            safetyFlag = nil
        }
        
        // Success haptic
        HapticService.shared.success()
    }
}
```

### 4. SafetyActionSheet Modal

```swift
// Views/SafetyActionSheet.swift
import SwiftUI

struct SafetyActionSheet: View {
    let flag: SafetyFlag
    let onRecord: (SafetyAction) -> Void
    
    @State private var actionType: SafetyActionType = .assessmentCompleted
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss
    @AccessibilityFocusState private var focusedField: Field?
    
    enum Field {
        case actionType
        case notes
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Safety flag details
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.errorRed)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading) {
                            Text("Safety Flag")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(flag.message)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.errorRed)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Alert Details")
                }
                
                // Action type selection
                Section {
                    Picker("Action Type", selection: $actionType) {
                        ForEach(SafetyActionType.allCases) { type in
                            VStack(alignment: .leading) {
                                Text(type.displayName)
                                    .font(.body)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }
                    .accessibilityFocused($focusedField, equals: .actionType)
                } header: {
                    Text("Action Taken")
                } footer: {
                    Text("Select the immediate action taken in response to this safety concern.")
                }
                
                // Notes (required)
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .accessibilityLabel("Safety action notes")
                        .accessibilityHint("Enter detailed notes about the action taken")
                        .accessibilityFocused($focusedField, equals: .notes)
                    
                    if notes.isEmpty {
                        Label("Notes are required", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.errorRed)
                    }
                } header: {
                    Text("Notes (Required)")
                } footer: {
                    Text("Document specific details about the action taken, including who was contacted, what was discussed, and next steps.")
                }
                
                // Record button
                Section {
                    Button {
                        recordAction()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                            Text("Record Action")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Record safety action")
                    .accessibilityHint("Saves action and dismisses safety alert")
                }
            }
            .navigationTitle("Record Safety Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel without recording")
                    .accessibilityHint("Returns to assessment without recording action")
                }
            }
            .onAppear {
                // Focus first field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    focusedField = .actionType
                }
            }
        }
    }
    
    private func recordAction() {
        let action = SafetyAction(
            flagId: flag.id,
            type: actionType,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            clinicianId: nil  // TODO: Get from auth service
        )
        
        onRecord(action)
        dismiss()
    }
}

// MARK: - Preview
struct SafetyActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        SafetyActionSheet(
            flag: SafetyFlag(
                id: UUID(),
                message: "Patient expressing suicidal ideation",
                severity: .high
            ),
            onRecord: { _ in }
        )
    }
}
```

---

## 🧪 Testing Checklist

### Unit Tests

```swift
// Tests/SafetyActionTests.swift
import XCTest
@testable import ASSESS

class SafetyActionTests: XCTestCase {
    func testBannerDoesNotDismissWithoutAction() {
        let flag = SafetyFlag(message: "Test")
        var safetyFlag: SafetyFlag? = flag
        
        // Simulate button tap WITHOUT recording action
        // Banner should remain
        XCTAssertNotNil(safetyFlag, "Banner should not dismiss without action")
    }
    
    func testActionRequiresNotes() {
        let action = SafetyAction(
            flagId: UUID(),
            type: .emergencyContacted,
            notes: ""
        )
        
        XCTAssertFalse(action.notes.isEmpty, "Action should require notes")
    }
    
    func testAuditEventCreated() {
        let auditService = AuditService.shared
        let initialCount = auditService.events.count
        
        auditService.log(
            action: "safety_action_recorded",
            target: UUID().uuidString,
            details: nil
        )
        
        XCTAssertEqual(auditService.events.count, initialCount + 1)
    }
    
    func testHMACVerification() {
        let auditService = AuditService.shared
        auditService.log(action: "test", target: "test")
        
        let event = auditService.events.last!
        XCTAssertTrue(auditService.verifyEvent(event))
    }
}
```

### Manual Tests

- [ ] **Banner Persistence**: Safety banner stays visible until action recorded
- [ ] **Modal Requirement**: Tapping "Record Action" opens modal (doesn't dismiss)
- [ ] **Notes Validation**: Cannot submit without notes
- [ ] **Audit Logging**: Audit event created with HMAC
- [ ] **Export Blocking**: Export remains disabled while flag present
- [ ] **Accessibility**: VoiceOver announces banner, modal navigable with keyboard
- [ ] **Haptics**: Warning haptic on banner appear, success haptic on action recorded

---

## 🔐 Security Considerations

### HMAC Implementation

**Purpose**: Prevent tampering with audit logs

**Algorithm**: HMAC-SHA256

**Key Management**:
```swift
// Production: Store in Keychain
import Security

func loadAuditKey() -> SymmetricKey {
    let query: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: "com.assess.audit.key",
        kSecReturnData as String: true
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    if status == errSecSuccess, let keyData = item as? Data {
        return SymmetricKey(data: keyData)
    } else {
        // Generate new key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "com.assess.audit.key",
            kSecValueData as String: keyData
        ]
        
        SecItemAdd(addQuery as CFDictionary, nil)
        return key
    }
}
```

### Audit Log Persistence

**Options**:
1. **Local SQLite** (offline support)
2. **Encrypted Core Data** (built-in encryption)
3. **Remote API** (immediate backup)

**Recommended**: Hybrid approach
- Write locally immediately
- Sync to server when online
- Server validates HMAC

```swift
func persistAuditEvent(_ event: AuditEvent) async throws {
    // 1. Write to local database
    try await database.insert(event)
    
    // 2. Sync to server (when online)
    if networkMonitor.isConnected {
        try await api.uploadAuditEvent(event)
    }
}
```

---

## 📋 Integration Checklist

### Phase 1: Basic Modal Flow
- [ ] Create `SafetyAction` model
- [ ] Create `SafetyActionSheet` view
- [ ] Update `SafetyBanner` to show sheet
- [ ] Test banner persistence

### Phase 2: Audit Logging
- [ ] Create `AuditService` with HMAC
- [ ] Log action when recorded
- [ ] Test HMAC verification
- [ ] Add audit log viewer (admin only)

### Phase 3: Export Blocking
- [ ] Update `ValidationService` to check for safety flags
- [ ] Block export if flag present
- [ ] Show clear error message
- [ ] Test preflight validation

### Phase 4: Accessibility
- [ ] Add VoiceOver labels
- [ ] Implement focus management
- [ ] Add haptic feedback
- [ ] Test with VoiceOver enabled

### Phase 5: Production Hardening
- [ ] Move HMAC key to Keychain
- [ ] Implement local persistence
- [ ] Add server sync
- [ ] Implement audit log export

---

## ✅ Definition of Done

1. **Functional**:
   - [ ] Banner never dismisses without action
   - [ ] Modal requires action type + notes
   - [ ] Audit event created with HMAC
   - [ ] Export blocked until flag cleared

2. **Accessible**:
   - [ ] VoiceOver announces banner
   - [ ] Modal keyboard navigable
   - [ ] Haptic feedback provided
   - [ ] Color contrast meets WCAG AA

3. **Secure**:
   - [ ] Audit log tamper-evident (HMAC)
   - [ ] Key stored in Keychain
   - [ ] Events persisted locally
   - [ ] Server sync implemented

4. **Tested**:
   - [ ] Unit tests pass
   - [ ] Manual tests pass
   - [ ] Accessibility tests pass
   - [ ] Security review complete

---

**Last Updated**: November 9, 2025  
**Priority**: 🔴 HYPER-CRITICAL  
**Blocking**: All other feature work until fixed  
**Estimated Effort**: 4-6 hours
