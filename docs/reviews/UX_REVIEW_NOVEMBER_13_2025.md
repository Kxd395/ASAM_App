# UX Review - November 13, 2025

**Reviewer**: User Review  
**Date**: November 13, 2025  
**Branch**: dev  
**Status**: Ready for Implementation  
**Priority**: High

---

## Executive Summary

Comprehensive review identifying 15 visual/UX inconsistencies, 7 logic issues, and 8 concrete fixes needed across the iOS app. Issues are categorized by severity and implementation complexity.

---

## 🔴 CRITICAL ISSUES (Fix First)

### 1. Header Text Inconsistency
**Issue**: Several screens say "Severity Rating – Dimension 1" even when in Domain 2, 4, 5, or 6.

**Impact**: User confusion, looks unprofessional  
**Effort**: 2-4 hours  
**Component**: `SeverityRatingView.swift`

**Fix**:
- Replace static "Dimension 1" string with injected title token per screen
- Use either "Dimension X" or "Domain X" consistently throughout app
- Pass dimension number dynamically from parent view

**Acceptance Criteria**:
- D2 shows "Severity Rating – Dimension 2"
- D5 shows "Severity Rating – Dimension 5"
- All 6 dimensions render correct index

**Implementation**:
```swift
// Add to SeverityRatingView init
let dimensionNumber: Int
let dimensionTitle: String

// Header
Text("Severity Rating – Dimension \(dimensionNumber)")
```

---

### 2. D3 Symptom Check Logic (Two Columns)
**Issue**: Currently implemented but need to verify dual-boolean enforcement.

**Impact**: Data integrity  
**Effort**: 2 hours (verification + fixes)  
**Component**: `CategorizedHealthIssuesView.swift`

**Requirements**:
- Each symptom has two booleans: `past30days` and `onlyWhenUsing`
- They are NOT mutually exclusive
- **Rule 1**: If "Only when using…" is checked → auto-check "Past 30 days"
- **Rule 2**: If "Past 30 days" is unchecked → uncheck "Only when using…"

**Current Implementation Status**: ✅ Already implemented in commit fd813ff

**Verification Needed**:
- Test both rules in simulator
- Verify data model persistence
- Check counts only include `past30days` items

---

### 3. Footer Button Inconsistency
**Issue**: Some screens show "Mark Complete," others "Save Changes"

**Impact**: Inconsistent UX  
**Effort**: 2 hours  
**Component**: `DomainView.swift`, `AssessmentView.swift`

**Fix**:
- **Primary action**: "Mark Complete" (for all sections)
- **Secondary action**: "Save" (only in editable dialogs)
- Disable until completion criteria met

**Completion Criteria**:
- All required questions answered OR
- Severity rating selected

**Additional Rules**:
- If severity is 3 or 4 and rationale is blank → show inline error + keep button disabled

**Implementation**:
```swift
var canComplete: Bool {
    return (allRequiredQuestionsAnswered || severityRatingSelected) 
           && !(severityRequiresRationale && rationaleText.isEmpty)
}

Button("Mark Complete") {
    // action
}
.disabled(!canComplete)
```

---

## 🟡 HIGH PRIORITY (This Week)

### 4. Left Rail Truncation and Width
**Issue**: "Assessment Det…" is cut off, rail takes too much space on iPad

**Impact**: Poor iPad UX  
**Effort**: 4-6 hours  
**Component**: `SidebarView.swift`

**Fix Options**:
1. Set narrower fixed width + ellipsis-aware title
2. Provide collapse chevron
3. Domain names and status chips remain visible when collapsed

**Recommended Approach**:
- iPad: 280px width with collapse to 60px (icon-only mode)
- iPhone: Keep current adaptive width
- Add chevron toggle button in header

**Implementation**:
```swift
@State private var sidebarCollapsed = false

var sidebarWidth: CGFloat {
    sidebarCollapsed ? 60 : 280
}

// Collapsed view shows icons + pills
// Expanded shows full names + status
```

---

### 5. Progress vs Counters Mismatch
**Issue**: Bottom progress shows 0% while left rail shows counts like 25, 26, 42

