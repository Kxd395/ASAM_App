# ASAM IP Compliance Enforcement - Implementation Task

**Priority**: 🔴 P0 - CRITICAL  
**Status**: 📋 TODO  
**Assigned**: Development Team  
**Due Date**: Before any TestFlight or production deployment  
**Task ID**: T-0050

---

## Goal

Keep the app compliant for internal enterprise use without an ASAM license. Add guardrails that prevent accidental use of ASAM text, marks, or PDFs. Make compliance testable in CI and visible in the UI.

**Current State**: Legal notice exists but no enforcement mechanisms.  
**Target State**: Hard controls in repo, app, CI, and build process that prevent IP violations.

---

## Scope

- iOS app source
- Rules JSON and PDFs
- CI pipeline
- Docs in repo

---

## Implementation Steps

### 1. Repo Policy

**Files to create/update:**
- `docs/governance/LEGAL_NOTICE_ASAM.md` (rename from existing)
- `docs/governance/CITATIONS.md` (new)

**Tasks:**
- [ ] Ensure legal notice file exists at `docs/governance/LEGAL_NOTICE_ASAM.md`
- [ ] Set version to 1.0 and date to today (November 10, 2025)
- [ ] Create `docs/governance/CITATIONS.md` with neutral citation section
- [ ] Verify zero trademark terms in headings

**Acceptance:**
- Both files exist and are properly formatted
- No ASAM trademarks in CITATIONS.md headings

---

### 2. App Configuration

**File to create:**
- `ios/ASAMAssessment/ASAMAssessment/Config/Compliance.swift`

**Implementation:**
```swift
import SwiftUI

enum ComplianceMode: String, Codable {
    case internal_neutral
    case licensed_asam
}

class ComplianceConfig: ObservableObject {
    @AppStorage("compliance.mode") var complianceMode: ComplianceMode = .internal_neutral
    @AppStorage("asam.license.id") var asamLicenseId: String?
    
    var canUseLicensedMode: Bool {
        guard let licenseId = asamLicenseId else { return false }
        return !licenseId.isEmpty
    }
    
    func setLicensedMode(licenseId: String) throws {
        guard !licenseId.isEmpty else {
            throw ComplianceError.missingLicenseId
        }
        self.asamLicenseId = licenseId
        self.complianceMode = .licensed_asam
    }
}

enum ComplianceError: Error {
    case missingLicenseId
    case officialTemplateInNeutralMode
    case bannedAssetInBundle
}
```

**Tasks:**
- [ ] Create `Config/Compliance.swift`
- [ ] Default to `internal_neutral` mode
- [ ] Block switching to `licensed_asam` unless `asamLicenseId` is nonempty
- [ ] Wire to app as `@StateObject` in main app

**Acceptance:**
- Compliance config accessible app-wide
- Cannot enable licensed mode without license ID
- Mode persists across app restarts

---

### 3. UI Wiring

**Files to modify:**
- `ios/ASAMAssessment/ASAMAssessment/Views/SettingsView.swift` (create if needed)
- `ios/ASAMAssessment/ASAMAssessment/Views/LegalView.swift` (new)
- `ios/ASAMAssessment/ASAMAssessment/Views/SummaryLOCView.swift`

**Tasks:**
- [ ] Add Legal screen at Settings > Legal that renders `LEGAL_NOTICE_ASAM.md` as read-only
- [ ] In `SummaryLOCView`, show source attribution:
  - `internal_neutral`: "Source: Internal Assessment"
  - `licensed_asam`: "Source: ASAM CONTINUUM (License: {id})"
- [ ] Audit all UI labels for ASAM terms
- [ ] Replace with neutral labels in `internal_neutral` mode:
  - "Domain A" not "ASAM Dimension 1"
  - "Level 2.1" not "ASAM Level 2.1"
  - "Assessment" not "ASAM Assessment"

**Acceptance:**
- Legal screen accessible and renders notice
- Source attribution visible in summary
- No ASAM/CONTINUUM/CO-Triage in UI when in neutral mode

---

### 4. PDF Export Rules

**Files to modify:**
- `tools/pdf_export/PDFExport.swift`
- `ios/ASAMAssessment/ASAMAssessment/Services/ExportService.swift` (create if needed)

