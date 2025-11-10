# Level of Care (LOC) Reference Files

**Location**: Philadelphia, PA  
**Last Updated**: November 8, 2025

This directory contains two JSON files that define the Level of Care taxonomy for the SUD Treatment Plan system:

## Files

### 1. `loc_reference_neutral.json` ✅ SHIP-SAFE

**Purpose**: Production-ready Level of Care taxonomy using neutral internal codes.

**Contents**:
- 10 LOC codes (OUT, IOP, PHP, RES, RES-WM, INP, INP-DETOX, OUT-WM, IOP-WM, PHP-WM)
- Capability attributes (biomedical, co-occurring, withdrawal management)
- Validation rules (hours/week, length of stay, medical necessity)
- UI tooltips with neutral clinical language
- Six-domain severity mapping guidelines

**Legal Status**: ✅ Safe to ship - No trademarked terminology

**Usage**:
```python
import json
from pathlib import Path

# Load neutral LOC reference
with open('data/loc_reference_neutral.json') as f:
    loc_ref = json.load(f)

# Get all available levels
levels = loc_ref['levels']

# Find appropriate level by code
iop = next(l for l in levels if l['code'] == 'IOP')
print(iop['display'])  # "Intensive Outpatient Program"
print(iop['ui_tooltip'])

# Validate hours for a level
if patient_hours >= iop['validation']['min_hours_week']:
    print("IOP is appropriate")
```

**EMR Integration**:
When exporting to FHIR, map these codes to:
- **LOINC**: Use `18776-5` (Plan of care note) for DocumentReference
- **SNOMED**: Use `713512009` (Treatment plan recommendation) for Observations
- **Display**: Use the neutral `display` field, never external taxonomy names

---

### 2. `analyst_crosswalk_internal.json` ⚠️ ANALYST-ONLY

**Purpose**: Maps neutral internal codes to external taxonomy names (ASAM Criteria levels).

**Contents**:
- Internal → External code mapping (e.g., "IOP" → "ASAM Level 2.1")
- Domain dimension mapping (Domain 1-6 → ASAM Dimension 1-6)
- License information and contact details
- Usage instructions and restrictions

**Legal Status**: ⚠️ **DO NOT SHIP** - Contains trademarked ASAM terminology

**Restrictions**:
- ❌ DO NOT include in production builds
- ❌ DO NOT include in client-facing documentation  
- ❌ DO NOT commit to public repositories
- ❌ DO NOT distribute without legal approval

**CI Protection**:
The `analyst-files-gate` job in `.github/workflows/ci.yml` will **automatically BLOCK** this file from production artifacts:

```yaml
- name: Block analyst files from dist artifacts
  run: |
    for artifact in dist/*.tar.gz dist/*.whl; do
      if tar -tzf "$artifact" | grep -q 'data/analyst_crosswalk_internal.json'; then
        echo "❌ BLOCKED: Analyst file found in $artifact"
        exit 1
      fi
    done
```

**Use Cases**:
- Internal training and education
- Understanding external research or publications  
- Preparing for potential ASAM Criteria licensing
- Mapping exercises for future integration

**Usage** (Development only):
```python
import json

# Load analyst crosswalk (DEV ONLY)
with open('data/analyst_crosswalk_internal.json') as f:
    crosswalk = json.load(f)

# Find external taxonomy name for internal code
internal_code = "IOP"
mapping = next(m for m in crosswalk['crosswalk'] if m['internal_code'] == internal_code)
print(f"Internal: {internal_code}")
print(f"External: {mapping['external_taxonomy']}")  # "ASAM Level 2.1"

# ⚠️ NEVER use external_taxonomy in production UI or exports!
```

---

## Integration Guide

### 1. Loading LOC Reference in Application

```python
# src/sudplan/services/loc_service.py
import json
from pathlib import Path
from typing import Dict, List, Optional

class LOCService:
    """Service for Level of Care determination and validation."""
    
    def __init__(self, data_dir: Path):
        loc_file = data_dir / "loc_reference_neutral.json"
        with open(loc_file) as f:
            self.loc_data = json.load(f)
        self.levels = {l['code']: l for l in self.loc_data['levels']}
    
    def get_level(self, code: str) -> Optional[Dict]:
        """Get LOC definition by code."""
        return self.levels.get(code)
    
    def validate_hours(self, code: str, hours_per_week: float) -> bool:
        """Validate if hours meet requirements for LOC."""
        level = self.get_level(code)
        if not level or 'validation' not in level:
            return False
        
        val = level['validation']
        if 'min_hours_week' in val and hours_per_week < val['min_hours_week']:
            return False
        if 'max_hours_week' in val and hours_per_week > val['max_hours_week']:
            return False
        
        return True
    
    def requires_biomedical_support(self, code: str) -> bool:
        """Check if LOC requires biomedical capabilities."""
        level = self.get_level(code)
        if not level:
            return False
        
        bio_level = level['capabilities'].get('biomedical', False)
        return bio_level in ['high', 'very_high']
    
    def get_ui_tooltip(self, code: str) -> str:
        """Get neutral tooltip text for UI."""
        level = self.get_level(code)
        return level.get('ui_tooltip', '') if level else ''
```

