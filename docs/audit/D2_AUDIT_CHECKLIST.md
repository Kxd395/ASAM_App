# Dimension 2: Biomedical Conditions - Audit Checklist

**Date**: November 13, 2025  
**Status**: Ready for Audit  
**Priority**: P1 - Critical for LOC Determination

---

## Overview

Dimension 2 assesses biomedical conditions and complications that may affect treatment. This dimension is critical for determining whether higher levels of care with medical support are needed.

**Key Concerns**:
- Chronic conditions requiring monitoring (diabetes, HIV, etc.)
- Acute medical issues needing immediate attention
- Pregnancy status and trimester
- Medication interactions with treatment

---

## Question-by-Question Audit

### Q1: Current Medical Conditions (Page 5)

**Question**: "Do you have any current medical conditions?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes, multi-select from categorized list:
  - **Infectious**: HIV, Hepatitis B/C, TB, COVID-19
  - **Chronic**: Diabetes, Hypertension, COPD, Asthma
  - **Cardiovascular**: CHF, CAD, Arrhythmia
  - **Neurological**: Seizure disorder, Stroke history, TBI
  - **Other**: Free-text (max 500 chars)

**Validation Rules**:
- [ ] **CRITICAL**: "Other" free-text limited to 500 chars
- [ ] Character counter at 450

**Quick-Add Chips**:
- [ ] Common combos: "Diabetes + HTN", "HIV + HepC", "COPD + smoking"
- [ ] Tap chip → selects all conditions + adds to "Other" field with timestamp

**Prefill from EMR**:
- [ ] Pull `problemList` from EHR (active conditions only)
- [ ] Match by ICD-10 code
- [ ] Show badge: "From chart, 12d"
- [ ] Conflict chip if user reports different condition

**Test Cases**:
```json
// Test: Multi-select with "Other"
{
  "d2.medicalConditions.value": true,
  "d2.medicalConditions.selected": ["diabetes", "hypertension"],
  "d2.medicalConditions.other": "Chronic back pain (herniated disc L4-L5)"
}

// Test: Character limit
{
  "d2.medicalConditions.other": "Lorem ipsum..." // 501 chars
  // ERROR: Character limit exceeded
}
```

---

### Q2: Taking Medications (Page 5)

**Question**: "Are you currently taking any medications?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes, medication grid:
  - **Name**: Free-text with autocomplete (RxNorm)
  - **Dose**: Free-text
  - **Frequency**: Dropdown (Daily, BID, TID, QID, PRN, etc.)
  - **Prescriber**: Free-text (optional)

**Validation Rules**:
- [ ] **CRITICAL**: Check for drug-drug interactions with MAT meds
  - **Rule**: `checkInteraction("d2.medications[*].name", matMeds: ["buprenorphine", "methadone", "naltrexone"])`
  - **Test**: Add "Benzodiazepine" + "Buprenorphine" → show warning banner

- [ ] Name autocomplete with RxNorm lookup

**Quick-Add Chips**:
- [ ] "Metformin 500mg BID" → populates all fields
- [ ] "Lisinopril 10mg daily"
- [ ] "Albuterol inhaler PRN"

**Prefill from EMR**:
- [ ] Pull `medicationList` from EHR (active only)
- [ ] Match by RxNorm code
- [ ] Badge: "From chart, 8d"

**Drug-Drug Interaction Logic**:
```swift
func checkInteraction(_ meds: [Medication]) -> [Warning] {
    var warnings: [Warning] = []
    
    // Benzo + Buprenorphine
    if meds.contains("benzodiazepine") && meds.contains("buprenorphine") {
        warnings.append(.init(
            level: .high,
            message: "Benzodiazepines increase overdose risk with buprenorphine"
        ))
    }
    
    // QTc prolongation risk
    if meds.contains("methadone") && meds.contains(where: { qtcDrugs.contains($0) }) {
        warnings.append(.init(
            level: .medium,
            message: "Methadone + QTc-prolonging drug - consider EKG"
        ))
    }
    
    return warnings
}
```

**Test Cases**:
```json
// Test: DDI warning
{
  "d2.medications": [
    { "name": "alprazolam", "dose": "1mg", "frequency": "TID" },
    { "name": "buprenorphine", "dose": "8mg", "frequency": "daily" }
  ],
  "expectedWarning": "Benzodiazepines increase overdose risk with buprenorphine",
  "warningLevel": "high"
}
```

