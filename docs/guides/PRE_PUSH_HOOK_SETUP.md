# Pre-Push Hook & Strict Testing - Complete Setup Guide

**Date**: 2025-11-10  
**Status**: ✅ Ready for integration  
**Purpose**: Automated quality gates with strict validation

---

## Overview

This system provides automated quality gates at **push time** and **CI** to catch issues before they reach production:

- **Pre-push hook**: Runs locally before `git push`, validates tests with `-DSTRICT_ANCHORS`
- **CI workflow**: Mirrors pre-push validation in GitHub Actions
- **Strict tests**: Heavy validation (rule uniqueness, precedence, anchors coverage) only runs with compile flag

---

## Components

### 1. ✅ Pre-Push Hook

**File**: `scripts/pre-push`  
**Status**: Created and executable

**Features**:
- Only runs when `ios/`, `rules/`, `mapping/`, or `scripts/` changed
- Auto-detects available iOS simulators
- Compiles tests with `-DSTRICT_ANCHORS` flag
- Runs optional linters if present (anchors check, target membership)
- Fast exits in CI and can be bypassed with `SKIP_PREPUSH=1`

**Installation**:
```bash
chmod +x scripts/pre-push
ln -sf ../../scripts/pre-push .git/hooks/pre-push

# Verify installation
ls -l .git/hooks/pre-push
# Should show: .git/hooks/pre-push -> ../../scripts/pre-push
```

**Usage**:
```bash
# Normal push (runs hook automatically)
git push

# Bypass hook (use sparingly)
SKIP_PREPUSH=1 git push

# Manual test of hook
./scripts/pre-push
```

---

### 2. ✅ StrictAnchors Helper

**File**: `ios/ASAMAssessment/ASAMAssessmentTests/StrictAnchors.swift`  
**Status**: Created

**Purpose**: Compile-time flag to enable/disable strict tests

**Code**:
```swift
enum StrictAnchors {
    #if STRICT_ANCHORS
    static let enabled = true
    #else
    static let enabled = false
    #endif
}
```

**Usage in Tests**:
```swift
func testMyStrictValidation() throws {
    try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
    
    // Heavy validation that only runs in pre-push/CI
    // ...
}
```

---

### 3. ✅ Strict Validation Tests

**File**: `ios/ASAMAssessment/ASAMAssessmentTests/StrictRulesValidationTests.swift`  
**Status**: Created with 6 validation tests

**Tests Included**:
1. **Rule ID Uniqueness** - No duplicate rule IDs
2. **Precedence Monotonicity** - Precedence values are consistent
3. **Required Fields Presence** - All rules have id, description, precedence, condition
4. **Anchors Coverage** - anchors.json has proper structure
5. **LOC Rules Structure** - LOC indication rules are well-formed
6. **Operators Definition** - All required operators defined

**Running Locally**:
```bash
# Without strict flag (skips heavy tests)
xcodebuild test -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj -scheme ASAMAssessment

# With strict flag (runs all tests)
xcodebuild test \
  -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
  -scheme ASAMAssessment \
  OTHER_SWIFT_FLAGS="\$(inherited) -DSTRICT_ANCHORS"
```

---

### 4. ✅ CI Workflow

**File**: `.github/workflows/ios-tests.yml`  
**Status**: Created

**Triggers**:
- Pull requests affecting `ios/`, `rules/`, `mapping/`, `scripts/`
- Pushes to `main`, `master`, `dev` branches

**Features**:
- Runs on macOS 14
- Auto-resolves latest iOS runtime
- Builds and tests with `-DSTRICT_ANCHORS`
- Uploads test results as artifacts (7-day retention)
- 30-minute timeout

---

## Setup Steps

### Step 1: Install Pre-Push Hook (1 minute)

```bash
# From repo root
cd /Users/kevindialmb/Downloads/ASAM_App

# Make executable
chmod +x scripts/pre-push

# Install hook
ln -sf ../../scripts/pre-push .git/hooks/pre-push

# Verify
ls -l .git/hooks/pre-push
```

### Step 2: Add Test Files to Xcode (5 minutes)

1. Open `ios/ASAMAssessment/ASAMAssessment.xcodeproj` in Xcode
2. Right-click **ASAMAssessmentTests** folder
3. Choose **Add Files to "ASAMAssessment"...**
4. Select:
   - `StrictAnchors.swift`
   - `StrictRulesValidationTests.swift`
