# ASAM App Master TODO + Audit Plan

**Created**: November 13, 2025  
**Status**: Active - Ready for Execution  
**Timeline**: 4-day sprint  
**Branch**: `dev`

---

## 🚨 P0 BLOCKERS (Must Fix Before Demo)

> **🔒 CRITICAL**: See [SECURITY_PRIVACY_HARDENING.md](SECURITY_PRIVACY_HARDENING.md) for production-ready security scaffolds that MUST be implemented alongside these P0 blockers. This includes:
> - Encryption, audit logging, ruleset versioning, and compliance requirements
> - **Severity Auto-Calculation + Clinician Override** (Section 11): Auto-calculate severity (0-4) from questionnaire answers for all dimensions (D1-D6), with clinician override capability, audit trail, and emergency floor constraints. Required for clinical consistency and HIPAA compliance.

### 1. Intake Header (Before D1 Access)
**Status**: ❌ Not Implemented  
**Effort**: 2-3 hours  
**Blocking**: All dimension work

**Required Fields**:
- [ ] Patient Name (full name)
- [ ] Date of Birth (MM/DD/YYYY)
- [ ] Sex at Birth (M/F/Other + specify)
- [ ] MRN (Medical Record Number)
- [ ] FIN (Financial/Encounter ID)
- [ ] Encounter Date/Time (auto-populated, editable)
- [ ] Assessment Location/Facility
- [ ] Clinician Name
- [ ] Clinician Credentials
- [ ] Consent Signed (checkbox + timestamp)

**Validation Gates**:
- Block D1 access until all required fields filled
- Show "Complete Intake Header" banner
- Store in `header.json` per storage spec

**Files to Create/Modify**:
- `ios/ASAMAssessment/ASAMAssessment/Views/IntakeHeaderView.swift`
- `ios/ASAMAssessment/ASAMAssessment/Models/IntakeHeader.swift`
- Update `ContentView.swift` to gate dimension access

---

### 2. Central Validation Matrix
**Status**: ❌ Not Implemented  
**Effort**: 4-6 hours  
**Blocking**: All domain logic

**Implementation**:
```swift
// ios/ASAMAssessment/ASAMAssessment/Services/ValidationMatrix.swift

enum ValidationRule {
    case required(path: String, when: String?)
    case clear(paths: [String], when: String, toast: String?, undoBucket: String?)
    case charLimit(path: String, max: Int, warnAt: Int?)
    case ttl(path: String, seconds: Int)
    case mutualExclusion(paths: [String])
    case implies(when: String, then: String)
    case minSeverity(when: String, min: Int)
    case visibleIf(path: String, when: String)
}

struct ValidationMatrix {
    static let rules: [ValidationRule] = [
        // D1 Rules
        .mutualExclusion(paths: ["d1.substances[*].frequency:never", "d1.substances[*].routes[*]"]),
        .ttl(path: "d1.usedLast48h", seconds: 48 * 3600),
        .required(path: "d1.currentWithdrawal.value", when: "d1.substances[opioid|alcohol|benzo].lastUse <= P14D"),
        
        // D2 Rules
        .minSeverity(when: "d2.lifeThreatening.value == true", min: 4),
        .required(path: "d2.lifeThreatening.note", when: "d2.lifeThreatening.value == true"),
        
        // D3 Rules
        .implies(when: "d3.symptoms.*.onlyWhenUsing == true", then: "d3.symptoms.*.past30 = true"),
        .minSeverity(when: "d3.suicidal.today.value == true", min: 3),
        .minSeverity(when: "d3.homicidal.today.value == true", min: 4),
        .required(path: "d3.suicidal.note", when: "d3.suicidal.today.value == true"),
        
        // D4 Rules
        .implies(when: "d4.needForTreatment.value == 'canStopAnytime'", then: "d4.stageOfChange.issue1 = 'Precontemplation'"),
        
        // D5 Rules
        .minSeverity(when: "d5.imminence.value == 'hoursDays'", min: 3),
        .clear(paths: ["d5.longestAbstinence.*"], when: "d5.neverInRecovery == true", toast: "Abstinence fields cleared", undoBucket: "d5_abstinence"),
        
        // D6 Rules
        .minSeverity(when: "d6.safety.weapon == true || d6.safety.killThreat == true", min: 3)
    ]
    
    func apply(to state: inout Assessment, from previous: Assessment) -> [ValidationError] {
        var errors: [ValidationError] = []
        // Implementation here
        return errors
    }
}
```

