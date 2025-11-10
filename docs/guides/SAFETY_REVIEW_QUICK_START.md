# Safety Review Enhancement - Quick Start Guide

**Ready to integrate? Follow these steps →**

---

## ✅ What's Complete

Three new files created and ready to add to Xcode:

1. **SafetyReviewSheet.swift** - Enhanced modal with auto-focus & stable keyboard
2. **AutofocusTextView.swift** - Optional UIKit helper for iPad
3. **SafetyReviewUITests.swift** - Comprehensive UI test suite

ContentView.swift already updated to use new sheet! ✅

---

## ⏳ Next Steps (15 minutes)

### Step 1: Add Files to Xcode Project (5 min)

**App Target:**
```
1. Open ios/ASAMAssessment/ASAMAssessment.xcodeproj
2. Right-click "Views" group → Add Files to "ASAMAssessment"
3. Navigate to:
   - Views/SafetyReviewSheet.swift
   - Views/UIKit/AutofocusTextView.swift
4. Check "ASAMAssessment" target
5. Click Add
```

**UI Tests Target:**
```
1. Right-click "ASAMAssessmentUITests" group
2. Add Files → SafetyReviewUITests.swift
3. Check "ASAMAssessmentUITests" target
4. Click Add
```

### Step 2: Build & Run (5 min)

**Build:**
```bash
cd ios/ASAMAssessment
xcodebuild build \
  -scheme ASAMAssessment \
  -destination 'platform=iOS Simulator,name=iPad Pro (11-inch) (M4)'
```

**Or**: Press Cmd+B in Xcode

### Step 3: Test Manually (5 min)

**Acceptance Checklist:**
- [ ] Launch app (Cmd+R)
- [ ] Create new assessment
- [ ] Safety review appears
- [ ] Sheet has drag indicator at top
- [ ] Tap "Action Taken" → Select any action
- [ ] **Cursor automatically appears in Notes field** ⭐
- [ ] Type some text → Notes field works smoothly
- [ ] Keyboard appears without sheet "jumping" ⭐
- [ ] Drag sheet up/down → Resizes between large/medium ⭐
- [ ] Toggle acknowledgment
- [ ] Tap Continue → Sheet dismisses
- [ ] Check console for audit log

### Step 4: Run UI Tests (Optional)

```bash
xcodebuild test \
  -scheme ASAMAssessmentUITests \
  -destination 'platform=iOS Simulator,name=iPad Pro (11-inch) (M4)'
```

---

## 🎯 Key Behaviors to Verify

### 1. Auto-Focus (Most Important!)
**What to watch**: After selecting an action from picker, cursor should automatically appear in Notes field after ~150ms

**Why it matters**: Main improvement requested in review

### 2. Stable Keyboard
**What to watch**: When keyboard appears, sheet should stay put (not resize/jump)

**Why it matters**: Prevents disorienting animation when typing

### 3. Resizable Sheet
**What to watch**: Drag the indicator at top of sheet up/down

**Why it matters**: Users can size sheet to their preference

---

## 🐛 Troubleshooting

### Notes field doesn't auto-focus on iPad
**Fix**: Edit SafetyReviewSheet.swift line 246, replace `TextEditor` with:
```swift
AutofocusTextView(text: $notes, shouldFocus: actionTaken != nil && notes.isEmpty)
    .frame(minHeight: 120)
    .padding(12)
    .background(.background, in: .rect(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
    .id("notes")
```

### Sheet still jumps with keyboard
**Check**: Make sure these modifiers are present in SafetyReviewSheet:
```swift
.scrollDismissesKeyboard(.interactively)
.ignoresSafeArea(.keyboard, edges: .bottom)
```

### Build errors about AppSettings
**Fix**: Make sure `AppSettings` is available or use `SettingsStore.shared` instead:
```swift
@EnvironmentObject private var settings: SettingsStore
```

---

## 📊 What Changed

### Before (Old SafetyBanner)
- Fixed size sheet
- Manual scrolling to Notes
- No auto-focus
- Sheet jumps when keyboard appears
- No inline validation feedback

### After (New SafetyReviewSheet)
- ✅ Resizable sheet (.large ↔ .medium)
- ✅ Auto-focus on Notes after action selection
- ✅ Stable keyboard (no jumping)
- ✅ Inline validation errors + haptics
- ✅ Full accessibility support
- ✅ Comprehensive UI tests

---

## 📝 Commit When Ready

```bash
git add ios/ASAMAssessment/ASAMAssessment/Views/SafetyReviewSheet.swift
git add ios/ASAMAssessment/ASAMAssessment/Views/UIKit/AutofocusTextView.swift
git add ios/ASAMAssessment/ASAMAssessmentUITests/SafetyReviewUITests.swift
git add ios/ASAMAssessment/ASAMAssessment/Views/ContentView.swift

git commit -m "feat(safety): enhance Safety Review with auto-focus & stable keyboard

- Auto-focus Notes field after action selection (150ms delay)
- Stable sheet presentation (no jumping with keyboard)
- Pullable/resizable sheet (.large ↔ .medium)
- Inline validation with error messages + haptics
- Comprehensive accessibility identifiers
- Optional UIKit AutofocusTextView for iPad reliability
- UI tests for all behaviors"
```

---

## 📚 Full Documentation

For complete technical details, see:
`/docs/guides/SAFETY_REVIEW_ENHANCEMENT_COMPLETE.md`

For original review feedback, see:
`/docs/reviews/settings_Update1.2`

---

## ✨ Success Criteria

You'll know it's working when:
1. ⭐ Selecting action → cursor appears in Notes (no manual tap)
2. ⭐ Keyboard slides up smoothly without sheet jumping
3. ⭐ Sheet can be dragged between sizes
4. ✅ Validation shows inline errors
5. ✅ All UI tests pass

**That's it!** The enhancement significantly improves the most critical workflow in the app. 🎉
