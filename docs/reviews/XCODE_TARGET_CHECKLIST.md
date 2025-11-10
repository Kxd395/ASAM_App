# Quick Checklist: Add 33 Files to Xcode Targets

**Print this and check off as you go!**

---

## Critical Files First (Fix immediate compile errors)

### 🔥 Priority 1 - Blocking ASAMAssessmentApp.swift
- [ ] `Services/NetworkSanityChecker.swift` → ASAMAssessment target
- [ ] `Services/UploadQueue.swift` → ASAMAssessment target
- [ ] `Utils/Time.swift` → ASAMAssessment target

**After adding these 3, try building (⌘B) - Should reduce errors significantly**

---

## Priority 2 - Core Services (Essential for app to run)

- [ ] `Services/RulesService.swift` → ASAMAssessment target
- [ ] `Services/RulesEngine.swift` → ASAMAssessment target
- [ ] `Services/AssessmentStore.swift` → ASAMAssessment target
- [ ] `Services/DatabaseManager.swift` → ASAMAssessment target
- [ ] `Services/AuditService.swift` → ASAMAssessment target
- [ ] `Services/LOCService.swift` → ASAMAssessment target
- [ ] `Services/TokenProvider.swift` → ASAMAssessment target
- [ ] `Services/MDMWipeHandler.swift` → ASAMAssessment target

**After adding these, try building again**

---

## Priority 3 - P0 Files (From recent commits)

- [ ] `Services/RulesServiceWrapper.swift` → ASAMAssessment target
- [ ] `Services/ExportPreflight.swift` → ASAMAssessment target
- [ ] `Services/RulesProvenance.swift` → ASAMAssessment target
- [ ] `Services/ReconciliationChecks.swift` → ASAMAssessment target
- [ ] `Services/ComplianceConfig.swift` → ASAMAssessment target

---

## Priority 4 - Models & Utils

- [ ] `Models/Assessment.swift` → ASAMAssessment target
- [ ] `Models/SubstanceRow.swift` → ASAMAssessment target
- [ ] `Utils/PDFMetadataScrubber.swift` → ASAMAssessment target
- [ ] `Utils/ExportUtils.swift` → ASAMAssessment target

---

## Priority 5 - Views & Components

- [ ] `Views/ContentView.swift` → ASAMAssessment target
- [ ] `Views/SubstanceRowSheet.swift` → ASAMAssessment target
- [ ] `Views/ClinicalFlagsSection.swift` → ASAMAssessment target
- [ ] `Views/FlagsSection.swift` → ASAMAssessment target
- [ ] `Views/RulesDegradedBanner.swift` → ASAMAssessment target
- [ ] `Views/RulesDiagnosticsView.swift` → ASAMAssessment target
- [ ] `Views/SubstanceSheet.swift` → ASAMAssessment target
- [ ] `Components/SafetyBanner.swift` → ASAMAssessment target

**After adding all above, build should succeed!**

---

## Priority 6 - Test Files

- [ ] `ASAMAssessmentTests/ASAMAssessmentTests.swift` → ASAMAssessmentTests target
- [ ] `ASAMAssessmentUITests/ASAMAssessmentUITests.swift` → ASAMAssessmentUITests target
- [ ] `ASAMAssessmentUITests/ASAMAssessmentUITestsLaunchTests.swift` → ASAMAssessmentUITests target

---

## How to Add Each File in Xcode

1. **Select the file** in Project Navigator (left panel)
2. **Open File Inspector** (right panel, ⌘⌥1)
3. **Check the target checkbox**:
   - "ASAMAssessment" for app files
   - "ASAMAssessmentTests" for test files
   - "ASAMAssessmentUITests" for UI test files

**OR**

1. **Right-click project** in navigator
2. **Add Files to "ASAMAssessment"...**
3. **Navigate to file**
4. **Uncheck "Copy items if needed"** (already in place)
5. **Check correct target**
6. **Click Add**

---

## Verification Commands

After adding files:

```bash
# Check target membership
./scripts/check-target-membership.sh

# Count missing files (should be 0)
find ios/ASAMAssessment/ASAMAssessment -name "*.swift" -type f | \
  while read f; do 
    rel="${f#ios/ASAMAssessment/ASAMAssessment/}"
    grep -q "$rel" ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj/project.pbxproj || echo "MISSING: $rel"
  done | wc -l
```

**Expected**: 0 missing files

---

## Final Check

1. **Build** (⌘B in Xcode) → Should succeed
2. **Run** (⌘R in Xcode) → App should launch in simulator
3. **Verify** no "Cannot find X in scope" errors
4. **Tell agent** when working → Then commit & push

---

**Progress**: ☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐☐ (0/33)

**Estimated Time**: 30-45 minutes
