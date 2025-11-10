# Agent Constitution

**Last Updated**: November 9, 2025  
**Authority**: Project governance  
**Relationship to INDEX.md**: This document defines rules; [INDEX.md](../../INDEX.md) is the Single Source of Truth for project navigation and status.

---

These rules govern how the agent and developers work in this repository.

## 📚 Navigation

**⭐ ALWAYS consult [INDEX.md](../../INDEX.md) for:**
- Current project status
- Active priorities
- Documentation locations
- Critical action items

**This document defines**: Principles and rules  
**INDEX.md defines**: What, where, and when

---

## Compliance and Safety
1. **No PHI in filenames or logs.** Use opaque IDs.
2. **Use official forms.** Prefer AcroForm fill, never re-typeset legal forms unless unavoidable.
3. **Ephemeral signatures.** Signature images used only to stamp final PDFs; do not persist beyond export.
4. **Backups and sync.** Exclude sensitive output from cloud sync unless your compliance officer has approved.
5. **Local testing only.** This package is POC‑focused and does not transmit PHI to any server.

## Code Quality
1. **Deterministic hashing.** JSON must be encoded with stable key ordering before hashing.
2. **No broken builds.** Keep Swift CLI building on latest stable Xcode.
3. **Zero secrets in repo.** Credentials are not committed; use local environment when needed.

## Operational Discipline
1. **Single Source of Truth.** [INDEX.md](../../INDEX.md) is the master navigation document, always kept current with project status, priorities, and documentation locations.
2. **Change log updates.** Every meaningful change updates `CHANGELOG.md` AND updates [INDEX.md](../../INDEX.md) if the change is significant (new feature, critical fix, structure change).
3. **Task tracking.** Maintain [docs/governance/TASKS.md](TASKS.md) for active work items; reference [INDEX.md](../../INDEX.md) for overall priorities.
4. **Review rules.** Any schema changes require updating field maps and validators.
5. **Documentation organization.** All documentation lives in `docs/` with proper subdirectories (see [PROJECT_STRUCTURE.md](../../PROJECT_STRUCTURE.md)).

## Agent Operations

**⚠️ CRITICAL**: All automated agent work must follow the [agent_ops/](../../agent_ops/) system.

1. **Post-run mandatory.** Every agent run MUST call `agent_ops/tools/agent_postrun.py` before completion. No exceptions.
2. **Root hygiene.** Agent must never create files in repository root except those listed in `agent_ops/docs/ALLOWED_ROOT.json`. Run `agent_ops/tools/check_root_files.py` before committing.
3. **Task tracking.** Update `agent_ops/docs/TODO_INDEX.json` for all completed tasks. The system auto-generates `MASTER_TODO.md`.
4. **Run logging.** All runs logged in `agent_ops/docs/RUN_LOG.md` with no PHI (complies with HIPAA).
5. **HIPAA compliance.** Never log MRN, FIN, patient names in run summaries, filenames, or artifact paths.
6. **Neutral filenames.** Use timestamps and random IDs: `ASAMPlan_20251109120000.pdf`, never `John_Doe_Assessment.pdf`.
7. **Output directories.** Write to `artifacts/`, `out/`, or `docs/` only - never repo root.
8. **Constitution adherence.** Read and follow [agent_ops/docs/AGENT_CONSTITUTION.md](../../agent_ops/docs/AGENT_CONSTITUTION.md) for operational safety rules.

**Integration Guide**: See [agent_ops/docs/INTEGRATION_GUIDE.md](../../agent_ops/docs/INTEGRATION_GUIDE.md) for complete setup and usage.