**Tasks**:
- [ ] Create `ValidationMatrix.swift`
- [ ] Implement rule evaluation engine
- [ ] Add expression parser for `when` conditions
- [ ] Wire to `onChange`/`onBlur` handlers
- [ ] Add unit tests for all rules

---

### 3. Emergency Banner Registry
**Status**: ❌ Not Implemented  
**Effort**: 3-4 hours  
**Blocking**: Safety compliance

**Implementation**:
```swift
// ios/ASAMAssessment/ASAMAssessment/Services/EmergencyBanner.swift

struct EmergencyTrigger {
    let id: String
    let dimension: Int
    let condition: String
    let message: String
    let minSeverity: Int?
    let requiresReportable: Bool
}

struct EmergencyBannerRegistry {
    static let triggers: [EmergencyTrigger] = [
        // D1 Triggers
        EmergencyTrigger(
            id: "d1_severe_withdrawal",
            dimension: 1,
            condition: "d1.currentWithdrawal.value == true && d1.usedLast48h.value == true",
            message: "Patient experiencing active withdrawal with recent use. Immediate medical evaluation required.",
            minSeverity: 3,
            requiresReportable: false
        ),
        
        // D2 Triggers
        EmergencyTrigger(
            id: "d2_life_threatening",
            dimension: 2,
            condition: "d2.lifeThreatening.value == true",
            message: "Life-threatening medical symptoms reported. Immediate medical intervention required.",
            minSeverity: 4,
            requiresReportable: true
        ),
        
        // D3 Triggers
        EmergencyTrigger(
            id: "d3_suicidal_today",
            dimension: 3,
            condition: "d3.suicidal.today.value == true",
            message: "Active suicidal ideation reported. Immediate safety assessment and intervention required.",
            minSeverity: 3,
            requiresReportable: true
        ),
        EmergencyTrigger(
            id: "d3_homicidal_today",
            dimension: 3,
            condition: "d3.homicidal.today.value == true",
            message: "Active homicidal ideation reported. Immediate safety protocol activation required.",
            minSeverity: 4,
            requiresReportable: true
        ),
        
        // D5 Triggers
        EmergencyTrigger(
            id: "d5_imminent_relapse",
            dimension: 5,
            condition: "d5.imminence.value == 'hoursDays'",
            message: "Relapse anticipated within hours/days. Immediate intervention planning required.",
            minSeverity: 3,
            requiresReportable: false
        ),
        
        // D6 Triggers
        EmergencyTrigger(
            id: "d6_lethal_threat",
            dimension: 6,
            condition: "d6.safety.weapon == true || d6.safety.killThreat == true",
            message: "Lethal safety threat identified. Immediate safety planning and possible mandated reporting required.",
            minSeverity: 3,
            requiresReportable: true
        )
    ]
    
    func shouldShowBanner(for state: Assessment) -> EmergencyTrigger? {
        // Evaluate all triggers, return first match
        return triggers.first { trigger in
            evaluateCondition(trigger.condition, state: state)
        }
    }
}
```

**Tasks**:
- [ ] Create `EmergencyBanner.swift`
- [ ] Create `EmergencyBannerView.swift` with `role="alertdialog"`
- [ ] Implement condition evaluator
- [ ] Add dismiss tracking (user ID + timestamp)
- [ ] Wire to all dimension views
- [ ] Add unit tests for all triggers

---

### 4. Storage Architecture Export Layer
**Status**: ⚠️ Partially Implemented (UserDefaults only)  
**Effort**: 8-12 hours  
**Blocking**: PDF export

**Phase 1 Tasks** (This Sprint):
- [ ] Create `StorageExporter.swift`
  - [ ] `exportAssessment(_:to:)` method
  - [ ] `makeHeader(from:)` - convert Assessment → header.json
  - [ ] `flattenAnswers(from:)` - convert Domain.answers → field paths
  - [ ] `makeComputed(from:)` - extract severity/progress/flags
  - [ ] Atomic file writes with tmp/ folder

