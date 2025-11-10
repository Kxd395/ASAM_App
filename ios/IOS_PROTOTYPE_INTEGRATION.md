# iOS SwiftUI Prototype - Integration Guide

**Date**: November 9, 2025  
**Location**: Philadelphia, PA  
**Status**: Phase 1 Prototype Received ✅

---

## 🎉 Major Milestone: Working Prototype Delivered

You now have a **runnable SwiftUI prototype** that implements the core assessment shell. This moves the project from **SPEC PHASE** → **IMPLEMENTATION PHASE**.

### What You Received

**Prototype Package**: `ios_prototype.zip`

**Contents**:
- ✅ SwiftUI shell with NavigationSplitView
- ✅ Launch screen
- ✅ Assessment Overview screen
- ✅ One Domain screen (reference implementation)
- ✅ SafetyBanner component (persistent)
- ✅ ValidationService stub (blocker/gap/advisory)
- ✅ LOCService stub with neutral JSON loading
- ✅ README with Xcode import steps

**Lines of Code**: ~800-1000 (estimated)

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites
- macOS with Xcode 15+
- iOS 17+ SDK
- iPad simulator

### Installation Steps

1. **Create Xcode Project**
   ```bash
   # Open Xcode
   # File → New → Project
   # iOS → App
   # Product Name: ASSESS
   # Interface: SwiftUI
   # Language: Swift
   # Save to: /Users/kevindialmb/Downloads/ASAM_App/ios/ASSESS
   ```

2. **Extract Prototype**
   ```bash
   cd /Users/kevindialmb/Downloads/ASAM_App/ios
   unzip ~/Downloads/ios_prototype.zip -d ASSESS_prototype
   ```

3. **Quit Xcode** (important!)

4. **Copy Sources**
   ```bash
   cd ASSESS
   # Backup original
   mv ASSESS ASSESS.original
   
   # Copy prototype sources
   cp -r ../ASSESS_prototype/Sources/* ./
   ```

5. **Add LOC Reference JSON**
   - Open Xcode
   - Drag `/Users/kevindialmb/Downloads/ASAM_App/data/loc_reference_neutral.json` into project
   - Check "Copy items if needed"
   - Add to target: ASSESS
   - In Build Phases → Copy Bundle Resources, verify JSON is listed

6. **Build & Run**
   - Select iPad simulator (any model)
   - Product → Run (⌘R)

7. **Test Safety Banner**
   - In code, toggle `AppState.shared.safetyFlag = SafetyFlag(message: "Test")`
   - Rebuild to see banner behavior

---

## 🔍 Prototype Architecture Review

### File Structure (Expected)

```
ASSESS/
├── ASSESSApp.swift                 # Main app entry
├── Models/
│   ├── Assessment.swift            # Assessment data model
│   ├── Domain.swift                # Domain with severity
│   ├── SafetyFlag.swift            # Safety alert model
│   └── ValidationIssue.swift       # Blocker/gap/advisory
├── Services/
│   ├── AppState.swift              # Global app state
│   ├── LOCService.swift            # Level of care logic
│   └── ValidationService.swift     # Validation engine
├── Views/
│   ├── LaunchView.swift            # Screen 1: Launch & auth
│   ├── AssessmentOverview.swift   # Screen 4: Overview with chips
│   ├── DomainView.swift            # Screen 6: Domain detail
│   └── Components/
│       └── SafetyBanner.swift      # Persistent safety banner
└── Resources/
    └── loc_reference_neutral.json  # LOC taxonomy data
```

### Key Components

#### 1. NavigationSplitView Shell

```swift
// ASSESSApp.swift
@main
struct ASSESSApp: App {
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                // Sidebar navigation
                List {
                    NavigationLink("Launch", destination: LaunchView())
                    NavigationLink("Assessment", destination: AssessmentOverview())
                }
            } detail: {
                // Main content area
                LaunchView()
            }
            .overlay(alignment: .top) {
                SafetyBanner(safetyFlag: $appState.safetyFlag)
            }
        }
    }
}
```

**Architecture Match**: ✅ Mirrors UI_WIREFRAMES_ASCII.md structure

#### 2. SafetyBanner Component

