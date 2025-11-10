# Design Clarification & Requirements

**Project**: ASAMPlan POC - EMR Integration Edition  
**Date**: November 8, 2025  
**Status**: ✅ **REQUIREMENTS APPROVED**

---

## 🎯 Project Vision

Transform the PDF-only POC into a production ASAM Treatment Plan workflow that is **legal, audit-safe, and EMR integrated**.

**Non-negotiables**:

* Use EMR launch context. Identify patient by MRN and encounter by FIN.
* Offline-capable iPad client with Face ID gate and idle lock.
* PDF exports that fill official AcroForms or a neutral layout. No PHI in filenames.
* **Clear IP posture**: If we want real ASAM wording and logic, we must license it. See `LEGAL_NOTICE.md` for full details.

---

## ✅ APPROVED Requirements

### EMR Integration

**Q1: Cerner Connection Method?**
- [x] **Option C: FHIR API via Cerner Ignite** ✅ **APPROVED**
- Fallbacks: Option A REST only for non-FHIR endpoints, Option B HL7 v2 for legacy feeds
- ❌ Avoid Option D (direct database access)

**Q2: EPIC Connection Method?**
- [x] **Option A: EPIC FHIR API with SMART on FHIR launch** ✅ **APPROVED**
- Only use Option B for gaps that EPIC has not exposed yet

**Q3: Read-only or Read-write?**
- [x] **Read-write** ✅ **APPROVED**
- Write DocumentReference with flattened PDF and structured Observations
- Start read-only for week 1 if security review is pending, then enable writes

---

### Data Flow & Offline Capability

**Q4: Data Sync Strategy?**
- [x] **Hybrid: Option A (fetch on-demand) + Option D (manual sync) + Option B (periodic background every 4 hours)** ✅ **APPROVED**

**Q5: Offline Duration?**
- [x] **Full day (8 hours)** ✅ **APPROVED**
- Clinicians may be off Wi-Fi for a whole shift

**Q6: Data Freshness Requirements?**
- [x] **Recent (< 1 hour) for vitals and medications** ✅ **APPROVED**
- [x] **Same day (< 24 hours) for demographics and history** ✅ **APPROVED**

---

### Required EMR Data Fields

**Q7: Which patient data do you need from the EMR?** ✅ **APPROVED**

**Demographics:**
- [x] MRN (Medical Record Number)
- [x] FIN (Financial/Encounter Number)
- [x] Full Name
- [x] Date of Birth
- [x] Gender/Sex

**Clinical:**
- [x] Active Diagnoses with ICD-10 codes
- [x] Allergies
- [x] Current Medications
- [x] Past SUD diagnoses or problem list entries
- [x] Recent vitals (if available)

**Administrative:**
- [x] Insurance payer name only (for context)
- [x] Care team names
- [x] Admission date for current FIN

**ASAM-related signals:**
- [x] **No copied ASAM content** - We will store our own assessment data and computed level recommendations using **neutral field names**
- [x] If we later license CONTINUUM or CO-Triage, we will store their returned values with **clear source attribution**
- [x] **ASAM requires permission** to integrate their content into technology. See `LEGAL_NOTICE.md`.

---

### Workflow & User Experience

**Q8: Typical Clinician Workflow** ✅ **APPROVED**

```
Step 1: Launch from Cerner or Epic with SMART on FHIR context. Patient and FIN are prefilled.
Step 2: App fetches demographics, diagnoses, allergies, meds. Cache to device.
Step 3: Clinician completes our neutral six-domain triage. No ASAM text is displayed.
Step 4: Validate required fields. Clinician signs with PencilKit. Compute plan hash.
Step 5: Generate PDF. If licensed later, also embed vendor PDF from CONTINUUM. 
        Otherwise, fill a neutral form.
Step 6: Upload PDF as FHIR DocumentReference to the encounter. 
        Write back minimal structured Observations.
Step 7: Clear signature raster from disk. Keep only the cryptographic hash and signer metadata.
```

**Q9: PDF Destination?**
- [x] **Option E: Multiple destinations (Local + EMR upload)** ✅ **APPROVED**
- Local keeps a short-lived copy in app sandbox only for share flow, then deletes

**Q10: Signature Storage?**
- [x] **Option A: Ephemeral plus signature record** ✅ **APPROVED**
- Store: signer name, timestamp, plan hash
- Do NOT store: stroke data after export
- Only stamp the PDF

---

### Test Data Requirements

**Q11: Test Patient Complexity?**
- [x] **Option B: Moderate for week 1** ✅ **APPROVED**
- [x] **Option C: Complex once flowsheet works** (Future)

**Q12: Test Scenarios Needed?** ✅ **APPROVED - All Selected**

