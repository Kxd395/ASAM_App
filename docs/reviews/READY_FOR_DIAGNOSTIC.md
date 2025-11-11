# READY FOR DIAGNOSTIC RUN - Next Steps

**Status**: ✅ Code Complete + Build Succeeded  
**Date**: 2025-11-10 16:30  
**Next Action**: USER - Launch app and check console output

---

## What Was Done

### ✅ Hyper-Critical Diagnostic Probe Added

Per your request: *"Instrument the initializer to print the resolved URLs and file sizes before parse"*

**Added**: `debugRulesBundle()` method that runs BEFORE any rules parsing

**What It Does**:
```swift
// Checks all 5 required JSON files:
📦 bundle.rules dir = /path/to/app  
✅ rules/anchors.json size=6144
✅ rules/wm_ladder.json size=8192  
... or ...
❌ MISSING rules/anchors.json
```

**Where**: `RulesServiceWrapper.swift` line 158 (called before preflight check)

**Impact**: **Definitively** shows whether files exist in runtime bundle (no more guessing)

---

### ✅ All Critical Enhancements Re-Applied

After `git checkout` restored old version, I re-applied:

1. **Canonical 64-char hash with manifest** (sha256Full + sha256Short)
2. **Line-ending normalization** (CRLF/CR → LF for cross-platform)
3. **Per-file manifest** with individual hashes + byte counts
4. **loadedAt property** for diagnostics view
5. **reinitialize() method** for retry button
6. **Enhanced console logging** with full hash + manifest

---

### ✅ Critical Integration Points Verified

Per your warnings:

1. **ExportButton provenance** - ⚠️ **CONFIRMED**: Passing `nil` at line 173  
   → **Fix needed**: Replace with `RulesProvenanceTracker.shared.provenanceForExport()`  
   → **Status**: Documented as P1

2. **Domains .contentShape** - ✅ **VERIFIED PRESENT**: Line 400 in ContentView  
   → Full-row tap area implemented correctly

---

## What You Need To Do Now

### Step 1: Launch App (2 minutes)

Run the app in simulator and immediately check the **console output**.

**Expected Output A (Blue Folder Already Fixed)**:
```
📦 bundle.rules dir = /path/to/ASAMAssessment.app
✅ rules/anchors.json size=6144
✅ rules/wm_ladder.json size=8192
✅ rules/loc_indication.guard.json size=4096
✅ rules/validation_rules.json size=2048
✅ rules/operators.json size=1024
✅ Rules engine loaded successfully
🔒 Rules: v4 [A1B2C3D4E5F6]
```

**Expected Output B (Blue Folder NOT Fixed - ROOT CAUSE)**:
```
📦 bundle.rules dir = /path/to/ASAMAssessment.app
❌ MISSING rules/anchors.json
❌ MISSING rules/wm_ladder.json
❌ MISSING rules/loc_indication.guard.json
❌ MISSING rules/validation_rules.json
❌ MISSING rules/operators.json
⚠️ Rules engine degraded: Rules unavailable: ...
```

---

### Step 2: If You See ❌ MISSING (Blue Folder Fix Needed)

**Follow**: `docs/guides/BLUE_FOLDER_FIX.md`

**Steps** (5 minutes):
1. Open Xcode project
2. Remove yellow "rules" group (Remove References only)
3. Add rules/ folder back (Create **folder references** - blue)
4. Verify target membership (ASAMAssessment + ASAMAssessmentTests)
5. Check Copy Bundle Resources phase shows `rules` (folder)
6. Product → Clean Build Folder
7. Delete app from simulator
8. Rebuild and reinstall

---

### Step 3: If You See ✅ All Files But Still Failing

