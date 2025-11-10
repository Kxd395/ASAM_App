# iOS Rules Integration Pack

Drop `agent_ops/ios/*.swift` into your app target. Ship rules files in-app under `agent_ops/rules/` (or point to your sandbox path).

## Files
- RulesEngine.swift — JSON-driven evaluator supporting numeric comparisons, boolean tests, and membership.
- RulesService.swift — Thin facade that resolves URLs and exposes a simple `evaluate` API.
- Tests/RulesEngineTests.swift — Scaffold for your XCTest target.

## Usage (Swift)
```
let service = try RulesService()
let result = service.evaluate(
    severities: ["A":2,"B":1,"C":1,"D":1,"E":2,"F":1],
    d1Context: ["substances":[["substance_group":"opioid","last_use_hours":12,"cows":9]]],
    flags: ["vitals_unstable":false,"no_withdrawal_signs":false]
)
print(result.wm, result.loc)
```

Notes:
- This engine is deterministic and table-driven. It does not embed vendor wording.
- Update `loc_indication.guard.json` when editing WM/LOC precedence to avoid double-counting.
