# Repository Restructure Plan

**Date**: November 8, 2025  
**Status**: Ready for Implementation  
**Goal**: Transform simple POC into production-ready EMR-integrated system

---

## 📋 Current Structure (POC)

```
ASAM_App/
├── agent/
│   └── asm.py                    # Monolithic CLI
├── tools/
│   └── pdf_export/
│       └── PDFExport.swift       # Swift PDF tool
├── data/
│   ├── plan.sample.json          # Single test plan
│   ├── test_patients.json        # 10 test patients (NEW)
│   └── README_TEST_PATIENTS.md   # Test data docs (NEW)
├── assets/
│   ├── ASAM_TreatmentPlan_Template.pdf.PLACEHOLDER.txt
│   └── sample_signature.png
├── scripts/
│   └── build-swift-cli.sh
└── [governance docs]
```

---

## 🎯 Target Structure (Production)

```
ASAM_App/
├── src/
│   └── sudplan/                  # Main Python package (Substance Use Disorder Plan)
│       ├── __init__.py
│       │
│       ├── models/               # Data models (Pydantic)
│       │   ├── __init__.py
│       │   ├── patient.py        # Patient, Demographics
│       │   ├── encounter.py      # Encounter/Visit (FIN)
│       │   ├── assessment.py     # Neutral assessment (NOT "ASAM")
│       │   ├── plan.py           # Treatment plan
│       │   └── signature.py      # Signature metadata
│       │
│       ├── emr/                  # EMR adapters (Strategy pattern)
│       │   ├── __init__.py
│       │   ├── base.py           # Abstract EMRAdapter
│       │   ├── cerner.py         # Cerner FHIR implementation
│       │   ├── epic.py           # EPIC FHIR implementation
│       │   └── mock.py           # Mock adapter (uses test_patients.json)
│       │
│       ├── services/             # Business logic
│       │   ├── __init__.py
│       │   ├── patient_service.py    # Patient operations
│       │   ├── assessment_service.py # Assessment logic
│       │   ├── plan_service.py       # Plan generation
│       │   ├── pdf_service.py        # PDF export orchestration
│       │   ├── sync_service.py       # Background sync
│       │   └── audit_service.py      # Audit logging
│       │
│       ├── storage/              # Local database
│       │   ├── __init__.py
│       │   ├── database.py       # SQLite/SQLCipher setup
│       │   ├── schema.py         # Table definitions
│       │   ├── repositories/     # Data access layer
│       │   │   ├── __init__.py
│       │   │   ├── patient_repo.py
│       │   │   ├── encounter_repo.py
│       │   │   ├── assessment_repo.py
│       │   │   └── plan_repo.py
│       │   └── migrations/       # Schema migrations
│       │       ├── 001_initial_schema.sql
│       │       ├── 002_add_audit_log.sql
│       │       └── ...
│       │
│       ├── cli/                  # Command-line interface
│       │   ├── __init__.py
│       │   ├── commands.py       # Refactored asm.py
│       │   ├── scaffold.py       # Scaffold command
│       │   ├── plan.py           # Plan commands (hash, validate)
│       │   └── pdf.py            # PDF export command
│       │
│       ├── utils/                # Utilities
│       │   ├── __init__.py
│       │   ├── crypto.py         # Hashing, canonical JSON
│       │   ├── validators.py     # Field validation
│       │   └── id_generator.py   # Opaque ID generation
│       │
│       └── config/               # Configuration
│           ├── __init__.py
│           ├── settings.py       # App settings
│           └── logging.py        # Logging setup
│
├── tests/                        # Test suite
│   ├── __init__.py
│   ├── conftest.py               # Pytest fixtures
│   │
│   ├── unit/                     # Unit tests
│   │   ├── models/
│   │   ├── services/
│   │   ├── emr/
│   │   └── utils/
│   │
│   ├── integration/              # Integration tests
│   │   ├── test_emr_mock.py
│   │   ├── test_patient_flow.py
│   │   ├── test_assessment_flow.py
│   │   └── test_pdf_export.py
│   │
│   └── fixtures/                 # Test data
│       ├── test_patients.json    # Move from data/
│       ├── test_plans.json
│       └── test_signatures/
│
├── tools/                        # External tools
│   └── pdf_export/
│       ├── PDFExport.swift
│       ├── Package.swift         # Swift package manifest
│       └── README.md
│
├── data/                         # Runtime data (gitignored)
│   ├── .gitkeep
│   └── README.md                 # "Do not commit PHI"
│
├── out/                          # Generated outputs (gitignored)
│   ├── .gitkeep
│   └── README.md                 # "Temporary PDFs only"
│
├── assets/                       # Static assets
│   ├── forms/
│   │   └── neutral_treatment_plan_template.pdf  # NOT "ASAM"
│   └── images/
│       └── sample_signature.png
│
├── scripts/                      # Build and utility scripts
│   ├── build-swift-cli.sh
│   ├── setup-dev-env.sh          # NEW: Dev environment setup
│   ├── run-tests.sh              # NEW: Test runner
│   └── check-legal-compliance.sh # NEW: Scan for ASAM IP violations
│
├── docs/                         # Documentation
│   ├── README.md
│   ├── architecture.md
│   ├── emr-integration.md
│   ├── assessment-schema.md      # Neutral schema docs
│   └── api/                      # API documentation
│
├── .vscode/
│   ├── tasks.json                # Updated tasks
│   ├── launch.json               # Debug configurations
│   └── settings.json             # Workspace settings
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                # CI/CD pipeline
│   │   ├── legal-check.yml       # ASAM IP compliance check
│   │   └── tests.yml             # Test automation
│   ├── GITHUB_RULES.md
│   └── VSCODE_RULES.md
│
├── .specify/                     # Spec-kit framework
│   ├── memory/
│   │   └── constitution.md
│   └── ...
│
├── pyproject.toml                # Modern Python packaging (NEW)
├── requirements.txt              # Python dependencies (NEW)
├── requirements-dev.txt          # Dev dependencies (NEW)
├── setup.py                      # Package setup (NEW)
├── .gitignore                    # Updated with new paths
├── .gitattributes
│
├── LEGAL_NOTICE.md               # ✅ CREATED - ASAM IP compliance
├── DESIGN_CLARIFICATION.md       # ✅ UPDATED - Approved requirements
├── README.md                     # Updated with new structure
├── PRODUCT_DESCRIPTION.md
├── AGENT_CONSTITUTION.md
├── FILE_RULES.md
├── SECURITY.md
├── PRIVACY.md
├── TASKS.md
├── CHANGELOG.md
└── LICENSE
```

