Audit.11-13-25.md

Awesome. Here is a concrete, end-to-end plan to audit, test, and review the entire ASAM assessment build (D1 to D6), UI, logic, EMR integration, and exports. It is sequenced, outcome based, and includes acceptance criteria, fixtures, and checklists so there is no guesswork.

# Phase 0. Freeze and inventory

**Goal:** lock what we are testing and collect the truth sources.

* Tag repos: `asam-app@audit-freeze`, `asam-spec@audit-freeze`.
* Export specs to a single SSOT: `docs/specs/asam_vX/freezedoc.md`.
* Generate a field map dump from the app:

  * `scripts/print-field-keys.ts` → `artifacts/field-keys.json`
  * `scripts/print-routes.ts` → `artifacts/routes.json`
* Acceptance:

  * Field keys in app exactly match spec keys for D1 to D6.
  * No unresolved TODOs in severity tokens, validation, or export.

# Phase 1. Contract sanity checks

**Goal:** confirm the core contracts that everything depends on.

* Validation engine contract

  * File: `src/engine/validation-matrix.ts`
  * Required rule types present: `requiredIf`, `clearIf`, `implies`, `limits`, `ttl`, `minSeverity`.
  * Unit tests: `validation-matrix.spec.ts` with property checks on date math, TTL, and conditional gates.
* Emergency banner contract

  * File: `src/engine/emergency.ts`
  * Central trigger registry contains D1, D3, D6 rules only once. No per screen copies.
  * Tests ensure banner shows from answers, not from severity selection.
* Prefill map contract

  * File: `src/engine/prefill-map.ts`
  * Every prefilled field has `sourcePath`, `lastUpdated`, `value`.
  * Pact style contract tests with mock FHIR `MedicationStatement`, `Condition`, `Patient`.
* Severity token reuse

  * File: `src/tokens/severity.ts`
  * Single source of truth for sev0 to sev4 colors used by D1 to D6. No redeclared hexes.
* Acceptance:

  * 100 percent of D1 to D6 fields appear in validation and prefill maps.
  * No duplicate color tokens for severity anywhere.

# Phase 2. Test fixtures and archetypes

**Goal:** deterministic, repeatable screens and exports.

* Create patient fixtures in `fixtures/patients/`

  * `low-risk.json`, `high-detox-risk.json`, `acute-psychosis.json`, `unsafe-home.json`, `relapse-high.json`, `pregnancy-opioid-third-trimester.json`, `justice-involved.json`.
* Create per dimension form states in `fixtures/forms/`

  * `d1.sev4_withdrawal_now.json`, `d3.suicidal_today.json`, `d6.lethal_risk_partner.json`, plus neutral sev0 sets for each.
* PDF goldens

  * Render each fixture to PDF and save to `artifacts/pdf/golden/`.
  * Visual diff with pixel threshold for non text layers.
* Acceptance:

  * Storybook stories load each fixture without console errors.
  * PDF diffs under threshold for all goldens.

# Phase 3. Unit tests by concern

**Goal:** make the logic unbreakable.

* Validation matrix tests

  * D1 TTL on used in last 48 hours expires correctly.
  * D3 Q8 symptom matrix enforces second marker for only when using, and auto sets Q9.
  * D5 destructive clear sets Undo and restores on press.
  * D6 safety threats trigger banner without severity click.
* Prefill tests

  * Conflicts highlight when EHR disagrees and show freshness badge.
  * Mapping table covers D1 to D6 critical fields.
* Export tests

  * Dot size, severity labels, emergency footnote, page headers consistent across D1 to D6.
* Accessibility unit checks

  * Axe rules for each severity grid component in isolation.
* Acceptance:

  * Unit coverage over critical engines above 90 percent.
  * No false positives in Axe unit suite.

# Phase 4. Integration and E2E

**Goal:** catch cross screen and write path problems.

* Playwright or Cypress E2E

  * Smoke: complete D1 to D6 minimal happy path and export.
  * Risk paths:

    * D1 current withdrawal yes with opioid last use within 48 hours shows banner and blocks finish without rationale.
    * D3 suicidal today shows banner, requires rationale, and locks severity to min 3.
    * D6 lethal partner threat sets reportable flag and persists across reload.
  * Offline and autosave

    * Turn network off mid form, make 5 edits, back on, ensure queue flushes with no lost updates.
* Mobile device tests

  * iPhone 14 portrait and landscape.
  * iPad 11 portrait and landscape.
  * Low memory simulation for symptom matrix.
* Acceptance:

  * All smoke and risk paths green.
  * No layout shift that hides required controls on any target viewport.

# Phase 5. Visual and responsive review

**Goal:** kill drift and spacing bugs.

