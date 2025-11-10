Got the new rules pack. Here’s a tight, hyper-critical review plus concrete fixes so your agent can implement without guessing.

# Verdict

Solid foundation. The rules are coherent and wired for breadcrumbs, but there are edition drift, naming, and evaluation edge cases that will bite you if we do not tighten them now. The README and TODO are consistent with the artifacts you shipped.   

---

# What looks right

* **Rules as data** with neutral anchors and no licensed copy included. Good separation for a future asset bundle.  
* **WM ladder** encoded deterministically with priorities, not ML. Clear substance scopes and outputs. 
* **LOC indication** uses a priority stack and aggregate operators. Covers the full ladder including WM flavors. 
* **Validation tiers** and crumbs ready for Fix buttons, including overflow warnings. 
* **Documentation** explains evaluation strategies and the crumbs registry pattern.  
* **Program management** shows the new tasks and status in MASTER_TODO and TODO_INDEX.  

---

# High risk issues to fix now

1. **Edition drift and label collisions**

* Anchors use ASAM 3 style titles for dimensions. If you intend to support ASAM 4 names too, you need edition scoping or two files. Example: D1 title is “Acute Intoxication/Withdrawal Potential” which is ASAM 3 wording. In ASAM 4 the dimension naming shifts. Add `"edition": "asam3"` at file root or create `anchors.asam3.json` and `anchors.asam4.json`. 
* LOC rules include 3.3 and WM hyphenated levels while your ASAM 4 plan integrates WM into certain levels and may drop 3.3 program labeling. Add `"edition_matrix"` or `"enabled_levels"` so environments can switch sets without forking code. 

2. **LOC and WM coupling can double count**

* `loc_indication.json` has both base 3.7 and 3.7-WM rules plus a WM escalation rule. In some scenarios both will match and first-match priority decides. That is fine, but make it explicit by adding a guard that 3.7 base should not fire if a 3.7-WM rule already matched with higher priority. Otherwise clinicians will see unexplained “flip” when a substance field toggles. 

3. **Validation boolean that reads backward**

* `signature_required_before_export` uses `status == 'signed' or export_disabled`. If you compute this as a rule that “must be true,” you could accidentally green-light export in states where export is disabled for another reason but signature is missing. Recommend changing to either `status == 'signed'` only or split into two separate checks whose results the exporter explicitly consumes. 

4. **Crumb coverage must be proven, not assumed**

* Validation rules reference crumbs like `wm_plan`, `loc_discrepancy`, `domain/{domain_key}/field/{field_id}`. Ensure every crumb string from `validation_rules.json` exists in `crumbs.yml` with parameters and scroll targets. Add a build check that fails if a crumb is not resolvable. The README implies this pattern but the guarantee should be automated.  

5. **Neutral anchors need schema and version pinning**

* The anchors file lacks a `$schema` and explicit version field. Add both and include a `ruleset_hash` for audit. The README talks versioning generally, but the file itself should enforce it for safety and legal defensibility. 

6. **LOC operators need deterministic definitions**

* `all_severity_below`, `count_severity_2_or_3`, and composites need exact operator semantics in a mini spec so the evaluator implemented in Swift matches the intent byte for byte. Add an `operators.json` that your evaluator loads so testing is not tied to comments only. Current comments are helpful but not enforceable. 

7. **README shows patterns but not conformance tests**

* You need a tiny fixtures suite that proves the engine returns the same indicated LOC and WM outcomes for named scenarios, and that each rule id appears in audit logs. Your “Rules Infrastructure Complete” doc references readiness but not fixtures. Add a fixtures folder with at least 12 cases. 

---

# Medium risk issues

