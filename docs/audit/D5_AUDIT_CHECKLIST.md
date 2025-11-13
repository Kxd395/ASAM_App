# Dimension 5: Relapse/Continued Use/Continued Problem Potential - Audit Checklist

**Date**: November 13, 2025  
**Status**: Ready for Audit  
**Priority**: P2 - Important for LOC Determination

---

## Overview

Dimension 5 assesses **relapse risk** by examining triggers, coping skills, past relapse patterns, and environmental risks. This dimension heavily influences whether patient needs higher structure (residential) vs lower (outpatient).

**Key Risk Factors**:
- High-risk environment (people/places/things)
- Poor coping skills
- History of rapid relapse
- Lack of abstinence skills

---

## Question-by-Question Audit

### Q1: Known Triggers (Page 11)

**Question**: "What situations, people, or feelings trigger your substance use or mental health symptoms?"

**Answer Flow**:
- Multi-select from categorized list:
  - **People**: "Being with using friends", "Conflict with family", "Isolation/loneliness"
  - **Places**: "Bars/clubs", "Old neighborhood", "Home alone", "Work stress"
  - **Feelings**: "Anxiety", "Depression", "Anger", "Boredom", "Shame"
  - **Other**: Free-text (max 500 chars)

**Validation Rules**:
- [ ] At least 1 selection OR free-text required
- [ ] Character limit: 500 with counter
- [ ] **NO COUNTER CURRENTLY IMPLEMENTED** - LOG AS ISSUE

**Quick-Add Chips**:
- [ ] Combo triggers: "Stress + isolation → drink at home alone"
- [ ] "Payday triggers binge"
- [ ] "Arguments with partner → use to cope"

**Severity Impact**:
- [ ] Multiple triggers (≥5) + poor coping (Q3) → suggest Sev 3+ for skill-building

**Test Cases**:
```json
// Test: Multiple triggers
{
  "d5.triggers.selected": ["using_friends", "home_alone", "anxiety", "boredom", "payday"],
  "d5.triggers.other": "Also triggered by driving past old dealer's house",
  "expectedSuggestion": 2,
  "expectedFactor": "Multiple triggers identified - need coping skill development"
}
```

---

### Q2: High-Risk Environment (Page 11)

**Question**: "Do you live or spend time in environments where substances are easily available or people are using?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Living Situation**: Multi-select (Lives with active user, Dealer in building, Substance use common in home, etc.)
  - **Ability to Avoid**: 5-point Likert (Cannot avoid → Can easily avoid)
  - Free-text elaboration (max 500 chars)

**Validation Rules**:
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] "Roommate uses daily"
- [ ] "Dealer lives downstairs"
- [ ] "Whole neighborhood is using"
- [ ] "Can't move out right now"

**Severity Impact**:
- [ ] High-risk environment + cannot avoid → **strong indicator for Sev 3-4 (residential)**
  - Rationale: Need to remove from environment to stabilize

**Test Cases**:
```json
// Test: High-risk environment suggests residential
{
  "d5.highRiskEnv.value": true,
  "d5.highRiskEnv.livingSituation": ["lives_with_active_user", "substances_in_home"],
  "d5.highRiskEnv.abilityToAvoid": "cannot_avoid",
  "expectedSuggestion": 3,
  "expectedFactor": "High-risk environment patient cannot avoid - residential removes exposure"
}

// Test: Can avoid high-risk
{
  "d5.highRiskEnv.value": true,
  "d5.highRiskEnv.abilityToAvoid": "can_easily_avoid",
  "expectedSuggestion": 1
}
```

---

### Q3: Coping Skills (Page 11)

**Question**: "What skills or strategies do you use to cope with stress or cravings?"

**Answer Flow**:
- Multi-select from skill categories:
  - **Healthy**: Exercise, Meditation, Talk to support person, Attend meetings, Creative outlet
  - **Unhealthy**: Use substances, Isolation, Self-harm, Avoidance
  - **None**: "I don't have coping skills"
  - **Other**: Free-text (max 500 chars)

