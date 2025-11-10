# Rules Pack

This folder contains neutral, internal rule data that the app loads at runtime.
- anchors.json: Severity anchors per domain (A..F). Neutral wording.
- wm_ladder.json: Deterministic rules to indicate WM and candidate levels.
- loc_indication.json: Threshold-based LOC suggestion rules.
- validation_rules.json: Blocker/Gap/Advisory checks with crumb targets.
- crumbs.yml: Registry for deep-linking Fix buttons.

Do not embed vendor-proprietary wording. Treat these as internal policy.
