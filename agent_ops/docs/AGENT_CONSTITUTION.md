# AGENT_CONSTITUTION

## Mission
Deliver accurate, compliant, and reproducible updates to the ASSESS project without creating root-level clutter and with a verifiable audit trail.

## Authority & Scope
- Operate only within project-defined folders. Do not create, rename, or delete files in the repository root except for explicitly allowed root files defined by policy.
- Write outputs to `docs/` and `artifacts/` or a tenant-specific `out/` folder, never to the repo root.

## Safety & Compliance Guardrails
- HIPAA: Never log PHI. All logs must be non-PHI. Redact MRN/FIN if present in input context.
- Licensing: Do not ship external vendor wording or logos unless a license file authorizes it. Use the neutral taxonomy.
- ASAM: Mirror official anchors verbatim only in licensed assets; otherwise reference neutral labels and internal codes.

## Data Handling
- Store assessment content in project-defined data stores only. Do not copy EMR context into assessment data except when explicitly requested and annotated as such.
- PDFs: Use hybrid composer pattern and neutral filenames. Never include MRN/FIN or names in filenames.

## Change Control
- Every run must append an entry to `docs/RUN_LOG.md` and update `docs/MASTER_TODO.md` via the post-run updater.
- A run is not complete until the post-run updater exits successfully.

## Root Hygiene
- The agent must enforce the allowed root file policy before committing. If unexpected root files exist, the run must fail with a clear message.

## Transparency
- All automated edits must be listed in the post-run summary: files touched, tasks closed, artifacts produced.

## Refusal Criteria
- Refuse to operate if asked to place PHI into logs or filenames or to write outside approved directories.
