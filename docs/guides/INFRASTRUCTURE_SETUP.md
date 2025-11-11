# Infrastructure Components Setup Guide

This guide documents the infrastructure components for enforcing field mapping completeness in the ASAM Assessment project.

## Overview

The infrastructure ensures that all rule anchors referenced in `rules/*.json` files have corresponding entries in `mapping/fields_map.json`. This creates a complete audit trail:

**UI Field → Assessment Model → Rule Anchor → PDF Output**

## Components

### 1. Python Validation Script ✅ COMPLETE

**File**: `scripts/check-anchors-vs-map.py`

**Status**: Created and executable

**Purpose**: Core validation logic that discovers rule anchors and compares them to mapping entries.

**Features**:
- Discovers anchors from `rules/anchors.json` (preferred) or regex scanning
- Compares to `mapping/fields_map.json` keys
- Supports ignore list at `mapping/ignore_anchors.txt`
- Environment variables:
  - `LENIENT=0|1` - Set to 1 for warnings instead of failures (default: 0)
  - `RULES_DIR=<path>` - Custom rules directory (default: "rules")
  - `MAP_PATH=<path>` - Custom mapping file (default: "mapping/fields_map.json")

**Exit Codes**:
- `0`: All anchors have mapping entries
- `1`: Missing anchors found (in strict mode)

**Usage**:
```bash
# Strict mode (fails on missing anchors)
python3 scripts/check-anchors-vs-map.py

# Lenient mode (warnings only)
LENIENT=1 python3 scripts/check-anchors-vs-map.py
```

### 2. Pre-Commit Hook ✅ COMPLETE

**File**: `scripts/pre-commit`

**Status**: Created and executable

**Purpose**: Local enforcement before commits. Runs validation automatically when rules/ or mapping/ files are staged.

**Features**:
- Only runs if rules/ or mapping/ files changed (performance optimization)
- Runs in strict mode (LENIENT=0)
- Blocks commits if missing anchors are detected

**Installation**:
```bash
# Link the pre-commit hook to .git/hooks/
ln -sf ../../scripts/pre-commit .git/hooks/pre-commit

# Verify installation
ls -l .git/hooks/pre-commit
```

**Testing**:
```bash
# Test by adding a rule anchor without mapping
echo '{"test_anchor": "dom.TEST.missing"}' > rules/test.json
git add rules/test.json
git commit -m "Test commit"  # Should fail with missing anchor error

# Clean up test
rm rules/test.json
```

### 3. CI GitHub Actions Workflow ✅ COMPLETE

**File**: `.github/workflows/anchors.yml`

**Status**: Created

**Purpose**: Automated enforcement on push/PR events. Runs validation in CI environment.

**Features**:
- Two jobs:
  1. **anchors**: Runs anchor-to-mapping validation on Ubuntu
  2. **ios-tests**: Builds and tests iOS app with `STRICT_ANCHORS=1` on macOS-14
- Triggered on push to main/dev and pull requests
- Uses strict mode (LENIENT=0)

**Jobs**:

**Job 1: anchors**
- Platform: ubuntu-latest
- Runs: `python3 scripts/check-anchors-vs-map.py`
- Fast-fail: Blocks PR merge if validation fails

**Job 2: ios-tests**
- Platform: macos-14
- Xcode: Latest stable
- Destination: iPhone 15 Simulator
- Environment: `STRICT_ANCHORS=1`
- Runs: `xcodebuild test -scheme ASAMAssessment`

**Activation**: Will activate automatically once committed to the repository.

### 4. Xcode Build-Phase Guard (Optional)

**Purpose**: Optional local build-time validation. Catches missing/malformed mapping during Xcode builds.

**Status**: Not yet implemented (manual user step required)

**Implementation Steps**:

1. **Open Xcode Project**:
   - Launch Xcode
   - Open `ios/ASAMAssessment/ASAMAssessment.xcodeproj`

2. **Add Build Phase**:
   - Select the "ASAMAssessment" target
   - Go to "Build Phases" tab
   - Click "+" → "New Run Script Phase"
   - Name: "Verify Field Mapping"
   - Position: Drag before "Copy Bundle Resources"

3. **Add Script**:
   ```bash
   #!/bin/bash
   set -e
   
   # Path to mapping file (relative to project root)
   MAP_FILE="${PROJECT_DIR}/../../mapping/fields_map.json"
   
   # Check if mapping file exists
   if [ ! -f "$MAP_FILE" ]; then
       echo "error: Field mapping file not found at $MAP_FILE"
       exit 1
   fi
   
   # Validate JSON structure (basic check)
   if ! python3 -c "import json; json.load(open('$MAP_FILE'))" 2>/dev/null; then
       echo "error: Field mapping file is not valid JSON: $MAP_FILE"
       exit 1
   fi
   
   # Optional: Run full anchor validation during builds
   # Uncomment the following line to enable:
   # python3 "${PROJECT_DIR}/../../scripts/check-anchors-vs-map.py"
   
   echo "✅ Field mapping validation passed"
   ```

