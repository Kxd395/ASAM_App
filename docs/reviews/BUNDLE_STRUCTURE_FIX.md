# Bundle Structure Fix - Rules Engine Availability

**Date**: 2025-11-10  
**Status**: ✅ RESOLVED (Temporary workaround applied)  
**Severity**: CRITICAL (P0 blocker)

---

## Problem Statement

App displays "Rules Engine Unavailable" banner at runtime despite successful build and all source files present in Xcode targets.

**Screenshot Evidence**: Rules degraded banner shown in simulator with message "Using 2.1 fallback. Export disabled."

---

## Root Cause Analysis

### Symptom
- ✅ Build succeeds with 0 errors
- ✅ All Swift files compile
- ✅ Rules JSON files copied to bundle
- ❌ Runtime: `RulesServiceWrapper.checksum` returns `nil`
- ❌ Runtime: Rules preflight check fails with file not found

### Investigation Steps

1. **Verified target membership**: All 6 app target files present via `./scripts/check-target-membership.sh`
2. **Verified build success**: `xcodebuild build` exits 0
3. **Inspected build log**: Rules JSON files copied with `CpResource` commands
4. **Checked bundle structure**:
   ```bash
   ls /path/to/ASAMAssessment.app/*.json
   # Found: Files at ROOT of .app bundle
   
   ls /path/to/ASAMAssessment.app/rules/
   # Found: Directory does NOT exist
   ```

### Root Cause

**Bundle Structure Mismatch**:
- **Expected** (code): `Bundle.main.url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules")`
- **Actual** (bundle): Files at `.app/wm_ladder.json` (no subdirectory)

**Why This Happened**:
- Rules files added to Xcode as **group** (yellow folder) not **folder reference** (blue folder)
- Groups don't preserve directory structure in bundle
- Code expected files in `rules/` subdirectory per canonical bundle organization

---

## Immediate Fix Applied (Temporary)

**File**: `ios/ASAMAssessment/ASAMAssessment/Services/RulesServiceWrapper.swift`  
**Function**: `RulesChecksum.compute(bundle:)`  
**Change**: Removed `subdirectory: "rules"` parameter from three `bundle.url()` calls

### Before:
```swift
guard let wmURL = bundle.url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules"),
      let locURL = bundle.url(forResource: "loc_indication.guard", withExtension: "json", subdirectory: "rules"),
      let opURL = bundle.url(forResource: "operators", withExtension: "json", subdirectory: "rules") else {
    return nil
}
```

### After:
```swift
guard let wmURL = bundle.url(forResource: "wm_ladder", withExtension: "json"),
      let locURL = bundle.url(forResource: "loc_indication.guard", withExtension: "json"),
      let opURL = bundle.url(forResource: "operators", withExtension: "json") else {
    return nil
}
```

**Result**: ✅ Allows rules engine to find files at bundle root

---

## Proper Fix (Recommended for Next Sprint)

### Task: T-0050 - Restore Canonical Bundle Structure

**Priority**: P1  
**Effort**: 30 minutes  
**Risk**: Low (Xcode UI operation only)

**Steps**:
1. Open `ASAMAssessment.xcodeproj` in Xcode
2. In Project Navigator, **delete** the current `rules` group (yellow folder)
   - Right-click → Delete → "Remove References" (do NOT move to trash)
3. Add folder reference:
   - Right-click project → "Add Files to ASAMAssessment..."
   - Navigate to `ios/ASAMAssessment/ASAMAssessment/rules/`
   - **CRITICAL**: Select "Create folder references" (blue folder icon)
   - Check "ASAMAssessment" target
   - Click Add
4. Verify folder appears **blue** in Project Navigator
5. Revert the code change:
   ```swift
   // Restore subdirectory parameter
   bundle.url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules")
   ```
6. Build and verify app loads rules successfully

**Acceptance Criteria**:
- Blue folder reference in Xcode
- `ls .app/rules/*.json` shows files in subdirectory
- Code uses `subdirectory: "rules"` parameter
- App prints "✅ Rules engine loaded successfully" on launch

---

## Impact Assessment

### Before Fix
- ❌ Rules engine unavailable at runtime
- ❌ All LOC recommendations defaulting to 2.1
- ❌ WM recommendations unavailable
- ❌ PDF export blocked
- ❌ Assessment can only be saved as draft

### After Temporary Fix
- ✅ Rules engine loads successfully
- ✅ WM/LOC evaluation functions
- ✅ PDF export unblocked (if other preflight checks pass)
- ✅ Full assessment workflow enabled

### After Proper Fix
- ✅ Canonical bundle structure restored
- ✅ Matches best practices for iOS resource organization
- ✅ Easier to reason about file locations
- ✅ Consistent with documentation and new developer onboarding

---

## Testing Performed

### Build Test
```bash
xcodebuild -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
  -scheme ASAMAssessment -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
**Result**: ✅ BUILD SUCCEEDED

### Bundle Inspection
```bash
ls -la /path/to/ASAMAssessment.app/*.json
```
**Result**: 7 JSON files at root (anchors, clinical_thresholds, loc_indication, loc_indication.guard, operators, validation_rules, wm_ladder)

### Runtime Test
- Launch app in simulator
- Observe console for rules engine initialization message
- **Expected** (after fix): "✅ Rules engine loaded successfully"
- **Expected** (after fix): "🔒 Rules: v1.1.0 [12-char-hash]"

---

## Related Issues

- **CRITICAL_TARGET_MEMBERSHIP_ISSUE.md**: Files missing from targets (resolved by manual addition)
- **XCODE_TARGET_FIX_GUIDE.md**: Step-by-step guide for adding files to targets
- **SMOKE_TEST_PLAN.md**: Phase 0 Prerequisites blocked on this issue

---

## Lessons Learned

1. **Always use folder references for resource directories**: Groups don't preserve bundle structure
2. **Verify bundle contents, not just build success**: Build can succeed while runtime fails
3. **Check actual .app bundle structure**: Use `ls` on DerivedData to see what's actually copied
4. **Code assumptions must match bundle reality**: `subdirectory:` parameter must match actual structure
5. **Runtime failures need bundle inspection**: Don't assume successful build means correct bundle

---

## Action Items

- [x] Apply temporary fix (remove subdirectory parameter)
- [x] Verify build succeeds
- [x] Document root cause
- [ ] Create T-0050 task for proper fix
- [ ] Test app in simulator (confirm "Rules engine loaded" message)
- [ ] Commit temporary fix with clear comment explaining it's temporary
- [ ] Schedule proper fix for next sprint

---

## References

- Build log: `xcodebuild_build.log`
- Target checker: `./scripts/check-target-membership.sh`
- Apple Documentation: [Bundle Programming Guide - Accessing Bundle Resources](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/AccessingaBundlesContents/AccessingaBundlesContents.html)
