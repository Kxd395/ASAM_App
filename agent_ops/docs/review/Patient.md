Absolutely—this is one of the highest-risk parts of the app. Below is a tight, hyper-critical blueprint for **identifying the correct patient** and wiring it end-to-end (SMART launch, search, UI, rules, storage, and safety rails). Use this exactly as your spec for the agent.

---

# The goal (why this matters)

* Prevent **wrong-patient** and **wrong-encounter** errors.
* Make selection **fast** and **defensible** (meets “two identifiers” policy).
* Keep EMR as **source of truth**; our app only caches and links.

---

# Identifiers you should support (and how to use them)

## 1) MRN (Medical Record Number)

* **Type:** Patient-level identifier **scoped to a facility/system**.
* **FHIR:** `Patient.identifier[{system, value}]`
* **Use:** **Primary** lookup when the system (OID/URI) is known.
* **Pitfalls:** Same number can exist in different facilities → **always pair with `system`**.

## 2) FIN / CSN (Encounter/Account Number)

* **Type:** Encounter-level identifier (FIN = account; Epic often uses **CSN** for a specific visit).
* **FHIR:** `Encounter.identifier[{system, value}]`
* **Use:** Fetch encounter then `_include=Encounter:patient` to get patient deterministically.
* **Pitfalls:** Old/closed encounters; multiple matches if not date-bounded.

## 3) Name + DOB (and optional gender)

* **Type:** Demographic match, **never unique by itself**.
* **FHIR:** `/Patient?name=SMITH&birthdate=1980-01-01&gender=male`
* **Use:** Secondary, UI must **force manual adjudication**.
* **Pitfalls:** Hyphenation, nicknames, data entry errors → use **fuzzy display**, but **exact** FHIR query.

## 4) Enterprise Patient ID (EMPI/MPI/EUID)

* **Type:** Cross-facility **master** identifier (if available).
* **FHIR:** `Patient.identifier` with MPI system OID.
* **Use:** Highest trust when present; prefer over MRN for merges.
* **Pitfalls:** Not always exposed to app-level integrations.

## 5) Wristband barcode / label scan

* **Type:** **Code 128 / PDF417** barcode of MRN or FIN (hospital-specific schema).
* **Use:** **Fast + accurate** bedside capture via camera.
* **Pitfalls:** Format variance → add a lightweight **parsing profile per tenant**.

## 6) Optional secondaries (use cautiously)

* **Phone, Address, Last-4 SSN, Insurance ID** → **never primary**; only for UI verification hints. Avoid persisting these beyond cache TTL.

---

# Matching strategy (order of operations)

1. **SMART on FHIR launch (preferred)**

   * You receive `patient` and optionally `encounter` context.
   * **Action:** `GET /Patient/{id}`; if `encounter` present, `GET /Encounter/{id}` and assert `Encounter.subject.reference == "Patient/{id}"`.
   * **Guardrails:** Encounter `status ∈ {in-progress, arrived, triaged, planned}` else show “Not active” banner.

2. **Direct MRN search (with system)**

   * `GET /Patient?identifier={mrnSystem}|{mrnValue}`
   * If multiple results → force manual pick **with second identifier** (DOB).

3. **FIN/CSN search (with system)**

   * `GET /Encounter?identifier={finSystem}|{finValue}&_include=Encounter:patient`
   * Confirms patient deterministically from encounter.

4. **Name + DOB (fallback)**

   * `GET /Patient?name={name}&birthdate={yyyy-mm-dd}`
   * If >1 result → **require** a second factor (scan wristband or MRN entry) before opening.

**Never create patients locally.** Cache only what EMR returns.

---

# Scoring & adjudication (when multiple candidates)

Use **deterministic > probabilistic**. Only score for **display ranking**—selection is **human-confirmed**.

**Weights (example):**

* MRN(system+value) exact = 1.0
* FIN/Encounter link exact = 1.0
* Name(exact family+given) + DOB exact = 0.7
* Name(fuzzy) + DOB exact = 0.5

**Thresholds:**

* ≥ 0.95 → auto-select (but still **prompt “Confirm 2 identifiers”**).
* 0.7–0.95 → require manual pick + “2 identifiers” check.
* < 0.7 → show “No confident match. Refine search or scan wristband.”

---

# Safety rails (non-negotiable)

