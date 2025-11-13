# Dimension 3: Emotional/Behavioral/Cognitive - Audit Checklist

**Date**: November 13, 2025  
**Status**: Ready for Audit  
**Priority**: P1 - Critical for Safety Assessment

---

## Overview

Dimension 3 assesses mental health conditions, suicidality, behavioral health crises, and cognitive impairments. This is a **high-risk domain** for patient safety.

**Critical Safety Concerns**:
- Active suicidal ideation or plan
- Recent suicide attempt
- Violent behavior or homicidal ideation
- Acute psychosis
- Severe cognitive impairment affecting consent

---

## Question-by-Question Audit

### Q1: Mental Health Diagnoses (Page 7)

**Question**: "Have you been diagnosed with any mental health conditions?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes, multi-select from categorized list:
  - **Mood**: Major Depression, Bipolar I/II, Dysthymia
  - **Anxiety**: GAD, Panic Disorder, Social Anxiety, OCD, PTSD
  - **Psychotic**: Schizophrenia, Schizoaffective, Psychosis NOS
  - **Personality**: Borderline PD, Antisocial PD, Other PD
  - **Neurodevelopmental**: ADHD, ASD, Intellectual Disability
  - **Other**: Free-text (max 500 chars)

**Validation Rules**:
- [ ] Character limit: 500 with counter at 450
- [ ] **NO COUNTER CURRENTLY IMPLEMENTED** - LOG AS ISSUE

**Quick-Add Chips**:
- [ ] Common combos: "Depression + Anxiety", "Bipolar + PTSD", "Schizophrenia + substance use"

**Prefill from EMR**:
- [ ] Pull `mentalHealthDiagnoses` from EHR
- [ ] Match by ICD-10 code (F-codes)
- [ ] Badge: "From chart, 20d"

**Test Cases**:
```json
// Test: Multi-select with "Other"
{
  "d3.mentalHealth.value": true,
  "d3.mentalHealth.selected": ["major_depression", "ptsd"],
  "d3.mentalHealth.other": "Complex grief following multiple losses"
}
```

---

### Q2: Currently Taking Psych Medications (Page 7)

**Question**: "Are you currently taking psychiatric medications?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes, medication grid (same structure as D2):
  - Name, Dose, Frequency, Prescriber

**Validation Rules**:
- [ ] **CRITICAL**: Check for med/substance interactions
  - **Example**: MAOI + stimulant use = hypertensive crisis risk

**Quick-Add Chips**:
- [ ] "Sertraline 100mg daily"
- [ ] "Lithium 300mg BID"
- [ ] "Risperidone 2mg QHS"

**Test Cases**:
```json
// Test: Medication entry
{
  "d3.psychMeds.value": true,
  "d3.psychMeds.list": [
    { "name": "sertraline", "dose": "100mg", "frequency": "daily" }
  ]
}
```

---

### Q3: Current Mental Health Symptoms (Page 7)

**Question**: "Are you experiencing any of these symptoms now?"

**Answer Flow**:
- Multi-select symptom checklist:
  - **Mood**: Depressed mood, Irritability, Mania/hypomania
  - **Anxiety**: Panic attacks, Excessive worry, Flashbacks
  - **Psychotic**: Hallucinations, Delusions, Paranoia
  - **Cognitive**: Confusion, Memory loss, Disorientation
  - **Other**: Free-text

**Validation Rules**:
- [ ] If "Hallucinations" OR "Delusions" selected → auto-suggest Sev 3+
- [ ] If "Confusion" OR "Disorientation" selected → check for delirium (D1 interaction)

**Quick-Add Chips**:
- [ ] Symptom clusters: "Depressed + anhedonia + hopelessness"
- [ ] "Active hallucinations + paranoia"

**Test Cases**:
```json
// Test: Psychotic symptoms suggest high severity
{
  "d3.currentSymptoms.selected": ["hallucinations", "delusions"],
  "expectedSuggestion": 3,
  "expectedFactor": "Active psychotic symptoms - need psychiatric stabilization"
}
```

---

### Q4: Suicidal Ideation (Page 7)

**Question**: "In the past month, have you thought about killing yourself?"

**Answer Flow**:
- Radio: [Yes | No]
- If Yes:
  - **Frequency**: Dropdown (Daily, Few times/week, Few times/month, Once)
  - **Plan**: Boolean + free-text if Yes
  - **Means Access**: Boolean + free-text if Yes (e.g., "Gun in home")
  - **Intent**: Boolean (do you intend to act on it?)

**Validation Rules**:
- [ ] **ALWAYS REQUIRED** - no skip logic
- [ ] If Plan = Yes OR Intent = Yes → **EMERGENCY BANNER**

**Quick-Add Chips**:
- [ ] "Passive thoughts, no plan"
- [ ] "Active plan - overdose on pills in cabinet"
- [ ] "Frequent thoughts, no intent to act"

