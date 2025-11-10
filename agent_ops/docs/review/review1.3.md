Locked in. I generated the 12-case rules fixtures with golden outputs and updated your master checklist.

**Download:**

* [asam_rules_fixtures.zip](sandbox:/mnt/data/asam_rules_fixtures.zip)

### What you got

```
agent_ops/
  tests/
    README.md
    run_fixtures_example.py      # skeleton; plug in your evaluator
    fixtures/
      case_001.json  ... case_012.json  # inputs + expected outputs
  docs/
    TODO_INDEX.json              # T-0021 added/marked done
    MASTER_TODO.md               # regenerated summary/checklist
```

### Fixture coverage (high-level)

1. Opioid acute WM (1.7/2.7) with outpatient LOC 2.1
2. Alcohol CIWA severe → WM candidates 2.7/3.7 → LOC 3.7
3. Vital instability → WM candidates 3.7/4.0 → LOC 3.7
4. Severe A&B (4/4) → LOC 4.0
5. Psych crisis + environment risk → LOC 3.5
6. Environment structure need → LOC 3.1
7. Stable outpatient → LOC 2.1
8. No withdrawal signs → no WM
9. Polysubstance + biomedical ≥3 → LOC 3.7
10. WM candidate 2.7 only → no LOC escalation (stays 2.1)
11. Co-occurring advisory raised (C≥2/B≥2, program not capable)
12. Discrepancy reason required blocker (indicated ≠ actual, no reason)

Each `case_XXX.json` has:

* `input`: neutral severities A–F, D1 substance details, flags
* `expected`: `wm`, `loc`, and `validation` outcomes, aligned to your rule IDs

### How to use

* Wire your Swift evaluator to consume `fixtures/*.json` and compare with `expected`.
* Add CI step: run the same inputs against your engine and diff the output; fail on any mismatch.
* Keep all files under `agent_ops/` so nothing leaks into repo root.

### Recommend next

* **T-0022**: WM/LOC guard to avoid double-counting edge cases
* **T-0003**: Problems CRUD with validation integration (iOS)

If you want, I can generate the WM/LOC guard rules tweak and add a minimal Swift `RulesService` stub that loads these fixtures and runs them in a unit test target.

