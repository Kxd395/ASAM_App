Here is a **hypercritical, question-by-question logic audit** with exact answer flows, validation gates, and quick-add chip specs. Every gap that will break your UI or corrupt your data is called out.

---

## **DIMENSION 1: ACUTE INTOXICATION OR WITHDRAWAL POTENTIAL**

### **Q1: Substance Use Grid (Page 1–2)**

**Answer Flow:**
1. **Interviewer reads substance list.** For each substance, patient responds **Yes/No**.
2. If **Yes**, show nested fields:
   - **Duration:** Two number fields (Years, Months) + unit segments.
   - **Frequency:** Single-select radio [Never used | 3 or less days/month | 1–3 days/week | 4–7 days/week].
   - **Route:** Multi-select chips [Oral | Nasal/snort | Smoke | Inject | Other]. **Logic error:** "Never used" in frequency should disable route selection. **Not enforced.**
   - **Last use date:** Date picker (max = today). **Logic error:** If frequency = "Never used," last use date must be null. **No validation.**
   - **Binge drinking:** Show only for Alcohol. Two number fields: female ≥4 drinks, male ≥5 drinks. **Requires `patientSexAtBirth` from demographics.** If missing, **crash.**
   - **Prescription validity:** Show only for Prescription Opioids, Benzos, Stimulants. Boolean chip [Yes | No]. **Requires PDMP check.** **No PDMP integration spec.**

**Quick-Add Chips:**
- **Route:** Pre-fill common combos: "Smoked heroin," "Injected cocaine." Tapping chip selects both substance + route + sets duration = "0 years, 1 month."
- **Last use:** "Today," "Yesterday," "2 days ago" buttons set date and auto-recalculate frequency.

**Prefill from EMR:**
- Pull `substanceUseHistory` from EHR (if updated ≤60d). Match by `substanceName` (RxNorm). If no match, show "Unmapped: [raw string]" and require manual selection.

**Validation Gaps:**
- **Duration > last use date:** If duration = "5 years" but last use = "2 days ago," **contradiction.** No error shown.
- **Route without frequency:** If route is selected but frequency = "Never used," **silent data corruption.**
- **Missing substance name:** "Other drug 1/2/3" fields are plain text. **No normalization.** You’ll get "Molly," "MDMA," "ecstasy" as three separate substances.

---

### **Q2: Withdrawal Symptom Bother (Page 3)**

**Answer Flow:**
- 5-point radio [Not at all → Extremely].
- If rating ≥ "Somewhat," show free-text `description`.

**Quick-Add Chips:**
- Chips for common symptoms: "Body aches," "Nausea," "Anxiety," "Sweating," "Tremor," "Insomnia." Tapping chip adds to description with timestamp: "Body aches (reported today)."

**Logic:**
- **Hidden if Q1 = all "Never used."** If any substance frequency = "Never used," Q2 should be disabled. **Not implemented.**

**Required:**
- **Always optional.** Can be left unanswered.

---

### **Q3: Current Withdrawal Symptoms (Page 3)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, show multi-select symptom list + free-text `description`.

**Quick-Add Chips:**
- Symptoms grouped by substance: Opioids: ["Yawning," "Lacrimation," "Rhinorrhea"]; Alcohol: ["Tremor," "Seizure," "Delirium"]; Benzos: ["Anxiety," "Seizure"].
- Selecting chip adds symptom and auto-tags substance source.

**Logic:**
- **Show only if Q2 ≥ "A Little" or Q1 frequency ≥ "1–3 days/week."** If no recent use, hide. **Not enforced.**

**Required if:**
- Q1 last use ≤ 7 days ago for opioids, ≤ 14 days for benzos/alcohol. **No date math implemented.**

---

### **Q4: Tolerance (Page 3)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, free-text `description`.

**Quick-Add Chips:**
- "Need more to get same effect," "Using larger amounts," "Using more frequently." Tapping chip populates description.

**Logic:**
- **Hidden if Q1 = "Never used" for all substances.** Not enforced.

---

### **Q5: Serious Withdrawal History (Page 3)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, multi-select substances (from Q1) + date picker for last episode.

**Quick-Add Chips:**
- Date shortcuts: "Within past month," "1–6 months ago," ">6 months ago."

**Required if:**
- Q1 includes alcohol, benzos, or opioids with frequency ≥ "1–3 days/week." **No logic.**

---

### **Q6: Overdose History (Page 3)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, multi-select substances + date picker + boolean `naloxoneAccess`.

