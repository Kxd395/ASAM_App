# ASAMPlan POC — EMR Integration Edition

**⚠️ LEGAL NOTICE- 3-da-**Complianc**Compl**Compl**Compliance** (Week 1-4):
- Neutral six-domain assessment (no ASAM branding without license)
- Face ID gate with 2-minute idle lock
- Encrypted audit log (all EMR reads/writes)
- 3-day cache retention policy
- Legal compliance checker (scans for IP violations)

## Quickstart (Mac)k 1-4):
- Neutral six-domain assessment (no ASAM branding without license)
- Face ID gate with 2-minute idle lock
- Encrypted audit log (all EMR reads/writes)
- 3-day cache retention policy
- Legal compliance checker (scans for IP violations)

## Quickstart (Mac)k 1-4):
- Neutral six-domain assessment (no ASAM branding without license)
- Face ID gate with 2-minute idle lock
- Encrypted audit log (all EMR reads/writes)
- 3-day cache retention policy
- Legal compliance checker (scans for IP violations)

## Quickstart (Mac)4):
- Neutral six-domain assessment (no ASAM branding without license)
- Face ID gate with 2-minute idle lock
- Encrypted audit log (all EMR reads/writes)
- 3-day cache retention policy
- Legal compliance checker (scans for IP violations)

## SUDPlan POC — Drop‑in Integration Package

This package is a ready‑to‑use scaffold for your iPad **SUD Treatment Plan** proof of concept.
It includes a VS Code task runner, a Python "agent" CLI, a Swift CLI for PDF export,
and governance files to keep the project compliant from day one.pliance checker (scans for IP violations)

## SUDPlan POC — Drop‑in Integration Package

This package is a ready‑to‑use scaffold for your iPad **SUD Treatment Plan** proof of concept.
It includes a VS Code task runner, a Python "agent" CLI, a Swift CLI for PDF export,
and governance files to keep the project compliant from day one.he retention policy
- Legal compliance checker (scans for IP violations)MPlan POC — Drop‑in Integration Package

This package is a ready‑to‑use scaffold for your iPad **SUD Treatment Plan** proof of concept.
It includes a VS Code task runner, a Python "agent" CLI, a Swift CLI for PDF export,
and governance files to keep the project compliant from day one.is application is not affiliated with or endorsed by the American Society of Addiction Medicine. See [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) for full IP compliance requirements.

This is a **production-ready scaffold** for a Substance Use Disorder Treatment Plan system with EMR integration, built for **iPad deployment** with offline capability and HIPAA compliance.

## 🎯 Project Status

- ✅ **Requirements Approved** — See [`DESIGN_CLARIFICATION.md`](DESIGN_CLARIFICATION.md)
- ✅ **Test Data Created** — 10 synthetic patients covering all scenarios
- ✅ **Legal Framework** — IP compliance guide and prohibited terms list
- ✅ **Restructure Plan** — 4-week migration roadmap
- ⏳ **Implementation** — Ready to start Phase 1

## 🚀 Quick Links

| Document | Purpose |
|----------|---------|
| [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) | **READ FIRST** - ASAM IP compliance requirements |
| [`FIXES_APPLIED_SUMMARY.md`](FIXES_APPLIED_SUMMARY.md) | **NEW** - Executive summary of critical fixes (5 completed) |
| [`CRITICAL_FIXES.md`](CRITICAL_FIXES.md) | **NEW** - Detailed fixes from executive review (1,100+ lines) |
| [`docs/emr-integration.md`](docs/emr-integration.md) | **NEW** - FHIR R4 integration guide (500+ lines) |
| [`docs/mappings/levels.md`](docs/mappings/levels.md) | **NEW** - Private level code mapping (confidential, analyst only) |
| [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md) | What we've built and what's next |
| [`DESIGN_CLARIFICATION.md`](DESIGN_CLARIFICATION.md) | Approved requirements (EMR, workflow, security) |
| [`RESTRUCTURE_PLAN.md`](RESTRUCTURE_PLAN.md) | 4-week migration roadmap |
| [`data/README_TEST_PATIENTS.md`](data/README_TEST_PATIENTS.md) | 10 synthetic test patients documentation |
| [`.specify/memory/constitution.md`](.specify/memory/constitution.md) | Project governance and principles |

## 📋 Current POC Features

**CLI Tools**:
- Python agent (`agent/asm.py`) for plan validation, hashing, and orchestration
- Swift PDF export CLI for AcroForm filling and signature stamping
- SHA-256 cryptographic sealing with canonical JSON

**Security**:
- No PHI in filenames (opaque random IDs)
- `out/` directory git-ignored
- Ephemeral signature handling (delete after stamp)

## 🏗️ Planned Production Features

**EMR Integration** (Week 2-3):
- SMART on FHIR launch from Cerner and EPIC
- Patient identification by MRN (Medical Record Number)
- Encounter tracking by FIN (Financial/Visit Number)
- FHIR R4 API integration (Patient, Encounter, DocumentReference, Observation)

