# AGENT_OPERATIONS

This is the operational playbook for your automation.

## Directory rules
- Allowed root files: defined in `docs/ALLOWED_ROOT.json`.
- All documents: `docs/`
- Scripts and CLIs: `tools/`
- Build outputs: `artifacts/` (create if absent)
- Temp files: `tmp/` (excluded from VCS)

## Run phases
1. PLAN: decide tasks to execute
2. EXECUTE: modify files in-place, generate artifacts into `artifacts/`
3. POSTRUN: call the updater to log results and update the master TODO

## Required post-run call
```
python3 tools/agent_postrun.py   --run-id "$(date +%Y%m%d%H%M%S)"   --actor "agent"   --summary "Short description of what was done"   --completed T-0003 T-0007   --artifacts artifacts/export_2025-11-09.pdf
```

- The updater will:
  - Append a row to `docs/RUN_LOG.md`
  - Mark completed tasks in `docs/TODO_INDEX.json`
  - Regenerate `docs/MASTER_TODO.md`
  - Enforce root hygiene using `tools/check_root_files.py`

## VS Code integration
- Use `.vscode/tasks.json` provided here to wire one-click POSTRUN.

## Root hygiene check (preflight)
```
python3 tools/check_root_files.py
```
This fails if any file in repo root is not whitelisted.

## Notes
- Do not write to repo root. Put new docs under `docs/` and scripts under `tools/`.
- If a task cannot be completed, leave it open and include a reason in the run summary.
