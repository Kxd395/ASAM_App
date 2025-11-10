# Production Hardening Plan

**Date**: 2025-11-09  
**Severity**: CRITICAL  
**Context**: Post-audit production readiness gaps  

---

## Executive Summary

The rules engine implementation is **functionally correct** but **not production-ready**. This document identifies 10 high-impact gaps that must close before clinical deployment.

**Risk Level**: 🔴 HIGH - Silent failures possible, no audit trail, threading issues

---

## 1. Rules Loader Must Never `fatalError` in Prod

**Current State**: `resolveURL()` can throw, wrapper init can fail  
**Risk**: App crash during rules load = complete outage  
**Fix**: Graceful degradation with visible warning

### Implementation

```swift
enum RulesPreflight {
    case ok
    case degraded(String)
    
    static func check(_ bundle: Bundle = .main) -> RulesPreflight {
        do {
            _ = try RulesService(
                bundle: bundle,
                wmRulesPath: "rules/wm_ladder.json",
                locRulesPath: "rules/loc_indication.guard.json",
                operatorsPath: "rules/operators.json"
            )
            return .ok
        } catch {
            return .degraded("Rules unavailable: \(error.localizedDescription)")
        }
    }
}
```

**UI Impact**: Yellow banner "Rules unavailable, using 2.1 fallback. Export disabled."  
**Export Block**: Must prevent PDF generation when degraded

---

## 2. operators.json Is Spec-Only Right Now

**Current State**: File exists but semantics hardcoded in engine  
**Risk**: Spec drift, confusion over source of truth  
**Options**:

### Option A: Remove operators.json (Simplest)
- Hardcode operators in RulesEngine.swift
- Remove file from bundle
- Update docs

### Option B: Table-Driven Operators (Better)
- Load operators.json at init
- Build comparator map dynamically
- Assert known operators exist, refuse to start otherwise

**Recommendation**: Option A for this sprint, Option B for next

---

## 3. Precedence Determinism and ruleId Hygiene

**Current State**: No uniqueness enforcement  
**Risk**: Tie ordering across OS builds = non-deterministic placements  
**Fix**: XCTest assertions

```swift
func testRuleIdUniqueness() throws {
    let service = try RulesService()
    let wmRules = service.wmEngine.rules
    let locRules = service.locEngine.rules
    
    // WM rule IDs unique
    let wmIds = wmRules.map { $0.ruleId }
    XCTAssertEqual(wmIds.count, Set(wmIds).count, "WM ruleId collision")
    
    // LOC rule IDs unique
    let locIds = locRules.map { $0.ruleId }
    XCTAssertEqual(locIds.count, Set(locIds).count, "LOC ruleId collision")
}

func testPrecedenceStrictlyDescending() throws {
    let service = try RulesService()
    let wmRules = service.wmEngine.rules
    
    // Precedence strictly descending
    let precedences = wmRules.map { $0.precedence }
    XCTAssertEqual(precedences, precedences.sorted(by: >), "Precedence not descending")
    
    // No ties
    XCTAssertEqual(precedences.count, Set(precedences).count, "Precedence collision")
}
```

---

## 4. Guard Logic Test Should Verify Precedence Lineage

**Current State**: Test asserts escalation happens  
**Enhancement**: Prove no other rules matched

```swift
func testGuardLogicPreventsDoubleCount() throws {
    // ... existing fixture setup ...
    
    // Assert escalation
    XCTAssertTrue(["3.7", "4.0"].contains(result.loc.recommendation))
    
    // Assert single ruleId
    XCTAssertEqual(result.loc.ruleId, "loc_wm_escalation", 
                   "Guard should fire escalation rule only")
    
    // NEW: Assert no other rules of equal/higher precedence matched
    let escalationPrec = locRules.first { $0.ruleId == "loc_wm_escalation" }!.precedence
    let higherRules = locRules.filter { $0.precedence >= escalationPrec && $0.ruleId != "loc_wm_escalation" }
    for rule in higherRules {
        // None of these should have matched
        XCTAssertFalse(result.loc.matchedRuleIds.contains(rule.ruleId),
                       "Rule \(rule.ruleId) should not match with guard active")
    }
}

func testWMWithoutLOCEscalation() throws {
    // WM suggests 2.7 only, LOC should stay 2.1 (not 2.5 or 3.1)
    let assessment = Assessment(...)
    assessment.domains = [
        Domain(number: 1, severity: 3),  // E=3
        Domain(number: 2, severity: 2),  // Rest <=2
        Domain(number: 3, severity: 2),
        Domain(number: 4, severity: 2),
        Domain(number: 5, severity: 2),
        Domain(number: 6, severity: 2)
    ]
    
    let result = try service.calculateLOC(assessment)
    XCTAssertEqual(result.wm.recommendation, "2.7")
    XCTAssertEqual(result.loc.recommendation, "2.1", "LOC should not escalate without WM trigger")
}
```

