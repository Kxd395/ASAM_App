# Dimension 6: Recovery/Living Environment - Audit Checklist

**Date**: November 13, 2025  
**Status**: Ready for Audit  
**Priority**: P2 - Important for LOC Determination

---

## Overview

Dimension 6 assesses the patient's **living situation, social environment, and recovery resources**. This dimension is critical for determining whether patient can safely return to their environment or needs residential placement.

**Key Considerations**:
- Housing stability
- Safety of living environment
- Access to recovery resources
- Social support quality
- Legal/financial stressors

---

## Question-by-Question Audit

### Q1: Current Living Situation (Page 13)

**Question**: "What is your current living situation?"

**Answer Flow**:
- Radio select:
  - Stable housing (own/rent)
  - Living with family/friends
  - Sober living/halfway house
  - Temporary housing (shelter, motel)
  - Homeless (street, car, couch-surfing)
  - Incarcerated/institution
  - Other (free-text, max 500 chars)

**Validation Rules**:
- [ ] **ALWAYS REQUIRED**
- [ ] Character limit on "Other": 500 with counter
- [ ] **NO COUNTER CURRENTLY IMPLEMENTED** - LOG AS ISSUE

**Quick-Add Chips**:
- [ ] "Own apartment, stable"
- [ ] "Living with parents, supportive"
- [ ] "Couch-surfing, unstable"
- [ ] "Homeless, sleeping in car"

**Severity Impact**:
- [ ] Homeless or unstable → **strong indicator for Sev 3-4 (residential)**
  - Rationale: No safe place to discharge to
- [ ] Stable housing → can succeed in lower LOC

**Test Cases**:
```json
// Test: Homeless suggests residential
{
  "d6.livingSituation.type": "homeless",
  "d6.livingSituation.description": "Sleeping in car for past 2 months",
  "expectedSuggestion": 4,
  "expectedFactor": "Homeless - no safe discharge environment, residential provides housing stability"
}

// Test: Stable housing
{
  "d6.livingSituation.type": "stable_housing",
  "expectedSuggestion": 1
}
```

---

### Q2: Safety of Living Environment (Page 13)

**Question**: "Do you feel safe in your current living environment?"

**Answer Flow**:
- 5-point Likert: [Very unsafe → Very safe]
- If "Unsafe" or "Very unsafe":
  - **Reasons**: Multi-select (Domestic violence, Substance use by others, Criminal activity, Lack of security, etc.)
  - Free-text elaboration (max 500 chars)

**Validation Rules**:
- [ ] **ALWAYS REQUIRED**
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] Unsafe reasons: "DV with partner", "Drug dealing in building", "Fear of being robbed"
- [ ] "Safe, no concerns"

**Emergency Logic**:
- [ ] **CRITICAL**: Domestic violence reported → **EMERGENCY BANNER**
  - **Trigger**: `d6.safety.reasons.includes('domestic_violence')`
  - **Banner**: "Patient reports domestic violence. Safety planning and resources required."
  - **Min Severity**: 3 (may need residential for safety)

**Severity Impact**:
- [ ] Very unsafe → suggest Sev 3-4 (need safe environment)

**Test Cases**:
```json
// Test: DV triggers emergency
{
  "d6.safety.rating": "very_unsafe",
  "d6.safety.reasons": ["domestic_violence"],
  "d6.safety.elaboration": "Partner is violent when drunk, afraid to go home",
  "expectedBanner": "d6_domestic_violence",
  "expectedMinSeverity": 3
}

// Test: Safe environment
{
  "d6.safety.rating": "very_safe",
  "expectedSuggestion": 1
}
```

---

### Q3: Social Support Quality (Page 13)

**Question**: "How would you rate the quality of your social relationships?"

**Answer Flow**:
- 5-point Likert: [Very poor → Excellent]
- Free-text: "Who provides support?" (max 500 chars)
- Free-text: "Who is harmful to recovery?" (max 500 chars)

**Validation Rules**:
- [ ] **ALWAYS REQUIRED** (rating)
- [ ] Character limits: 500 with counter on both text fields

**Quick-Add Chips**:
- [ ] Supportive: "Family is very supportive", "Sponsor + recovery friends", "Faith community"
- [ ] Harmful: "All friends are active users", "Toxic relationship with partner", "Enabling family"

**Severity Impact**:
- [ ] "Very poor" + all relationships harmful → suggest Sev 3-4 (need to build new support network)
- [ ] "Excellent" + strong recovery support → can succeed in Sev 1