* **Two-Identifier Confirmation Gate**
  Require user to confirm **two** of: Name (full), DOB, MRN(system+value), FIN(system+value), **or scan**. Record `audit_event: {action: patient_verified, ids: masked}`.

* **Wrong-patient interlocks**
  When saving/signing/exporting: re-assert current `Patient.id` and `Encounter.id`. If changed mid-session → **block** and bounce to lookup.

* **Active encounter gate**
  Disallow writing to **finished** or **cancelled** encounters without override reason.

* **PHI-safe logs**
  No full identifiers in logs. Mask to last-4 and **hash** if needed. Avoid storing free-text search terms.

* **Offline**
  Allow only **previously cached** patient+encounter within TTL. Else block with “Offline – no cached data”.

---

# UI/UX blueprint (fast + safe)

* **Lookup screen**

  * Tabs: **Scan** | **MRN** | **FIN** | **Name + DOB**
  * Recent (local cache) with **status chips** (Active / Discharged).
  * **Tenant profile** drives MRN/FIN system OIDs and barcode parsing.

* **Results list**

  * Row: **Name (Legal)** • DOB • MRN(system) • Last encounter (date, type)
  * Tap → **“Confirm two identifiers” modal** (checkboxes + optional scan).

* **Patient header (persistent)**

  * Name • DOB • MRN(system) • Encounter FIN • Encounter status
  * “Switch Patient” button → warns about discarding in-progress draft.

* **Safety banner**

  * If **only one identifier** confirmed → yellow “Confirm second identifier to proceed.”
  * Export/sign buttons **disabled** until two identifiers verified.

---

# FHIR integration snippets (pseudo)

**By MRN**

```
GET /Patient?identifier={OID-for-MRN}|{value}
```

**By FIN with patient include**

```
GET /Encounter?identifier={OID-for-FIN}|{value}&_include=Encounter:patient
```

**By Name + DOB**

```
GET /Patient?name={family-or-given}&birthdate={YYYY-MM-DD}
```

**Verify encounter ↔ patient**

```
GET /Encounter/{id}
assert(encounter.subject.reference == "Patient/{patientId}")
```

---

# Persistence (GRDB / SQLite) — minimal, indexable, safe

**patients**

* `fhir_id (PK)`
* `mrn_system`, `mrn_value` (indexed pair)
* `name_family`, `name_given`, `name_full`
* `birth_date`, `gender`
* `photo_hash` (optional), `photo_blob` (optional; encrypt; TTL)
* `cached_at`, `ttl_expires_at`

**encounters**

* `fhir_id (PK)`
* `patient_fhir_id (FK)`
* `fin_system`, `fin_value` (indexed pair)
* `status`, `class`, `type`
* `period_start`, `period_end`

**constraints**

* Unique on `fhir_id`.
* Unique composite on `(mrn_system, mrn_value)` and `(fin_system, fin_value)` when present.
* Do **not** cascade update patient ids; they’re immutable.

---

# Barcode scanning (camera)

* Use **AVFoundation** to read Code 128 / PDF417.
* Per-tenant **decoder**: map scanned payload → `(system, value)` for MRN or FIN.
* If payload ambiguous, open **“Select type: MRN/FIN”** sheet.

---

# Acceptance criteria (safety & UX)

* Cannot enter Assessment until **two identifiers** are confirmed.
* If SMART launch provides `patient`+`encounter`, the app still shows a **brief verify banner**; export/sign remain blocked until user taps “Verified”.
* Selecting FIN **must** result in exactly one Patient (via `_include` link); else block.
* Attempting export with stale encounter (`status != active`) → **blocked with reason**.
* Switching patient mid-draft → **blocked** unless user discards draft.
* Offline search only surfaces cached entries **within TTL**.

---

# Common failure modes (and the fix)

* **MRN without system** → multiple hits across facilities.
  **Fix:** Always store and query with **`identifier.system`**; if user typed MRN only, prompt to choose facility.

* **Encounter not active** but clinician wants to continue.
  **Fix:** Allow read; block write/export without **override reason** (audit).

* **Name/DOB duplicates** (John Smith 01-01-1980).
  **Fix:** Require **MRN/FIN scan** to break ties.

* **Photo mismatch risk**
  **Fix:** Use `Patient.photo` only if delivered by EMR; do not import camera photos for matching.

---

# Agent tasks (drop-in)