**Tasks:**
- [ ] Block use of any official ASAM PDF unless `complianceMode == .licensed_asam`
- [ ] In `internal_neutral` mode:
  - [ ] Use only neutral templates
  - [ ] Strip all PDF metadata (author, device info)
  - [ ] Stamp footer with: `plan_hash`, `rules_hash`, `legal_notice_version`
- [ ] Add preflight check that fails if resource path contains "asam" or "continuum"

**Implementation:**
```swift
func preflightPDFExport(templatePath: String, complianceMode: ComplianceMode) throws {
    let lowercasePath = templatePath.lowercased()
    
    if complianceMode == .internal_neutral {
        if lowercasePath.contains("asam") || lowercasePath.contains("continuum") {
            throw ComplianceError.officialTemplateInNeutralMode
        }
    }
}

func stampPDFFooter(doc: PDFDocument, planHash: String, rulesHash: String, legalVersion: String) {
    let footer = "Plan: \(planHash.prefix(8)) | Rules: \(rulesHash.prefix(8)) | Legal: v\(legalVersion)"
    // Add to all pages
}
```

**Acceptance:**
- Cannot export with ASAM templates in neutral mode
- PDF metadata stripped in neutral mode
- Footer contains all required hashes

---

### 5. Asset and String Audit

**File to create:**
- `.github/workflows/asam-guard.yml`

**CI Job Configuration:**
```yaml
name: ASAM IP Guard

on: [push, pull_request]

jobs:
  asam-guard:
    name: Check for ASAM IP violations
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Scan for banned tokens
        run: |
          # Allowlist
          ALLOWED="docs/governance/LEGAL_NOTICE_ASAM.md docs/governance/CITATIONS.md"
          
          # Search patterns (case-insensitive)
          PATTERNS='\bASAM\b|\bCONTINUUM\b|CO[- ]?Triage|Dimension 1|Dimension 2'
          
          # Scan directories
          VIOLATIONS=0
          for dir in ios/ASAMAssessment/Assets ios/ASAMAssessment/Resources agent_ops/rules data/; do
            if [ -d "$dir" ]; then
              MATCHES=$(grep -riE "$PATTERNS" "$dir" --exclude-dir=".git" || true)
              if [ -n "$MATCHES" ]; then
                echo "❌ Found violations in $dir:"
                echo "$MATCHES"
                VIOLATIONS=$((VIOLATIONS+1))
              fi
            fi
          done
          
          # Check PDF filenames
          ASAM_PDFS=$(find . -name "*asam*.pdf" -o -name "*continuum*.pdf" | grep -v "$ALLOWED" || true)
          if [ -n "$ASAM_PDFS" ]; then
            echo "❌ Found ASAM/CONTINUUM PDFs:"
            echo "$ASAM_PDFS"
            VIOLATIONS=$((VIOLATIONS+1))
          fi
          
          if [ $VIOLATIONS -gt 0 ]; then
            echo "❌ ASAM IP violations detected. See above."
            exit 1
          fi
          
          echo "✅ No ASAM IP violations found"
```

**Tasks:**
- [ ] Create CI workflow `asam-guard.yml`
- [ ] Configure allowlist for legal docs only
- [ ] Test with intentional violation (should fail)
- [ ] Test clean repo (should pass)

**Acceptance:**
- CI fails when banned tokens found outside allowlist
- CI passes on clean repo
- Clear error messages show violation locations

---

### 6. Source Scanner Script

**File to create:**
- `tools/asam_guard.sh`

**Implementation:**
```bash
#!/bin/bash
# ASAM IP Guard - Scans for trademark violations

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

ALLOWED_FILES=(
  "docs/governance/LEGAL_NOTICE_ASAM.md"
  "docs/governance/CITATIONS.md"
)

PATTERNS='\bASAM\b|\bCONTINUUM\b|CO[- ]?Triage'
VIOLATIONS=0

echo "🔍 Scanning for ASAM IP violations..."

# Scan code and JSON
for ext in swift json md; do
  FILES=$(find ios agent_ops data -name "*.$ext" -type f || true)
  for file in $FILES; do
    # Skip allowed files
    SKIP=false
    for allowed in "${ALLOWED_FILES[@]}"; do
      if [[ "$file" == *"$allowed"* ]]; then
        SKIP=true
        break
      fi
    done
    
    if [ "$SKIP" = false ]; then
      MATCHES=$(grep -iE "$PATTERNS" "$file" || true)
      if [ -n "$MATCHES" ]; then
        echo "❌ Violation in $file:"
        echo "$MATCHES" | head -3
        VIOLATIONS=$((VIOLATIONS+1))
      fi
    fi
  done
done

if [ $VIOLATIONS -gt 0 ]; then
  echo ""
  echo "❌ Found $VIOLATIONS file(s) with ASAM IP violations"
  echo "Fix violations or add to allowlist in tools/asam_guard.sh"
  exit 1
fi

echo "✅ No ASAM IP violations detected"
exit 0
```