4. **Configure Options**:
   - Shell: `/bin/bash`
   - Show environment variables in build log: ☑️ (checked)
   - Run script: Based on dependency analysis ☑️ (checked)
   - Input Files: (none)
   - Output Files: (none)

5. **Build and Verify**:
   ```bash
   # Clean build to verify
   xcodebuild clean -project ios/ASAMAssessment/ASAMAssessment.xcodeproj -scheme ASAMAssessment
   xcodebuild build -project ios/ASAMAssessment/ASAMAssessment.xcodeproj -scheme ASAMAssessment
   ```

**Features**:
- Fast-fail: Catches problems early in local development
- Basic validation: Checks file existence and JSON validity
- Optional full check: Uncomment last line to run complete anchor validation
- Build-time feedback: Shows in Xcode build log

**Performance Note**: The full anchor validation (commented line) adds ~1-2 seconds to build time. Recommend keeping it commented for normal development and relying on pre-commit hook instead.

## Installation Order

For new developers setting up the project:

1. ✅ **Clone repository** (scripts already in place)
2. ✅ **Verify script permissions**:
   ```bash
   chmod +x scripts/check-anchors-vs-map.py
   chmod +x scripts/pre-commit
   ```
3. ✅ **Install pre-commit hook**:
   ```bash
   ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
   ```
4. ⏳ **Add Xcode build phase** (optional - follow steps above)
5. ✅ **CI workflow** (automatic on push/PR)

## Testing the System

### Test Case 1: Pre-Commit Hook

```bash
# Create test rule with missing anchor
echo '{"test": "dom.TEST.missing"}' > rules/test_rule.json
git add rules/test_rule.json

# Attempt commit (should fail)
git commit -m "Test missing anchor"

# Expected output:
# 🔁 Running anchor↔︎mapping check (pre-commit)…
# ❗ Missing from mapping (1):
#    - dom.TEST.missing

# Clean up
rm rules/test_rule.json
git reset
```

### Test Case 2: Add Valid Mapping

```bash
# Add mapping entry first
cat >> mapping/fields_map.json <<EOF
{
  "dom.TEST.valid": {
    "model_key": "testField",
    "pdf_field": "test_field",
    "rules_anchors": ["dom.TEST.valid"]
  }
}
EOF

# Then add rule
echo '{"test": "dom.TEST.valid"}' > rules/test_rule.json
git add mapping/fields_map.json rules/test_rule.json

# Commit should succeed
git commit -m "Add test field with mapping"

# Expected output:
# 🔁 Running anchor↔︎mapping check (pre-commit)…
# ✅ Mapping covers all discovered anchors.
```

### Test Case 3: CI Workflow

1. Create branch with missing anchor
2. Push to GitHub
3. Open pull request
4. CI should fail on anchors job
5. Add mapping entry
6. Push update
7. CI should pass

## Ignore List

To temporarily ignore specific anchors during migration:

**File**: `mapping/ignore_anchors.txt`

**Format**: One anchor per line
```
dom.A.legacy_field
flags.deprecated_flag
substance.old_substance
```

**Usage**:
```bash
# Create ignore list
cat > mapping/ignore_anchors.txt <<EOF
dom.A.legacy_field
flags.deprecated_flag
EOF

# Script will skip these anchors
python3 scripts/check-anchors-vs-map.py
```

## Lenient Mode

For gradual migration or development:

```bash
# Set LENIENT=1 to get warnings instead of failures
LENIENT=1 python3 scripts/check-anchors-vs-map.py

# Example output in lenient mode:
# ❗ Missing from mapping (3):
#    - dom.A.new_field
#    - flags.new_flag
#    - substance.new_substance
# ⚠️  LENIENT=1 set — not failing build.
```

## Troubleshooting

### Pre-Commit Hook Not Running

**Symptom**: Commits succeed even with missing anchors

**Solutions**:
1. Verify hook installation:
   ```bash
   ls -l .git/hooks/pre-commit
   # Should show: .git/hooks/pre-commit -> ../../scripts/pre-commit
   ```

2. Verify script permissions:
   ```bash
   ls -l scripts/pre-commit
   # Should show: -rwxr-xr-x (executable)
   ```