**Impact**: User confusion about completion status  
**Effort**: 2-3 hours  
**Component**: `ProgressView`, `AssessmentViewModel.swift`

**Fix Options**:
1. Define percent as: `answered_required / total_required`
2. State complete when severity chosen → show 100%
3. Show "X of Y answered" instead of percent

**Recommended**: Option 3 - Remove percent bar to avoid false precision

**Implementation**:
```swift
// Replace progress bar with:
Text("\(answeredCount) of \(totalRequired) questions answered")
    .font(.caption)
    .foregroundColor(.secondary)
```

---

### 6. Left Rail Pills and Color Logic
**Issue**: Pill doesn't reflect chosen severity color and number

**Impact**: Missed visual feedback  
**Effort**: 3-4 hours  
**Component**: `SidebarView.swift`, domain status model

**Fix**:
- When severity chosen → set pill background to severity accent color + display numeric level
- When no choice → neutral status with in-progress dot

**Implementation**:
```swift
// Domain status pill
if let severity = domain.severityLevel {
    HStack(spacing: 4) {
        Text("\(severity)")
            .font(.caption.weight(.semibold))
        Image(systemName: "checkmark.circle.fill")
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(domain.severityColor)
    .cornerRadius(12)
} else {
    // In-progress neutral pill
    HStack {
        Circle().fill(.blue).frame(width: 6, height: 6)
        Text("\(domain.answeredCount)")
    }
}
```

---

### 7. Decision Required Badge
**Issue**: "Decision Required" chip appears even after severity is selected

**Impact**: Confusing status indicator  
**Effort**: 1 hour  
**Component**: Status badge logic

**Fix**:
```swift
if !domain.severitySelected && domain.requiresSeverity {
    Text("Decision Required")
        .font(.caption)
        .foregroundColor(.orange)
}
```

---

## 🟢 MEDIUM PRIORITY (Next Week)

### 8. Selected-State Affordance
**Issue**: Blue check glyph position/style inconsistent across D1-D6

**Impact**: Visual inconsistency  
**Effort**: 2 hours  
**Component**: `SeverityCardView.swift`

**Fix**:
- Standardize check icon position (top-right corner)
- Same icon: `checkmark.circle.fill`
- Same background token across all dimensions
- Same animation transition

**Token**:
```swift
// Design tokens
let selectedCheckIcon = "checkmark.circle.fill"
let selectedCheckColor = Color.blue
let selectedCheckSize: CGFloat = 24
let selectedCheckPosition: Alignment = .topTrailing
let selectedCheckPadding: CGFloat = 12
```

---

### 9. Severity Card Shell Drift
**Issue**: D3 alert banner ("If 3 or 4 is selected…") only appears in that domain's Guidance block

**Impact**: Inconsistent safety messaging  
**Effort**: 4-6 hours  
**Component**: Create reusable `SafetyCallout.swift`

**Fix**:
- Create reusable red callout component
- Position above cards for all domains with critical triggers
- Feed from per-domain rules in JSON

**Implementation**:
```swift
struct SafetyCallout: View {
    let message: String
    let severity: SafetyLevel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
    }
}

// Usage in severity view
if let safetyRule = domain.activeSafetyRule {
    SafetyCallout(
        message: safetyRule.message,
        severity: safetyRule.level
    )
}
```

---

### 10. Spacing Debt
**Issue**: Too much vertical gap above first card set and inside cards

**Impact**: Excessive scrolling  
**Effort**: 3-4 hours  
**Component**: Multiple views

**Fix**:
- Reduce section top margins
- Consistent card inner padding: 12px top/bottom, 16px left/right
- Tighten vertical rhythm throughout

**Tokens**:
```swift
// Spacing tokens
let cardPaddingVertical: CGFloat = 12
let cardPaddingHorizontal: CGFloat = 16
let sectionTopMargin: CGFloat = 16 // Reduced from 24
let cardSpacing: CGFloat = 12
```

---

## 🔵 LOW PRIORITY (Nice to Have)

### 11. Terminology Alignment
**Issue**: Mix of "Domain" and "Dimension" terminology

