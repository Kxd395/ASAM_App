# Test Patients Documentation

## ⚠️ PHI Notice

**THIS IS SYNTHETIC TEST DATA ONLY**

All patient data in `test_patients.json` is entirely synthetic and contains **NO real patient information**. This data is created for development and testing purposes in compliance with the HIPAA Privacy Rule (45 CFR §164.514(a)).

## Overview

This file contains 10 comprehensive synthetic patient records covering diverse ASAM assessment scenarios, special populations, and clinical complexities.

## Patient Summary

| MRN | Name | Age | Primary Substance | Recommended Level | Special Population |
|-----|------|-----|-------------------|-------------------|--------------------|
| TEST001234 | Maria Rodriguez | 39 | Alcohol | IOP | Spanish-speaking |
| TEST002345 | James Thompson | 52 | Opioids (Rx) | RES-3 | Chronic pain, MAT |
| TEST003456 | Ashley Williams | 17 | Cannabis | OP | Adolescent/Minor, ADHD |
| TEST004567 | Robert Jackson | 56 | Cocaine/Alcohol | INP-MED | Homeless, Co-occurring SMI |
| TEST005678 | Lisa Chen | 30 | Methamphetamine | INP-MED-PW | First trimester pregnancy |
| TEST006789 | Michael O'Brien | 69 | Alcohol | PH | Elderly, Late-onset, Grief |
| TEST007890 | Tyrone Washington | 34 | Heroin | IOP | Military Veteran, PTSD |
| TEST008901 | Sophia Martinez | 36 | Benzodiazepines | INP-DETOX | **CRITICAL: Seizure risk** |
| TEST009012 | Kevin Nguyen | 26 | Alcohol (binge) | EARLY | Young professional |
| TEST010123 | Patricia Johnson | 44 | None (in recovery) | MAT-MAINT | Success story, 18 mo clean |

## Internal Level Codes Represented

**See `docs/mappings/levels.md` for internal-to-clinical mapping (analyst use only)**

- **EARLY** - Early Intervention (1 patient)
- **OP** - Outpatient Services (1 patient)
- **IOP** - Intensive Outpatient (2 patients, one with MAT)
- **PH** - Partial Hospitalization (1 patient)
- **RES-3** - Residential Treatment (1 patient)
- **INP-MED** - Inpatient Medical (2 patients)
- **INP-MED-PW** - Inpatient Pregnant Women (1 patient)
- **MAT-MAINT** - Medication Maintenance (1 patient in stable recovery)

## Clinical Scenarios

### 1. TEST001234 - Maria Rodriguez
**Scenario**: Moderate alcohol use disorder with anxiety, Spanish-speaking patient

**Key Features**:
- Language barrier requiring interpreter
- Co-occurring anxiety disorder
- Relationship stress as trigger
- Multiple visit history (ER + Assessment)

**Testing Use Cases**:
- Multilingual support
- Co-occurring disorder management
- Social determinants of health

### 2. TEST002345 - James Thompson
**Scenario**: Prescription opioid misuse following injury, on MAT

**Key Features**:
- Iatrogenic addiction (started with legitimate pain management)
- Chronic pain comorbidity
- Already engaged in MAT (buprenorphine)
- Divorced, lives alone (limited support)

**Testing Use Cases**:
- MAT integration
- Chronic pain + SUD
- Step-up in level of care

### 3. TEST003456 - Ashley Williams
**Scenario**: Adolescent cannabis use disorder, school-mandated

**Key Features**:
- **MINOR** - requires parent/guardian consent
- ADHD with controlled medication
- Pre-contemplation stage (mandated, not self-referred)
- CHIP insurance

**Testing Use Cases**:
- Minor patient workflows
- Parental consent requirements
- School coordination
- Adolescent-specific assessments

### 4. TEST004567 - Robert Jackson
**Scenario**: Severe polysubstance use with homelessness and schizophrenia

**Key Features**:
- **HOMELESS** - no fixed address
- Co-occurring severe mental illness (schizophrenia)
- Medication non-compliance
- Crisis assessment
- Multiple social barriers

