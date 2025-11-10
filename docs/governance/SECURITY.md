# SECURITY.md

**Threat model**: POC on a developer Mac. The iOS app adds Face ID and idle lock; this repo focuses on PDF pipeline.

## Key controls
- No PHI in filenames.
- Outputs in `out/` are git‑ignored.
- Use FileVault on development Macs.
- Do not place this repo in a consumer cloud‑sync folder.
- When building the iOS app, mark data files as **Complete File Protection** and exclude from iCloud backup.

## Incident response (POC)
- If a PDF with PHI is generated in the wrong place, delete securely and rotate any test data files.
