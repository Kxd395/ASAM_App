# ASAMAssessment Project - File Tree with Missing Files

## 📁 Complete Project Structure

```
ASAMAssessment/
│
├── 📄 AppDelegate.swift                          ❌ MISSING FROM BUILD
├── 📄 ASAMAssessmentApp.swift                    ✅ In Build
├── 📄 TestQuestionnaireLoading.swift             ⚠️  (test file)
│
├── 📁 Components/
│   └── 📄 SafetyBanner.swift                     ✅ In Build
│
├── 📁 Diagnostics/
│   └── 📄 SafetyReviewDiagnostic.swift           ❌ MISSING FROM BUILD
│
├── 📁 Models/
│   ├── 📄 AppSettings.swift                      ✅ In Build
│   ├── 📄 ASAMModels.swift                       ✅ In Build
│   ├── 📄 ASAMModelsEnhanced.swift               ⏸️  DISABLED (has errors)
│   ├── 📄 ASAMTraceabilityMatrix.swift           ✅ In Build
│   ├── 📄 Assessment.swift                       ✅ In Build
│   ├── 📄 QuestionnaireModels.swift              ✅ In Build
│   └── 📄 SubstanceRow.swift                     ✅ In Build
│
├── 📁 Services/
│   ├── 📄 ASAMDimension1Builder.swift            ❌ MISSING FROM BUILD
│   ├── 📄 ASAMDimension3Builder.swift            ❌ MISSING FROM BUILD
│   ├── 📄 ASAMService.swift                      ❌ MISSING FROM BUILD
│   ├── 📄 ASAMSkipLogicEngine.swift              ❌ MISSING FROM BUILD
│   ├── 📄 ASAMSubstanceInventoryBuilder.swift    ❌ MISSING FROM BUILD
│   ├── 📄 AssessmentStore.swift                  ✅ In Build
│   ├── 📄 AuditService.swift                     ✅ In Build
│   ├── 📄 ComplianceConfig.swift                 ✅ In Build
│   ├── 📄 DatabaseManager.swift                  ✅ In Build
│   ├── 📄 ExportPreflight.swift                  ✅ In Build
│   ├── 📄 LOCService.swift                       ✅ In Build
│   ├── 📄 MDMWipeHandler.swift                   ✅ In Build
│   ├── 📄 NetworkSanityChecker.swift             ✅ In Build
│   ├── 📄 QuestionsService.swift                 ✅ In Build
│   ├── 📄 ReconciliationChecks.swift             ✅ In Build
│   ├── 📄 RulesEngine.swift                      ✅ In Build
│   ├── 📄 RulesProvenance.swift                  ✅ In Build
│   ├── 📄 RulesService.swift                     ✅ In Build
│   ├── 📄 RulesServiceWrapper.swift              ✅ In Build
│   ├── 📄 SettingsCoordinator.swift              ✅ In Build
│   ├── 📄 SettingsStore.swift                    ✅ In Build
│   ├── 📄 SeverityScoring.swift                  ✅ In Build
│   ├── 📄 TokenProvider.swift                    ✅ In Build
│   └── 📄 UploadQueue.swift                      ✅ In Build
│
├── 📁 Utilities/
│   ├── 📄 TextInputManager.swift                 ❌ MISSING FROM BUILD
│   └── 📄 TimeUtility.swift                      ❌ MISSING FROM BUILD
│
├── 📁 Utils/
│   ├── 📄 ExportUtils.swift                      ✅ In Build
│   ├── 📄 PDFMetadataScrubber.swift              ❌ MISSING FROM BUILD
│   └── 📄 Time.swift                             ✅ In Build
│
├── 📁 Views/
│   ├── 📄 ClinicalFlagsSection.swift             ✅ In Build
│   ├── 📄 ContentView.swift                      ❌ MISSING FROM BUILD
│   ├── 📄 FlagsSection.swift                     ✅ In Build
│   ├── 📄 QuestionnaireRenderer.swift            ❌ MISSING FROM BUILD
│   ├── 📄 RobustTextField.swift                  ❌ MISSING FROM BUILD
│   ├── 📄 RulesDegradedBanner.swift              ✅ In Build
│   ├── 📄 RulesDiagnosticsView.swift             ✅ In Build
│   ├── 📄 SafetyReviewSheet.swift                ✅ In Build
│   ├── 📄 SettingsView.swift                     ❌ MISSING FROM BUILD
│   ├── 📄 SettingsViewEnhanced.swift             ✅ In Build
│   ├── 📄 SubstanceGridView.swift                ✅ In Build
│   ├── 📄 SubstanceRowSheet.swift                ✅ In Build
│   ├── 📄 SubstanceSheet.swift                   ✅ In Build
│   └── 📁 UIKit/
│       └── 📄 AutofocusTextView.swift            ✅ In Build
│
└── 📁 _archived_files/                           (cleaned up duplicates)
    └── 📁 duplicates/
        ├── 📄 RulesProvenance.swift
        └── 📄 RulesServiceWrapper.swift
```

---

## ❌ Files MISSING from Xcode Build (14 Total)

### Root Level (1 file)
```
ASAMAssessment/
└── AppDelegate.swift                             ❌ ADD THIS
```

### Diagnostics (1 file)
```
ASAMAssessment/Diagnostics/
└── SafetyReviewDiagnostic.swift                  ❌ ADD THIS
```