**Testing Use Cases**:
- Complex co-occurring disorders
- Social services coordination
- Address/contact challenges
- High-acuity stabilization

### 5. TEST005678 - Lisa Chen
**Scenario**: Pregnant woman with methamphetamine use disorder

**Key Features**:
- **PREGNANT** (12 weeks gestation, first trimester)
- High-risk pregnancy
- Bipolar disorder (stable on pregnancy-safe medication)
- Highly motivated (wants to stop for baby)
- Requires OB coordination

**Testing Use Cases**:
- Pregnancy-specific protocols
- Multi-specialty coordination (SUD + OB)
- Medication safety in pregnancy
- Enhanced motivation assessment

### 6. TEST006789 - Michael O'Brien
**Scenario**: Elderly patient with late-onset alcohol use disorder after spouse's death

**Key Features**:
- **GERIATRIC** (age 69)
- Multiple chronic medical conditions (HTN, DM2, dementia)
- Grief-related substance use (recent onset)
- Medicare insurance
- Polypharmacy concerns

**Testing Use Cases**:
- Geriatric assessments
- Medical complexity
- Grief counseling integration
- Age-related withdrawal risks

### 7. TEST007890 - Tyrone Washington
**Scenario**: Military veteran with opioid use disorder and PTSD

**Key Features**:
- **VETERAN** (Iraq deployment 2008-2013)
- Combat-related PTSD
- Heroin use (intranasal route)
- VA coordination needed
- Good MAT candidate

**Testing Use Cases**:
- Military/VA integration
- Trauma-informed care
- PTSD + SUD dual diagnosis
- Benefits coordination

### 8. TEST008901 - Sophia Martinez
**Scenario**: Benzodiazepine use disorder requiring medical detox

**Key Features**:
- **CRITICAL CASE** - benzodiazepine withdrawal is life-threatening
- Started with legitimate prescription, escalated
- Co-occurring panic disorder and OCD
- HIGH SEIZURE RISK without medical supervision
- Cannot do outpatient taper

**Testing Use Cases**:
- Medical emergency protocols
- Detox requirements
- Risk stratification
- Level 3.7 medical necessity documentation

### 9. TEST009012 - Kevin Nguyen
**Scenario**: Young professional with mild alcohol use disorder, self-referred

**Key Features**:
- **EARLY INTERVENTION** candidate
- Self-referred (good insight)
- Binge drinking pattern (not daily use)
- Mild depression, work stress
- Bilingual (English/Vietnamese)
- Good prognosis with brief intervention

**Testing Use Cases**:
- Screening and brief intervention (SBI)
- Prevention focus
- Motivational interviewing
- Low-intensity services

### 10. TEST010123 - Patricia Johnson
**Scenario**: Success story - patient in stable recovery on MAT

**Key Features**:
- **18 MONTHS CLEAN** - sustained recovery
- Stable on buprenorphine/naloxone
- Active in NA (3x/week meetings)
- Excellent family support
- Employed and thriving
- Regular monthly follow-ups

**Testing Use Cases**:
- Maintenance phase workflows
- Long-term success tracking
- Relapse prevention monitoring
- Recovery milestone documentation

## Data Structure

Each patient record includes:

```json
{
  "mrn": "Unique Medical Record Number",
  "fin_current": "Current Financial/Visit Identifier",
  "demographics": {
    // Name, DOB, gender, address, contact, language, marital status, emergency contact
  },
  "insurance": {
    // Primary insurance, member ID, group number, supplemental
  },
  "clinical": {
    "primary_diagnosis": "ICD-10 code and description",
    "secondary_diagnoses": ["Array of ICD-10 diagnoses"],
    "substance_use": {
      // Substance, frequency, amount, onset, last use, route
    },
    "current_medications": ["List of current meds with dosing"],
    "allergies": ["Drug allergies"]
  },
  "assessment": {
    "recommended_level": "Internal level code",
    "level_name": "Level description",
    "domains": {
      // Assessment of all 6 clinical domains
    }
  },
  "visit_history": [
    {
      "fin": "Visit identifier",
      "date": "ISO date",
      "type": "Visit type",
      "provider": "Provider name",
      "location": "Facility"
    }
  ],
  "notes": "Clinical notes and special considerations"
}
```