- [ ] Create `PDFExporter.swift`
  - [ ] Load template from assets/
  - [ ] Map field paths to PDF form fields via FORM_FIELD_MAP.json
  - [ ] Add signature image placement
  - [ ] Save to artifacts/ folder
  - [ ] Create frozen bundle.json snapshot

- [ ] Wire to UI
  - [ ] Add "Export PDF" button to assessment detail
  - [ ] Show export progress sheet
  - [ ] Display exported PDF preview
  - [ ] Handle export errors

**See**: [docs/specs/STORAGE_EXPORT_SPRINT_PLAN.md](specs/STORAGE_EXPORT_SPRINT_PLAN.md)

---

## 📋 Dimension-Specific Audit Checklists

### D1: Acute Intoxication/Withdrawal

**Logic Audit**:
- [ ] Q1 Substance Grid: Route disabled when frequency = "Never used"
- [ ] Q1 Duration validation: Duration > last use date shows error
- [ ] Q2 Withdrawal Bother: Hidden if all Q1 = "Never used"
- [ ] Q3 Current Withdrawal: Required if last use ≤7d (opioids) or ≤14d (alcohol/benzos)
- [ ] Q7 Used Last 48h: TTL expires after 48 hours, shows "Data stale" banner
- [ ] Emergency: Severe withdrawal + recent use triggers banner

**Quick-Add Chips**:
- [ ] Q1 Routes: "Smoked heroin", "Injected cocaine"
- [ ] Q3 Symptoms: Grouped by substance (Opioids: "Yawning", "Lacrimation"; Alcohol: "Tremor", "Seizure")
- [ ] Q8 Observation: "Slurred speech", "Ataxia", "Tremor", "Agitation"

**Severity**:
- [ ] Auto-suggest based on withdrawal symptoms + frequency
- [ ] Require rationale for Sev 3/4
- [ ] Emergency banner raises floor to Sev 3+

**Test Fixtures**:
- [ ] `d1_sev4_withdrawal.json` - Active withdrawal + last use 2d ago
- [ ] `d1_sev0_never_used.json` - All substances "Never used"

---

### D2: Biomedical Conditions

**Logic Audit**:
- [ ] Q5 Chronic Conditions: Auto-answer Q6 if HIV/Hepatitis/TB selected
- [ ] Q7 Stability: Hidden if Q5 empty
- [ ] Q11 Pregnancy: Shown only if sexAtBirth = 'Female'
- [ ] Q11 Pregnancy: Third trimester + opioids triggers Sev 3+ hint
- [ ] Q19 Life-Threatening: Auto-set Sev 4 and block completion until addressed

**Quick-Add Chips**:
- [ ] Q3 Concerns: "Chest pain", "SOB", "Uncontrolled diabetes"
- [ ] Q5 Conditions: Grouped with icons (heart, lung)
- [ ] Q9 Substance Impact: "Skipping insulin to drink", "Missing dialysis"

**Severity**:
- [ ] Life-threatening = auto Sev 4 with emergency banner
- [ ] Unstable chronic conditions suggest Sev 2-3

**Test Fixtures**:
- [ ] `d2_life_threatening.json` - Q19 = Yes, emergency active
- [ ] `d2_pregnancy_third_trimester_opioid.json` - Triggers high severity

---

### D3: Emotional/Behavioral Conditions

**Logic Audit**:
- [ ] Q8 Symptom Matrix: Both checkboxes allowed
- [ ] Q8 Coupling: `onlyWhenUsing = true` → `past30 = true` (auto-set)
- [ ] Q8 Coupling: Clearing `past30` → clear `onlyWhenUsing` + show Undo toast
- [ ] Q10 Hallucinations: Computed from psychosis group, can override
- [ ] Suicidal Today: Emergency banner + min Sev 3 + rationale required
- [ ] Homicidal Today: Emergency banner + min Sev 4 + rationale required

**Quick-Add Chips**:
- [ ] Q8 Symptoms: All 22 symptoms as chips
- [ ] Problem Statements: Common phrases

