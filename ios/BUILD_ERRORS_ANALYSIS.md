# Build Errors Analysis - November 11, 2025

## ✅ Fixed Issue #1: Duplicate ASAMVersion Enum

**Problem:** ASAMVersion was defined in TWO places:
- Models/ASAMModels.swift (correct: `.v3_2013`, `.v4_2024`)
- Services/RulesServiceWrapper.swift (wrong: `.v3`, `.v4`)

**Solution:** ✅ Removed duplicate from RulesServiceWrapper.swift

---

## 🔍 Current Issue #2: ASAMQuestion Initializer Mismatch

**Problem:** Builders (ASAMDimension1Builder, ASAMDimension3Builder) are calling ASAMQuestion with ~14 parameters, but the init only accepts 7.

**What Builders Are Calling:**
```swift
ASAMQuestion(
    id: "...",
    questionNumber: "1.2",
    text: "...",
    helpText: "...",           // ❌ Not in init signature
    type: .scale,
    options: options,          // ❌ Not in init signature
    validation: validation,    // ❌ Not in init signature
    skipLogic: nil,           // ❌ Not in init signature
    followUpQuestions: nil,   // ❌ Not in init signature
    riskWeighting: weighting, // ❌ Not in init signature
    isRequired: true,
    dimensionId: 1,
    subdimensionId: "..."
)
```

**What's Defined:**
```swift
init(id: String, questionNumber: String? = nil, text: String, type: ASAMQuestionType, 
     dimensionId: Int, subdimensionId: String? = nil, isRequired: Bool = true)
```

---

## 🎯 Root Cause

ASAMQuestion struct has ALL the properties defined, but only a **convenience initializer** for simple cases. The builders need the **full memberwise initializer** which Swift should provide automatically.

---

## ✅ Solution: Remove Custom Init (Let Swift Generate Memberwise)

Swift automatically generates a memberwise initializer for structs if you don't provide a custom one. The current custom init is **blocking** the automatic memberwise initializer.

**Option 1:** Remove the custom init entirely
**Option 2:** Keep custom init but add `@MainActor` or move to extension

---

## 🔍 Current Issue #3: Immutable Properties

**Problem:** ASAMService.swift trying to mutate `let` constants:
- `response.answers[questionId] = newAnswer` (line 138)
- `response.lastAnsweredQuestion = ...` (line 139)
- `response.lastModified = ...` (line 140)

**Solution:** These properties need to be `var` instead of `let` in ASAMAssessmentResponse struct

---

## 🔍 Current Issue #4: Missing ASAMSymptomCategory

**Problem:** ASAMDimension3Builder.swift references `ASAMSymptomCategory` but it doesn't exist

**Likely in:** ASAMModelsEnhanced.swift (currently disabled from build)

---

## 📊 Error Summary

| Category | Count | Status |
|----------|-------|--------|
| ASAMVersion ambiguous | ~5 | ✅ Should be fixed |
| Extra arguments in ASAMQuestion init | ~80 | 🔧 Need to fix init |
| Cannot assign to immutable | ~10 | 🔧 Need to change let→var |
| Missing ASAMSymptomCategory | ~3 | ⏸️ Need ASAMModelsEnhanced |

---

## 🎯 Next Steps

1. ✅ Clean build to verify ASAMVersion fix worked
2. 🔧 Fix ASAMQuestion initializer (remove custom init or make it extension)
3. 🔧 Change immutable properties to mutable in ASAMAssessmentResponse
4. ⏸️ Consider enabling ASAMModelsEnhanced.swift (after removing duplicates)