* **WM ladder thresholds**: CIWA and COWS cutoffs are present but you should confirm scoring ranges and bounds handling in evaluator, for example inclusive vs exclusive on “>= 10” and stale timestamp guarding for “last_use_hours”. The rule comments are clear, but the engine must normalize inputs first. 
* **Overflow thresholds**: You define coarse thresholds, but PDF fonts and line heights differ. Treat these as preflight hints only and always add a dynamic overflow page. The rule already warns, which is good. Pair it with a deterministic overflow renderer test. 
* **Program capability alignment**: When a program cannot perform WM at the level indicated, the rules do not currently down-shift gracefully. Add an advisory plus a resolver that picks the nearest supported level or flags “no compatible program,” rather than letting the UI present an impossible choice. 

---

# Concrete fixes to apply

Add these files and updates to the rules pack, then wire a tiny conformance test harness.

1. **Split anchors by edition or scope anchors**

* Create `anchors.asam3.json` and `anchors.asam4.json` or add `"edition": "asam3"` plus a second file later. Include `$schema`, `version`, `updated`, and `ruleset_hash`. 

2. **Gate levels by edition**

* In `loc_indication.json`, add `"enabled_levels": ["0.5","1.0","1.7-WM","2.1","2.5","2.7-WM","3.1","3.3","3.5","3.7","3.7-WM","4.0","4.0-WM"]` and plan to toggle per tenant. Add an explicit “no match” fallback that emits a blocker so clinicians never see an empty indicated level. 

3. **Tighten signature rule**

* Change `signature_required_before_export` to `status == 'signed'` only. Add a separate exporter gate that checks both “no blockers” and “signed” to enable the button. 

4. **Crumb linter**

* Add a tiny script to parse `validation_rules.json` and ensure every `crumb` path exists in `crumbs.yml`, with parameters declared. Fail CI if any do not match.  

5. **Operators manifest**

* Create `operators.json` documenting each function and the evaluator’s exact semantics, including inclusivity on bounds and truth table for `implies`. The LOC and WM files both reference these operators in prose. Encode them as data so your evaluator is table driven.  

6. **Fixtures and golden outputs**

* Add `tests/fixtures/` with JSON inputs and expected outputs for at least these 12 cases: opioid acute, alcohol CIWA severe, benzo chronic, stimulant severe, polysubstance with comorbidity, low risk outpatient, environment 3 plus moderate clinical, psychiatric crisis, medical crisis, WM indicated with 2.7 choice, WM escalates to 3.7, all zeros early intervention. Reference rule ids in expected “why” fields. 

7. **Ruleset hash in audit and PDF seal**

* Compute SHA-256 over the concatenated normalized rules files at export time and store in audit events and add to the PDF footer. This lets you prove which logic produced a decision later. The README already encourages determinism, so make it verifiable. 

---

# Suggested TODO additions

Append these to the master list so the agent has concrete work items to close the gaps.

* **T-0017** P1 Add edition scoping for anchors and levels, plus ruleset_hash computation.
* **T-0018** P1 Replace signature rule with strict check and wire exporter gate.
* **T-0019** P1 Add crumb linter that validates all rule crumbs against crumbs.yml in CI.
* **T-0020** P1 Create operators.json and wire evaluator to data driven operators.
* **T-0021** P1 Add rules fixtures with golden outputs and include rule ids in audit logs.
* **T-0022** P2 Implement WM to LOC guard so 3.7 base does not fire if 3.7-WM already matched at higher priority.
* **T-0023** P2 Add program capability resolver that down-shifts or flags no compatible program.
* **T-0024** P2 Add ruleset hash to PDF seal and audit events.

These extend the plan already captured in MASTER_TODO and TODO_INDEX and keep everything out of the repo root as you requested.  

---

# Ready to paste agent notes

* Always load rules from `agent_ops/rules` only. Never from the app bundle root. The README is the single integration reference. 
* On every run, write back MASTER_TODO status and append an audit event with the ruleset hash and versions used. 
* Before export, run validation and block if any blocker tier issues remain. Use each issue’s crumb for Fix navigation. 
* When WM is indicated, evaluate LOC after WM so escalation rules are applied once, not twice.  

If you want, I can generate the edition scoped anchors file, the operators manifest, and a starter fixtures set next, and add the new tasks to MASTER_TODO for you.

