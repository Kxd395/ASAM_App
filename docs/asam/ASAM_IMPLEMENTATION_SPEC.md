# ASAM Criteria Implementation Specification

## Overview

This document specifies the implementation of **official ASAM criteria** (versions 3 and 4) to replace placeholder questionnaires. Based on the analysis of official ASAM documents:

- **ASAM v3 (2013)**: Assessment Form with 6 dimensions, 0-4 severity scale
- **ASAM v4 (2024)**: Level-of-Care Guide with subdimensions, skip logic, letter-coded risk ratings (A-E)

---

## Data Model Requirements

### Core ASAM Assessment Model

```swift
struct ASAMAssessment {
    let id: UUID
    let patientId: String
    let version: ASAMVersion // .v3, .v4
    let dimensions: [ASAMDimension]
    let overallRecommendation: ASAMRecommendation?
    let createdAt: Date
    let completedAt: Date?
}

enum ASAMVersion {
    case v3_2013  // Assessment form, 0-4 severity
    case v4_2024  // Level-of-care, A-E risk ratings
}
```

### Skip Logic & Conditional Branching

```swift
struct ASAMQuestion {
    let id: String  // e.g., "Q11", "Q12", "D1_substance_inventory" 
    let text: String
    let type: QuestionType
    let skipLogic: [SkipCondition]?
    let followUpQuestions: [String]? // Question IDs triggered by specific answers
    let riskWeighting: RiskWeighting?
}

struct SkipCondition {
    let dependsOn: String // Previous question ID
    let condition: ConditionOperator // .equals, .greaterThan, .contains
    let value: AnswerValue
    let action: SkipAction // .skip, .show, .required
}
```

---

## ASAM v3 (2013) Implementation 

### Dimension 1: Acute Intoxication & Withdrawal Potential

**Key Question Sets:**

1. **Substance Inventory** (per substance: alcohol, opioids, benzos, stimulants, cannabis, nicotine, others)
   - Duration of continuous use
   - Frequency in last 30 days
   - Route(s) of use
   - Date of last use  
   - Average daily amount
   - Binge episodes (alcohol specific)

2. **Withdrawal Assessment**
   - Physical/emotional symptoms when stopping (scale: Not at all - Extremely)
   - Current withdrawal symptoms (tremors, sweating, rapid HR, nausea, anxiety)
   - Sleep trouble, physical problems, health worries
   - History of severe withdrawal (medical care needed, seizures, delirium)

3. **Clinical Scales Integration**
   - CIWA-Ar scores (alcohol withdrawal)
   - COWS scores (opioid withdrawal)

### Dimension 2: Biomedical Conditions & Complications

**Question Categories:**

1. **Healthcare Access**
   - Primary care clinician (name/contact)
   - Last medical visit (when/reason)

2. **Current Medical Status**
   - Current medications (including medical marijuana/CBD, contraceptives)
   - Medical concerns/disabilities
   - Physical health conditions checklist (heart, BP, GI, neurological, liver/kidney, HIV, hepatitis, diabetes, asthma, chronic pain, cancer, STIs)
   - Infectious disease considerations
   - Medical stability (stable w/ treatment, unstable/uncontrolled, stable w/o treatment, unknown)

3. **Substance-Related Medical Issues**
   - Medical problems caused/worsened by substance use
   - Need for additional medical treatment

4. **Special Populations**
   - Immunization status (COVID, Tdap, Flu, Hep A/B, MMR, Tetanus, VAR)
   - Pregnancy status & prenatal care (trimester tracking)

5. **Functional Impact**
   - Health issues impact on self-care (scale: Not at all - Extremely)
   - Impact on work/school/socializing
   - Impact on SUD treatment attendance
   - Available support for health issues

### Dimension 3: Emotional, Behavioral, or Cognitive Conditions

**Assessment Areas:**

1. **Cognitive Function**
   - Interviewer observation (disorientation, memory problems)
   - Marijuana/CBD use for psychiatric conditions

2. **Mental Health Symptoms (Past 30 Days)**
   - Depression, anhedonia, hopelessness
   - Irritability/anger, impulsivity
   - Pressured speech, grandiosity, racing thoughts
   - Anxiety, OCD symptoms
   - Flashbacks, paranoia, delusions
   - Sleep problems, memory/concentration issues
   - Gambling, risky sexual behavior, physical aggression
   - **Temporal relationship**: Symptoms during use/withdrawal only vs. independent

3. **Functional Impact**
   - Interference with self-care, work/school/social activities, SUD treatment