**Tasks:**
- [ ] Create `tools/asam_guard.sh`
- [ ] Make executable: `chmod +x tools/asam_guard.sh`
- [ ] Add to pre-commit hook
- [ ] Test with violations

**Acceptance:**
- Script exits 1 when violations found
- Script exits 0 on clean repo
- Shows clear violation reports

---

### 7. Rules Provenance

**Files to modify:**
- `ios/ASAMAssessment/ASAMAssessment/Services/RulesServiceWrapper.swift`
- `ios/ASAMAssessment/ASAMAssessment/Services/AuditService.swift`

**Implementation:**
```swift
func computeRulesHash() -> String {
    // Load all rules JSON files
    let files = ["wm_ladder.json", "loc_indication.json", "validation_rules.json"]
    var combined = ""
    
    for file in files {
        if let data = loadRulesFile(file) {
            combined += data
        }
    }
    
    let hash = SHA256.hash(data: combined.data(using: .utf8)!)
    return hash.map { String(format: "%02x", $0) }.joined()
}

// On app launch
func auditRulesLoaded() {
    let rulesHash = computeRulesHash()
    let rulesHashShort = String(rulesHash.prefix(16))
    
    auditService.logEvent(
        .rulesLoaded,
        actor: "system",
        notes: "Rules version: \(rulesVersion), Hash: \(rulesHashShort)"
    )
    
    // Store for PDF footer
    UserDefaults.standard.set(rulesHashShort, forKey: "rules_hash_short")
}
```

**Tasks:**
- [ ] Add `computeRulesHash()` to RulesServiceWrapper
- [ ] Log `rules_loaded` audit event on app launch
- [ ] Store `rules_hash_short` in UserDefaults
- [ ] Include in PDF footer

**Acceptance:**
- Rules hash computed on launch
- Audit event logged with version and hash
- Same hash appears in PDF footer

---

### 8. Distribution Gate

**File to modify:**
- Xcode project build phases

**Build Phase Script:**
```bash
# Compliance Gate

if [[ "$PRODUCT_BUNDLE_IDENTIFIER" == *"testflight"* ]] || [[ "$PRODUCT_BUNDLE_IDENTIFIER" == *"appstore"* ]]; then
  
  COMPLIANCE_MODE=$(defaults read "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Defaults" "compliance.mode" 2>/dev/null || echo "internal_neutral")
  ALLOW_PUBLIC="${ALLOW_PUBLIC_DISTRIBUTION_INTERNAL_NEUTRAL:-false}"
  
  if [[ "$COMPLIANCE_MODE" == "internal_neutral" ]] && [[ "$ALLOW_PUBLIC" != "true" ]]; then
    echo "error: ❌ Cannot distribute to TestFlight/App Store in internal_neutral compliance mode"
    echo "error: Either:"
    echo "error:   1. Set compliance.mode to licensed_asam (requires ASAM license)"
    echo "error:   2. Set ALLOW_PUBLIC_DISTRIBUTION_INTERNAL_NEUTRAL=true (for enterprise-only apps)"
    exit 1
  fi
fi

echo "✅ Compliance gate passed"
```

**Tasks:**
- [ ] Add build phase "Compliance Gate" in Xcode
- [ ] Configure to run after "Compile Sources"
- [ ] Test with TestFlight bundle ID (should fail)
- [ ] Test with ALLOW_PUBLIC override (should pass)

**Acceptance:**
- Build fails for public distribution in neutral mode
- Clear error message with remediation steps
- Override flag works for enterprise apps

---

### 9. Unit Tests

**File to create:**
- `ios/ASAMAssessment/ASAMAssessmentTests/ComplianceTests.swift`