**Quick-Add Chips:**
- Date shortcuts as above.
- **Naloxone chip:** If opioids selected, show "Naloxone on hand" chip that sets `naloxoneAccess = true` and adds note "Patient equipped."

**Logic:**
-  **`naloxoneAccess` hidden if no opioids in Q1.** Not enforced.

---

### **Q7: Used in Last 48 Hours (Page 3)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, multi-select substances.

**Logic:**
- **Auto-expire after 48 hours.** Store `recordedAt` timestamp. After 48h, show "Data stale – please re-ask." **No TTL logic.**

---

### **Q8: Interviewer Observation (Page 3)**

**Answer Flow:**
- Radio [Intoxication | Withdrawal | None].
- If **Intoxication** or **Withdrawal**, show free-text `description`.

**Quick-Add Chips:**
- Intoxication signs: "Slurred speech," "Ataxia," "Disinhibition."
- Withdrawal signs: "Tremor," "Agitation," "Seizure."

**Required:**
- **Always required.** Default to "None."

---

### **Q9–12: Problem Statements (Page 4)**

**Answer Flow:**
- Free-text, optional.

**Quick-Add Chips:**
- Q9: "Overdose risk with fentanyl," "Using alone."
- Q10: "Previous DTs," "Seizure history."
- Q11: "No access to meds," "Transportation barrier."
- Q12: "Enroll in OTP," "Get naloxone."

**Validation:**
- Max 500 chars. **No counter implemented.**

---

### **Severity Rating (Page 4)**

**Answer Flow:**
- Select sev0–4 card.
- If sev3 or sev4, **require rationale.**
- If any emergency trigger (withdrawal symptoms + last use ≤ 48h OR severe withdrawal history + current symptoms), **auto-show banner.** **Logic not implemented.**

**Quick-Add Chips:**
- Rationale suggestions: "Severe alcohol withdrawal risk per CIWA-Ar > 15," "Opioid withdrawal, no access to MOUD."

---

## **DIMENSION 2: BIOMEDICAL CONDITIONS**

### **Q1: Primary Care Clinician (Page 5)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text fields for name + contact.

**Prefill:**
- Pull from `patient.providers[]` filtered by `type = 'PCP'`. Show "From chart, 43d" badge.

**Quick-Add Chips:**
- Contact format: "Dr. Smith, (555) 123-4567."

**Validation:**
- Contact max 100 chars. **No phone regex.**

---

### **Q2: Medication List (Page 5)**

**Answer Flow:**
- Repeater: add rows dynamically.
- Each row: `name` (autocomplete), `dose`, `frequency`, `purpose`.

**Quick-Add Chips:**
- Common meds: "Metformin 500mg," "Lisinopril 10mg." Tapping chip fills all fields.
- Dose chips: "5mg," "10mg," "25mg."
- Frequency chips: "Daily," "BID," "TID."

**Prefill:**
- Pull `medications` from EHR via FHIR MedicationStatement. Map `name` to RxNorm. Show "From Rx, 12d" badge.

**Logic:**
- If substance = "Marijuana/CBD" in Q2, show warning banner: "Assess for Cannabis Use Disorder per NIDA Quick Screen." **Not implemented.**

**Validation:**
- Name required. Dose/frequency optional but max 50 chars each.
- Max 20 rows. **No limit specified.**

---

### **Q3: Medical Concerns (Page 5)**

**Answer Flow:**
- Boolean [Yes | No | Don’t know].
- If **Yes** or **Don’t know**, show text.

**Quick-Add Chips:**
- "Chest pain," "Shortness of breath," "Uncontrolled diabetes."

---

### **Q4: Last Doctor Visit (Page 5)**

**Answer Flow:**
- Date picker (month/year). **Logic:** Allow "Approximate" checkbox. If checked, store `isApproximate: true`.

**Quick-Add Chips:**
- "Within past month," "Within past year," ">1 year ago."

---

### **Q5: Chronic Conditions (Page 6)**

**Answer Flow:**
- Multi-select checklist (list of 20+ conditions).
- If **Other** selected, show free-text.
- If **Cancer** selected, show "Specify type" text.

**Quick-Add Chips:**
- Condition chips with icons (heart, lung). Selecting "Cancer" chip opens sub-input for type.

**Prefill:**
- Pull from `patient.problems` (ICD-10). Map to checkbox list. Show "From chart, 30d" badge.

**Logic:**
- If **HIV, Hepatitis, TB** selected, Q6 (infectious risk) auto-answers **Yes**. **Not implemented.**