**Validation Rules**:
- [ ] At least 1 selection OR free-text required
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] Healthy: "Call sponsor when craving", "Go for a run", "Deep breathing"
- [ ] Unhealthy: "Use to cope", "Isolate in room"

**Severity Impact**:
- [ ] No healthy coping skills → suggest Sev 3+ for skill-building (DBT, CBT)
- [ ] Relies on substance use to cope → high relapse risk

**Test Cases**:
```json
// Test: No healthy coping
{
  "d5.copingSkills.selected": ["use_substances", "isolation"],
  "d5.copingSkills.healthyCount": 0,
  "expectedSuggestion": 3,
  "expectedFactor": "Lacks healthy coping skills - need intensive skill-building (IOP or residential)"
}

// Test: Strong healthy coping
{
  "d5.copingSkills.selected": ["exercise", "talk_to_support", "attend_meetings"],
  "expectedSuggestion": 1
}
```

---

### Q4: Past Relapse Patterns (Page 11)

**Question**: "After periods of abstinence or stability, how quickly do you typically relapse or return to problematic use?"

**Answer Flow**:
- Radio:
  - "Within days"
  - "Within weeks"
  - "Within months"
  - "After 6+ months"
  - "Have maintained long-term abstinence"
  - "N/A - first treatment"

**Validation Rules**:
- [ ] **ALWAYS REQUIRED** - default to "N/A" if Q4 (D4) pastTreatment = false

**Quick-Add Chips**:
- [ ] "Always relapse within first week"
- [ ] "Usually make it 2-3 months"
- [ ] "Once stable, can maintain"

**Severity Impact**:
- [ ] "Within days" → **strong indicator for Sev 3-4** (need extended stabilization)
- [ ] "Within weeks" → suggest Sev 2-3 (IOP)
- [ ] "6+ months" or "long-term" → can succeed in Sev 1 (outpatient)

**Test Cases**:
```json
// Test: Rapid relapse suggests high LOC
{
  "d5.relapsePattern.value": "within_days",
  "expectedSuggestion": 4,
  "expectedFactor": "History of rapid relapse - need extended residential stabilization"
}

// Test: Long-term stability
{
  "d5.relapsePattern.value": "long_term_abstinence",
  "expectedSuggestion": 1
}
```

---

### Q5: Longest Period of Abstinence (Page 12)

**Question**: "What is the longest period you've maintained abstinence or stability?"

**Answer Flow**:
- Duration field: Years and Months
- Free-text: "What helped you maintain it?" (max 500 chars)

**Validation Rules**:
- [ ] Duration cannot be negative
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] Duration shortcuts: "< 1 month", "1-6 months", "6-12 months", "1+ year"
- [ ] What helped: "Residential program + aftercare", "Sponsor + meetings", "Removed from environment"

**Severity Impact**:
- [ ] Never maintained >30 days → suggest Sev 3+ for structure
- [ ] 6+ months with support → can succeed in lower LOC

**Test Cases**:
```json
// Test: Never maintained stability
{
  "d5.longestAbstinence.years": 0,
  "d5.longestAbstinence.months": 0,
  "expectedSuggestion": 3,
  "expectedFactor": "Never achieved sustained abstinence - need structured environment"
}

// Test: Long abstinence
{
  "d5.longestAbstinence.years": 2,
  "d5.longestAbstinence.months": 0,
  "d5.longestAbstinence.whatHelped": "Residential + 12-step meetings + sponsor",
  "expectedSuggestion": 1
}
```

---

### Q6: Ability to Recognize Early Warning Signs (Page 12)

**Question**: "Can you recognize the early warning signs that you're headed toward relapse or crisis?"

**Answer Flow**:
- 5-point Likert: [Not at all → Very well]
- If "Somewhat" or better, free-text: "What are the warning signs?" (max 500 chars)