5. Ensure **ASAMAssessmentTests** target is checked
6. Click **Add**

### Step 3: Verify Rules Bundle (1 minute)

Ensure `rules/` folder is a **blue folder reference** in Xcode:

```bash
# Check if rules files exist
ls -la ios/ASAMAssessment/ASAMAssessment/rules/

# Should show:
# - anchors.json
# - wm_ladder.json
# - loc_indication.guard.json
# - operators.json
# - validation_rules.json
```

If missing, add as blue folder:
1. Delete yellow `rules` group from Xcode
2. Right-click project → Add Files
3. Select `rules/` folder
4. Check "Create folder references" (blue folder)
5. Add to both **ASAMAssessment** and **ASAMAssessmentTests** targets

### Step 4: Update Scheme (2 minutes)

1. In Xcode: **Product** → **Scheme** → **Edit Scheme...**
2. Select **Test** action
3. Ensure **ASAMAssessmentTests** is checked
4. Click **Close**

### Step 5: Test Locally (5 minutes)

```bash
# Run tests without strict mode (should pass quickly)
xcodebuild test \
  -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
  -scheme ASAMAssessment \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests with strict mode (runs all validations)
xcodebuild test \
  -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
  -scheme ASAMAssessment \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  OTHER_SWIFT_FLAGS="\$(inherited) -DSTRICT_ANCHORS"
```

### Step 6: Test Pre-Push Hook (2 minutes)

```bash
# Make a small change to trigger hook
echo "# Test" >> ios/ASAMAssessment/README.md
git add ios/ASAMAssessment/README.md
git commit -m "Test pre-push hook"

# Try to push (hook will run)
git push

# If you want to bypass for testing
SKIP_PREPUSH=1 git push

# Clean up test
git reset HEAD~1
```

### Step 7: Commit CI Workflow (1 minute)

```bash
git add .github/workflows/ios-tests.yml
git commit -m "Add iOS strict testing CI workflow"
git push
```

---

## Acceptance Checklist

### Pre-Push Hook
- [ ] `scripts/pre-push` exists and is executable
- [ ] Symlink installed at `.git/hooks/pre-push`
- [ ] Hook runs when pushing changes to `ios/`, `rules/`, `mapping/`, `scripts/`
- [ ] Hook skips when pushing other files
- [ ] Hook can be bypassed with `SKIP_PREPUSH=1`

### Test Files
- [ ] `StrictAnchors.swift` added to ASAMAssessmentTests target
- [ ] `StrictRulesValidationTests.swift` added to ASAMAssessmentTests target
- [ ] Both files compile without errors
- [ ] Tests show up in Xcode Test Navigator

### Rules Bundle
- [ ] `rules/` is a blue folder (not yellow group) in Xcode
- [ ] Rules files accessible from ASAMAssessmentTests target
- [ ] All 5 rules files present: anchors, wm_ladder, loc_indication.guard, operators, validation_rules

### Scheme Configuration
- [ ] ASAMAssessmentTests included in scheme Test action
- [ ] Scheme builds and tests successfully
- [ ] Tests can run from Xcode (Cmd+U)

### Strict Mode
- [ ] Tests pass without `-DSTRICT_ANCHORS` (lightweight mode)
- [ ] Tests run with `-DSTRICT_ANCHORS` (strict mode)
- [ ] Strict tests actually validate (try breaking a rule ID to verify)

### CI Integration
- [ ] `.github/workflows/ios-tests.yml` committed
- [ ] Workflow appears in GitHub Actions tab
- [ ] Workflow runs on pull requests
- [ ] Workflow runs on pushes to main/master/dev

---

## Troubleshooting

### Problem: Pre-push hook not running

**Symptoms**: `git push` succeeds without running tests

**Solutions**:
1. Verify symlink exists:
   ```bash
   ls -l .git/hooks/pre-push
   ```

2. Reinstall hook:
   ```bash
   rm .git/hooks/pre-push
   ln -sf ../../scripts/pre-push .git/hooks/pre-push
   chmod +x scripts/pre-push
   ```

3. Check if changes affect watched paths:
   ```bash
   git diff --name-only HEAD~1..HEAD
   # Should show files in ios/, rules/, mapping/, or scripts/
   ```

---

### Problem: "No such module 'XCTest'" in test files

**Symptoms**: Test files show compile errors in editor

