# Dimension 4: Readiness to Change - Audit Checklist

**Date**: November 13, 2025  
**Status**: Ready for Audit  
**Priority**: P2 - Important for Treatment Planning

---

## Overview

Dimension 4 assesses the patient's motivation, readiness, and resistance to change. This dimension uses **Stages of Change model** (Precontemplation → Contemplation → Preparation → Action → Maintenance) to determine treatment approach.

**Key Concepts**:
- Internal vs external motivation
- Ambivalence about change
- Past treatment experiences
- Current barriers to engagement

---

## Question-by-Question Audit

### Q1: Recognition of Problem (Page 9)

**Question**: "Do you think you have a problem with substance use or mental health?"

**Answer Flow**:
- 5-point Likert: [Not at all | A little | Somewhat | Quite a bit | Definitely]
- Free-text elaboration (max 500 chars, optional)

**Validation Rules**:
- [ ] Character limit: 500 with counter at 450
- [ ] **NO COUNTER CURRENTLY IMPLEMENTED** - LOG AS ISSUE

**Quick-Add Chips**:
- [ ] "Yes, it's affecting my life"
- [ ] "Others think I do, but I'm not sure"
- [ ] "No, I'm here because of [legal/family/work]"

**Stage of Change Mapping**:
- "Not at all" → Precontemplation
- "A little" / "Somewhat" → Contemplation
- "Quite a bit" / "Definitely" → Preparation or Action

**Test Cases**:
```json
// Test: Denial indicates Precontemplation
{
  "d4.problemRecognition.rating": "not_at_all",
  "d4.problemRecognition.elaboration": "I'm only here because court mandated it",
  "expectedStage": "precontemplation"
}

// Test: Acceptance indicates Preparation
{
  "d4.problemRecognition.rating": "definitely",
  "d4.problemRecognition.elaboration": "I know I need help, ready to change",
  "expectedStage": "preparation"
}
```

---

### Q2: Desire to Change (Page 9)

**Question**: "How much do you want to change your substance use or mental health situation?"

**Answer Flow**:
- 10-point scale (0 = No desire, 10 = Very strong desire)
- Slider with anchor labels

**Validation Rules**:
- [ ] **ALWAYS REQUIRED** - default to 5

**Quick-Add Chips**:
- [ ] "Very ready (8-10)"
- [ ] "Somewhat ready (5-7)"
- [ ] "Not ready (0-4)"

**Stage of Change Mapping**:
- 0-3 → Precontemplation
- 4-6 → Contemplation
- 7-10 → Preparation/Action

**Test Cases**:
```json
// Test: High desire
{
  "d4.desireToChange.value": 9,
  "expectedStage": "preparation"
}

// Test: Low desire
{
  "d4.desireToChange.value": 2,
  "expectedStage": "precontemplation"
}
```

---

### Q3: Confidence in Ability to Change (Page 9)

**Question**: "How confident are you that you can make this change?"

**Answer Flow**:
- 10-point scale (0 = No confidence, 10 = Very confident)
- Slider with anchor labels

**Validation Rules**:
- [ ] **ALWAYS REQUIRED** - default to 5

**Quick-Add Chips**:
- [ ] "Very confident (8-10)"
- [ ] "Somewhat confident (5-7)"
- [ ] "Not confident (0-4)"

**Severity Impact**:
- [ ] Low confidence (0-3) → may need higher structure (Sev 3+)
- [ ] High desire + low confidence = good candidate for motivational interviewing

**Test Cases**:
```json
// Test: High desire, low confidence (ambivalence)
{
  "d4.desireToChange.value": 8,
  "d4.confidenceInChange.value": 3,
  "expectedSuggestion": "Motivational interviewing to address ambivalence",
  "expectedStage": "contemplation"
}
```

---

### Q4: Past Treatment Episodes (Page 9)

**Question**: "Have you participated in substance use or mental health treatment before?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Number of Episodes**: Number field
  - **Most Recent**: Date picker
  - **Type**: Multi-select (Inpatient, IOP, Outpatient, MAT, etc.)
  - **Completed**: Boolean
  - **Length of Sobriety After**: Duration (years/months)
  - **Relapse Reason**: Free-text (max 500 chars)

**Validation Rules**:
- [ ] Most recent date cannot be future
- [ ] Character limit on relapse reason: 500 with counter

**Quick-Add Chips**:
- [ ] Treatment Type: "30-day inpatient", "IOP 3mo", "MAT ongoing"
- [ ] Relapse Reason: "Lost housing", "Job stress", "Stopped meds", "Lost support"

