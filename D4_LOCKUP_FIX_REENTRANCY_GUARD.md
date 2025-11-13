# D4 Severity Rating Lockup Fix - Re-entrancy Guard

## Date: 2025-11-13

## Problem
When clicking severity rating 3 or higher on Dimension 4, the app locks up (UI freezes). This is caused by an infinite loop in the `saveAnswer()` function triggered by cascading `onChange` handlers.

## Root Cause Analysis

### The Loop Flow:
1. User clicks rating 3 button → `selectedRating = 3`
2. `.onChange(of: selectedRating)` fires → calls `saveAnswer()`
3. `saveAnswer()` sets `answer = .text(jsonString)` (updates the `@Binding`)
4. QuestionnaireRenderer's `.onChange(of: answer)` fires → calls `updateLocalState()`
5. Setting `showRationaleError = true` (for rating >= 3) causes view re-render
6. **The re-render can trigger `saveAnswer()` again → infinite loop**

### Why Rating >= 3 is Affected:
- Ratings 0-2: No `showRationaleError` state change, no loop
- Ratings 3-4: `showRationaleError = true` triggers additional state changes and view re-renders
- This amplifies the onChange cascade

## Solution: Re-entrancy Guard

Added a simple boolean flag `@State private var isSaving: Bool = false` to prevent `saveAnswer()` from being called while it's already executing.

### Code Changes:

**File:** `ios/ASAMAssessment/ASAMAssessment/Views/SeverityRatingView.swift`

1. Added state variable:
```swift
@State private var isSaving: Bool = false  // Prevent save loops
```

2. Updated `saveAnswer()` function:
```swift
private func saveAnswer() {
    // Prevent re-entrant saves that could cause loops
    guard !isSaving else { return }
    isSaving = true
    defer { isSaving = false }
    
    var result: [String: Any] = [:]
    // ... rest of function unchanged
}
```

### How It Works:
- **guard !isSaving else { return }**: If `saveAnswer()` is called while already running, exit immediately
- **isSaving = true**: Set flag at the start of function
- **defer { isSaving = false }**: Guarantee flag is reset even if function throws error
- This breaks the infinite loop by preventing re-entrant calls

## Testing Required

1. **D4 Severity Rating**: Test clicking rating 3 (Severe) and 4 (Very Severe)
   - Should NOT lock up
   - Should display rationale field correctly
   - Should save answer properly

2. **D1 Severity Rating**: Verify not broken (uses same component)
3. **D2 Severity Rating**: Verify not broken (uses same component)
4. **D3**: Verify still works (doesn't use severity rating)

## Status

- ✅ Code changes applied
- ❌ Build currently fails due to **pre-existing** compile errors (not related to this fix)
- ⏳ Awaiting user testing after build issues are resolved

## Notes

- This is a **defensive fix** that prevents symptom (infinite loop) without changing the fundamental architecture
- A more comprehensive fix would refactor the onChange cascade pattern
- The `defer` statement ensures the flag is always reset, preventing deadlock if an error occurs

## Previous Failed Attempt

- Commit a77f1c1: Tried `isLoadingInitialData` flag approach
- **FAILED**: Broke D3 completely (nothing clickable)
- Commit d402845: Reverted that approach
- **Lesson**: Guarding onChange handlers during load is too broad - breaks unrelated functionality

## This Approach vs. Previous

| Aspect | Previous (isLoadingInitialData) | Current (isSaving) |
|--------|--------------------------------|-------------------|
| Scope | Disabled ALL onChange handlers during load | Only prevents re-entrant saveAnswer() calls |
| Impact | Broke D3 completely | Targeted to D4 rating >= 3 issue |
| Timing | Load-time guard | Runtime guard |
| Safety | Too broad - prevented legitimate updates | Precise - only blocks recursive calls |
