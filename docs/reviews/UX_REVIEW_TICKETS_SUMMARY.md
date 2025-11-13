# UX Review - Quick Ticket Summary

**Date**: November 13, 2025  
**Total Tickets**: 10  
**Estimated Effort**: 25-34 hours  
**Timeline**: 3 weeks (3 sprints)

---

## 🔴 CRITICAL (Sprint 1 - Week 1)

| # | Ticket | Effort | Component | Status |
|---|--------|--------|-----------|--------|
| 1 | Fix header text inconsistency | 2-4h | SeverityRatingView | 🔲 To Do |
| 2 | Standardize footer actions | 2h | DomainView, AssessmentView | 🔲 To Do |
| 3 | Verify D3 dual-checkbox logic | 2h | CategorizedHealthIssuesView | 🔲 To Do |
| 9 | Hide "Decision Required" badge | 1h | Status badges | 🔲 To Do |

**Sprint 1 Total**: 7-9 hours

---

## 🟡 HIGH PRIORITY (Sprint 2 - Week 2)

| # | Ticket | Effort | Component | Status |
|---|--------|--------|-----------|--------|
| 4 | Left rail status pills | 3-4h | SidebarView | 🔲 To Do |
| 5 | Fix progress display | 2-3h | ProgressView | 🔲 To Do |
| 6 | Responsive left rail (iPad) | 4-6h | SidebarView | 🔲 To Do |

**Sprint 2 Total**: 9-13 hours

---

## 🟢 MEDIUM PRIORITY (Sprint 3 - Week 3)

| # | Ticket | Effort | Component | Status |
|---|--------|--------|-----------|--------|
| 7 | Reusable safety callout | 4-6h | New component | 🔲 To Do |
| 8 | Standardize spacing tokens | 3-4h | Design system | 🔲 To Do |
| 10 | Selected state affordance | 2h | SeverityCardView | 🔲 To Do |

**Sprint 3 Total**: 9-12 hours

---

## 📋 Quick Fix Checklist

### Ticket 1: Header Text
```swift
// Add to SeverityRatingView init
let dimensionNumber: Int

// Header
Text("Severity Rating – Dimension \(dimensionNumber)")
```

### Ticket 2: Footer
```swift
var canComplete: Bool {
    return (allRequiredQuestionsAnswered || severityRatingSelected) 
           && !(severityRequiresRationale && rationaleText.isEmpty)
}

Button("Mark Complete") { }
    .disabled(!canComplete)
```

### Ticket 3: D3 Logic
- ✅ Already implemented (commit fd813ff)
- **Action**: Test and verify only

### Ticket 4: Status Pills
```swift
if let severity = domain.severityLevel {
    HStack {
        Text("\(severity)")
        Image(systemName: "checkmark.circle.fill")
    }
    .background(domain.severityColor)
} else {
    // Neutral in-progress pill
}
```

### Ticket 5: Progress
```swift
// Replace progress bar with:
Text("\(answeredCount) of \(totalRequired) questions answered")
```

### Ticket 9: Decision Badge
```swift
if !domain.severitySelected && domain.requiresSeverity {
    Text("Decision Required")
}
```

---

## 🎯 Priority Order (If Time-Constrained)

1. **Ticket 1** - Headers (most visible bug)
2. **Ticket 2** - Footer consistency (UX confusion)
3. **Ticket 9** - Decision badge (quick win)
4. **Ticket 4** - Status pills (visual feedback)
5. **Ticket 5** - Progress display (clarity)
6. **Ticket 3** - D3 verification (data integrity)
7. **Ticket 6** - iPad layout (platform support)
8. **Ticket 8** - Spacing (polish)
9. **Ticket 10** - Selected state (consistency)
10. **Ticket 7** - Safety callout (reusable component)

---

## 📊 Effort Breakdown

- **Quick Wins** (≤2h): Tickets 1, 2, 9 = ~5-7 hours
- **Medium** (2-4h): Tickets 3, 4, 5, 8, 10 = ~12-17 hours
- **Complex** (4-6h): Tickets 6, 7 = ~8-12 hours

**Total**: 25-34 hours

---

## ✅ Definition of Done

Each ticket is complete when:
- [ ] Code changes committed
- [ ] Build succeeds with no warnings
- [ ] Manual testing on iPhone and iPad
- [ ] Screenshots captured for documentation
- [ ] Ticket moved to "Done" column

---

## 🔗 Full Documentation

See [UX_REVIEW_NOVEMBER_13_2025.md](UX_REVIEW_NOVEMBER_13_2025.md) for:
- Detailed acceptance criteria
- Code implementation examples
- Component specifications
- Design tokens
- Related documentation links

---

**Next Action**: Review with team and assign Sprint 1 tickets