**Validation Rules**:
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] Warning signs: "Start isolating", "Stop going to meetings", "Romanticizing past use", "Irritability increases"

**Severity Impact**:
- [ ] "Not at all" + poor coping → suggest Sev 3+ for psychoeducation
- [ ] "Very well" + good coping → can succeed in lower LOC

**Test Cases**:
```json
// Test: Cannot recognize warning signs
{
  "d5.warningSigns.recognition": "not_at_all",
  "d5.copingSkills.healthyCount": 0,
  "expectedSuggestion": 3,
  "expectedFactor": "Cannot identify relapse warning signs - need skill-building"
}

// Test: Strong self-awareness
{
  "d5.warningSigns.recognition": "very_well",
  "d5.warningSigns.signs": "I know when I start isolating, skip meetings, or feel irritable that I'm at risk",
  "expectedSuggestion": 1
}
```

---

### Q7: Recovery Support Participation (Page 12)

**Question**: "Are you currently participating in recovery support (AA, NA, SMART Recovery, etc.)?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Type**: Multi-select (12-step, SMART, Faith-based, Peer support, etc.)
  - **Frequency**: Dropdown (Daily, Few times/week, Weekly, Monthly)
  - **Sponsor/Mentor**: Boolean
  - **Engaged**: Boolean (actively participating vs just attending)

**Validation Rules**:
- [ ] Optional - valid to answer "No"

**Quick-Add Chips**:
- [ ] "AA daily + sponsor"
- [ ] "SMART weekly, very helpful"
- [ ] "Used to go, stopped attending"

**Severity Impact**:
- [ ] No recovery support + poor coping → suggest Sev 3+ (need structured peer support)
- [ ] Active participation → can succeed in lower LOC

**Test Cases**:
```json
// Test: No recovery support
{
  "d5.recoverySupport.value": false,
  "d5.copingSkills.healthyCount": 0,
  "expectedSuggestion": 3,
  "expectedFactor": "No recovery support system - need structured environment with peer support"
}

// Test: Active engagement
{
  "d5.recoverySupport.value": true,
  "d5.recoverySupport.type": ["12_step"],
  "d5.recoverySupport.frequency": "daily",
  "d5.recoverySupport.sponsor": true,
  "d5.recoverySupport.engaged": true,
  "expectedSuggestion": 1
}
```

---

### Q8-11: Problem Statements (Page 12)

**Questions**:
- Q8: Relapse/continued use problems
- Q9: Environmental or skill risks
- Q10: Barriers to maintaining abstinence
- Q11: Recommended actions

**Quick-Add Chips**:
- [ ] **Q8**: "High-risk environment - dealer in building", "Rapid relapse pattern within days", "No abstinence skills"
- [ ] **Q9**: "Lives with active user - cannot avoid", "Multiple triggers, poor coping", "History of AMA within week"
- [ ] **Q10**: "Can't afford to move", "No access to meetings", "Isolation - no support system"
- [ ] **Q11**: "Residential to remove from environment", "IOP with DBT for skill-building", "Structured aftercare with sober living"

---

### Severity Rating (Page 12)

**Severity Suggestion Logic**:
```swift
func d5SuggestSeverity(_ state: Assessment) -> (suggested: Int, factors: [String]) {
    var level = 0
    var factors: [String] = []
    
    // Sev 4: Extreme relapse risk
    if state.d5.highRiskEnv.cannotAvoid && 
       state.d5.relapsePattern == .withinDays &&
       state.d5.copingSkills.healthyCount == 0 {
        level = 4
        factors.append("High-risk environment, rapid relapse pattern, no coping skills - need extended residential")
    }
    
    // Sev 3: High relapse risk
    if state.d5.highRiskEnv.cannotAvoid || 
       state.d5.relapsePattern == .withinWeeks ||
       state.d5.longestAbstinence < 30.days {
        level = max(level, 3)
        factors.append("High relapse risk - need residential or intensive IOP")
    }
    
    // Sev 2: Moderate relapse risk
    if state.d5.triggers.count >= 3 || 
       state.d5.copingSkills.healthyCount < 2 ||
       state.d5.warningSigns.recognition <= .somewhat {
        level = max(level, 2)
        factors.append("Moderate relapse risk - need IOP for skill-building")
    }
    
    // Sev 1: Low relapse risk
    if state.d5.longestAbstinence >= 6.months &&
       state.d5.copingSkills.healthyCount >= 3 &&
       state.d5.recoverySupport.engaged {
        level = max(level, 1)
        factors.append("Stable recovery skills and support - outpatient appropriate")
    }
    
    return (level, factors)
}
```

