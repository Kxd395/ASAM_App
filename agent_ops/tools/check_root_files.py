#!/usr/bin/env python3
import os, json, sys

# When installed at <repo>/agent_ops/tools/check_root_files.py
# REPO_ROOT is the parent directory of agent_ops
TOOLS = os.path.dirname(__file__)
AGENT_OPS = os.path.dirname(TOOLS)
REPO_ROOT = os.path.dirname(AGENT_OPS)

with open(os.path.join(AGENT_OPS, "docs", "ALLOWED_ROOT.json"), "r", encoding="utf-8") as f:
    allow = set(json.load(f)["allowed"])

violations = []
for name in os.listdir(REPO_ROOT):
    if name in ("agent_ops",".git"):
        continue
    p = os.path.join(REPO_ROOT, name)
    if os.path.isdir(p):
        # Ignore directories (we only police stray files)
        continue
    if name not in allow:
        violations.append(name)

if violations:
    print("Root hygiene error: unexpected files in repo root:", ", ".join(violations))
    sys.exit(2)
else:
    print("Root hygiene OK.")
