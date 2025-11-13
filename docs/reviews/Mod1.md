Here is a **hypercritical, blow-by-blow teardown** of every question in the ASAM Criteria Assessment Form, exposing the implementation landmines, contradictions, and silent failures that will torpedo your build.

---

## **DIMENSION 1: ACUTE INTOXICATION OR WITHDRAWAL POTENTIAL**

### **Question 1: Substance Use Grid**
**Field:** `d1.substances[].{name, durationYears, durationMonths, frequency, route, lastUseDate, avgDrinks, bingeFrequency, prescriptionValid}`

**Criticism:**
- **Data model is a denormalized nightmare.** You’re cramming 8 substance types (alcohol, heroin, benzos, cocaine, etc.) into a single array with heterogeneous fields. Alcohol has `avgDrinks` and `bingeFrequency`; opioids have `prescriptionValid`; "Other" is a repeating group. This guarantees `undefined` pollution in your database.
- **Date validation is vaporware.** `lastUseDate` is a string with no format enforcement. "Yesterday" is a valid input. So is "2025-13-45". 
- **Route is a multi-select enum**, but the paper form shows checkboxes without mutual exclusion. You’ll get users selecting "Inject" + "Oral" for heroin and "Never Used" simultaneously. No validation prevents mutually exclusive combos.
- **Binge frequency is gendered** ("4+ for females, 5+ for males") but you have no `patientSexAtBirth` field on this screen. You’ll calculate it incorrectly or not at all.
- **Duration fields are split** (Years + Months) but the paper form says "Estimate Years and/or Months". Users will enter "6 months" in the years field. **No input masking, no coercion logic.**
- **`prescriptionValid` is a boolean**, but the question asks "Were these medications from a valid prescription?" The answer should be a tristate: Yes/No/Unknown. You’ve forced a false binary and lost clinical nuance.

**Implementation bomb:** When you prefill from EHR, `lastUseDate` will be an ISO string, but manual entry is free-text. Your serializer will crash on `new Date("Yesterday")`.

---

### **Question 2: Withdrawal Symptom Bother**
**Field:** `d1.withdrawalBother.rating` (0-4 Likert), `d1.withdrawalBother.note`

**Criticism:**
- **Substance-specific context is missing.** The question asks about "physical or emotional symptoms when you stop or reduce," but you don’t store *which* substance. A patient using alcohol + benzos has different withdrawal profiles, but you’re aggregating into one rating. Clinical garbage.
- **The note field `d1.withdrawalBother.note` is a string with no char limit.** Users will paste War & Peace. EHRs will reject >500 chars and you’ll lose data on save.
- **No validation ties this to Q1.** If Q1 shows "Never Used" for all substances, this question should be hidden. You’ll ask about withdrawal from substances they don’t use, confusing users and corrupting data.

---

### **Question 3: Current Withdrawal Symptoms**
**Field:** `d1.currentWithdrawal.value`, `d1.currentWithdrawal.symptoms[]`, `d1.currentWithdrawal.description`

**Criticism:**
- **"Please describe" is a free-text bomb.** No validation against a controlled symptom list. Users will type "feeling weird." No SNOMED-CT coding, no structured data.
- **The array `symptoms[]` is undefined.** Do you store ["tremor", "sweating"] or [{id: "tremor", observed: true}]? You’ve left the schema blank.
- **No timestamp.** If a user says "Yes, experiencing withdrawal," you don’t capture *when* they reported it. On autosave retry, you’ll show stale withdrawal status from 3 hours ago.

---

### **Question 4: Tolerance**
**Field:** `d1.tolerance.value`, `d1.tolerance.description`

**Criticism:**
-  **"Please describe" is lazy.** This should be a structured list of substances with increased dose/frequency. Instead, you’ve got one blob of text that can’t be trended or reported.
- **No min/max dates.** If they describe a pattern from "last year," you can’t differentiate acute vs chronic risk.

---

### **Question 5: Serious Withdrawal History**
**Field:** `d1.severeWithdrawalHistory.value`, `d1.severeWithdrawalHistory.substances[]`, `d1.severeWithdrawalHistory.lastEpisodeDate`

