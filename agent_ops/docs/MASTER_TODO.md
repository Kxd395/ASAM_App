# MASTER_TODO
This document is generated from `docs/TODO_INDEX.json`. Do not edit by hand.

Updated: 2025-11-11T03:45:00.000000
Open: 36  |  Done: 16 (T-0024 merged into T-0029)

## ⚠️ CRITICAL: Compile Breakers Fixed

**COMMIT 2519513 + FOLLOW-UP**: Critical compilation + logic fixes
- ✅ FIX #1: PDFKit import + NSFont→PlatformFont + arity mismatch (3 params)
- ✅ FIX #3: Added RulesState enum to RulesServiceWrapper (.healthy vs .degraded)
- ✅ FIX #2: Updated ExportPreflight.check() signature + wired provenance/complianceMode
- ✅ FIX #5: Created ComplianceConfig with typed ComplianceMode enum
- ✅ FIX #7: Fixed WM vs LOC code space mixup (check WM candidates, not LOC string)
- ✅ FIX #9: Externalized clinical thresholds to clinical_thresholds.json

**Remaining Critical Fixes** (P1):
- T-0037: Wire clinical thresholds JSON loader to ReconciliationChecks
- T-0038: PDF flatten service + embed provenance in PDF Info dict
- T-0039: Deterministic target membership CI check (replace grep)
- ✅ T-0040: Canonical hash with 5 files + manifest (64-char SHA256) **COMPLETE 2025-11-10**

**Screenshot Review Fixes** (COMPLETE 2025-11-10):
- ✅ Enhanced diagnostic logging for rules initialization (per-file verification)
- ✅ Implemented full ExportView UI (was placeholder text only)
- ✅ Verified SafetyAction picker implementation (correct)
- ⏳ Manual: Blue folder conversion (USER - P0 BLOCKER)
- ⏳ Manual: Delete duplicate files (USER - P0)
- ⏳ Manual: Add build phase guard (USER - P1)
- See: `docs/reviews/SCREENSHOT_ISSUES_FIXED.md` for complete analysis

**Hyper-Critical Review Fixes** (COMPLETE 2025-11-10):
- ✅ LocalizedError for RulesServiceError (file-specific diagnostics)
- ✅ Canonical 64-char hash with manifest (line-ending normalization)
- ✅ Domains navigation fixed (NavigationStack + tappable rows)
- ✅ DomainDetailPlaceholderView created (pending questionnaire)
- ⏳ Manual: Blue folder conversion (USER - P0 BLOCKER) ← ROOT CAUSE
- See: `docs/reviews/HYPER_CRITICAL_FIXES_APPLIED.md` for technical details

**Diagnostic Probe + Enhancements** (COMPLETE 2025-11-10):
- ✅ Added debugRulesBundle() probe showing file sizes or MISSING
- ✅ Re-applied canonical hash after git checkout (sha256Full + manifest)
- ✅ Added loadedAt property for diagnostics view
- ✅ Added reinitialize() method for retry button
- ✅ Verified ExportButton provenance issue (nil passed - P1 fix needed)
- ✅ Confirmed .contentShape(Rectangle()) present on domain rows
- ⏳ Manual: Launch app + check console for diagnostic output (USER - P0)
- See: `docs/reviews/DIAGNOSTIC_PROBE_ADDED.md` for diagnostic details

**Resilient Bundle Resolver** (COMPLETE 2025-11-10):
- ✅ Implemented resolveJSON() with 3 fallback strategies
- ✅ Updated RulesPreflight.check() to use resolver
- ✅ Updated initialize() to use resolver  
- ✅ Updated RulesChecksum.compute() to use resolver
- ✅ Created build-phase guard script (verify-rules-build-phase.sh)
- ✅ App now works even if bundle structure wrong (defensive coding)
- ⏳ Manual: 60-second blue folder conversion (USER - P0 CRITICAL)
- ⏳ Manual: Add build-phase guard to prevent regression (USER - P1)
- See: `docs/reviews/RESILIENT_RESOLVER_COMPLETE.md` for 60-second fix

---

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
| **T-0037** | **open** | **P1** | **Externalize clinical thresholds to rules/clinical_thresholds.json** | **agent** |  |
| **T-0038** | **open** | **P1** | **PDF flatten service + embed provenance in PDF Info dict** | **agent** |  |
| **T-0039** | **open** | **P1** | **Replace grep with deterministic target-membership check in CI** | **agent** |  |
| **T-0040** | **done** | **P1** | **Implement canonical hash with 5 files + manifest (64-char SHA256)** | **agent** | **2025-11-10** |
| **T-0041** | **done** | **P0** | **Create Domain A–F questionnaire JSON (neutral) - ASAM assessment forms** | **agent** | **2025-11-11** |
| **T-0042** | **done** | **P0** | **Build QuestionnaireRenderer and plug into domain detail** | **agent** | **2025-11-11** |
| **T-0043** | **done** | **P0** | **Wire SeverityScoring to domain severities (A..F)** | **agent** | **2025-11-11** |
| **T-0044** | **open** | **P1** | **Required-question validation + progress tracking** | **agent** |  |
| **T-0045** | **open** | **P1** | **Persist answers to AssessmentStore with per-domain ownership** | **agent** |  |
| **T-0046** | **open** | **P1** | **Add schema validation in CI for questionnaires** | **agent** |  |
| **T-0047** | **open** | **P2** | **Localize questionnaires (e.g., es-US) + unit preferences** | **agent** |  |