### Services (5 files)
```
ASAMAssessment/Services/
├── ASAMDimension1Builder.swift                   ❌ ADD THIS
├── ASAMDimension3Builder.swift                   ❌ ADD THIS
├── ASAMService.swift                             ❌ ADD THIS
├── ASAMSkipLogicEngine.swift                     ❌ ADD THIS
└── ASAMSubstanceInventoryBuilder.swift           ❌ ADD THIS
```

### Utilities (2 files)
```
ASAMAssessment/Utilities/
├── TextInputManager.swift                        ❌ ADD THIS
└── TimeUtility.swift                             ❌ ADD THIS
```

### Utils (1 file)
```
ASAMAssessment/Utils/
└── PDFMetadataScrubber.swift                     ❌ ADD THIS
```

### Views (4 files)
```
ASAMAssessment/Views/
├── ContentView.swift                             ❌ ADD THIS
├── QuestionnaireRenderer.swift                   ❌ ADD THIS
├── RobustTextField.swift                         ❌ ADD THIS
└── SettingsView.swift                            ❌ ADD THIS
```

---

## 🎯 How to Add Each File in Xcode

### Step 1: Add AppDelegate.swift (Root Level)
1. In Xcode Project Navigator, locate **"ASAMAssessment"** folder (the TOP one, same level as Models/Views/Services)
2. Right-click on **"ASAMAssessment"** folder
3. Choose **"Add Files to ASAMAssessment..."**
4. In the file picker, navigate to show files at root level
5. Select **AppDelegate.swift** (it's at the root, same level as ASAMAssessmentApp.swift)
6. ✓ Check **"Add to targets: ASAMAssessment"**
7. ✗ Uncheck **"Copy items if needed"**
8. Click **"Add"**

### Step 2: Add Views Files (4 files)
1. In Xcode, find and right-click the **"Views"** folder
2. Choose **"Add Files to ASAMAssessment..."**
3. The file picker should open in the Views folder
4. Hold **Cmd** and click to select ALL 4 files:
   - **ContentView.swift**
   - **QuestionnaireRenderer.swift**
   - **RobustTextField.swift**
   - **SettingsView.swift**
5. ✓ Check **"Add to targets: ASAMAssessment"**
6. ✗ Uncheck **"Copy items if needed"**
7. Click **"Add"**

### Step 3: Add Services Files (5 files)
1. In Xcode, right-click the **"Services"** folder
2. Choose **"Add Files to ASAMAssessment..."**
3. Hold **Cmd** and select these 5 files (they all start with "ASAM"):
   - **ASAMDimension1Builder.swift**
   - **ASAMDimension3Builder.swift**
   - **ASAMService.swift**
   - **ASAMSkipLogicEngine.swift**
   - **ASAMSubstanceInventoryBuilder.swift**
4. ✓ Check **"Add to targets: ASAMAssessment"**
5. ✗ Uncheck **"Copy items if needed"**
6. Click **"Add"**

### Step 4: Add Utilities Files (2 files)
1. Right-click the **"Utilities"** folder
2. Choose **"Add Files to ASAMAssessment..."**
3. Select both:
   - **TextInputManager.swift**
   - **TimeUtility.swift**
4. ✓ Check **"Add to targets: ASAMAssessment"**
5. ✗ Uncheck **"Copy items if needed"**
6. Click **"Add"**

### Step 5: Add Utils/PDFMetadataScrubber.swift (1 file)
1. Right-click the **"Utils"** folder
2. Choose **"Add Files to ASAMAssessment..."**
3. Select **PDFMetadataScrubber.swift**
4. ✓ Check **"Add to targets: ASAMAssessment"**
5. ✗ Uncheck **"Copy items if needed"**
6. Click **"Add"**

### Step 6: Add Diagnostics/SafetyReviewDiagnostic.swift (1 file)
1. Right-click the **"Diagnostics"** folder
2. Choose **"Add Files to ASAMAssessment..."**
3. Select **SafetyReviewDiagnostic.swift**
4. ✓ Check **"Add to targets: ASAMAssessment"**
5. ✗ Uncheck **"Copy items if needed"**
6. Click **"Add"**

---

## ✅ After Adding All Files

1. **Clean:** Press `Cmd+Shift+K`
2. **Build:** Press `Cmd+B`
3. **Run:** Press `Cmd+R` (if build succeeds)

---

## 📊 File Locations Reference

**Full paths for reference:**
```bash
# Root level
./AppDelegate.swift

# Diagnostics
./Diagnostics/SafetyReviewDiagnostic.swift

# Services
./Services/ASAMDimension1Builder.swift
./Services/ASAMDimension3Builder.swift
./Services/ASAMService.swift
./Services/ASAMSkipLogicEngine.swift
./Services/ASAMSubstanceInventoryBuilder.swift

# Utilities
./Utilities/TextInputManager.swift
./Utilities/TimeUtility.swift

# Utils
./Utils/PDFMetadataScrubber.swift

# Views
./Views/ContentView.swift
./Views/QuestionnaireRenderer.swift
./Views/RobustTextField.swift
./Views/SettingsView.swift
```

---

## 🔍 Legend

- ✅ = File is in Xcode build target
- ❌ = File exists but NOT in build target (NEEDS TO BE ADDED)
- ⏸️ = File disabled due to errors
- ⚠️ = Test file (optional)

---

**Created:** November 11, 2025  
**Purpose:** Visual guide for adding missing files to Xcode project
