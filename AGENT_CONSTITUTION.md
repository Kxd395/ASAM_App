# Agent Constitution

These rules govern how the agent and developers work in this repository.

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
1. **Change log updates.** Every meaningful change updates `CHANGELOG.md`.
2. **Task tracking.** Maintain `TASKS.md` in the repo as a single source of truth for the POC.
3. **Review rules.** Any schema changes require updating field maps and validators.