---

## 5. Fallback Transparency

**Current State**: Wrapper falls back to 2.1 silently  
**Risk**: Silent misplacement during partial outage  
**Fix**: Visible non-blocking yellow banner

### UI Component

```swift
struct RulesDegradedBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(8)
    }
}

// In ContentView:
if !rulesService.isAvailable {
    RulesDegradedBanner(message: "Rules unavailable. Using 2.1 fallback. Export disabled.")
}
```

---

## 6. ASAM Versioning Needs a Switch, Not Comments

**Current State**: 3.3 removed in code with comments  
**Enhancement**: Runtime switchable ASAM v3/v4

```swift
enum ASAMVersion: String, CaseIterable {
    case v3 = "ASAM 3"
    case v4 = "ASAM 4"
}

extension Assessment {
    @AppStorage("asam_version") var asamVersion: ASAMVersion = .v4
}

// In RulesServiceWrapper:
func locDescription(_ level: String) -> String {
    switch level {
    case "0.5": return "0.5 Early Intervention"
    case "1.0": return "1.0 Outpatient"
    case "2.1": return "2.1 Intensive Outpatient"
    case "2.5": return "2.5 Partial Hospitalization"
    case "3.1": return "3.1 Clinically Managed Low-Intensity Residential"
    case "3.3": 
        if asamVersion == .v3 {
            return "3.3 Clinically Managed Medium-Intensity Residential"
        } else {
            return "Level 3.3 deprecated in ASAM 4"
        }
    case "3.5": return "3.5 Clinically Managed High-Intensity Residential"
    case "3.7": return "3.7 Medically Monitored Intensive Inpatient"
    case "4.0": return "4.0 Medically Managed Intensive Inpatient"
    default: return "Unknown Level: \(level)"
    }
}
```

---

## 7. d1Context and flags Cannot Stay TODO Past This Sprint

**Current State**: Return empty `{}`, most rules won't fire  
**Risk**: Engine appears to work but always returns 2.1 fallback  
**Fix**: Minimal SubstanceRow sheet + Flags toggles

### Expected JSON Shape

```json
{
  "substances": [
    {
      "substance_group": "opioid",
      "last_use_hours": 12,
      "cows": 9,
      "route": ["smoked"]
    },
    {
      "substance_group": "alcohol",
      "last_use_hours": 30,
      "ciwa": 18
    }
  ]
}
```

```json
{
  "vitals_unstable": false,
  "pregnant": false,
  "no_withdrawal_signs": false,
  "acute_psych": false
}
```

### Implementation Files
- `SubstanceRow.swift` - Data model
- `SubstanceSheet.swift` - SwiftUI sheet
- `FlagsSection.swift` - Toggle UI
- `Assessment+Context.swift` - Updated d1Context() and flags()

---

## 8. Threading on RulesServiceWrapper

**Current State**: Published properties can flip off main thread  
**Risk**: SwiftUI crashes, purple runtime warnings  
**Fix**: MainActor + debouncing

```swift
@MainActor
class RulesServiceWrapper: ObservableObject {
    @Published var isAvailable: Bool = false
    @Published var errorMessage: String? = nil
    
    private var debounceTask: Task<Void, Never>?
    
    func calculateLOC(_ assessment: Assessment) -> (wm: WMResult, loc: LOCResult) {
        debounceTask?.cancel()
        
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms
            guard !Task.isCancelled else { return }
            
            do {
                let result = try service.calculateLOC(assessment)
                // ... publish result
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        // Return last known or fallback synchronously
        return (wm: lastWM ?? fallbackWM, loc: lastLOC ?? fallbackLOC)
    }
}
```

---

## 9. Resource Resolution Across Targets

**Current State**: Resolver handles subdirectories  
**Enhancement**: Test across main bundle, test bundle, absolute paths

```swift
func testResourceResolutionMainBundle() throws {
    let service = try RulesService(bundle: .main)
    XCTAssertNotNil(service.wmEngine)
}

func testResourceResolutionTestBundle() throws {
    let service = try RulesService(bundle: Bundle(for: Self.self))
    XCTAssertNotNil(service.wmEngine)
}

func testResourceResolutionAbsolutePath() throws {
    let path = "/Users/.../agent_ops/rules/wm_ladder.json"
    let service = try RulesService(wmRulesPath: path)
    XCTAssertNotNil(service.wmEngine)
}
```