**Test Cases**:
```json
// Test: Multiple failed attempts suggest need for higher LOC
{
  "d4.pastTreatment.value": true,
  "d4.pastTreatment.count": 3,
  "d4.pastTreatment.mostRecent": "2025-08-15",
  "d4.pastTreatment.type": ["inpatient"],
  "d4.pastTreatment.completed": false,
  "d4.pastTreatment.longestSobriety": { "years": 0, "months": 2 },
  "d4.pastTreatment.relapseReason": "Left AMA due to anxiety, used within a week",
  "expectedSuggestion": 3,
  "expectedFactor": "Multiple treatment episodes with early dropout - need higher structure"
}
```

---

### Q5: Current Motivation Source (Page 10)

**Question**: "What is motivating you to seek treatment now?"

**Answer Flow**:
- Multi-select:
  - **Internal**: "I want to feel better", "Health concerns", "Want to be better parent", "Lost too much"
  - **External**: "Court-ordered", "Family pressure", "Employer requirement", "CPS involvement"
  - **Other**: Free-text (max 500 chars)

**Validation Rules**:
- [ ] At least 1 selection required
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] Internal: "Want to be there for my kids", "Scared of dying"
- [ ] External: "Court says I have to", "Family gave ultimatum"

**Severity Impact**:
- [ ] All external motivation + low desire (Q2 ≤3) → may need Sev 3+ for structure
- [ ] Internal motivation + high desire → can succeed in lower LOC

**Test Cases**:
```json
// Test: All external motivation
{
  "d4.motivation.selected": ["court_ordered", "family_pressure"],
  "d4.desireToChange.value": 2,
  "expectedSuggestion": 3,
  "expectedFactor": "External motivation only with low internal desire - need structured environment"
}

// Test: Strong internal motivation
{
  "d4.motivation.selected": ["health_concerns", "better_parent"],
  "d4.desireToChange.value": 9,
  "expectedSuggestion": 1,
  "expectedFactor": "Strong internal motivation - good candidate for outpatient"
}
```

---

### Q6: Barriers to Treatment Engagement (Page 10)

**Question**: "What might make it difficult for you to participate in treatment?"

**Answer Flow**:
- Multi-select:
  - **Practical**: Transportation, Childcare, Work schedule, Cost/insurance
  - **Personal**: "Don't think I need it", "Don't trust providers", "Fear of judgment", "Privacy concerns"
  - **Other**: Free-text (max 500 chars)

**Validation Rules**:
- [ ] Optional - blank is valid
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] "No car, clinic is 20mi away"
- [ ] "Work nights, can't make day appointments"
- [ ] "Don't want family to know"
- [ ] "Tried before, didn't work"

**Severity Impact**:
- [ ] Multiple practical barriers + low confidence → may need residential (Sev 3-4) to remove barriers

**Test Cases**:
```json
// Test: Multiple barriers
{
  "d4.barriers.selected": ["transportation", "childcare", "work_schedule"],
  "d4.confidenceInChange.value": 3,
  "expectedSuggestion": 3,
  "expectedFactor": "Multiple practical barriers - residential may remove obstacles"
}
```

---

### Q7: Support System (Page 10)

**Question**: "Do you have people who support your recovery?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Who**: Multi-select (Family, Friends, Sponsor, Faith community, etc.)
  - **Quality of Support**: 5-point Likert (Very poor → Excellent)
  - Free-text elaboration (max 500 chars)

**Validation Rules**:
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] "Family is very supportive"
- [ ] "Sponsor from AA, 2 years sober"
- [ ] "No one really understands"

**Severity Impact**:
- [ ] No support → may need Sev 3+ for peer/staff support
- [ ] Strong support → can succeed in lower LOC

**Test Cases**:
```json
// Test: No support
{
  "d4.support.value": false,
  "expectedSuggestion": 3,
  "expectedFactor": "Lack of recovery support - need structured environment with peer support"
}

// Test: Strong support
{
  "d4.support.value": true,
  "d4.support.who": ["family", "sponsor"],
  "d4.support.quality": "excellent",
  "expectedSuggestion": 1,
  "expectedFactor": "Strong recovery support system in place"
}
```

---

### Q8-11: Problem Statements (Page 10)

**Questions**:
- Q8: Readiness problems affecting well-being
- Q9: Motivation risks or ambivalence
- Q10: Barriers to engagement
- Q11: Recommended actions

