# Dimension 1: Acute Intoxication/Withdrawal - Audit Checklist

**Date**: November 13, 2025  
**Status**: Ready for Audit  
**Priority**: P0 - Critical Safety Domain

---

## Overview

Dimension 1 assesses acute intoxication and withdrawal potential across all substance classes. This is the highest-risk domain for medical emergencies and requires strict validation and emergency protocols.

**Critical Safety Concerns**:
- Severe alcohol/benzo withdrawal can be fatal
- Opioid withdrawal timing affects medical intervention
- Poly-substance use complicates risk assessment

---

## Question-by-Question Audit

### Q1: Substance Use Grid (Pages 1-2)

**Question**: "Have you used any of the following substances?"

**Answer Flow**:
1. For each substance, patient responds Yes/No
2. If Yes, show nested fields:
   - **Duration**: Years and Months number fields
   - **Route**: Multi-select (Oral, Smoked, Injected, etc.)
   - **Frequency**: Dropdown (Daily, 4-6 days/week, 1-3 days/week, etc.)
   - **Last Use**: Date picker
   - **Prescription Valid**: Boolean (only for Rx Opioids, Benzos, Stimulants)

**Validation Rules**:
- [ ] **CRITICAL**: Route cannot be selected when frequency = "Never used"
  - **Test**: Select route → set frequency to "Never" → route should clear + show error
  - **Rule**: `mutualExclusion(["d1.substances[*].frequency:never", "d1.substances[*].routes[*]"])`

- [ ] Duration must be ≤ patient age
  - **Test**: Set duration = 50 years for 30-year-old patient → show error
  
- [ ] Last use date cannot be future
  - **Test**: Set last use = tomorrow → show error
  
- [ ] Last use date must be ≤ duration
  - **Test**: Duration = 2 years, last use = 5 years ago → show error

**Quick-Add Chips**:
- [ ] Route chips populate both substance + route
  - **Chips**: "Smoked heroin", "Injected cocaine", "Oral prescription opioid"
  - **Test**: Tap "Smoked heroin" → heroin selected, route = Smoked, duration = 1 month

- [ ] Last use shortcuts
  - **Chips**: "Today", "Yesterday", "2 days ago", "Last week"
  - **Test**: Tap "Today" → date set to current date

**Prefill from EMR**:
- [ ] Pull `substanceUseHistory` from EHR (if ≤60 days old)
- [ ] Match by RxNorm substance name
- [ ] Show badge: "From chart, 43d"
- [ ] Show conflict chip if user value differs

**Data Issues**:
- [ ] **CRITICAL**: "Other" text fields lack normalization
  - **Problem**: "Molly", "MDMA", "ecstasy" stored as 3 separate substances
  - **Fix**: Add autocomplete with RxNorm lookup
  
