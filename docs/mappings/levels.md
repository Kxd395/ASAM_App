# Internal Level Codes (Analyst Reference Only - NOT SHIPPED)

**⚠️ CONFIDENTIAL - FOR INTERNAL USE ONLY**

This mapping table is for analyst reference and clinical research. **DO NOT** surface these mappings in:
- User interface
- PDF exports
- EMR uploads
- API responses
- Log files

## Purpose

Until we obtain an ASAM license agreement (see `LEGAL_NOTICE.md`), we use neutral internal codes for level-of-care recommendations. This table documents the clinical equivalency for analyst review and future integration planning.

## Internal Code Mapping

| Internal Code | Description | ASAM Reference (If Licensed) | Notes |
|--------------|-------------|------------------------------|-------|
| `EARLY` | Early Intervention | Level 0.5 | Brief intervention, psychoeducation |
| `OP` | Outpatient Services | Level 1 | Standard outpatient counseling |
| `IOP` | Intensive Outpatient | Level 2.1 | 9+ hours/week structured programming |
| `PH` | Partial Hospitalization | Level 2.5 | Day treatment, 20+ hours/week |
| `RES-3` | Residential Treatment | Level 3.1 | 24/7 supervision, non-medical |
| `RES-3-5` | Residential High-Intensity | Level 3.5 | 24/7 with medical monitoring |
| `INP-MED` | Inpatient Medical | Level 3.7 | Medically monitored intensive inpatient |
| `INP-MED-PW` | Inpatient Pregnant Women | Level 3.7-WM | Specialized inpatient for pregnancy |
| `INP-DETOX` | Medical Detoxification | Level 3.7-WM / 4 | Acute withdrawal management |
| `MAT-MAINT` | Medication Maintenance | OMT | Stable recovery with MAT (methadone/buprenorphine) |

## Clinical Severity Mapping (Internal Use Only)

Our neutral assessment produces these internal severity scores:

| Domain | Low Risk | Moderate Risk | High Risk | Critical Risk |
|--------|----------|---------------|-----------|---------------|
| Domain 1: Withdrawal | 0-1 | 2-3 | 4-5 | 6+ (medical emergency) |
| Domain 2: Medical | 0-1 | 2-3 | 4-5 | 6+ (immediate care) |
| Domain 3: Psychological | 0-1 | 2-3 | 4-5 | 6+ (crisis) |
| Domain 4: Readiness | 0-1 | 2-3 | 4-5 | N/A |
| Domain 5: Relapse | 0-1 | 2-3 | 4-5 | 6+ (imminent) |
| Domain 6: Environment | 0-1 | 2-3 | 4-5 | 6+ (unsafe) |

## Algorithm Notes (Proprietary - Not ASAM)

**This is OUR algorithm, not ASAM's.** If we license CONTINUUM API later, we will replace this logic with ASAM's official algorithm and store results with proper provenance.

Example decision tree:
```
IF Domain1 >= 6 OR Domain2 >= 6 OR Domain3 >= 6
  THEN → INP-MED (immediate medical stabilization)

ELSE IF Domain1 >= 4 OR Domain2 >= 4
  THEN → PH or INP-DETOX (depending on medical complexity)

ELSE IF (Domain3 >= 4 AND Domain5 >= 4) OR (Domain4 <= 1 AND Domain5 >= 4)
  THEN → RES-3 (24/7 structure needed)

ELSE IF Domain5 >= 3 OR Domain6 >= 4
  THEN → IOP (intensive support, can live at home)

ELSE IF Domain3 >= 2 OR Domain5 >= 2
  THEN → OP (standard outpatient adequate)

ELSE
  THEN → EARLY (prevention/education)
```

**Special Population Modifiers**:
- Pregnancy → Always upgrade to INP-MED-PW if Domain1 >= 4
- Adolescent → Prefer OP/IOP over residential unless crisis
- Elderly → Medical monitoring if Domain1 >= 3 OR Domain2 >= 3
- Homelessness → Upgrade to RES-3 minimum if Domain6 >= 5

## Usage in Code

**Correct usage** (neutral terminology):
```python
# Assessment model
assessment.recommended_level = "IOP"  # Internal code
assessment.recommended_level_description = "Intensive Outpatient Services"

# PDF export
pdf_fill({
    "recommended_care_level": "Intensive Outpatient Services",
    "clinical_rationale": "Based on six-domain assessment..."
})

# EMR upload (FHIR Observation)
{
    "code": {"text": "Treatment recommendation"},
    "valueString": "IOP",  # Neutral code
    "note": [{"text": "Internal assessment code: IOP"}]
}
```

**INCORRECT usage** (ASAM terminology without license):
```python
# ❌ DO NOT DO THIS
assessment.asam_level = "2.1"  # Trademark violation
pdf_fill({"asam_criteria_level": "Level 2.1 - IOP"})  # IP violation
```

## ASAM License Integration (Future)

**When license is obtained**, update code to:

1. **Call CONTINUUM API**:
```python
asam_result = await continuum_client.assess(patient_data)
# Store with provenance
assessment.asam_official_level = asam_result.level  # e.g., "2.1"
assessment.asam_source = "ASAM CONTINUUM API v2.0"
assessment.asam_license = "ASAM-2025-0001"
```

2. **Update PDF template** to include official ASAM branding (with permission)

3. **Display mapping** in UI: "IOP (ASAM Level 2.1)"

4. **Attribution** in exports: "ASAM Criteria™ results used by permission"

## Contact

For licensing questions: **asamcriteria@asam.org**

For internal questions about this mapping: Contact clinical lead

---

**Last Updated**: November 8, 2025  
**Status**: Neutral internal codes only (no ASAM license)  
**Next Review**: When ASAM license obtained
