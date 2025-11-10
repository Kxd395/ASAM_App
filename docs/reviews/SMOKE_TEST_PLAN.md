# 15-Minute Smoke Test Plan

**Purpose**: Validate P0 fixes (provenance, preflight, flags, reconciliation, debounce) and surface remaining breakages.

**Status**: Created 2025-11-10 | Last Run: NEVER (blocked on Xcode integration)

---

## Prerequisites (CRITICAL - Must Complete First)

### ✅ Step 0: Verify Compile-Breaker Fixes Applied

All fixes from commit **d0677e9** must be present:

- [x] `RulesProvenance.pdfFooterText()` takes 3 args: `(planId, planHash, complianceMode)`
- [x] `RulesProvenance.swift` has `import PDFKit` and uses `UIFont` (not `NSFont`)
- [x] `RulesServiceWrapper` exposes `@Published var rulesState: RulesState`
- [x] `ExportPreflight.check()` signature includes `provenance` and `complianceMode` parameters
- [x] `ComplianceConfig.swift` exists with typed `ComplianceMode` enum
- [x] `clinical_thresholds.json` exists in `ios/ASAMAssessment/ASAMAssessment/rules/`

### 🚫 Step 1: Xcode Target Integration (BLOCKING)

**Current Status**: 9 files missing from targets

Run validation:
```bash
./scripts/check-target-membership.sh
```

**Expected**: "All P0 files are properly added…"  
**Actual**: ❌ 9 files missing

**Manual Fix Required**:
1. Open `ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj` in Xcode
2. Add these files to **ASAMAssessment** app target:
   - Views/SubstanceRowSheet.swift
   - Views/ClinicalFlagsSection.swift
   - Services/ExportPreflight.swift
   - Services/RulesProvenance.swift
   - Services/ReconciliationChecks.swift
   - Services/RulesServiceWrapper.swift
   - Services/ComplianceConfig.swift
3. Add these files to **ASAMAssessmentTests** test target:
   - ASAMAssessmentTests/P0RulesInputTests.swift
   - ASAMAssessmentTests/ExportPreflightTests.swift
   - ASAMAssessmentTests/RulesProvenanceTests.swift
4. Re-run `./scripts/check-target-membership.sh` to verify

**DO NOT PROCEED** until this step passes.

---

## Phase 1: Automated Build & Test (5 minutes)

### Test 1.1: Build Project

```bash
xcodebuild \
  -scheme ASAMAssessment \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  clean build \
  -quiet
```

**Expected**: ✅ Build succeeds with no errors  
**Failure Signals**:
- `NSFont` not found → Check cross-platform font handling
- `rulesState` property not found → Check RulesServiceWrapper
- ComplianceMode unresolved → Check ComplianceConfig.swift in target

### Test 1.2: Run Unit Tests Headless

```bash
xcodebuild \
  -scheme ASAMAssessment \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test \
  -quiet \
  | tee agent_ops/tests/test_results/smoke/$(date +%Y%m%d_%H%M%S)_full.log
```

**Test Coverage**:
- `RulesEngineTests` - Golden path + guard logic
- `P0RulesInputTests` - SubstanceRow + ClinicalFlags validation
- `ExportPreflightTests` - Hard gates + compliance template blocking
- `RulesProvenanceTests` - Hash generation + footer stamping

**Expected**: ✅ All tests pass  
**Acceptable**: ⚠️ Some tests fail due to missing test helpers (Assessment.exampleComplete(), etc.)

### Test 1.3: Critical Negative Proofs

Run only the three most critical safety tests:

```bash
# Test 1: WM/LOC guard prevents double-counting
xcodebuild test \
  -scheme ASAMAssessment \
  -only-testing:ASAMAssessmentTests/RulesEngineTests/testGuardLogicPreventsDoubleCount

# Test 2: Export blocks when rules degraded
xcodebuild test \
  -scheme ASAMAssessment \
  -only-testing:ASAMAssessmentTests/ExportPreflightTests/testFailsWhenRulesDegraded

# Test 3: COWS requires minimum D1 severity
xcodebuild test \
  -scheme ASAMAssessment \
  -only-testing:ASAMAssessmentTests/P0RulesInputTests/testCowsRequiresMinD1
```

**Expected**: ✅ All three pass (critical safety gates active)

---

## Phase 2: Manual UI Verification (7 minutes)

Launch simulator and manually test critical workflows:

### Test 2.1: Debounce Behavior

1. Open Assessment screen
2. Toggle **"Vitals Unstable"** flag
   - **Expected**: Immediate re-evaluation (0ms, no spinner delay)
3. Type into any notes field
   - **Expected**: ~300ms debounce (no thrashing, smooth typing)

**Failure Signal**: Safety toggle feels delayed → Check `bypassDebounce: true` wiring

### Test 2.2: Reconciliation Blockers

**Scenario A: COWS vs D1 contradiction**
1. Create SubstanceRow with COWS = 14
2. Set Domain A (D1) = 1
   - **Expected**: ❌ BLOCKER error: "COWS 14 requires Domain A ≥ 3"