**Test Cases**:
```json
// Test: Poor support suggests higher LOC
{
  "d6.socialSupport.rating": "very_poor",
  "d6.socialSupport.supportive": "None",
  "d6.socialSupport.harmful": "All my friends use drugs, no sober people in my life",
  "expectedSuggestion": 3,
  "expectedFactor": "No recovery-supportive relationships - need structured peer support"
}

// Test: Excellent support
{
  "d6.socialSupport.rating": "excellent",
  "d6.socialSupport.supportive": "Family, sponsor, recovery friends from meetings",
  "expectedSuggestion": 1
}
```

---

### Q4: Access to Recovery Resources (Page 14)

**Question**: "Do you have access to recovery resources (meetings, treatment, support services)?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Resources Available**: Multi-select (12-step meetings, Treatment centers, Sober living, Transportation, Childcare, etc.)
- If No:
  - **Barriers**: Multi-select (No meetings nearby, No transportation, No childcare, Cost, etc.)
  - Free-text elaboration (max 500 chars)

**Validation Rules**:
- [ ] **ALWAYS REQUIRED**
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] Available: "AA meetings within walking distance", "Clinic has IOP + childcare"
- [ ] Barriers: "Rural area, no meetings within 50mi", "No car, can't get to clinic"

**Severity Impact**:
- [ ] No access + multiple barriers → suggest Sev 3-4 (residential provides all resources)
- [ ] Good access → can succeed in lower LOC

**Test Cases**:
```json
// Test: No access suggests residential
{
  "d6.recoveryResources.value": false,
  "d6.recoveryResources.barriers": ["no_meetings_nearby", "no_transportation", "rural_area"],
  "d6.recoveryResources.elaboration": "Live 75 miles from nearest clinic, no car",
  "expectedSuggestion": 3,
  "expectedFactor": "No access to recovery resources - residential provides integrated support"
}

// Test: Good access
{
  "d6.recoveryResources.value": true,
  "d6.recoveryResources.available": ["meetings", "treatment_centers", "transportation"],
  "expectedSuggestion": 1
}
```

---

### Q5: Employment/School Status (Page 14)

**Question**: "What is your current employment or school status?"

**Answer Flow**:
- Radio select:
  - Employed full-time
  - Employed part-time
  - Unemployed, looking
  - Unemployed, not looking
  - On disability
  - Student (full-time / part-time)
  - Retired
  - Other (free-text)
- If employed/student:
  - **Supportive of Recovery**: Boolean
  - **At Risk of Losing**: Boolean

**Validation Rules**:
- [ ] **ALWAYS REQUIRED**

**Quick-Add Chips**:
- [ ] "Employed FT, boss is supportive"
- [ ] "Unemployed, lost job due to use"
- [ ] "On disability for mental health"
- [ ] "About to lose job if don't get treatment"

**Severity Impact**:
- [ ] "At risk of losing job" → may need IOP (Sev 2) to maintain employment
- [ ] "Unemployed, not looking" + no structure → suggest Sev 3+ for routine

**Test Cases**:
```json
// Test: At risk of job loss
{
  "d6.employment.status": "employed_full_time",
  "d6.employment.supportive": false,
  "d6.employment.atRisk": true,
  "expectedSuggestion": 2,
  "expectedFactor": "At risk of job loss - IOP maintains employment while treating"
}

// Test: Unemployed, no structure
{
  "d6.employment.status": "unemployed_not_looking",
  "expectedSuggestion": 3,
  "expectedFactor": "No daily structure - residential provides routine"
}
```

---

### Q6: Legal Issues (Page 14)

**Question**: "Do you have any current legal issues or pending charges?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Type**: Multi-select (DUI, Drug possession, Probation/parole, Pending trial, Child custody, Other)
  - **Court-Ordered Treatment**: Boolean
  - **Next Court Date**: Date picker (optional)
  - Free-text elaboration (max 500 chars)

**Validation Rules**:
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] "DUI, court-ordered treatment"
- [ ] "Probation for drug possession"
- [ ] "CPS case, need to complete treatment to regain custody"

**Severity Impact**:
- [ ] Court-ordered + probation → may need Sev 3+ for compliance verification
- [ ] Child custody case → may need residential to demonstrate commitment

**Test Cases**:
```json
// Test: CPS case suggests residential
{
  "d6.legalIssues.value": true,
  "d6.legalIssues.type": ["child_custody"],
  "d6.legalIssues.elaboration": "CPS removed kids, need to complete treatment to get them back",
  "expectedSuggestion": 3,
  "expectedFactor": "Child custody case - residential demonstrates commitment + provides structure"
}

// Test: No legal issues
{
  "d6.legalIssues.value": false,
  "expectedSuggestion": 1
}
```

---

### Q7: Financial Stability (Page 14)