```swift
// Views/Components/SafetyBanner.swift
struct SafetyBanner: View {
    @Binding var safetyFlag: SafetyFlag?
    
    var body: some View {
        if let flag = safetyFlag {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(flag.message)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Record Action") {
                    // STUB: Currently just dismisses
                    // TODO: Show modal, record action, audit log
                    safetyFlag = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
        }
    }
}
```

**Status**: ⚠️ STUB - Needs modal + audit (see Critical Note #2)

#### 3. LOCService

```swift
// Services/LOCService.swift
class LOCService: ObservableObject {
    @Published var levels: [LOCLevel] = []
    
    init() {
        loadLevels()
    }
    
    func loadLevels() {
        guard let url = Bundle.main.url(forResource: "loc_reference_neutral", withExtension: "json") else {
            print("❌ LOC reference not found")
            return
        }
        
        // Load and decode JSON
        let data = try! Data(contentsOf: url)
        let decoded = try! JSONDecoder().decode(LOCReference.self, from: data)
        self.levels = decoded.levels
    }
    
    func recommendLOC(assessment: Assessment) -> String {
        // STUB: Basic algorithm
        // TODO: Implement full decision tree (see Critical Note #3)
        let maxSeverity = assessment.domains.map { $0.severity }.max() ?? 0
        
        if maxSeverity >= 3 { return "INP" }
        if maxSeverity >= 2 { return "RES" }
        if maxSeverity >= 1 { return "IOP" }
        return "OUT"
    }
    
    func getDisplayName(_ code: String) -> String {
        levels.first(where: { $0.code == code })?.display ?? code
    }
}
```

**Status**: ⚠️ STUB - Needs decision trace (see Critical Note #3)

#### 4. ValidationService

```swift
// Services/ValidationService.swift
class ValidationService: ObservableObject {
    @Published var blockers: [ValidationIssue] = []
    @Published var gaps: [ValidationIssue] = []
    @Published var advisory: [ValidationIssue] = []
    
    func validate(assessment: Assessment, safetyFlag: SafetyFlag?) {
        blockers.removeAll()
        gaps.removeAll()
        advisory.removeAll()
        
        // BLOCKER: Safety flag present
        if safetyFlag != nil {
            blockers.append(ValidationIssue(
                message: "Safety action not recorded",
                fixAction: { /* Navigate to safety modal */ }
            ))
        }
        
        // BLOCKER: Missing domain ratings
        for domain in assessment.domains {
            if domain.severity == nil {
                blockers.append(ValidationIssue(
                    message: "Domain \(domain.id) severity not set",
                    fixAction: { /* Navigate to domain */ }
                ))
            }
        }
        
        // GAP: Missing goals
        // ADVISORY: Consider additional services
    }
    
    var canExport: Bool {
        blockers.isEmpty
    }
}
```

**Status**: ✅ Good foundation - Needs expansion from VALIDATION_GATES.json

---

## 🚨 HYPER-CRITICAL IMPLEMENTATION NOTES

### 1. Accessibility Must Be Built In NOW ⚠️

**Current State**: ❌ Likely missing accessibility labels

**Required Immediate Actions**:

```swift
// BAD: No accessibility
Button("Record Action") {
    recordSafetyAction()
}

// GOOD: Full accessibility
Button("Record Action") {
    recordSafetyAction()
}
.accessibilityLabel("Record safety action")
.accessibilityHint("Opens form to document safety response")
.accessibilityAddTraits(.isButton)

// GOOD: Severity chips with semantic meaning
ForEach(assessment.domains) { domain in
    SeverityChip(severity: domain.severity)
        .accessibilityLabel("Domain \(domain.name) severity \(domain.severity)")
        .accessibilityValue("\(domain.severity) out of 4")
}
```

**Testing Checklist**:
- [ ] Enable VoiceOver in simulator (Accessibility Inspector)
- [ ] Navigate entire flow with VoiceOver only
- [ ] Test Dynamic Type (Settings → Accessibility → Larger Text)
- [ ] Verify color contrast ≥4.5:1 for all text

**Color Contrast Tokens** (create now):
```swift
// Theme/Colors.swift
extension Color {
    // WCAG AA compliant (4.5:1 ratio)
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)     // #1A1A1A
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)   // #666666
    static let errorRed = Color(red: 0.8, green: 0.1, blue: 0.1)        // #CC1A1A
    static let successGreen = Color(red: 0.1, green: 0.6, blue: 0.1)    // #1A991A
}
```

**Accessibility Audit Tool**:
```swift
// Development only
#if DEBUG
.onAppear {
    if ProcessInfo.processInfo.environment["ACCESSIBILITY_AUDIT"] != nil {
        AccessibilityAudit.run(view: self)
    }
}
#endif
```

---

### 2. Safety Banner Must Never Be Dismissible Without Recording Action 🚨

**Current Implementation**: ❌ BROKEN - Dismisses on button tap

**Required Fix**:

```swift
// Views/Components/SafetyBanner.swift
struct SafetyBanner: View {
    @Binding var safetyFlag: SafetyFlag?
    @State private var showActionSheet = false
    @EnvironmentObject var auditService: AuditService
    
    var body: some View {
        if let flag = safetyFlag {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .accessibilityHidden(true)  // Redundant with text
                
                Text(flag.message)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Record Action") {
                    showActionSheet = true  // Show modal, don't dismiss
                }
                .buttonStyle(.borderedProminent)
                .tint(.errorRed)
                .accessibilityLabel("Record safety action")
                .accessibilityHint("Opens form to document immediate safety response")
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .sheet(isPresented: $showActionSheet) {
                SafetyActionSheet(
                    flag: flag,
                    onRecord: { action in
                        // Record to audit log
                        auditService.log(
                            action: "safety_action_recorded",
                            target: flag.id,
                            details: action
                        )
                        
                        // NOW dismiss banner
                        safetyFlag = nil
                    }
                )
            }
        }
    }
}

// New view: Safety action recording modal
struct SafetyActionSheet: View {
    let flag: SafetyFlag
    let onRecord: (SafetyAction) -> Void
    
    @State private var actionType: SafetyActionType = .assessmentCompleted
    @State private var notes: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Safety Flag") {
                    Text(flag.message)
                        .foregroundColor(.errorRed)
                }
                
                Section("Action Taken") {
                    Picker("Type", selection: $actionType) {
                        Text("Emergency services contacted").tag(SafetyActionType.emergencyContacted)
                        Text("Safety plan created").tag(SafetyActionType.safetyPlanCreated)
                        Text("Assessment completed with supervision").tag(SafetyActionType.assessmentCompleted)
                        Text("Consultation obtained").tag(SafetyActionType.consultationObtained)
                    }
                    
                    TextField("Notes (required)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Record Action") {
                        let action = SafetyAction(
                            type: actionType,
                            notes: notes,
                            timestamp: Date()
                        )
                        onRecord(action)
                        dismiss()
                    }
                    .disabled(notes.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Record Safety Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Models
enum SafetyActionType: String, Codable {
    case emergencyContacted = "emergency_contacted"
    case safetyPlanCreated = "safety_plan_created"
    case assessmentCompleted = "assessment_completed"
    case consultationObtained = "consultation_obtained"
}

struct SafetyAction: Codable {
    let type: SafetyActionType
    let notes: String
    let timestamp: Date
}
```

**Validation**:
- [ ] Banner NEVER dismisses without recording action
- [ ] Modal cannot be submitted without notes
- [ ] Audit event created with HMAC
- [ ] Export remains blocked until action recorded

---

### 3. LOC Integration Must Be Deterministic and Explainable 📊

**Current Implementation**: ❌ Black box algorithm

**Required Enhancement**:

```swift
// Services/LOCService.swift
class LOCService: ObservableObject {
    @Published var levels: [LOCLevel] = []
    
    // NEW: Decision trace for explainability
    struct DecisionTrace {
        let steps: [DecisionStep]
        let finalRecommendation: String
        
        var explanation: String {
            steps.map { $0.description }.joined(separator: "\n")
        }
    }
    
    struct DecisionStep {
        let rule: String
        let condition: String
        let result: String
        
        var description: String {
            "• \(rule): \(condition) → \(result)"
        }
    }
    
    func recommendLOC(assessment: Assessment) -> (code: String, trace: DecisionTrace) {
        var steps: [DecisionStep] = []
        
        // Step 1: Check withdrawal risk
        let withdrawalRisk = assessment.domains.first { $0.id == 1 }?.severity ?? 0
        steps.append(DecisionStep(
            rule: "Withdrawal Assessment (Domain 1)",
            condition: "Severity = \(withdrawalRisk)",
            result: withdrawalRisk >= 2 ? "Withdrawal management needed" : "No WM required"
        ))
        
        // Step 2: Check biomedical needs
        let biomedical = assessment.domains.first { $0.id == 2 }?.severity ?? 0
        steps.append(DecisionStep(
            rule: "Biomedical Conditions (Domain 2)",
            condition: "Severity = \(biomedical)",
            result: biomedical >= 3 ? "Hospital-level care required" : "Lower level appropriate"
        ))
        
        // Step 3: Check maximum severity across all domains
        let maxSeverity = assessment.domains.map { $0.severity }.max() ?? 0
        steps.append(DecisionStep(
            rule: "Maximum Domain Severity",
            condition: "Max = \(maxSeverity) across 6 domains",
            result: "Overall acuity: \(severityLabel(maxSeverity))"
        ))
        
        // Step 4: Apply decision tree
        var recommendation: String
        if maxSeverity >= 3 || biomedical >= 3 {
            recommendation = withdrawalRisk >= 2 ? "INP-DETOX" : "INP"
            steps.append(DecisionStep(
                rule: "High Acuity Path",
                condition: "Max severity ≥3 OR biomedical ≥3",
                result: "Recommended: \(recommendation)"
            ))
        } else if maxSeverity >= 2 {
            recommendation = withdrawalRisk >= 2 ? "RES-WM" : "RES"
            steps.append(DecisionStep(
                rule: "Moderate Acuity Path",
                condition: "Max severity = 2",
                result: "Recommended: \(recommendation)"
            ))
        } else if maxSeverity >= 1 {
            recommendation = withdrawalRisk >= 2 ? "IOP-WM" : "IOP"
            steps.append(DecisionStep(
                rule: "Mild Acuity Path",
                condition: "Max severity = 1",
                result: "Recommended: \(recommendation)"
            ))
        } else {
            recommendation = "OUT"
            steps.append(DecisionStep(
                rule: "Minimal Acuity Path",
                condition: "All severities = 0",
                result: "Recommended: OUT"
            ))
        }
        
        let trace = DecisionTrace(steps: steps, finalRecommendation: recommendation)
        return (recommendation, trace)
    }
    
    private func severityLabel(_ severity: Int) -> String {
        switch severity {
        case 0: return "None"
        case 1: return "Mild"
        case 2: return "Moderate"
        case 3: return "Severe"
        default: return "Unknown"
        }
    }
}

// UI: Show "Why?" button
struct LOCRecommendationView: View {
    let recommendation: String
    let trace: LOCService.DecisionTrace
    @State private var showExplanation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Recommended LOC")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(recommendation)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Button {
                showExplanation = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Why?")
                }
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Show LOC recommendation explanation")
        }
        .sheet(isPresented: $showExplanation) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Decision Process")
                            .font(.headline)
                        
                        Text(trace.explanation)
                            .font(.body)
                            .monospaced()
                        
                        Text("Final Recommendation: \(trace.finalRecommendation)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.top)
                    }
                    .padding()
                }
                .navigationTitle("LOC Logic")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showExplanation = false
                        }
                    }
                }
            }
        }
    }
}
```

**Validation**:
- [ ] Every recommendation shows "Why?" button
- [ ] Explanation traces all decision steps
- [ ] Rules reference domain severities explicitly
- [ ] Audit log includes recommendation + trace

---

### 4. Keep EMR Context Fully Read-Only 🔒

**Current State**: Needs implementation

**Required Pattern**:

```swift
// Models/EMRContext.swift
struct EMRContext {
    let patientId: String
    let allergies: [Allergy]
    let medications: [Medication]
    let vitals: Vitals?
    let lastFetch: Date
    
    var ttl: TimeInterval {
        Date().timeIntervalSince(lastFetch)
    }
    
    var isStale: Bool {
        ttl > 3600 // 1 hour
    }
}

// Views/Components/EMRContextDrawer.swift
struct EMRContextDrawer: View {
    let context: EMRContext
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Drawer header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("EMR Context (Read-Only)", systemImage: "building.2.fill")
                        .font(.headline)
                    
                    Spacer()
                    
                    // TTL badge
                    TTLBadge(lastFetch: context.lastFetch, isStale: context.isStale)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Allergies (read-only)
                    if !context.allergies.isEmpty {
                        ReadOnlySection(title: "Allergies", icon: "allergen") {
                            ForEach(context.allergies) { allergy in
                                Text("• \(allergy.name)")
                                    .foregroundColor(.errorRed)
                            }
                        }
                    }
                    
                    // Medications (read-only)
                    if !context.medications.isEmpty {
                        ReadOnlySection(title: "Current Medications", icon: "pills") {
                            ForEach(context.medications) { med in
                                Text("• \(med.name) \(med.dose)")
                            }
                        }
                    }
                    
                    // Vitals (read-only)
                    if let vitals = context.vitals {
                        ReadOnlySection(title: "Recent Vitals", icon: "heart.text.square") {
                            Text("BP: \(vitals.bloodPressure)")
                            Text("HR: \(vitals.heartRate) bpm")
                            Text("Temp: \(vitals.temperature)°F")
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
            }
        }
        .overlay(alignment: .topTrailing) {
            // Lock icon to indicate read-only
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(8)
        }
    }
}

struct TTLBadge: View {
    let lastFetch: Date
    let isStale: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isStale ? "clock.badge.exclamationmark" : "clock")
                .font(.caption)
            Text(timeAgoString)
                .font(.caption)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isStale ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
        .foregroundColor(isStale ? .orange : .green)
        .cornerRadius(4)
    }
    
    var timeAgoString: String {
        let seconds = Int(Date().timeIntervalSince(lastFetch))
        if seconds < 60 { return "\(seconds)s ago" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}

struct ReadOnlySection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            content
                .font(.body)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Read-only \(title) from EMR")
    }
}
```

**Design Enforcement**:
- [ ] Blue tint for all EMR context (visual distinction)
- [ ] Lock icon always visible
- [ ] TTL badge shows data freshness
- [ ] NO form fields prefilled from EMR
- [ ] Drawer collapsible to reduce clutter

---

### 5. PDF and Problems Deliberately Omitted - Do Not Add Quick Hacks 🚫

**Current State**: ✅ Correctly absent from prototype

**Temptation to Avoid**:
```swift
// ❌ DO NOT DO THIS
struct QuickProblemsView: View {
    @State private var problems: [String] = []
    
    var body: some View {
        List {
            ForEach(problems, id: \.self) { problem in
                Text(problem)
            }
        }
    }
}
```

**Why This Is Bad**:
- Problems module is THE single CRUD owner (complex state management)
- Needs domain tags, goals, objectives hierarchy
- Requires audit trail for all changes
- Will be referenced by PDF composer
- Quick hack creates technical debt

**Correct Approach**:
Wait for Phase 2 implementation with full spec:
- Single Problems table as source of truth
- Domain scratchpad → Problems flow
- Goal setting with target dates
- PDF overflow handling

**Same for PDF**:
- Hybrid composer (static + dynamic) is complex
- Font embedding required
- Overflow pagination logic
- Atomic write pattern
- Don't add "quick PDF export" - do it right

---

## 📋 Suggested Next Additions (In Order)

### 1. Summary + LOC Screen (Week 2)

**Priority**: 🔴 HIGH - Critical decision point

**Components Needed**:
```swift
struct SummaryLOCView: View {
    @ObservedObject var assessment: Assessment
    @StateObject private var locService = LOCService()
    @State private var actualLOC: String = ""
    @State private var discrepancyReasons: Set<DiscrepancyReason> = []
    
    var (indicatedLOC, trace) = locService.recommendLOC(assessment: assessment)
    var levelsMatch: Bool { indicatedLOC == actualLOC }
    
    var body: some View {
        Form {
            // Severity grid summary
            Section("Assessment Summary") {
                SeverityGridView(domains: assessment.domains)
            }
            
            // WM indication
            Section("Withdrawal Management") {
                WMIndicationView(assessment: assessment)
            }
            
            // LOC comparison
            Section("Level of Care") {
                HStack {
                    LOCRecommendationView(
                        title: "Indicated LOC",
                        code: indicatedLOC,
                        trace: trace
                    )
                    
                    Image(systemName: levelsMatch ? "checkmark.circle.fill" : "arrow.right")
                        .foregroundColor(levelsMatch ? .green : .orange)
                    
                    Picker("Actual LOC", selection: $actualLOC) {
                        ForEach(locService.levels) { level in
                            Text(level.display).tag(level.code)
                        }
                    }
                }
            }
            
            // Discrepancy reasoning (required if levels differ)
            if !levelsMatch && !actualLOC.isEmpty {
                Section("Discrepancy Explanation (Required)") {
                    DiscrepancyReasonPicker(reasons: $discrepancyReasons)
                    
                    if discrepancyReasons.isEmpty {
                        Label("Must select at least one reason", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.errorRed)
                    }
                }
            }
            
            // Continue button
            Section {
                Button("Proceed to Planning Mode") {
                    // Validate and proceed
                }
                .disabled(!canProceed)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Summary & LOC")
    }
    
    var canProceed: Bool {
        !actualLOC.isEmpty && (levelsMatch || !discrepancyReasons.isEmpty)
    }
}

enum DiscrepancyReason: String, CaseIterable, Identifiable {
    case patientPreference = "Patient preference"
    case insuranceLimitation = "Insurance limitation"
    case programAvailability = "Program availability"
    case clinicalOverride = "Clinical judgment override"
    case familyConsideration = "Family/social considerations"
    
    var id: String { rawValue }
}
```

**Validation**:
- [ ] Shows severity grid summary
- [ ] Displays indicated LOC with "Why?" button
- [ ] Requires actual LOC selection
- [ ] Enforces discrepancy reasoning when levels differ
- [ ] Blocks progression until complete

---

### 2. Problems Module with Single CRUD Ownership (Week 3)

**Priority**: 🟡 MEDIUM - Core clinical content

**Architecture**:
```swift
// Models/Problem.swift
struct Problem: Identifiable, Codable {
    let id: UUID
    var statement: String
    var goal: String
    var domainTags: Set<Int>  // Domain IDs (1-6)
    var objectives: [Objective]
    let createdAt: Date
    var updatedAt: Date
}

struct Objective: Identifiable, Codable {
    let id: UUID
    var text: String
    var targetDate: Date?
    var completed: Bool
}

// Services/ProblemsService.swift
class ProblemsService: ObservableObject {
    @Published var problems: [Problem] = []
    private let auditService: AuditService
    
    func addProblem(_ problem: Problem) {
        problems.append(problem)
        auditService.log(action: "problem_created", target: problem.id.uuidString)
    }
    
    func updateProblem(_ problem: Problem) {
        if let index = problems.firstIndex(where: { $0.id == problem.id }) {
            problems[index] = problem
            problems[index].updatedAt = Date()
            auditService.log(action: "problem_updated", target: problem.id.uuidString)
        }
    }
    
    func deleteProblem(_ id: UUID) {
        problems.removeAll { $0.id == id }
        auditService.log(action: "problem_deleted", target: id.uuidString)
    }
}

// Views/ProblemsView.swift
struct ProblemsView: View {
    @StateObject private var problemsService = ProblemsService()
    @State private var showAddSheet = false
    
    var body: some View {
        List {
            ForEach(problemsService.problems) { problem in
                ProblemRow(problem: problem)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            problemsService.deleteProblem(problem.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("Problems")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Problem", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ProblemEditSheet(
                onSave: { problem in
                    problemsService.addProblem(problem)
                }
            )
        }
    }
}
```

**Scratchpad → Problems Flow**:
```swift
// In DomainView
struct DomainView: View {
    @State private var scratchpad: String = ""
    @EnvironmentObject var problemsService: ProblemsService
    @State private var showSendToProblems = false
    
    var body: some View {
        Form {
            // ... domain content ...
            
            Section("Scratchpad") {
                TextEditor(text: $scratchpad)
                    .frame(height: 100)
                
                Button("Send to Problems") {
                    showSendToProblems = true
                }
                .disabled(scratchpad.isEmpty)
            }
        }
        .sheet(isPresented: $showSendToProblems) {
            ProblemEditSheet(
                initialStatement: scratchpad,
                domainTag: domain.id,
                onSave: { problem in
                    problemsService.addProblem(problem)
                    scratchpad = ""  // Clear after sending
                }
            )
        }
    }
}
```

**Validation**:
- [ ] Problems service is single source of truth
- [ ] All CRUD operations audit logged
- [ ] Domain scratchpad sends to Problems (doesn't create directly)
- [ ] Goals and objectives editable
- [ ] Domain tags visible and filterable

---

### 3. Preflight Page Consuming VALIDATION_GATES.json (Week 3)

**Priority**: 🟡 MEDIUM - Export safety gate

**Implementation**:
```swift
// Load validation gates from JSON
struct ValidationGates: Codable {
    let blockers: [ValidationRule]
    let gaps: [ValidationRule]
    let advisory: [ValidationRule]
}

struct ValidationRule: Codable, Identifiable {
    let id: String
    let name: String
    let condition: String
    let message: String
    let fixHint: String
}

// Services/PreflightService.swift
class PreflightService: ObservableObject {
    @Published var results: PreflightResults?
    private let gates: ValidationGates
    
    init() {
        // Load VALIDATION_GATES.json from bundle
        let url = Bundle.main.url(forResource: "VALIDATION_GATES", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        gates = try! JSONDecoder().decode(ValidationGates.self, from: data)
    }
    
    func runPreflight(assessment: Assessment, safetyFlag: SafetyFlag?) async -> PreflightResults {
        var blockers: [ValidationIssue] = []
        var gaps: [ValidationIssue] = []
        var advisory: [ValidationIssue] = []
        
        // Check each blocker rule
        for rule in gates.blockers {
            if !evaluateRule(rule, assessment: assessment, safetyFlag: safetyFlag) {
                blockers.append(ValidationIssue(
                    id: rule.id,
                    message: rule.message,
                    fixHint: rule.fixHint
                ))
            }
        }
        
        // Check gaps and advisory similarly...
        
        return PreflightResults(
            blockers: blockers,
            gaps: gaps,
            advisory: advisory,
            canExport: blockers.isEmpty
        )
    }
    
    private func evaluateRule(_ rule: ValidationRule, assessment: Assessment, safetyFlag: SafetyFlag?) -> Bool {
        // Parse and evaluate condition
        // Examples:
        // - "safety_flag_absent"
        // - "all_domains_rated"
        // - "wm_documented"
        // - "discrepancy_explained"
        
        switch rule.condition {
        case "safety_flag_absent":
            return safetyFlag == nil
        case "all_domains_rated":
            return assessment.domains.allSatisfy { $0.severity != nil }
        case "wm_documented":
            return assessment.wmIndicated == true || !assessment.wmRationale.isEmpty
        // ... more conditions
        default:
            return true
        }
    }
}

// Views/PreflightView.swift
struct PreflightView: View {
    let assessment: Assessment
    let safetyFlag: SafetyFlag?
    @StateObject private var preflightService = PreflightService()
    @State private var results: PreflightResults?
    
    var body: some View {
        List {
            if let results = results {
                // Blockers section (must fix)
                if !results.blockers.isEmpty {
                    Section {
                        ForEach(results.blockers) { blocker in
                            ValidationIssueRow(issue: blocker, severity: .blocker)
                        }
                    } header: {
                        Label("Blockers - Must Fix", systemImage: "exclamationmark.octagon.fill")
                            .foregroundColor(.errorRed)
                    }
                }
                
                // Gaps section (should fix)
                if !results.gaps.isEmpty {
                    Section {
                        ForEach(results.gaps) { gap in
                            ValidationIssueRow(issue: gap, severity: .gap)
                        }
                    } header: {
                        Label("Gaps - Should Fix", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                    }
                }
                
                // Advisory section
                if !results.advisory.isEmpty {
                    Section {
                        ForEach(results.advisory) { item in
                            ValidationIssueRow(issue: item, severity: .advisory)
                        }
                    } header: {
                        Label("Advisory", systemImage: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
                
                // Export button
                Section {
                    if results.canExport {
                        Button("Proceed to Export") {
                            // Navigate to export screen
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Fix all blockers to enable export")
                            .foregroundColor(.errorRed)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                ProgressView("Running preflight checks...")
            }
        }
        .navigationTitle("Preflight")
        .task {
            results = await preflightService.runPreflight(
                assessment: assessment,
                safetyFlag: safetyFlag
            )
        }
    }
}
```

**Validation**:
- [ ] Loads rules from VALIDATION_GATES.json
- [ ] Evaluates all blocker conditions
- [ ] Blocks export until all blockers cleared
- [ ] Shows fix hints for each issue
- [ ] Provides navigation to fix locations

---

## ✅ Validation Checklist Before Extending Prototype

Before adding Summary+LOC, Problems, or Preflight, ensure:

### Accessibility
- [ ] All interactive elements have accessibility labels
- [ ] VoiceOver navigation tested
- [ ] Dynamic Type tested (largest size)
- [ ] Color contrast verified (≥4.5:1)
- [ ] Semantic grouping with `accessibilityElement(children: .contain)`

### Safety Banner
- [ ] Modal shown on "Record Action" tap
- [ ] Modal requires action type + notes
- [ ] Audit event created with HMAC
- [ ] Banner persists until action recorded
- [ ] Export blocked while flag present

### LOC Service
- [ ] Decision trace generated for every recommendation
- [ ] "Why?" button shows all decision steps
- [ ] Rules reference specific domain severities
- [ ] Trace included in audit log

### EMR Context
- [ ] Visually distinct (blue tint + lock icon)
- [ ] TTL badge shows data freshness
- [ ] No form fields prefilled from EMR
- [ ] Drawer collapsible
- [ ] Read-only label on all sections

### Code Quality
- [ ] No Problems quick hacks
- [ ] No PDF quick exports
- [ ] All services use dependency injection
- [ ] Models conform to Codable
- [ ] Audit logging on all state changes

---

## 📦 Final Integration Steps

1. **Extract Prototype**
   ```bash
   cd /Users/kevindialmb/Downloads/ASAM_App/ios
   # Extract ios_prototype.zip when ready
   ```

2. **Add LOC JSON to Bundle**
   ```bash
   cp ../data/loc_reference_neutral.json ASSESS/Resources/
   ```

3. **Add Validation Gates JSON**
   ```bash
   cp ../Documents/agent_pack/VALIDATION_GATES.json ASSESS/Resources/
   ```

4. **Run Legal Compliance Check**
   ```bash
   cd ..
   ./scripts/check-legal-compliance.sh
   # Should pass with exit code 0
   ```

5. **Update Xcode Project**
   - Add JSONs to Copy Bundle Resources
   - Set deployment target: iOS 17+
   - Enable Face ID capability (later)

6. **First Build**
   ```bash
   # In Xcode
   # Product → Clean Build Folder (⌘⇧K)
   # Product → Build (⌘B)
   # Product → Run (⌘R)
   ```

---

## 🎯 Success Criteria

### Immediate (After Integration)
- [ ] Prototype builds without errors
- [ ] Launch screen shows correctly
- [ ] Can navigate to Assessment Overview
- [ ] Safety banner appears when flag set
- [ ] LOC service loads neutral JSON

### Week 2 (After Critical Fixes)
- [ ] Safety banner requires modal + audit
- [ ] LOC shows decision trace
- [ ] All views have accessibility labels
- [ ] EMR context drawer implemented
- [ ] Color contrast meets WCAG AA

### Week 3 (After Extensions)
- [ ] Summary + LOC screen complete
- [ ] Problems module with CRUD
- [ ] Preflight validation working
- [ ] All acceptance tests pass

---

## 📞 Next Actions

**Immediate**:
1. Extract and integrate ios_prototype.zip
2. Build and run in Xcode
3. Review actual code structure
4. Implement safety banner modal fix

**Short-Term (Week 2)**:
1. Add accessibility labels to all views
2. Implement LOC decision trace
3. Build EMR context drawer
4. Test with VoiceOver

**Medium-Term (Week 3)**:
1. Add Summary + LOC screen
2. Build Problems module
3. Implement preflight validation
4. Run acceptance tests

---

**Last Updated**: November 9, 2025  
**Status**: Ready for prototype integration  
**Next Review**: After critical fixes applied (Week 2)
