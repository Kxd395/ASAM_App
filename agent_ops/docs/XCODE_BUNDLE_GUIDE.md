# Xcode Bundle Integration Guide

**Date:** 2025-11-09  
**Status:** Ready to complete

## 📋 **Quick Checklist**

### ✅ **Already Done**
- [x] RulesEngine.swift in correct location and added to target
- [x] RulesService.swift in correct location and added to target
- [x] RulesService updated to use `Bundle.main.url(forResource:withExtension:)`
- [x] Build succeeds

### ⏳ **To Do Now**

- [ ] Remove current `rules` folder (if it exists)
- [ ] Add 3 JSON files to Xcode project root
- [ ] Verify files show target membership
- [ ] Build and test

---

## 🎯 **Step-by-Step: Add JSON Files**

### Step 1: Clean Up Current Rules Folder (if needed)

If you have a `rules` folder in Project Navigator:

1. Right-click `rules` folder
2. Select **"Delete"**
3. Choose **"Remove Reference"** (files stay on disk)

### Step 2: Add the 3 Required JSON Files

1. In Xcode Project Navigator, right-click **`ASAMAssessment`** (the project root)
2. Select **"Add Files to 'ASAMAssessment'..."**
3. Navigate to: `/Users/kevindialmb/Downloads/ASAM_App/agent_ops/rules/`
4. **Select these 3 files ONLY:**
   - ✅ `wm_ladder.json`
   - ✅ `loc_indication.guard.json`
   - ✅ `operators.json`
5. In the dialog:
   - ✅ "Copy items if needed" = **UNCHECKED** (files stay in agent_ops)
   - ✅ "Create groups" = **CHECKED** (yellow folder is fine)
   - ✅ "Add to targets" → **"ASAMAssessment"** = **CHECKED**
6. Click **"Add"**

### Step 3: Verify Files Are Bundled

In Project Navigator, you should see:
```
ASAMAssessment
├── ASAMAssessmentApp.swift
├── Services/
│   ├── RulesEngine.swift        ✅
│   ├── RulesService.swift       ✅
│   └── ...
├── wm_ladder.json               ✅ (at root level)
├── loc_indication.guard.json    ✅ (at root level)
└── operators.json               ✅ (at root level)
```

Click each JSON file and verify in the **File Inspector** (right panel):
- ✅ "Target Membership" → "ASAMAssessment" is **CHECKED**

### Step 4: Build and Test

```
Cmd+B  (Build)
→ Should compile successfully
→ No "RulesEngine not found" errors
```

---

## 🔧 **How RulesService Loads Files**

The updated `RulesService.swift` now uses:

```swift
public init(bundle: Bundle = .main,
            wmRulesFile: String = "wm_ladder",
            locRulesFile: String = "loc_indication.guard",
            operatorsFile: String = "operators") throws {
    guard let wmURL = bundle.url(forResource: wmRulesFile, withExtension: "json") else {
        throw RulesServiceError.notFound(URL(fileURLWithPath: wmRulesFile))
    }
    // ... similar for other files
}
```

**Key points:**
- Uses `Bundle.main.url(forResource:withExtension:)` - standard iOS approach
- Files must be added to the app target (bundle membership)
- Defaults to the 3 required files (no need to pass paths)
- Throws proper errors instead of `fatalError` (production-safe)

---

## 📱 **Usage in Your App**

Once the files are bundled, you can use RulesService:

```swift
// In ASAMAssessmentApp.swift or wherever needed
do {
    let rulesService = try RulesService()  // Uses bundled JSON files
    
    // Evaluate WM and LOC
    let result = rulesService.evaluate(
        severities: assessment.domainSeverities(),
        d1Context: assessment.d1Context(),
        flags: assessment.flags()
    )
    
    print("WM: \(result.wm.indication)")
    print("LOC: \(result.loc.recommendation)")
    
} catch {
    print("Failed to initialize rules: \(error)")
}
```

---

## ✅ **Verification Commands**

After adding files, verify they're bundled:

```bash
# Build the app in Xcode, then check the app bundle:
cd ~/Library/Developer/Xcode/DerivedData/ASAMAssessment-*/Build/Products/Debug-iphonesimulator/ASAMAssessment.app

# List bundled JSON files:
ls -la *.json

# Should show:
# wm_ladder.json
# loc_indication.guard.json
# operators.json
```

---

## 🚨 **Common Issues**

### Issue: "Cannot find RulesEngine in scope"
**Cause:** RulesEngine.swift not added to target  
**Fix:** Click RulesEngine.swift → File Inspector → Check "ASAMAssessment" target

### Issue: "Rules file not found: wm_ladder"
**Cause:** JSON files not added to target  
**Fix:** Click each .json file → File Inspector → Check "ASAMAssessment" target

### Issue: "Build succeeds but app crashes at runtime"
**Cause:** Files not actually bundled despite showing target membership  
**Fix:** Clean build folder (Cmd+Shift+K), then rebuild

---

## 📊 **What's Next**

After bundling is complete:

1. **Wire RulesService** to replace LOCService in app
2. **Add Assessment helpers** (domainSeverities, d1Context, flags)
3. **Create XCTests** using the 12 test fixtures
4. **Test on simulator** with real assessments

See `WHATS_MISSING.md` for complete integration steps!

---

**Generated:** 2025-11-09  
**Purpose:** Guide for bundling JSON rules files with iOS app  
**Status:** ⏳ Ready to execute - follow Step 2 above