---

### Q3: Pregnant/Possibility of Pregnancy (Page 5)

**Question**: "Are you pregnant or is there a possibility of pregnancy?"

**Answer Flow**:
- Radio: [Pregnant | Possibly pregnant | Not pregnant | N/A (male)]
- If "Pregnant", show:
  - **Trimester**: Radio (1st | 2nd | 3rd)
  - **Due Date**: Date picker
  - **Prenatal Care**: Boolean
  - **High-Risk**: Boolean + free-text if Yes

**Validation Rules**:
- [ ] **CRITICAL**: Hidden if patient sex = male
  - **Rule**: `visibleIf("d2.pregnancy", when: "header.sex != 'male'")`

- [ ] Trimester + due date must be consistent
  - **Test**: Trimester = 1st, due date = 2 months from now → ERROR

- [ ] Due date cannot be past

**Quick-Add Chips**:
- [ ] **Trimester shortcuts**: "1st tri (12w)", "2nd tri (26w)", "3rd tri (36w)" → auto-calc due date
- [ ] "High-risk - previous stillbirth"
- [ ] "No prenatal care yet"

**Severity Impact**:
- [ ] Pregnancy + substance use → suggest Sev 3+ (need specialized LOC)

**Test Cases**:
```json
// Test: Hidden for male
{
  "header.sex": "male",
  "d2.pregnancy.visible": false
}

// Test: Valid pregnancy
{
  "d2.pregnancy.status": "pregnant",
  "d2.pregnancy.trimester": "3rd",
  "d2.pregnancy.dueDate": "2025-12-15",
  "d2.pregnancy.prenatalCare": true,
  "d2.pregnancy.highRisk": false
}
```

---

### Q4: Medical Appointments/Follow-up (Page 5)

**Question**: "Do you have upcoming medical appointments or need follow-up?"

**Answer Flow**:
- Boolean: [Yes | No]
- If Yes:
  - **Appointment Type**: Dropdown (Primary care, Specialist, Lab work, etc.)
  - **Date**: Date picker
  - **Location**: Free-text
  - **Critical**: Boolean (if appointment is urgent/cannot miss)

**Validation Rules**:
- [ ] Appointment date cannot be past
- [ ] If "Critical" = true, highlight in red + add to barriers (D6)

**Quick-Add Chips**:
- [ ] "PCP next week"
- [ ] "Specialist consult pending"
- [ ] "Labs due in 3 days" → auto-set critical = true

**Test Cases**:
```json
// Test: Critical appointment
{
  "d2.appointments.value": true,
  "d2.appointments.type": "specialist",
  "d2.appointments.date": "2025-11-20",
  "d2.appointments.critical": true,
  "expectedHighlight": true,
  "expectedBarrierAdded": "Critical medical appointment on 11/20 - cannot miss"
}
```

---

### Q5-8: Problem Statements (Page 6)

**Questions**:
- Q5: Health problems affecting well-being
- Q6: Medical risks or complications
- Q7: Barriers to treatment
- Q8: Recommended actions

**Answer Flow**: Free-text, max 500 chars each

**Quick-Add Chips**:
- [ ] **Q5**: "Uncontrolled diabetes", "Chronic pain", "Mobility issues"
- [ ] **Q6**: "Infection risk with injection use", "Pregnancy complications", "Seizure risk"
- [ ] **Q7**: "No insurance", "No PCP", "Can't afford meds"
- [ ] **Q8**: "Refer to ID clinic", "Enroll in prenatal care", "Get MAT with medical monitoring"

**Validation Rules**:
- [ ] Character limit: 500 with counter at 450
- [ ] **NO COUNTER CURRENTLY IMPLEMENTED** - LOG AS ISSUE

---

### Severity Rating (Page 6)