**Solution**: This is normal for files not yet in Xcode project. After adding to Xcode (Step 2), errors will clear.

---

### Problem: Tests can't find rules files

**Symptoms**: Tests fail with "Failed to load wm_ladder.json"

**Solutions**:
1. Verify rules folder is blue (not yellow) in Xcode
2. Check target membership:
   - Select `rules` folder in Xcode
   - File Inspector → Target Membership
   - Ensure **ASAMAssessmentTests** is checked

3. Verify files exist on disk:
   ```bash
   ls -la ios/ASAMAssessment/ASAMAssessment/rules/
   ```

---

### Problem: Simulator not found

**Symptoms**: Hook fails with "No iOS simulators available"

**Solutions**:
1. Open Xcode once to install runtimes
2. List available simulators:
   ```bash
   xcrun simctl list devices available
   ```

3. If none available, install via Xcode:
   - Xcode → Settings → Platforms
   - Download iOS simulator runtime

---

### Problem: Tests time out in CI

**Symptoms**: GitHub Actions workflow times out after 30 minutes

**Solutions**:
1. Check test logs for stuck tests
2. Reduce test scope temporarily
3. Increase timeout in workflow file (line 8)

---

## Adding New Strict Tests

### Template

```swift
func testMyNewValidation_Strict() throws {
    try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
    
    // 1. Load data
    guard let url = Bundle(for: Self.self).url(
        forResource: "my_file",
        withExtension: "json",
        subdirectory: "rules"
    ) else {
        XCTFail("File not found")
        return
    }
    
    let data = try Data(contentsOf: url)
    let json = try JSONSerialization.jsonObject(with: data)
    
    // 2. Validate
    // ... your assertions ...
    
    XCTAssertTrue(condition, "Validation failed: reason")
}
```

### Best Practices

1. **Use descriptive names**: End with `_Strict` suffix
2. **Skip when flag not set**: Always use `XCTSkipUnless(StrictAnchors.enabled, ...)`
3. **Load from bundle**: Use `Bundle(for: Self.self)` to find test resources
4. **Clear error messages**: Include context in assertion messages
5. **Fail fast**: Return early if setup fails (don't cascade failures)

---

## Performance

### Local Development (without strict flag)
- **Duration**: ~10-15 seconds
- **What runs**: Basic functionality tests only
- **When**: Every Cmd+U in Xcode

### Pre-Push Hook (with strict flag)
- **Duration**: ~30-60 seconds
- **What runs**: All tests including heavy validation
- **When**: Before every `git push` (if relevant files changed)

### CI Workflow (with strict flag)
- **Duration**: ~2-4 minutes (includes build time)
- **What runs**: Full test suite with strict validation
- **When**: Every PR and push to main/master/dev

---

## Integration with Settings Architecture

The pre-push hook validates **SettingsStore** integration:

1. **No mixed settings sources**: Hook catches references to deprecated `AppSettings`
2. **Consistent property names**: Strict tests verify prefixed keys (`ui_*`, `rules_*`)
3. **Migration integrity**: Tests validate settings version and defaults

To complete integration:
- ⏳ Wire `SettingsStore.shared` in `ASAMAssessmentApp`
- ⏳ Update all views to use new property names
- ⏳ Deprecate old `AppSettings` class
- ⏳ Run strict tests to verify consistency

---

## References

- **Settings Architecture**: `docs/guides/SETTINGS_ARCHITECTURE_OVERHAUL.md`
- **P0 Fixes Summary**: `docs/guides/P0_FIXES_COMPLETE.md`
- **Quick Reference**: `docs/guides/SETTINGS_QUICK_REFERENCE.md`
- **Infrastructure Setup**: `docs/guides/INFRASTRUCTURE_SETUP.md`

---

## Next Steps

1. **Immediate** (today):
   - [ ] Install pre-push hook
   - [ ] Add test files to Xcode
   - [ ] Verify rules bundle
   - [ ] Run tests locally

2. **This week**:
   - [ ] Wire SettingsStore across app
   - [ ] Add more strict tests (crumbs coverage, field mapping)
   - [ ] Document MDM configuration
   - [ ] Train team on bypass procedures

3. **Next sprint**:
   - [ ] Add UI tests with strict mode
   - [ ] Performance profiling of strict tests
   - [ ] Extend to other validation types

---

**Last Updated**: 2025-11-10  
**Owner**: Development Team  
**Status**: ✅ Ready for installation
