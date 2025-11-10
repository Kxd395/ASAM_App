# Legal Notice and Attribution

**Version**: 1.0  
**Date**: November 8, 2025  
**Status**: MANDATORY - READ BEFORE DEVELOPMENT

---

## ⚖️ ASAM Intellectual Property Notice

**NOTICE**

This application is not affiliated with or endorsed by the American Society of Addiction Medicine. The terms ASAM, The ASAM Criteria, ASAM CONTINUUM, and CO-Triage are trademarks or registered trademarks of ASAM.

Integrating ASAM content into technology, reusing ASAM wording, decision logic, forms, or branding requires a permission agreement from ASAM. See [ASAM Copyright and Permissions](https://www.asam.org/asam-criteria/copyright-and-permissions) and [Permission Request Forms](https://www.asam.org/asam-criteria/copyright-and-permissions/permission-request-forms). Contact [asamcriteria@asam.org](mailto:asamcriteria@asam.org).

**Until a signed agreement is in place, this app must not copy or adapt ASAM text, questions, decision tables, PDFs, or marks. Build a neutral six-domain assessment with our own wording. If and when a license is executed, store any ASAM outputs with explicit source attribution fields and add the vendor required notices.**

---

## 📋 Required Attribution (If Licensed)

**If you later license ASAM content, include both lines, adapted to your terms:**

1. "Portions of this software incorporate content licensed from The American Society of Addiction Medicine. Used by permission."
2. "ASAM, The ASAM Criteria, CONTINUUM, and CO-Triage are trademarks or registered trademarks of The American Society of Addiction Medicine. Used under license."

**If you rely on minimal fair use citation only, include this citation anywhere content is quoted:**

* "Mee-Lee D, Shulman GD, Fishman MJ, Gastfriend DR, Miller MM. The ASAM Criteria."

ASAM states that even fair use requires proper citation and that training and integrated technology do not qualify for fair use exceptions and need permission. ([Fair Use Policy](https://www.asam.org/publications-resources/licensing/fair-use))

---

## 🚫 What NOT to Do

### Prohibited Actions (Without License)

1. ❌ **Do NOT rename this tool** to include "ASAM", "CONTINUUM", or "CO-Triage"
2. ❌ **Do NOT import or re-typeset** ASAM PDFs without a license
3. ❌ **Do NOT market** as "ASAM compatible" without written permission
4. ❌ **Do NOT copy ASAM text**, questions, or decision logic verbatim
5. ❌ **Do NOT display ASAM logos** or branding without authorization
6. ❌ **Do NOT use ASAM field names** or schema without permission
7. ❌ **Do NOT claim ASAM certification** without going through their process

### Required Practices

1. ✅ **USE neutral terminology** for assessment domains (e.g., "Domain 1: Withdrawal Risk" not "ASAM Dimension 1")
2. ✅ **CREATE original wording** for assessment questions
3. ✅ **STORE vendor outputs** with explicit `source` attribution fields (e.g., `source: "ASAM CONTINUUM"`)
4. ✅ **MAINTAIN clear provenance** for any licensed content
5. ✅ **CITE properly** if using minimal fair use quotation
6. ✅ **CONTACT ASAM** before marketing or public release if using their logic

---

## 🔐 Vendor Integration Path

### ASAM CONTINUUM Integration API

ASAM provides a REST Integration API for CONTINUUM. Key facts:

- **Certification Required**: Integrations must be certified by ASAM
- **Typical Effort**: ~200 developer hours (per ASAM documentation)
- **Process**: Request permission → Sign agreement → Integration API access → Certification demo
- **Authorized Distributor Program**: Available for EHR vendors

**Resources**:
- [ASAM CONTINUUM Developers](https://www.asam.org/asam-criteria/asam-criteria-software/asam-continuum/developers)
- [Technology Vendor Permissions](https://www.asam.org/asam-criteria/copyright-and-permissions/permission-request-forms)

### Permission Request Requirements

When requesting ASAM permission, provide:

1. **Use Case**: Clinical workflow description
2. **Populations**: Patient demographics and volumes
3. **Number of Clinicians**: Expected user count
4. **Integration Model**: API, embedded, standalone
5. **Data Flow**: How ASAM content will be used
6. **Storage**: Where and how long ASAM data persists
7. **Distribution**: Internal vs. commercial

**Contact**: [asamcriteria@asam.org](mailto:asamcriteria@asam.org)

---

## 🏥 Current Implementation Strategy

### Phase 1: Neutral Assessment (Current - No License Required)

**Allowed**:
- Build a six-domain substance use disorder assessment
- Use our own original questions and wording
- Create neutral level-of-care recommendations (e.g., "Level 1: Outpatient", "Level 3.7: Inpatient")
- Store assessment results in our own schema
- Generate PDFs with neutral forms (not official ASAM templates)

**Field Naming Convention**:
```json
{
  "assessment_id": "uuid",
  "domain_1_withdrawal_risk": "moderate",
  "domain_2_medical_conditions": "stable",
  "domain_3_mental_health": "co-occurring_mild",
  "domain_4_readiness": "contemplation",
  "domain_5_relapse_risk": "high",
  "domain_6_environment": "supportive",
  "recommended_level": "2.1",
  "recommended_level_name": "Intensive Outpatient",
  "source": "internal_assessment",
  "assessed_by": "clinician_id",
  "assessed_date": "2025-11-08T14:30:00Z"
}
```

**PDF Template**:
- Use a neutral template labeled "Substance Use Disorder Treatment Plan"
- Do NOT use "ASAM Treatment Plan" header
- Do NOT include ASAM logos or marks
- Include hospital/organization branding only

### Phase 2: Licensed ASAM Content (Future - Requires Agreement)

**If License Obtained**:
- Can use official ASAM terminology and field names
- Can integrate ASAM CONTINUUM API
- Can display ASAM levels with official names
- Can use official ASAM PDF templates
- Must include required attribution notices
- Must store data with source provenance

**Storage Example with Provenance**:
```json
{
  "assessment_id": "uuid",
  "internal_assessment": { /* our neutral data */ },
  "asam_continuum_result": {
    "source": "ASAM CONTINUUM API v2.0",
    "license_agreement": "ASAM-2025-0001",
    "asam_level": "2.1-IOP",
    "asam_dimension_scores": [3, 1, 2, 2, 3, 2],
    "asam_rationale": "...",
    "retrieved_at": "2025-11-08T14:35:00Z"
  }
}
```

---

## 🔍 Code Review Checklist

Before committing code, verify:

- [ ] No hardcoded ASAM text, questions, or decision logic
- [ ] No ASAM trademarks in UI, variables, or function names
- [ ] No ASAM PDF templates embedded in repository
- [ ] All assessment fields use neutral naming
- [ ] Source attribution included for any external content
- [ ] Legal notice displayed in app "About" or "Legal" screen
- [ ] README and documentation avoid "ASAM-compatible" claims

---

## 📚 Reference Links

1. **ASAM Copyright and Permissions**: https://www.asam.org/asam-criteria/copyright-and-permissions
2. **Permission Request Forms**: https://www.asam.org/asam-criteria/copyright-and-permissions/permission-request-forms
3. **Copyright FAQs**: https://www.asam.org/asam-criteria/copyright-and-permissions/copyright-and-permission-faqs
4. **Fair Use Policy**: https://www.asam.org/publications-resources/licensing/fair-use
5. **CONTINUUM Developers**: https://www.asam.org/asam-criteria/asam-criteria-software/asam-continuum/developers

---

## 🎯 Developer Responsibilities

**Every developer working on this project must**:

1. ✅ **Read this notice** before writing any assessment-related code
2. ✅ **Review changes** to ensure no ASAM IP violations
3. ✅ **Question any ASAM references** in tickets, designs, or code
4. ✅ **Use neutral terminology** in all code and documentation
5. ✅ **Flag concerns** immediately to project leadership

**When in doubt**: Contact [asamcriteria@asam.org](mailto:asamcriteria@asam.org) or consult legal counsel.

---

## 📝 Amendment Log

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-08 | 1.0 | Initial legal notice created | Development Team |

---

**This notice must remain in the repository at all times and must be reviewed during onboarding of new team members.**