- [x] New patient (first assessment)
- [x] Returning patient with multiple FINs
- [x] Various levels including 1, 2.1, 2.5, 3.5, 3.7, 4 (represented as neutral outcomes)
- [x] Alcohol, opioid, stimulant, polysubstance stories
- [x] Co-occurring disorders
- [x] Special populations (pregnant, adolescent)
- [x] Edge cases (no insurance, language barrier)
- [x] Treatment progression and relapse

**Note**: ✅ **10 test patients already created** in `data/test_patients.json` covering all scenarios

---

## 🏗️ APPROVED Architecture

**Launch**: SMART on FHIR app link inside Cerner now and Epic later. OAuth2, OpenID, PKCE.

**Local**: SQLite with SQLCipher. Content key in iOS Keychain. Exclude from iCloud backup. Complete file protection.

**Data**: Neutral assessment schema. No ASAM titles or wording. If licensed later, store vendor outputs with provenance fields such as `source = "ASAM CONTINUUM"`.

**Sync**: Background worker pulls lightweight EMR deltas. Queue uploads of PDFs and Observations. Retries with exponential backoff.

**Adapters**: Strategy pattern with Cerner and Epic implementations. A Mock adapter feeds 10 synthetic patients for demos.

### ⚠️ Hyper-Critical Checks

- ❌ **Do NOT persist FIN or MRN in filenames.** Use an opaque ID.
- ❌ **Do NOT display ASAM names or logos in the UI** unless and until we have a signed permission agreement. See `LEGAL_NOTICE.md`.

### High-Level Design

```
┌──────────────────────────────────────────────────────┐
│                  iPad Application                     │
│                    (SwiftUI)                          │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│              Local SQLite Database                    │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │  Patients  │  │  Encounters │  │  ASAM Plans  │  │
│  │  (cached)  │  │   (FINs)    │  │   (drafts)   │  │
│  └────────────┘  └─────────────┘  └──────────────┘  │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│           Sync Service (Background)                   │
│  - Pulls patient updates from EMR                     │
│  - Queues PDFs for upload                             │
│  - Handles offline queue                              │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│              EMR Adapter (Strategy Pattern)           │
│  ┌──────────────────┐      ┌────────────────────┐    │
│  │  Cerner Adapter  │      │   EPIC Adapter     │    │
│  │  (Current)       │◄────►│   (Future)         │    │
│  └──────────────────┘      └────────────────────┘    │
│                                                        │
│  ┌──────────────────┐      ┌────────────────────┐    │
│  │   Mock Adapter   │      │   Test Adapter     │    │
│  │  (Development)   │      │  (10 patients)     │    │
│  └──────────────────┘      └────────────────────┘    │
└─────────────────────┬────────────────────────────────┘
                      │
                ┌─────┴─────┐
                ▼           ▼
        ┌───────────┐  ┌──────────┐
        │  Cerner   │  │   EPIC   │
        │    EMR    │  │   EMR    │
        └───────────┘  └──────────┘
```

### Key Components

**1. EMR Adapter Layer** (Python/Swift Protocol)
```python
class EMRAdapter(ABC):
    @abstractmethod
    def get_patient_by_mrn(self, mrn: str) -> Patient:
        pass
    
    @abstractmethod
    def get_encounter_by_fin(self, fin: str) -> Encounter:
        pass
    
    @abstractmethod
    def get_patient_diagnoses(self, mrn: str) -> List[Diagnosis]:
        pass
    
    @abstractmethod
    def upload_asam_plan(self, plan_pdf: bytes, fin: str) -> bool:
        pass
```

**2. Data Models**
```python
@dataclass
class Patient:
    mrn: str  # Primary identifier
    name: str
    dob: date
    gender: str
    # ... other fields
    
@dataclass
class Encounter:
    fin: str  # Financial/Visit identifier
    mrn: str  # Links to patient
    encounter_date: datetime
    encounter_type: str
    # ... other fields

@dataclass
class ASAMPlan:
    id: str  # UUID
    mrn: str
    fin: str
    plan_data: dict  # JSON blob
    plan_hash: str  # SHA-256
    pdf_path: str
    created_at: datetime
    signed_at: Optional[datetime]
```

**3. Repository Structure** (Python Package)
```
ASAM_App/
├── src/
│   └── sudplan/
│       ├── __init__.py
│       ├── models/           # Data models
│       │   ├── __init__.py
│       │   ├── patient.py
│       │   ├── encounter.py
│       │   └── asam_plan.py
│       ├── emr/              # EMR adapters
│       │   ├── __init__.py
│       │   ├── base.py       # Abstract base
│       │   ├── cerner.py     # Cerner implementation
│       │   ├── epic.py       # EPIC implementation
│       │   └── mock.py       # Mock for testing
│       ├── services/         # Business logic
│       │   ├── __init__.py
│       │   ├── patient_service.py
│       │   ├── plan_service.py
│       │   └── sync_service.py
│       ├── storage/          # Local database
│       │   ├── __init__.py
│       │   ├── database.py
│       │   └── migrations/
│       └── cli/              # CLI interface (existing agent/)
│           ├── __init__.py
│           └── commands.py
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
│       └── test_patients.json  # 10 test patients
├── tools/
│   └── pdf_export/          # Existing Swift CLI
├── pyproject.toml           # Modern Python packaging
├── requirements.txt         # Dependencies
└── [governance files]
```