**Criticism:**
-  **`substances[]` is a free-text array.** No linking to Q1’s substance list. You’ll get "heroin" vs "HEROIN" vs "dope" in three different records. No normalization.
-  **`lastEpisodeDate` is a string.** No date picker, no validation. Users will type "2023." 
- **No severity scale.** "Serious withdrawal" is binary. The real world has gradations (seizure vs DTs vs insomnia). You’ve lost granularity.

---

### **Question 6: Overdose History**
**Field:** `d1.overdoseHistory.value`, `d1.overdoseHistory.substances[]`, `d1.overdoseHistory.lastOverdoseDate`, `d1.overdoseHistory.naloxoneAccess`

**Criticism:**
-  **`naloxoneAccess` is a boolean.** The question is "If opioids - Do you have access to naloxone?" If the patient used opioids in the past but not now, you still show this field. No conditional logic.
-  **`lastOverdoseDate` is a string.** Same validation hell as above.

---

### **Question 7: Used in Last 48 Hours**
**Field:** `d1.usedLast48h.value`, `d1.usedLast48h.substances[]`

**Criticism:**
- **Time decay is not implemented.** This is only valid for 48 hours. After 2 days, the answer is stale, but you’ll keep it in the record. You need a TTL field or automatic invalidation.

---

### **Question 8: Interviewer Observation (Intoxication/Withdrawal)**
**Field:** `d1.interviewerObservation.value` (enum: Intoxication/Withdrawal/None), `d1.interviewerObservation.description`

**Criticism:**
- **The enum is a radio group, but "None" is first.** Users will accidentally select "None" and skip describing severe intoxication. **Order should be Intoxication/Withdrawal/None**, with "None" last.
- **No severity scale.** "Intoxication" could be mild buzz vs unconscious. No granularity.

---

### **Questions 9–12: Problem Statements**
**Fields:** `d1.problems.overdoseRisk`, `d1.problems.withdrawalRisk`, `d1.problems.medicationAccess`, `d1.goals.withdrawalManagement`

**Criticism:**
- **These are optional, but you’re not storing a `isCompleted` flag.** You can’t distinguish "user skipped" from "user hasn’t gotten there yet." Your progress bar will lie.

---

### **Severity Rating Block (0–4)**

**Criticism:**
-  **"For guidance assessing risk, please see Risk Rating Matrices"**  — you’ve punted the entire clinical decision to an external PDF. **No algorithmic logic** ties Q1–Q8 to the severity selection. Users will guess, and you’ll have no audit trail for *why* they chose sev3 vs sev2.
- **The bullet text is incomplete.** The paper form has more nuanced bullets for each level, but your spec only shows a summary. **You must include the full text verbatim** or you’re not ASAM-compliant.

---

## **DIMENSION 2: BIOMEDICAL CONDITIONS AND COMPLICATIONS**

### **Question 1: Primary Care Clinician**
**Field:** `d2.hasPrimaryCare.value`, `d2.primaryCareName`, `d2.primaryCareContact`

**Criticism:**
- **Contact fields are free-text.** No validation for phone/email format. You’ll get "Dr. Smith, 555-1234" in the same field as "call the clinic."
- **No deduplication.** If the primary care clinician is also the MH provider from D3, you’ll store duplicate contacts. Should be a shared `clinicians[]` array.

---

### **Question 2: Medication List**
**Field:** `d2.medications[].{name, dose, frequency, purpose, prefill}`

**Criticism:**
- **Purpose is free-text.** No SNOMED-CT or RxNorm codes. No interoperability.
- **No interaction checking.** The form warns about drug interactions (e.g., opioids for pain in OUD patient), but you’ve built no logic to flag this. It’s a dead warning.
- **No max items.** A polypharmacy patient could have 50 meds. Your UI will scroll forever. **Paginate or cap at 20.**

---

### **Question 3: Medical Concerns**
**Field:** `d2.medicalConcerns.value`, `d2.medicalConcerns.description`

**Criticism:**
- **"Don't know" is a third state** but you’ve modeled it as `value: 'Yes' | 'No'`. Add `'Unknown'`.

---

### **Question 4: Last Doctor Visit**
**Field:** `d2.lastDoctorVisit.date`, `d2.lastDoctorVisit.reason`