## Six-Domain Assessment Dimensions

All patients include assessment across six clinical domains:

1. **Domain 1** - Acute Intoxication and/or Withdrawal Potential
2. **Domain 2** - Biomedical Conditions and Complications
3. **Domain 3** - Emotional, Behavioral, or Cognitive Conditions and Complications
4. **Domain 4** - Readiness to Change
5. **Domain 5** - Relapse, Continued Use, or Continued Problem Potential
6. **Domain 6** - Recovery/Living Environment

## Special Populations Covered

- ✅ Spanish-speaking (interpreter needs)
- ✅ Adolescent/Minor (parental consent)
- ✅ Homeless (address/contact challenges)
- ✅ Pregnant (high-risk, OB coordination)
- ✅ Elderly/Geriatric (medical complexity)
- ✅ Military Veteran (VA coordination)
- ✅ Recovery/Maintenance (success story)
- ✅ Bilingual (Vietnamese)

## Edge Cases and Challenges

1. **No Insurance** - Robert Jackson (Homeless, Medicaid)
2. **Language Barriers** - Maria Rodriguez (Spanish), Kevin Nguyen (Vietnamese)
3. **Minor Requiring Consent** - Ashley Williams (age 17)
4. **No Fixed Address** - Robert Jackson (Homeless)
5. **Complex Comorbidities** - Multiple patients
6. **Life-Threatening Withdrawal** - Sophia Martinez (benzodiazepines)
7. **Pregnancy Complications** - Lisa Chen (first trimester, high-risk)
8. **Medication Non-compliance** - Robert Jackson (schizophrenia)

## MRN and FIN Identifiers

### Medical Record Number (MRN)
- **Format**: `TEST######` (e.g., TEST001234)
- **Purpose**: Unique patient identifier across all encounters
- **Persistence**: Permanent, assigned at first registration
- **Usage**: Links all patient encounters, demographics, and clinical history

### Financial/Visit Number (FIN)
- **Format**: `FIN##########` (e.g., FIN2025110801)
- **Structure**: FIN + YYYYMMDD + sequence (2 digits)
- **Purpose**: Unique encounter/visit identifier
- **Persistence**: One per visit/encounter
- **Usage**: Tracks specific episodes of care, billing, and encounter-specific data

### Example:
Patient Maria Rodriguez (MRN: TEST001234) has TWO encounters:
- **FIN2025110801** - Current ASAM Assessment (Nov 8, 2025)
- **FIN2025080515** - Previous ER Visit (Aug 5, 2025)

## ICD-10 Diagnosis Codes Represented

### Substance Use Disorders (F10-F19)
- F10.10 - Alcohol use disorder, mild
- F10.20 - Alcohol use disorder, moderate
- F11.20 - Opioid use disorder, moderate
- F12.20 - Cannabis use disorder, moderate
- F13.20 - Sedative/anxiolytic use disorder, severe (benzodiazepines)
- F14.20 - Cocaine use disorder, severe
- F15.20 - Stimulant use disorder, severe (methamphetamine)

### Mental Health Disorders (F20-F99)
- F20.9 - Schizophrenia, unspecified
- F31.31 - Bipolar disorder, current episode depressed
- F32.0 - Major depressive disorder, single episode, mild
- F32.1 - Major depressive disorder, single episode, moderate
- F33.1 - Major depressive disorder, recurrent, moderate
- F41.0 - Panic disorder
- F41.1 - Generalized anxiety disorder
- F42.2 - Obsessive-compulsive disorder
- F43.10 - Post-traumatic stress disorder
- F90.2 - ADHD, combined type

### Z-Codes (Social Determinants, Treatment Status)
- Z33.1 - Pregnant state, incidental
- Z56.9 - Work-related stress
- Z59.0 - Homelessness
- Z63.0 - Problems in relationship with spouse or partner
- Z65.5 - Exposure to disaster/war/other hostilities
- Z71.51 - Drug counseling and surveillance

