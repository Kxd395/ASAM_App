# EMR Integration Guide

**Version**: 1.0  
**Last Updated**: November 8, 2025  
**Status**: Production Requirements

---

## Overview

This document specifies the complete FHIR R4 integration strategy for Cerner and EPIC EMR systems, including SMART on FHIR launch, data retrieval, and result upload.

**Critical Requirements**:
- ✅ Use neutral terminology (no "ASAM" branding without license)
- ✅ Use opaque IDs in all exports (no MRN/FIN in filenames)
- ✅ Respect EMR size limits (5-10 MB attachments)
- ✅ Include source attribution for all structured data

---

## Table of Contents

1. [Configuration Constants](#configuration-constants)
2. [SMART on FHIR Launch](#smart-on-fhir-launch)
3. [Authentication & Authorization](#authentication--authorization)
4. [Data Retrieval (Read Operations)](#data-retrieval-read-operations)
5. [Result Upload (Write Operations)](#result-upload-write-operations)
6. [Error Handling](#error-handling)
7. [EMR-Specific Considerations](#emr-specific-considerations)

---

## Configuration Constants

**⚠️ TENANT-SPECIFIC VALUES - DO NOT HARD-CODE**

These values MUST be configurable per EMR tenant and stored in configuration files, NOT hard-coded in application logic.

### LOINC Codes

| Constant | Default Value | Notes |
|----------|---------------|-------|
| `LOINC_TREATMENT_PLAN` | `18776-5` | "Plan of care note" (preferred for SUD treatment plans) |
| `LOINC_DISCHARGE_PLAN` | `11506-3` | "Hospital discharge plan" (alternative if tenant requires) |
| `LOINC_ASSESSMENT` | `51847-2` | "Assessment note" (for initial evaluation) |

**Rationale**: Different EMR tenants may require specific LOINC codes for treatment plans. Using a configurable constant allows quick adaptation without code changes.

**Configuration Example**:
```python
# src/sudplan/config/tenant.py
TENANT_CONFIG = {
    "cerner_prod": {
        "loinc_treatment_plan": "18776-5",  # Tenant-approved code
        "mrn_system": "urn:oid:1.2.840.114350.1.13.0.1.7.2.696580",
        "fin_system": "urn:oid:1.2.840.114350.1.13.0.1.7.2.696580",
        "max_attachment_size_mb": 5
    },
    "epic_prod": {
        "loinc_treatment_plan": "18776-5",
        "mrn_system": "urn:oid:1.2.840.114350.1.13.0.1.7.5.737384",
        "fin_system": "urn:oid:1.2.840.114350.1.13.0.1.7.5.737384",
        "max_attachment_size_mb": 10
    }
}
```

### SNOMED Codes

| Constant | Value | Use |
|----------|-------|-----|
| `SNOMED_TREATMENT_RECOMMENDATION` | `713512009` | "Treatment plan recommendation" (for Observations) |
| `SNOMED_SUD_ASSESSMENT` | `225338004` | "Substance use assessment" |

### Identifier Systems

**⚠️ CRITICAL**: MRN and FIN identifier systems vary by tenant. NEVER hard-code OIDs.

```python
# Example retrieval
tenant = get_current_tenant()
mrn_system = TENANT_CONFIG[tenant]["mrn_system"]

# Use in FHIR query
patient_query = f"{iss}/Patient?identifier={mrn_system}|{mrn}"
```

---

## SMART on FHIR Launch

### Registration Model

**Static Registration** (Recommended for hospital deployment):

Each EMR tenant requires pre-registration with hospital IT during deployment.

**Configuration Structure**:
```json
{
  "cerner_prod": {
    "client_id": "xxxxx-xxxxx-xxxxx",
    "iss": "https://fhir-myrecord.cerner.com/r4/xxxxx",
    "redirect_uri": "treatmentplan://oauth/callback",
    "scopes": [
      "patient/Patient.read",
      "patient/Encounter.read",
      "patient/Condition.read",
      "patient/AllergyIntolerance.read",
      "patient/MedicationRequest.read",
      "patient/Observation.read",
      "patient/DocumentReference.write",
      "patient/Observation.write"
    ]
  },
  "epic_prod": {
    "client_id": "yyyyy-yyyyy-yyyyy",
    "iss": "https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4",
    "redirect_uri": "treatmentplan://oauth/callback",
    "scopes": [
      "patient/*.read",
      "patient/DocumentReference.write",
      "patient/Observation.write"
    ]
  }
}
```

### Authorization Flow (PKCE Required)

**Step 1: EHR Launch** (Preferred method)
```
EMR launches app with context:
treatmentplan://launch?iss={issuer}&launch={launch_token}
```

**Step 2: Authorization Request**
```http
GET {iss}/oauth2/authorize
  ?response_type=code
  &client_id={client_id}
  &redirect_uri={redirect_uri}
  &scope={space_separated_scopes}
  &state={random_state_256bit}
  &aud={iss}
  &launch={launch_token}
  &code_challenge={base64url(sha256(verifier))}
  &code_challenge_method=S256
```

**Step 3: Token Exchange**
```http
POST {iss}/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code={auth_code}&
redirect_uri={redirect_uri}&
client_id={client_id}&
code_verifier={pkce_verifier}
```

**Response**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "patient": "12345",
  "encounter": "67890"
}
```

---

## Authentication & Authorization

### Token Storage (iOS Keychain)

| Token Type | Storage Location | Accessibility | TTL |
|-----------|------------------|---------------|-----|
| Access Token | **Memory only** (never persisted) | N/A | 1 hour |
| Refresh Token | iOS Keychain | `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | 60-90 days |
| PKCE Verifier | Memory during flow only | N/A | Single use |

### Token Refresh (Background Sync)

```python
async def background_sync():
    """Refresh tokens and sync data"""
    # Only attempt if device unlocked
    if not await device_is_unlocked():
        logger.info("Device locked - skipping background sync")
        return
    
    # Retrieve refresh token from Keychain
    refresh_token = await keychain.get("oauth_refresh_token")
    if not refresh_token:
        logger.warning("No refresh token - user must re-launch from EMR")
        return
    
    try:
        # Refresh access token
        new_tokens = await oauth_client.refresh(refresh_token)
        
        # Update Keychain (refresh tokens rotate on each use)
        await keychain.set("oauth_refresh_token", new_tokens['refresh_token'])
        
        # Perform sync operations
        await sync_patient_data(new_tokens['access_token'])
        
    except TokenExpiredError:
        logger.error("Refresh token expired - user must re-authenticate")
        await notify_user_reauth_required()
```

### Token Expiry Handling

- **Access tokens**: 1 hour (refresh in background every 45 minutes)
- **Refresh tokens**: 90 days (Cerner), 60 days (EPIC)
- **On expiry**: Prompt user to re-launch from EMR (cannot refresh without user interaction)
- **Never store**: Passwords, client secrets, or long-lived credentials

---

## Data Retrieval (Read Operations)

### Patient Demographics

**FHIR Resource**: `Patient`

```http
GET {iss}/Patient?identifier={system}|{mrn}
Authorization: Bearer {access_token}
Accept: application/fhir+json
```

**Example Response**:
```json
{
  "resourceType": "Patient",
  "id": "12345",
  "identifier": [
    {"system": "urn:oid:1.2.840.114350", "value": "MRN001234"}
  ],
  "name": [
    {
      "use": "official",
      "family": "Rodriguez",
      "given": ["Maria", "Elena"]
    }
  ],
  "birthDate": "1985-05-15",
  "gender": "female",
  "address": [
    {
      "use": "home",
      "line": ["123 Main St"],
      "city": "Philadelphia",
      "state": "PA",
      "postalCode": "19019"
    }
  ],
  "telecom": [
    {"system": "phone", "value": "215-555-0100"}
  ],
  "communication": [
    {"language": {"coding": [{"code": "es"}]}}
  ]
}
```

### Encounters (FIN)

**FHIR Resource**: `Encounter`

```http
GET {iss}/Encounter?identifier={system}|{fin}
Authorization: Bearer {access_token}
Accept: application/fhir+json
```

### Diagnoses (ICD-10)

**FHIR Resource**: `Condition`

```http
GET {iss}/Condition?patient={patient_id}&clinical-status=active
Authorization: Bearer {access_token}
Accept: application/fhir+json
```

### Medications

**FHIR Resource**: `MedicationRequest`

```http
GET {iss}/MedicationRequest?patient={patient_id}&status=active
Authorization: Bearer {access_token}
Accept: application/fhir+json
```

### Vitals (Recent)

**FHIR Resource**: `Observation`

```http
GET {iss}/Observation?patient={patient_id}&category=vital-signs&date=ge{1_hour_ago}
Authorization: Bearer {access_token}
Accept: application/fhir+json
```

---

## Result Upload (Write Operations)

### DocumentReference (PDF Export)

**Purpose**: Upload completed treatment plan PDF to EMR

**Two Patterns Available**:

#### Pattern A: Inline Base64 (Small PDFs <2 MB)

**Use When**: PDF is small and EMR accepts inline attachments

**Template**:
```json
{
  "resourceType": "DocumentReference",
  "status": "current",
  "type": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "{{LOINC_TREATMENT_PLAN}}",
        "display": "Plan of care note"
      }
    ],
    "text": "Treatment Plan Assessment"
  },
  "subject": {
    "reference": "Patient/{patientId}",
    "display": "{patient_full_name}"
  },
  "context": {
    "encounter": [
      {
        "reference": "Encounter/{encounterId}"
      }
    ]
  },
  "date": "{iso8601Timestamp}",
  "author": [
    {
      "reference": "Practitioner/{practitionerId}",
      "display": "{signer_name}"
    }
  ],
  "description": "Treatment Plan - Six-Domain Assessment",
  "content": [
    {
      "attachment": {
        "contentType": "application/pdf",
        "title": "TreatmentPlan_{opaqueUUID}.pdf",
        "creation": "{iso8601Timestamp}",
        "hash": "{base64SHA256}",
        "size": {sizeInBytes},
        "data": "{base64EncodedPDF}"
      }
    }
  ]
}
```

#### Pattern B: Binary Reference (Large PDFs or Preferred by EMR)

**Use When**: 
- PDF is >2 MB
- EMR prefers Binary resources
- Better performance needed

**Step 1: Upload PDF as Binary**
```http
POST {iss}/Binary
Authorization: Bearer {access_token}
Content-Type: application/pdf

<raw PDF bytes>

# Response
201 Created
Location: {iss}/Binary/{binaryId}
{
  "resourceType": "Binary",
  "id": "{binaryId}",
  "contentType": "application/pdf"
}
```

**Step 2: Create DocumentReference with Binary Link**
```json
{
  "resourceType": "DocumentReference",
  "status": "current",
  "type": {
    "coding": [
      {
        "system": "http://loinc.org",
        "code": "{{LOINC_TREATMENT_PLAN}}",
        "display": "Plan of care note"
      }
    ],
    "text": "Treatment Plan Assessment"
  },
  "subject": {
    "reference": "Patient/{patientId}",
    "display": "{patient_full_name}"
  },
  "context": {
    "encounter": [
      {
        "reference": "Encounter/{encounterId}"
      }
    ]
  },
  "date": "{iso8601Timestamp}",
  "author": [
    {
      "reference": "Practitioner/{practitionerId}",
      "display": "{signer_name}"
    }
  ],
  "description": "Treatment Plan - Six-Domain Assessment",
  "content": [
    {
      "attachment": {
        "contentType": "application/pdf",
        "title": "TreatmentPlan_{opaqueUUID}.pdf",
        "creation": "{iso8601Timestamp}",
        "hash": "{base64SHA256}",
        "size": {sizeInBytes},
        "data": "{base64EncodedPDF}"
      }
    }
  ]
}
```

**HTTP Request**:
```http
POST {iss}/DocumentReference
Authorization: Bearer {access_token}
Content-Type: application/fhir+json
Accept: application/fhir+json

{...DocumentReference JSON...}
```

**Size Constraints**:
- **Cerner**: 5 MB maximum
- **EPIC**: 10 MB maximum
- **Action if exceeded**: Compress PDF or reduce image quality

### Observation (Discrete Values)

**Purpose**: Write back structured recommendation for EMR analytics

**Two Value Options**:

#### Option A: String Value (Simple)
```json
{
  "resourceType": "Observation",
  "status": "final",
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "social-history",
          "display": "Social History"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "713512009",
        "display": "Treatment plan recommendation"
      }
    ],
    "text": "Treatment recommendation"
  },
  "subject": {
    "reference": "Patient/{patientId}"
  },
  "encounter": {
    "reference": "Encounter/{encounterId}"
  },
  "effectiveDateTime": "{iso8601Timestamp}",
  "issued": "{iso8601Timestamp}",
  "performer": [
    {
      "reference": "Practitioner/{practitionerId}",
      "display": "{signer_name}"
    }
  ],
  "valueString": "IOP",
  "note": [
    {
      "text": "Recommended Level: Intensive Outpatient (IOP). Based on neutral six-domain assessment. See attached PDF for details."
    }
  ]
}
```

#### Option B: CodeableConcept Value (Queryable)
```json
{
  "resourceType": "Observation",
  "status": "final",
  "category": [
    {
      "coding": [
        {
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "social-history",
          "display": "Social History"
        }
      ]
    }
  ],
  "code": {
    "coding": [
      {
        "system": "http://snomed.info/sct",
        "code": "713512009",
        "display": "Treatment plan recommendation"
      }
    ],
    "text": "Treatment recommendation"
  },
  "subject": {
    "reference": "Patient/{patientId}"
  },
  "encounter": {
    "reference": "Encounter/{encounterId}"
  },
  "effectiveDateTime": "{iso8601Timestamp}",
  "issued": "{iso8601Timestamp}",
  "performer": [
    {
      "reference": "Practitioner/{practitionerId}",
      "display": "{signer_name}"
    }
  ],
  "valueCodeableConcept": {
    "coding": [
      {
        "system": "http://hospital.local/CodeSystem/treatment-levels",
        "code": "IOP",
        "display": "Intensive Outpatient Program"
      }
    ],
    "text": "IOP"
  },
  "note": [
    {
      "text": "Based on six-domain clinical assessment. Internal code: IOP. See local mapping for details."
    }
  ]
}
```

**HTTP Request**:
```http
POST {iss}/Observation
Authorization: Bearer {access_token}
Content-Type: application/fhir+json
Accept: application/fhir+json

{...Observation JSON...}
```

**⚠️ IMPORTANT**: Use internal codes (`IOP`, `RES-3`, etc.) NOT ASAM level numbers (`2.1`, `3.1`) unless licensed.

---

## Error Handling

### HTTP Status Codes

| Status | Meaning | Action |
|--------|---------|--------|
| 200/201 | Success | Continue |
| 400 | Bad Request | Log validation error, alert user |
| 401 | Unauthorized | Refresh token or re-authenticate |
| 403 | Forbidden | Check scopes, may need permission escalation |
| 404 | Not Found | Resource doesn't exist (expected for some queries) |
| 413 | Payload Too Large | Compress PDF, reduce size |
| 429 | Rate Limit | Exponential backoff, retry after delay |
| 500/502/503 | Server Error | Retry with exponential backoff (max 3 attempts) |

### Retry Strategy

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    reraise=True
)
async def upload_to_emr(pdf_bytes: bytes, metadata: dict) -> bool:
    """Upload with automatic retry on transient failures"""
    
    # Size validation
    size_mb = len(pdf_bytes) / (1024 * 1024)
    if size_mb > 5:  # Conservative limit
        raise ValueError(f"PDF too large: {size_mb:.1f}MB (max 5MB)")
    
    # Create DocumentReference
    doc_ref = create_document_reference(pdf_bytes, metadata)
    
    try:
        response = await fhir_client.create(doc_ref)
        
        if response.status_code in [200, 201]:
            await audit_log.log("emr_upload_success", resource_id=response.id)
            return True
        elif response.status_code == 413:
            raise ValueError("PDF too large for EMR")
        elif response.status_code in [500, 502, 503]:
            raise TransientError("EMR temporarily unavailable")
        else:
            raise PermanentError(f"EMR rejected upload: {response.status_code}")
            
    except httpx.TimeoutException:
        raise TransientError("EMR timeout - will retry")
    except Exception as e:
        await audit_log.log_error("emr_upload_failed", str(e))
        raise
```

---

## EMR-Specific Considerations

### Cerner Ignite FHIR R4

**Base URL**: `https://fhir-myrecord.cerner.com/r4/{tenant_id}`

**Key Features**:
- Full FHIR R4 support
- Requires `tenant_id` in URL path
- Refresh tokens expire after 90 days
- DocumentReference size limit: **5 MB**
- Supports dynamic registration (but static preferred)

**Known Limitations**:
- Some Observation categories require specific LOINC codes
- MedicationRequest may not include discontinued meds in `status=active` filter

### EPIC FHIR R4

**Base URL**: `https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4`

**Key Features**:
- SMART on FHIR launch strongly preferred
- Patient and Encounter context passed in launch token
- Refresh tokens expire after 60 days
- DocumentReference size limit: **10 MB**
- Excellent documentation at https://fhir.epic.com/

**Known Limitations**:
- Requires pre-registration with EPIC App Orchard (production only)
- Some scopes require additional approval (e.g., `patient/*.write`)
- Background sync may require special "Backend Services" scope

### Fallback Strategy

If FHIR endpoint unavailable:

1. **Cerner**: Fall back to Cerner REST API (non-FHIR) for critical reads
2. **EPIC**: Fall back to web services for specific gaps
3. **Both**: Queue uploads locally and retry when connectivity restored

---

## Testing

### Mock EMR Adapter

Use `src/sudplan/emr/mock.py` with `tests/fixtures/test_patients.json` for development:

```python
from sudplan.emr.mock import MockEMRAdapter

adapter = MockEMRAdapter("tests/fixtures/test_patients.json")
patient = await adapter.get_patient_by_mrn("TEST001234")
assert patient.demographics.first_name == "Maria"
```

### Integration Testing

**Week 2**: Connect to Cerner/EPIC sandbox environments
**Week 3**: Full end-to-end workflow with test patient in sandbox
**Week 4**: Pre-production validation with hospital IT

---

## Security Checklist

- [ ] All tokens stored in iOS Keychain (not UserDefaults or files)
- [ ] Access tokens never persisted (memory only)
- [ ] TLS 1.2+ enforced for all EMR connections
- [ ] Certificate pinning enabled (if hospital provides certificates)
- [ ] All EMR operations logged to audit trail
- [ ] No PHI in log files or crash reports
- [ ] PKCE used for all OAuth flows (no client secret on device)
- [ ] Refresh tokens rotated on each use

---

## References

- SMART on FHIR: https://docs.smarthealthit.org/
- HL7 FHIR R4: https://www.hl7.org/fhir/R4/
- Cerner Ignite: https://fhir.cerner.com/
- EPIC FHIR: https://fhir.epic.com/
- OAuth 2.0 PKCE: https://tools.ietf.org/html/rfc7636

---

**Last Updated**: November 8, 2025  
**Next Review**: After Phase 2 implementation (Week 2)