**QUESTIONNAIRE INTEGRATION STATUS**: Files ready at `/ios/ASAMAssessment/ASAMAssessment/` - needs 2-minute Xcode target membership integration. See `docs/questionnaires/XCODE_INTEGRATION_GUIDE.md` for step-by-step instructions.

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
- [ ] **T-0037  Externalize clinical thresholds to rules/clinical_thresholds.json (P1)**
- [ ] **T-0038  PDF flatten service + embed provenance in PDF Info dict (P1)**
- [ ] **T-0039  Replace grep with deterministic target-membership check in CI (P1)**
- [x] **T-0040  Implement canonical hash with 5 files + manifest (64-char SHA256) (P1) ✅ COMPLETE 2025-11-10**
- [x] **T-0041  Create Domain A–F questionnaire JSON (neutral) - ASAM assessment forms (P0) ✅ COMPLETE 2025-11-11**
- [x] **T-0042  Build QuestionnaireRenderer and plug into domain detail (P0) ✅ COMPLETE 2025-11-11**
- [x] **T-0043  Wire SeverityScoring to domain severities (A..F) (P0) ✅ COMPLETE 2025-11-11**

## 🚨 CRITICAL: Official ASAM Criteria Implementation (P0)

**REF:** `agent_ops/docs/review/asam-paper-criteria---edtitable-final-form (1).pdf`
**REF:** `agent_ops/docs/review/asam_loc-assessment-guide_fillable-v1.0-2.25.25 (1).pdf`

**IMPORTANT**: Current questionnaires are **placeholder/demo only**. Real implementation must use official ASAM criteria documents above.

### ASAM v3 (2013) Assessment Form - 6 Dimensions, 0-4 severity scale
### ASAM v4 (2024) Level-of-Care Guide - Subdimensions, skip logic, letter-coded risk ratings

**Implementation Priority:**
- [ ] **T-0056  Design ASAM v3/v4 data models with skip logic and conditional branching (P0)**
- [ ] **T-0057  Implement ASAM v3 D1: Acute Intoxication/Withdrawal (substance inventory, CIWA/COWS) (P0)**  
- [ ] **T-0058  Implement ASAM v3 D2: Biomedical Conditions (medical history, pregnancy, medications) (P0)**
- [ ] **T-0059  Implement ASAM v3 D3: Emotional/Behavioral/Cognitive (mental health, self-harm, psychosis) (P0)**
- [ ] **T-0060  Implement ASAM v3 D4: Readiness to Change (impact assessment, stage of change) (P0)**
- [ ] **T-0061  Implement ASAM v3 D5: Relapse/Continued Use Potential (triggers, abstinence history) (P0)**  
- [ ] **T-0062  Implement ASAM v3 D6: Recovery Environment (housing, employment, legal, safety) (P0)**
- [ ] **T-0063  Add ASAM v4 Level-of-Care determination logic (Q11-Q47, risk ratings A-E) (P0)**
- [ ] **T-0064  Wire ASAM scoring algorithms (v3: 0-4 severity, v4: LOC recommendations) (P0)**
- [ ] **T-0065  Add version switching (v3 Assessment vs v4 Level-of-Care) with user selection (P0)**

## 📝 Questionnaire System Enhancement (P1-P2)

- [ ] **T-0044  Required-question validation + progress tracking (P1)**
- [ ] **T-0045  Persist answers to AssessmentStore with per-domain ownership (P1)**
- [ ] **T-0046  Add schema validation in CI for questionnaires (P1)**
- [ ] **T-0047  Localize questionnaires (e.g., es-US) + unit preferences (P2)**

## 🏥 Patient Identification & EMR Integration (P1-P2)

**REF:** `agent_ops/docs/review/Patient.md` - Comprehensive patient ID system spec
**REF:** `agent_ops/docs/review/patients/` - Clinical test cases and fixtures

- [ ] **T-0048  Implement SMART on FHIR patient lookup with two-identifier safety gates (P1)**
- [ ] **T-0049  Build Patient ID UI (MRN/FIN/Name+DOB/Barcode scan) with tenant config (P1)**  
- [ ] **T-0050  Add FHIR vitals ingestion (temp, BP, HR, RR, SpO2) with safety thresholds (P1)**
- [ ] **T-0051  Implement UDS (drug screen) integration with LOINC mapping (P1)**
- [ ] **T-0052  Build substance intake profiles per-substance (opioids, alcohol, etc) (P2)**
- [ ] **T-0053  Wire EMR context to assessment rules (vitalsUnstable, suspectedFentanyl) (P2)**
- [ ] **T-0054  Add patient switching safety gates (discard draft protection) (P2)**
- [ ] **T-0055  Implement encounter status validation (active/finished) for export gates (P2)**
