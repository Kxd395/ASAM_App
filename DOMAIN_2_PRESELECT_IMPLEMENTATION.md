# DOMAIN 2 PRE-SELECTED OPTIONS - IMPLEMENTATION PLAN

**Date**: November 12, 2025  
**Request**: "For Domain 2 I need pre-select option similar to Domain 1"  
**Status**: 🔍 **CLARIFICATION NEEDED**

---

## 📋 CURRENT DOMAIN 2 STRUCTURE

### Questionnaire: `d2_biomedical_neutral.json`

**Questions** (7 total):
1. **b01**: Current medical conditions (single_choice, required)
   - Options: none, mild, moderate, severe
2. **b02**: Prescribed medications (single_choice, required)
   - Options: none, few, multiple, critical
3. **b03**: Recent hospitalizations (boolean, required)
4. **b04**: Physical health status (single_choice, required)
   - Options: excellent, good, fair, poor
5. **b05**: Infectious diseases (single_choice, required)
   - Options: none, stable, active, contagious
6. **b06**: Self-care ability (single_choice, required)
   - Options: independent, minimal_help, significant_help, dependent
7. **b07**: Pregnancy considerations (single_choice, NOT required)
   - Options: not_applicable, not_pregnant, pregnant_stable, pregnant_high_risk
   - Conditional visibility based on patient gender

---

## ❓ CLARIFICATION QUESTIONS

Before I can implement pre-selected options for Domain 2, I need to understand:

### 1. **What should be pre-selected?**
   - [ ] Should specific questions have default answers?
   - [ ] Which questions should have defaults?
   - [ ] What should the default values be?

### 2. **When should pre-selection happen?**
   - [ ] When starting a new assessment?
   - [ ] Based on answers from Domain 1?
   - [ ] Based on patient demographics?
   - [ ] Always the same defaults?

### 3. **What is "similar to Domain 1"?**
   - [ ] Does Domain 1 currently have pre-selected options in the app?
   - [ ] Are you referring to a specific behavior you see in Domain 1?
   - [ ] Is there a specific question in Domain 1 that demonstrates this?

---

## 🔍 DOMAIN 1 ANALYSIS

### Current Domain 1 Structure (`d1_withdrawal_neutral.json`):
- **a01**: Intoxication signs (single_choice)
- **a02**: Consciousness level (single_choice)
- **a03**: Withdrawal symptoms (single_choice)
- **a04**: Recent substance use (multiple_choice)
- **a05**: Withdrawal history (boolean)
- **a06**: Physical distress score (number, 0-10)
- **a07**: Medical complications (single_choice)

### No Pre-selection Found in Code:
I searched the codebase and didn't find any automatic pre-selection logic for Domain 1. All answers start empty (`answers: [:]`).

---

## 💡 POSSIBLE INTERPRETATIONS

### Option A: Clinical Defaults
Pre-select the most common/safe answers:
```swift
// Example for Domain 2
let defaultAnswers: [String: AnswerValue] = [
    "b01": .single("none"),           // No medical conditions
    "b03": .bool(false),               // No recent hospitalizations
    "b04": .single("good"),            // Good health status
    "b05": .single("none"),            // No infectious diseases
    "b06": .single("independent"),     // Independent self-care
    "b07": .single("not_applicable")   // Not applicable (pregnancy)
]
```

### Option B: Carry-Forward from Domain 1
Use Domain 1 answers to pre-populate Domain 2:
```swift
// Example logic
if domain1.answers["a07"] == .single("severe") {
    // Pre-select "severe" for medical conditions in Domain 2
    domain2.answers["b01"] = .single("severe")
}
```

### Option C: Patient Profile Defaults
Pre-select based on patient demographics:
```swift
if patient.gender == "female" && patient.age < 50 {
    domain2.answers["b07"] = .single("not_pregnant")
}
```

