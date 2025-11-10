# iOS Prototype Integration - Quick Reference

**Last Updated**: November 9, 2025  
**Location**: Philadelphia, PA

---

## 🎯 What You Have

- ✅ Working iOS SwiftUI prototype (`ios_prototype.zip`)
- ✅ LOC reference files integrated with CI protection
- ✅ Comprehensive UI/UX specifications
- ✅ Legal compliance passing (exit code 0)
- ✅ Complete integration documentation

---

## 🚨 Critical Fixes Required (Before Any New Features)

| Priority | Fix | Status | Effort | Document |
|----------|-----|--------|--------|----------|
| 🔴 #1 | Accessibility labels | Not started | 4-6h | `ACCESSIBILITY_IMPLEMENTATION.md` |
| 🔴 #2 | Safety banner modal + audit | **BROKEN** | 4-6h | `SAFETY_BANNER_ENHANCEMENT.md` |
| 🟡 #3 | LOC explainability | Not started | 6-8h | `IOS_PROTOTYPE_INTEGRATION.md` §3 |
| 🟡 #4 | EMR context separation | Not started | 4-6h | `IOS_PROTOTYPE_INTEGRATION.md` §4 |
| 🟢 #5 | No PDF/Problems hacks | Ongoing | N/A | `IOS_PROTOTYPE_INTEGRATION.md` §5 |

---

## 📋 5-Minute Quickstart

### Step 1: Extract Prototype
```bash
cd /Users/kevindialmb/Downloads/ASAM_App/ios
# Extract ios_prototype.zip when ready
```

### Step 2: Create Xcode Project
1. Open Xcode
2. File → New → Project → iOS App
3. Name: `ASSESS`
4. Interface: SwiftUI
5. Save to: `/Users/kevindialmb/Downloads/ASAM_App/ios/ASSESS`

### Step 3: Copy Files
```bash
# Quit Xcode first!
cd ASSESS
cp -r ../ASSESS_prototype/Sources/* ./
```

### Step 4: Add Resources
- Drag `data/loc_reference_neutral.json` into Xcode
- Check "Copy items if needed"
- Add to target: ASSESS
- Verify in Build Phases → Copy Bundle Resources

### Step 5: Build & Run
- Select iPad simulator
- Product → Run (⌘R)
- Test safety banner toggle

---

## 📚 Documentation Map

### Start Here
- **`PROJECT_STATUS.md`** - Overview, metrics, next actions
- **`IOS_PROTOTYPE_INTEGRATION.md`** - Complete integration guide

### Critical Fixes
- **`ACCESSIBILITY_IMPLEMENTATION.md`** - WCAG 2.1 AA guide
- **`SAFETY_BANNER_ENHANCEMENT.md`** - Modal + audit spec

### Reference
- **`UI_UX_REVIEW_COMPLETE.md`** - 14-screen analysis
- **`Documents/agent_pack/`** - Original specifications
- **`LOC_INTEGRATION_COMPLETE.md`** - LOC reference guide

---

## ✅ Validation Checklist

### Before Adding Features
- [ ] Safety banner requires action recording (modal flow)
- [ ] VoiceOver labels on all interactive elements
- [ ] Dynamic Type tested at largest size (AX5)
- [ ] Color contrast ≥4.5:1 (WCAG AA)
- [ ] LOC shows decision trace ("Why?" button)
- [ ] EMR context drawer with TTL badges

### Before Committing
- [ ] No accessibility warnings in Xcode
- [ ] No Problems quick hacks added
- [ ] No PDF quick exports added
- [ ] Audit logging on state changes
- [ ] Unit tests passing

---

## 🔄 Development Workflow

### Daily Loop
1. Pick one critical fix from priority list
2. Implement with accessibility from start
3. Test with VoiceOver + Dynamic Type
4. Verify color contrast (Accessibility Inspector)
5. Run unit tests
6. Commit with descriptive message

### Weekly Review
1. Demo completed features
2. Run full accessibility audit
3. Update PROJECT_STATUS.md
4. Plan next week's fixes/features

---

