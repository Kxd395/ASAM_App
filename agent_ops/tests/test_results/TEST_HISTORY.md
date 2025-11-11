# Test Execution History

This file logs all test runs chronologically. Each entry includes timestamp, type, status, and key findings.

---

## 2025-11-10

### Run ID: 20251110_pre_smoke_01
**Timestamp**: 2025-11-10 14:30:00 UTC  
**Type**: Pre-smoke validation  
**Status**: ❌ BLOCKED  
**Executor**: Agent

**Blocker**: 9 files missing from Xcode targets

**Missing Files**:
- App Target: SubstanceRowSheet.swift, ClinicalFlagsSection.swift, ExportPreflight.swift, RulesProvenance.swift, ReconciliationChecks.swift, RulesServiceWrapper.swift
- Test Target: P0RulesInputTests.swift, ExportPreflightTests.swift, RulesProvenanceTests.swift

**Action Required**: Manual Xcode integration before tests can execute

**Environment**:
- macOS: Darwin
- Xcode Project: ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj
- Branch: master
- Last Commit: d0677e9

**Notes**: All P0 code complete and compile-breaker fixes applied (commit d0677e9), but Xcode target membership prevents build.

---

### Run ID: 20251110_133904
**Timestamp**: 2025-11-10 13:39:04 UTC  
**Type**: smoke  
**Status**: 🚫 BLOCKED → ✅ RESOLVED  
**Executor**: Agent

**Blocker**: Bundle structure mismatch - rules JSON files at wrong location

**Root Cause**:
- Rules files added as Xcode **group** (yellow folder), not **folder reference** (blue folder)
- Files copied to `.app/` root instead of `.app/rules/` subdirectory
- Code expected `subdirectory: "rules"` but files not in subdirectory
- Runtime: RulesChecksum.compute() returned nil, triggering degraded state

**Investigation**:
- ✅ Build succeeded (all compile errors fixed)
- ✅ Target membership verified (6/6 app files present)
- ❌ Bundle inspection: `ls .app/rules/` → directory does NOT exist
- ❌ Files at root: `.app/wm_ladder.json`, `.app/operators.json`, etc.

**Fix Applied** (temporary workaround):
- Removed `subdirectory: "rules"` from `RulesServiceWrapper.compute()`
- Files now loaded from bundle root
- Build succeeds, app should load rules successfully

**Proper Fix** (scheduled as T-0050):
- Delete rules group in Xcode
- Re-add as folder reference (blue folder)
- Restore subdirectory parameter in code
- Canonical bundle structure: `.app/rules/*.json`

**Files Modified**:
- `ios/ASAMAssessment/ASAMAssessment/Services/RulesServiceWrapper.swift` (lines 44-46)

**Documentation Created**:
- `docs/reviews/BUNDLE_STRUCTURE_FIX.md` (full RCA and remediation plan)

**Environment**:
- macOS: Darwin
- Xcode: iPhone 17 simulator
- Build: Debug-iphonesimulator
- Branch: master

---

## Template for Future Entries

```markdown
### Run ID: YYYYMMDD_type_nn
**Timestamp**: YYYY-MM-DD HH:MM:SS UTC  
**Type**: smoke|unit|integration|full  
**Status**: ✅ PASS | ⚠️ PARTIAL | ❌ FAIL | 🚫 BLOCKED  
**Executor**: Agent|Human|CI

**Summary**:
- Total: N tests
- Passed: N
- Failed: N
- Skipped: N
- Duration: N seconds

**Key Findings**:
- Finding 1
- Finding 2

**Failures** (if any):
1. Test name - reason
2. Test name - reason

**Environment**:
- Xcode: version
- Simulator: device
- iOS: version
- Branch: name
- Commit: hash

**Notes**: Additional context
```

---