1. **Lookup UI**

   * Build tabs (Scan/MRN/FIN/Name+DOB) with async FHIR calls.
   * Add tenant config for `mrnSystemOID` and `finSystemOID`.
2. **Two-identifier gate**

   * Implement modal + persistent header banner.
   * Wire gate to **disable Sign/Export**.
3. **FHIR wiring**

   * Implement `/Patient?identifier`, `/Encounter?identifier&_include=Encounter:patient`, `/Patient?name&birthdate`.
   * Add status/date checks; disallow finished encounters.
4. **Persistence**

   * Create `patients`, `encounters` tables and indices as above.
   * TTL purge job (e.g., 72h encounters, 7d demographics).
5. **Barcode parser**

   * AVFoundation reader + pluggable decoder per tenant.
6. **Audit**

   * `patient_verified` event with masked ids (e.g., MRN ****1234).

Add these as tasks in `MASTER_TODO` (P1), and wire the export/sign buttons to the **two-identifier state**.

---

If you want, I’ll generate:

* the **FHIR query helpers** (Swift),
* the **GRDB migrations**, and
* a **unit test matrix** for matching/adjudication (including wristband scans).
Awesome—pulling vitals + UDS into the assessment is the right move for safety, decision-support, and billing defensibility. Here’s a tight, hyper-critical integration plan with FHIR queries, LOINC mappings, UI placement, validation hooks, and JSON stubs you can drop into your repo.

---

# What to ingest (and why)

* **Vitals (last, most recent in encounter)**
  Required for safety gating (e.g., unstable vitals), review screens, and audit.
  Map via FHIR `Observation` (category=`vital-signs`) and specific LOINC codes:

  * Temperature: **8310-5** (Body temperature) ([LOINC][1])
  * Heart rate: **8867-4** (Heart rate) ([LOINC][2])
  * Respiratory rate: **9279-1** (Respiratory rate) ([LOINC][3])
  * SpO₂: **59408-5** (Oxygen saturation by pulse oximetry) and fallback **2708-6** (O2 sat, arterial) ([LOINC][4])
  * FiO₂: **3150-0** (Inspired O₂ fraction) ([LOINC][5])
  * Blood pressure: **85354-9** (BP panel) with components **8480-6** (Systolic) & **8462-4** (Diastolic) ([LOINC][6])

* **UDS (qualitative presence/absence)**
  Pull qualitative “screen” results for defensibility and WM/LOC rules. Use FHIR `Observation` (category=`laboratory`) with these common LOINC “Presence in Urine by Screen method” codes (include panel/alt codes where appropriate):

  * Cocaine: **19359-9** (Cocaine metabolites—presence) ([LOINC][7])
  * Cannabinoids: **18282-4** ([LOINC][8])
  * Amphetamines: **19363-1** ([LOINC][9])
  * Barbiturates: **19270-8** ([LOINC][10])
  * Benzodiazepines: **14316-4** ([LOINC][11])
  * Opiates: **19295-5** ([LOINC][12])
  * Phencyclidine (PCP): **19659-2** ([LOINC][13])
  * Methadone: **19550-3** ([LOINC][14])
  * **Fentanyl:** **59673-4** (Presence—screen) and related group expansions in CDC Opioid UDS ValueSet ([FHIR Build][15])
  * **Oxycodone:** **19642-8** (Presence—screen) and **58430-0** (Oxycodone/Oxymorphone presence—screen) ([FHIR Build][15])
  * **Buprenorphine:** **58359-1** (Presence—screen) among codes listed in CDC Opioid UDS ValueSet ([FHIR Build][15])

> Why these: They are the most commonly implemented qualitative screen LOINCs. We also reference authoritative HL7/CDC/LOINC sources for fentanyl/oxycodone/buprenorphine where lab menus vary. The CDC Opioid UDS ValueSet gives you a robust superset for opioids and analogs. ([FHIR Build][15])

---

# FHIR pulls (safe, reproducible)

**Vitals (per encounter)**

```
GET Observation?
  category=vital-signs
  &encounter={Encounter/id}
  &_sort=-date
  &_count=50
```

Filter client-side to preferred LOINC codes above (use BP panel’s components for sys/dia).

**UDS (per encounter)**

```
GET Observation?
  category=laboratory
  &code={comma-separated LOINCs from uds_codes.json}
  &encounter={Encounter/id}
  &_sort=-date
  &_count=100
```