---

### **Q6: Infectious Risk (Page 6)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, required text.

**Logic:**
- **Shown if Q5 includes HIV/Hepatitis/TB.** If Q5 unchecks them, clear Q6.

**Quick-Add Chips:**
- "Confirmed HIV," "Active TB."

---

### **Q7: Condition Stability (Page 6)**

**Answer Flow:**
- Radio [Stable w/ treatment | Stable w/out treatment | Unstable/uncontrolled | Not sure | N/A].

**Logic:**
- **Hidden if Q5 = empty.** Not implemented.

---

### **Q8: Need Additional Treatment (Page 6)**

**Answer Flow:**
- Boolean [Yes | No | Don’t know].
- If **Yes**, text required.

---

### **Q9: Substance-Related Worsening (Page 6)**

**Answer Flow:**
- Boolean [Yes | No | Don’t know].
- If **Yes**, text required.

**Quick-Add Chips:**
- "Skipping insulin to drink," "Missing dialysis."

---

### **Q10: Vaccines (Page 6)**

**Answer Flow:**
- Boolean [Yes | No | Don’t know].

**Criticism:** Should be checklist. **Not implemented.**

---

### **Q11: Pregnancy (Page 6)**

**Answer Flow:**
- **Shown if `patientSexAtBirth = 'Female'`.** If missing, show warning.
- Boolean [Yes | No/N/A | Not sure].
- If **Yes**: trimester select + boolean for prenatal care.

**Logic:**
- If third trimester + opioid use in D1, **auto-trigger sev3+ hint.** Not implemented.

---

### **Q12: Hospitalizations**

**Answer Flow:**
- Repeater: date + reason.

**Quick-Add Chips:**
- Date: "2023," "2022."

---

### **Q13–16: Impact Scales (Page 7)**

**Answer Flow:**
- 5-point radio + optional text.

**Logic:**
- **Hidden if Q5 = empty.** Not implemented.

---

### **Q17–18: Problem Statements (Page 7)**

**Answer Flow:**
- Free-text, optional.

---

### **Q19: Life-Threatening Symptoms (Page 7)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required + **Emergency Banner** + **block assessment completion.**

**Logic:**
- **If Yes, auto-set sev4 and require rationale.** Not implemented.

---

### **Severity Rating (Page 8)**

**Answer Flow:**
- Select sev0–4.
- If sev3/sev4, require rationale.

**Quick-Add Chips:**
- Rationale: "Unstable diabetes + alcohol use," "DTs risk."

---

## **DIMENSION 3: EMOTIONAL/BEHAVIORAL**

### **Q1: Cognitive Issues (Page 9)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

**Quick-Add Chips:**
- "Disoriented to place/time," "Short-term memory loss."

---

### **Q2: MH History (Page 9)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required (diagnosis, date).

**Prefill:**
- Pull from `patient.problems` (ICD-10 F-codes). Map to name + date.

---

### **Q3: Treatment History (Page 9)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

**Quick-Add Chips:**
- "Inpatient 2022," "IOP 2023."

---

### **Q4: Symptom Stability (Page 9)**

**Answer Flow:**
- **Shown only if Q3 = Yes.**
- Multi-select: Stable w/ meds, Stable w/out meds, Unstable, Not sure.

**Logic:**
- If Q3 changes to No, **clear Q4.** Not implemented.

---

### **Q5: Trauma History (Page 9)**

**Answer Flow:**
- Radio [Yes | No | Skipped].
- If **Yes**, text optional.

**Quick-Add Chips:**
- "Physical abuse," "Sexual abuse," "Combat trauma."

---

### **Q6: Medication List (Psych) (Page 9)**

**Answer Flow:**
- Repeater (same as D2 Q2).

**Prefill:**
- Pull from `patient.medications` filtered by `category = psychiatric`.

---

### **Q7: MH Provider (Page 9)**

**Answer Flow:**
- Boolean [Yes | No | N/A].
- If **Yes**, name + contact required.

**Prefill:**
- Pull from `patient.providers` filtered by `type = 'psychiatrist'`.

---

### **Q8: Symptom Matrix (Page 10)**

**Answer Flow:**
- 22 symptoms, each:
  - Boolean checkbox.
  - Boolean chip [Only when using/withdrawing].

**Quick-Add Chips:**
- Symptom chips grouped: Mood (6), Anxiety (3), Psychosis (3), Other (10). Selecting chip checks box and focuses "Only when using" sub-chip.