**Offline Capability** (Week 2):
- SQLCipher encrypted local database
- Full-day offline support (8 hours)
- Background sync (every 4 hours when online)
- Manual sync button for immediate updates

**Compliance** (Week 1-4):
- Neutral six-domain assessment (no ASAM branding without license)
- Face ID gate with 2-minute idle lock
- Encrypted audit log (all EMR reads/writes)
- 3-day cache retention policy
- Legal compliance checker (scans for IP violations)MPlan POC — Drop‑in Integration Package

This package is a ready‑to‑use scaffold for your iPad **SUD Treatment Plan** proof of concept.
It includes a VS Code task runner, a Python “agent” CLI, a Swift CLI for PDF export,
and governance files to keep the project compliant from day one.

## Quickstart (Mac)

**Current POC**:
1. Install Xcode command line tools: `xcode-select --install`
2. Open this folder in VS Code
3. Put your official PDF at `assets/ASAM_TreatmentPlan_Template.pdf` (see placeholder)
4. From VS Code, run task **Agent: Export PDF**
5. Output PDF appears in `out/` with opaque filename

**Next Steps (Production)**:
1. Read [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) — **MANDATORY before development**
2. Review [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md)
3. Execute Phase 1 of [`RESTRUCTURE_PLAN.md`](RESTRUCTURE_PLAN.md)
4. Create package structure: `mkdir -p src/sudplan/{models,emr,services,storage,cli,utils,config}`
5. Implement Mock EMR adapter using `data/test_patients.json`
6. Run legal compliance checker: `./scripts/check-legal-compliance.sh`

## App and Package Names

- App name: **Treatment Plan Assistant** (NOT "ASAMPlan" without permission)
- Bundle ID: `org.axxessphila.treatmentplan.poc`
- App Group: `group.org.axxessphila.treatmentplan.poc`
- Data path: `Library/Application Support/TreatmentPlan/TreatmentPlan.sqlite` (encrypted with SQLCipher)
- Export filename pattern: `TreatmentPlan_<UUID>.pdf` (**NO MRN/FIN in filenames**)
- Package name (Python): `sudplan` (internal only, not customer-facing)

## Security Defaults

**Current POC**:
- Non-PHI filenames for outputs (random IDs, no MRN/FIN)
- `out/` directory git-ignored
- PDF export uses AcroForm fill first
- Signature stamped on PDF, then deleted
- Cryptographic seal (SHA-256) in PDF footer

**Production Additions** (see [`DESIGN_CLARIFICATION.md`](DESIGN_CLARIFICATION.md)):
- SQLCipher database encryption (key in iOS Keychain)
- Complete File Protection (iOS data protection)
- Excluded from iCloud backup
- Face ID gate on launch and 2-minute idle
- Encrypted audit log (append-only)
- TLS 1.2+ for EMR communication
- OAuth 2.0 with SMART on FHIR
- 3-day cache retention (auto-purge expired data)
- Signature raster deleted immediately after PDF export

## Contents

**Current POC**:
- `agent/asm.py` — Python CLI for hashing, validation, and PDF export orchestration
- `tools/pdf_export/PDFExport.swift` — Swift CLI for AcroForm filling and signature stamping
- `scripts/build-swift-cli.sh` — Build script for Swift CLI
- `data/plan.sample.json` — Canonical sample plan JSON
- `data/test_patients.json` — **NEW**: 10 synthetic test patients with MRN/FIN
- `data/README_TEST_PATIENTS.md` — **NEW**: Test data documentation (600+ lines)

**Governance & Legal** (**NEW** - Must Read):
- [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) — **MANDATORY**: ASAM IP compliance requirements
- [`DESIGN_CLARIFICATION.md`](DESIGN_CLARIFICATION.md) — Approved EMR integration requirements
- [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md) — What we've built and next steps
- [`RESTRUCTURE_PLAN.md`](RESTRUCTURE_PLAN.md) — 4-week migration roadmap
- [`.specify/memory/constitution.md`](.specify/memory/constitution.md) — Project governance (650+ lines)
- [`.github/GITHUB_RULES.md`](.github/GITHUB_RULES.md) — Repository standards (800+ lines)
- [`.github/VSCODE_RULES.md`](.github/VSCODE_RULES.md) — Editor configuration (700+ lines)
- `AGENT_CONSTITUTION.md`, `FILE_RULES.md`, `SECURITY.md`, `PRIVACY.md` — Original governance
- `PRODUCT_DESCRIPTION.md`, `CHANGELOG.md`, `TASKS.md`, `LICENSE` — Project docs

## VS Code Tasks

**Current** (POC commands):
- **Agent: Scaffold** — Ensures folders exist
- **Agent: Plan Hash** — Computes SHA-256 of canonical JSON
- **Agent: Validate** — Minimal POC validator (checks 3 required fields)
- **Agent: Build pdf_export** — Builds Swift CLI
- **Agent: Export PDF** — Full pipeline: fill AcroForm, stamp signature, add seal