**Quick-Add Chips**:
- [ ] **Q8**: "Precontemplation stage - denies problem", "Ambivalent about change", "Court-ordered, low internal motivation"
- [ ] **Q9**: "May leave AMA if feels forced", "History of early dropout", "Low confidence despite high desire"
- [ ] **Q10**: "Transportation barrier - clinic 30mi away", "Childcare needed for 3 kids", "Work schedule conflicts with IOP hours"
- [ ] **Q11**: "Motivational interviewing to build readiness", "Address practical barriers (transport vouchers)", "Residential to remove obstacles + build motivation"

---

### Severity Rating (Page 10)

**Severity Suggestion Logic**:
```swift
func d4SuggestSeverity(_ state: Assessment) -> (suggested: Int, factors: [String]) {
    var level = 0
    var factors: [String] = []
    
    // Sev 4: Extreme resistance, high risk of AMA
    if state.d4.stage == .precontemplation && 
       state.d4.pastTreatment.countAMA >= 2 &&
       state.d4.externalMotivationOnly {
        level = 4
        factors.append("Precontemplation stage with AMA history - need high structure")
    }
    
    // Sev 3: Low readiness, multiple barriers, no support
    if state.d4.desireToChange <= 3 || 
       (state.d4.barriers.count >= 3 && !state.d4.support) {
        level = max(level, 3)
        factors.append("Low readiness or multiple barriers - need residential to engage")
    }
    
    // Sev 2: Contemplation stage, some barriers
    if state.d4.stage == .contemplation || state.d4.barriers.count > 0 {
        level = max(level, 2)
        factors.append("Contemplation stage - need structured IOP with MI")
    }
    
    // Sev 1: Preparation/Action stage, strong motivation
    if state.d4.stage >= .preparation && state.d4.desireToChange >= 7 {
        level = max(level, 1)
        factors.append("Ready for action - good candidate for outpatient")
    }
    
    return (level, factors)
}
```

**Validation Rules**:
- [ ] Rationale required if Sev 3 or 4

**Quick-Add Rationale Chips**:
- [ ] "Precontemplation + court-ordered - need residential for engagement"
- [ ] "High ambivalence + multiple barriers - IOP to address both"
- [ ] "Multiple failed attempts - need higher LOC for structure"

---

## Fixtures

### Fixture: d4_sev3_precontemplation.json

```json
{
  "id": "test-007",
  "dimension": 4,
  "problemRecognition": {
    "rating": "not_at_all",
    "elaboration": "I don't have a problem, court made me come"
  },
  "desireToChange": {
    "value": 2
  },
  "confidenceInChange": {
    "value": 4
  },
  "motivation": {
    "selected": ["court_ordered"]
  },
  "support": {
    "value": false
  },
  "expectedOutcomes": {
    "suggestedSeverity": 3,
    "stage": "precontemplation",
    "factorIncluded": "External motivation only with low internal desire"
  }
}
```

### Fixture: d4_sev1_action.json

```json
{
  "id": "test-008",
  "dimension": 4,
  "problemRecognition": {
    "rating": "definitely",
    "elaboration": "I know I need to change, ready to do the work"
  },
  "desireToChange": {
    "value": 9
  },
  "confidenceInChange": {
    "value": 7
  },
  "motivation": {
    "selected": ["health_concerns", "better_parent"]
  },
  "support": {
    "value": true,
    "who": ["family", "sponsor"],
    "quality": "excellent"
  },
  "expectedOutcomes": {
    "suggestedSeverity": 1,
    "stage": "action"
  }
}
```

---

## Test Execution Checklist

### Unit Tests
- [ ] Stage of Change calculation
- [ ] Severity suggestion algorithm
- [ ] Barrier count logic
- [ ] Support quality impact

### Integration Tests
- [ ] Load fixture → verify stage calculated
- [ ] Answer Q1-Q7 → verify severity suggestion updates

### UI Tests
- [ ] Slider controls work smoothly
- [ ] Quick-add chips populate correctly
- [ ] Character counters show at 450/500

---

## Known Issues

1. ❌ **No character counter on free-text fields**
   - **Impact**: Medium
   - **Fix**: Add `TextAreaLimited` component

2. ❌ **Stage of Change not displayed to user**
   - **Impact**: Medium - useful for clinician
   - **Fix**: Add badge showing calculated stage

---

## Sign-Off

- [ ] All validation rules implemented
- [ ] Stage calculation working
- [ ] Severity logic tested
- [ ] All fixtures pass

**Auditor**: ___________________  
**Date**: ___________________  
**Status**: ☐ Pass  ☐ Fail  ☐ Pass with Issues