---

## 🔄 Migration Steps

### Phase 1: Package Structure (Week 1)

**1.1 Create package skeleton**
```bash
mkdir -p src/sudplan/{models,emr,services,storage/repositories,storage/migrations,cli,utils,config}
touch src/sudplan/__init__.py
# Create __init__.py in all subdirs
```

**1.2 Create pyproject.toml**
```toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "sudplan"
version = "1.0.0"
description = "Substance Use Disorder Treatment Plan System"
readme = "README.md"
requires-python = ">=3.11"
license = {text = "Proprietary"}
authors = [
    {name = "Development Team"}
]

dependencies = [
    "pydantic>=2.0",
    "httpx>=0.24",
    "python-dateutil>=2.8",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "pytest-asyncio>=0.21",
    "pytest-cov>=4.1",
    "black>=23.0",
    "pylint>=2.17",
    "mypy>=1.4",
]

[project.scripts]
sudplan = "sudplan.cli.commands:main"
```

**1.3 Migrate agent/asm.py → src/sudplan/cli/commands.py**
- Refactor monolithic file into modules
- Keep existing commands working
- Add new commands for EMR operations

**1.4 Create data models**
```python
# src/sudplan/models/patient.py
from pydantic import BaseModel, Field
from datetime import date
from typing import Optional, List

class Demographics(BaseModel):
    """Patient demographics - stored locally"""
    first_name: str
    last_name: str
    dob: date
    gender: str
    preferred_language: Optional[str] = "English"

class Patient(BaseModel):
    """Patient master record"""
    mrn: str = Field(..., description="Medical Record Number")
    demographics: Demographics
    cached_at: datetime
    emr_source: str  # "cerner", "epic", "mock"
    
    @property
    def full_name(self) -> str:
        return f"{self.demographics.first_name} {self.demographics.last_name}"
    
    @property
    def age(self) -> int:
        today = date.today()
        return today.year - self.demographics.dob.year - (
            (today.month, today.day) < 
            (self.demographics.dob.month, self.demographics.dob.day)
        )
```

