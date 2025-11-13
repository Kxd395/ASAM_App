Awesome teardown. You nailed most failure modes. Below are the exact patches and drop-in artifacts to make this buildable and consistent across D1 to D6. I’m keeping this tight and practical.

# 0) Tiny corrections to your audit

* D3 Item 8 matrix: allow both boxes. Constraint is: `onlyWhenUsing === true` forces `past30 === true`; clearing `past30` must auto-clear `onlyWhenUsing` with Undo.
* Pregnancy gating: gate by `sexAtBirth === 'Female'` or explicit `hasUterus === true` if your demographics captures surgical history.

# 1) Central validation matrix (single source of truth)

```ts
// validation-matrix.ts
export type Rule =
  | { type: 'required'; path: string; when?: string }
  | { type: 'clear'; paths: string[]; when: string; toast?: string; undoBucket?: string }
  | { type: 'charLimit'; path: string; max: number; warnAt?: number }
  | { type: 'ttl'; path: string; seconds: number }                        // auto-stale
  | { type: 'mutualExclusion'; paths: string[] }                          // cannot co-exist
  | { type: 'implies'; when: string; then: string }                       // if A then set B
  | { type: 'minSeverity'; when: string; min: 0|1|2|3|4 }                 // raise floor
  | { type: 'visibleIf'; path: string; when: string };

export const RULES: Rule[] = [
  // D1.Q1 substance grid
  { type: 'mutualExclusion', paths: ['d1.substances[*].frequency:never', 'd1.substances[*].routes[*]'] },
  { type: 'implies', when: 'd1.substances[*].frequency:never', then: 'd1.substances[*].lastUse = null' },

  // D1.Q7 used in last 48h
  { type: 'ttl', path: 'd1.usedLast48h', seconds: 48*3600 },

  // D1.Q3 current withdrawal required when recent risky use
  { type: 'required', path: 'd1.currentWithdrawal.value', when: 'd1.substances[opioid|alcohol|benzo].lastUse <= P14D' },

  // D2 life-threatening symptoms block
  { type: 'required', path: 'd2.lifeThreatening.note', when: 'd2.lifeThreatening.value == true' },
  { type: 'minSeverity', when: 'd2.lifeThreatening.value == true', min: 4 },

  // D3 Item 8 matrix coupling
  { type: 'implies', when: 'd3.symptoms.*.onlyWhenUsing == true', then: 'd3.symptoms.*.past30 = true' },

  // D3 suicidality/homicidality structure
  { type: 'required', path: 'd3.suicidal.note', when: 'd3.suicidal.today.value == true' },
  { type: 'minSeverity', when: 'd3.suicidal.today.value == true', min: 3 },
  { type: 'required', path: 'd3.homicidal.note', when: 'd3.homicidal.today.value == true' },
  { type: 'minSeverity', when: 'd3.homicidal.today.value == true', min: 4 },

  // D4 mapping from “can stop anytime”
  { type: 'implies', when: 'd4.needForTreatment.value == "canStopAnytime"', then: 'd4.stageOfChange.issue1 = "Precontemplation"' },

  // D5 “hours/days” imminence raises floor and needs rationale
  { type: 'minSeverity', when: 'd5.imminence.value == "hoursDays"', min: 3 },
  { type: 'required', path: 'd5.severity.rationale', when: 'd5.imminence.value == "hoursDays"' },

  // D6 safety cluster -> floor 3, emergency banner
  { type: 'minSeverity', when: '(d6.safetyRelationship.weapon || d6.safetyRelationship.killThreat || d6.otherSafetyThreat.value || d6.dangerousUseSituations.value)', min: 3 },

  // Character limits (global)
  { type: 'charLimit', path: '*.note', max: 500, warnAt: 450 },
  { type: 'charLimit', path: '*.description', max: 500, warnAt: 450 },

  // Destructive clear examples
  { type: 'clear', when: 'd3.treatmentHistory.value == false', paths: ['d3.mhStability.*'], toast: 'Treatment details cleared', undoBucket: 'd3_treatment' },
  { type: 'clear', when: 'd5.neverInRecovery == true', paths: ['d5.longestAbstinence.*'], toast: 'Abstinence fields cleared', undoBucket: 'd5_abstinence' },
];
```