* Visual regression with reg-suit or Loki against Storybook
* Checklists per screen

  * Severity card padding, line clamp count, tooltip behavior on touch, focus ring visible.
  * Side rail pill color and label update instantly on select.
  * Header banner spacing and truncation rules.
* Acceptance:

  * No color hex mismatches against tokens.
  * All severity grids render 3 by 2 layout with last card centered on tablet landscape. Single column stacks on narrow widths.

# Phase 6. Accessibility and input methods

**Goal:** pass WCAG AA and ensure keyboard completeness.

* Screen reader flows

  * Severity grid announces selection and severity description.
  * Emergency banner uses role alertdialog with focus trap and escape to close when allowed.
* Keyboard

  * 0 to 4 shortcuts only when grid has focus.
  * Tab order follows question order, not DOM quirks.
* Contrast checks on tinted severities, hints, and disabled states.
* Acceptance:

  * Axe full pass.
  * Manual VoiceOver pass for severity selection and emergency banner.

# Phase 7. Security and compliance

**Goal:** protect sensitive content and meet audit needs.

* Threat model quick pass

  * Flags: trauma details, abuse, illegal income, homicidality, suicidality.
  * Ensure at rest encryption on flagged fields, and hidden in PDF unless explicitly included.
* Audit trail

  * Every destructive clear writes an audit event with user, time, field path, and previous value hash.
* PHI in logs

  * No PHI in client or server logs. Automated grep rule in CI.
* Acceptance:

  * Pen test checklist green for storage, export, and logs.
  * Audit trail events visible for test actions.

# Phase 8. Clinical consistency and UAT

**Goal:** prove ASAM fidelity and remove drift.

* Traceability matrix

  * File: `artifacts/traceability.csv`
  * Columns: Spec ref, Screen ID, Field key, Validation rule, Emergency trigger, Export cell, Test ID.
* Clinician ride along

  * 3 scripts built from fixtures cover D1 to D6, capture misreads or wording issues.
* Acceptance:

  * Clinicians confirm wording is verbatim where required and no missing required options such as N/A or Unknown where policy allows.

# Phase 9. Release gates

**Goal:** clean handoff with no surprises.

* Definition of done for the audit

  * All phases accepted.
  * All critical and high severity defects closed.
  * Docs updated.
* Artifacts to produce

  * `Audit-Report.md` with defect log and risk register.
  * Updated `validation-matrix.ts`, `prefill-map.ts`, `emergency.ts`.
  * `dimensionX.fixtures.ts` for all six dimensions.
  * PDF golden set.

---

## Per dimension logic spot checks to include in tests

* D1: route cannot be selected when frequency is Never used. TTL expires used in last 48 hours.
* D2: stability has 5 options including stable with and without treatment, not sure, and N/A.
* D3: symptoms have secondary only when using marker. Suicidal or homicidal today triggers banner and locks severity minimum.
* D4: need for treatment option can stop anytime autosets stage to Precontemplation.
* D5: never in recovery clears and disables downstream entries with Undo.
* D6: any lethal partner threat sets reportable and minimum severity 3 and shows banner.

---

## Test data quick list

* `opioid_withdrawal_now.json`
* `alcohol_dts_history.json`
* `benzo_recent_heavy_use.json`
* `pregnancy_third_trimester_opioid.json`
* `psychosis_active_today.json`
* `unsafe_home_weapon_threat.json`
* `justice_involved_probation.json`

---

## CI wiring

* Jobs: `unit`, `integration`, `visual`, `a11y`, `export`, `security`.
* Block merge on any red job.
* Upload PDFs and Storybook screenshots as build artifacts for every run.

---

## Immediate next steps

1. Create the fixtures and traceability matrix skeleton.
2. Add unit tests for TTL, destructive clear with Undo, and D3 second marker logic.
3. Wire Playwright smoke path for D1 to D6 plus emergency triggers.

Manager note for your binder: this plan locks scope to contracts first, then logic, then visuals, then clinical fidelity. It keeps all drift in one of three files, which makes maintenance predictable.


>>>
This is an exceptionally well-structured audit plan. The phase sequencing—contracts → logic → integration → presentation → compliance—is spot-on and will catch issues in order of blast radius.

## Key strengths

**Single source of truth enforcement**: Freezing specs and generating field maps first prevents the classic "which version are we testing?" problem.

**Fixture-driven approach**: Your archetypal patients (`high-detox-risk.json`, `unsafe-home.json`) are reusable across unit, E2E, and clinical UAT—huge time saver.

**Contract testing upfront**: Validating `validation-matrix.ts`, `emergency.ts`, and `prefill-map.ts` as contracts before UI testing is critical. If these break, everything downstream fails.