**Question**: "How would you rate your current financial stability?"

**Answer Flow**:
- 5-point Likert: [Very unstable → Very stable]
- Free-text: "What are your main financial stressors?" (max 500 chars)

**Validation Rules**:
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] Financial stressors: "Can't afford rent", "Medical debt", "No income", "Child support arrears"

**Severity Impact**:
- [ ] "Very unstable" + housing threatened → suggest Sev 3-4 (residential provides stability while addressing)
- [ ] "Very stable" → can afford lower LOC

**Test Cases**:
```json
// Test: Severe financial stress
{
  "d6.financialStability.rating": "very_unstable",
  "d6.financialStability.stressors": "About to be evicted, no income, $20k in debt",
  "expectedSuggestion": 3,
  "expectedFactor": "Severe financial instability - residential provides stability + case management"
}
```

---

### Q8: Cultural/Language Needs (Page 15)

**Question**: "Do you have any cultural, language, or accessibility needs that should be considered in treatment?"

**Answer Flow**:
- Multi-select:
  - Language barrier (specify language in free-text)
  - Cultural practices to accommodate
  - Religious considerations
  - Disability accommodations
  - LGBTQ+ affirming care
  - Gender-specific programming
  - Other (free-text, max 500 chars)

**Validation Rules**:
- [ ] Optional - blank is valid
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] "Need Spanish-speaking provider"
- [ ] "Muslim - need halal food + prayer space"
- [ ] "Transgender - need gender-affirming care"
- [ ] "Deaf - need ASL interpreter"

**Severity Impact**:
- [ ] Specialized need + not available locally → may need to refer to facility with resources (affects LOC availability, not severity)

**Test Cases**:
```json
// Test: Language barrier documented
{
  "d6.culturalNeeds.selected": ["language_barrier"],
  "d6.culturalNeeds.other": "Primary language is Spanish, limited English proficiency",
  "expectedNote": "Refer to Spanish-speaking program"
}
```

---

### Q9-12: Problem Statements (Page 15)

**Questions**:
- Q9: Recovery environment problems
- Q10: Environmental risks
- Q11: Barriers to recovery in current environment
- Q12: Recommended actions

**Quick-Add Chips**:
- [ ] **Q9**: "Homeless - no safe discharge", "Living with active users", "DV in home - unsafe", "No recovery resources nearby"
- [ ] **Q10**: "Eviction risk - behind on rent", "CPS case - need to demonstrate stability", "All social ties are using friends"
- [ ] **Q11**: "No transportation to clinic", "Rural area - no meetings", "Toxic relationship - can't leave", "No childcare for treatment"
- [ ] **Q12**: "Residential provides housing + safety + resources", "IOP with case management for housing", "Sober living referral", "DV shelter + treatment"

**Validation Rules**:
- [ ] Character limits: 500 with counter on all fields

---

### Severity Rating (Page 15)

**Severity Suggestion Logic**:
```swift
func d6SuggestSeverity(_ state: Assessment) -> (suggested: Int, factors: [String]) {
    var level = 0
    var factors: [String] = []
    
    // Sev 4: Extreme instability (homeless + unsafe + no resources)
    if state.d6.livingSituation == .homeless &&
       state.d6.safety.rating <= .unsafe &&
       !state.d6.recoveryResources {
        level = 4
        factors.append("Homeless, unsafe environment, no recovery resources - residential essential")
    }
    
    // Sev 3: High instability
    if state.d6.livingSituation == .temporary ||
       state.d6.safety.rating == .veryUnsafe ||
       state.d6.socialSupport.rating == .veryPoor ||
       !state.d6.recoveryResources {
        level = max(level, 3)
        factors.append("Unstable housing or unsafe environment - residential provides stability")
    }
    
    // Sev 2: Moderate concerns
    if state.d6.socialSupport.rating <= .fair ||
       state.d6.employment.atRisk ||
       state.d6.financialStability.rating <= .unstable {
        level = max(level, 2)
        factors.append("Environmental stressors - IOP with case management")
    }
    
    // Sev 1: Stable environment
    if state.d6.livingSituation == .stable &&
       state.d6.safety.rating >= .safe &&
       state.d6.recoveryResources {
        level = max(level, 1)
        factors.append("Stable recovery-supportive environment - outpatient appropriate")
    }
    
    return (level, factors)
}
```

**Validation Rules**:
- [ ] Rationale required if Sev 3 or 4

**Quick-Add Rationale Chips**:
- [ ] "Homeless with no safe discharge - residential provides housing stability"
- [ ] "DV in home - need residential for safety + stabilization"
- [ ] "No recovery resources in rural area - residential provides integrated support"
- [ ] "CPS case - residential demonstrates commitment to regain custody"