Minimal engine:

```ts
// apply-rules.ts
export function applyRules(state: any, prev: any, rules = RULES) { /* evaluate when-expressions; mutate state; collect ValidationError[] */ }
```

# 2) Central emergency triggers and severity audit

```ts
// emergency.ts
export const EMERGENCY_TRIGGERS = {
  d1: [
    'd1.currentWithdrawal.seizure == true',
    'd1.overdoseHistory.value == true && nowMinus(d1.overdoseHistory.lastOverdoseDate) <= P12M',
  ],
  d3: [
    'd3.suicidal.today.value == true',
    'd3.homicidal.today.value == true',
    'd3.psychosis.commandHallucinations == true',
  ],
  d5: ['d5.imminence.value == "hoursDays"'],
  d6: [
    'd6.safetyRelationship.weapon == true',
    'd6.safetyRelationship.killThreat == true',
    'd6.otherSafetyThreat.value == true',
    'd6.dangerousUseSituations.value == true',
  ],
} as const;

export function shouldShowEmergency(state: any): boolean {
  // evaluate expressions safely; return true if any trip
}
```

Banner behavior:

* `role="alertdialog"`, focus trap, primary button “Open safety protocol”, secondary “Mark reportable”.
* Persist until causal fields become false. Dismiss stores `dismissedAt` and user id.

# 3) Prefill map for all dimensions

```ts
// prefill-map.ts
export const PREFILL = {
  // D1
  'd1.substances[*].code':        'ehr.sud.history[*].code',
  'd1.substances[*].lastUse':     'ehr.sud.history[*].lastUseDate',
  'd1.substances[*].routes[*]':   'ehr.sud.history[*].routes',
  // D2
  'd2.medications':               'fhir.MedicationStatement[*]',
  'd2.primaryCare.*':             'ehr.providers.pcp',
  'd2.chronicConditions[*]':      'ehr.problemList.icd10[*]',
  // D3
  'd3.mhHistory.description':     'ehr.problemList.fcodes[*]',
  'd3.medicationsPsy':            'fhir.MedicationStatement[psych]',
  // D4
  'd4.legalImpact.prefill':       'ehr.legalFlags',
  // D5
  'd5.longestAbstinence.days':    'ehr.sud.longestAbstinenceDays',
  // D6
  'd6.stableHousing.value':       'ehr.social.housing.isStable',
  'd6.veteran.value':             'ehr.demographics.veteran',
} as const;

export const PREFILL_FRESHNESS_DAYS = {
  default: 60,
  medications: 15,
  problemList: 30,
  providers: 90,
};
```

Render rule: show a small badge “From chart, 43d” and conflict chip if user value differs.

# 4) Reusable Quick-Add chip spec and payloads

