# D4 Lockup Investigation - November 13, 2025

## User Report
- D4 **still locking up** after my fixes
- D3 severity rating "missing" (but D3 never had one - user may be confused)
- Concerned about losing progress

## What I Changed (Commits Today)

### Commit df1053e - ImpactGridView Fixes
- Removed Binding wrapper in QuestionnaireRenderer for ImpactGridView
- Changed TextField to use `onCommit` instead of saving on every keystroke
- **Status**: Should have fixed lockup on impact grid selections

### Commit e36bab7 - Compile Errors
- Added type-converting Binding for ImpactGridView (AnswerValue → AnswerValue?)
- Fixed Swift 6 concurrency in TokenProvider
- **Status**: Fixed compile errors

### Commit a77f1c1 - Severity Rating onChange Guard
- Added `isLoadingInitialData` flag to SeverityRatingView
- Guarded all onChange handlers to prevent cascade during load
- **Status**: Should have fixed severity rating lockup

## Current Hypothesis

The lockup is **STILL HAPPENING** which means my fixes didn't work. Possible causes:

### 1. The Binding Wrapper IS the Problem (Again)
In commit e36bab7, I added a Binding wrapper for ImpactGridView:
```swift
answer: Binding(
    get: { 
        if case .none = answer {
            return nil
        }
        return answer
    },
    set: { newValue in
        if let newValue = newValue {
            answer = newValue
        } else {
            answer = .none
        }
    }
)
```

**Problem**: This might STILL cause a loop because:
- ImpactGridView calls saveAnswer()
- Sets binding (calls `set` closure)
- Updates `answer`
- QuestionnaireRenderer has `.onChange(of: answer)`
- Might trigger re-render
- **Loop?**

### 2. The Severity Rating Fix Didn't Work
My `isLoadingInitialData` flag might not be preventing the issue because:
- `DispatchQueue.main.async` runs AFTER loadExistingAnswer
- But if loadExistingAnswer doesn't set any values (empty answer), the onChange handlers never fire during load anyway
- So the flag doesn't help
- The REAL issue might be when user CLICKS a rating card
- THAT triggers onChange
- Which calls saveAnswer
- Which updates answer binding
- Which might cause loop in parent

### 3. It's Not the Views - It's the Store
Looking at the logs:
```
💾 Saving answers for Domain 4
📊 Answer count changed: 20 → 20 (Δ0)
⚠️ Failed to calculate severity for Domain 4: configurationNotFound
💾 Persisting 10 assessments
```

The app is trying to calculate severity and failing. Maybe the "lockup" is actually the app trying to process something in AssessmentStore?

### 4. It's a Rendering Issue
The logs show many `DomainNavigationRow rendering` messages. Maybe the lockup is actually just slow rendering of a complex view?

## What I Need to Check

1. **Does D4 lockup happen immediately or after an action?**
   - On scroll to severity rating? (my hypothesis)
   - On clicking a rating card?
   - On clicking the impact grid?
   - On page load?

2. **What does "lockup" mean exactly?**
   - App frozen completely?
   - Spinning wheel?
   - Just slow/laggy?
   - Eventually recovers?

3. **D3 Severity Rating**
   - D3 JSON never had severity_rating
   - User might be thinking of D2 or D4
   - Need to clarify which dimension they mean

## Next Steps (DO NOT IMPLEMENT YET)

1. **Revert the Binding wrapper** - Go back to direct `$answer` for ImpactGridView
   - The type mismatch might be better solved differently
   
2. **Add more logging** - Instrument SeverityRatingView to see when it's called
   
3. **Check AssessmentStore** - See if there's a loop in the store updates

4. **Test incrementally** - Don't change multiple things at once

## Questions for User

1. When exactly does the lockup happen? (Immediate on opening D4? After clicking something? When scrolling?)
2. Which dimension are you looking for the severity rating in? (D1, D2, D3, D4?)
3. Does the app eventually recover, or do you have to force quit?
4. Are you able to answer the first few D4 questions before it locks up?

---

**Status**: INVESTIGATING - No changes made yet
**Priority**: CRITICAL
**Date**: November 13, 2025 12:00 PM