- [ ] Prescription validity requires PDMP integration (not yet spec'd)
  - **Action**: Log as future enhancement

**Test Cases**:
```json
// Test: Route blocked when "Never used"
{
  "d1.substances.alcohol.frequency": "never",
  "d1.substances.alcohol.routes": [] // Should be empty, UI disabled
}

// Test: Valid daily heroin use
{
  "d1.substances.heroin.frequency": "daily",
  "d1.substances.heroin.routes": ["smoked", "injected"],
  "d1.substances.heroin.duration": { "years": 3, "months": 2 },
  "d1.substances.heroin.lastUse": "2025-11-12"
}
```

---

### Q2: Withdrawal Symptom Bother (Page 3)

**Question**: "How much have withdrawal symptoms bothered you?"

**Answer Flow**:
- 5-point Likert: [Not at all | A little | Somewhat | Quite a bit | Extremely]
- If rating ≥ "Somewhat", show free-text description (max 500 chars)

**Validation Rules**:
- [ ] **CRITICAL**: Hidden if ALL substances in Q1 = "Never used"
  - **Test**: Set all Q1 to "Never" → Q2 should not be visible
  - **Rule**: `visibleIf("d1.q2", when: "d1.substances[*].frequency != 'never'")`

- [ ] Description required if rating ≥ "Somewhat"
- [ ] Character limit: 500 with counter at 450

**Quick-Add Chips**:
- [ ] Common symptoms: "Body aches", "Nausea", "Anxiety", "Sweating", "Tremor", "Insomnia"
- [ ] Tap chip → add to description with timestamp: "Body aches (reported today)"

**Test Cases**:
```json
// Test: Q2 hidden when no use
{
  "d1.substances.alcohol.frequency": "never",
  "d1.substances.heroin.frequency": "never",
  "d1.q2.visible": false
}

// Test: Description required
{
  "d1.q2.rating": "extremely",
  "d1.q2.description": "" // ERROR: Description required
}
```

---

### Q3: Current Withdrawal Symptoms (Page 3)

**Question**: "Are you experiencing withdrawal symptoms right now?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - Multi-select symptom checklist (grouped by substance)
  - Free-text description (max 500 chars)

**Validation Rules**:
- [ ] **CRITICAL**: Required if last use ≤7 days (opioids) or ≤14 days (alcohol/benzos)
  - **Test**: Opioid last use = 3 days ago → Q3 must be answered
  - **Rule**: `required("d1.currentWithdrawal.value", when: "d1.substances[opioid|alcohol|benzo].lastUse <= P14D")`

- [ ] Shown only if Q2 rating ≥ "A little" OR any substance frequency ≥ "1-3 days/week"

**Quick-Add Chips by Substance**:
- [ ] **Opioids**: "Yawning", "Lacrimation", "Rhinorrhea", "Muscle aches", "Dilated pupils"
- [ ] **Alcohol**: "Tremor", "Seizure", "Delirium", "Hallucinations", "Autonomic instability"
- [ ] **Benzos**: "Anxiety", "Seizure", "Insomnia", "Tremor", "Confusion"
- [ ] Selecting chip adds symptom and auto-tags substance source

**Emergency Logic**:
- [ ] **CRITICAL**: Current withdrawal + last use ≤48h = emergency banner
  - **Trigger**: `d1.currentWithdrawal.value == true && d1.usedLast48h.value == true`
  - **Banner**: "Patient experiencing active withdrawal with recent use. Immediate medical evaluation required."
  - **Min Severity**: 3

**Test Cases**:
```json
// Test: Emergency trigger
{
  "d1.currentWithdrawal.value": true,
  "d1.currentWithdrawal.symptoms": ["tremor", "sweating"],
  "d1.usedLast48h.value": true,
  "expectedBanner": "d1_severe_withdrawal",
  "expectedMinSeverity": 3
}

// Test: Required when recent opioid use
{
  "d1.substances.heroin.lastUse": "2025-11-10", // 3 days ago
  "d1.currentWithdrawal.value": null, // ERROR: Required
  "validationError": "Current withdrawal status required for recent opioid use"
}
```

---

### Q4: Tolerance (Page 3)

**Question**: "Have you developed tolerance to any substances?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes, free-text description (max 500 chars)

**Validation Rules**:
- [ ] Hidden if ALL Q1 = "Never used"
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] "Need more to get same effect"
- [ ] "Using larger amounts"
- [ ] "Using more frequently"

**Test Cases**:
```json
// Test: Quick-add chip
{
  "d1.tolerance.value": true,
  "d1.tolerance.description": "Need more to get same effect (reported today)"
}
```

---

### Q5: Serious Withdrawal History (Page 3)

**Question**: "Have you experienced serious withdrawal complications (DTs, seizures, etc.)?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - Multi-select substances (from Q1)
  - Date picker for last episode

**Validation Rules**:
- [ ] **CRITICAL**: Required if Q1 includes alcohol/benzos/opioids with frequency ≥ "1-3 days/week"
  - **Rule**: Not currently enforced - LOG AS ISSUE

**Quick-Add Chips**:
- [ ] Date shortcuts: "Within past month", "1-6 months ago", ">6 months ago"

**Severity Impact**:
- [ ] History of DTs or seizures → suggest Sev 3+ with current use

**Test Cases**:
```json
// Test: Required for heavy alcohol use
{
  "d1.substances.alcohol.frequency": "daily",
  "d1.seriousWithdrawal.value": null, // ERROR: Required
  "validationError": "Serious withdrawal history required for daily alcohol use"
}
```

