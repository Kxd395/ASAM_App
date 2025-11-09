# ASAMPlan POC — Drop‑in Integration Package

This package is a ready‑to‑use scaffold for your iPad **ASAM Treatment Plan** proof of concept.
It includes a VS Code task runner, a Python “agent” CLI, a Swift CLI for PDF export,
and governance files to keep the project compliant from day one.

## Quickstart (Mac)
1. Install Xcode command line tools: `xcode-select --install`
2. Open this folder in VS Code.
3. Put your official PDF at `assets/ASAM_TreatmentPlan_Template.pdf` (see placeholder).
4. From VS Code, run task **Agent: Export PDF**. The output PDF will appear in `out/`.

## App and package names
- App name: **ASAMPlan POC**
- Bundle ID: `org.axxessphila.asamplan.poc`
- App Group: `group.org.axxessphila.asamplan.poc`
- Data path: `Library/Application Support/ASAMPlanPOC/ASAMPlan.sqlite` (on device)
- Export filename pattern: `ASAMPlan_<random>.pdf` (no PHI in filenames)

## Security defaults in this repo
- Non‑PHI filenames for outputs
- `out/` is git‑ignored
- PDF export uses **AcroForm fill** first; signature is stamped; footer contains the cryptographic seal
- Guidance for exclusion from backup and file protection is in code comments

## Contents
- `agent/asm.py` — Python CLI for hashing, validation, and PDF export orchestration
- `tools/pdf_export/PDFExport.swift` — Swift CLI that fills AcroForms and adds a footer seal
- `scripts/build-swift-cli.sh` — Build script for the Swift CLI
- `assets/ASAM_TreatmentPlan_Template.pdf.PLACEHOLDER.txt` — Drop the official PDF next to this file
- `assets/sample_signature.png` — Tiny sample signature image for stamping
- `data/plan.sample.json` — Canonical sample plan JSON
- Governance: `AGENT_CONSTITUTION.md`, `FILE_RULES.md`, `PRODUCT_DESCRIPTION.md`, `SECURITY.md`, `PRIVACY.md`, `CHANGELOG.md`, `TASKS.md`, `LICENSE`

## VS Code tasks
- **Agent: Scaffold** — Makes sure folders exist
- **Agent: Plan Hash** — Prints SHA‑256 of the canonical JSON
- **Agent: Validate** — Minimal POC validator
- **Agent: Build pdf_export** — Builds the Swift CLI
- **Agent: Export PDF** — Full pipeline: fill AcroForms, optional signature, footer seal

Generated: 2025-11-09 01:42:30