**Impact**: Minor confusion  
**Effort**: 2 hours (search and replace)

**Fix**:
- Choose one term: "Dimension X" (recommended based on clinical literature)
- Update all UI strings
- Update data keys: `dX.*` in schema

---

### 12. D6 Scale Alignment
**Issue**: Top has 1-4 "supportiveness" radio, below has 0-4 severity scale

**Impact**: Potential data mapping confusion  
**Effort**: 2 hours (documentation + validation)

**Fix**:
- Document explicit mapping in spec
- Example: supportiveness 4 → severity hint 0-1
- Example: supportiveness 1 → severity hint 3-4
- **Do NOT auto-select severity from radio** (keep separate)

---

### 13. Safety Banners Logic
**Issue**: D3 banner driven by both answers and severity

**Impact**: Inconsistent triggering  
**Effort**: 3 hours  
**Component**: Safety rule engine

**Recommended Logic**:
- Trigger on: severity ≥3 OR any configured safety checkbox
- Persist until resolved or explicitly dismissed
- Write dismissal flag for export/audit

**Implementation**:
```swift
struct SafetyTrigger {
    let condition: SafetyCondition
    let dismissed: Bool
    let timestamp: Date?
}

enum SafetyCondition {
    case severityThreshold(Int)
    case criticalCheckbox(String)
    case combinedRule([SafetyCondition])
}
```

---

## 📋 Implementation Tickets

### Ticket 1: Fix Header Text Inconsistency
**Priority**: 🔴 Critical  
**Effort**: 2-4 hours  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Add `dimensionNumber` parameter to `SeverityRatingView`
- [ ] Update all call sites to pass correct dimension number
- [ ] Verify D1-D6 show correct titles
- [ ] Update unit tests

**Files to Modify**:
- `ios/ASAMAssessment/ASAMAssessment/Views/SeverityRatingView.swift`
- All domain view controllers calling SeverityRatingView

---

### Ticket 2: Standardize Footer Actions
**Priority**: 🔴 Critical  
**Effort**: 2 hours  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Replace all "Save Changes" with "Mark Complete"
- [ ] Implement completion criteria logic
- [ ] Add severity 3/4 rationale validation
- [ ] Show inline error for missing rationale
- [ ] Disable button until criteria met

**Files to Modify**:
- `DomainView.swift`
- `AssessmentView.swift`
- `SeverityRatingView.swift`

---

### Ticket 3: Verify D3 Dual-Checkbox Logic
**Priority**: 🔴 Critical  
**Effort**: 2 hours  
**Assignee**: iOS Developer + QA

**Tasks**:
- [ ] Test Rule 1: Checking "Only when" auto-checks "Past 30 days"
- [ ] Test Rule 2: Unchecking "Past 30 days" clears "Only when"
- [ ] Verify counts only include `past30days` items
- [ ] Test data persistence across app restart
- [ ] Document any bugs found

**Current Status**: ✅ Implemented in fd813ff, needs verification

---

### Ticket 4: Implement Left Rail Status Pills
**Priority**: 🟡 High  
**Effort**: 3-4 hours  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Create domain status model with severity level
- [ ] Update pill rendering based on severity
- [ ] Apply severity accent color to pill
- [ ] Show numeric level in pill
- [ ] Neutral state for no selection
- [ ] Test across all 6 dimensions

**Files to Modify**:
- `SidebarView.swift`
- `DomainViewModel.swift`

---

### Ticket 5: Fix Progress Display
**Priority**: 🟡 High  
**Effort**: 2-3 hours  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Remove percent bar or fix calculation
- [ ] Show "X of Y answered" format
- [ ] Ensure consistency with left rail counters
- [ ] Update progress calculation logic
- [ ] Test edge cases (0 answered, all answered)

**Files to Modify**:
- `ProgressView.swift`
- `AssessmentViewModel.swift`

---

### Ticket 6: Responsive Left Rail (iPad)
**Priority**: 🟡 High  
**Effort**: 4-6 hours  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Set narrower fixed width for iPad (280px)
- [ ] Add collapse/expand chevron
- [ ] Implement collapsed icon-only mode (60px)
- [ ] Ellipsis-aware titles
- [ ] Persist collapse state
- [ ] Test on iPad sizes