---

## 📊 APPROVED Technology Stack

### iPad App
- **SwiftUI** — Modern UI framework
- **GRDB or Core Data** — Local storage
- **PencilKit** — Signature capture
- **PDFKit** — AcroForm fill when official template is licensed. Otherwise neutral PDF.

### Integration
- **FHIR R4** — Standard healthcare API
- **Resources**: Patient, Encounter, Practitioner, QuestionnaireResponse, DocumentReference (PDF), Observation (scores)

### Backend (Python - CLI/Utilities)
- **Python 3.11+** — Modern Python features
- **SQLite** — Local database (already chosen)
- **Pydantic** — Data validation
- **httpx** — Async HTTP for API calls
- **pytest** — Testing framework

### Backend Services (Future - Not Required for POC)
- **Azure Functions** (if needed for fleet policy and remote wipe)
- **Azure Key Vault** (for secrets management)

### Vendor Path
If we want endorsed ASAM logic, use **ASAM CONTINUUM Integration API** and follow their developer process. Their site describes a REST Integration API, certification demo, and typical effort around 200 developer hours.

---

## 🔒 APPROVED Security & Compliance

### Access Control
- **Face ID gate** on open and after 2 minutes idle
- Auto lock on protected data loss notification

### Storage
- Exclude app data from **iCloud backup**
- Mark DB files with **Complete File Protection**

### Network
- **TLS 1.2 minimum** (hospital constraints)
- Use hospital MDM when available
- Optional cert pinning

### Audit
- **Local encrypted audit log** of EMR reads and writes
- Append-only
- Upload a daily audit digest to a secure endpoint

### Retention
- **Purge cached patient data after 3 days** by default
- **Delete signature raster immediately** after successful PDF export

### Authentication
- **OAuth 2.0** for EMR APIs
- Secure token storage (iOS Keychain)
- Automatic token refresh

---

## 🎯 Next Steps for Implementation

**Now that requirements are approved:**

1. ✅ **DONE: Legal notice created** — `LEGAL_NOTICE.md` with IP compliance
2. ✅ **DONE: Test patients created** — 10 synthetic patients in `data/test_patients.json`
3. ⏳ **NEXT: Restructure repository** — Proper Python package layout
4. ⏳ **Confirm connection methods** — Cerner: SMART on FHIR + FHIR R4, Epic: Same
5. ⏳ **Implement EMR Adapter interface** with Mock adapter first
6. ⏳ **Add local schema** — Patient cache, Encounter cache, Plan drafts, Upload queue
7. ⏳ **Build neutral six-domain form** and PDF export with non-PHI filenames
8. ⏳ **Add audit log and retention policy**
9. ⏳ **Prepare ASAM permission request** (if leadership wants official logic)

### What NOT to Do

See `LEGAL_NOTICE.md` for complete list:

- ❌ **Do NOT rename** our tool to include "ASAM", "CONTINUUM", or "CO-Triage"
- ❌ **Do NOT import** or re-typeset ASAM PDFs without a license
- ❌ **Do NOT market** as "ASAM compatible" without written permission
- ❌ **Do NOT copy ASAM text**, questions, decision tables, or marks

### Legal Attribution Block

**Use this block verbatim in the repo and in tickets:**

> **NOTICE**
> This application is not affiliated with or endorsed by the American Society of Addiction Medicine. The terms ASAM, The ASAM Criteria, ASAM CONTINUUM, and CO-Triage are trademarks or registered trademarks of ASAM.
> 
> Integrating ASAM content into technology, reusing ASAM wording, decision logic, forms, or branding requires a permission agreement from ASAM. See [ASAM Copyright and Permissions](https://www.asam.org/asam-criteria/copyright-and-permissions). Contact [asamcriteria@asam.org](mailto:asamcriteria@asam.org).
> 
> Until a signed agreement is in place, this app must not copy or adapt ASAM text, questions, decision tables, PDFs, or marks. Build a neutral six-domain assessment with our own wording. If and when a license is executed, store any ASAM outputs with explicit source attribution fields and add the vendor required notices.

---

**Status**: ✅ **REQUIREMENTS APPROVED - READY FOR IMPLEMENTATION**  
**Confidence**: 95%  
**Next**: Repository restructure + EMR adapter implementation