If your lab uses **panels**, also fetch `DiagnosticReport?encounter=...` and follow `result` references to `Observation`.

**Robustness**

* Accept both `valueCodeableConcept` (POS/NEG + interpretation) and `valueQuantity` (rare, numeric).
* Normalize “Detected/Positive/Reactive” → `positive`, “Not detected/Negative/Nonreactive” → `negative`.
* De-duplicate by code+effectiveDateTime; keep the **most recent** in the encounter.

---

# Persistence (do NOT overwrite clinician-entered data)

Add a **read-only EMR snapshot** to your local DB—never auto-populate form answers:

* `emr_observation_snapshot`

  ```
  id, patient_mrn, encounter_fin, category("vital-signs"/"laboratory"),
  loinc, display, value, unit, ref_low, ref_high,
  interpretation("positive"/"negative"/"high"/"low"/"critical"?),
  effective_dt, issued_dt, source_system, raw_json (blob), fetched_at
  ```
* TTL (matches your Settings): vitals 12h, labs 72h (already in your Settings wireframe).

This keeps provenance, allows audit replay, and avoids “battle of the sources.”

---

# UI placement (no IP issues, clinically crisp)

* **Assessment Overview (top card):**
  *Vitals (Most recent)*: Temp, BP, HR, RR, SpO₂ (± FiO₂), timestamps.
  Danger highlighting (site-policy thresholds): e.g., RR>24, HR>120, SpO₂<90% RA, Temp>38.3°C or <35°C.
* **Domain A (Intox/Withdrawal):**
  *UDS summary* chip row (latest per analyte): Cocaine, Fentanyl, Oxycodone, Opiates, etc. Click to expand full lab detail (timestamp, method, lab comment).
* **Safety banner:**
  Flip `vitals_unstable` automatically if vitals breach thresholds (still allow clinician to override with a note).

> Critical: Keep this **read-only** (EMR Context). Never auto-fill assessment fields.

---

# Rules & validation wiring (ties to what you already built)

* **ReconciliationChecks** (you added):

  * If `vitals_unstable == true` → block ambulatory WM levels (candidate ladder disabled).
  * If UDS **fentanyl** positive and D1 suggests outpatient WM → raise blocker or escalate (site policy).
  * If UDS **buprenorphine** positive and patient on MOUD → do **not** treat as illicit positive (warning only).
* **Rules inputs:**

  * Provide `flags.vitalsUnstable` from vitals thresholds.
  * Provide `d1Context.lastUseHours` + `suspectedFentanyl` derived from UDS (if lab panel indicates fentanyl).
* **ExportPreflight**: require a “Vitals present within encounter” gate (advisory if none; blocker if safety flags referenced but missing data).

---

# Billing hook (visit code “assist”, not advice)

* Add a **read-only “Visit Context” card** (for the clinician):

  * Encounter type, LOS clock, most recent vitals, number of data elements reviewed (vitals+UDS counts), time stamps.
  * **Do not** compute CPT codes; just surface supporting elements.
* Store: `billing_context { vitals_count, labs_count, last_vitals_dt, last_lab_dt }` for your note generator.

---

# JSON stubs (drop-in)

**`codes/vitals_codes.json`**

```json
{
  "temperature": ["8310-5"],
  "heart_rate": ["8867-4"],
  "resp_rate": ["9279-1"],
  "spo2": ["59408-5", "2708-6"],
  "fio2": ["3150-0"],
  "bp_panel": ["85354-9"],
  "bp_systolic": ["8480-6"],
  "bp_diastolic": ["8462-4"]
}
```

**`codes/uds_codes.json`**

```json
{
  "cocaine": ["19359-9"],
  "cannabinoids": ["18282-4"],
  "amphetamines": ["19363-1"],
  "barbiturates": ["19270-8"],
  "benzodiazepines": ["14316-4"],
  "opiates": ["19295-5"],
  "phencyclidine": ["19659-2"],
  "methadone": ["19550-3"],
  "fentanyl": ["59673-4"],
  "oxycodone": ["19642-8", "58430-0"],
  "buprenorphine": ["58359-1"]
}
```