**Coming** (Production commands - Week 3):
- **Agent: Sync EMR** — Manual sync with EMR (fetch patient updates)
- **Agent: Test Mock EMR** — Run integration tests with 10 test patients
- **Agent: Check Legal** — Run legal compliance checker (scan for ASAM IP violations)
- **Agent: Purge Cache** — Clear expired cached patient data
- **Agent: Generate Audit Report** — Export encrypted audit log

---

## 🚨 Critical Warnings

### ❌ DO NOT Do This (Without ASAM Permission)

1. **DO NOT** use "ASAM", "CONTINUUM", "CO-Triage" in UI, marketing, or customer-facing text
2. **DO NOT** copy ASAM questions, decision logic, or assessment wording
3. **DO NOT** use official ASAM PDF templates without a signed license
4. **DO NOT** claim "ASAM-compatible" or "ASAM-certified" status
5. **DO NOT** include MRN/FIN in filenames (PHI violation)
6. **DO NOT** store signature stroke data after PDF export
7. **DO NOT** commit real patient data to repository

### ✅ DO This Instead

1. **USE** neutral terminology: "Domain 1-6" (avoid trademarked language)
2. **USE** opaque IDs for filenames: UUIDs (not MRN/FIN)
3. **USE** generic assessment questions with our own wording
4. **USE** neutral PDF template: "Substance Use Disorder Treatment Plan"
5. **RUN** legal compliance checker before commits: `./scripts/check-legal-compliance.sh`
6. **READ** [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) before writing assessment code
7. **CONTACT** ASAM for permission if leadership wants official content: asamcriteria@asam.org

---

## 📊 Test Data

**10 Synthetic Patients** (`data/test_patients.json`):

| MRN | Name | Age | Substance | Level | Special Population |
|-----|------|-----|-----------|-------|--------------------|
| TEST001234 | Maria Rodriguez | 39 | Alcohol | IOP | Spanish-speaking |
| TEST002345 | James Thompson | 52 | Opioids | RES-3 | On MAT |
| TEST003456 | Ashley Williams | 17 | Cannabis | OP | Minor (parental consent) |
| TEST004567 | Robert Jackson | 56 | Cocaine | INP-MED | Homeless + Schizophrenia |
| TEST005678 | Lisa Chen | 30 | Meth | INP-MED-PW | 12 weeks pregnant |
| TEST006789 | Michael O'Brien | 69 | Alcohol | PH | Elderly, grief-related |
| TEST007890 | Tyrone Washington | 34 | Heroin | IOP | Military veteran + PTSD |
| TEST008901 | Sophia Martinez | 36 | Benzos | INP-DETOX | **CRITICAL** seizure risk |
| TEST009012 | Kevin Nguyen | 26 | Alcohol | EARLY | Young professional |
| TEST010123 | Patricia Johnson | 44 | Recovery | MAT-MAINT | 18 months clean ✅ |

**Coverage**: 10 internal level codes, co-occurring disorders, special populations, edge cases  
**Mapping**: See [`docs/mappings/levels.md`](docs/mappings/levels.md) for internal code definitions (analyst use only)  
**Documentation**: See [`data/README_TEST_PATIENTS.md`](data/README_TEST_PATIENTS.md) for full patient details

---

## 📞 Support & Resources

**Project Documentation**:
- [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md) — Current status and next steps
- [`DESIGN_CLARIFICATION.md`](DESIGN_CLARIFICATION.md) — Approved requirements
- [`RESTRUCTURE_PLAN.md`](RESTRUCTURE_PLAN.md) — Migration roadmap
- [`.specify/memory/constitution.md`](.specify/memory/constitution.md) — Governance

**ASAM Resources**:
- Copyright & Permissions: https://www.asam.org/asam-criteria/copyright-and-permissions
- Permission Request Forms: https://www.asam.org/asam-criteria/copyright-and-permissions/permission-request-forms
- CONTINUUM Integration: https://www.asam.org/asam-criteria/asam-criteria-software/asam-continuum/developers
- Email: asamcriteria@asam.org

**Technical Standards**:
- FHIR R4: https://www.hl7.org/fhir/R4/
- SMART on FHIR: https://docs.smarthealthit.org/
- Cerner Ignite: https://fhir.cerner.com/
- EPIC FHIR: https://fhir.epic.com/

---

## 🎯 Next Steps

**Week 1** (Nov 11-15):
1. Read [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) — All developers must read
2. Execute Phase 1 of [`RESTRUCTURE_PLAN.md`](RESTRUCTURE_PLAN.md)
3. Create Python package structure
4. Implement Mock EMR adapter
5. Create legal compliance checker
6. Run tests with 10 synthetic patients

**Week 2-4**: See [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md) for full timeline

---

Generated: 2025-11-08 (EMR Integration Edition)  
Previous: 2025-11-09 01:42:30 (POC)