### 2. Using in Treatment Plan Algorithm

```python
# src/sudplan/services/plan_service.py
from typing import Dict, List

def recommend_loc(assessment: Dict) -> str:
    """
    Recommend appropriate Level of Care based on clinical assessment.
    
    Args:
        assessment: Dict with 'domains' key containing severity scores (0-3) for each domain
    
    Returns:
        Recommended LOC code (e.g., "IOP", "RES", "INP")
    """
    domains = assessment.get('domains', {})
    
    # Extract severity scores (0-3 scale)
    withdrawal_risk = domains.get('1', {}).get('severity', 0)  # Domain 1
    biomedical = domains.get('2', {}).get('severity', 0)       # Domain 2
    emotional = domains.get('3', {}).get('severity', 0)        # Domain 3
    readiness = domains.get('4', {}).get('severity', 0)        # Domain 4
    relapse_risk = domains.get('5', {}).get('severity', 0)     # Domain 5
    environment = domains.get('6', {}).get('severity', 0)      # Domain 6
    
    # Maximum severity across all domains
    max_severity = max(withdrawal_risk, biomedical, emotional, relapse_risk, environment)
    
    # Withdrawal management needed?
    needs_wm = withdrawal_risk >= 2
    
    # Severe cases
    if max_severity >= 3 or biomedical >= 3:
        if needs_wm:
            return "INP-DETOX"  # Medical detox
        return "INP"  # Inpatient
    
    # High severity
    if max_severity >= 2 or environment >= 2:
        if needs_wm:
            return "RES-WM"  # Residential with withdrawal management
        return "RES"  # Residential
    
    # Moderate severity
    if max_severity >= 1 or relapse_risk >= 2:
        if needs_wm:
            return "PHP-WM"  # PHP with withdrawal management
        return "PHP"  # Partial hospitalization
    
    # Mild severity
    if any(v >= 1 for v in [withdrawal_risk, biomedical, emotional, relapse_risk]):
        if needs_wm:
            return "IOP-WM"  # IOP with withdrawal management
        return "IOP"  # Intensive outpatient
    
    # Minimal severity
    if needs_wm:
        return "OUT-WM"  # Outpatient withdrawal management
    return "OUT"  # Standard outpatient
```

### 3. Exporting to EMR (FHIR Observation)

```python
# src/sudplan/services/fhir_service.py
from datetime import datetime

def create_loc_observation(
    patient_id: str,
    encounter_id: str,
    loc_code: str,
    loc_service: LOCService
) -> Dict:
    """
    Create FHIR Observation for recommended Level of Care.
    Uses neutral display names from loc_reference_neutral.json.
    """
    level = loc_service.get_level(loc_code)
    if not level:
        raise ValueError(f"Unknown LOC code: {loc_code}")
    
    return {
        "resourceType": "Observation",
        "status": "final",
        "category": [{
            "coding": [{
                "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                "code": "survey",
                "display": "Survey"
            }]
        }],
        "code": {
            "coding": [{
                "system": "http://snomed.info/sct",
                "code": "713512009",
                "display": "Treatment plan recommendation"
            }]
        },
        "subject": {
            "reference": f"Patient/{patient_id}"
        },
        "encounter": {
            "reference": f"Encounter/{encounter_id}"
        },
        "effectiveDateTime": datetime.utcnow().isoformat() + "Z",
        "valueCodeableConcept": {
            "coding": [{
                "system": "http://hospital.local/CodeSystem/treatment-levels",
                "code": loc_code,
                "display": level['display']  # ✅ Use neutral display name
            }]
        }
    }
```

---

## Testing

### Validation Tests