**Emergency Logic**:
- [ ] **CRITICAL**: Plan + intent = immediate safety assessment
  - **Trigger**: `d3.suicidalIdeation.plan == true && d3.suicidalIdeation.intent == true`
  - **Banner**: "Patient has suicidal plan with intent. Immediate safety intervention required."
  - **Min Severity**: 4
  - **Action Button**: "Open Safety Protocol"

**Test Cases**:
```json
// Test: Emergency trigger
{
  "d3.suicidalIdeation.value": true,
  "d3.suicidalIdeation.plan": true,
  "d3.suicidalIdeation.planDescription": "Plan to overdose on pain pills tonight",
  "d3.suicidalIdeation.meansAccess": true,
  "d3.suicidalIdeation.intent": true,
  "expectedBanner": "d3_suicide_plan_intent",
  "expectedMinSeverity": 4
}

// Test: Passive SI, no emergency
{
  "d3.suicidalIdeation.value": true,
  "d3.suicidalIdeation.frequency": "few_times_month",
  "d3.suicidalIdeation.plan": false,
  "d3.suicidalIdeation.intent": false,
  "expectedBanner": false,
  "expectedSuggestion": 2
}
```

---

### Q5: Suicide Attempt History (Page 7)

**Question**: "Have you ever attempted suicide?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Number of Attempts**: Number field
  - **Most Recent**: Date picker
  - **Method**: Free-text
  - **Medical Treatment**: Boolean (were you hospitalized?)

**Validation Rules**:
- [ ] Most recent attempt date cannot be future
- [ ] If attempt ≤30 days → auto-suggest Sev 3+

**Quick-Add Chips**:
- [ ] "1 attempt, >1 year ago, hospitalized"
- [ ] "Multiple attempts, most recent 6mo ago"

**Test Cases**:
```json
// Test: Recent attempt suggests high severity
{
  "d3.suicideAttempt.value": true,
  "d3.suicideAttempt.count": 1,
  "d3.suicideAttempt.mostRecent": "2025-10-15", // 29 days ago
  "d3.suicideAttempt.method": "Overdose on opioids",
  "d3.suicideAttempt.medicalTreatment": true,
  "expectedSuggestion": 3,
  "expectedFactor": "Recent suicide attempt within 30 days"
}
```

---

### Q6: Violent Behavior/Homicidal Ideation (Page 7)

**Question**: "In the past month, have you had thoughts of harming others or acted violently?"

**Answer Flow**:
- Radio: [Yes | No]
- If Yes:
  - **Thoughts**: Boolean
  - **Verbal Threats**: Boolean
  - **Physical Violence**: Boolean
  - **Specific Target**: Boolean + free-text if Yes (name/relation)

**Validation Rules**:
- [ ] **CRITICAL**: If "Specific Target" = Yes → **EMERGENCY BANNER** + Duty to Warn
  - **Trigger**: `d3.homicidalIdeation.specificTarget == true`
  - **Banner**: "Patient has identifiable target for violence. Duty to warn may apply."
  - **Min Severity**: 4

**Emergency Logic**:
```swift
if d3.homicidalIdeation.specificTarget {
    showBanner(.dutyToWarn, severity: 4)
    requireAction(.contactClinicalSupervisor)
}
```

**Test Cases**:
```json
// Test: Duty to warn trigger
{
  "d3.homicidalIdeation.value": true,
  "d3.homicidalIdeation.thoughts": true,
  "d3.homicidalIdeation.specificTarget": true,
  "d3.homicidalIdeation.targetDescription": "Ex-partner, threatened to 'get even'",
  "expectedBanner": "d3_duty_to_warn",
  "expectedMinSeverity": 4,
  "expectedAction": "Contact clinical supervisor immediately"
}
```

---

### Q7: Currently in MH Treatment (Page 8)

**Question**: "Are you currently receiving mental health treatment?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Treatment Type**: Multi-select (Therapy, Medication Mgmt, IOP, PHP, Inpatient)
  - **Provider Name**: Free-text
  - **Last Appointment**: Date picker
  - **Engaged/Compliant**: Boolean

**Validation Rules**:
- [ ] If treatment = Yes BUT engaged = No → add to barriers (D6)

**Quick-Add Chips**:
- [ ] "Weekly therapy, engaged"
- [ ] "Monthly med mgmt, compliant"
- [ ] "Recently discharged from inpatient"

**Test Cases**:
```json
// Test: Not engaged adds barrier
{
  "d3.currentTreatment.value": true,
  "d3.currentTreatment.type": ["therapy"],
  "d3.currentTreatment.engaged": false,
  "expectedBarrierAdded": "Not engaged in current mental health treatment"
}
```

---

### Q8-11: Problem Statements (Page 8)

**Questions**:
- Q8: Mental health problems affecting well-being
- Q9: Psychiatric risks or crises
- Q10: Barriers to treatment
- Q11: Recommended actions

**Quick-Add Chips**:
- [ ] **Q8**: "Severe depression interfering with daily function", "PTSD flashbacks", "Paranoia affecting relationships"
- [ ] **Q9**: "Suicide risk with plan", "Psychotic decompensation", "Violent behavior when intoxicated"
- [ ] **Q10**: "No access to psychiatrist", "Can't afford meds", "Trauma history with male providers"
- [ ] **Q11**: "Psychiatric consult for med adjustment", "Safety plan + crisis hotline", "Refer to DBT program"

