# CRITICAL STATUS - D4 Still Locking + D2/D3 Missing Severity

## Date: November 13, 2025 - UPDATED

## 🚨 USER REPORT

> "everything still locking up on 4 and three is missing the severity rating still the color one we build before"

**Translation**:
1. D4 severity rating STILL locks up when clicking rating 3 or 4
2. D3 is missing the colored severity rating cards entirely

---

## Current Status Summary

### ❌ D4 - STILL BROKEN (Lockup on Rating 3/4)

**Fixes Attempted**:
1. ✅ Re-entrancy guard with `isSaving` flag (Commit 1002443) - **DIDN'T WORK**
2. ✅ Computed property for `showRationaleError` (Commit 338855c) - **DIDN'T WORK**

**Problem**: Despite both fixes, D4 STILL locks up when clicking rating 3 or 4

**Hypothesis**: The issue might not be in `saveAnswer()` at all. Could be:
- The `withAnimation` wrapper causing main thread block
- Parent view (`QuestionnaireRenderer`) has an onChange loop
- SwiftUI re-rendering the entire view tree on state change
- Something specific to rating >= 3 that we haven't identified

### ❌ D3 - MISSING SEVERITY RATING

**Current State**:
- D3 has 34 questions
- Ends with `d3_17_further_notes` (textarea)
- NO `severity_rating` question

**Expected State** (per user):
- Should have colored severity rating cards (like D1, D4, D5)
- User says "the color one we build before" - implies it existed previously

**Evidence It Should Exist**:
- `docs/reviews/settungs_update.md` shows `"pdf_field": "D3.Severity"`
- Field mapping expects D3 to have a severity rating
- ASAM assessment guide mentions D3 severity (0-4 ratings for danger to self/others)

### ❌ D2 - ALSO MISSING SEVERITY RATING

**Current State**:
- D2 has NO `severity_rating` question in any variant
- `settungs_update.md` shows `"pdf_field": "D2.Severity"`

---

## Dimension Severity Rating Status

| Dimension | Severity Rating? | Status | Notes |
|-----------|------------------|--------|-------|
| **D1** | ✅ Yes | ✅ Working | In `d1_withdrawal_enhanced.json` |
| **D2** | ❌ No | 🔴 MISSING | Needs colored cards added |
| **D3** | ❌ No | 🔴 MISSING | User says it existed before |
| **D4** | ✅ Yes | 🔴 LOCKUP | Freezes on rating 3/4 |
| **D5** | ✅ Yes | ⚠️ Untested | Has severity_rating in JSON |
| **D6** | ❓ Unknown | ⚠️ Not checked | - |

---

## Next Debugging Steps for D4 Lockup

### 1. Remove Animation Wrapper (Most Likely Culprit)

The `withAnimation` might be blocking the main thread when combined with state changes:

```swift
// Current (possibly problematic)
Button(action: {
    withAnimation(.easeInOut(duration: 0.2)) {
        selectedRating = card.rating
    }
}) { ... }

// Try this instead
Button(action: {
    selectedRating = card.rating  // Direct assignment, no animation
}) { ... }
```

**Rationale**: When rating >= 3, setting `selectedRating` triggers:
1. Computed property recalculation (`showRationaleError`)
2. View re-render (rationale field appears)
3. `saveAnswer()` in onChange
4. Parent view update

All of this wrapped in an animation might cause a deadlock.

### 2. Add Debug Logging

```swift
.onChange(of: selectedRating) { oldValue, newValue in
    print("🔄 [SeverityRating] selectedRating: \(String(describing: oldValue)) → \(String(describing: newValue))")
    saveAnswer()
    print("✅ [SeverityRating] saveAnswer() completed")
}
```

This will show if:
- onChange is being called multiple times
- saveAnswer() is completing or hanging
- The order of operations

### 3. Check QuestionnaireRenderer

Need to verify that `QuestionnaireRenderer.swift`'s `.onChange(of: answer)` isn't creating a feedback loop:

```swift
// In QuestionnaireRenderer
.onChange(of: answer) { _, _ in
    updateLocalState()  // Does this trigger something that updates answer again?
}
```

### 4. Try Async Save

Move the save operation off the main thread:

```swift
.onChange(of: selectedRating) { oldValue, newValue in
    Task {
        await MainActor.run {
            saveAnswer()
        }
    }
}
```

---

## Adding D3 Severity Rating

### Spec Requirements (from ASAM docs)

D3 severity should assess:
- Danger to self/others
- Ability to care for self
- Psychiatric/cognitive impairment
- Impact on functioning

### Proposed Severity Cards for D3