**1.5 Create EMR adapter interface**
```python
# src/sudplan/emr/base.py
from abc import ABC, abstractmethod
from typing import Optional, List
from ..models.patient import Patient
from ..models.encounter import Encounter

class EMRAdapter(ABC):
    """Abstract base for EMR integrations"""
    
    @abstractmethod
    async def get_patient_by_mrn(self, mrn: str) -> Optional[Patient]:
        """Fetch patient by MRN"""
        pass
    
    @abstractmethod
    async def get_encounter_by_fin(self, fin: str) -> Optional[Encounter]:
        """Fetch encounter by FIN"""
        pass
    
    @abstractmethod
    async def get_patient_diagnoses(self, mrn: str) -> List[dict]:
        """Fetch active diagnoses"""
        pass
    
    @abstractmethod
    async def upload_plan_pdf(
        self, 
        pdf_bytes: bytes, 
        fin: str, 
        metadata: dict
    ) -> bool:
        """Upload completed plan PDF to EMR"""
        pass
```

### Phase 2: EMR Integration (Week 2)

**2.1 Implement Mock Adapter**
```python
# src/sudplan/emr/mock.py
import json
from pathlib import Path
from typing import Optional
from .base import EMRAdapter
from ..models.patient import Patient

class MockEMRAdapter(EMRAdapter):
    """Mock adapter using test_patients.json"""
    
    def __init__(self, test_data_path: str = "tests/fixtures/test_patients.json"):
        with open(test_data_path) as f:
            data = json.load(f)
            self.patients = {p['mrn']: p for p in data['test_patients']}
    
    async def get_patient_by_mrn(self, mrn: str) -> Optional[Patient]:
        if patient_data := self.patients.get(mrn):
            return Patient.from_dict(patient_data)
        return None
```

**2.2 Implement Cerner Adapter (Stub)**
```python
# src/sudplan/emr/cerner.py
import httpx
from .base import EMRAdapter
from ..config.settings import settings

class CernerAdapter(EMRAdapter):
    """Cerner FHIR R4 adapter"""
    
    def __init__(self, base_url: str, access_token: str):
        self.base_url = base_url
        self.client = httpx.AsyncClient(
            headers={
                "Authorization": f"Bearer {access_token}",
                "Accept": "application/fhir+json",
            },
            timeout=30.0
        )
    
    async def get_patient_by_mrn(self, mrn: str) -> Optional[Patient]:
        # Week 2: Implement FHIR Patient search
        # GET /Patient?identifier=mrn|{mrn}
        raise NotImplementedError("Cerner integration coming in Week 2")
```

**2.3 Implement EPIC Adapter (Stub)**
```python
# src/sudplan/emr/epic.py
# Similar structure to CernerAdapter
```

### Phase 3: Storage Layer (Week 2-3)