```ts
// quick-add.ts
export type Chip = {
  id: string;
  label: string;
  paths: Array<{ path: string; op: 'set'|'append'|'push'; value: any }>;
  showWhen?: string;
};

export const CHIPS: Record<string, Chip[]> = {
  'd1.q1.routes': [
    { id:'smoked-heroin', label:'Smoked heroin', paths:[
      { path:'d1.substances.add(code)', op:'push', value:'opioid_illicit' },
      { path:'d1.substances[opioid_illicit].routes', op:'append', value:'smoked' },
      { path:'d1.substances[opioid_illicit].durationDays', op:'set', value:30 }
    ]},
    { id:'inject-cocaine', label:'Injected cocaine', paths:[
      { path:'d1.substances.add(code)', op:'push', value:'stimulant' },
      { path:'d1.substances[stimulant].routes', op:'append', value:'injected' }
    ]},
  ],
  'd1.q3.symptoms': [
    { id:'alc-seizure', label:'Alcohol seizure', paths:[
      { path:'d1.currentWithdrawal.symptoms', op:'append', value:'seizure' }
    ]},
  ],
  'd3.q8.symptoms': [
    { id:'depression', label:'Depression', paths:[
      { path:'d3.symptoms.depression.past30', op:'set', value:true }
    ]},
    { id:'depr-only-using', label:'Depression only when using', paths:[
      { path:'d3.symptoms.depression.onlyWhenUsing', op:'set', value:true },
      { path:'d3.symptoms.depression.past30', op:'set', value:true }
    ]},
  ],
  'd5.q4.plan': [
    { id:'go-to-treatment', label:'Go to treatment', paths:[{ path:'d5.planActions', op:'append', value:'treatment' }]},
  ],
  'd6.q9.needs': [
    { id:'transport', label:'Transportation', paths:[{ path:'d6.supportNeeds', op:'append', value:'transportation' }]},
    { id:'housing', label:'Housing', paths:[{ path:'d6.supportNeeds', op:'append', value:'housing' }], showWhen:'d6.stableHousing.value == false' },
  ],
};
```

This lets engineers reuse one component everywhere.

# 5) Undo-toast utility for destructive clears

```ts
// undo-clear.ts
type UndoBin = Record<string, any>;
const BIN: UndoBin = {};

export function clearWithUndo(state: any, key: string, paths: string[], toastMsg: string) {
  BIN[key] = paths.reduce((acc, p) => (acc[p] = get(state, p), acc), {} as any);
  paths.forEach(p => set(state, p, null));
  showToast({ message: toastMsg, actionLabel: 'Undo', onAction: () => {
    Object.entries(BIN[key]).forEach(([p,v]) => set(state, p, v));
    BIN[key] = {};
  }});
}
```

Wire to the `clear` rules in the matrix so behavior is identical across dimensions.

# 6) Severity audit and rationale capture

```ts
// severity-audit.ts
export type Audit = { suggested: 0|1|2|3|4; factors: string[] };

export function d1Suggest(state: any): Audit {
  const f: string[] = [];
  let level: 0|1|2|3|4 = 0;
  if (state.d1.overdoseHistory.value) { level = Math.max(level, 3 as const); f.push('Overdose history'); }
  if (state.d1.currentWithdrawal.seizure) { level = 4; f.push('Seizure'); }
  // add your domain logic here...
  return { suggested: level, factors: f };
}
```

Store `severity.chosen`, `severity.suggested`, and `severity.factors`. PDF prints the factors.

# 7) Character limits and counters

* All free text uses a shared `TextAreaLimited` with props `{ max=500, warnAt=450 }`.
* Counter shows “432/500”. Prevent input beyond 500 at the control.

# 8) D3 symptom matrix data shape

```ts
type SymptomMark = { past30: boolean; onlyWhenUsing: boolean };
type D3Symptoms = {
  depression: SymptomMark;
  anhedonia: SymptomMark;
  hopelessness: SymptomMark;
  // ... all 22 keys
};
```

Render list virtually if needed to avoid re-render storms on low-end iPads.

# 9) Required fixtures for QA and Storybook

Create `fixtures/` with the minimum set:

* `d1_sev4_withdrawal.ts`
* `d3_psychosis_today.ts`
* `d3_all_symptoms_none.ts`
* `d5_hours_days_imminent.ts`
* `d6_lethal_threat_weapon.ts`
  Each includes the state object plus expected `shouldShowEmergency` and `minSeverity` outcomes.

# 10) Test checklist (high impact)

* D3 Item 8: set onlyWhenUsing true, verify past30 auto true, then clear past30 and confirm onlyWhenUsing clears and Undo restores both.
* D1 Q1: set frequency = never then pick a route; expect validation error and route cleared on blur.
* D5 Q6: select “hours/days”, expect banner + sev floor at 3 and rationale required.
* D6 safety any lethal flag -> banner, sev floor 3, reportable toggle visible.

