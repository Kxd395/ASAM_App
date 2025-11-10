# What's Missing - Integration Checklist

**Date:** 2025-11-09  
**Status:** 🟡 Partially Complete - Xcode Integration Needed

## ✅ What's Already Done

### Rules Infrastructure
- ✅ **RulesEngine.swift** - Created in `ios/ASAMAssessment/Services/`
- ✅ **RulesService.swift** - Created in `ios/ASAMAssessment/Services/`
- ✅ **loc_indication.guard.json** - Created in `agent_ops/rules/`
- ✅ **operators.json** - Exists in `agent_ops/rules/`
- ✅ **wm_ladder.json** - Exists in `agent_ops/rules/`
- ✅ **12 test fixtures** - Exist in `agent_ops/tests/fixtures/`
- ✅ **T-0022 guard logic** - Implemented

### Documentation
- ✅ **RULES_ENGINE_IOS_INTEGRATION_COMPLETE.md** - Complete guide
- ✅ **FIXTURES_INTEGRATION_COMPLETE.md** - Fixtures documented
- ✅ **ROOT_HYGIENE_CLEANUP.md** - Constitution compliance
- ✅ **TODO updated** - 17 open, 7 done

---

## ❌ What's Missing - Xcode Integration

### 1. **Add Swift Files to Xcode Project Target** ⚠️ CRITICAL

**Problem:** The Swift files exist on disk but may not be in the Xcode project target.

**What You Need to Do:**
1. Open `ios/ASAMAssessment/ASAMAssessment.xcodeproj` in Xcode
2. In Project Navigator, right-click on `Services` folder
3. Select "Add Files to 'ASAMAssessment'..."
4. Navigate to `ios/ASAMAssessment/Services/`
5. Select both:
   - ✅ `RulesEngine.swift`
   - ✅ `RulesService.swift`
6. **CRITICAL:** Check the box for "ASAMAssessment" target
7. Click "Add"

**How to Verify:**
- Click on `RulesEngine.swift` in Project Navigator
- Check "Target Membership" in right panel (File Inspector)
- ✅ "ASAMAssessment" should be checked
- Do the same for `RulesService.swift`

---

### 2. **Add Rules Files to App Bundle** ⚠️ CRITICAL

**Problem:** Rules JSON files need to be bundled with the app so they're available at runtime.

**What You Need to Do:**
1. In Xcode Project Navigator
2. Right-click on project root (ASAMAssessment)
3. Select "Add Files to 'ASAMAssessment'..."
4. Navigate to your project root and select `agent_ops/rules/` folder
5. **CRITICAL:** Choose "Create folder references" (blue folder icon, NOT yellow group)
6. **CRITICAL:** Check "ASAMAssessment" target
7. Click "Add"

**Files That Should Be Bundled:**
- ✅ `wm_ladder.json`
- ✅ `loc_indication.guard.json` (or `loc_indication.json`)
- ✅ `operators.json`

**How to Verify:**
- In Project Navigator, `agent_ops/rules/` should appear as a **blue folder**
- Click on any JSON file
- Check "Target Membership" → "ASAMAssessment" should be checked
- Build the app (Cmd+B)
- Rules files should be in app bundle

---

### 3. **Wire RulesService to App** 🔧 IMPLEMENTATION NEEDED

**Problem:** App still uses old `LOCService` with hardcoded logic.

**Current State (from screenshot):**
```swift
// ASAMAssessmentApp.swift lines 13-15
@StateObject private var assessmentStore = AssessmentStore()
@StateObject private var auditService = AuditService()
@StateObject private var locService = LOCService()  // ❌ OLD HARDCODED SERVICE
```

**What You Need to Do:**

#### Option A: Replace LOCService (Recommended)
```swift
// ASAMAssessmentApp.swift
@StateObject private var assessmentStore = AssessmentStore()
@StateObject private var auditService = AuditService()
@StateObject private var rulesService = RulesService()  // ✅ NEW RULES ENGINE

var body: some Scene {
    WindowGroup {
        ContentView()
            .environmentObject(assessmentStore)
            .environmentObject(auditService)
            .environmentObject(rulesService)  // ✅ INJECT INTO ENVIRONMENT
    }
}
```

**Then update wherever LOC is calculated:**
```swift
// OLD: In some view or service
let locResult = locService.calculateLOC(from: assessment)

// NEW: Using RulesService
let result = rulesService.evaluate(
    severities: assessment.domainSeverities(),
    d1Context: assessment.d1Context,
    flags: assessment.flags
)
// result.wm.indicated, result.loc.indicated
```