---

## 10. Audit and Tamper Evidence for Rules

**Current State**: No audit trail for which rules generated placement  
**Risk**: Cannot prove which ruleset used, regulatory risk  
**Fix**: SHA-256 checksum + PDF footer stamp

```swift
struct RulesChecksum {
    let sha256: String
    let version: String
    let timestamp: Date
    
    static func compute(bundle: Bundle = .main) -> RulesChecksum? {
        guard let wmURL = bundle.url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules"),
              let locURL = bundle.url(forResource: "loc_indication.guard", withExtension: "json", subdirectory: "rules"),
              let opURL = bundle.url(forResource: "operators", withExtension: "json", subdirectory: "rules") else {
            return nil
        }
        
        let combined = try? [wmURL, locURL, opURL]
            .compactMap { try? Data(contentsOf: $0) }
            .reduce(Data()) { $0 + $1 }
        
        guard let data = combined else { return nil }
        
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        return RulesChecksum(
            sha256: String(hashString.prefix(12)),  // Short hash
            version: "1.1.0",
            timestamp: Date()
        )
    }
}

// In ASAMAssessmentApp.swift:
init() {
    if let checksum = RulesChecksum.compute() {
        print("🔒 Rules loaded: \(checksum.version) [\(checksum.sha256)]")
        AuditService.shared.log(event: "rules_loaded", 
                                metadata: ["sha256": checksum.sha256, 
                                          "version": checksum.version])
    }
}
```

### PDF Footer Addition

```swift
// In PDFExporter:
footer += " | Rules: \(checksum.sha256)"
```

---

## Build and CI Guardrails

### Build Phase Script

```bash
#!/bin/bash
set -e

RULES_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/rules"

echo "🔍 Validating rules bundle..."

# Check presence
for f in wm_ladder.json loc_indication.guard.json operators.json; do
    if [ ! -f "$RULES_DIR/$f" ]; then
        echo "❌ Missing rules file: $f"
        exit 1
    fi
done

# Compute checksum
CHECKSUM=$(shasum -a 256 "$RULES_DIR/"*.json | shasum -a 256 | awk '{print $1}')
echo "$CHECKSUM" > "$RULES_DIR/rules.bundle.sha256"

echo "✅ Rules bundle validated: ${CHECKSUM:0:12}"
```

### CI Additions

```yaml
- name: Validate Rules Schema
  run: |
    npm install -g ajv-cli
    ajv validate -s agent_ops/rules/schemas/wm_ladder.schema.json -d agent_ops/rules/wm_ladder.json
    ajv validate -s agent_ops/rules/schemas/loc_indication.schema.json -d agent_ops/rules/loc_indication.guard.json

- name: Test Precedence Uniqueness
  run: xcodebuild test -scheme ASAMAssessment -only-testing:ASAMAssessmentTests/testPrecedenceStrictlyDescending

- name: Check PHI Tokens
  run: |
    if grep -r "John\|Doe\|patient\|SSN" agent_ops/tests/fixtures/; then
      echo "❌ PHI-like tokens found in fixtures"
      exit 1
    fi
```

---

## UX Polish That Prevents Clinical Pain

### 1. WM Display Separate from LOC

```swift
struct RecommendationCard: View {
    let wm: WMResult
    let loc: LOCResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // WM Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Withdrawal Management")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(wm.recommendation)
                    .font(.title2)
                    .fontWeight(.bold)
                if let ladder = wm.metadata["ladder"] as? [String] {
                    Text("Candidates: \(ladder.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // LOC Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Level of Care")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(loc.recommendation)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Rule: \(loc.ruleId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
```

### 2. Export Block on Degraded Rules

```swift
// In ExportView:
Button("Generate PDF") {
    if !rulesService.isAvailable {
        showDegradedAlert = true
    } else {
        exportPDF()
    }
}
.alert("Rules Unavailable", isPresented: $showDegradedAlert) {
    Button("View Diagnostics") { showDiagnostics = true }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("PDF export blocked. Rules engine degraded. Check Diagnostics for details.")
}
```

### 3. Review Screen "Why" Chips