---

### Q6: Overdose History (Page 3)

**Question**: "Have you ever overdosed?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - Multi-select substances
  - Date picker for last overdose
  - Boolean: `naloxoneAccess` (if opioids involved)

**Validation Rules**:
- [ ] Naloxone question hidden unless opioids selected
  - **Rule**: `visibleIf("d1.overdose.naloxoneAccess", when: "d1.overdose.substances.includes('opioid')")`

**Quick-Add Chips**:
- [ ] Date shortcuts as above
- [ ] **Naloxone chip**: "Naloxone on hand" → sets naloxoneAccess = true + adds note "Patient equipped"

**Test Cases**:
```json
// Test: Naloxone shown for opioids only
{
  "d1.overdose.value": true,
  "d1.overdose.substances": ["heroin"],
  "d1.overdose.naloxoneAccess": true
}

// Test: Naloxone hidden for non-opioids
{
  "d1.overdose.value": true,
  "d1.overdose.substances": ["alcohol"],
  "d1.overdose.naloxoneAccessVisible": false
}
```

---

### Q7: Used in Last 48 Hours (Page 3)

**Question**: "Have you used any substances in the last 48 hours?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes, multi-select substances

**Validation Rules**:
- [ ] **CRITICAL**: TTL expires after 48 hours from `recordedAt`
  - **Test**: Answer recorded at T0 → at T0+49h, show banner "Data stale – please re-ask"
  - **Rule**: `ttl("d1.usedLast48h", seconds: 48*3600)`
  - **UI**: Strike through answer, show refresh icon

**Emergency Logic**:
- [ ] Used in last 48h + current withdrawal = emergency banner (see Q3)

**Test Cases**:
```json
// Test: TTL expiration
{
  "d1.usedLast48h.value": true,
  "d1.usedLast48h.recordedAt": "2025-11-11T10:00:00Z",
  "currentTime": "2025-11-13T11:00:00Z", // 49 hours later
  "expectedBanner": "Data stale – please re-ask",
  "expectedStrikethrough": true
}
```

---

### Q8: Interviewer Observation (Page 3)

**Question**: "Interviewer assessment of intoxication or withdrawal"

**Answer Flow**:
- Radio: [Intoxication | Withdrawal | None]
- If Intoxication or Withdrawal, free-text description

**Validation Rules**:
- [ ] **ALWAYS REQUIRED** - defaults to "None"
- [ ] Character limit: 500 with counter

**Quick-Add Chips**:
- [ ] **Intoxication signs**: "Slurred speech", "Ataxia", "Disinhibition", "Nystagmus"
- [ ] **Withdrawal signs**: "Tremor", "Agitation", "Seizure", "Autonomic instability"

**Test Cases**:
```json
// Test: Default value
{
  "d1.observation.value": "none" // Auto-set on load
}

// Test: Quick-add chip
{
  "d1.observation.value": "intoxication",
  "d1.observation.description": "Slurred speech, Ataxia (observed Nov 13 4:30pm)"
}
```

---

### Q9-12: Problem Statements (Page 4)

**Questions**:
- Q9: Problems affecting patient well-being
- Q10: Withdrawal risks or complications
- Q11: Barriers to treatment or change
- Q12: Recommended actions/referrals

**Answer Flow**:
- Free-text, optional
- Max 500 characters each

**Quick-Add Chips**:
- [ ] **Q9**: "Overdose risk with fentanyl", "Using alone", "Poly-substance use"
- [ ] **Q10**: "Previous DTs", "Seizure history", "Medical complications"
- [ ] **Q11**: "No access to meds", "Transportation barrier", "Housing instability"
- [ ] **Q12**: "Enroll in OTP", "Get naloxone", "Medical detox referral"

**Validation Rules**:
- [ ] Character limit: 500 with counter at 450
- [ ] **NO COUNTER CURRENTLY IMPLEMENTED** - LOG AS ISSUE

---

### Severity Rating (Page 4)