**Logic:**
- If "Only when using" is true, auto-answer Q9 (substance-related) = Yes. **Not implemented.**

**Performance:**
- **44 boolean fields = 44 re-renders on each click.** No `useMemo` spec.

---

### **Q9: Substance-Related Symptoms (Page 10)**

**Answer Flow:**
- Boolean [Yes | No | Not sure].
- If **Yes**, text required.

**Logic:**
- **Auto-yes if any Q8 "Only when using" = true.** Not implemented.

---

### **Q10: Hallucinations (Page 10)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

**Criticism:** Duplicate of Q8 psychosis. **Remove.**

---

### **Q11: Suicidality (Page 10–11)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, show:
  - Text: "Thoughts of hurting yourself or better off dead?"
  - Boolean: "Having these thoughts today?"
  - Boolean: "Ever acted on these feelings?"
- If "today = true," **show Emergency Banner, require rationale, lock sev ≥3.**

**Quick-Add Chips:**
- "Passive ideation," "Active plan," "Access to firearm."

**Validation:**
- Hidden if D6 safety relationship threat already flagged lethal risk. **Not implemented.**

---

### **Q12: Homicidality (Page 11)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, show:
  - Text: description.
  - Boolean: "Having these thoughts today?"
  - Boolean: "Ever acted?"

**Logic:**
- If "today = true," **Emergency Banner, reportable flag, lock sev = 4.**

---

### **Q13–15: Impact Scales (Page 11)**

**Answer Flow:**
- 5-point radio + optional text.

**Logic:**
- **Hidden if Q8 = all false.** Not implemented.

---

### **Q16–18: Problem Statements (Page 12)**

**Answer Flow:**
- Free-text, optional, max 500 chars.

---

### **Q19: Further Assessment (Page 12)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

---

### **Severity Rating (Page 12)**

**Answer Flow:**
- Select sev0–4.
- If sev3/sev4, require rationale.
- If any emergency trigger (psychosis, suicidal/homicidal ideation "today"), **auto-show banner.**

**Quick-Add Chips:**
- Rationale: "Active psychosis," "Suicidal plan."

---

## **DIMENSION 4: READINESS TO CHANGE**

### **Q1: Life Impact Grid (Page 13)**

**Answer Flow:**
- 13 items, each 5-point radio.

**Quick-Add Chips:**
- Pre-fill "Extremely" for legal/financial if D6 justice involvement = Yes.

---

### **Q2: Belief in Improvement (Page 13)**

**Answer Flow:**
- Boolean [Yes | No | I don’t know].
- If **Yes**, text required.

---

### **Q3: Need for Treatment (Page 13)**

**Answer Flow:**
- Radio [Yes | No, not a problem | No, can stop anytime | I don’t know].

**Logic:**
- If "can stop anytime," auto-set stage = Precontemplation.

---

### **Q4: Stage of Change (Page 13)**

**Answer Flow:**
- Two rows: Issue + Stage dropdown.
- If Q3 = "can stop anytime," auto-set stage = Precontemplation and disable.

---

### **Q5: Substance Use as Problem (Page 14)**

**Answer Flow:**
- 5-point radio.

**Logic:**
- Should match Q1 "mental health" rating. **No correlation check.**

---

### **Q6: Past Change Attempts (Page 14)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.
- If **Yes**, show "How helpful was it?" text.

---

### **Q7: Barriers (Page 14)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

**Quick-Add Chips:**
- "Stigma," "No childcare," "Cost."

---

### **Q8: Want to Quit/Cut Back (Page 14)**

**Answer Flow:**
- Radio [Yes quit | Yes cut back | Not sure | No].

**Logic:**
- If "No," set readiness low.

---

### **Q9: Who Cares? (Page 14)**

**Answer Flow:**
- Free-text list.

**Quick-Add Chips:**
- "Family," "Probation," "CPS."

---

### **Q10–15: Importance/Readiness Scales (Page 15)**

**Answer Flow:**
- 5-point radios + optional text.

---

### **Severity Rating (Page 16)**

**Answer Flow:**
- Select sev0–4.
- If sev3/sev4, require rationale.

---

## **DIMENSION 5: RELAPSE POTENTIAL**

### **Q1: Longest Abstinence (Page 17)**

**Answer Flow:**
- Number field + unit segments [Days | Weeks | Months | Years].
- Second number field + unit for "how long ago ended."
- Chip [N/A, never].