```json
{
  "id": "d3_18",
  "text": "SEVERITY RATING - DIMENSION 3 (Emotional, Behavioral, or Cognitive Conditions)",
  "type": "severity_rating",
  "required": true,
  "breadcrumb": "d3_severity_rating",
  "helpText": "Please circle the intensity and urgency of the patient's CURRENT needs for services based on the information collected in Dimension 3",
  "severity_rating": {
    "severity_cards": [
      {
        "rating": 0,
        "title": "0 None",
        "color": "#48bb78",
        "border": "#4CAF50",
        "icon": "checkmark.circle",
        "bullets": [
          "No significant emotional, behavioral, or cognitive issues",
          "Stable mental health",
          "Functioning well in daily activities"
        ],
        "disposition": ""
      },
      {
        "rating": 1,
        "title": "1 Mild",
        "color": "#84cc16",
        "border": "#65a30d",
        "icon": "info.circle",
        "bullets": [
          "Mild symptoms that don't significantly impair functioning",
          "Can manage daily activities with minimal support",
          "Low risk to self or others"
        ],
        "disposition": "Low intensity outpatient mental health services"
      },
      {
        "rating": 2,
        "title": "2 Moderate",
        "color": "#facc15",
        "border": "#eab308",
        "icon": "exclamationmark.triangle",
        "bullets": [
          "Moderate symptoms affecting functioning",
          "Needs regular support for daily activities",
          "Some risk management needed"
        ],
        "disposition": "Moderate intensity mental health services with regular monitoring"
      },
      {
        "rating": 3,
        "title": "3 Severe",
        "color": "#fb923c",
        "border": "#f97316",
        "icon": "exclamationmark.triangle.fill",
        "bullets": [
          "Severe symptoms significantly impairing functioning",
          "Difficulty with self-care or safety",
          "Moderate risk to self or others",
          "Significant distress or disability"
        ],
        "disposition": "High intensity mental health services with close monitoring and safety planning"
      },
      {
        "rating": 4,
        "title": "4 Very Severe",
        "color": "#ef4444",
        "border": "#dc2626",
        "icon": "xmark.circle.fill",
        "bullets": [
          "Imminent danger to self or others",
          "Unable to care for self",
          "Severe psychiatric crisis",
          "Requires immediate intervention"
        ],
        "disposition": "Crisis intervention or psychiatric hospitalization required"
      }
    ],
    "substance_options": [],
    "safety_rules": [
      {
        "condition": "rating >= 3",
        "severity": "critical",
        "message": "If 3 or 4 is selected, consider higher level of mental health care and implement safety protocols"
      }
    ]
  }
}
```

---

## Timeline of Fixes

| Commit | Fix Attempted | Result |
|--------|---------------|--------|
| d402845 | REVERT isLoadingInitialData | ✅ Restored D3 clickability |
| 1002443 | Re-entrancy guard (`isSaving`) | ❌ D4 still locks |
| f16166a | Fix type errors (SeverityCardData) | ✅ Build succeeds |
| 338855c | Computed property (`showRationaleError`) | ❌ D4 still locks |

---

## User Impact

**Cannot Complete Assessment**:
- D4 blocks at severity rating (can't click 3 or 4)
- D3 has no way to enter severity rating
- Cannot generate proper LOC recommendation without all severity ratings

**Workaround**: None available - these are blocking issues

---

## Recommended Action Plan

### Immediate (Fix D4 Lockup)

1. **Try removing withAnimation** - Most likely cause
2. **Add debug logging** - See what's actually happening  
3. **Test on simulator** - Reproduce the lockup
4. **Check parent view** - QuestionnaireRenderer onChange loop?

### High Priority (Add D3 Severity)

1. Add the severity_rating question to d3_emotional_neutral.json
2. Verify it renders correctly
3. Test that it doesn't have the same lockup issue as D4

### Medium Priority (Add D2 Severity)

1. Define appropriate severity cards for biomedical domain
2. Add to d2 JSON
3. Test

---

## Questions for User

1. **D4 Lockup**: Can you click ratings 0, 1, or 2 successfully? Or do ALL ratings lock up?
2. **D3 Missing**: Do you remember when D3 had severity cards? Was it in a previous version?
3. **Testing**: Are you testing on simulator or physical device?
4. **Console**: Do you see any error messages or console output when it locks up?

---

## Build Status

✅ **BUILD SUCCEEDED** (as of 338855c)  
⚠️ **RUNTIME BROKEN** (D4 lockup persists)  
🔴 **FUNCTIONALITY MISSING** (D2/D3 severity ratings)