### Medical Conditions
- E11.9 - Type 2 diabetes mellitus
- F03.90 - Dementia, mild
- I10 - Essential hypertension
- M54.5 - Low back pain

## Using This Test Data

### In Development

```python
import json

# Load test patients
with open('data/test_patients.json', 'r') as f:
    data = json.load(f)
    patients = data['test_patients']

# Get specific patient by MRN
maria = next(p for p in patients if p['mrn'] == 'TEST001234')

# Get all patients requiring high-acuity care
high_acuity = [p for p in patients if p['assessment']['recommended_level'] in ['INP-MED', 'INP-DETOX']]

# Get all adolescent patients
adolescents = [p for p in patients if (2025 - int(p['demographics']['dob'][:4])) < 18]
```

### In Tests

```python
import pytest
from data.test_patients import load_test_patients

@pytest.fixture
def spanish_speaking_patient():
    """Patient requiring interpreter services"""
    patients = load_test_patients()
    return next(p for p in patients if p['mrn'] == 'TEST001234')

@pytest.fixture
def minor_patient():
    """Minor patient requiring parental consent"""
    patients = load_test_patients()
    return next(p for p in patients if p['mrn'] == 'TEST003456')

def test_parental_consent_required(minor_patient):
    age = calculate_age(minor_patient['demographics']['dob'])
    assert age < 18
    assert 'emergency_contact' in minor_patient['demographics']
```

### For EMR Mock Adapter

```python
class MockEMRAdapter(EMRAdapter):
    def __init__(self):
        with open('data/test_patients.json', 'r') as f:
            self.patients = json.load(f)['test_patients']
    
    def get_patient_by_mrn(self, mrn: str) -> Optional[Patient]:
        patient_data = next((p for p in self.patients if p['mrn'] == mrn), None)
        if patient_data:
            return Patient.from_dict(patient_data)
        return None
    
    def get_encounter_by_fin(self, fin: str) -> Optional[Encounter]:
        for patient in self.patients:
            for visit in patient['visit_history']:
                if visit['fin'] == fin:
                    return Encounter.from_dict(visit, patient['mrn'])
        return None
```

## Validation Checks

All test patients pass the following validation:

- ✅ Valid MRN format (TEST###### pattern)
- ✅ Valid FIN format (FIN########## pattern)
- ✅ Valid ICD-10 diagnosis codes
- ✅ All 6 ASAM dimensions assessed
- ✅ ASAM level matches clinical presentation
- ✅ Complete demographics (required fields)
- ✅ At least one visit/encounter
- ✅ Age calculation from DOB
- ✅ Insurance information present
- ✅ Clinical notes provided

## Security and Privacy

Per the Constitution (Section I: PHI Protection First):

1. **No Real PHI**: All data is synthetic
2. **Opaque Identifiers**: MRN/FIN do not encode patient information
3. **No PHI in Logs**: Test data designed to avoid logging sensitive details
4. **Git Safety**: Safe to commit to repository (synthetic only)
5. **Development Use Only**: Not for production or research

## Next Steps

1. ✅ **Test data created** - 10 diverse patients with MRN/FIN
2. ⏳ **Answer design questions** (Q1-Q12 in DESIGN_CLARIFICATION.md)
3. ⏳ **Create data models** (Patient, Encounter, ASAMPlan classes)
4. ⏳ **Build MockEMRAdapter** using this test data
5. ⏳ **Implement validation** against these test cases
6. ⏳ **Create unit tests** for each patient scenario
7. ⏳ **Build integration tests** for EMR workflows

## Questions or Additions Needed?

If you need additional test patients or scenarios:
- Different ASAM levels
- Additional special populations
- Specific clinical complications
- Edge cases or error conditions

Please update this file or create additional test patient files in the same format.

---

**Remember**: This is synthetic test data for development purposes only. Always use appropriate security measures when handling real patient information in production.
