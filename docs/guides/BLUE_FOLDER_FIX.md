# 🔵 Blue Folder Fix - Required Manual Step

**Status**: ⚠️ REQUIRED BEFORE NEXT BUILD  
**Priority**: P0 STOP-SHIP  
**Task**: T-0056

---

## Problem

The `rules/` directory was added to Xcode as a **group** (yellow folder icon), which does NOT preserve directory structure in the app bundle. This causes:

1. **Runtime failure**: `Bundle.url(forResource:withExtension:subdirectory:"rules")` returns nil
2. **Rules engine degraded**: No files found → "Rules Engine Unavailable" banner
3. **Audit break**: Cannot verify canonical hash if files at wrong location

---

## Solution

Convert `rules/` from a **group** (yellow) to a **folder reference** (blue).

---

## Manual Steps (5 minutes)

### 1. Open Xcode Project

```bash
open ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj
```

### 2. Delete Current "rules" Group

1. In Project Navigator (left sidebar), locate the **yellow** `rules` folder
2. Right-click → **Delete**
3. Choose **"Remove References"** (NOT "Move to Trash")
   - This only removes from Xcode, doesn't delete files

### 3. Re-add as Folder Reference

1. Right-click on `ASAMAssessment` (project root in Navigator)
2. Choose **"Add Files to 'ASAMAssessment'..."**
3. Navigate to: `ios/ASAMAssessment/ASAMAssessment/rules`
4. **CRITICAL**: Select **"Create folder references"** (NOT "Create groups")
   - Look for blue folder icon in preview
5. **Target Membership**:
   - ✅ Check **ASAMAssessment** (app target)
   - ✅ Check **ASAMAssessmentTests** (test target) if tests need access
6. Click **"Add"**

### 4. Verify Blue Folder

In Project Navigator, the `rules` folder should now appear **BLUE** (not yellow).

### 5. Verify Build Phase

1. Select **ASAMAssessment** target → **Build Phases**
2. Expand **"Copy Bundle Resources"**
3. Verify `rules` folder appears (should show as "folder" not individual files)

---

## Verification

### A. Build & Inspect Bundle

```bash
# Build
xcodebuild -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
  -scheme ASAMAssessment \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# Verify bundle structure
./scripts/verify-rules-bundle.sh
```

**Expected output:**

```
✅ rules/anchors.json
✅ rules/wm_ladder.json
✅ rules/loc_indication.guard.json
✅ rules/validation_rules.json
✅ rules/operators.json
✅ rules/ folder packaged correctly (blue folder reference)
```

### B. Runtime Verification

Launch app in simulator, check console:

```
✅ Rules engine loaded successfully
🔒 Rules: v4 [A1B2C3D4E5F6]
```

**No** "Rules Engine Unavailable" banner should appear.

---

## Code Changes (Already Applied)

The following code was **restored** to use `subdirectory: "rules"`:

```swift
// RulesChecksum.compute (RulesServiceWrapper.swift)
bundle.url(forResource: resource, 
           withExtension: "json", 
           subdirectory: "rules")  // ← RESTORED

// RulesService.init (RulesService.swift)
wmRulesFile: "rules/wm_ladder.json",
locRulesFile: "rules/loc_indication.guard.json",
operatorsFile: "rules/operators.json"
```

---

## Build-Time Gate (Automated)

Add **Run Script Phase** to app target (before "Compile Sources"):

1. Xcode → ASAMAssessment target → **Build Phases** → **+** → **New Run Script Phase**
2. Name: **"Verify Rules Bundle Structure"**
3. Script:

```bash
RULES_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/rules"
REQUIRED=("anchors.json" "wm_ladder.json" "loc_indication.guard.json" "validation_rules.json" "operators.json")

if [[ ! -d "$RULES_DIR" ]]; then
  echo "error: rules/ folder not found in bundle. Did you add it as a blue folder reference?"
  exit 1
fi

for f in "${REQUIRED[@]}"; do
  if [[ ! -f "$RULES_DIR/$f" ]]; then
    echo "error: rules/$f missing from bundle."
    exit 1
  fi
done

# No non-JSON junk
NON_JSON=$(find "$RULES_DIR" -type f ! -name '*.json' -print || true)
if [[ -n "$NON_JSON" ]]; then
  echo "error: Non-JSON files present in rules/:"
  echo "$NON_JSON"
  exit 1
fi

echo "✅ Rules bundle structure verified"
```

4. Move this phase **after** "Copy Bundle Resources"

---

## Acceptance Criteria

- [ ] `rules` folder appears **BLUE** in Xcode Project Navigator
- [ ] `./scripts/verify-rules-bundle.sh` exits 0
- [ ] Build succeeds with 0 errors
- [ ] App launches and prints "✅ Rules engine loaded successfully"
- [ ] No "Rules Engine Unavailable" banner appears
- [ ] Export button enabled (if assessment complete)

---

## What Was Wrong Before

| Aspect | Yellow Group (Wrong) | Blue Folder (Correct) |
|--------|---------------------|----------------------|
| Icon | 📁 Yellow | 🔵 Blue |
| Bundle Structure | Files at `.app/` root | Files in `.app/rules/` |
| Code Lookup | `subdirectory:` fails | `subdirectory:` works |
| Rules Engine | Degraded | Healthy |
| Audit Trail | Broken | Valid |

---

## Related Tasks

- **T-0056** (P0): Blue folder conversion ← THIS TASK
- **T-0057** (P0): 64-char hash canonical format (DONE)
- **T-0058** (P1): Edition-aware LOC/WM names (DONE)
- **T-0040** (P1): Canonical hash with per-file manifest (DONE)

---

## Timeline

**Estimated time**: 5 minutes (manual Xcode steps)  
**Critical path**: Blocks all testing and export functionality  
**Do this**: **RIGHT NOW** before any other work

---

## Questions?

See: `docs/reviews/BUNDLE_STRUCTURE_FIX.md` for original RCA