**Severity**:
- [ ] Suicidal today = min Sev 3
- [ ] Homicidal today = min Sev 4
- [ ] Active psychosis = Sev 3+

**Test Fixtures**:
- [ ] `d3_psychosis_today.json` - Active psychosis, emergency
- [ ] `d3_all_symptoms_none.json` - Neutral baseline
- [ ] `d3_suicidal_today.json` - Suicidal ideation, emergency banner

---

### D4: Readiness to Change

**Logic Audit**:
- [ ] Q5 "Can stop anytime" → auto-set Stage = "Precontemplation"
- [ ] All stage dropdowns sync per issue
- [ ] Ambivalence factors list managed

**Quick-Add Chips**:
- [ ] Problem statements: Common readiness phrases

**Severity**:
- [ ] Precontemplation + high use = suggest Sev 2-3
- [ ] Maintenance stage = suggest Sev 0-1

**Test Fixtures**:
- [ ] `d4_can_stop_anytime.json` - Auto Precontemplation
- [ ] `d4_maintenance.json` - Low severity

---

### D5: Relapse/Continued Use

**Logic Audit**:
- [ ] Q6 Imminence "Hours/Days" → min Sev 3 + rationale required
- [ ] Never in recovery clears abstinence fields + Undo toast
- [ ] Undo bucket: `d5_abstinence` restores all cleared fields

**Quick-Add Chips**:
- [ ] Imminence: "Hours/days", "Weeks", "Months"
- [ ] Triggers: Common relapse triggers

**Severity**:
- [ ] Imminent relapse (hours/days) = min Sev 3 + emergency banner
- [ ] Strong recovery history = suggest Sev 0-1

**Test Fixtures**:
- [ ] `d5_hours_days_imminent.json` - Emergency relapse risk
- [ ] `d5_never_in_recovery.json` - Undo clear test

---

### D6: Recovery Environment

**Logic Audit**:
- [ ] Q9 Safety: Any lethal threat (weapon/kill) → min Sev 3 + emergency banner + reportable
- [ ] Q9 Safety: Auto-show "Mark Reportable" button
- [ ] Veteran status gates military-specific questions

**Quick-Add Chips**:
- [ ] Housing: "Stable", "Unstable", "Homeless"
- [ ] Support: Common support types
- [ ] Safety: "Weapon access", "Threats"

**Severity**:
- [ ] Lethal safety threat = min Sev 3 + emergency banner
- [ ] Unstable housing + no support = Sev 2-3
- [ ] Strong support network = Sev 0-1

**Test Fixtures**:
- [ ] `d6_lethal_threat_weapon.json` - Emergency safety issue
- [ ] `d6_unsafe_home.json` - High risk environment

---

## 🧪 Smoke Test Matrix

### Test Coverage Per Dimension

| Dimension | Fixture | Expected Outcomes |
|-----------|---------|-------------------|
| **D1** | `d1_sev4_withdrawal.json` | Emergency banner, min Sev 3, withdrawal chips populate |
| | `d1_sev0_never_used.json` | Q2/Q3 hidden, no emergency, Sev 0 suggested |
| | `d1_ttl_expired.json` | Q7 shows "Data stale" after 48h |
| **D2** | `d2_life_threatening.json` | Emergency banner, auto Sev 4, blocks completion |
| | `d2_pregnancy_opioid.json` | Sev 3+ hint, pregnancy fields visible |
| **D3** | `d3_suicidal_today.json` | Emergency banner, min Sev 3, rationale required |
| | `d3_homicidal_today.json` | Emergency banner, min Sev 4, reportable |
| | `d3_symptom_matrix.json` | Coupling: onlyWhenUsing → past30, Undo works |
| **D4** | `d4_can_stop_anytime.json` | Auto Precontemplation stage |
| **D5** | `d5_hours_days_imminent.json` | Emergency banner, min Sev 3, rationale required |
| | `d5_never_recovery.json` | Abstinence cleared + Undo toast |
| **D6** | `d6_lethal_threat.json` | Emergency banner, min Sev 3, reportable |
| | `d6_stable_support.json` | Sev 0-1 suggested |

### Automated Test Commands