**Implementation:**
```swift
import XCTest
@testable import ASAMAssessment

class ComplianceTests: XCTestCase {
    
    func testNoBannedTokensInAppBundle() throws {
        let bundle = Bundle.main
        let bannedPatterns = ["ASAM", "CONTINUUM", "CO-Triage"]
        
        // Scan all text resources
        for pattern in bannedPatterns {
            // Check Info.plist
            let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
            XCTAssertFalse(displayName.contains(pattern), "Bundle display name contains banned token: \(pattern)")
        }
    }
    
    func testComplianceModeBlocksOfficialTemplates() throws {
        let compliance = ComplianceConfig()
        compliance.complianceMode = .internal_neutral
        
        let officialTemplate = "path/to/ASAM_Template.pdf"
        
        XCTAssertThrowsError(
            try preflightPDFExport(templatePath: officialTemplate, complianceMode: compliance.complianceMode)
        ) { error in
            XCTAssertEqual(error as? ComplianceError, .officialTemplateInNeutralMode)
        }
    }
    
    func testLegalNoticePresentInUI() throws {
        let legalView = LegalView()
        // Assert notice renders (check for key phrases)
        // This would need UI testing
    }
    
    func testPDFFooterContainsRulesAndLegalVersion() throws {
        // Create neutral sample export
        let planHash = "abc123def456"
        let rulesHash = "789ghi012jkl"
        let legalVersion = "1.0"
        
        // Export PDF
        let pdf = exportNeutralSample(planHash: planHash, rulesHash: rulesHash, legalVersion: legalVersion)
        
        // Extract footer text from PDF
        let footerText = extractPDFFooter(pdf)
        
        XCTAssertTrue(footerText.contains(String(planHash.prefix(8))))
        XCTAssertTrue(footerText.contains(String(rulesHash.prefix(8))))
        XCTAssertTrue(footerText.contains("v\(legalVersion)"))
    }
}
```

**Tasks:**
- [ ] Create `ComplianceTests.swift`
- [ ] Implement all 4 test methods
- [ ] Run tests and verify they pass
- [ ] Add to CI test suite

**Acceptance:**
- All 4 tests pass on clean code
- Tests fail when violations introduced
- Tests run in CI automatically

---

### 10. Documentation

**Files to update:**
- `README.md`
- `agent_ops/docs/MASTER_TODO.md`
- Create `docs/COMPLIANCE_REPORT.md`

**README.md additions:**
```markdown
## 🔒 ASAM IP Compliance

This application is designed for **internal enterprise use only** without an ASAM license.

### Compliance Mode

The app operates in two modes:

1. **Internal Neutral** (default)
   - Uses neutral terminology ("Domain A", "Level 2.1")
   - No ASAM trademarks in UI
   - Blocks official ASAM PDF templates
   - Safe for internal use without license

2. **Licensed ASAM** (requires license)
   - Enables ASAM terminology and branding
   - Allows official PDF templates
   - Requires valid `asam.license.id`

### Configuration

```swift
// Set compliance mode
ComplianceConfig.shared.complianceMode = .internal_neutral

// For licensed mode (requires ASAM agreement)
try ComplianceConfig.shared.setLicensedMode(licenseId: "ASAM-2025-0001")
```

### Restrictions

- ❌ No ASAM text or trademarks in UI (neutral mode)
- ❌ No AI ingestion of ASAM materials
- ❌ No distribution to App Store/TestFlight (neutral mode)
- ✅ Internal enterprise deployment allowed

### Legal

See [LEGAL_NOTICE_ASAM.md](docs/governance/LEGAL_NOTICE_ASAM.md) for full compliance requirements.

For ASAM licensing: asamcriteria@asam.org
```

**MASTER_TODO.md additions:**
- T-0050: ASAM IP Compliance Enforcement (meta-task)
- T-0051: CI token guard implementation
- T-0052: Compliance Gate in build process
- T-0053: Legal screen and PDF footer fields
- T-0054: Rules hash audit event
- T-0055: Licensed mode toggle and checks