---

## Emergency Banner Triggers

### Trigger: d6_domestic_violence

**Condition**: `d6.safety.reasons.includes('domestic_violence')`

**Banner Message**: "Patient reports domestic violence. Safety planning and resources required. Consider residential for safe environment."

**Actions**:
- [ ] Min Severity: 3
- [ ] Requires: Safety plan, DV resources, consider protective order
- [ ] Primary Button: "Open DV Safety Protocol"
- [ ] Logs dismissal with safety plan documented

**Test**:
```json
{
  "d6.safety.rating": "very_unsafe",
  "d6.safety.reasons": ["domestic_violence"],
  "expectedBanner": true,
  "expectedMinSeverity": 3,
  "expectedAction": "Safety plan + DV resources"
}
```

---

### Trigger: d6_homelessness

**Condition**: `d6.livingSituation.type == 'homeless'`

**Banner Message**: "Patient is currently homeless. Safe discharge planning required. Residential or sober living strongly recommended."

**Actions**:
- [ ] Min Severity: 3
- [ ] Requires: Housing resources, case management
- [ ] Primary Button: "Housing Resources"

**Test**:
```json
{
  "d6.livingSituation.type": "homeless",
  "expectedBanner": true,
  "expectedMinSeverity": 3
}
```

---

## Fixtures

### Fixture: d6_sev4_homeless_unsafe.json

```json
{
  "id": "test-011",
  "dimension": 6,
  "livingSituation": {
    "type": "homeless",
    "description": "Sleeping in car, no stable housing for 6 months"
  },
  "safety": {
    "rating": "very_unsafe",
    "reasons": ["lack_of_security", "criminal_activity"],
    "elaboration": "Car broken into twice, afraid to sleep at night"
  },
  "socialSupport": {
    "rating": "very_poor",
    "supportive": "",
    "harmful": "All friends are active users, no sober support"
  },
  "recoveryResources": {
    "value": false,
    "barriers": ["no_transportation", "homeless"]
  },
  "employment": {
    "status": "unemployed_not_looking"
  },
  "financialStability": {
    "rating": "very_unstable",
    "stressors": "No income, no housing, no resources"
  },
  "expectedOutcomes": {
    "suggestedSeverity": 4,
    "emergencyBanner": true,
    "factorIncluded": "Homeless, unsafe environment, no recovery resources"
  }
}
```

### Fixture: d6_sev1_stable.json

```json
{
  "id": "test-012",
  "dimension": 6,
  "livingSituation": {
    "type": "stable_housing",
    "description": "Own apartment, lived there 3 years"
  },
  "safety": {
    "rating": "very_safe"
  },
  "socialSupport": {
    "rating": "excellent",
    "supportive": "Family, sponsor, recovery friends from meetings",
    "harmful": "Cut ties with using friends"
  },
  "recoveryResources": {
    "value": true,
    "available": ["meetings", "treatment_centers", "transportation", "sober_living"]
  },
  "employment": {
    "status": "employed_full_time",
    "supportive": true,
    "atRisk": false
  },
  "legalIssues": {
    "value": false
  },
  "financialStability": {
    "rating": "stable"
  },
  "expectedOutcomes": {
    "suggestedSeverity": 1
  }
}
```

---

## Test Execution Checklist

### Unit Tests
- [ ] Homelessness triggers emergency banner
- [ ] DV triggers emergency banner
- [ ] Severity suggestion algorithm
- [ ] Cultural needs documented

### Integration Tests
- [ ] Load homeless fixture → verify Sev 4 + banner
- [ ] Answer Q1-Q8 → verify severity updates
- [ ] Complete dimension → all validations pass

### UI Tests
- [ ] Emergency banners show correctly
- [ ] Quick-add chips populate fields
- [ ] Character counters show at 450/500

---

## Known Issues

1. ❌ **No character counter on free-text fields**
   - **Impact**: High
   - **Fix**: Add `TextAreaLimited` component

2. ❌ **No integrated housing resource database**
   - **Impact**: Medium - clinicians must manually find resources
   - **Fix**: Add housing resource API (Continuum of Care registry)

3. ❌ **DV safety protocol not fully spec'd**
   - **Impact**: High - safety issue
   - **Fix**: Create DV safety planning workflow

---

## Sign-Off

- [ ] All validation rules implemented
- [ ] Emergency triggers tested
- [ ] Housing/safety assessment working
- [ ] All fixtures pass

**Auditor**: ___________________  
**Date**: ___________________  
**Status**: ☐ Pass  ☐ Fail  ☐ Pass with Issues