#### Option B: Parallel Implementation (For Testing)
Keep both temporarily to compare outputs:
```swift
@StateObject private var locService = LOCService()      // Keep temporarily
@StateObject private var rulesService = RulesService()  // Add new

// Compare outputs in development
#if DEBUG
let oldResult = locService.calculateLOC(from: assessment)
let newResult = rulesService.evaluate(...)
print("Old LOC: \(oldResult.level), New LOC: \(newResult.loc.indicated)")
assert(oldResult.level == newResult.loc.indicated, "Migration validation")
#endif
```

---

### 4. **Add Helper Methods to Assessment Model** 🔧 NEEDED

**Problem:** Assessment model needs methods to convert to dictionary format for RulesService.

**What You Need to Add:**

```swift
// ios/ASAMAssessment/Models/Assessment.swift
extension Assessment {
    
    /// Convert domain severities to dictionary format for rules engine
    func domainSeverities() -> [String: Int] {
        var severities: [String: Int] = [:]
        for domain in domains {
            severities[domain.letter] = domain.severity.rawValue
        }
        return severities
    }
    
    /// Convert D1 substance data to dictionary format
    func d1Context() -> [String: Any] {
        // Extract substance details from Domain A
        guard let domainA = domains.first(where: { $0.letter == "A" }) else {
            return [:]
        }
        
        var substances: [[String: Any]] = []
        // Map your substance data structure here
        // Example:
        // for substance in domainA.substances {
        //     substances.append([
        //         "substance_group": substance.group,
        //         "last_use_hours": substance.lastUseHours,
        //         "cows": substance.cowsScore,
        //         "ciwa": substance.ciwaScore
        //     ])
        // }
        
        return ["substances": substances]
    }
    
    /// Convert flags to dictionary format
    func flags() -> [String: Bool] {
        return [
            "vitals_unstable": false,  // Map from your data
            "no_withdrawal_signs": false  // Map from your data
        ]
    }
}
```

---

### 5. **Create XCTest for Rules Engine** 🧪 TESTING NEEDED

**Problem:** No tests written yet for the rules engine.

**What You Need to Do:**

1. **Add test file to Xcode:**
   - Right-click `ASAMAssessmentTests` folder
   - New File → Swift File
   - Name it `RulesEngineTests.swift`
   - Check "ASAMAssessmentTests" target

2. **Implement fixture loader:**

```swift
// ios/ASAMAssessment/ASAMAssessment/ASAMAssessmentTests/RulesEngineTests.swift
import XCTest
@testable import ASAMAssessment

final class RulesEngineTests: XCTestCase {
    var service: RulesService!
    
    override func setUp() throws {
        // Initialize service with bundled rules
        service = try RulesService(
            wmRulesPath: "agent_ops/rules/wm_ladder.json",
            locRulesPath: "agent_ops/rules/loc_indication.guard.json",
            operatorsPath: "agent_ops/rules/operators.json"
        )
    }
    
    func testCase001_OpioidAcuteWM() throws {
        // Load fixture from bundle or parse inline
        let result = service.evaluate(
            severities: ["A": 2, "B": 1, "C": 1, "D": 1, "E": 2, "F": 1],
            d1Context: [
                "substances": [
                    ["substance_group": "opioid", "last_use_hours": 12, "cows": 9]
                ]
            ],
            flags: ["vitals_unstable": false, "no_withdrawal_signs": false]
        )
        
        XCTAssertTrue(result.wm.indicated)
        XCTAssertTrue(result.wm.candidateLevels.contains("1.7"))
        XCTAssertTrue(result.wm.candidateLevels.contains("2.7"))
        XCTAssertEqual(result.loc.indicated, "2.1")
    }
    
    func testWMGuardPreventsDoubleCount() throws {
        // Test T-0022 guard logic
        let result = service.evaluate(
            severities: ["A": 2, "B": 3, "C": 1, "D": 1, "E": 2, "F": 1],
            d1Context: [
                "substances": [
                    ["substance_group": "opioid", "cows": 9]
                ]
            ],
            flags: ["vitals_unstable": false, "no_withdrawal_signs": false]
        )
        
        // WM should escalate to 3.7
        XCTAssertTrue(result.wm.indicated)
        XCTAssertTrue(result.wm.candidateLevels.contains("3.7"))
        
        // LOC should use WM rationale, not biomedical
        XCTAssertEqual(result.loc.indicated, "3.7")
        XCTAssertTrue(result.loc.why.contains("wm_requires_medical_setting"))
        XCTAssertFalse(result.loc.why.contains("biomedical_management"))
    }
}
```