> Notes: Local labs may use additional codes or panels—merge your site’s LOINCs into these arrays. Fentanyl/oxycodone/buprenorphine families are best kept extensible; the CDC ValueSet is a strong reference superset for opioids. ([FHIR Build][15])

---

# Swift (query shape, pseudo-code)

```swift
// Vitals
fhir.search(Observation.self,
  query: [
    "_sort": "-date",
    "category": "vital-signs",
    "encounter": encounterId
  ]) { result in
    let wanted = VitalsCodes.all // from vitals_codes.json
    let keep = result.filter { wanted.contains($0.code.loinc) }
    // Special-case BP: read components 8480-6/8462-4
}

// UDS
let udsCodes = UDSCodes.all // flattened from uds_codes.json
fhir.search(Observation.self,
  query: [
    "_sort": "-date",
    "category": "laboratory",
    "code": udsCodes.joined(separator: ","),
    "encounter": encounterId
  ]) { result in
    normalizeQual(result) // POS/NEG map
}
```

---

# Thresholds (make them site-policy configurable)

* Default “unstable vitals” (flip `vitalsUnstable`):

  * Temp ≥ 38.3°C or ≤ 35.0°C
  * HR ≥ 120 bpm
  * RR ≥ 24 /min
  * SpO₂ < 90% on room air (if FiO₂ > 0.21, annotate)
    Store in `settings/thresholds.json` so clinical leadership can tune without code changes.

---

# QA & Safety checks

* **Unit tests:** fixtures with POS/NEG permutations, absent vitals, mixed units (°F vs °C), panel vs singleton Observations.
* **Validation list:** show explicit “No vitals for this encounter” advisory.
* **Audit:** store raw `Observation` JSON with `source_system` + timestamp.

---

# What can go wrong (and how we prevent it)

1. **Wrong patient/encounter:** use your two-identifier gate + `encounter FIN` lock before fetching.
2. **Lab aliases:** labs often use panel LOINCs—keep a **site override file** to merge local codes.
3. **POS but “Not Detected” text:** normalize via interpretive code OR text fallback; never rely on display text only.
4. **Auto-population bias:** keep EMR data **read-only**; clinician’s interview remains the source of truth.
5. **Billing creep:** present counts/timestamps only; do not offer CPT suggestions.

---

## Quick next steps

* Add `codes/vitals_codes.json` and `codes/uds_codes.json`.
* Add `settings/thresholds.json` (site-policy defaults).
* Implement `EMRIngestService` (FHIR pulls + normalization + snapshot writes).
* Surface “Vitals & UDS” panel in Overview + Domain A (read-only).
* Wire `vitalsUnstable` from thresholds to your existing safety gates.
* Extend rules to look at `suspectedFentanyl` when UDS fentanyl is positive (advisory vs blocker per policy).

If you want, I can spit out those three JSON files exactly as shown and a minimal `EMRIngestService` stub to drop into your project.

[1]: https://loinc.org/LG2847-4?utm_source=chatgpt.com "LOINC Group LG2847-4 Amphetamines|PrThr|Pt|ANYUrine"
[2]: https://loinc.org/files/LOINC%20Groups_Feedback%20Review_20171102.xlsx?utm_source=chatgpt.com "Sheet1"
[3]: https://loinc.org/55419-6/panel?utm_source=chatgpt.com "Home drug screening panel - Urine"
[4]: https://loinc.org/58381-5?utm_source=chatgpt.com "fentaNYL [Mass/volume] in Urine by Confirmatory method"
[5]: https://loinc.org/58430-0?utm_source=chatgpt.com "oxyCODONE+oxyMORphone [Presence] in Urine by ..."
[6]: https://loinc.org/18282-4?utm_source=chatgpt.com "Cannabinoids [Presence] in Urine by Screen method"
[7]: https://loinc.org/19642-8?utm_source=chatgpt.com "oxyCODONE [Presence] in Urine by Screen method"
[8]: https://loinc.org/93494-3?utm_source=chatgpt.com "LOINC 93494-3 Buprenorphine [Presence] in Urine ..."
[9]: https://loinc.org/3414-0?utm_source=chatgpt.com "LOINC 3414-0 Buprenorphine [Presence] in Urine"
[10]: https://loinc.org/58359-1?utm_source=chatgpt.com "Buprenorphine+Norbuprenorphine [Presence] in Urine by ..."
[11]: https://loinc.org/82371-6?utm_source=chatgpt.com "Norbuprenorphine [Presence] in Urine by Screen method"
[12]: https://loinc.org/91027-3?utm_source=chatgpt.com "Buprenorphine-3-glucuronide [Presence] in Urine ..."
[13]: https://loinc.org/89305-7?utm_source=chatgpt.com "Norbuprenorphine-3-glucuronide [Presence] in Urine by ..."
[14]: https://loinc.org/LG37597-8?utm_source=chatgpt.com "LOINC Group LG37597-8 Buprenorphine|ANYProp|ANYTm"
[15]: https://build.fhir.org/ig/cqframework/opioid-cds-r4//ValueSet-opioid-urine-drug-screening.html "Opioid drug urine screening - 2022 CDC Clinical Practice Guideline for Prescribing Opioids Implementation Guide v2022.1.0"
Got it—here’s a clean, copy-pasteable spec your agent can implement. It lists **all fields** for an ad-hoc per-substance intake, with types, constraints, computed fields, and UI/validation hints. I kept names neutral and aligned with the rest of your stack.