**Answer Flow**:
1. Clinician reviews all answers
2. System suggests severity (0-4) based on:
   - Withdrawal risk
   - Current withdrawal symptoms
   - Recent use + withdrawal
   - Overdose history
   - Tolerance
3. Clinician selects severity card (0-4)
4. If Sev 3 or 4, **rationale required** (500 chars)

**Severity Suggestion Logic**:
```swift
func d1SuggestSeverity(_ state: Assessment) -> (suggested: Int, factors: [String]) {
    var level = 0
    var factors: [String] = []
    
    // Sev 4: Emergency withdrawal
    if state.d1.currentWithdrawal && state.d1.usedLast48h {
        level = 4
        factors.append("Active withdrawal with recent use")
    }
    
    // Sev 3-4: History of severe withdrawal + current use
    if state.d1.seriousWithdrawal && anyDailyUse {
        level = max(level, 3)
        factors.append("History of DTs/seizures + current daily use")
    }
    
    // Sev 2-3: Daily use, tolerance
    if anyDailyUse && state.d1.tolerance {
        level = max(level, 2)
        factors.append("Daily use with tolerance")
    }
    
    // Sev 1: Occasional use, no complications
    if anyUse && level == 0 {
        level = 1
        factors.append("Recent substance use reported")
    }
    
    return (level, factors)
}
```

**Validation Rules**:
- [ ] Rationale required if Sev 3 or 4
- [ ] **Emergency banner** if Sev 4 factors present (auto-shows before selection)
- [ ] Min severity raised by emergency triggers (cannot select < 3 if emergency active)

**Quick-Add Rationale Chips**:
- [ ] "Severe alcohol withdrawal risk per CIWA-Ar > 15"
- [ ] "Opioid withdrawal, no access to MOUD"
- [ ] "Poly-substance use with recent overdose"
- [ ] "DT history with current daily drinking"

**Test Cases**:
```json
// Test: Emergency auto-suggests Sev 4
{
  "d1.currentWithdrawal.value": true,
  "d1.usedLast48h.value": true,
  "expectedSuggestion": 4,
  "expectedFactors": ["Active withdrawal with recent use"],
  "expectedBanner": "d1_severe_withdrawal"
}

// Test: Rationale required for Sev 3
{
  "d1.severity.chosen": 3,
  "d1.severity.rationale": "", // ERROR: Required
  "validationError": "Rationale required for severity 3 or 4"
}
```

---

## Emergency Banner Triggers

### Trigger: d1_severe_withdrawal

**Condition**: `d1.currentWithdrawal.value == true && d1.usedLast48h.value == true`

**Banner Message**: "Patient experiencing active withdrawal with recent use. Immediate medical evaluation required."

**Actions**:
- [ ] Min Severity: 3
- [ ] Requires Reportable: No (clinical judgment)
- [ ] Primary Button: "Open Safety Protocol"
- [ ] Logs dismissal: user ID + timestamp

**Test**:
```json
{
  "d1.currentWithdrawal.value": true,
  "d1.currentWithdrawal.symptoms": ["tremor", "sweating", "anxiety"],
  "d1.usedLast48h.value": true,
  "d1.usedLast48h.substances": ["alcohol"],
  "expectedBanner": true,
  "expectedMinSeverity": 3
}
```

---

## Data Model

```swift
struct D1Assessment {
    // Q1: Substance Grid
    var substances: [SubstanceUse]
    
    // Q2: Withdrawal Bother
    var withdrawalBother: WithdrawalBother?
    
    // Q3: Current Withdrawal
    var currentWithdrawal: CurrentWithdrawal?
    
    // Q4: Tolerance
    var tolerance: Tolerance?
    
    // Q5: Serious Withdrawal
    var seriousWithdrawal: SeriousWithdrawal?
    
    // Q6: Overdose
    var overdose: Overdose?
    
    // Q7: Used Last 48h
    var usedLast48h: UsedLast48h?
    
    // Q8: Observation
    var observation: Observation
    
    // Q9-12: Problem Statements
    var wellBeingProblems: String?
    var withdrawalRisks: String?
    var barriers: String?
    var recommendations: String?
    
    // Severity
    var severity: DomainSeverity
}

struct SubstanceUse {
    let substance: String
    var duration: Duration
    var routes: [Route]
    var frequency: Frequency
    var lastUse: Date?
    var prescriptionValid: Bool? // Only for Rx substances
}

struct WithdrawalBother {
    var rating: LikertScale // 1-5
    var description: String?
}

struct CurrentWithdrawal {
    var value: Bool
    var symptoms: [String]
    var description: String?
}
```

