# MASTER_TODO
This document is generated from `docs/TODO_INDEX.json`. Do not edit by hand.

Updated: 2025-11-10T20:00:00.000000
Open: 28  |  Done: 13 (T-0024 merged into T-0029)

## ⚠️ CRITICAL FIXES IN PROGRESS

**FIX PR**: Critical P0 Hardening - Safety Gates and Provenance
- FIX #1: Canonical ruleset hash with exact deterministic PDF footer format
- FIX #2: Hard preflight gate requiring healthy rules state and valid provenance
- FIX #3: Reconciliation checks between COWS/CIWA and D1 severity
- FIX #4: Vitals stability check blocking ambulatory WM recommendations
- FIX #5: Adaptive debouncing (0ms for safety flags, 300ms for text inputs)
- FIX #6: Job-level export gating (not button-level)
- FIX #9: Compliance template validation in ExportPreflight
- FIX #12: CI script for target membership validation

**Status**: Code complete, ready for Xcode integration

---

## 🔴 CRITICAL: ASAM IP Compliance

**Task T-0050**: ASAM IP Compliance Enforcement - **P0 BLOCKER**  
See: `agent_ops/docs/ASAM_IP_COMPLIANCE_ENFORCEMENT.md`

**Sub-tasks:**
- T-0051: CI token guard implementation (P0)
- T-0052: Compliance Gate in build process (P0)
- T-0053: Legal screen and PDF footer fields (P0)
- T-0054: Rules hash audit event (P0)
- T-0055: Licensed mode toggle and checks (P0)

⚠️ **Must complete before any TestFlight or production deployment**

| ID | Status | Priority | Title | Owner | Due |
|----|--------|----------|-------|-------|-----|
| T-0001 | done | P1 | Implement NavigationSplitView shell and screens | agent |  |
| T-0002 | done | P1 | Build safety banner and export block logic | agent |  |
| T-0003 | open | P1 | Implement Problems module (single CRUD owner) | agent |  |
| T-0004 | open | P2 | EMR Context drawer (read only + TTL) | agent |  |
| T-0005 | open | P1 | PDFComposer and dynamic renderers (D1/D2/Problems) | agent |  |
| T-0006 | open | P1 | Preflight checks + neutral filename policy | agent |  |
| T-0007 | open | P2 | Upload with retry and Binary->DocumentReference fallback | agent |  |
| T-0008 | open | P1 | Unit tests: gates, hash stability, renderer overflow, preflight | agent |  |
| T-0009 | open | P2 | Accessibility pass and idle lock wiring | agent |  |
| T-0010 | open | P1 | Implement canonical JSON encoder for seal and composer | agent |  |
| T-0011 | open | P1 | Implement OverflowPredictor and wire to preflight | agent |  |
| T-0012 | open | P1 | Build SafetyAction modal and persistence | agent |  |
| T-0013 | open | P1 | Add crumb anchors to all rules and form fields | agent |  |
| T-0014 | open | P2 | Build DocumentReference flow with Binary fallback and Provenance | agent |  |
| T-0015 | open | P1 | Add MAC chain to audit_events and a verifier command | agent |  |
| T-0016 | open | P2 | Add Accessibility pass checklist and automated contrast checks | agent |  |
| T-0017 | open | P1 | Add edition scoping for anchors and levels, plus ruleset_hash computation | agent |  |
| T-0018 | done | P1 | Replace signature rule with strict check and wire exporter gate | agent |  |
| T-0019 | done | P1 | Add crumb linter that validates all rule crumbs against crumbs.yml in CI | agent |  |
| T-0020 | done | P1 | Create operators.json and wire evaluator to data-driven operators | agent |  |
| T-0021 | done | P1 | Add rules fixtures with golden outputs and include rule ids in audit logs | agent |  |
| T-0022 | done | P2 | Implement WM to LOC guard so 3.7 base does not fire if 3.7-WM already matched | agent |  |
| T-0023 | open | P2 | Add program capability resolver that down-shifts or flags no compatible program | agent |  |
| **T-0024** | **MERGED** | **P2** | **MERGED INTO T-0029 - Ruleset hash to PDF seal and audit events** | **agent** | **2025-11-10** |
| **T-0025** | **done** | **P0** | **Implement SubstanceRow sheet for Domain 1 context (CRITICAL for rules to fire)** | **agent** | **2025-11-10** |
| **T-0026** | **done** | **P0** | **Implement Flags UI for clinical indicators (CRITICAL for rules to fire)** | **agent** | **2025-11-10** |
| **T-0027** | **done** | **P1** | **Add MainActor enforcement and debouncing to RulesServiceWrapper** | **agent** | **2025-11-10** |
| **T-0028** | **done** | **P1** | **Add Export block and banner on degraded rules** | **agent** | **2025-11-10** |
| **T-0029** | **done** | **P2** | **Add rules checksum audit and PDF footer stamp (canonical hash, manifest)** | **agent** | **2025-11-10** |
| **T-0030** | **open** | **P2** | **Add precedence/ruleId uniqueness tests** | **agent** |  |
| **T-0031** | **open** | **P3** | **Add ASAM version switch (v3/v4) with 3.3 hiding** | **agent** |  |
| **T-0032** | **open** | **P3** | **Add WM display separate from LOC with candidate ladder** | **agent** |  |
| **T-0033** | **open** | **P3** | **Add JSON schema validation for rules in CI** | **agent** |  |
| **T-0034** | **open** | **P3** | **Add build phase rules validation script** | **agent** |  |
| **T-0035** | **open** | **P1** | **Add reverse WM guard requiring D1 evidence for LOC 3.7 or 4.0** | **agent** |  |
| **T-0036** | **open** | **P1** | **Add reconciliation checks between flags, COWS/CIWA, and D1 severity** | **agent** |  |