### Option D: "None/No" Baseline
Start with all "no problem" answers selected to speed up assessment:
```swift
let baselineAnswers: [String: AnswerValue] = [
    "b01": .single("none"),
    "b02": .single("none"),
    "b03": .bool(false),
    "b05": .single("none")
]
```

---

## 🛠️ IMPLEMENTATION APPROACH

### Step 1: Define Pre-selection Rules
Create a configuration file or function:

```swift
// In AssessmentStore.swift or new file
extension Domain {
    static func defaultAnswersForDomain(_ domainNumber: Int) -> [String: AnswerValue] {
        switch domainNumber {
        case 2:
            return [
                "b01": .single("none"),
                "b02": .single("none"),
                "b03": .bool(false),
                "b04": .single("good"),
                "b05": .single("none"),
                "b06": .single("independent"),
                "b07": .single("not_applicable")
            ]
        default:
            return [:]
        }
    }
}
```

### Step 2: Apply Defaults on Domain Creation
Modify `Domain.allDomains()` in Assessment.swift:

```swift
static func allDomains() -> [Domain] {
    let domains = [
        Domain(id: UUID(), number: 1, title: "Acute Intoxication/Withdrawal", 
               severity: 0, notes: "", isComplete: false, 
               answers: [:]),  // No defaults
        Domain(id: UUID(), number: 2, title: "Biomedical Conditions", 
               severity: 0, notes: "", isComplete: false, 
               answers: defaultAnswersForDomain(2)),  // PRE-SELECTED
        // ... rest
    ]
    return domains
}
```

### Step 3: Update UI to Show Pre-selected Values
QuestionnaireRenderer already handles `initialAnswers`, so this will work automatically.

---

## 📊 EXAMPLE SCENARIOS

### Scenario 1: Speed Up Assessment
**Goal**: Reduce clicks for healthy patients

**Pre-select**:
- b01: "No current medical conditions"
- b02: "No prescribed medications"
- b03: false (No recent hospitalizations)
- b04: "Good" physical health
- b05: "No infectious diseases"
- b06: "Fully independent" self-care

**Clinician Action**: Only change if different from defaults

---

### Scenario 2: Clinical Carry-Forward
**Goal**: Intelligent defaults based on Domain 1

**Logic**:
- If Domain 1 shows severe withdrawal → Pre-select b01 as "moderate" medical conditions
- If Domain 1 shows no complications → Pre-select b01 as "none"

---

## ✅ NEXT STEPS

To proceed, please clarify:

1. **What specific values** should be pre-selected for Domain 2?
2. **Should these be**:
   - ☐ Fixed defaults (same for all patients)?
   - ☐ Based on Domain 1 answers?
   - ☐ Based on patient demographics?
3. **Should clinicians be able to**:
   - ☐ Clear all pre-selected answers?
   - ☐ See which answers were pre-selected?
   - ☐ Have defaults disabled via settings?

---

## 🎯 RECOMMENDED APPROACH

**My Recommendation**: Start with **Option D - "None/No" Baseline**

### Why:
- ✅ Speeds up assessment for healthy patients (common case)
- ✅ Easy to override if patient has conditions
- ✅ Clinically safe (defaults to "no problems")
- ✅ Simple to implement
- ✅ No complex logic needed

### Default Values:
```json
{
  "b01": "none",           // No medical conditions
  "b02": "none",           // No medications
  "b03": false,            // No hospitalizations
  "b04": "good",           // Good health
  "b05": "none",           // No infectious diseases
  "b06": "independent",    // Independent
  "b07": "not_applicable"  // N/A (pregnancy)
}
```

**Would this work for your use case?**

---

**Awaiting Your Clarification**:
- Please describe what you see in Domain 1 that you want replicated
- Or specify which answers should be pre-selected for Domain 2
- Or provide screenshots showing the desired behavior

---

**Status**: ⏸️ **ON HOLD - AWAITING USER INPUT**