```python
# tests/test_loc_reference.py
import json
import pytest
from pathlib import Path

@pytest.fixture
def loc_data():
    loc_file = Path(__file__).parent.parent / "data" / "loc_reference_neutral.json"
    with open(loc_file) as f:
        return json.load(f)

def test_all_levels_have_required_fields(loc_data):
    """Ensure all LOC entries have required fields."""
    required = ['code', 'display', 'description', 'intensity', 'setting', 'capabilities']
    
    for level in loc_data['levels']:
        for field in required:
            assert field in level, f"Missing {field} in {level.get('code', 'unknown')}"

def test_no_asam_terminology(loc_data):
    """Ensure neutral file contains no ASAM trademarked terms."""
    prohibited = ['ASAM', 'asam', 'CONTINUUM', 'CO-Triage']
    json_str = json.dumps(loc_data)
    
    for term in prohibited:
        assert term not in json_str, f"Found prohibited term '{term}' in neutral LOC file"

def test_withdrawal_codes_have_wm_capability(loc_data):
    """Codes with -WM suffix must have withdrawal_management capability."""
    for level in loc_data['levels']:
        if '-WM' in level['code']:
            assert level['capabilities'].get('withdrawal_management') is True, \
                f"{level['code']} missing withdrawal_management capability"

def test_validation_rules_consistent(loc_data):
    """Validation rules should be consistent with level intensity."""
    intensity_order = ['low', 'moderate', 'high', 'very_high']
    
    for level in loc_data['levels']:
        if 'min_hours_week' in level.get('validation', {}):
            # Higher intensity should have higher minimum hours
            min_hours = level['validation']['min_hours_week']
            intensity = level['intensity']
            
            if intensity == 'low':
                assert min_hours < 9
            elif intensity == 'moderate':
                assert 9 <= min_hours < 20
            elif intensity in ['high', 'very_high']:
                assert min_hours >= 20 or 'inpatient' in level['setting']
```

### CI Protection Tests

```python
# tests/test_analyst_file_protection.py
import tarfile
import zipfile
from pathlib import Path
import pytest

def test_analyst_file_not_in_wheel():
    """Ensure analyst_crosswalk_internal.json is not in wheel distribution."""
    wheel_files = list(Path('dist').glob('*.whl'))
    
    if not wheel_files:
        pytest.skip("No wheel files found in dist/")
    
    for wheel in wheel_files:
        with zipfile.ZipFile(wheel) as zf:
            names = zf.namelist()
            assert not any('analyst_crosswalk' in n for n in names), \
                f"Analyst file found in {wheel.name}"

def test_analyst_file_not_in_tarball():
    """Ensure analyst_crosswalk_internal.json is not in source distribution."""
    tar_files = list(Path('dist').glob('*.tar.gz'))
    
    if not tar_files:
        pytest.skip("No tarball files found in dist/")
    
    for tarball in tar_files:
        with tarfile.open(tarball) as tf:
            names = tf.getnames()
            assert not any('analyst_crosswalk' in n for n in names), \
                f"Analyst file found in {tarball.name}"
```

---

## Localization (i18n)

For multi-language support, create locale-specific versions:

```
data/
├── loc_reference_neutral.json          # English (default)
├── loc_reference_neutral.es.json       # Spanish
├── loc_reference_neutral.fr.json       # French
└── analyst_crosswalk_internal.json     # No localization needed (analyst-only)
```

Example Spanish localization:

```json
{
  "code": "IOP",
  "display": "Programa Ambulatorio Intensivo",
  "description": "9+ horas de programación estructurada por semana",
  "ui_tooltip": "Programa estructurado para pacientes que necesitan más apoyo que el ambulatorio"
}
```

---

## Migration from Legacy Code

If migrating from code that used ASAM terminology:

```python
# OLD (PROHIBITED)
if patient_data['asam_level'] == '2.1':
    return "Intensive Outpatient"

# NEW (COMPLIANT)
if patient_data['assessment']['recommended_level'] == 'IOP':
    loc_service = LOCService(data_dir)
    level = loc_service.get_level('IOP')
    return level['display']  # "Intensive Outpatient Program"
```

---

## Future Integration with ASAM Criteria

**If organization licenses ASAM Criteria or CONTINUUM API**:

1. Use `analyst_crosswalk_internal.json` to map internal codes to ASAM levels
2. Update `loc_reference_neutral.json` to include ASAM attribution:
   ```json
   "legal_attribution": "ASAM Criteria™ results used by permission of the American Society of Addiction Medicine"
   ```
3. Update CI whitelist to allow ASAM terms in production
4. Update UI to display ASAM level names alongside neutral names
5. Integrate with CONTINUUM API for algorithmic recommendations

---

## Support

**Questions about LOC taxonomy**: Contact clinical team  
**Questions about ASAM licensing**: Contact asamcriteria@asam.org  
**Questions about CI protection**: See `.github/workflows/ci.yml`

**Documentation**:
- EMR Integration: `docs/emr-integration.md`
- Legal Compliance: `LEGAL_NOTICE.md`
- CI/CD Pipeline: `.github/workflows/ci.yml`
