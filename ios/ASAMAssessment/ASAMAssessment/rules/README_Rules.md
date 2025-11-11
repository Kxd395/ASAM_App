# Rules Directory

Production-grade rules engine configuration for ASAM Assessment application.

## Philosophy

**Rules as data, not code.** All clinical logic, validation checks, and navigation paths live in versioned JSON/YAML files. This enables:

- Hot-reload during development
- Patch rules without binary release
- A/B testing of logic variants
- Audit trail of rule changes
- Separation of neutral vs licensed content

## Files

### `anchors.json`
**Severity anchors by domain (A-F)**

- Neutral descriptive text for each severity level (0-4)
- Used for UI tooltips and clinician reference
- Production: replace with licensed ASAM text in separate asset bundle

Schema:
```json
{
  "domains": {
    "A": {
      "title": "Domain Name",
      "anchors": {
        "0": ["bullet 1", "bullet 2"],
        "1": [...],
        ...
      }
    }
  }
}
```

### `wm_ladder.json`
**Withdrawal Management indication logic**

- Deterministic rules to set `wm_indicated` flag
- Suggests candidate WM levels (1.7, 2.7, 3.7, 4.0)
- Uses substance type, withdrawal scores (COWS/CIWA), timing

Evaluation strategy: **max_priority_true**
- Evaluate all rules
- Return highest-priority rule where conditions match
- Default to `wm_indicated: false` if no rules fire

Schema:
```json
{
  "rules": [
    {
      "rule_id": "unique_id",
      "priority": 100,
      "if": {
        "substance": "opioid",
        "cows_score": ">=8"
      },
      "then": {
        "wm_indicated": true,
        "candidate_levels": ["1.7-WM", "2.7-WM"],
        "rationale": "Explanation"
      }
    }
  ]
}
```

### `loc_indication.json`
**Level of Care indication engine**

- Threshold rules using domain severities (A-F) and WM status
- Returns indicated LOC code and rationale
- Covers all ASAM levels (0.5, 1.0, 1.7-WM, 2.1, 2.5, 2.7-WM, 3.1, 3.3, 3.5, 3.7, 3.7-WM, 4.0, 4.0-WM)

Evaluation strategy: **first_match_by_priority**
- Evaluate rules in descending priority order
- Return first rule where all conditions match

Schema:
```json
{
  "rules": [
    {
      "rule_id": "unique_id",
      "priority": 100,
      "if": {
        "severity_A": "==4",
        "or": {"severity_B": "==4"}
      },
      "then": {
        "indicated_loc": "4.0",
        "rationale": "Explanation"
      }
    }
  ]
}
```

Aggregate functions used in conditions:
- `count_severity_3_or_4`: Count domains with severity >= 3
- `any_severity_4`: True if any domain == 4
- `all_severity_below`: True if all domains < threshold

### `validation_rules.json`
**Three-tier validation checks**

- **Blocker**: Prevents export (must resolve)
- **Gap**: Review warning (should address)
- **Advisory**: Non-binding suggestion

Each rule includes:
- Expression to evaluate
- Failure message
- Breadcrumb for Fix button navigation
- Fix hint text

Schema:
```json
{
  "rules": [
    {
      "id": "unique_id",
      "tier": "blocker",
      "expr": "count(domains where severity is not null) == 6",
      "message": "Error message",
      "crumb": "module/assessment/{assessment_id}/domains",
      "fix_hint": "Help text"
    }
  ]
}
```

### `crumbs.yml`
**Breadcrumb navigation registry**

- Single source of truth for deep-link paths
- Used by Fix buttons, autosave resume, back-stack navigation
- Maps crumb strings to screens and parameters

Format: `module/resource/{id}/sub-resource`

Schema:
```yaml
crumbs:
  - path: "module/assessment/{assessment_id}/domain/{domain_key}"
    description: "Description"
    screen: "ScreenName"
    parameters:
      assessment_id: "UUID"
      domain_key: "String"
```

## Usage in Swift

### Load rules at app launch

```swift
class RulesService: ObservableObject {
    @Published var anchors: [String: DomainAnchors] = [:]
    @Published var wmRules: [WMRule] = []
    @Published var locRules: [LOCRule] = []
    @Published var validationRules: [ValidationRule] = []
    @Published var crumbs: [CrumbDefinition] = []
    
    init() {
        loadRules()
    }
    
    func loadRules() {
        // Load from bundle or file system
        // Parse JSON/YAML
        // Store in @Published properties
    }
}
```