**Scenario B: Withdrawal flags contradiction**
1. Set "No Withdrawal Signs" = true
2. Set Domain A (D1) = 3
   - **Expected**: ❌ BLOCKER error: "Cannot set 'No withdrawal signs' when D1 is severe"

**Scenario C: Recent use warning**
1. Set "Recent use < 24h" = true
2. Set "No Withdrawal Signs" = true
   - **Expected**: ⚠️ WARNING (not blocker)

### Test 2.3: WM vs LOC Separation

1. Document opioid withdrawal with COWS ≥ 13
   - **Expected**: WM candidates show 3.7/4.0
2. Verify LOC recommendation
   - **Expected**: LOC does NOT double-count from WM escalation
   - **Expected**: LOC at clinically appropriate level per D2/D3/D4 factors

**Failure Signal**: LOC jumps to 3.7 solely because WM did → WM/LOC coupling not separated

### Test 2.4: Compliance Template Gate

1. Set app to `internal_neutral` mode (default)
2. Attempt export with template path containing "asam" or "continuum"
   - **Expected**: ❌ Export BLOCKED with compliance violation message
3. Switch to neutral template name
   - **Expected**: ✅ Export preflight passes (assuming other gates pass)

### Test 2.5: Rules Health Preflight

1. Temporarily rename `ios/ASAMAssessment/ASAMAssessment/rules/wm_ladder.json` to `wm_ladder.json.bak`
2. Restart app (force rules reload)
3. Attempt export
   - **Expected**: ❌ Export BLOCKED: "Rules engine degraded, provenance unavailable"
4. Restore `wm_ladder.json`

---

## Phase 3: PDF Provenance Validation (3 minutes)

### Test 3.1: Export & Inspect Footer

1. Complete an assessment
2. Export to PDF
3. Open PDF in Preview
4. Verify bottom-right footer text matches **exact spec**:

```
Plan <8HEX> | Seal <12HEX> | Rules <12HEX> | Legal v1.0 | Mode internal_neutral
```

**Expected**:
- Plan ID: 8 hex characters
- Seal: 12 hex characters (first 12 of assessment hash)
- Rules: 12 hex characters (first 12 of ruleset hash)
- Legal: "v1.0"
- Mode: "internal_neutral" or "licensed_asam"

### Test 3.2: PDF Metadata (Optional - Not Yet Implemented)

If `PDFMetadataWriter` is implemented, check PDF Info dictionary contains:

```bash
# Use exiftool or similar
exiftool out/ASAMPlan_*.pdf | grep -E "(RulesetHash|RulesManifest|ComplianceMode)"
```

**Expected**:
- `RulesetHash`: Full 64-char SHA256
- `RulesManifest`: JSON array of {file, hash}
- `ComplianceMode`: "internal_neutral" or "licensed_asam"
- `LegalNoticeVersion`: "1.0"
- `PlanId`: 8-char hex
- `Seal`: 8-char hex

**Note**: Metadata embedding is tracked as **T-0040** (canonical hash) - not yet implemented.

---

## Triage Guide

If tests fail, use this quick diagnosis:

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| Compile error in PDFDocument extension | Font/import issue | Verify `import PDFKit` and `UIFont` usage |
| Export allowed while rules degraded | `rulesState` not checked | Verify `ExportPreflight.check()` uses `rulesState == .healthy` |
| Ambulatory WM not blocked with unstable vitals | Validator checking LOC codes | Point validator at WM candidates array (fix #7 in d0677e9) |
| 3.7/4.0 naming wrong in v4 | Edition-specific strings | Update `locDescription` by ASAMVersion |
| Reconciliation thresholds drift | Hardcoded constants | Load from `clinical_thresholds.json` (T-0037) |

---

## Pass/Fail Criteria

### ✅ GO (Tests Pass)
- Build succeeds
- All unit tests pass (or only fail on missing test helpers)
- Export blocks when rules degraded
- Footer string exact
- WM/LOC separation working
- Reconciliation contradictions produce blockers

### 🚫 NO-GO (Tests Fail)
- Any export slips through with degraded rules
- Any WM/LOC double-count detected
- COWS/CIWA contradictions don't block
- Footer format incorrect
- Compile errors present

---

## CI Integration (Optional)

Add to `.github/workflows/smoke.yml`:

```yaml
name: Smoke Tests
on: [push, workflow_dispatch]

jobs:
  ios-smoke:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Verify Target Membership
        run: ./scripts/check-target-membership.sh
      
      - name: Build & Test
        run: |
          xcodebuild -scheme ASAMAssessment \
            -sdk iphonesimulator \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            clean build test -quiet
      
      - name: Archive Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: |
            agent_ops/tests/test_results/**/*.json
            agent_ops/tests/test_results/**/*.log
```

---

## Next Steps After Smoke Pass

If smoke tests pass, proceed to:

1. **T-0037**: Clinical thresholds JSON loader (2 hours)
2. **T-0040**: Canonical hash with 64-char + manifest (4 hours)
3. **T-0038**: PDF flattening service (4 hours)
4. **T-0035**: Reverse WM guard (3 hours)
5. **T-0036**: Reconciliation UI wiring (2 hours)

---

**Status Log**:
- 2025-11-10 14:30 - Plan created, blocked on Xcode integration