**3.1 Create database schema**
```sql
-- src/sudplan/storage/migrations/001_initial_schema.sql

-- Cached patients
CREATE TABLE patients (
    mrn TEXT PRIMARY KEY,
    data JSON NOT NULL,  -- Full patient record
    emr_source TEXT NOT NULL,
    cached_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL
);

-- Cached encounters
CREATE TABLE encounters (
    fin TEXT PRIMARY KEY,
    mrn TEXT NOT NULL,
    data JSON NOT NULL,
    cached_at TIMESTAMP NOT NULL,
    FOREIGN KEY (mrn) REFERENCES patients(mrn)
);

-- Assessment drafts (neutral schema, NOT "ASAM")
CREATE TABLE assessments (
    id TEXT PRIMARY KEY,  -- UUID
    mrn TEXT NOT NULL,
    fin TEXT NOT NULL,
    domain_1_withdrawal TEXT,  -- JSON blob
    domain_2_medical TEXT,
    domain_3_mental TEXT,
    domain_4_readiness TEXT,
    domain_5_relapse TEXT,
    domain_6_environment TEXT,
    recommended_level TEXT,  -- e.g., "2.1"
    recommended_level_name TEXT,  -- e.g., "Intensive Outpatient"
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    FOREIGN KEY (mrn) REFERENCES patients(mrn),
    FOREIGN KEY (fin) REFERENCES encounters(fin)
);

-- Treatment plans
CREATE TABLE plans (
    id TEXT PRIMARY KEY,  -- Opaque ID (NOT MRN/FIN)
    assessment_id TEXT NOT NULL,
    mrn TEXT NOT NULL,
    fin TEXT NOT NULL,
    plan_hash TEXT NOT NULL,  -- SHA-256
    pdf_path TEXT,
    signed_by TEXT,
    signed_at TIMESTAMP,
    uploaded_to_emr BOOLEAN DEFAULT FALSE,
    uploaded_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    FOREIGN KEY (assessment_id) REFERENCES assessments(id)
);

-- Signature metadata (NOT stroke data)
CREATE TABLE signatures (
    plan_id TEXT PRIMARY KEY,
    signer_name TEXT NOT NULL,
    signer_role TEXT,
    signed_at TIMESTAMP NOT NULL,
    signature_hash TEXT NOT NULL,  -- Hash of signature image
    FOREIGN KEY (plan_id) REFERENCES plans(id)
);

-- Audit log
CREATE TABLE audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TIMESTAMP NOT NULL,
    user_id TEXT,
    action TEXT NOT NULL,  -- "read_patient", "create_assessment", etc.
    resource_type TEXT,  -- "patient", "encounter", "plan"
    resource_id TEXT,
    emr_operation TEXT,  -- "fhir_read", "fhir_write", NULL
    details JSON,
    ip_address TEXT
);

-- Indexes
CREATE INDEX idx_patients_cached_at ON patients(cached_at);
CREATE INDEX idx_patients_expires_at ON patients(expires_at);
CREATE INDEX idx_assessments_mrn ON assessments(mrn);
CREATE INDEX idx_assessments_fin ON assessments(fin);
CREATE INDEX idx_plans_assessment ON plans(assessment_id);
CREATE INDEX idx_plans_mrn ON plans(mrn);
CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_log_action ON audit_log(action);
```

**3.2 Create repositories**
```python
# src/sudplan/storage/repositories/patient_repo.py
class PatientRepository:
    def __init__(self, db: Database):
        self.db = db
    
    async def get_by_mrn(self, mrn: str) -> Optional[Patient]:
        """Get patient from cache"""
        pass
    
    async def save(self, patient: Patient) -> None:
        """Save patient to cache with TTL"""
        pass
    
    async def purge_expired(self) -> int:
        """Remove expired cached patients"""
        pass
```

### Phase 4: Services Layer (Week 3)

**4.1 Create PatientService**
```python
# src/sudplan/services/patient_service.py
class PatientService:
    def __init__(
        self,
        emr_adapter: EMRAdapter,
        patient_repo: PatientRepository,
        audit_service: AuditService
    ):
        self.emr = emr_adapter
        self.repo = patient_repo
        self.audit = audit_service
    
    async def get_patient(self, mrn: str, use_cache: bool = True) -> Patient:
        """Get patient, checking cache first"""
        if use_cache:
            if cached := await self.repo.get_by_mrn(mrn):
                await self.audit.log("read_patient", "cache", mrn)
                return cached
        
        patient = await self.emr.get_patient_by_mrn(mrn)
        if patient:
            await self.repo.save(patient)
            await self.audit.log("read_patient", "emr", mrn)
        return patient
```

**4.2 Create AssessmentService**
```python
# src/sudplan/services/assessment_service.py
class AssessmentService:
    """Business logic for neutral assessments (NOT "ASAM")"""
    
    def create_draft(self, mrn: str, fin: str) -> Assessment:
        """Create new assessment draft"""
        pass
    
    def validate(self, assessment: Assessment) -> List[str]:
        """Validate required fields"""
        pass
    
    def compute_recommendation(self, assessment: Assessment) -> str:
        """Compute level of care recommendation"""
        # NOTE: This is OUR logic, not ASAM's
        # If we license CONTINUUM later, we'll call their API here
        pass
```