**COMPLIANCE_REPORT.md:**
```markdown
# ASAM IP Compliance Report

**Date**: November 10, 2025  
**Version**: 1.0  
**Current Mode**: Internal Neutral

## Summary

All ASAM IP compliance enforcement mechanisms have been implemented.

## Changes Made

### Code
- Added `Config/Compliance.swift` with mode switching
- Added `Views/LegalView.swift` for in-app legal notice
- Updated `SummaryLOCView.swift` with source attribution
- Added PDF export preflight checks
- Added rules provenance tracking

### CI/CD
- Added `asam-guard.yml` workflow
- Added pre-commit hook for local validation
- Added Xcode build phase "Compliance Gate"

### Documentation
- Renamed legal notice to `LEGAL_NOTICE_ASAM.md`
- Created `CITATIONS.md` with neutral citations
- Updated README.md with compliance section

### Tests
- Added `ComplianceTests.swift` with 4 test methods
- All tests passing

## Current Compliance Status

✅ **Enforcement Active**
- CI blocks banned tokens
- Build blocks public distribution in neutral mode
- Export blocks official ASAM templates
- UI shows only neutral terminology

✅ **Auditability**
- Rules hash tracked and logged
- PDF footers contain provenance
- Legal version stamped in exports

✅ **Documentation**
- Legal notice accessible in app
- README explains modes clearly
- All restrictions documented

## Mode Details

**Current**: Internal Neutral
**License ID**: None
**Public Distribution**: Blocked

To enable licensed mode, contact asamcriteria@asam.org for licensing agreement.

## Acceptance Criteria Status

- [x] Build fails if banned assets introduced
- [x] Export fails with ASAM templates in neutral mode
- [x] UI shows no ASAM terms in neutral mode
- [x] Legal screen present and functional
- [x] PDF footer contains all required hashes
- [x] CI guard passes on clean repo
- [x] Licensed mode requires license ID

## Next Steps

1. Test distribution build (should block)
2. Verify all UI labels neutral
3. Run full test suite
4. Deploy to enterprise environment

---

**Report Generated**: November 10, 2025  
**Compliance Officer**: Development Team
```

**Tasks:**
- [ ] Add compliance section to README.md
- [ ] Update MASTER_TODO.md with new task IDs
- [ ] Create COMPLIANCE_REPORT.md
- [ ] Update PROJECT_STRUCTURE.md if needed

**Acceptance:**
- README explains both modes clearly
- TODO reflects new tasks
- Compliance report is comprehensive

---

## Acceptance Criteria Summary

✅ **Build Enforcement**
- [ ] Build fails if banned asset/string introduced outside allowlist
- [ ] Build fails for TestFlight/App Store in neutral mode

✅ **Export Enforcement**
- [ ] Export fails in neutral mode with ASAM templates
- [ ] PDF metadata stripped in neutral mode
- [ ] PDF footer contains plan hash, rules hash, legal version

✅ **UI Compliance**
- [ ] No ASAM/CONTINUUM/CO-Triage in neutral mode UI
- [ ] Legal screen shows notice verbatim
- [ ] Source attribution visible in summary

✅ **CI/CD**
- [ ] CI job `asam-guard` passes on clean repo
- [ ] CI job fails when banned token injected

✅ **Mode Switching**
- [ ] Cannot enable licensed mode without license ID
- [ ] Mode persists across restarts

---

## Deliverables

- [ ] PR with all code changes
- [ ] CI workflow `asam-guard.yml`
- [ ] Unit tests `ComplianceTests.swift`
- [ ] Script `tools/asam_guard.sh`
- [ ] Build phase "Compliance Gate"
- [ ] Documentation:
  - [ ] `docs/governance/LEGAL_NOTICE_ASAM.md`
  - [ ] `docs/governance/CITATIONS.md`
  - [ ] `docs/COMPLIANCE_REPORT.md`
  - [ ] Updated `README.md`
  - [ ] Updated `MASTER_TODO.md`

---

## Notes for Implementation

- ❌ Do not place new files in repo root
- ✅ Keep new code under `ios/`, `tools/`, or `docs/`
- ✅ Use neutral wording everywhere unless `compliance mode = licensed_asam`
- ✅ Test thoroughly before marking complete
- ✅ Get legal review of all text changes

---

## Estimated Effort

- **Planning**: 2 hours
- **Code Implementation**: 8 hours
- **CI/CD Setup**: 3 hours
- **Testing**: 4 hours
- **Documentation**: 2 hours
- **Review & Fixes**: 3 hours

**Total**: ~22 hours (3 days)

---

## Dependencies

- None (can start immediately)

## Blockers

- None identified

---

**Created**: November 10, 2025  
**Priority**: P0 - Must complete before any external distribution  
**Owner**: Development Team  
**Status**: Ready to start