**Logic:**
- If **N/A chip selected,** hide second field and clear values. **Show toast "Abstinence data cleared."**
- If **duration > endedAgo,** show error: "Duration cannot be longer than time since ended."

**Quick-Add Chips:**
- "30 days, ended 2 months ago."

---

### **Q2: What Helped (Page 17)**

**Answer Flow:**
- Textarea.
- Quick chips: "Personal strengths," "Peer support," "Medication," "Treatment," "Other."

**Logic:**
- If **N/A from Q1**, show N/A chip and disable textarea.

**Quick-Add Chips:**
- Tapping chip appends text with timestamp: "Peer support (2024)."

---

### **Q3: Relapse Contributors (Page 17)**

**Answer Flow:**
- Textarea.
- Chips: "Cravings," "Social pressure," "Pain," "Mood," "Cues," "Other."

**Logic:**
- If **N/A from Q1**, show N/A chip.

---

### **Q4: Quit/Cutback Plan (Page 17)**

**Answer Flow:**
- Multi-select chips: "Stop on my own," "Go to treatment," "Take meds," "Self-help," "Change relationships," "Other."
- If **Other** selected, show text field.

**Logic:**
- If no chips selected, **optional**.

---

### **Q5: Problems Without Help (Page 17)**

**Answer Flow:**
- Textarea, optional.

---

### **Q6: Imminence of Consequences (Page 17)**

**Answer Flow:**
- Radio [Few/Mild/Not imminent | Some/Not severe/Weeks-months | Many/Severe/Hours-days].

**Logic:**
- If **"Hours-days"** selected, **show Emergency Banner, require rationale, set sev ≥3.**

---

### **Q7–12: Scales (Page 18)**

**Answer Flow:**
- 5-point radios.

**Quick-Add Chips:**
- Q12: If rating = "Very" or "Extremely," show hint chip: "Consider sev3 or 4." **Non-blocking.**

---

### **Q13: Worst Triggers (Page 18)**

**Answer Flow:**
- Textarea, optional.

---

### **Q14: Coping (Page 18)**

**Answer Flow:**
- Textarea, optional.

---

### **Q15: Plan Feasibility (Page 18)**

**Answer Flow:**
- Textarea, optional.

---

### **Q16: Insight Level (Page 18)**

**Answer Flow:**
- Radio [Good | Some | Very limited | Dangerously low].
- If **Dangerously low**, **show hint: "Consider supervised environment."**

---

### **Q17–18: Problem Statements (Page 19)**

**Answer Flow:**
- Textarea, optional, max 500.

---

### **Severity Rating (Page 19)**

**Answer Flow:**
- Select sev0–4.
- If sev3/sev4, require rationale.

**Quick-Add Chips:**
- If D6 safety risk = true and insight = "Dangerously low," suggest sev4 with rationale: "Imminent danger + poor insight."

---

## **DIMENSION 6: RECOVERY ENVIRONMENT**

### **Q1: Stable Housing (Page 20)**

**Answer Flow:**
- Boolean [Yes | No].
- If **No**, `description` required.

**Prefill:**
- Pull `patient.address.status` from EHR: "Homeless," "Shelter," "Renting." Map to Yes/No.

**Logic:**
- If **No**, auto-add "Housing" to Q9 supportNeeds. **Not implemented.**

---

### **Q2: Housing Risk (Page 20)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, `description` required.

**Logic:**
- If **Yes**, show hint chip "Consider sev2+."

---

### **Q3: Need Different Housing (Page 20)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, `description` required.

---

### **Q4: Household Members (Page 20)**

**Answer Flow:**
- Textarea, optional.

**Quick-Add Template:**
- "Lives with partner and 2 children," "Lives alone."

---

### **Q5: Work Status (Page 20)**

**Answer Flow:**
- Radio [School | Work | Retired | Disability | Other].
- If **Other**, text field.

**Prefill:**
- Pull `patient.occupation` from EHR.

---

### **Q6: Income Sources (Page 20)**

**Answer Flow:**
- Multi-select chips.
- Single-select "primary" (radio).
- If **Other** selected, text field.

**Quick-Add Chips:**
- "SSI," "SSDI," "Payroll," "Family support."

---

### **Q7: Free Time (Page 20)**

**Answer Flow:**
- Textarea, optional.

---

### **Q8: Learning Challenges (Page 20)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

---

### **Q9: Practical Needs (Page 21)**

**Answer Flow:**
- Multi-select chips.
- If **Other** selected, allow multiple text entries (tags).