```bash
# Unit tests
cd ios/ASAMAssessment
xcodebuild test -scheme ASAMAssessment -destination 'platform=iOS Simulator,name=iPhone 16'

# Specific test suites
xcodebuild test -scheme ASAMAssessment -only-testing:ASAMAssessmentTests/ValidationMatrixTests
xcodebuild test -scheme ASAMAssessment -only-testing:ASAMAssessmentTests/EmergencyBannerTests
xcodebuild test -scheme ASAMAssessment -only-testing:ASAMAssessmentTests/StorageExporterTests
```

---

## 📄 Audit Documentation Checklist

### Created Documents ✅
- [x] [STORAGE_ARCHITECTURE_COMPARISON.md](specs/STORAGE_ARCHITECTURE_COMPARISON.md) - Current vs proposed storage
- [x] [STORAGE_EXPORT_SPRINT_PLAN.md](specs/STORAGE_EXPORT_SPRINT_PLAN.md) - Export implementation roadmap
- [x] [STORAGE_ANALYSIS_SUMMARY.md](STORAGE_ANALYSIS_SUMMARY.md) - Executive summary
- [x] [UX_REVIEW_NOVEMBER_13_2025.md](reviews/UX_REVIEW_NOVEMBER_13_2025.md) - 10 tickets, 3 sprints

### Documents to Create 📋
- [ ] `docs/audit/D1_AUDIT_CHECKLIST.md` - Dimension 1 complete audit
- [ ] `docs/audit/D2_AUDIT_CHECKLIST.md` - Dimension 2 complete audit
- [ ] `docs/audit/D3_AUDIT_CHECKLIST.md` - Dimension 3 complete audit
- [ ] `docs/audit/D4_AUDIT_CHECKLIST.md` - Dimension 4 complete audit
- [ ] `docs/audit/D5_AUDIT_CHECKLIST.md` - Dimension 5 complete audit
- [ ] `docs/audit/D6_AUDIT_CHECKLIST.md` - Dimension 6 complete audit
- [ ] `docs/audit/VALIDATION_MATRIX_SPEC.md` - Complete validation rules
- [ ] `docs/audit/EMERGENCY_BANNER_SPEC.md` - All emergency triggers
- [ ] `docs/audit/QUICK_ADD_CHIPS_CATALOG.md` - All chips per question
- [ ] `docs/audit/SETTINGS_IMPLEMENTATION.md` - Complete settings spec
- [ ] `docs/audit/INTAKE_HEADER_SPEC.md` - Header fields and validation

### Review Documents (Already Exist)
- [x] [Mod1.md](reviews/Mod1.md) - Original hypercritical review
- [x] [mod1.1.md](reviews/mod1.1.md) - Question-by-question logic audit
- [x] [mod1.11.md](reviews/mod1.11.md) - Patches and drop-in artifacts
- [x] [display n settings.md](reviews/display%20n%20settings.md) - Settings requirements
- [x] [logo.md](agent_ops/docs/review/logo.md) - Icon and branding spec

---

## 📅 5-Day Execution Schedule

> **⚠️ UPDATED**: Schedule extended to 5 days to include critical security hardening. See [SECURITY_PRIVACY_HARDENING.md](SECURITY_PRIVACY_HARDENING.md) for Day 0.5 security foundations.

### Day 0.5: Security Foundations (4 hours) - CRITICAL
**Morning (2h)**:
1. SecureStore Implementation (1.5h)
   - Create `SecureStore.swift`
   - Generate AES-256 key, store in Keychain with `.afterFirstUnlockThisDeviceOnly`
   - Mark storage folder `.isExcludedFromBackup = true`
   - Test: Key survives app restart, no iCloud backup

2. AuditLog Foundation (0.5h)
   - Create `AuditLog.swift` with JSONL append-only
   - Test: Append works, survives crashes

**Afternoon (2h)**:
3. Ruleset Versioning (1h)
   - Add `ruleset: "v2.0.0"` to Assessment
   - Add `rulesetChecksum` (SHA-256 of ValidationMatrix.rules)
   - Include in export envelope
   - Test: Persists in export, enables PDF reproducibility