---

### Severity Rating (Page 8)

**Severity Suggestion Logic**:
```swift
func d3SuggestSeverity(_ state: Assessment) -> (suggested: Int, factors: [String]) {
    var level = 0
    var factors: [String] = []
    
    // Sev 4: Imminent danger
    if (state.d3.suicidalIdeation.plan && state.d3.suicidalIdeation.intent) ||
       state.d3.homicidalIdeation.specificTarget {
        level = 4
        factors.append("Imminent risk to self or others")
    }
    
    // Sev 3: Acute crisis or recent attempt
    if state.d3.activePsychosis || state.d3.recentSuicideAttempt {
        level = max(level, 3)
        factors.append("Acute psychiatric crisis requiring stabilization")
    }
    
    // Sev 2: Chronic symptoms, passive SI, stable on meds
    if state.d3.passiveSI || state.d3.chronicSymptoms {
        level = max(level, 2)
        factors.append("Mental health symptoms requiring integrated treatment")
    }
    
    // Sev 1: Stable with treatment
    if state.d3.stableOnTreatment {
        level = max(level, 1)
        factors.append("Stable mental health condition with treatment")
    }
    
    return (level, factors)
}
```

**Validation Rules**:
- [ ] Rationale required if Sev 3 or 4
- [ ] **Emergency banner** auto-shows before selection if Sev 4 factors present

**Quick-Add Rationale Chips**:
- [ ] "Active suicidal plan with access to means - need inpatient stabilization"
- [ ] "Psychotic symptoms + substance use - dual diagnosis LOC"
- [ ] "Recent attempt + ongoing SI - high risk for repeat"

---

## Emergency Banner Triggers

### Trigger: d3_suicide_plan_intent

**Condition**: `d3.suicidalIdeation.plan == true && d3.suicidalIdeation.intent == true`

**Banner Message**: "Patient has suicidal plan with intent. Immediate safety intervention required."

**Actions**:
- [ ] Min Severity: 4
- [ ] Requires: Safety assessment, no-harm contract or involuntary commitment evaluation
- [ ] Primary Button: "Open Safety Protocol"
- [ ] Logs dismissal with justification required

---

### Trigger: d3_duty_to_warn

**Condition**: `d3.homicidalIdeation.specificTarget == true`

**Banner Message**: "Patient has identifiable target for violence. Duty to warn may apply. Contact supervisor immediately."

**Actions**:
- [ ] Min Severity: 4
- [ ] Requires: Clinical supervisor notification
- [ ] Primary Button: "Document Duty to Warn"

---

## Fixtures

### Fixture: d3_sev4_suicide_plan.json

```json
{
  "id": "test-005",
  "dimension": 3,
  "mentalHealth": {
    "value": true,
    "selected": ["major_depression"]
  },
  "suicidalIdeation": {
    "value": true,
    "frequency": "daily",
    "plan": true,
    "planDescription": "Plan to overdose on pain pills in medicine cabinet",
    "meansAccess": true,
    "intent": true
  },
  "expectedOutcomes": {
    "suggestedSeverity": 4,
    "emergencyBanner": true,
    "minSeverity": 4,
    "rationaleRequired": true
  }
}
```

### Fixture: d3_sev0_stable.json

```json
{
  "id": "test-006",
  "dimension": 3,
  "mentalHealth": {
    "value": true,
    "selected": ["gad"]
  },
  "psychMeds": {
    "value": true,
    "list": [{ "name": "sertraline", "dose": "50mg", "frequency": "daily" }]
  },
  "suicidalIdeation": {
    "value": false
  },
  "currentTreatment": {
    "value": true,
    "type": ["therapy"],
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
- [ ] Suicide emergency trigger (plan + intent)
- [ ] Duty to warn trigger (specific target)
- [ ] Recent attempt suggests Sev 3+
- [ ] Psychotic symptoms suggest Sev 3+

### Integration Tests
- [ ] Load fixture → verify emergency banner shows
- [ ] Answer Q4 with plan + intent → verify min severity = 4
- [ ] Complete dimension → all validations pass

### UI Tests
- [ ] Emergency banner focus trap works
- [ ] Safety protocol button navigates correctly
- [ ] Character counters show at 450/500

---

## Known Issues

1. ❌ **No character counter on free-text fields**
   - **Impact**: High
   - **Fix**: Add `TextAreaLimited` component

2. ❌ **Duty to warn workflow not fully spec'd**
   - **Impact**: High - legal requirement
   - **Fix**: Create duty-to-warn documentation flow

---

## Sign-Off

- [ ] All validation rules implemented
- [ ] Emergency triggers tested
- [ ] Safety protocols accessible
- [ ] All fixtures pass

**Auditor**: ___________________  
**Date**: ___________________  
**Status**: ☐ Pass  ☐ Fail  ☐ Pass with Issues