**Criticism:**
-  **`date` is a string.** No validation, no "approximate" flag. Users will type "2021-ish." 
- **No "never" option.** The paper form allows "don't remember," but your schema doesn't.

---

### **Question 5: Chronic Conditions Checklist**
**Field:** `d2.chronicConditions[]` (enum array)

**Criticism:**
- **The list is incomplete.** "Other: Cancer (specify type)" is in the paper form, but you have no `d2.chronicConditionsOther.text[]` to capture multiple cancers.
- **No severity for each condition.** "Diabetes" could be well-controlled or ketoacidosis. You’re flattening critical nuance.

---

### **Question 6: Infectious Risk**
**Field:** `d2.infectiousRisk.value`, `d2.infectiousRisk.description`

**Criticism:**
- **Should require staff confirmation.** The form says "Seek medical consultation if unsure," but you’ve built no workflow to block submission pending consult.

---

### **Question 7: Condition Stability**
**Field:** `d2.conditionStability.value` (enum: Stable/Unstable/N/A)

**Criticism:**
- **"Stable with treatment" and "Stable without treatment" are both missing.** The paper form has 4 options; you have 3. **Data loss.**

---

### **Question 8: Need for Additional Treatment**
**Field:** `d2.additionalTreatment.value`, `d2.additionalTreatment.description`

**Criticism:**
- **"Don’t know" is a third state** but not in your enum.

---

### **Question 9: Substance-Related Worsening**
**Field:** `d2.substanceWorsening.value`, `d2.substanceWorsening.description`

**Criticism:**
-  **`description` is a blob.** Should be a list of condition-substance pairs. Instead, you’ll get "pain pills make my back worse" with no structure.

---

### **Question 10: Vaccines**
**Field:** `d2.vaccines.upToDate` (boolean)

**Criticism:**
- **Should be a checklist** (COVID, Flu, HepB, etc.). A single boolean loses compliance tracking for TB outbreaks.

---

### **Question 11: Pregnancy**
**Field:** `d2.pregnancy.isPregnant`, `d2.pregnancy.trimester`, `d2.pregnancy.careReceived`

**Criticism:**
-  **"If female sex at birth"**  — you don’t capture sex at birth anywhere else. Add `patientSexAtBirth` to demographics.
-  **`trimester` is an enum**  , but weeks are numeric. If she says "week 15," you force "2nd." Loss of precision.
- **No gestational age field.** Critical for opioid withdrawal risk.

---

### **Question 12: Prior Hospitalizations**
**Field:** `d2.hospitalizations[].{date, reason}`

**Criticism:**
-  **`date` is a string.** No validation. Users will type "2020."
- **No max length on reason.** EHRs will truncate.

---

### **Severity Rating Block**
**Criticism:**
- **Bullet text is truncated in your spec.** The paper form has more detail (e.g., "Unstable condition with severe medical problems, **including but not limited to: Emergent chest pain, DTs, unstable pregnancy**"). You must include the full list or you’re not clinically accurate.

---

## **DIMENSION 3: EMOTIONAL, BEHAVIORAL, OR COGNITIVE CONDITIONS**

### **Question 1: Cognitive Issues**
**Field:** `d3.cognitiveIssues.value`, `d3.cognitiveIssues.description`

**Criticism:**
- **No differentiation between disorientation and memory issues.** These are separate clinical flags. You’ve collapsed them into one boolean.

---

### **Question 2: Mental Health History**
**Field:** `d3.mhHistory.value`, `d3.mhHistory.description`

**Criticism:**
- **"Brain injury" is folded in** but has different implications (e.g., cognitive rehab vs therapy). No sub-field to capture TBI severity.

---

### **Question 3: Treatment History**
**Field:** `d3.mhTreatmentHistory.value`, `d3.mhTreatmentHistory.description`

**Criticism:**
-  **`description` is a blob.** Should be structured: setting, dates, outcomes. You’ll get "hospitalized in 2020, didn’t help" with no parseability.

---

### **Question 4: Symptom Stability**
**Field:** `d3.mhStability[]` (multi-select enum)