**Severity Suggestion Logic**:
```swift
func d2SuggestSeverity(_ state: Assessment) -> (suggested: Int, factors: [String]) {
    var level = 0
    var factors: [String] = []
    
    // Sev 4: Life-threatening condition
    if state.d2.lifeThreateningCondition {
        level = 4
        factors.append("Acute life-threatening medical condition")
    }
    
    // Sev 3: Pregnancy + substance use OR unstable chronic condition
    if (state.d2.pregnancy.status == .pregnant && state.d1.anySubstanceUse) {
        level = max(level, 3)
        factors.append("Pregnancy with substance use - specialized LOC needed")
    }
    
    if state.d2.unstableChronicCondition {
        level = max(level, 3)
        factors.append("Unstable chronic condition requiring medical monitoring")
    }
    
    // Sev 2: Stable chronic conditions OR critical appointments
    if state.d2.stableChronicConditions.count > 0 || state.d2.criticalAppointments {
        level = max(level, 2)
        factors.append("Medical conditions requiring outpatient monitoring")
    }
    
    // Sev 1: Minor conditions, no complications
    if state.d2.anyMedicalCondition && level == 0 {
        level = 1
        factors.append("Medical conditions noted, no complications")
    }
    
    return (level, factors)
}
```

**Validation Rules**:
- [ ] Rationale required if Sev 3 or 4

**Quick-Add Rationale Chips**:
- [ ] "Pregnancy in 3rd trimester + opioid use - need maternal LOC"
- [ ] "Uncontrolled diabetes + insulin - need medical monitoring"
- [ ] "Recent stroke + hypertension - unstable"

**Test Cases**:
```json
// Test: Pregnancy suggests Sev 3
{
  "d2.pregnancy.status": "pregnant",
  "d2.pregnancy.trimester": "3rd",
  "d1.substances.heroin.frequency": "daily",
  "expectedSuggestion": 3,
  "expectedFactors": ["Pregnancy with substance use - specialized LOC needed"]
}
```

---

## Emergency Banner Triggers

### Trigger: d2_life_threatening

**Condition**: `d2.medicalConditions.selected.includes(lifeThreatening) || d2.acuteMedicalIssue`

**Banner Message**: "Patient has acute life-threatening medical condition. Immediate medical evaluation required."

**Actions**:
- [ ] Min Severity: 4
- [ ] Primary Button: "Call EMS / Transfer to ED"

**Test**:
```json
{
  "d2.medicalConditions.selected": ["active_TB", "acute_MI"],
  "expectedBanner": true,
  "expectedMinSeverity": 4
}
```

---

## Fixtures

### Fixture: d2_sev3_pregnancy.json

```json
{
  "id": "test-003",
  "dimension": 2,
  "medicalConditions": {
    "value": false
  },
  "pregnancy": {
    "status": "pregnant",
    "trimester": "3rd",
    "dueDate": "2025-12-20",
    "prenatalCare": true,
    "highRisk": false
  },
  "expectedOutcomes": {
    "suggestedSeverity": 3,
    "rationaleRequired": true,
    "factorIncluded": "Pregnancy with substance use"
  }
}
```

### Fixture: d2_sev0_healthy.json

```json
{
  "id": "test-004",
  "dimension": 2,
  "medicalConditions": {
    "value": false
  },
  "medications": {
    "value": false
  },
  "pregnancy": {
    "status": "not_pregnant"
  },
  "appointments": {
    "value": false
  },
  "expectedOutcomes": {
    "suggestedSeverity": 0
  }
}
```

---

## Test Execution Checklist

### Unit Tests
- [ ] Pregnancy visibility logic (hidden for male)
- [ ] DDI warnings (benzo + buprenorphine)
- [ ] Severity suggestion algorithm
- [ ] Trimester/due date consistency

### Integration Tests
- [ ] Load fixture → verify pregnancy fields populate
- [ ] Answer medications → verify DDI check runs
- [ ] Trigger life-threatening → verify banner shows

### UI Tests
- [ ] Quick-add medication chips work
- [ ] Character counters show at 450/500
- [ ] DDI warning banner is dismissible

---

## Known Issues

1. ❌ **No DDI engine integrated**
   - **Impact**: High - safety issue
   - **Fix**: Integrate Lexicomp or RxNav API

2. ❌ **Character counter missing**
   - **Impact**: Medium
   - **Fix**: Add `TextAreaLimited` component

---

## Sign-Off

- [ ] All validation rules implemented
- [ ] DDI warnings tested
- [ ] Pregnancy logic working
- [ ] All fixtures pass

**Auditor**: ___________________  
**Date**: ___________________  
**Status**: ☐ Pass  ☐ Fail  ☐ Pass with Issues