**Files to Modify**:
- `SidebarView.swift`

---

### Ticket 7: Create Reusable Safety Callout
**Priority**: 🟢 Medium  
**Effort**: 4-6 hours  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Create `SafetyCallout.swift` component
- [ ] Position above severity cards
- [ ] Feed from domain safety rules in JSON
- [ ] Implement for D3 and D6
- [ ] Standardize trigger conditions
- [ ] Add dismissal tracking

**Files to Create**:
- `SafetyCallout.swift`

**Files to Modify**:
- `SeverityRatingView.swift`
- Domain JSON files

---

### Ticket 8: Standardize Spacing Tokens
**Priority**: 🟢 Medium  
**Effort**: 3-4 hours  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Define spacing token constants
- [ ] Apply to all severity cards
- [ ] Reduce section top margins
- [ ] Tighten vertical rhythm
- [ ] Test on iPhone and iPad

**Files to Create**:
- `DesignTokens.swift`

**Files to Modify**:
- All view files

---

### Ticket 9: Hide "Decision Required" When Complete
**Priority**: 🟡 High  
**Effort**: 1 hour  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Add conditional logic to badge rendering
- [ ] Hide when severity selected
- [ ] Test across all domains

---

### Ticket 10: Standardize Selected State Affordance
**Priority**: 🟢 Medium  
**Effort**: 2 hours  
**Assignee**: iOS Developer

**Tasks**:
- [ ] Define check icon design tokens
- [ ] Standardize position (top-right)
- [ ] Same icon across all dimensions
- [ ] Same animation transition
- [ ] Test visual consistency

---

## 🎯 Sprint Planning Recommendation

### Sprint 1 (Week 1) - Critical Fixes
- Ticket 1: Fix Header Text (2-4 hours)
- Ticket 2: Standardize Footer Actions (2 hours)
- Ticket 3: Verify D3 Logic (2 hours)
- Ticket 9: Hide Decision Badge (1 hour)

**Total**: ~7-9 hours

### Sprint 2 (Week 2) - High Priority UX
- Ticket 4: Left Rail Pills (3-4 hours)
- Ticket 5: Fix Progress Display (2-3 hours)
- Ticket 6: Responsive Left Rail (4-6 hours)

**Total**: ~9-13 hours

### Sprint 3 (Week 3) - Polish
- Ticket 7: Safety Callout (4-6 hours)
- Ticket 8: Spacing Tokens (3-4 hours)
- Ticket 10: Selected State (2 hours)

**Total**: ~9-12 hours

---

## 📊 Impact Assessment

### User Experience
- **High Impact**: Header text, footer consistency, left rail pills
- **Medium Impact**: Progress display, spacing, safety callouts
- **Low Impact**: Terminology alignment

### Development Effort
- **Quick Wins** (<2 hours): Tickets 1, 2, 9
- **Medium Effort** (2-4 hours): Tickets 3, 4, 5, 8, 10
- **Complex** (4-6 hours): Tickets 6, 7

### Technical Debt
- Spacing tokens will reduce future inconsistencies
- Reusable safety callout benefits all domains
- Design system foundation for future features

---

## 🔗 Related Documentation

- [D3 Dual-Checkbox Implementation](../dev-notes/D3_SEVERITY_RATING_ADDED.md)
- [Severity Implementation Complete](../dev-notes/SEVERITY_IMPLEMENTATION_COMPLETE.md)
- [iOS Quick Reference](../../ios/QUICK_REFERENCE.md)

---

## ✅ Next Steps

1. Review and prioritize tickets with team
2. Assign tickets to sprint 1
3. Create Xcode issues/tasks for tracking
4. Begin implementation with critical fixes
5. Schedule QA review after each sprint

---

**Review Status**: Ready for Implementation  
**Estimated Total Effort**: 25-34 hours  
**Suggested Timeline**: 3 weeks (3 sprints)

---

*Generated from user review on November 13, 2025. All issues documented with concrete acceptance criteria and implementation guidance.*