**Criticism:**
- **Shown only if Q3 is Yes, but you have no `hideIf` logic in schema.** You’ll store `mhStability` for patients who never had treatment, corrupting data.

---

### **Question 5: Trauma History**
**Field:** `d3.traumaHistory.value` (Yes/No/Skipped), `d3.traumaHistory.note`

**Criticism:**
-  **"Skipped" is a third state**  , but your boolean logic treats it as `null`. **The UI needs a "Prefer not to answer" chip that sets `value: 'Skipped'`.**

---

### **Question 6: Medication List (Psychiatric)**
**Field:** `d3.medicationsPsy[]` (same structure as D2 meds)

**Criticism:**
-  **`d3.medicationsPsy` vs `d2.medications` are separate arrays.** If a med treats both depression and pain (e.g., duloxetine), you’ll have duplicate entries. No deduplication logic.

---

### **Question 7: MH Provider**
**Field:** `d3.hasMhProvider.value`, `d3.mhProviderName`, `d3.mhProviderContact`

**Criticism:**
- **Same dedupe issue as D2 Q1.** No shared clinician registry.

---

### **Question 8: Symptom Matrix**
**Field:** `d3.symptoms.{depression, anhedonia, hopelessness, ...}.value` (boolean), `d3.symptoms.{...}.substanceRelated` (boolean)

**Criticism:**
- **22 symptoms * 2 fields = 44 keys.** Your form state will be enormous. No virtualization = lag on low-end devices.
- **"Interviewer observation" is a separate boolean for some symptoms** (e.g., pressured speech) but not others. Inconsistent pattern.
- **No severity rating per symptom.** A checkbox for "depression" doesn't capture if it’s mild or severe. **Clinical noise.**

---

### **Question 9: Substance-Related Symptoms**
**Field:** `d3.symptomsSubstanceRelated.value`, `d3.symptomsSubstanceRelated.description`

**Criticism:**
- **Should be calculated, not asked.** If any `symptom.substanceRelated == true`, this is automatically Yes. Asking it again invites contradiction.

---

### **Question 10: Hallucinations**
**Field:** `d3.hallucinations.value`, `d3.hallucinations.description`

**Criticism:**
- **Duplicate of `d3.symptoms.psychosis.hallucinations`.** You’re asking the same question twice. Data will conflict.

---

### **Question 11: Suicidality**
**Field:** `d3.suicidalIdeation.value`, `d3.suicidalIdeation.description`, `d3.suicidalIdeationCurrent`, `d3.suicidalIdeationHistory`

**Criticism:**
- **"Have you had thoughts... Please describe" is a blob.** Should be separate fields: plan, intent, means, timeframe.
- **`suicidalIdeationCurrent` is a boolean.** The paper form asks "Are you having these thoughts today?" This should be a severity 0–4 scale, not yes/no.
- **No "access to means" field.** The interviewer note says "assess firearm access," but you have no `d3.suicidalIdeation.accessToMeans` key. **This is a lethal omission.**
- **Emergency trigger logic is incomplete.** If `suicidalIdeationCurrent == true`, you must show banner, but you also need to check `suicidalIdeation.plan == "yes"` for imminent risk. **Missing nested logic.**

---

### **Question 12: Homicidality**
**Field:** `d3.homicidalIdeation.value`, `d3.homicidalIdeation.description`, `d3.homicidalIdeationCurrent`, `d3.homicidalIdeationHistory`

**Criticism:**
- **Same issues as suicidality.** No target, means, or imminence fields.
- **No legal reportability flag.** If target is a child, you must trigger mandatory reporting. No `d3.homicidalIdeation.targetAge` field.

---

### **Questions 13–15: Impact Scales**
**Field:** `d3.impactSelfCare.rating`, `d3.impactWorkSchool.rating`, `d3.impactTreatment.rating`

**Criticism:**
- **"Not applicable" is a fifth option** but you only model 0–4. Add `null` for N/A.
- **No conditional show.** If all symptoms are unchecked, these questions should be hidden.

---

### **Questions 16–18: Problem Statements**
**Field:** `d3.problemStatement`, `d3.concernsAboutTreatment`, `d3.mhGoals`