4. **Safety Assessment**
   - Psychosis (hallucinations during use/withdrawal vs. independent)
   - Self-harm ideation (current, historical, actions taken)
   - Harm to others (thoughts, current risk, historical actions)

5. **Treatment Planning**
   - Major problems caused by symptoms
   - Patient concerns about mental health treatment
   - Goals for emotional health
   - Need for further mental health assessment

### Dimension 4: Readiness to Change

**Core Assessment Components:**

1. **Impact Recognition**
   - Substance use impact on multiple life areas (work, school, mental health, hobbies, legal, finances, family, friendships, romantic relationships, self-esteem, physical health, enjoyment, sexual function, hygiene/self-care)
   - Rating scale: Not at all - Extremely

2. **Change Beliefs**
   - Belief that changing substance use could improve life areas (Yes/No/Don't know)
   - Perceived need for treatment (Yes / No-not a problem / No-can stop alone / Don't know)

3. **Stage of Change Classification**
   - Interviewer assessment: Precontemplation, Contemplation, Preparation, Action, Maintenance

4. **Problem Recognition**
   - Severity rating of substance use as a problem (Not at all - Extremely)

5. **Change History**
   - Past change attempts (mutual help groups, substance switching, social changes)
   - Helpfulness of past treatments

6. **Barriers & Motivators**
   - Treatment barriers (stigma, time, housing, childcare, relationships)
   - Social pressures (probation, courts, family, CPS, employer)
   - Desire to quit vs. cut back vs. unsure vs. neither
   - External pressure ratings and personal importance ratings

7. **Goals & Concerns**
   - Other life areas patient wants to change
   - Concerns about changing substance use

### Dimension 5: Relapse, Continued Use, or Continued Problem Potential

**Assessment Framework:**

1. **Abstinence History**
   - Longest period of abstinence (alcohol/drugs)
   - When abstinence ended
   - Methods used to maintain abstinence (personal strengths, peer support, medication, treatment)

2. **Relapse Analysis**
   - Triggers that led to relapse
   - Plan for future change (stop alone, treatment, medication, support groups, relationship/job changes)

3. **Consequence Assessment**
   - Potential consequences of not changing (near-term vs. long-term)
   - Interviewer severity rating (few/mild, some/not severe, many/severe and imminent)

4. **Trigger & Stress Management**
   - Rating of trigger intensity (Not at all - Extremely):
     - Cravings
     - Social pressure
     - Emotional difficulties
     - Financial stress
     - Physical health problems
   - Worst recent triggers
   - Current coping strategies
   - Quality of relapse prevention plan

5. **Clinical Assessment**
   - Interviewer rating of patient insight into triggers/coping (good, some, limited, dangerously low)
   - Pressing relapse risk issues
   - Goals for addressing relapse risks

### Dimension 6: Recovery/Living Environment

**Environmental Assessment:**

1. **Housing Stability**
   - Current housing status (own/rent/household member)
   - Housing stability over past 2 months
   - Housing security concerns (next 2 months)
   - Need for different housing
   - Household composition (friends, family, partner, roommates)

2. **Economic & Educational Status**
   - Employment status (working, school, retired, disability, unemployed)
   - Job skills inventory
   - Income sources (paid work, SSI/SSDI, family/friends, illegal/under-table, other)
   - Primary income source identification

3. **Social & Functional Assessment**
   - Free time activities (when not working or using substances)
   - Learning challenges requiring support
   - Support needs (transportation, childcare, housing, employment, education, legal, financial)

4. **System Involvement**
   - Social service engagement (CPS, Tribal Service Agency, HHS, others)
   - Criminal justice involvement related to substance use
   - Probation/parole status
   - History of incarceration
   - Court-ordered treatment requirements

5. **Support Systems**
   - Veteran status/VA benefits eligibility
   - Peer support group participation (AA/NA, SMART, etc.)
   - Recovery-supportive vs. risky environmental factors

6. **Safety Assessment**
   - Substance use in living environment
   - Alternative living environment availability
   - Relationship safety threats (weapons, attempts to kill, other threats)
   - Substance use creating dangerous situations

7. **Environmental Analysis**
   - Recovery-supportive factors rating (Not at all - Extremely)
   - Recovery-hindering factors rating
   - Environmental change willingness
   - Goals for improved environment

---

## ASAM v4 (2024) Implementation

### Enhanced Features for Level-of-Care Determination

**Key Differences from v3:**
- Subdimensions within major dimensions
- Question numbering system (Q11, Q12, Q13, etc.)
- Letter-coded risk ratings (A-E) tied to specific treatment levels
- Enhanced skip logic and conditional branching
- Focus on immediate treatment level determination

### Dimension 1: Acute Intoxication, Withdrawal & Addiction Medication Needs

**Question Structure:**

1. **Intoxication Assessment (Q11-Q12)**
   - Q11: Interviewer observation - Patient intoxicated or at imminent withdrawal risk? (Yes/No)
   - Q12: "Are you feeling the effects of any substances right now?" (Yes/No)

2. **Withdrawal Assessment (Q13-Q16)**
   - Q13: "Are you experiencing withdrawal now or do you think you will soon?"
   - Q14: "How uncomfortable would your withdrawal symptoms become without treatment?"
   - Q15: "Have you ever needed medical care for withdrawal?"
     - Q15a: If yes, where?
     - Q15b: Severe withdrawal symptoms (seizures, delirium)?
   - Q16: "Have you received substance use treatment before?"
     - Q16a: If yes, did cravings/withdrawal prevent completion?

3. **Addiction Medication Assessment (Q17-Q17b)**
   - Q17: "Are you now taking, or have you ever taken, prescribed medication to help control cravings or other unwanted symptoms?"
   - Q17a: If yes, specify medication (buprenorphine, methadone, naltrexone, acamprosate)
   - Q17b: "How has it worked for you?" (effectiveness on cravings/withdrawal, dose adjustment issues)

4. **Clinical Scales**
   - CIWA-Ar scores (if applicable)
   - COWS scores (if applicable)

5. **Clinical Determination (Q18)**
   - Interviewer assessment: "Do you think the patient needs medically managed care for intoxication, withdrawal, or addiction medication initiation/titration?" (Yes/No + rationale)

### Dimension 2: Biomedical Conditions (v4 Enhanced)

**Structured Assessment:**

1. **Current Health Status (Q19-Q23)**
   - Q19: "Do you have any other health issues that concern you right now?"
   - Q20: "Are you pregnant?" (If unsure, offer test)
     - Q20a: If pregnant, "Are you receiving prenatal care?"
     - Q20b: Pregnancy complications (high BP, gestational diabetes, pre-eclampsia, placenta problems, premature labor)

2. **Impact Assessment**
   - Q21: "How concerned are you about your current health issue(s)?" (Not at all / Somewhat / Very / A lot)
   - Q22: "How much do these health issues affect your ability to take care of yourself?" (Not at all / Somewhat / A lot)
   - Q23: "How much might your current health issue(s) affect your ability to participate in addiction treatment?"

3. **Risk Rating Determination**
   - Interviewer determines if health issues require medically managed care (Level 3.7 or 4)

### Dimension 3: Emotional, Behavioral, or Cognitive Conditions (v4 Subdimensions)

**Subdimension Split:**

1. **Acute Psychiatric Symptoms**
   - Current mental health symptoms that might worsen with substance discontinuation
   - Severe mood disorders, psychosis, suicidality
   - Need for psychiatric medication management

2. **Persistent Disability**
   - Functional impact assessment
   - Cognitive impairments limiting treatment participation
   - Need for specialized accommodations

3. **Co-Occurring Enhanced (COE) Services**
   - Need for integrated skilled mental health interventions
   - Severe mood/anxiety disorders, schizophrenia spectrum, trauma-related disorders

### Dimension 4: Readiness/Imminent Risk of Use (v4)

**Risk Assessment Focus:**

1. **Trigger Understanding (Q41-Q47a)**
   - Customized to primary substance and treatment goals (abstinence vs. harm reduction)
   - Trigger identification (cravings, emotions, social situations)
   - Risky behavior assessment

2. **Consequence Analysis**
   - Timeline and severity of consequences if risky behaviors continue
   - Differentiation between:
     - Destabilizing consequences (serious harm, victimization, incarceration)
     - Negative but less destabilizing consequences (job loss, relationship strain)

3. **Functional Assessment**
   - Ability to function in current environment when not using substances
   - Chronic deficits that won't resolve immediately with abstinence

4. **Risk Ratings**
   - Letter-coded ratings (B = minimum Level 2.1, E = minimum Level 3.5)
   - Treatment intensity determination

### Dimension 5: Recovery Environment (v4)

**Level-of-Care Oriented Assessment:**

1. **Baseline Functioning**
   - Functional level when not using substances

2. **Environmental Assessment**
   - Housing, family, and social context safety
   - Recovery conduciveness vs. risk factors

3. **Structured Setting Needs**
   - Recovery residence requirements
   - Supportive living environment alongside outpatient/residential treatment

---

## Technical Implementation Requirements

### 1. Data Architecture

```swift
// Enhanced models for ASAM v3/v4
struct ASAMv3Assessment: Codable {
    let dimensions: [ASAMv3Dimension]
    let severityRatings: [DimensionSeverity] // 0-4 scale per dimension
    let overallSeverity: Int
    let recommendations: [String]
}

struct ASAMv4Assessment: Codable {
    let dimensions: [ASAMv4Dimension]
    let riskRatings: [DimensionRiskRating] // A-E ratings per dimension
    let levelOfCare: LevelOfCareRecommendation
    let subdimensionScores: [SubdimensionScore]
}

enum LevelOfCareRecommendation: String, CaseIterable {
    case level_1_0 = "1.0 - Outpatient Services"
    case level_2_1 = "2.1 - Intensive Outpatient"  
    case level_2_5 = "2.5 - Partial Hospitalization"
    case level_3_1 = "3.1 - Clinically Managed Low-Intensity Residential"
    case level_3_3 = "3.3 - Clinically Managed Population-Specific High-Intensity Residential"
    case level_3_5 = "3.5 - Clinically Managed High-Intensity Residential"
    case level_3_7 = "3.7 - Medically Monitored Intensive Inpatient"
    case level_4_0 = "4.0 - Medically Managed Intensive Inpatient"
}
```

### 2. Skip Logic Engine

```swift
class ASAMSkipLogicEngine {
    func shouldShowQuestion(_ questionId: String, 
                          givenAnswers: [String: AnswerValue],
                          version: ASAMVersion) -> Bool {
        // Implementation for complex conditional logic
    }
    
    func getFollowUpQuestions(for questionId: String, 
                            answer: AnswerValue,
                            version: ASAMVersion) -> [String] {
        // Dynamic question generation based on answers
    }
}
```

### 3. Scoring & Risk Rating Engine

```swift
class ASAMScoringEngine {
    func calculateV3Severity(dimension: ASAMv3Dimension, 
                           answers: [String: AnswerValue]) -> Int {
        // 0-4 severity calculation per v3 criteria
    }
    
    func calculateV4RiskRating(dimension: ASAMv4Dimension,
                             answers: [String: AnswerValue]) -> String {
        // A-E risk rating calculation per v4 criteria
    }
    
    func determineLevelOfCare(assessment: ASAMv4Assessment) -> LevelOfCareRecommendation {
        // Complex level-of-care determination algorithm
    }
}
```

### 4. Version Switching

```swift
struct ASAMVersionSelector: View {
    @State private var selectedVersion: ASAMVersion = .v3_2013
    
    var body: some View {
        Picker("ASAM Version", selection: $selectedVersion) {
            Text("ASAM v3 (2013) - Assessment Form").tag(ASAMVersion.v3_2013)
            Text("ASAM v4 (2024) - Level of Care").tag(ASAMVersion.v4_2024)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}
```

---

## Implementation Phases

### Phase 1: Core Framework (T-0056)
- [ ] Design enhanced data models with skip logic support
- [ ] Create version switching infrastructure
- [ ] Build skip logic and conditional branching engine

### Phase 2: ASAM v3 Implementation (T-0057 through T-0062)
- [ ] Implement all 6 dimensions with official question sets
- [ ] Add 0-4 severity scoring per dimension  
- [ ] Create comprehensive assessment flow

### Phase 3: ASAM v4 Implementation (T-0063 through T-0064)
- [ ] Add subdimension support
- [ ] Implement Q-numbered question system
- [ ] Build A-E risk rating system
- [ ] Create level-of-care determination logic

### Phase 4: Integration & Testing (T-0065)
- [ ] Version selection UI
- [ ] Cross-version data compatibility
- [ ] Clinical validation testing

---

## Quality Assurance Requirements

1. **Clinical Accuracy**: All questions must match official ASAM documents exactly
2. **Skip Logic Validation**: Comprehensive testing of all conditional paths
3. **Scoring Verification**: Validate severity/risk calculations against ASAM standards
4. **User Experience**: Intuitive navigation despite complexity
5. **Data Integrity**: Robust handling of partial assessments and version switches

---

## Next Steps

1. **Review and approve** this specification
2. **Begin Phase 1** implementation with enhanced data models
3. **Create detailed question mappings** from official ASAM documents
4. **Implement one dimension end-to-end** as proof of concept
5. **Scale to full ASAM v3/v4 implementation**

This specification provides the foundation for implementing **clinical-grade ASAM assessments** that meet professional standards while leveraging our existing questionnaire infrastructure.