```swift
struct RecommendationReview: View {
    let result: LOCResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.recommendation)
                .font(.title)
            
            // Why chips
            if let rationale = result.metadata["rationale"] as? [String] {
                FlowLayout(spacing: 8) {
                    ForEach(rationale, id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Text("Rule ID: \(result.ruleId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

---

## Concrete TODOs for MASTER_TODO

```markdown
### T-0023 ASAM Version Setting
- Add ASAMVersion enum (v3, v4)
- Add @AppStorage("asam_version")
- Update locDescription() to hide 3.3 in v4
- Add Settings screen toggle
- **Priority**: MEDIUM
- **Sprint**: Current

### T-0024 SubstanceRow Sheet
- Create SubstanceRow.swift model
- Create SubstanceSheet.swift UI
- Wire to Domain 1 "Add Substance" button
- Update Assessment.d1Context() to return structured data
- **Priority**: CRITICAL
- **Sprint**: Current

### T-0025 Flags UI
- Create FlagsSection.swift
- Add toggles: vitals_unstable, pregnant, no_withdrawal_signs, acute_psych
- Add to Assessment model as @Published properties
- Update Assessment.flags() to return structured data
- **Priority**: CRITICAL
- **Sprint**: Current

### T-0026 Rules Checksum Audit
- Create RulesChecksum.swift
- Compute SHA-256 at app launch
- Log to AuditService
- Stamp in PDF footer
- **Priority**: HIGH
- **Sprint**: Current

### T-0027 JSON Schema Validation
- Create wm_ladder.schema.json
- Create loc_indication.schema.json
- Create operators.schema.json
- Add CI validation step
- **Priority**: MEDIUM
- **Sprint**: Next

### T-0028 Precedence/RuleId Uniqueness Tests
- testRuleIdUniqueness()
- testPrecedenceStrictlyDescending()
- testGuardPrecedenceLineage()
- testWMWithoutLOCEscalation()
- **Priority**: HIGH
- **Sprint**: Current

### T-0029 Threading + Debouncing
- Add @MainActor to RulesServiceWrapper
- Implement 250ms debounce
- Add Task cancellation
- Test with rapid input changes
- **Priority**: HIGH
- **Sprint**: Current

### T-0030 Export Block on Degraded Rules
- Add RulesDegradedBanner component
- Block Export button when !isAvailable
- Add Diagnostics link
- Test with missing rules files
- **Priority**: HIGH
- **Sprint**: Current

### T-0031 Build Phase Rules Validation
- Create validate_rules_bundle.sh
- Add to Xcode build phases
- Test failure path
- **Priority**: MEDIUM
- **Sprint**: Next

### T-0032 WM Display Separate from LOC
- Create RecommendationCard component
- Show WM candidates ladder
- Show LOC with ruleId
- Add "Why" chips from metadata
- **Priority**: MEDIUM
- **Sprint**: Current
```

---

## Priority Matrix

| ID | Task | Impact | Effort | Priority | Sprint |
|----|------|--------|--------|----------|--------|
| T-0024 | SubstanceRow Sheet | 🔴 CRITICAL | Medium | P0 | Current |
| T-0025 | Flags UI | 🔴 CRITICAL | Small | P0 | Current |
| T-0029 | Threading + Debounce | 🔴 HIGH | Small | P1 | Current |
| T-0030 | Export Block | 🔴 HIGH | Small | P1 | Current |
| T-0026 | Checksum Audit | 🟠 HIGH | Medium | P2 | Current |
| T-0028 | Uniqueness Tests | 🟠 HIGH | Small | P2 | Current |
| T-0032 | WM Display | 🟡 MEDIUM | Medium | P3 | Current |
| T-0023 | ASAM Version Switch | 🟡 MEDIUM | Small | P3 | Current |
| T-0027 | Schema Validation | 🟡 MEDIUM | Large | P4 | Next |
| T-0031 | Build Validation | 🟡 MEDIUM | Small | P4 | Next |

---

## Ship Criteria

**Cannot deploy without**:
- ✅ SubstanceRow sheet (T-0024)
- ✅ Flags UI (T-0025)
- ✅ Threading fixes (T-0029)
- ✅ Export block (T-0030)

**Should not deploy without**:
- ⚠️ Checksum audit (T-0026)
- ⚠️ Uniqueness tests (T-0028)

**Nice to have**:
- 💡 WM display polish (T-0032)
- 💡 ASAM version switch (T-0023)

---

## Next Steps

1. **Immediate** (30 min): Implement RulesServiceWrapper v2 with MainActor + debouncing
2. **This Session** (1 hour): Create SubstanceRow + Flags UI components
3. **This Sprint** (2 hours): Add checksum audit + uniqueness tests
4. **CI Integration** (1 hour): Build validation script + schema checks

**End State**: Production-ready rules engine with audit trail, graceful degradation, and clinical data capture.