**Criticism:**
-  **`concernsAboutTreatment` is a blob.** Should be a checklist (cost, stigma, side effects). You’ll get unstructured text that can’t drive care planning.

---

### **Question 19: Further Assessment**
**Field:** `d3.furtherAssessment.value`, `d3.furtherAssessment.description`

**Criticism:**
-  **`description` is required if Yes, but you have no `requiredIf` rule.** Users can skip it, and validation won’t catch it.

---

### **Severity Rating Block**
**Criticism:**
- **"Imminent danger to self/others" is listed in sev4 bullets, but you have no imminence field.** If danger is not imminent, you can’t differentiate sev3 vs sev4. **Missing `d3.dangerImminence` enum.**

---

## **DIMENSION 4: READINESS TO CHANGE**

### **Question 1: Life Impact Grid**
**Field:** `d4.impactAreas.{work, school, mentalHealth, ...}.rating` (0–4)

**Criticism:**
- **13 impact areas * 1 rating = 13 keys.** No reuse of D3 symptom matrix component.
- **"Other" is free-text.** No `d4.impactAreas.other.text` field. You’ll lose the "Other" description.

---

### **Question 2: Belief in Improvement**
**Field:** `d4.beliefInImprovement.value`, `d4.beliefInImprovement.description`

**Criticism:**
- **"Please describe" is required if Yes, but no rule enforces it.** Silent data loss.

---

### **Question 3: Need for Treatment**
**Field:** `d4.needForTreatment.value` (enum: Yes/No/CanStopAnytime/Unknown)

**Criticism:**
-  **"No, I can stop anytime without help"**  — this is a precontemplation marker, but you’re storing it as a string instead of a stage-of-change enum. **No mapping to D4 severity.**

---

### **Question 4: Stage of Change**
**Field:** `d4.stageOfChange.{issue1, issue2}.value` (enum: Precontemplation/Contemplation/Preparation/Action/Maintenance)

**Criticism:**
-  **`issue1` and `issue2` are free-text.** No predefined list (SUD, MH, Legal, etc.). You’ll get "my job" vs "employment" vs "work stress" — ungroupable.
- **No validation that issue2 is different from issue1.** Users can select the same issue twice.

---

### **Question 5: Substance Use as a Problem**
**Field:** `d4.substanceProblemRating.rating`, `d4.substanceProblemRating.description`

**Criticism:**
- **Duplicate of Q1's "mental health" rating.** You’re double-asking.

---

### **Question 6: Past Change Attempts**
**Field:** `d4.pastAttempts.value`, `d4.pastAttempts.description`

**Criticism:**
-  **`description` is a blob.** Should structure: methods, dates, outcomes.

---

### **Question 7: Barriers to Treatment**
**Field:** `d4.treatmentBarriers.value`, `d4.treatmentBarriers.description`

**Criticism:**
-  **`description` is a blob.** Should be a checklist (stigma, cost, childcare). You’re forcing users into an essay.

---

### **Questions 8–14: Importance/Readiness Scales**
**Field:** `d4.importanceOfChange.rating`, `d4.readinessToStop.rating`, `d4.importanceOfTreatment.rating`

**Criticism:**
-  **"Please describe" fields are optional blobs.** No enforcement that description length matches rating severity. A user can rate "Extremely" and type "idk."

---

### **Severity Rating Block**
**Criticism:**
- **Bullet text is incomplete.** Missing key phrases like "Engaging in potentially dangerous behavior" for sev4. **Not ASAM-compliant.**

---

## **DIMENSION 5: RELAPSE POTENTIAL**

### **Question 1: Longest Abstinence**
**Field:** `d5.longestAbstinence.duration`, `d5.longestAbstinence.unit`, `d5.longestAbstinence.endedAgo`, `d5.longestAbstinence.endedUnit`, `d5.neverInRecovery`

**Criticism:**
- **Unit conversion logic is missing.** If they say "6 months" and later "3 months," you can’t sum them programmatically. **No `totalDaysAbstinent` computed field.**
-  **`neverInRecovery` is a boolean that hides Q1a/b.** When toggled, you must clear `duration` and `endedAgo`. You have no `clearOnEnable` rule.

---