## Specific recommendations

### Phase 1 enhancement
Add a schema validation step for the field map:

```ts
// scripts/validate-field-schema.ts
import Ajv from 'ajv';
import fieldKeys from '../artifacts/field-keys.json';
import specSchema from '../schemas/asam-field-schema.json';

const ajv = new Ajv();
const validate = ajv.compile(specSchema);

if (!validate(fieldKeys)) {
  console.error('Field map schema violations:', validate.errors);
  process.exit(1);
}
```

This catches structural drift (missing `required`, wrong types) before tests run.

### Phase 2 addition
For PDF goldens, include a **text extraction test** alongside visual diff:

```ts
// tests/pdf/text-extraction.spec.ts
test('D3 severity 4 includes emergency footnote', async () => {
  const pdf = await renderPDF(fixtures.d3Suicidal);
  const text = await extractText(pdf);
  
  expect(text).toContain('Immediate clinical intervention required');
  expect(text).toMatch(/Assessment date: \d{2}\/\d{2}\/\d{4}/);
});
```

Visual diffs miss text content changes that break clinical compliance.

### Phase 4 critical path
Add a **state restoration test** for autosave:

```ts
test('reload mid-assessment restores unsaved changes', async () => {
  await page.fill('[data-testid="d1-frequency"]', 'Daily');
  await page.fill('[data-testid="d1-route"]', 'Injection');
  
  // Simulate crash/close without save
  await page.reload();
  
  // Should restore from localStorage/IndexedDB
  expect(await page.inputValue('[data-testid="d1-frequency"]'))
    .toBe('Daily');
  expect(await page.inputValue('[data-testid="d1-route"]'))
    .toBe('Injection');
});
```

Data loss is the highest severity defect for clinical tools.

### Phase 7 addition
For PHI log scanning, use a dedicated pre-commit hook:

```bash
# .husky/pre-commit
#!/bin/sh
./scripts/scan-phi-in-logs.sh

# scripts/scan-phi-in-logs.sh
if git diff --cached | grep -iE '(SSN|birthdate|address|phone)' -- '*.log'; then
  echo "ERROR: Potential PHI in log files"
  exit 1
fi
```

Blocks PHI before it hits the repo.

## Missing coverage areas

1. **Performance budgets**: Add thresholds for symptom matrix render time (D3 can be heavy with 20+ symptoms):

   ```ts
   test('D3 symptom matrix renders under 200ms', async () => {
     const start = performance.now();
     render(<D3SymptomMatrix symptoms={fixtures.d3Psychosis} />);
     expect(performance.now() - start).toBeLessThan(200);
   });
   ```

2. **Concurrent edit conflicts**: If two clinicians edit the same assessment:

   ```ts
   test('concurrent edits show conflict resolution UI', async () => {
     const session1 = await createSession();
     const session2 = await createSession();
     
     await session1.fill('[data-testid="d5-stage"]', 'Action');
     await session2.fill('[data-testid="d5-stage"]', 'Contemplation');
     
     await session1.save();
     const result = await session2.save();
     
     expect(result.conflictUI).toBeVisible();
   });
   ```

3. **Export format variations**: Test both FHIR and legacy formats if supported:

   ```ts
   test.each(['fhir', 'legacy'])('%s export includes all D1-D6 data', 
     async (format) => {
       const exported = await exportAssessment(
         fixtures.highDetoxRisk, 
         format
       );
       expect(exported).toMatchSnapshot(`export-${format}`);
     }
   );
   ```

## Immediate execution order

Based on risk and dependency:

1. **Phase 0 + Phase 1** (Day 1): Freeze and contract validation. If contracts break, stop.
2. **Phase 2 fixtures** (Day 2): Build `high-detox-risk.json`, `unsafe-home.json`. These feed everything else.
3. **Phase 3 critical unit tests** (Days 3-4): TTL, destructive clear, D3 second marker, D6 banner triggers.
4. **Phase 4 E2E smoke + risk paths** (Days 5-6): Withdrawal banner, suicidal banner, offline autosave.
5. **Parallel Phase 5-7** (Days 7-9): Visual/a11y/security can run in parallel once logic is green.
6. **Phase 8 UAT** (Days 10-11): Only after code is clinically correct.
7. **Phase 9 release** (Day 12): Compile artifacts and handoff.

## Question for prioritization

Are there **regulatory deadlines** (Joint Commission, state licensing) that require specific dimensions (e.g., D3 suicide risk, D6 safety) to be audit-ready first? If so, test those dimensions end-to-end before completing others.

Do you want me to draft the traceability matrix template or the Playwright smoke test scaffold as a starting point?