4. Enhanced IntakeHeader (1h)
   - Add `sessionId` auto-generation (ASAM_20251113_143022)
   - Add `timezone`, `encounterId`, `facilityAdd MRN/FIN normalization and validation
   - Add DOB range validation (0-120 years)
   - Test: All validations work

**Deliverables**:
- ✅ AES-256 encryption enabled, no iCloud backup
- ✅ Audit log appending (field changes, emergency banners, severity overrides)
- ✅ Ruleset versioned for export reproducibility
- ✅ IntakeHeader validation working (MRN, DOB, required fields)

---

### Day 1: Foundations (P0 Blockers + Severity)
**12 hours** _(extended from 8h to include severity system)_

**Morning (6h)**:
1. Intake Header Implementation (2h)
   - Create IntakeHeaderView.swift
   - Create IntakeHeader model
   - Wire gating logic to ContentView
   - Test: Block D1 until header complete

2. **Severity Auto-Calculation (3h)** _(NEW)_
   - Create `SeverityCalculator.swift` with all D1-D6 logic
   - Add `DomainState` and `AssessmentSeverity` structs to Assessment model
   - Implement dimension-specific calculations:
     - D1: withdrawal severity + recent use → emergency
     - D2: life-threatening conditions, pregnancy, DDI
     - D3: suicide (plan + intent), homicidal (target), psychosis
     - D4: Stages of Change calculation, barriers
     - D5: imminent relapse, high-risk environment
     - D6: homelessness, domestic violence
   - Integrate into Domain answer changes (auto-recalc on update)
   - Test: All dimension calculations with test fixtures

3. Validation Matrix Core (1h)
   - Create ValidationMatrix.swift skeleton
   - Implement rule evaluation engine
   - Add first 5 rules (D1 + D2 critical)
   - Unit tests for basic rules

**Afternoon (4h)**:
4. Emergency Banner Registry (2h)
   - Create EmergencyBanner.swift
   - Create EmergencyBannerView.swift (UI)
   - Implement condition evaluator
   - Wire to D1, D2, D3 (highest risk)
   - **Hook emergency triggers into severity minFloor calculation**
   - Test: D3 suicidal triggers banner AND sets minFloor = 3

5. **Severity Override System (2h)** _(NEW)_
   - Add `SeverityOverride` struct to models
   - Create `SeverityOverrideManager` with validation (floor, reason, emergency ack)
   - Create `SeverityOverrideSheet` SwiftUI view
   - Create `SeverityChip` component (color-coded 0-4)
   - Add override button to each domain summary
   - Test: Floor constraints work, acknowledgement required, audit logged

**Evening (2h)**:
6. Storage Export Foundation (1h)
   - Create StorageExporter.swift skeleton
   - Implement basic directory structure
   - Test: Create assessments/<id>/ folder

7. AppSettings + Patient Header (1h)
   - Paste `AppSettings.swift` from security guide
   - Paste `CompactPatientHeader.swift` from security guide
   - Wire patient header to all dimension forms (sticky)
   - Test: Settings persist, header always visible

**Deliverables**:
- ✅ Intake header blocks D1 access
- ✅ 5 validation rules working
- ✅ Emergency banner shows for D3 suicidal
- ✅ **All severity calculations working (D1-D6)**
- ✅ **Override system with audit trail**
- ✅ **Emergency floors enforced in override**
- ✅ Export creates correct folder structure
- ✅ Settings + patient header complete

---

### Day 2: Validation + Emergency (Complete Logic)
**8 hours**

**Morning (4h)**:
1. Complete Validation Matrix (3h)
   - Add all D3-D6 rules
   - Implement TTL for D1.Q7
   - Implement clear-with-undo for D5
   - Add expression parser for complex conditions
   - Unit tests for all rules

2. Test Fixtures Creation (1h)
   - Create all 12 test fixtures
   - Place in `fixtures/patients/`
   - Verify each loads without error

**Afternoon (4h)**:
3. Complete Emergency Registry (2h)
   - Add all remaining triggers (D5, D6)
   - Implement dismiss tracking
   - Add audit logging for dismissals
   - Test: All emergency scenarios

4. Quick-Add Chips Implementation (2h)
   - Create QuickAddChip.swift component
   - Add chip catalogs for D1, D3
   - Wire to UI
   - Test: Chips populate fields correctly

**Deliverables**:
- ✅ All validation rules implemented
- ✅ All emergency triggers working
- ✅ 12 test fixtures created
- ✅ Quick-add chips functional

---

### Day 3: Storage + Export (PDF Generation)
**8 hours**

**Morning (4h)**:
1. Storage Exporter Complete (3h)
   - Implement makeHeader()
   - Implement flattenAnswers()
   - Implement makeComputed()
   - Atomic file writes with tmp/
   - Test: Export complete assessment

2. PDF Template Setup (1h)
   - Verify template exists
   - Load FORM_FIELD_MAP.json
   - Document missing fields

**Afternoon (4h)**:
3. PDF Exporter Implementation (3h)
   - Create PDFExporter.swift
   - Load template + fill fields
   - Add signature placement
   - Save to artifacts/
   - Create frozen bundle.json

4. Export UI Wiring (1h)
   - Add "Export PDF" button
   - Create ExportProgressView
   - Wire error handling
   - Test: End-to-end export

**Deliverables**:
- ✅ Export creates header/answers/computed.json
- ✅ PDF generates with filled fields
- ✅ Frozen bundle snapshot created
- ✅ UI shows export progress

---

### Day 4: Testing + Documentation
**8 hours**

**Morning (4h)**:
1. Smoke Test Execution (2h)
   - Run all 12 fixture tests
   - Document failures
   - Fix critical issues
   - Re-run until green

2. Settings Implementation Start (2h)
   - Create AppSettings model
   - Create SettingsView sections
   - Implement Privacy section
   - Implement Export defaults section

**Afternoon (4h)**:
3. Documentation Completion (3h)
   - Create all dimension audit checklists
   - Complete validation matrix spec
   - Complete emergency banner spec
   - Update INDEX.md

4. Final Build + QA (1h)
   - Clean build
   - Run all tests
   - Manual smoke test on simulator
   - Tag release candidate

**Deliverables**:
- ✅ All smoke tests passing
- ✅ Settings UI in place
- ✅ All audit docs created
- ✅ Clean build + passing tests

---

## 🤖 Agent Prompts (Ready to Use)

### Prompt 1: Intake Header

```
Task: Create intake header that blocks dimension access until complete

