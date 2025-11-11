# Essential Files Checklist

## Files Currently in Build Target

Run this command to see current files:
```bash
grep "\.swift in Sources" ASAMAssessment.xcodeproj/project.pbxproj | grep -v "fileRef\|isa"
```

## Essential Files That Should Be Added

- [ ] AppDelegate.swift
- [ ] Views/ContentView.swift
- [ ] Views/QuestionnaireRenderer.swift
- [ ] Views/RobustTextField.swift
- [ ] Services/ASAMService.swift
- [ ] Services/ASAMDimension1Builder.swift
- [ ] Services/ASAMDimension3Builder.swift
- [ ] Services/ASAMSkipLogicEngine.swift
- [ ] Services/ASAMSubstanceInventoryBuilder.swift
- [ ] Utilities/TextInputManager.swift
- [ ] Utilities/TimeUtility.swift
- [ ] Utils/PDFMetadataScrubber.swift
- [ ] Views/SettingsView.swift
- [ ] Diagnostics/SafetyReviewDiagnostic.swift

## Archived Files (Duplicates)

The following duplicate files have been moved to `_archived_files/duplicates/`:

- RulesProvenance.swift (duplicate - kept version in Services/)
- RulesServiceWrapper.swift (duplicate - kept version in Services/)