---

# Substance Intake – Field Catalog (per substance)

> One profile per substance the patient reports (e.g., alcohol, fentanyl, cannabis).
> All fields are **patient-reported** unless otherwise noted. EMR/UDS is **read-only context**.

## 1) JSON schema (engine/DB friendly)

```json
{
  "$id": "SubstanceIntakeProfile",
  "type": "object",
  "required": ["substance_group", "last_use_dt", "route", "freq_7d_days", "freq_30d_days"],
  "properties": {
    "profile_id":        { "type": "string", "format": "uuid" },
    "assessment_id":     { "type": "string", "format": "uuid" },
    "substance_group":   { "type": "string", "enum": [
      "alcohol","opioid_fentanyl","opioid_heroin","opioid_oxycodone","opioid_methadone",
      "opioid_buprenorphine","stimulant_cocaine","stimulant_methamphetamine",
      "benzodiazepines","barbiturates","cannabis","pcp","hallucinogens","inhalants","other"
    ]},
    "other_substance_text": { "type": "string", "maxLength": 120 },

    "last_use_dt":       { "type": "string", "format": "date-time" },        // local TZ OK
    "last_use_hours":    { "type": "integer", "minimum": 0 },                // computed
    "route":             { "type": "array", "items": { "type": "string", "enum": [
      "oral","intranasal","smoked","iv","sublingual","transdermal","rectal","other"
    ]}, "minItems": 1, "uniqueItems": true },
    "route_other_text":  { "type": "string", "maxLength": 80 },

    "freq_7d_days":      { "type": "integer", "minimum": 0, "maximum": 7 },
    "freq_30d_days":     { "type": "integer", "minimum": 0, "maximum": 30 },
    "uses_per_day_typical": { "type": "number", "minimum": 0, "maximum": 48 },

    "amount_text":       { "type": "string", "maxLength": 120 },             // e.g., "pint/day", "3 bags/day"
    "std_drinks_per_day":{ "type": "number", "minimum": 0, "maximum": 40 },  // alcohol optional struct
    "mg_per_day":        { "type": "number", "minimum": 0, "maximum": 5000 },// optional struct

    "age_first_use":     { "type": "integer", "minimum": 0, "maximum": 100 },
    "longest_abstinence_days": { "type": "integer", "minimum": 0, "maximum": 36500 },

    "current_withdrawal_symptoms": { "type": "boolean" },
    "cows_score":        { "type": "integer", "minimum": 0, "maximum": 48 }, // if opioid class
    "ciwa_score":        { "type": "integer", "minimum": 0, "maximum": 67 }, // if alcohol

    "craving_0_10":      { "type": "integer", "minimum": 0, "maximum": 10 },

    "treatment_history": {
      "type": "object",
      "properties": {
        "detox":   { "type": "boolean" },
        "residential": { "type": "boolean" },
        "outpatient":  { "type": "boolean" },
        "mat_current": { "type": "boolean" },
        "mat_type": { "type": "string", "enum": ["methadone","buprenorphine","naltrexone","acamprosate","disulfiram","none","other"] },
        "mat_other_text": { "type": "string", "maxLength": 80 }
      }
    },

    "overdose_history": {
      "type": "object",
      "properties": {
        "ever_overdosed": { "type": "boolean" },
        "last_overdose_dt": { "type": "string", "format": "date-time" },
        "overdose_count_lifetime": { "type": "integer", "minimum": 0, "maximum": 100 }
      }
    },

    "risk_context": {
      "type": "object",
      "properties": {
        "injection_use": { "type": "boolean" },           // route includes "iv" → set true
        "shares_equipment": { "type": "boolean" },
        "naloxone_access":  { "type": "boolean" },        // for opioids
        "binge_pattern":    { "type": "boolean" },
        "money_spent_per_day": { "type": "number", "minimum": 0, "maximum": 10000 },
        "typical_time_of_day": { "type": "string", "enum": ["morning","afternoon","evening","overnight","varies"] },
        "triggers_text": { "type": "string", "maxLength": 240 }
      }
    },

    "evidence_links": {
      "type": "object",
      "properties": {
        "uds_latest": { "type": "string" },              // Observation.id (if available)
        "emr_observation_ids": { "type": "array", "items": { "type": "string" } }
      }
    },

    "notes_clinician":   { "type": "string", "maxLength": 1000 },

    "computed_flags": {
      "type": "object",
      "properties": {
        "recent_use_lt_24h":   { "type": "boolean" },
        "suspected_fentanyl":  { "type": "boolean" },   // from UDS or report
        "wm_indicated_candidate": { "type": "boolean" } // derived for UI only
      }
    },

    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

---

## 2) UI widgets & validation (agent build hints)

* **Substance:** segmented picker (common list) + “Other…” text.
* **Last Use (date/time):** date-time picker → compute `last_use_hours` on save; **Gate**: negative/ future dates blocked.
* **Route:** multi-select chips; when “IV” selected → auto-set `risk_context.injection_use = true`.
* **Frequency (7d / 30d):** numeric steppers; **Rule:** `freq_7d_days ≤ 7`, `freq_30d_days ≤ 30`, and `freq_7d_days ≤ freq_30d_days` (soft check).
* **Uses per day:** numeric stepper; **Warn** if > 12.
* **Amount text:** free text; **If alcohol**, show optional `std_drinks_per_day`. **If opioid**, show optional `mg_per_day`.
* **Age first use / Longest abstinence:** numeric; **Warn** if abstinence > lifetime days.
* **Withdrawal flags & scales:** show `COWS` when substance_group ∈ opioids; show `CIWA` when `alcohol`.
* **Craving (0–10):** slider with discrete ticks.
* **Treatment history:** checkbox matrix; MAT type dropdown appears when `mat_current = true`.
* **Overdose:** if `ever_overdosed = true`, require `last_overdose_dt` or `overdose_count_lifetime > 0` (validation).
* **Risk context:** toggles and optional numeric/text; money/day allow 2 decimals.
* **Evidence links:** readonly (populated by EMR ingest).
* **Notes:** multiline, spellcheck on.

**Cross-field guards (wire to your ReconciliationChecks):**

* `COWS ≥ 13` → require Domain A severity ≥ 3 (blocker suggestion).
* `CIWA ≥ 16` → suggest Domain A ≥ 3 (blocker suggestion if contradictions).
* `noWithdrawalSigns = true` → cap Domain A ≤ 1 (blocker if violated).
* `last_use_hours ≤ 24` and `opioid_*` → set `computed_flags.recent_use_lt_24h = true` (for WM ladder).

---

## 3) Persistence (GRDB / SQLite columns)

*Table: `substance_rows` (one row per substance per assessment)*

* PKs: `profile_id (UUID)`, `assessment_id (UUID)`
* Core: `substance_group TEXT`, `other_substance_text TEXT`
* Timing: `last_use_dt TEXT`, `last_use_hours INT`
* Route: `route_csv TEXT`, `route_other_text TEXT`
* Frequency: `freq_7d_days INT`, `freq_30d_days INT`, `uses_per_day_typical REAL`
* Amounts: `amount_text TEXT`, `std_drinks_per_day REAL`, `mg_per_day REAL`
* History: `age_first_use INT`, `longest_abstinence_days INT`
* Withdrawal: `current_withdrawal_symptoms INT`, `cows_score INT`, `ciwa_score INT`
* Craving: `craving_0_10 INT`
* Treatment: `tx_detox INT`, `tx_residential INT`, `tx_outpatient INT`, `mat_current INT`, `mat_type TEXT`, `mat_other_text TEXT`
* Overdose: `od_ever INT`, `od_last_dt TEXT`, `od_count INT`
* Risk: `injection_use INT`, `shares_equipment INT`, `naloxone_access INT`, `binge_pattern INT`, `money_spent_per_day REAL`, `typical_time_of_day TEXT`, `triggers_text TEXT`
* Evidence: `uds_latest TEXT`, `emr_observation_ids TEXT` (JSON)
* Computed: `recent_use_lt_24h INT`, `suspected_fentanyl INT`, `wm_indicated_candidate INT`
* Notes: `notes_clinician TEXT`
* Audit: `created_at TEXT`, `updated_at TEXT`

> Tip: keep `route_csv` (fast filter) **and** `route` as JSON in a companion materialized column if you want schema flexibility.

---

## 4) Example payload (one substance)

```json
{
  "profile_id": "b6b6f52a-8af1-4e8d-9b0a-3f8a2d0e8a41",
  "assessment_id": "6f1b6b62-7c1f-449e-a3e2-9d1ff1e54c2a",
  "substance_group": "opioid_fentanyl",
  "last_use_dt": "2025-11-10T08:30:00-06:00",
  "last_use_hours": 6,
  "route": ["iv"],
  "freq_7d_days": 6,
  "freq_30d_days": 24,
  "uses_per_day_typical": 4,
  "amount_text": "≈0.3 g/day",
  "age_first_use": 21,
  "longest_abstinence_days": 14,
  "current_withdrawal_symptoms": true,
  "cows_score": 16,
  "ciwa_score": 0,
  "craving_0_10": 8,
  "treatment_history": {
    "detox": true,
    "residential": false,
    "outpatient": true,
    "mat_current": false,
    "mat_type": "none"
  },
  "overdose_history": {
    "ever_overdosed": true,
    "last_overdose_dt": "2025-08-14T22:00:00-05:00",
    "overdose_count_lifetime": 2
  },
  "risk_context": {
    "injection_use": true,
    "shares_equipment": false,
    "naloxone_access": true,
    "binge_pattern": false,
    "money_spent_per_day": 120,
    "typical_time_of_day": "evening",
    "triggers_text": "Arguments, payday"
  },
  "evidence_links": {
    "uds_latest": "Observation/UDS-987654",
    "emr_observation_ids": ["Observation/UDS-987654","Observation/UDS-123456"]
  },
  "computed_flags": {
    "recent_use_lt_24h": true,
    "suspected_fentanyl": true,
    "wm_indicated_candidate": true
  },
  "notes_clinician": "Reports severe cravings on waking.",
  "created_at": "2025-11-10T09:02:10-06:00",
  "updated_at": "2025-11-10T09:05:43-06:00"
}
```

---

## 5) Agent tasks (checklist)

1. **Models**

   * Create `SubstanceIntakeProfile` model from JSON schema.
   * Add GRDB table `substance_rows` with columns above (migration + DAO).

2. **UI**

   * Build `SubstanceRowSheet` using these widgets and guards.
   * Contextual scales: show COWS for opioid groups; CIWA for alcohol.
   * Auto-compute `last_use_hours` on change.

3. **Validation**

   * Enforce requireds: substance_group, last_use_dt, route, freq_7d_days, freq_30d_days.
   * Wire ReconciliationChecks (COWS/CIWA vs Domain A, noWithdrawalSigns cap).
   * If `ever_overdosed = true` → require last date or count.

4. **Rules Inputs**

   * Feed `last_use_hours`, `injection_use`, `suspected_fentanyl`, `cows_score`/`ciwa_score` into rules.
   * Set `wm_indicated_candidate` for UI only (do not persist as source of truth).

5. **EMR Context**

   * Map UDS to `evidence_links.*` (read-only).
   * Never auto-populate patient-entered fields from EMR.

6. **Export Preflight**

   * Add guard: if opioid + `recent_use_lt_24h` and severe withdrawal → WM ladder must display before export (advisory → blocker per your policy).
   * Ensure provenance and rules health gates already in place.

7. **Accessibility**

   * All numeric inputs support stepper and keypad entry.
   * Sliders (craving) include numeric labels and VoiceOver value.

---

If you want this delivered as actual **JSON files** (schema + enum lists) and a **Swift model stub**, I can generate those verbatim for your repo.