### **Question 2: What Helped**
**Field:** `d5.helpedFactors.text`, `d5.helpedFactors.chips[]`

**Criticism:**
- **Chip list is undefined.** What chips? "Personal strengths, Peer support, Medication"? You never listed them. **Engineers will invent their own.**
- **No max chips.** Users could add 50 "Other" chips. No limit.

---

### **Question 3: Relapse Contributors**
**Field:** `d5.relapseContributors.text`, `d5.relapseContributors.chips[]`

**Criticism:**
- **Same chip problem as Q2.** Undefined list.

---

### **Question 4: Quit/Cutback Plan**
**Field:** `d5.planActions[]`, `d5.planOther.text`

**Criticism:**
-  **`planActions` is a multi-select enum**  , but you haven’t defined the options: ["Stop on my own", "Go to treatment", "Take medications", "Attend self-help", "Change relationships", "Other"]. **Missing in spec.**
- **When "Other" is selected, `planOther.text` is required.** No validation rule.

---

### **Question 5: Problems Without Help**
**Field:** `d5.problemsIfNoHelp.text`

**Criticism:**
- **No min length.** Users can type "none." No clinical utility.

---

### **Question 6: Imminence of Consequences**
**Field:** `d5.imminenceRating.value` (enum: Few/Some/Many), `d5.imminenceRating.description`

**Criticism:**
-  **"Many/Severe consequences/Imminent within hours or days"**  — this should trigger the EmergencyBanner, but you have no `d5.emergencyTriggeredBy` rule.

---

### **Questions 7–12: Self-Report Scales**
**Field:** `d5.scales.{cravings, socialPressure, emotions, finances, health, likelihood}.rating`

**Criticism:**
- **"Not applicable" is missing** for Q12 ("Likelihood of relapse"). Add `null` state.
- **No correlation logic.** If `likelihood.rating === 5` (Extremely likely), you should hint sev3/sev4. You have no auto-hint.

---

### **Questions 13–15: Triggers and Coping**
**Field:** `d5.triggers.text`, `d5.coping.text`, `d5.planFeasibility.text`

**Criticism:**
-  **`text` fields are unbounded.** No char limit. **EHR rejection risk.**
-  **`d5.planFeasibility.text` is named inconsistently.** The paper says "Do you feel like you have a good plan and ability?" Your key `planFeasibility` is ambiguous.

---

### **Question 16: Insight Level**
**Field:** `d5.insightLevel.value` (enum: Good/Some/Very limited/Dangerously low), `d5.insightLevel.description`

**Criticism:**
- **"Dangerously low insight" should trigger EmergencyBanner.** No trigger defined.

---

### **Questions 17–18: Problem Statements**
**Field:** `d5.problems.text`, `d5.goals.text`

**Criticism:**
- **Unbounded text.** No char limit.

---

### **Severity Rating Block**
**Criticism:**
- **"For acute cases, need for 24-hour clinically managed living environment"** vs **"For chronic cases... need 24-hour supportive living environment"** — you have no `d5.acuteVsChronic` flag to differentiate. **The bullet is clinically ambiguous.**

---

## **DIMENSION 6: RECOVERY/LIVING ENVIRONMENT**

### **Question 1: Stable Housing**
**Field:** `d6.stableHousing.value`, `d6.stableHousing.description`

**Criticism:**
-  **"Negative response indicates homelessness"**  — but you don’t auto-set `d6.homelessnessStatus` or trigger housing support referrals. **The logic is implied, not implemented.**

---

### **Question 2: Housing Risk**
**Field:** `d6.housingRisk.value`, `d6.housingRisk.description`

**Criticism:**
- **Positive response shows "risk of homelessness" but you have no `d6.housingRiskLevel` enum** (Low/Medium/High). No prioritization for housing workers.

---

### **Question 3: Need Different Housing**
**Field:** `d6.differentHousingNeeded.value`, `d6.differentHousingNeeded.description`

**Criticism:**
-  **`description` is required if Yes, but no rule.** Silent validation gap.

---

### **Question 4: Household Members**
**Field:** `d6.household.text`

**Criticism:**
-  **`text` is a blob.** Should be structured: relationship, age, substance use status. You’ll get "mom, sis, friend" with no parseability.

