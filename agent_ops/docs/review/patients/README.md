# Test Fixtures – 10 Patients

This folder contains synthetic data for local testing of the Neutral Six‑Domain Assessment app.

**Files**
- `case_001.json` … `case_010.json` — Patient, Encounter, Assessment (domains A–F + d1..d6 mirror), Vitals, UDS, Substance rows
- `fixtures_index.json` — Quick lookup of MRN/FIN and domain severities

**Notes**
- Timestamps are fixed relative for deterministic tests (do not depend on current clock).
- UDS values use: `"positive"`, `"negative"`, or `"n/a"` (for analytes not on the urine panel).
- These are fully synthetic and safe for demo use.
