# ✅ Pre-Push Hook Integration - FINAL CHECKLIST

**Date**: November 10, 2025  
**Status**: Hook Installed ✅ | Manual Xcode Steps Needed ⏳  
**Time to Complete**: 5-10 minutes

---

## What's Complete ✅

### 1. Pre-Push Hook Installed
```bash
✅ scripts/pre-push → executable
✅ .git/hooks/pre-push → symlinked to ../../scripts/pre-push
✅ Verified: lrwxr-xr-x  .git/hooks/pre-push -> ../../scripts/pre-push
```

### 2. Files Added to Git
```bash
✅ scripts/pre-push
✅ scripts/install-hooks.sh  
✅ .github/workflows/ios-tests.yml
✅ ios/ASAMAssessment/ASAMAssessmentTests/StrictAnchors.swift
✅ ios/ASAMAssessment/ASAMAssessmentTests/StrictRulesValidationTests.swift
✅ docs/guides/PRE_PUSH_HOOK_SETUP.md
✅ docs/guides/COMPLETE_IMPLEMENTATION_SUMMARY.md
```

### 3. What the Hook Does
- Detects changes in: `ios/`, `rules/`, `mapping/`, `scripts/`
- Auto-finds available iOS simulator
- Runs tests with `-DSTRICT_ANCHORS` flag
- Validates 6 strict rules: uniqueness, precedence, structure, coverage
- Takes 30-60 seconds (acceptable for quality gate)
- Bypass available: `SKIP_PREPUSH=1 git push` (for emergencies)

---

## What You Need to Do ⏳

### Step 1: Add Test Files to Xcode (3 minutes)

**Open Xcode:**
```bash
open ios/ASAMAssessment/ASAMAssessment.xcodeproj
```

**In Xcode:**

1. **Find the test target** in Project Navigator
   - Look for **ASAMAssessmentTests** (yellow folder with test tube icon)

2. **Add files**
   - Right-click **ASAMAssessmentTests** → "Add Files to 'ASAMAssessment'..."
   - Navigate to: `ios/ASAMAssessment/ASAMAssessmentTests/`
   - Select BOTH files:
     - `StrictAnchors.swift`
     - `StrictRulesValidationTests.swift`
   
3. **In the Add Files dialog:**
   - ✅ **DO NOT** check "Copy items if needed" (files are already in right place)
   - ✅ **DO** check "Add to targets: ASAMAssessmentTests"
   - Click **Add**

4. **Verify:**
   - Files appear under ASAMAssessmentTests in Navigator
   - Click each file → File Inspector → Target Membership shows ASAMAssessmentTests ✅
   - No red text or compile errors

---

### Step 2: Verify Rules Bundle (1 minute)

**In Xcode Project Navigator:**

1. **Find the `rules/` folder**
   - Should be under ASAMAssessment project

2. **Check the folder color:**
   - ✅ **Blue folder** = folder reference (correct!)
   - ❌ **Yellow folder** = group (WRONG - needs fix)

3. **If blue** (correct):
   - Click `rules/` folder
   - File Inspector (right panel) → Target Membership
   - ✅ Check **ASAMAssessmentTests** if not already checked
   - Done!

4. **If yellow** (wrong):
   - Follow instructions in `docs/guides/BLUE_FOLDER_FIX.md`
   - Takes 60 seconds to fix

---

### Step 3: Test Locally (3 minutes)

**Test 1: Without strict flag (should skip strict tests)**
```bash
cd /Users/kevindialmb/Downloads/ASAM_App

xcodebuild test \
  -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
  -scheme ASAMAssessment \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Expected output:**
```
Test Suite 'All tests' passed
- Ran ~10-15 tests
- Strict tests SKIPPED
- Duration: 10-15 seconds
```

**Test 2: With strict flag (what pre-push runs)**
```bash
xcodebuild test \
  -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
  -scheme ASAMAssessment \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  OTHER_SWIFT_FLAGS="\$(inherited) -DSTRICT_ANCHORS"