---

## Fixtures

### Fixture: d1_sev4_withdrawal.json

```json
{
  "id": "test-001",
  "dimension": 1,
  "substances": [
    {
      "substance": "alcohol",
      "frequency": "daily",
      "routes": ["oral"],
      "duration": { "years": 5, "months": 0 },
      "lastUse": "2025-11-12"
    }
  ],
  "withdrawalBother": {
    "rating": "extremely",
    "description": "Severe shaking, sweating, anxiety - can't sleep"
  },
  "currentWithdrawal": {
    "value": true,
    "symptoms": ["tremor", "sweating", "anxiety", "insomnia"],
    "description": "Hands shaking badly, sweating profusely"
  },
  "usedLast48h": {
    "value": true,
    "substances": ["alcohol"],
    "recordedAt": "2025-11-13T10:00:00Z"
  },
  "observation": {
    "value": "withdrawal",
    "description": "Visible tremor, autonomic instability"
  },
  "expectedOutcomes": {
    "suggestedSeverity": 4,
    "emergencyBanner": true,
    "minSeverity": 3,
    "rationaleRequired": true
  }
}
```

### Fixture: d1_sev0_never_used.json

```json
{
  "id": "test-002",
  "dimension": 1,
  "substances": [
    {
      "substance": "alcohol",
      "frequency": "never"
    },
    {
      "substance": "heroin",
      "frequency": "never"
    }
  ],
  "observation": {
    "value": "none"
  },
  "expectedOutcomes": {
    "suggestedSeverity": 0,
    "q2Visible": false,
    "q3Visible": false,
    "q4Visible": false,
    "emergencyBanner": false
  }
}
```

---

## Test Execution Checklist

### Unit Tests
- [ ] All validation rules (8 rules)
- [ ] TTL expiration logic
- [ ] Emergency trigger evaluation
- [ ] Severity suggestion algorithm
- [ ] Visibility conditions (Q2, Q3, Q4)

### Integration Tests
- [ ] Load fixture → verify all fields populate
- [ ] Answer Q1 → verify Q2 visibility updates
- [ ] Trigger emergency → verify banner shows + min severity enforced
- [ ] Complete dimension → verify all validation passes

### UI Tests
- [ ] Quick-add chips populate fields correctly
- [ ] Character counters show at 450/500
- [ ] TTL expired shows "Data stale" banner
- [ ] Emergency banner focus trap works
- [ ] Severity cards disabled when emergency active (< min)

### Accessibility Tests
- [ ] VoiceOver reads all questions
- [ ] VoiceOver announces emergency banner
- [ ] Keyboard navigation through substance grid
- [ ] High contrast mode shows severity clearly

---

## Known Issues

1. ❌ **No character counter on free-text fields**
   - **Impact**: High - users can exceed limits
   - **Fix**: Add `TextAreaLimited` component

2. ❌ **"Other" substance fields not normalized**
   - **Impact**: Medium - data quality issue
   - **Fix**: Add autocomplete with RxNorm

3. ❌ **PDMP integration not spec'd**
   - **Impact**: Low - future feature
   - **Action**: Document as enhancement

4. ❌ **Q5 not required despite logic spec**
   - **Impact**: Medium - missed validation
   - **Fix**: Add to validation matrix

---

## Sign-Off

- [ ] All validation rules implemented
- [ ] Emergency triggers tested
- [ ] TTL logic working
- [ ] Quick-add chips functional
- [ ] All fixtures pass
- [ ] Documentation complete

**Auditor**: ___________________  
**Date**: ___________________  
**Status**: ☐ Pass  ☐ Fail  ☐ Pass with Issues