1. Create IntakeHeaderView.swift:
   - All required fields (Name, DOB, Sex, MRN, FIN, etc.)
   - Validation: All fields required before proceeding
   - Save to Assessment.header
   - Show completion checkmark when done

2. Create IntakeHeader model:
   struct IntakeHeader: Codable {
       var patientName: String
       var dateOfBirth: Date
       var sexAtBirth: String
       var mrn: String
       var fin: String
       var encounterDateTime: Date
       var location: String
       var clinicianName: String
       var clinicianCredentials: String
       var consentSigned: Bool
       var consentTimestamp: Date?
   }

3. Wire gating to ContentView:
   - Show IntakeHeaderView first
   - Disable dimension navigation until header complete
   - Show banner: "Complete Intake Header to begin assessment"

4. Test: Verify D1 blocked until all fields filled

Output: Screenshot of header form + blocked D1 access
```

---

### Prompt 2: Validation Matrix

```
Task: Implement central validation matrix with all dimension rules

1. Create ValidationMatrix.swift:
   - Copy enum ValidationRule structure from master plan
   - Implement all 20+ rules from D1-D6
   - Add apply(to:from:) method
   - Return ValidationError array

2. Create expression evaluator:
   - Parse "when" conditions
   - Support operators: ==, !=, <=, >=, &&, ||
   - Support field paths: "d1.substances[*].frequency"
   - Handle date comparisons: "<= P14D"

3. Wire to UI:
   - Call on onChange for all form fields
   - Call on onBlur
   - Display errors inline
   - Block "Mark Complete" if errors exist

4. Add unit tests:
   - Test each rule individually
   - Test TTL expiration
   - Test clear-with-undo
   - Test implies chains

Output: All validation tests green + screenshot of validation error
```

---

### Prompt 3: Emergency Banner

```
Task: Implement emergency banner registry and UI

1. Create EmergencyBanner.swift:
   - Copy EmergencyTrigger struct from master plan
   - Add all 6 triggers (D1-D6)
   - Implement shouldShowBanner(for:) evaluation