```

**Expected output:**
```
Test Suite 'All tests' passed
- Ran ~16-21 tests (includes 6 strict tests)
- testRuleIdUniqueness_Strict ✅
- testPrecedenceMonotonicity_Strict ✅
- testRequiredFieldsPresent_Strict ✅
- testAnchorsCoverage_Strict ✅
- testLOCRulesStructure_Strict ✅
- testOperatorsDefinition_Strict ✅
- Duration: 30-60 seconds
```

---

### Step 4: Test the Pre-Push Hook (2 minutes)

**Create a test commit:**
```bash
cd /Users/kevindialmb/Downloads/ASAM_App

# Make trivial change
echo "# Testing pre-push hook" >> ios/ASAMAssessment/README.md

# Commit
git add ios/ASAMAssessment/README.md
git commit -m "test: verify pre-push hook with strict tests"

# Push (hook will run automatically)
git push
```

**What should happen:**
```
1. Git detects changes in ios/ directory
2. Pre-push hook runs
3. Output shows:
   → Detecting iOS changes...
   → Running iOS tests with STRICT_ANCHORS...
   → Using simulator: iPhone 15
   → xcodebuild test ...
   → Test Suite 'All tests' passed
4. Push succeeds
```

**If you see this, YOU'RE DONE! 🎉**

---

## Troubleshooting

### Problem: "Tests can't find wm_ladder.json"

**Cause**: Rules folder not set up as blue folder reference with test target membership

**Fix**:
1. Make sure `rules/` is **blue folder** (not yellow group)
2. File Inspector → Target Membership → Check **ASAMAssessmentTests**
3. See `docs/guides/BLUE_FOLDER_FIX.md` for detailed steps

### Problem: "Strict tests don't run" (only shows ~10 tests)

**Cause**: `-DSTRICT_ANCHORS` flag not being applied

**Fix**:
1. Verify exact command: `OTHER_SWIFT_FLAGS="\$(inherited) -DSTRICT_ANCHORS"`
2. Check StrictAnchors.swift is in ASAMAssessmentTests target
3. Clean build: `xcodebuild clean ...`

### Problem: "No simulator available"

**Cause**: Xcode hasn't set up simulators yet

**Fix**:
```bash
# Check available simulators
xcrun simctl list devices available

# If empty, open Xcode once to install runtimes
open -a Xcode
# Xcode → Settings → Platforms → Install iOS Simulator
```

### Problem: "Hook runs every push even without ios/ changes"

**Cause**: Hook's path detection logic triggered

**Fix**:
- This is expected if you changed files in: `ios/`, `rules/`, `mapping/`, or `scripts/`
- Hook is smart - it only runs when relevant files changed
- Check: `git diff main...HEAD --name-only`

### Problem: "Hook is too slow"

**Expected**: 30-60 seconds is normal for quality gate

**Emergency bypass** (use sparingly):
```bash
SKIP_PREPUSH=1 git push
```

**Note**: Bypass is logged - your team will know 😉

---

## Acceptance Checklist

### Infrastructure
- [x] Pre-push hook executable and symlinked
- [ ] StrictAnchors.swift added to ASAMAssessmentTests target
- [ ] StrictRulesValidationTests.swift added to ASAMAssessmentTests target
- [ ] rules/ is blue folder with ASAMAssessmentTests membership
- [ ] CI workflow committed (.github/workflows/ios-tests.yml)

### Testing
- [ ] Tests pass without `-DSTRICT_ANCHORS` (~10-15 tests)
- [ ] Tests pass with `-DSTRICT_ANCHORS` (~16-21 tests, includes 6 strict)
- [ ] Pre-push hook runs on push to ios/ directory
- [ ] All 6 strict tests pass: uniqueness, precedence, fields, anchors, LOC, operators

### Verification Commands
```bash
# 1. Check hook is installed
ls -l .git/hooks/pre-push
# Should show: -> ../../scripts/pre-push