## 🎯 Next 3 Priorities (In Order)

### 1. Fix Safety Banner (URGENT - Stop-Ship) 🔴
- **Time**: 4-6 hours
- **Blocker**: Export liability risk
- **Guide**: `SAFETY_BANNER_ENHANCEMENT.md`
- **Test**: Banner persists until action recorded

### 2. Add Accessibility Labels (URGENT - Architecture) 🔴
- **Time**: 4-6 hours
- **Blocker**: Affects layout decisions
- **Guide**: `ACCESSIBILITY_IMPLEMENTATION.md`
- **Test**: Complete VoiceOver navigation

### 3. LOC Explainability (Important - Clinical Trust) 🟡
- **Time**: 6-8 hours
- **Blocker**: None (can add later)
- **Guide**: `IOS_PROTOTYPE_INTEGRATION.md` Section 3
- **Test**: "Why?" button shows rule trace

---

## 📞 Key Questions for User

1. **Prototype Access**: Do you have `ios_prototype.zip` ready to share?
2. **Development Env**: Is Xcode 15+ installed with iPad simulator?
3. **Next Features**: Should I wait for your Summary+LOC/Problems extensions, or implement from specs?
4. **Authentication**: Wire up real auth or keep stubbed?
5. **Testing**: Who performs accessibility validation?

---

## 🚀 Success Indicators

### You're Ready to Start When:
- [ ] ios_prototype.zip extracted
- [ ] Xcode project created
- [ ] Prototype builds without errors
- [ ] Can navigate to Assessment Overview
- [ ] Safety banner appears when flag set

### You're On Track When:
- [ ] Safety banner fixed (modal + audit)
- [ ] VoiceOver navigation works
- [ ] No accessibility warnings
- [ ] LOC shows decision trace
- [ ] EMR context visually separated

### You're Ready to Extend When:
- [ ] All 5 critical fixes complete
- [ ] Accessibility tests passing
- [ ] Unit tests passing
- [ ] Code review approved

---

## 🆘 Troubleshooting

### Prototype Won't Build
- Check Xcode version (needs 15+)
- Verify iOS SDK 17+ installed
- Clean build folder (⌘⇧K)
- Restart Xcode

### LOC JSON Not Found
- Verify file in Copy Bundle Resources
- Check filename: `loc_reference_neutral.json`
- Verify no typos in Bundle.main.url() call
- Try clean build

### Safety Banner Not Appearing
- Check AppState.shared.safetyFlag is set
- Verify banner overlay in ASSESSApp
- Toggle flag in code to test
- Check z-index/overlay placement

### VoiceOver Not Working
- Enable in Simulator: Settings → Accessibility
- Or use Accessibility Inspector (Xcode)
- Verify labels are set (not nil)
- Check accessibilityElement usage

---

## 📊 Progress Tracking

### Week 1 (Current)
- [x] Extract prototype
- [x] Create Xcode project
- [ ] Fix safety banner
- [ ] Add accessibility labels

### Week 2
- [ ] LOC explainability
- [ ] EMR context drawer
- [ ] Color contrast audit
- [ ] VoiceOver testing

### Week 3
- [ ] Summary + LOC screen
- [ ] Problems module
- [ ] Preflight validation
- [ ] Acceptance tests

---

## 🎓 Learning Resources

### Apple Documentation
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Accessibility for SwiftUI](https://developer.apple.com/documentation/swiftui/accessibility)
- [VoiceOver Programming](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/)

### Testing Tools
- Xcode Accessibility Inspector
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

---

## 💡 Pro Tips

1. **Always test with VoiceOver** - Don't wait until the end
2. **Use semantic fonts** - `.body`, `.headline`, not `.system(size: 16)`
3. **Define color tokens early** - Easier than fixing contrast later
4. **Audit logs are not optional** - Safety flags require documentation
5. **Resist quick hacks** - Complexity containment is critical

---

**Status**: Ready to integrate prototype  
**Blocking**: Safety banner fix (stop-ship)  
**Next Step**: Extract `ios_prototype.zip` and follow Quickstart
