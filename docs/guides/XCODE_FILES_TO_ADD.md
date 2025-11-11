# Files to Add to Xcode Project - Quick Checklist

**Problem**: Build fails because these files exist but aren't added to the Xcode project.

**Solution**: Add them through Xcode (File → Add Files to "ASAMAssessment"...)

---

## ✅ Files That Need to Be Added

### 1. Models Folder

**Right-click "Models" → Add Files to "ASAMAssessment"...**

- [ ] `ios/ASAMAssessment/ASAMAssessment/Models/AppSettings.swift`
  - ✅ Target: **ASAMAssessment**

---

### 2. Services Folder

**Right-click "Services" → Add Files to "ASAMAssessment"...**

- [ ] `ios/ASAMAssessment/ASAMAssessment/Services/SettingsStore.swift`
  - ✅ Target: **ASAMAssessment**
  
- [ ] `ios/ASAMAssessment/ASAMAssessment/Services/SettingsCoordinator.swift`
  - ✅ Target: **ASAMAssessment**

---

### 3. Views Folder

**Right-click "Views" → Add Files to "ASAMAssessment"...**

- [ ] `ios/ASAMAssessment/ASAMAssessment/Views/SafetyReviewSheet.swift`
  - ✅ Target: **ASAMAssessment**
  
- [ ] `ios/ASAMAssessment/ASAMAssessment/Views/SettingsView.swift`
  - ✅ Target: **ASAMAssessment**
  
- [ ] `ios/ASAMAssessment/ASAMAssessment/Views/SettingsViewEnhanced.swift`
  - ✅ Target: **ASAMAssessment**

---

### 4. Views/UIKit Folder (if folder exists)

**If Views/UIKit folder exists, add to it. Otherwise add to Views.**

- [ ] `ios/ASAMAssessment/ASAMAssessment/Views/UIKit/AutofocusTextView.swift`
  - ✅ Target: **ASAMAssessment**

**OR if UIKit folder doesn't exist:**

- [ ] `ios/ASAMAssessment/ASAMAssessment/Views/AutofocusTextView.swift`
  - ✅ Target: **ASAMAssessment**

---

### 5. Test Files (ASAMAssessmentTests)

**Right-click "ASAMAssessmentTests" → Add Files to "ASAMAssessment"...**

- [ ] `ios/ASAMAssessment/ASAMAssessmentTests/StrictAnchors.swift`
  - ✅ Target: **ASAMAssessmentTests** (not ASAMAssessment!)
  
- [ ] `ios/ASAMAssessment/ASAMAssessmentTests/StrictRulesValidationTests.swift`
  - ✅ Target: **ASAMAssessmentTests** (not ASAMAssessment!)

---

### 6. UI Test Files (ASAMAssessmentUITests)

**Right-click "ASAMAssessmentUITests" → Add Files to "ASAMAssessment"...**

- [ ] `ios/ASAMAssessment/ASAMAssessmentUITests/SafetyReviewUITests.swift`
  - ✅ Target: **ASAMAssessmentUITests**

---

## ⚠️ IMPORTANT: When Adding Files

### For EACH file you add:

1. **Uncheck** "Copy items if needed" (files are already in right place)
2. **Check** the correct target:
   - App files → **ASAMAssessment**
   - Unit tests → **ASAMAssessmentTests**
   - UI tests → **ASAMAssessmentUITests**
3. Click **Add**

---

## Quick Verification

After adding all files, verify in Xcode:

### Check Target Membership:
1. Select each file in Navigator
2. Look at File Inspector (right panel)
3. Verify correct target is checked

### Build:
```bash
# Should compile without "Cannot find X in scope" errors
Cmd+B in Xcode
```

---

## After Adding Files

Once all files are added to Xcode:

1. **Clean Build Folder**: Cmd+Shift+K
2. **Build**: Cmd+B
3. **Run Tests**: Cmd+U

Expected result: ✅ Build succeeds, no "Cannot find" errors

---

## Common Mistakes

❌ **Copying files instead of referencing**
- Always uncheck "Copy items if needed"

❌ **Wrong target membership**
- App code → ASAMAssessment target
- Tests → Test targets

❌ **Forgetting to add files**
- Use this checklist to track progress

---

## Status

- [ ] All Models files added (1 file)
- [ ] All Services files added (2 files)
- [ ] All Views files added (4 files)
- [ ] All Test files added (2 files)
- [ ] All UI Test files added (1 file)
- [ ] Build succeeds (Cmd+B)

**Total**: 10 files to add

---

**After completing this checklist**, the build should succeed! 🎉