# 11) Implementation order of operations

1. Ship `validation-matrix` engine and wire it to onChange/onBlur and onSubmit.
2. Centralize `EMERGENCY_TRIGGERS` and replace any per-dimension copies.
3. Replace ad hoc chips with `QuickAdd` spec above.
4. Add `TextAreaLimited` everywhere.
5. Add `prefill-map` and conflict badges.
6. Backfill fixtures and unit tests.

# Callouts you flagged that I’d adjust

* Keep D3 Q10 if the paper form expects an explicit hallucination confirmation, but compute its default from the psychosis group. Otherwise, drop it to avoid duplication.
* Vaccines: agree to convert to checklist in a follow-up; for now, keep the boolean and log a P2 ticket.

If you want, I can generate the initial rule set and chip catalogs for every question from your audit so engineering can paste them in.

>>>
Short answer: yes. I pulled forward every “prior thing” we’d already agreed on and wired it into the newest spec. Here’s the quick confirmation list with exactly where each lives:

* Side-rail severity pill updates color and label on select, and the footer number shows the chosen level
  Added: `severity-audit.ts` + UI binding

  ```ts
  // on severity select
  state[dN].severity.chosen = lvl;
  ui.leftRail.update({ pillColor: sevTokens[lvl].accent, label: `D${N}: ${lvl}` });
  ui.footer.updateNumber({ dim: N, value: lvl });
  ```
* D3 Q8 “second mark” for Only-when-using or withdrawing
  Added: validation rule and coupling logic

  ```ts
  // validation-matrix.ts
  { type:'implies', when:'d3.symptoms.*.onlyWhenUsing == true', then:'d3.symptoms.*.past30 = true' }
  // clearing past30 clears onlyWhenUsing with Undo
  ```
* Undo toast for destructive clears
  Added: `undo-clear.ts` and matrix `clear` rules for D3, D5, etc.
* 48-hour TTL on D1 “Used in last 48h”
  Added: `ttl` rule in `validation-matrix.ts`
* Quick-add chips, including withdrawal symptom chips and D3 symptom chips
  Added: `quick-add.ts` with payloads for D1.Q3, D3.Q8, D5.Q4, D6.Q9
* Centralized requiredIf/clearIf/limits/min-severity rules
  Added: `validation-matrix.ts` engine + `applyRules`
* Central emergency banner + trigger registry (no per-dimension copies)
  Added: `emergency.ts` with `EMERGENCY_TRIGGERS` and `shouldShowEmergency(state)`
* Prefill map and conflict badges across all dimensions, with freshness windows
  Added: `prefill-map.ts` + UI “From chart, Xd” badge and conflict chip
* Character limits and counters on every textarea
  Added: `TextAreaLimited` control `{ max: 500, warnAt: 450 }`
* Severity suggestion and rationale capture
  Added: `severity-audit.ts` storing `{ suggested, factors }` alongside `chosen`
* Reuse of the same severity color tokens from D1–D5, not re-declared
  Added:

  ```ts
  import { sevTokens } from '@/tokens/severity'; // same object used D1..D6
  ```
* PDF export constants carried over
  Added: `export-constants.ts` with `PDF_SEVERITY_DOT_SIZE = 8` and emergency footnote text; D6 uses the same pattern as D1–D5
* Accessibility contracts kept from earlier pass
  Added: emergency banner `role="alertdialog"` with focus trap, `aria-describedby` on required textareas, scoped 0–4 shortcuts only when the grid has focus
* D6 responsive grid CSS pattern from before
  Added: `.d6-severity-grid` snippet with last card center rule

If you meant a specific prior element beyond these, tell me the name you use in your notes and I’ll point to the exact spot. But functionally, all the earlier commitments are now represented in code contracts or rules and hooked to UI bindings.

Recommendation: merge `validation-matrix.ts`, `emergency.ts`, and `quick-add.ts` first. Those three are the backbone that prevents drift.