---

### **Question 5: Work Status**
**Field:** `d6.workStatus.value`, `d6.workStatus.description`

**Criticism:**
-  **"Other" is free-text.** No sub-questions for "Other: Disabled" (e.g., SSDI status, disability type). **Missed eligibility screening.**

---

### **Question 6: Income Sources**
**Field:** `d6.incomeSources.values[]`, `d6.incomeSources.primary`

**Criticism:**
-  **`values[]` is an enum array**  , but "Illegal/Under the table" is included. **You’re asking patients to self-incriminate with no legal shield.** Need a "Prefer not to answer" option.
-  **`primary` is a string, not an enum.** Users will type "Job" when the array has "Paid work." **Data inconsistency.**

---

### **Question 7: Free Time**
**Field:** `d6.freeTime.text`

**Criticism:**
- **Unbounded text.** No char limit. No "None" option.

---

### **Question 8: Learning Challenges**
**Field:** `d6.learningSupports.value`, `d6.learningSupports.description`

**Criticism:**
-  **`description` is required if Yes, but no rule.** Validation gap.

---

### **Question 9: Practical Needs**
**Field:** `d6.supportNeeds[]`, `d6.supportNeedsOther[]`

**Criticism:**
-  **`supportNeedsOther[]` is a string array.** No linking to which "Other" chip was selected. You can’t distinguish "Other: Legal" from "Other: Internet."

---

### **Question 10: Agency Engagement**
**Field:** `d6.agencyEngagement[]`, `d6.agencyEngagementOther[]`

**Criticism:**
- **Same "Other" problem as Q9.** No linking.

---

### **Question 11: Criminal Justice**
**Field:** `d6.justiceInvolvement.value`, `d6.justiceInvolvement.description`, `d6.currentSupervision.value`

**Criticism:**
-  **`description` is a blob.** Should be structured: charges, dates, status (probation/parole/diversion).
-  **`currentSupervision` is a boolean.** Should be enum: Probation/Parole/Diversion/None.

---

### **Question 12: Mandated Treatment**
**Field:** `d6.mandatedTreatment.value`, `d6.mandatedTreatment.description`

**Criticism:**
- **No "mandated by" checklist** (CPS, employer, court). Just a blob.

---

### **Question 13: Veteran Status**
**Field:** `d6.veteran.value`, `d6.veteran.description`

**Criticism:**
- **Should be enum: Yes/No/Unknown/Not Applicable.** Some patients aren’t US citizens. **Missing N/A.**

---

### **Question 14: Peer Support History**
**Field:** `d6.peerSupportHistory.value`

**Criticism:**
- **No list of which groups** (AA/NA/SMART Recovery). No history dates.

---

### **Question 15: Environment with Substance Use**
**Field:** `d6.surroundedByUse.value`, `d6.alternativeHousingAvailable.value`

**Criticism:**
-  **`alternativeHousingAvailable` should be TriBool**  : Yes/No/Unknown. You have boolean.

---

### **Question 16: Relationship Safety Threat**
**Field:** `d6.safetyRelationship.any`, `d6.safetyRelationship.weapon`, `d6.safetyRelationship.killThreat`, `d6.safetyRelationship.mightKill`

**Criticism:**
-  **`any` is a boolean.** Should be "Has this person..." with a dropdown of relationships. **No perpetrator field.**
- **Lethality assessment is incomplete.** Missing "Strangulation history," "Access to firearms," "Stalking." **You’re using a truncated Danger Assessment.** Non-compliant with forensic standards.

---

### **Question 17: Other Safety Threats**
**Field:** `d6.otherSafetyThreat.value`, `d6.otherSafetyThreat.description`

**Criticism:**
- **No "immediacy" field.** Is the threat "today" vs "someday"?

---

### **Question 18: Dangerous Use Situations**
**Field:** `d6.dangerousUseSituations.value`, `d6.dangerousUseSituations.description`

**Criticism:**
- **No "victims" field.** If children are at risk, you need mandatory reporting. **No `d6.dangerousUseSituations.victimsAge` field.**

---