# 2. Check test files are committed
git ls-files | grep Strict
# Should show both test files

# 3. Check CI workflow is committed
git ls-files .github/workflows/ios-tests.yml
# Should show the workflow file

# 4. List available simulators
xcrun simctl list devices available | grep iPhone
# Should show at least one iPhone simulator
```

---

## What Gets Validated (6 Strict Tests)

### 1. Rule ID Uniqueness
- No duplicate IDs across all rules files
- Prevents logic conflicts

### 2. Precedence Monotonicity  
- Precedence values are consistent
- Ensures predictable rule evaluation

### 3. Required Fields Present
- All rules have: id, description, precedence, condition
- No malformed rules

### 4. Anchors Coverage
- anchors.json has valid structure
- domains and flags keys present

### 5. LOC Rules Structure
- LOC indication rules well-formed
- Required fields present

### 6. Operators Definition
- All operators defined: ==, !=, >, <, >=, <=, in, contains
- Logic engine complete

---

## Performance Expectations

```
Lightweight tests (Cmd+U):          10-15 seconds
Strict tests (with -D flag):        30-60 seconds
Pre-push hook (automatic):          30-60 seconds
CI workflow (GitHub Actions):       2-4 minutes
```

**Why strict tests are slower:**
- Loads and parses all JSON rules files
- Validates cross-file references
- Checks structural integrity
- Worth it for preventing production bugs!

---

## After Integration

### Immediate
1. ✅ Complete Xcode steps 1-2
2. ✅ Run tests locally (step 3)
3. ✅ Test hook (step 4)
4. ✅ Commit all changes
5. ✅ Push to trigger CI

### This Week
- [ ] Team training on hook usage
- [ ] Document bypass policy
- [ ] Enable GitHub branch protection
- [ ] Monitor CI runs

### Optional
- [ ] Add pre-commit hook for faster feedback
- [ ] Add check-target-membership.sh to linters
- [ ] Customize hook for team needs

---

## Quick Commands Reference

```bash
# Install hook (already done)
chmod +x scripts/pre-push && ln -sfn ../../scripts/pre-push .git/hooks/pre-push

# Run tests locally (lightweight)
xcodebuild test -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj -scheme ASAMAssessment -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests with strict validation
xcodebuild test -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj -scheme ASAMAssessment -destination 'platform=iOS Simulator,name=iPhone 15' OTHER_SWIFT_FLAGS="\$(inherited) -DSTRICT_ANCHORS"

# Test push (hook will run)
echo "# test" >> ios/ASAMAssessment/README.md && git add -A && git commit -m "test: hook" && git push

# Emergency bypass
SKIP_PREPUSH=1 git push

# Check hook status
ls -l .git/hooks/pre-push

# List simulators
xcrun simctl list devices available
```

---

## Documentation

**Complete Setup Guide** (502 lines):  
→ `docs/guides/PRE_PUSH_HOOK_SETUP.md`

**Implementation Summary** (360 lines):  
→ `docs/guides/COMPLETE_IMPLEMENTATION_SUMMARY.md`

**Blue Folder Fix** (if needed):  
→ `docs/guides/BLUE_FOLDER_FIX.md`

---

## Summary

✅ **Hook installed and ready**  
⏳ **Need to add test files to Xcode** (3 min)  
⏳ **Need to verify rules/ bundle** (1 min)  
⏳ **Need to test locally** (3 min)  

**Total time**: 5-10 minutes  
**Impact**: Automated quality gates prevent broken rules  
**Bypass available**: `SKIP_PREPUSH=1` for emergencies  

---

**YOU'RE ALMOST THERE!** Just complete the 3 manual Xcode steps above and you're done. 🚀

**Questions?** See troubleshooting section or full setup guide.