2. Create EmergencyBannerView.swift:
   - role="alertdialog"
   - Focus trap (Esc dismisses if allowed)
   - Primary button: "Open Safety Protocol"
   - Secondary button: "Mark Reportable"
   - Log dismissals with user ID + timestamp

3. Wire to dimension views:
   - Check on every answer change
   - Show banner immediately when triggered
   - Raise severity floor if required
   - Block completion until acknowledged

4. Test all triggers:
   - D1: Severe withdrawal
   - D2: Life-threatening
   - D3: Suicidal today
   - D3: Homicidal today
   - D5: Imminent relapse
   - D6: Lethal threat

Output: Screenshot of emergency banner + test results
```

---

### Prompt 4: Storage Export

```
Task: Implement file-based export for PDF generation

1. Create StorageExporter.swift:
   - export(assessment:to:) method
   - Create Documents/ASAM/assessments/<id>/ structure
   - Write header.json (from Assessment metadata)
   - Write answers.json (flatten Domain.answers with field_path keys)
   - Write computed.json (severity + progress + emergency state)
   - Use tmp/ folder for atomic writes

2. Create PDFExporter.swift:
   - Load template from assets/ASAM_TreatmentPlan_Template.pdf
   - Load FORM_FIELD_MAP.json
   - Fill form fields from answers.json
   - Add signature image at designated location
   - Save to artifacts/asam_<id>_v1.pdf
   - Create frozen bundle.json snapshot

3. Wire to UI:
   - Add "Export PDF" button in assessment detail
   - Show ExportProgressView during export
   - Display PDF preview on completion
   - Handle errors gracefully

4. Test:
   - Export complete assessment
   - Verify all JSON files created
   - Verify PDF generated
   - Verify bundle.json frozen snapshot

Output: Exported files + PDF screenshot
```

---

## 📊 Success Criteria

### P0 Complete When:
- [x] Build succeeds (✅ Done - commit aadb297)
- [ ] Intake header blocks D1 access
- [ ] All validation rules enforced
- [ ] All emergency triggers working
- [ ] PDF export generates correctly
- [ ] All smoke tests passing

### Ready for Demo When:
- [ ] All P0 criteria met
- [ ] Settings UI in place (basic)
- [ ] All audit docs created
- [ ] Manual QA pass complete
- [ ] No critical bugs

---

## 🔗 Quick Links

**Storage Architecture**:
- [Storage Comparison](specs/STORAGE_ARCHITECTURE_COMPARISON.md)
- [Export Sprint Plan](specs/STORAGE_EXPORT_SPRINT_PLAN.md)
- [Storage Summary](STORAGE_ANALYSIS_SUMMARY.md)

**UX & Reviews**:
- [UX Review (Nov 13)](reviews/UX_REVIEW_NOVEMBER_13_2025.md)
- [Display & Settings](reviews/display%20n%20settings.md)
- [Mod1 Complete Review](reviews/Mod1.md)
- [Mod1.1 Logic Audit](reviews/mod1.1.md)
- [Mod1.11 Patches](reviews/mod1.11.md)

**Project Docs**:
- [INDEX.md](INDEX.md) - Master index
- [PROJECT_STATUS](ios/PROJECT_STATUS.md) - iOS status
- [CHANGELOG](CHANGELOG.md) - Version history

---

## 📝 Notes

**Current State** (Nov 13, 2025):
- ✅ Build fixed - all errors resolved
- ✅ Sprint 1 UX fixes merged (dynamic headers, footer button, decision badge)
- ✅ Storage analysis complete
- ⚠️ No intake header (P0 blocker)
- ⚠️ No validation matrix (P0 blocker)
- ⚠️ No emergency banner (P0 blocker)
- ⚠️ No PDF export (P0 blocker)

**Branch Status**:
- Current: `dev` (6 commits ahead of master)
- Last commit: `aadb297` - Build error fixes
- Clean: No uncommitted changes

**Next Immediate Steps**:
1. Start Day 1 execution
2. Create intake header (2h)
3. Create validation matrix core (2h)
4. Create emergency banner (3h)
5. Start storage export foundation (1h)