**Validation Rules**:
- [ ] Rationale required if Sev 3 or 4

**Quick-Add Rationale Chips**:
- [ ] "High-risk environment patient cannot avoid - residential removes exposure"
- [ ] "Rapid relapse within days of abstinence - need extended stabilization"
- [ ] "No healthy coping skills + multiple triggers - intensive skill-building needed"

---

## Fixtures

### Fixture: d5_sev4_extreme_risk.json

```json
{
  "id": "test-009",
  "dimension": 5,
  "highRiskEnv": {
    "value": true,
    "livingSituation": ["lives_with_active_user", "substances_in_home"],
    "abilityToAvoid": "cannot_avoid"
  },
  "relapsePattern": {
    "value": "within_days"
  },
  "copingSkills": {
    "selected": ["use_substances", "isolation"],
    "healthyCount": 0
  },
  "longestAbstinence": {
    "years": 0,
    "months": 0
  },
  "expectedOutcomes": {
    "suggestedSeverity": 4,
    "factorIncluded": "High-risk environment, rapid relapse pattern, no coping skills"
  }
}
```

### Fixture: d5_sev1_stable.json

```json
{
  "id": "test-010",
  "dimension": 5,
  "highRiskEnv": {
    "value": false
  },
  "copingSkills": {
    "selected": ["exercise", "talk_to_support", "attend_meetings", "meditation"],
    "healthyCount": 4
  },
  "relapsePattern": {
    "value": "long_term_abstinence"
  },
  "longestAbstinence": {
    "years": 2,
    "months": 6,
    "whatHelped": "Residential + aftercare + sponsor"
  },
  "warningSigns": {
    "recognition": "very_well",
    "signs": "I know when I start isolating or skip meetings"
  },
  "recoverySupport": {
    "value": true,
    "type": ["12_step"],
    "frequency": "daily",
    "sponsor": true,
    "engaged": true
  },
  "expectedOutcomes": {
    "suggestedSeverity": 1
  }
}
```

---

## Test Execution Checklist

### Unit Tests
- [ ] High-risk environment logic
- [ ] Relapse pattern severity mapping
- [ ] Coping skill counting
- [ ] Severity suggestion algorithm

### Integration Tests
- [ ] Load extreme risk fixture → verify Sev 4 suggestion
- [ ] Answer Q1-Q7 → verify severity updates dynamically

### UI Tests
- [ ] Multi-select triggers work
- [ ] Likert scales render correctly
- [ ] Quick-add chips populate fields

---

## Known Issues

1. ❌ **No character counter on free-text fields**
   - **Impact**: Medium
   - **Fix**: Add `TextAreaLimited` component

2. ❌ **Relapse pattern not auto-populated from D4 past treatment**
   - **Impact**: Low - data consistency issue
   - **Fix**: Auto-sync with D4.pastTreatment.longestSobriety

---

## Sign-Off

- [ ] All validation rules implemented
- [ ] Severity logic tested
- [ ] Environment risk assessment working
- [ ] All fixtures pass

**Auditor**: ___________________  
**Date**: ___________________  
**Status**: ☐ Pass  ☐ Fail  ☐ Pass with Issues