## Checklist
- [x] T-0001  Implement NavigationSplitView shell and screens (P1)
- [x] T-0002  Build safety banner and export block logic (P1)
- [ ] T-0003  Implement Problems module (single CRUD owner) (P1)
- [ ] T-0004  EMR Context drawer (read only + TTL) (P2)
- [ ] T-0005  PDFComposer and dynamic renderers (D1/D2/Problems) (P1)
- [ ] T-0006  Preflight checks + neutral filename policy (P1)
- [ ] T-0007  Upload with retry and Binary->DocumentReference fallback (P2)
- [ ] T-0008  Unit tests: gates, hash stability, renderer overflow, preflight (P1)
- [ ] T-0009  Accessibility pass and idle lock wiring (P2)
- [ ] T-0010  Implement canonical JSON encoder for seal and composer (P1)
- [ ] T-0011  Implement OverflowPredictor and wire to preflight (P1)
- [ ] T-0012  Build SafetyAction modal and persistence (P1)
- [ ] T-0013  Add crumb anchors to all rules and form fields (P1)
- [ ] T-0014  Build DocumentReference flow with Binary fallback and Provenance (P2)
- [ ] T-0015  Add MAC chain to audit_events and a verifier command (P1)
- [ ] T-0016  Add Accessibility pass checklist and automated contrast checks (P2)
- [ ] T-0017  Add edition scoping for anchors and levels, plus ruleset_hash computation (P1)
- [x] T-0018  Replace signature rule with strict check and wire exporter gate (P1)
- [x] T-0019  Add crumb linter that validates all rule crumbs against crumbs.yml in CI (P1)
- [x] T-0020  Create operators.json and wire evaluator to data-driven operators (P1)
- [x] T-0021  Add rules fixtures with golden outputs and include rule ids in audit logs (P1)
- [x] T-0022  Implement WM to LOC guard so 3.7 base does not fire if 3.7-WM already matched (P2)
- [ ] T-0023  Add program capability resolver that down-shifts or flags no compatible program (P2)
- [x] **T-0024  MERGED INTO T-0029 - Ruleset hash to PDF seal and audit events (P2) ✅ MERGED 2025-11-10**
- [x] **T-0025  Implement SubstanceRow sheet for Domain 1 context (P0) ✅ COMPLETE 2025-11-10**
- [x] **T-0026  Implement Flags UI for clinical indicators (P0) ✅ COMPLETE 2025-11-10**
- [x] **T-0027  Add MainActor enforcement and debouncing to RulesServiceWrapper (P1) ✅ COMPLETE 2025-11-10**
- [x] **T-0028  Add Export block and banner on degraded rules (P1) ✅ COMPLETE 2025-11-10**
- [x] **T-0029  Add rules checksum audit and PDF footer stamp (canonical hash, manifest) (P2) ✅ COMPLETE 2025-11-10**
- [ ] **T-0030  Add precedence/ruleId uniqueness tests (P2)**
- [ ] **T-0031  Add ASAM version switch (v3/v4) with 3.3 hiding (P3)**
- [ ] **T-0032  Add WM display separate from LOC with candidate ladder (P3)**
- [ ] **T-0033  Add JSON schema validation for rules in CI (P3)**
- [ ] **T-0034  Add build phase rules validation script (P3)**
- [ ] **T-0035  Add reverse WM guard requiring D1 evidence for LOC 3.7 or 4.0 (P1)**
- [ ] **T-0036  Add reconciliation checks between flags, COWS/CIWA, and D1 severity (P1)**