3. **Run tests:**
   - Press Cmd+U or Product → Test
   - Check that tests pass

---

### 6. **Fix RulesService Initialization** ⚠️ POTENTIAL ISSUE

**Problem:** RulesService uses `fatalError` if files not found. This will crash the app.

**Current Code (RulesService.swift line 50):**
```swift
fatalError("Rules file not found: \(path)")
```

**Recommended Fix:**
```swift
// Better error handling
private static func resolveURL(bundle: Bundle, path: String) throws -> URL {
    // Try absolute file first
    let abs = URL(fileURLWithPath: path)
    if FileManager.default.fileExists(atPath: abs.path) { return abs }
    
    // Try bundle resource
    if let url = bundle.url(forResource: path, withExtension: nil) { return url }
    
    // Try without agent_ops prefix (for bundle resources)
    let simplePath = path.replacingOccurrences(of: "agent_ops/rules/", with: "")
    if let url = bundle.url(forResource: simplePath, withExtension: nil) { return url }
    
    throw RulesServiceError.notFound(URL(fileURLWithPath: path))
}
```

**Update RulesService init:**
```swift
public init(bundle: Bundle = .main,
            wmRulesPath: String = "wm_ladder.json",  // Simplified for bundle
            locRulesPath: String = "loc_indication.guard.json",
            operatorsPath: String = "operators.json") throws {
    let wmURL = try RulesService.resolveURL(bundle: bundle, path: wmRulesPath)
    let locURL = try RulesService.resolveURL(bundle: bundle, path: locRulesPath)
    let opURL = try RulesService.resolveURL(bundle: bundle, path: operatorsPath)
    self.engine = try RulesEngine(wmRulesURL: wmURL, locRulesURL: locURL, operatorsURL: opURL)
}
```

---

### 7. **Update Assessment Model for WM/LOC Results** 🔧 DATA MODEL

**Problem:** Assessment model needs properties to store WM and LOC outcomes.

**What You Need to Add:**

```swift
// ios/ASAMAssessment/Models/Assessment.swift
struct Assessment: Identifiable, Codable, Hashable {
    let id: UUID
    var status: AssessmentStatus
    var timestamp: Date
    var domains: [Domain]
    var problems: [Problem]
    
    // ADD THESE:
    var wmOutcome: WMOutcome?          // ✅ Store WM result
    var locRecommendation: LOCOutcome?  // ✅ Store LOC result
    var validationIssues: ValidationResult?  // ✅ For future validation
    
    // ... rest of existing code
}

// ADD THESE TYPES (or import from RulesEngine):
struct WMOutcome: Codable, Hashable {
    let indicated: Bool
    let candidateLevels: [String]
    let rationale: [String]
    let ruleId: String?
}

struct LOCOutcome: Codable, Hashable {
    let indicated: String
    let why: [String]
    let ruleId: String?
}
```

---

### 8. **Problems Module (T-0003)** 📋 NOT STARTED

**What's Missing:**
- ❌ ProblemsListView.swift
- ❌ ProblemDetailView.swift
- ❌ Problem CRUD operations
- ❌ Severity tracking UI
- ❌ Goal tracking
- ❌ Domain tags linking

**Priority:** HIGH (after rules engine wired up)

---

### 9. **Validation Rules Integration** 🔍 NOT STARTED

**What's Missing:**
- ❌ Validation engine (similar pattern to RulesEngine)
- ❌ ValidationService.swift
- ❌ Review screen showing validation issues
- ❌ Fix button navigation (using crumbs.yml)

**Priority:** HIGH (depends on Problems Module)

---

### 10. **Audit Logging for Rules** 📝 PARTIAL

**What's Missing:**
- ❌ Capture rule IDs in audit events
- ❌ Log WM evaluations with rationale
- ❌ Log LOC calculations with why
- ❌ Add ruleset hash to audit trail (T-0024)

**What You Need to Add:**