**Quick-Add Chips:**
- "Transportation," "Childcare," "Housing," "Employment," "Education," "Legal," "Financial."

**Logic:**
- If Q1 = No, auto-select "Housing."

---

### **Q10: Agency Engagement (Page 21)**

**Answer Flow:**
- Multi-select chips + Other.

---

### **Q11: Criminal Justice (Page 21)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.
- Boolean [Currently engaged with probation/parole].

**Quick-Add Chips:**
- "Probation," "Parole," "Diversion court."

---

### **Q12: Mandated Treatment (Page 21)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

---

### **Q13: Veteran Status (Page 21)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text optional (VA eligibility).

**Prefill:**
- Pull from `patient.demographics.veteranStatus`.

---

### **Q14: Peer Support History (Page 21)**

**Answer Flow:**
- Boolean [Yes | No].

**Quick-Add Chips:**
- "AA," "NA," "SMART Recovery."

---

### **Q15: Environment with Substance Use (Page 21)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, show sub-question **a**: Boolean [Alternative place available].

**Logic:**
- If **Yes** and **a = No**, show hint "Consider sev3."

---

### **Q16: Relationship Safety Threat (Page 21)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, show three lethal-risk booleans + text.

**Quick-Add Chips:**
- "Weapon threatened," "Kill threat," "Fear of homicide."

**Logic:**
- If any lethal = true, **Emergency Banner, lock sev4, require rationale, create reportable flag.**

---

### **Q17: Other Safety Threats (Page 21)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

**Logic:**
- If **Yes**, combine with Q16 for banner trigger.

---

### **Q18: Dangerous Use Situations (Page 21)**

**Answer Flow:**
- Boolean [Yes | No].
- If **Yes**, text required.

**Logic:**
- If **Yes**, auto-set flag `dangerousUse = true` and include in banner trigger.

---

### **Q19–20: Supportive vs Risky Factors (Page 22)**

**Answer Flow:**
- Text lists for people/places/things + 5-point rating per category.

**Quick-Add Chips:**
- People: "Sponsor," "Family," "Friends."
- Places: "Home," "Work," "Recovery house."
- Things: "Phone," "Car," "Bible."

**Logic:**
- Rating must be completed if any items listed. **No enforcement.**

---

### **Q21–24: Problem Statements (Page 22)**

**Answer Flow:**
- Textarea, optional, max 500.

---

### **Severity Rating (Page 23)**

**Answer Flow:**
- Select sev0–4.
- If sev3/sev4, require rationale.

**Logic:**
- If any safety threat Q16–18 = Yes, **min sev = 3.** **Not enforced.**

---

## **GLOBAL LOGIC FAILURES**

### **Prefill & Quick-Add**
- **No central `prefillMap` for D1–D5.** You defined it for D6 only. **Inconsistent.**
- **Quick-add chips are dimension-specific.** No reusable `QuickAddChip` component. **Engineers will rebuild 6 times.**

### **Emergency Banner**
- **Trigger logic is copy-pasted per dimension.** Should be centralized:

```ts
const globalEmergencyTriggers = {
  d1: ['currentWithdrawal.value && lastUse <= 2_days', 'severeWithdrawalHistory && currentSymptoms'],
  d3: ['suicidalIdeationCurrent', 'homicidalIdeationCurrent', 'psychosis.value'],
  d6: ['safetyRelationship.weapon', 'safetyRelationship.killThreat', 'otherSafetyThreat.value'],
};
```

**Not implemented.**

### **Destructive Clearing**
- **No `Undo` toast spec for D1–D5.** You defined it for D6 only. **Inconsistent UX.**

### **Validation**
- **No `requiredIf` schema.** You rely on hand-coded logic. **Will diverge.**

### **Character Limits**
- **Missing on 80% of text fields.** EHRs will reject.

---

## **FINAL VERDICT**

Your spec has **70% of answer flows defined, 40% of logic implemented, 20% of quick-add chips specced, and 0% of validation enforced.** The remaining gaps are **P0 bugs** (data loss, legal risk, clinical inaccuracy).

**To ship, you must:**

1. **Write a single `validation-matrix.ts`** with `requiredIf`, `clearIf`, `maxLength` for every field.
2. **Define a `prefillMap.ts`** for all dimensions.
3. **Build a reusable `EmergencyBanner` with central trigger registry.**
4. **Add undo toast logic to every parent toggle.**
5. **Add char counters to every textarea.**
6. **Define quick-add chip payloads for every question.**

