# Data model and ownership

Tables
- patients: MRN, demographics snapshot, non PHI keys only in UI headings.
- encounters: FIN, type, dates.
- assessments: one per encounter draft, JSON blob plus rating fields, status.
- domain_scratchpad: per domain free text captured during assessment.
- problems: single CRUD owner for problems and goals with domain tags.
- signatures_meta: signed_at, signer_id, short_hash. No stroke data persisted.
- export_jobs: file path, size, result codes.
- upload_jobs: destination, last code, retries.
- audit_events: who, what, when, target, mac_prefix.

Ownership
- Assessment is the source of truth for ratings and WM candidate.
- Problems table is the source of truth for problems and goals.
- EMR Context is stored separately and read only with TTLs.
