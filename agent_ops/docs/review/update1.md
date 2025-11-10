Done. I generated the rule stubs, the breadcrumb registry, and updated your Master TODO with T-0010 through T-0016. Everything is packaged cleanly (no root clutter).

Download:

* [agent_rules_update.zip](sandbox:/mnt/data/agent_rules_update.zip)

### What’s inside

```
agent_ops/
  rules/
    anchors.json            # Severity anchors per domain (neutral text)
    wm_ladder.json          # Deterministic WM indication + candidate levels
    loc_indication.json     # Threshold rules for indicated LOC
    validation_rules.json   # Blocker/Gap/Advisory checks + crumb targets
    crumbs.yml              # Registry for deep-linking Fix buttons
    README.md               # Brief schema + usage notes
  docs/
    TODO_INDEX.json         # Updated with T-0010..T-0016
    MASTER_TODO.md          # Regenerated checklist view
```

### How to wire these in (quick)

* Load JSON at app launch into `RulesService`. Keep them hot-reloadable for dev.
* Rules engine:

  * **WM**: evaluate `rules/wm_ladder.json` using `max_priority_true`, set `wm.indicated` and `wm.candidate_levels`.
  * **LOC**: feed severities A..F and `wm.candidate_levels` to `rules/loc_indication.json`; pick the highest-precedence rule that fires → `indicated_loc`.
  * **Validation**: evaluate `rules/validation_rules.json`; each failure emits a crumb string from the rule for one-tap “Fix”.
* Breadcrumbs: use `rules/crumbs.yml` as the single source of truth for deep links.

### Hyper-critical implementation notes

* **Determinism**: Use one canonical JSON encoder (sorted keys, UTC ISO8601) for any hashed payloads. That’s T-0010.
* **Overflow**: Add the OverflowPredictor now (T-0011) so you solve “text_may_overflow” before building the PDF composer.
* **Safety gate**: Don’t block data entry anywhere; only block **Export** until “safety_resolved_before_export” is satisfied (T-0012).
* **Crumbs**: Every validation rule must point to an actionable crumb; keep templates in data, not code (T-0013).
* **Upload**: Implement Binary → DocumentReference fallback for large PDFs, and attach Provenance (T-0014).
* **Tamper-evidence**: Add a MAC chain to `audit_events` plus a small verifier CLI (T-0015).
* **A11y**: Contrast, focus order, and large type pass (T-0016).

If you want, I can also add a tiny `RulesService` Swift file that loads these JSONs, exposes evaluation helpers, and connects to your ViewModels next.

Confidence: 96%