### Evaluate WM indication

```swift
func evaluateWM(assessment: Assessment) -> WMResult {
    let matchingRules = wmRules.filter { rule in
        evaluate(rule.conditions, against: assessment)
    }
    
    // Return highest-priority match
    return matchingRules
        .sorted { $0.priority > $1.priority }
        .first?
        .then ?? WMResult(indicated: false)
}
```

### Evaluate LOC indication

```swift
func evaluateLOC(assessment: Assessment) -> LOCResult {
    for rule in locRules.sorted(by: { $0.priority > $1.priority }) {
        if evaluate(rule.conditions, against: assessment) {
            return LOCResult(
                code: rule.then.indicated_loc,
                rationale: rule.then.rationale
            )
        }
    }
    return LOCResult(code: "0.5", rationale: "Default: minimal risk")
}
```

### Run validation

```swift
func validate(assessment: Assessment) -> ValidationReport {
    var blockers: [ValidationIssue] = []
    var gaps: [ValidationIssue] = []
    var advisories: [ValidationIssue] = []
    
    for rule in validationRules {
        if !evaluate(rule.expr, against: assessment) {
            let issue = ValidationIssue(
                rule: rule,
                crumb: fillPlaceholders(rule.crumb, with: assessment)
            )
            
            switch rule.tier {
            case "blocker": blockers.append(issue)
            case "gap": gaps.append(issue)
            case "advisory": advisories.append(issue)
            }
        }
    }
    
    return ValidationReport(
        blockers: blockers,
        gaps: gaps,
        advisories: advisories,
        exportAllowed: blockers.isEmpty
    )
}
```

### Navigate via crumb

```swift
func navigate(to crumb: String) {
    // Parse crumb string
    let components = parseCrumb(crumb)
    
    // Look up in crumbs registry
    guard let definition = findCrumbDefinition(components) else {
        showToast("Content not found")
        return
    }
    
    // Extract parameters
    let params = extractParameters(from: components, using: definition)
    
    // Navigate to screen
    if definition.modal {
        presentModal(definition.screen, params: params)
    } else if definition.drawer {
        showDrawer(definition.screen, params: params)
    } else {
        navigate(to: definition.screen, params: params)
    }
    
    // Scroll to field if specified
    if let scrollTarget = definition.scroll_to {
        scrollToField(params[scrollTarget])
    }
}
```

## Hyper-Critical Notes

1. **Never bake clinical logic in Swift code**
   - All thresholds, conditions, and rationales belong in JSON
   - Code should only interpret and execute rules

2. **Determinism required**
   - Rule evaluation must be reproducible
   - No randomness, no ML black boxes
   - Same inputs → same outputs always

3. **Versioning**
   - Include `version` and `updated` fields in all rule files
   - Track rule changes in version control
   - Consider schema migration path for future changes

4. **Hot reload in dev**
   - Watch rule files for changes during development
   - Reload and re-evaluate without app restart
   - Makes iteration fast and safe

5. **Licensed content separation**
   - Current anchors use neutral language
   - Production: load licensed ASAM text from separate asset bundle
   - Never mix licensed and neutral content in same file

6. **Expression language**
   - Keep expression syntax simple and unambiguous
   - Document all operators and functions
   - Consider using existing parser (e.g., JSON Logic) vs custom

7. **Testing**
   - Unit test rule evaluation with known assessment scenarios
   - Test edge cases (all zeros, all fours, mixed)
   - Test validation Fix button navigation

8. **Performance**
   - Cache parsed rules at app launch
   - Re-evaluate only when assessment data changes
   - Consider memoization for expensive aggregate functions

## Next Steps

See `agent_ops/docs/MASTER_TODO.md` for implementation tasks:

- **T-0010**: Canonical JSON encoder (for seals and hashing)
- **T-0011**: OverflowPredictor (text overflow detection)
- **T-0012**: SafetyAction modal and persistence
- **T-0013**: Crumb anchors wired to all rules and forms
- **T-0014**: DocumentReference upload with Binary fallback
- **T-0015**: MAC chain for audit events
- **T-0016**: Accessibility pass (contrast, focus, large type)

---

Last updated: 2025-11-09
Version: 1.0.0