3. Reinstall hook:
   ```bash
   rm .git/hooks/pre-commit
   ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
   ```

### CI Workflow Not Running

**Symptom**: No CI job appears on pull request

**Solutions**:
1. Verify workflow file exists: `.github/workflows/anchors.yml`
2. Check GitHub Actions settings (may be disabled in repo settings)
3. Verify branch protection rules allow workflows

### False Positives

**Symptom**: Script reports anchors that don't exist

**Solutions**:
1. Review regex patterns in `check-anchors-vs-map.py` (lines 35-41)
2. Add false positives to `mapping/ignore_anchors.txt`
3. Use explicit `rules/anchors.json` instead of regex scanning

### Performance Issues

**Symptom**: Pre-commit hook takes too long

**Solutions**:
1. Hook only runs when rules/ or mapping/ files changed (already optimized)
2. Use explicit `rules/anchors.json` (faster than regex scanning)
3. Reduce number of rule files (consolidate if possible)

## Maintenance

### Adding New Anchors

1. Add anchor to mapping/fields_map.json:
   ```json
   {
     "dom.A.new_field": {
       "model_key": "newField",
       "pdf_field": "new_field_name",
       "rules_anchors": ["dom.A.new_field"]
     }
   }
   ```

2. Add rule using anchor in rules/*.json:
   ```json
   {
     "condition": {
       "field": "dom.A.new_field",
       "operator": "==",
       "value": "some_value"
     }
   }
   ```

3. Stage both files:
   ```bash
   git add mapping/fields_map.json rules/my_rule.json
   git commit -m "Add new_field with complete mapping"
   ```

### Updating Anchors

When renaming/removing anchors:

1. Update mapping/fields_map.json (remove old, add new)
2. Update all rules/*.json files using the anchor
3. Commit together to ensure consistency

### Periodic Audits

Run manual validation periodically:

```bash
# Full strict check
python3 scripts/check-anchors-vs-map.py

# With detailed output
LENIENT=1 python3 scripts/check-anchors-vs-map.py | tee audit.log
```

## Migration Strategy

For existing projects with many unmapped anchors:

**Phase 1: Discovery** (Week 1)
- Run script in lenient mode
- Document all missing anchors
- Prioritize by usage frequency

**Phase 2: Critical Mappings** (Week 2)
- Add mappings for P0 anchors (used in production rules)
- Test with pre-commit hook enabled
- Keep lenient mode in CI

**Phase 3: Gradual Completion** (Weeks 3-4)
- Add mappings for P1/P2 anchors
- Reduce ignore list progressively
- Monitor CI for issues

**Phase 4: Strict Enforcement** (Week 5+)
- Remove lenient mode from CI
- Clear ignore list
- Enforce strict mode everywhere

## Status Summary

| Component | File | Status | Next Step |
|-----------|------|--------|-----------|
| Python Script | `scripts/check-anchors-vs-map.py` | ✅ Complete | Test with real data |
| Pre-Commit Hook | `scripts/pre-commit` | ✅ Complete | Install: `ln -sf ../../scripts/pre-commit .git/hooks/pre-commit` |
| CI Workflow | `.github/workflows/anchors.yml` | ✅ Complete | Commit and push to activate |
| Xcode Build Phase | N/A | ⏳ Manual | Follow implementation steps above |

## Next Actions

1. **Install pre-commit hook** (30 seconds):
   ```bash
   ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
   ```

2. **Test pre-commit hook** (2 minutes):
   - Create test file with missing anchor
   - Attempt commit
   - Verify hook blocks commit

3. **Commit CI workflow** (1 minute):
   ```bash
   git add .github/workflows/anchors.yml
   git commit -m "Add CI workflow for anchor validation"
   git push
   ```

4. **Add Xcode build phase** (5 minutes):
   - Follow implementation steps above
   - Build to verify

5. **Create initial mapping file** (if missing):
   ```bash
   mkdir -p mapping
   echo '{}' > mapping/fields_map.json
   ```

6. **Run first audit**:
   ```bash
   LENIENT=1 python3 scripts/check-anchors-vs-map.py > initial-audit.txt
   ```

## References

- Field Mapping Specification: `docs/reviews/settungs_update.md` (lines 890-1133)
- Settings Enhancement: `docs/reviews/SETTINGS_ENHANCEMENT_SUMMARY.md`
- Display Settings: `docs/guides/DISPLAY_SETTINGS_QUICK_REFERENCE.md`

---

**Last Updated**: 2025-01-17  
**Version**: 1.0  
**Author**: GitHub Copilot (automated infrastructure setup)