```swift
// When evaluating assessment
let result = rulesService.evaluate(...)

// Log to audit service
auditService.logEvent(
    event: "rules_evaluation",
    actor: "system",
    notes: """
    WM: \(result.wm.indicated ? "indicated" : "not indicated")
    WM Rule: \(result.wm.ruleId ?? "none")
    LOC: \(result.loc.indicated)
    LOC Rule: \(result.loc.ruleId ?? "unknown")
    """
)
```

---

## 📊 Progress Summary

### Completed (7 tasks)
- ✅ T-0001: NavigationSplitView shell
- ✅ T-0002: Safety banner
- ✅ T-0018: Signature validation fix
- ✅ T-0019: Crumb linter
- ✅ T-0020: Operators.json
- ✅ T-0021: Test fixtures
- ✅ T-0022: WM/LOC guard logic

### In Progress (Xcode Integration)
- 🟡 Add Swift files to Xcode project
- 🟡 Bundle rules files with app
- 🟡 Wire RulesService to app
- 🟡 Add XCTests

### Not Started (17 tasks)
- ❌ T-0003: Problems Module CRUD
- ❌ T-0004: EMR Context drawer
- ❌ T-0005: PDF Composer
- ❌ T-0006: Preflight checks
- ❌ T-0007: Upload with retry
- ❌ T-0008: Unit tests
- ❌ T-0009: Accessibility pass
- ❌ T-0010: Canonical JSON encoder
- ❌ T-0011: OverflowPredictor
- ❌ T-0012: SafetyAction modal
- ❌ T-0013: Crumb anchors implementation
- ❌ T-0014: DocumentReference flow
- ❌ T-0015: MAC chain audit
- ❌ T-0016: Accessibility checklist
- ❌ T-0017: ASAM 4 edition support
- ❌ T-0023: Program capability resolver
- ❌ T-0024: Ruleset hash in PDF

---

## 🎯 Immediate Action Items (Priority Order)

### 1. **TODAY: Xcode Integration** ⚠️ CRITICAL
   - [ ] Add RulesEngine.swift to Xcode project target
   - [ ] Add RulesService.swift to Xcode project target
   - [ ] Add agent_ops/rules/ folder to app bundle (blue folder)
   - [ ] Fix RulesService path resolution for bundle resources
   - [ ] Build and verify no compilation errors

### 2. **TODAY: Basic Wiring** 🔧
   - [ ] Add domainSeverities() helper to Assessment model
   - [ ] Add d1Context() helper to Assessment model
   - [ ] Add flags() helper to Assessment model
   - [ ] Add wmOutcome and locRecommendation properties
   - [ ] Replace @StateObject locService with rulesService in App

### 3. **THIS WEEK: Testing** 🧪
   - [ ] Create RulesEngineTests.swift
   - [ ] Implement testCase001_OpioidAcuteWM()
   - [ ] Implement testWMGuardPreventsDoubleCount()
   - [ ] Run all 12 fixtures through tests
   - [ ] Verify guard logic works correctly

### 4. **NEXT: Problems Module (T-0003)** 📋
   - [ ] Create ProblemsListView
   - [ ] Implement CRUD operations
   - [ ] Wire to validation rules
   - [ ] Add breadcrumb navigation

---

## 🚨 Blockers

### High Priority Blockers
1. **Swift files not in Xcode target** - App won't compile if files aren't added
2. **Rules files not bundled** - App will crash at runtime with "file not found"
3. **No Assessment helpers** - Can't convert data to rules engine format

### Medium Priority Blockers
1. **No tests** - Can't verify rules engine works correctly
2. **No Problems Module** - Can't complete assessment workflow
3. **No validation integration** - Can't show validation errors

---

## 📝 Quick Start Checklist

Copy this into your notes and check off as you go:

```
[ ] Open Xcode project
[ ] Add RulesEngine.swift to ASAMAssessment target
[ ] Add RulesService.swift to ASAMAssessment target
[ ] Add agent_ops/rules/ folder as blue folder reference
[ ] Verify rules files in target membership
[ ] Build (Cmd+B) - should compile without errors
[ ] Add Assessment helper methods (domainSeverities, etc.)
[ ] Replace locService with rulesService in App
[ ] Create RulesEngineTests.swift
[ ] Write first test (testCase001)
[ ] Run tests (Cmd+U)
[ ] Test in simulator
[ ] Verify WM/LOC evaluation works
```

---

**Generated:** 2025-11-09  
**Status:** 🟡 Xcode Integration Required  
**Blockers:** 3 high priority, 3 medium priority  
**Next Step:** Add Swift files to Xcode project target