**Possible Causes**:
- JSON parse error (trailing comma, BOM, invalid syntax)
- File encoding issue (not UTF-8)
- Permissions issue (can't read file)

**Next Diagnostic**:
The console will show which file failed to parse with exact error message (LocalizedError now provides file-specific details).

---

## Critical Findings From Your Review

### 1. ExportButton Provenance (⚠️ P1 Fix Needed)

**File**: `ios/ASAMAssessment/ASAMAssessment/Services/ExportPreflight.swift:173`

**Current (WRONG)**:
```swift
let result = ExportPreflight.check(
    provenance: nil as RulesProvenance?,  // ⚠️ BREAKS AUDIT CHAIN
    ...
)
```

**Fix Needed**:
```swift
let result = ExportPreflight.check(
    provenance: RulesProvenanceTracker.shared.provenanceForExport(),
    ...
)
```

**Impact**: Export preflight can't verify provenance → audit chain broken

**When To Fix**: After blue folder conversion confirmed working

---

### 2. Questionnaire Content (Not Yet Implemented)

You're absolutely right - the **question banks** don't exist yet.

**What Exists**:
- UI scaffolding (severity chips, D1 substance sheet)
- Domain list with navigation
- Placeholder detail view

**What's Missing**:
- `questions/<domain>.json` files with structured items
- QuestionsService loader
- FormRenderer for dynamic SwiftUI forms
- Skip logic (`showIf`, `required`)
- Persistence bindings

**Recommendation**: Tackle after blue folder fix unblocks rules engine

**Optional**: I can generate 6 neutral item-bank JSONs (A-F, ~50 items total) if you want to wire them immediately

---

## Build Status

✅ **BUILD SUCCEEDED** with 0 errors

**Files Modified**:
- `ios/ASAMAssessment/ASAMAssessment/Services/RulesServiceWrapper.swift`
  - Added diagnostic probe (lines 334-350)
  - Re-applied canonical hash (lines 36-113)
  - Added loadedAt + reinitialize()
  - Enhanced console logging

**Verified**:
- All previous fixes preserved (LocalizedError, Domains navigation)
- Diagnostic probe called before parse
- Build compiles successfully

---

## Acceptance Criteria

### Pass (Diagnostic Working):
- [ ] Console shows bundle.rules dir path
- [ ] Each file shows either ✅ size=N or ❌ MISSING
- [ ] If ❌ MISSING → blue folder conversion confirmed as root cause
- [ ] If ✅ all files → investigate parse error (LocalizedError will show exact file)

### Fail (Diagnostic Not Working):
- [ ] No console output at all (probe not being called - report back)
- [ ] Mixed ✅ and ❌ (partial bundle issue - report pattern)

---

## What Happens After Diagnostic Run

**Scenario A: All ❌ MISSING** (Most Likely)
→ Blue folder conversion needed (5 minutes manual Xcode work)  
→ Clean + rebuild + reinstall  
→ Rerun diagnostic → should see all ✅  
→ Rules engine loads successfully  
→ Banner disappears  
→ Domains tappable  
→ Export enabled (subject to other gates)

**Scenario B: All ✅ But Still Failing**
→ Parse error in one of the JSON files  
→ LocalizedError will show exact file + reason  
→ Fix JSON syntax  
→ Rebuild + rerun  
→ Rules engine loads successfully

**Scenario C: All ✅ And Rules Load**
→ Something else was wrong that got fixed  
→ Verify domains tappable  
→ Verify no banner  
→ Move to next priority (ExportButton provenance fix)

---

## Priority Order After Diagnostic

1. **P0**: Blue folder conversion (if diagnostic shows ❌ MISSING)
2. **P1**: ExportButton provenance fix (nil → real provenance)
3. **P1**: Debounce callsite audit (safety flags bypass)
4. **P2**: Questionnaire JSONs (optional, enables full workflow)
5. **P1**: Clinical thresholds loader (T-0037)
6. **P2**: Job-level export gate (T-0007)
7. **P1**: PDF flattening + Info dict (T-0038)

---

## Summary

**Code Status**: ✅ Complete + Building  
**Runtime Status**: ⏳ Awaiting diagnostic run  
**Root Cause**: Likely blue folder (will be confirmed by diagnostic)  
**Blocker**: 5-minute manual Xcode operation (if diagnostic confirms)

**Your Guidance Applied**:
- ✅ Diagnostic probe prints resolved URLs + file sizes
- ✅ Called before any parse attempt
- ✅ Definitively shows bundle structure
- ✅ No guessing required
- ✅ Canonical hash deterministic
- ✅ Provenance issue documented

Launch the app and check the console. The diagnostic will tell you exactly what's wrong in 2 seconds.
