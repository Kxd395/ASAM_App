Nice—let’s knock out two birds:

1. **Rules Evaluator** scaffolding (RulesService.swift + engine)
2. **Guard Logic (T-0022)** to prevent WM/LOC double-counting

I built a ready-to-drop pack with the rules guard and a Swift evaluator you can plug in today.

**Download:**
[rules_ios_integration_pack.zip](sandbox:/mnt/data/rules_ios_integration_pack.zip)

### What’s inside

```
agent_ops/
  rules/
    operators.json                 # Data-driven operator semantics
    loc_indication.guard.json      # UPDATED: precedence + WM guard
  ios/
    RulesEngine.swift              # JSON-driven evaluator
    RulesService.swift             # Thin facade for your app
    README.md                      # How to wire it
    Tests/
      RulesEngineTests.swift       # XCTest scaffold (wire to fixtures)
```

### How to wire it (fast path)

```swift
// App start / DI container
let rules = try RulesService(
  bundle: .main,
  wmRulesPath: "agent_ops/rules/wm_ladder.json",
  locRulesPath: "agent_ops/rules/loc_indication.guard.json",
  operatorsPath: "agent_ops/rules/operators.json"
)

// When assessing:
let result = rules.evaluate(
  severities: ["A":2,"B":1,"C":1,"D":1,"E":2,"F":1],
  d1Context: ["substances":[["substance_group":"opioid","last_use_hours":12,"cows":9]]],
  flags: ["vitals_unstable":false,"no_withdrawal_signs":false]
)
// -> result.wm.indicated / candidateLevels
// -> result.loc.indicated / why
```

### What the guard does (T-0022)

* Adds **`loc_wm_escalation`** precedence rule: if `wm_candidate` includes `3.7` or `4.0`, LOC jumps to at least **3.7**.
* Adds **negative membership guard** for base medical rules: `{"wm_candidate": ["!3.7","!4.0"]}` so **base 3.7** never fires if a stronger **WM** rule already did.
* Ensures deterministic ordering via `precedence` values.
  Result: no flip-flop when a clinician toggles WM inputs.

### Operators now data-driven

`operators.json` defines the semantics your engine uses:

* `numeric_cmp` for strings like `">=3"`, `"< =2"`
* `bool_eq` for strict booleans
* `string_in` for membership (with support for negated `"!3.7"` entries in `wm_candidate`)

This matches the JSON ruleset style you’ve adopted and keeps logic out of code.

### Tests

* You already have **12 golden fixtures** under `agent_ops/tests/fixtures/`.
* Point an XCTest at those JSON files and compare engine output (`wm`, `loc`) to `expected`.
* I included `RulesEngineTests.swift` as a scaffold—just add a file-loader to your test bundle.

### Hyper-critical notes

* The evaluator intentionally **does not** embed clinical constants; all thresholds must come from JSON. If a decision is off, fix the rules, not the code.
* File resolution in `RulesService` tries absolute path first, then bundle. Keep rules under `agent_ops/rules/` to avoid root clutter (your repo contract).
* The guard file is named `loc_indication.guard.json`. Update your app config to point there. When you formalize, you can rename it back to `loc_indication.json`.

### Suggested next move

* **Run your fixtures** with this evaluator to prove parity.
* Then start **iOS Development (T-0003)**: Problems CRUD + validation crumbs hooked to the same rules outputs.

Want me to wire the XCTest to load `/agent_ops/tests/fixtures` automatically and spit a pass/fail report you can drop into CI? I can generate that next.