**4.3 Create PDFService**
```python
# src/sudplan/services/pdf_service.py
class PDFService:
    def __init__(self, swift_cli_path: str):
        self.swift_cli = swift_cli_path
    
    async def export_plan(
        self,
        plan: Plan,
        signature_image: bytes,
        output_path: Path
    ) -> Path:
        """Export plan to PDF with signature"""
        # Call Swift CLI: tools/pdf_export/pdf_export
        # Fill neutral form (NOT official ASAM template)
        # Stamp signature
        # Return path to generated PDF
        pass
```

### Phase 5: Legal Compliance (Week 1-4)

**5.1 Create legal compliance checker**
```bash
# scripts/check-legal-compliance.sh
#!/bin/bash
# Scan codebase for ASAM IP violations

echo "🔍 Checking for ASAM IP violations..."

# Check for prohibited terms
PROHIBITED_TERMS=(
    "ASAM Criteria"
    "ASAM Level"
    "ASAM Dimension"
    "CONTINUUM"
    "CO-Triage"
    "ASAM Treatment Plan"
)

violations=0

for term in "${PROHIBITED_TERMS[@]}"; do
    matches=$(grep -r "$term" src/ --exclude-dir=__pycache__)
    if [ ! -z "$matches" ]; then
        echo "❌ Found prohibited term: '$term'"
        echo "$matches"
        violations=$((violations+1))
    fi
done

# Check for official ASAM PDF templates
if find assets/ -name "*ASAM*.pdf" | grep -q .; then
    echo "❌ Found ASAM PDF template in assets/"
    violations=$((violations+1))
fi

# Check for MRN/FIN in filenames
if find out/ data/ -type f | grep -E "(MRN|FIN)" | grep -q .; then
    echo "❌ Found MRN/FIN in filenames (PHI violation)"
    violations=$((violations+1))
fi

if [ $violations -eq 0 ]; then
    echo "✅ No ASAM IP violations detected"
    exit 0
else
    echo "❌ $violations violation(s) detected"
    exit 1
fi
```

**5.2 Add pre-commit hook**
```bash
# .git/hooks/pre-commit
#!/bin/bash
./scripts/check-legal-compliance.sh
```

### Phase 6: Testing (Week 3-4)

**6.1 Move test data**
```bash
mv data/test_patients.json tests/fixtures/
mv data/README_TEST_PATIENTS.md tests/fixtures/
```

**6.2 Create integration tests**
```python
# tests/integration/test_patient_flow.py
import pytest
from sudplan.emr.mock import MockEMRAdapter
from sudplan.services.patient_service import PatientService

@pytest.mark.asyncio
async def test_get_patient_from_mock_emr():
    """Test fetching patient from mock EMR"""
    adapter = MockEMRAdapter("tests/fixtures/test_patients.json")
    patient = await adapter.get_patient_by_mrn("TEST001234")
    
    assert patient is not None
    assert patient.demographics.first_name == "Maria"
    assert patient.demographics.last_name == "Rodriguez"
```

---

## ✅ Success Criteria

- [ ] Package structure matches target
- [ ] All existing CLI commands still work
- [ ] Mock EMR adapter returns test patients
- [ ] Database schema supports offline caching
- [ ] No ASAM IP violations in codebase
- [ ] All tests pass
- [ ] Legal compliance checker passes
- [ ] Documentation updated

---

## 🚀 Implementation Order

**Week 1 (Nov 11-15)**:
1. ✅ Create package skeleton
2. ✅ Create pyproject.toml
3. ✅ Migrate asm.py → cli/commands.py
4. ✅ Create data models
5. ✅ Create EMR adapter interface
6. ✅ Implement Mock adapter
7. ✅ Create legal compliance checker

**Week 2 (Nov 18-22)**:
1. Database schema
2. Repository layer
3. Cerner adapter (stub with FHIR client)
4. EPIC adapter (stub)
5. Sync service

**Week 3 (Nov 25-29)**:
1. Services layer (Patient, Assessment, Plan, PDF)
2. Integration tests
3. Update CLI commands for new structure

**Week 4 (Dec 2-6)**:
1. Documentation
2. CI/CD pipeline
3. Code review and refinement

---

**Status**: 📋 Ready for Implementation  
**Next**: Execute Phase 1 - Package Structure