### **Questions 19–20: Supportive vs Risky Factors**
**Field:** `d6.supportive.people[]`, `d6.supportive.places[]`, `d6.supportive.things[]`, `d6.supportive.rating`, `d6.risky.people[]`, etc.

**Criticism:**
-  **`people[]` is a string array.** No structure: name, relationship, contact, substance use status. **Useless for care planning.**
-  **`rating` is a single number for all three categories.** Should be per-category. You're forcing one rating for people, places, and things combined.

---

### **Questions 21–24: Problem Statements**
**Field:** `d6.problems.text`, `d6.goalsAble.text`, `d6.goalsUnwilling.text`, `d6.goalsEnvironment.text`

**Criticism:**
-  **`goalsAble` and `goalsUnwilling` are named backwards.** The paper asks "What changes are you able or willing to make?" Your key `goalsAble` is ambiguous. **Rename to `changesWilling` and `changesUnwilling`.**
- **Unbounded text.** No char limits.

---

### **Severity Rating Block**
**Criticism:**
-  **"May need assistance in: finding a supportive environment, developing supports re: skills training, childcare, transportation"**  — this is a **run-on sentence** missing Oxford commas. **Clinical documentation will fail readability audits.**

---

## **CROSS-DIMENSIONAL LANDMINES**

### **EHR Prefill**
- **No `prefillMap` defined for D1–D3.** You defined it for D6 but not others. **Inconsistent.**
- **60-day freshness window is arbitrary** and not documented as a clinical policy. **Will be challenged in audits.**

### **Emergency Banner**
- **Triggers are hardcoded per dimension.** No central registry. **You’ll have 6 different banner components with divergent logic.**
-  **`onDismiss` is a function prop**  , but you never define where the dismissal timestamp is stored (`dismissedAt` in Redux? localStorage?). **Memory leak risk.**

### **Autosave**
-  **"500ms debounce" is performance suicide on slow networks.** You need exponential backoff and a max batch size (e.g., 5 fields per request).
- **No offline conflict resolution.** If user edits on mobile offline, then edits on desktop online, you’ll have a merge conflict with no resolution strategy.

### **PDF Export**
- **Font size is not specified for any dimension.** You’ll get 12pt on D1, 10pt on D2, 14pt on D3. **Visual drift.**
- **Emergency footnote text is hardcoded per dimension.** If wording differs, you’ll fail legal review for consistency.

### **Validation**
- **You have no `validate` function signature.** Is it sync or async? Does it return `ValidationError[]` or throw? **Undefined contract.**

### **Accessibility**
- **No `aria-live` text for severity selection.** When user selects sev4, screen reader won't announce "Severity 4 selected. Imminent danger flagged."
- **No `aria-describedby` for medication list add/remove.** Screen readers won't announce "Medication added" or "Medication removed."
- **Keyboard shortcuts (0–4) conflict with browser zoom (`Ctrl+0`).** You need `event.preventDefault()` but it's not specified.

### **Security & Compliance**
-  **"Illegal/Under the table" income** is stored in plaintext. **Subpoena risk.** Should be encrypted at rest and not exported to PDF.
- **Trauma history (Q5) and abuse details are not flagged as sensitive.** No automatic encryption or restricted access controls. **HIPAA violation waiting to happen.**

---

## **SUMMARY: YOUR SPEC IS 40% COMPLETE**

You have:
- ✅ **Token colors** (but they drift)
- ✅ **Basic field mappings** (but they’re blobs)
- ✅ **Emergency banner** (but triggers are incomplete)
- ❌ **Destructive clearing confirmation** (no undo)
- ❌ **Prefill conflict resolution** (no mapping)
- ❌ **Structured data for medications** (no RxNorm)
- ❌ **Imminence fields** for suicidality/homicidality
- ❌ **Access to means** field
- ❌ **Legal reportability flags**
- ❌ **Character limits** on 90% of text fields
- ❌ **Consistent naming** across dimensions
- ❌ **Merge strategy** for offline edits
- ❌ **Performance budget** for 44-key symptom matrix
- ❌ **Accessibility contracts** for every interactive element
- ❌ **Security controls** for sensitive data

**Until you close these gaps, your "build-ready" spec is a 6-month death march of bug triage and clinical disasters.**
