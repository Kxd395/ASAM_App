#!/usr/bin/env python3
"""
Crumb Linter - Validates validation rule crumbs against crumbs.yml registry

Ensures every crumb referenced in validation_rules.json exists in crumbs.yml
with proper parameters. Fails CI if any crumbs are unresolvable.

Usage:
    python3 agent_ops/tools/crumb_linter.py

Exit codes:
    0: All crumbs valid
    1: One or more crumbs invalid or missing
"""

import json
import sys
from pathlib import Path
import re
try:
    import yaml
except ImportError:
    print("⚠️  PyYAML not installed. Install with: pip install pyyaml")
    sys.exit(1)

def load_validation_rules():
    """Load validation rules from JSON"""
    rules_file = Path("agent_ops/rules/validation_rules.json")
    if not rules_file.exists():
        print(f"❌ Validation rules file not found: {rules_file}")
        sys.exit(1)

    with open(rules_file, 'r') as f:
        data = json.load(f)

    return data.get('rules', [])

def load_crumb_registry():
    """Load crumb definitions from YAML"""
    crumbs_file = Path("agent_ops/rules/crumbs.yml")
    if not crumbs_file.exists():
        print(f"❌ Crumbs registry file not found: {crumbs_file}")
        sys.exit(1)

    with open(crumbs_file, 'r') as f:
        data = yaml.safe_load(f)

    return data.get('crumbs', [])

def extract_placeholders(crumb_path):
    """Extract parameter placeholders from crumb path

    Example: 'module/assessment/{assessment_id}/domain/{domain_key}'
    Returns: ['assessment_id', 'domain_key']
    """
    return re.findall(r'\{([^}]+)\}', crumb_path)

def normalize_path(path):
    """Normalize crumb path by replacing placeholders with generic marker

    Example: 'module/assessment/{assessment_id}/domain/{domain_key}'
    Returns: 'module/assessment/{id}/domain/{id}'
    """
    return re.sub(r'\{[^}]+\}', '{id}', path)

def match_crumb_pattern(crumb_path, registry_path):
    """Check if a crumb path matches a registry pattern

    Both paths have placeholders. Match structure and placeholder positions.
    """
    # Extract parts (split on /)
    crumb_parts = crumb_path.split('/')
    registry_parts = registry_path.split('/')

    # Must have same number of parts
    if len(crumb_parts) != len(registry_parts):
        return False

    # Each part must either match exactly or both be placeholders
    for c_part, r_part in zip(crumb_parts, registry_parts):
        c_is_placeholder = c_part.startswith('{') and c_part.endswith('}')
        r_is_placeholder = r_part.startswith('{') and r_part.endswith('}')

        # If one is placeholder, other must be too (or exact match)
        if c_is_placeholder != r_is_placeholder:
            # Allow exact match if not both placeholders
            if c_part != r_part:
                return False
        elif not c_is_placeholder and c_part != r_part:
            # Both are literals, must match
            return False

    return True

def find_crumb_definition(crumb_path, registry):
    """Find matching crumb definition in registry"""
    for crumb_def in registry:
        reg_path = crumb_def.get('path', '')
        if match_crumb_pattern(crumb_path, reg_path):
            return crumb_def
    return None

def validate_crumb_parameters(crumb_path, crumb_def):
    """Validate that crumb placeholders match registry parameters"""
    crumb_placeholders = set(extract_placeholders(crumb_path))
    registry_params = set(crumb_def.get('parameters', {}).keys())

    missing = crumb_placeholders - registry_params
    extra = registry_params - crumb_placeholders

    issues = []
    if missing:
        issues.append(f"Missing parameter definitions: {sorted(missing)}")
    if extra:
        issues.append(f"Unused parameter definitions: {sorted(extra)}")

    return issues

def main():
    print("🔍 Crumb Linter - Validating rule crumbs against registry\n")

    # Load files
    validation_rules = load_validation_rules()
    crumb_registry = load_crumb_registry()

    print(f"📋 Loaded {len(validation_rules)} validation rules")
    print(f"📋 Loaded {len(crumb_registry)} crumb definitions\n")

    # Track issues
    all_issues = []

    # Validate each rule's crumb
    for rule in validation_rules:
        rule_id = rule.get('id', 'unknown')
        crumb = rule.get('crumb', '')

        if not crumb:
            all_issues.append(f"❌ Rule '{rule_id}': No crumb defined")
            continue

        # Find matching definition
        crumb_def = find_crumb_definition(crumb, crumb_registry)

        if not crumb_def:
            all_issues.append(f"❌ Rule '{rule_id}': Crumb '{crumb}' not found in registry")
            continue

        # Validate parameters
        param_issues = validate_crumb_parameters(crumb, crumb_def)
        if param_issues:
            all_issues.append(f"⚠️  Rule '{rule_id}': {', '.join(param_issues)}")
        else:
            print(f"✅ Rule '{rule_id}': Crumb valid → {crumb_def.get('screen', 'unknown')}")

    # Report results
    print(f"\n{'='*60}")
    if all_issues:
        print(f"\n❌ Found {len(all_issues)} issue(s):\n")
        for issue in all_issues:
            print(f"  {issue}")
        print(f"\n{'='*60}")
        print("❌ Crumb validation FAILED")
        sys.exit(1)
    else:
        print("\n✅ All crumbs valid - registry complete")
        print(f"{'='*60}")
        sys.exit(0)

if __name__ == '__main__':
    main()
