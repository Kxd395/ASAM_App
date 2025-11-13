# Storage Architecture Comparison

**Date**: November 13, 2025  
**Status**: Analysis & Roadmap  
**Priority**: High - Demo Preparation

---

## TL;DR

**Current**: We have working persistence using UserDefaults with a monolithic Assessment model that stores answers in a field_path-like dictionary.

**Proposed**: File-based storage with separate concerns (header, answers, computed, audit) that's inspection-friendly and sync-ready.

**Recommendation**: **Hybrid approach** - Keep current model working for demo, add file export layer for PDF generation and future sync.

---

## Current Implementation (What We Have)

### Storage Location
```
UserDefaults → assessments array → JSON blob
```

### File Structure
```swift
// In AssessmentStore.swift
@Published var assessments: [Assessment] = []

// Persisted as single JSON array in UserDefaults
UserDefaults.standard.set(encodedData, forKey: "stored_assessments")
```

### Data Model

**Assessment.swift** (Main entity):
```swift
struct Assessment: Identifiable, Codable {
    let id: UUID
    var createdAt: Date
    var updatedAt: Date
    var status: AssessmentStatus  // draft, inProgress, review, complete
    
    var assessorId: String
    var facilityId: String
    var sessionId: String
    
    var domains: [Domain]         // 6 ASAM dimensions
    var problems: [Problem]
    var locRecommendation: LOCRecommendation?
    var substances: [SubstanceRow]
    
    // Clinical flags
    var vitalsUnstable: Bool
    var pregnant: Bool
    var noWithdrawalSigns: Bool
    var acutePsych: Bool
}
```

**Domain.swift** (Per dimension):
```swift
struct Domain: Identifiable, Codable {
    let id: UUID
    let number: Int              // 1-6
    let title: String
    var severity: Int            // 0-4
    var notes: String
    var isComplete: Bool
    var answers: [String: AnswerValue]  // ✅ Field-path-like storage!
}
```

**AnswerValue enum** (Polymorphic answers):
```swift
enum AnswerValue: Codable {
    case text(String)
    case number(Double)
    case bool(Bool)
    case single(QuestionValue)
    case multi(Set<QuestionValue>)
    case substanceGrid([SubstanceAssessment])
    case impactGrid(ImpactGridAnswer)
    case none
}
```

### Example Answer Storage

Current format in `Domain.answers`:
```swift
[
    "q1_substances_alcohol": .single(.string("1-3_days_per_week")),
    "q2_last_use": .text("2025-11-12"),
    "q3_withdrawal": .bool(true),
    "q3_withdrawal_symptoms": .multi([.string("tremor"), .string("sweating")]),
    "q4_withdrawal_desc": .text("Tremor and sweating today")
]
```

### Persistence Flow

```swift
// 1. User answers question
func saveDomainAnswers(_ newAnswers: [String: AnswerValue]) {
    var updated = assessment
    updated.domains[domainIndex].answers = newAnswers
    assessmentStore.updateAssessment(updated)
}

// 2. Store persists immediately
func updateAssessment(_ assessment: Assessment) {
    assessments[index] = updated
    persistAssessments()  // ← Saves to UserDefaults
}

// 3. On app launch
init() {
    loadPersistedAssessments()  // ← Loads from UserDefaults
}
```

### Strengths ✅

- ✅ **Working right now** - Persistence confirmed via tests
- ✅ **Field-path-like keys** - `Domain.answers` dictionary uses string keys
- ✅ **Type-safe answers** - AnswerValue enum handles all question types
- ✅ **Atomic updates** - Single transaction per assessment update
- ✅ **Progress tracking** - `calculateProgress()` methods work
- ✅ **Status tracking** - Draft → Complete workflow exists

### Weaknesses ❌

- ❌ **Monolithic blob** - All data in one UserDefaults entry (hard to inspect)
- ❌ **No audit trail** - Can't see who changed what when
- ❌ **No separation of concerns** - Header + answers + computed mixed
- ❌ **No PDF artifacts** - Can't export frozen snapshots
- ❌ **No file protection** - UserDefaults not as secure as file-based
- ❌ **Sync-hostile** - Hard to sync partial changes (must send entire assessment)
- ❌ **Limited searchability** - No index for fast patient lookup

---

## Proposed Implementation (From User Request)

### Storage Location
```
<App Sandbox>/Documents/ASAM/
├─ index.json
├─ assessments/<uuid>/
│  ├─ header.json
│  ├─ answers.json
│  ├─ computed.json
│  ├─ audit.log
│  └─ artifacts/
│     ├─ asam_<id>_v1.pdf
│     └─ asam_<id>_bundle.json
└─ tmp/
```

### File Schemas

#### 1. index.json (List View)
```json
{
  "version": 1,
  "assessments": [
    {
      "assessment_id": "7c6dc8f7-...",
      "patient_name": "Doe, Jane",
      "dob": "1987-09-03",
      "mrn": "EIN-00112233",
      "fin": "FIN-984455",
      "status": "draft",
      "started_at": "2025-11-13T16:20:30Z",
      "updated_at": "2025-11-13T16:45:22Z",
      "location": "CRC North",
      "instrument_version": "ASAM_Paper_v2025-11-10"
    }
  ]
}
```

#### 2. header.json (Demographics + Consent)
```json
{
  "patient": {
    "fullName": "Jane Doe",
    "dateOfBirth": "1987-09-03",
    "sexAtBirth": "Female",
    "identifiers": [
      { "system": "urn:ein:mrn", "value": "EIN-00112233" }
    ]
  },
  "encounter": {
    "identifiers": [
      { "system": "urn:ein:fin", "value": "FIN-984455" }
    ],
    "startDateTime": "2025-11-13T16:19:08Z",
    "location": "CRC North",
    "service": "Psych Emergency"
  },
  "clinician": {
    "userId": "kdial",
    "name": "Kevin Dial",
    "credentials": "CRS"
  },
  "assessment": {
    "instrumentVersion": "ASAM_Paper_v2025-11-10",
    "consentSigned": true,
    "consentTimestamp": "2025-11-13T16:20:05Z",
    "sourceProvenance": "manual"
  }
}
```

#### 3. answers.json (All Questionnaire Responses)
```json
{
  "version": 1,
  "answers": {
    "d1.substances.alcohol.frequency": "1-3_days_per_week",
    "d1.substances.alcohol.lastUseDate": "2025-11-12",
    "d1.currentWithdrawal.value": true,
    "d1.currentWithdrawal.symptoms": ["tremor", "sweating"],
    "d1.currentWithdrawal.description": "Tremor and sweating today",
    "d3.symptoms.depression.value": true,
    "d3.symptoms.depression.onlyWhenUsingOrWithdrawing": false,
    "d6.stableHousing.value": false,
    "d6.stableHousing.description": "Couch surfing last month",
    "d6.safetyRelationship.weapon": true,
    "d6.safetyRelationship.killThreat": false,
    "d6.supportNeeds": ["Housing", "Transportation"]
  },
  "prefill": {
    "d2.medications[0].name": {
      "source": "EHR",
      "sourcePath": "MedicationStatement[0].medication",
      "lastUpdated": "2025-11-02",
      "value": "Metformin 500 mg"
    }
  },
  "provenance": {
    "deviceId": "ipad-pro-12-9-1",
    "appVersion": "1.0.0-demo"
  }
}
```

#### 4. computed.json (Derived State)
```json
{
  "version": 1,
  "severity": {
    "d1": 2, "d2": 1, "d3": 3, "d4": 1, "d5": 2, "d6": 4,
    "overall": 4
  },
  "emergency": {
    "active": true,
    "triggers": [
      "d6.safetyRelationship.weapon",
      "d1.currentWithdrawal.value"
    ],
    "firstTriggeredAt": "2025-11-13T16:41:02Z",
    "acknowledgedAt": null
  },
  "progress": {
    "requiredAnswered": 86,
    "requiredTotal": 92
  }
}
```

#### 5. audit.log (Append-Only Trail)
```
{"ts":"2025-11-13T16:21:11Z","actor":"kdial","action":"create","field":"d1.substances.alcohol.frequency","old":null,"new":"1-3_days_per_week"}
{"ts":"2025-11-13T16:41:02Z","actor":"kdial","action":"emergency.trigger","field":"d6.safetyRelationship.weapon","old":false,"new":true}
{"ts":"2025-11-13T16:46:10Z","actor":"kdial","action":"submit","field":null,"old":null,"new":null}
```

#### 6. artifacts/ (Submission Outputs)
- `asam_<id>_v1.pdf` - Rendered treatment plan
- `asam_<id>_bundle.json` - Frozen snapshot at submission

### Strengths ✅

- ✅ **Inspectable** - Can open files in text editor/JSON viewer
- ✅ **Sync-friendly** - Can sync individual files (answers.json only)
- ✅ **Audit trail** - Complete history of changes
- ✅ **Separation of concerns** - Header/answers/computed decoupled
- ✅ **PDF artifacts** - Frozen snapshots for compliance
- ✅ **File protection** - iOS FileProtectionType support
- ✅ **Searchable** - Can add SQLite index for fast lookup
- ✅ **Versioned** - Can track schema changes per file
- ✅ **Amend workflow** - New assessment ID with parent pointer

### Weaknesses ❌

- ❌ **More complex** - Multiple files to coordinate
- ❌ **Atomicity challenges** - Need careful write ordering
- ❌ **More code** - File I/O, path management, error handling
- ❌ **Testing burden** - More edge cases (partial writes, disk full)
- ❌ **Migration required** - Must port existing UserDefaults data

---

## Gap Analysis

### What We Already Have ✅

| Feature | Current | Proposed | Gap |
|---------|---------|----------|-----|
| **Field-path keys** | ✅ `Domain.answers` dictionary | ✅ `answers.json` | Minor - just key naming |
| **Status tracking** | ✅ `AssessmentStatus` enum | ✅ `index.json` status | Match |
| **Progress calculation** | ✅ `calculateProgress()` | ✅ `computed.json` progress | Match |
| **Severity storage** | ✅ `Domain.severity` | ✅ `computed.json` severity | Match |
| **Timestamps** | ✅ `createdAt`, `updatedAt` | ✅ `started_at`, `updated_at` | Match |
| **Polymorphic answers** | ✅ `AnswerValue` enum | ✅ JSON values | Compatible |

### What We're Missing ❌

| Feature | Current | Proposed | Gap Size |
|---------|---------|----------|----------|
| **File-based storage** | ❌ UserDefaults blob | ✅ Separate files | Large |
| **Audit trail** | ❌ None | ✅ `audit.log` | Medium |
| **PDF export** | ❌ None | ✅ `artifacts/` | Large |
| **Header separation** | ❌ Mixed in Assessment | ✅ `header.json` | Small |
| **Computed separation** | ❌ Mixed in Assessment | ✅ `computed.json` | Small |
| **Index file** | ❌ Load all assessments | ✅ `index.json` | Medium |
| **File protection** | ❌ UserDefaults | ✅ FileProtectionType | Small |
| **Amend workflow** | ❌ None | ✅ Parent pointer | Medium |
| **SQLite index** | ❌ None | ⚠️ Optional | Optional |

---

## Recommended Migration Path

### Phase 1: Demo Ready (Current Sprint) ✅

**Goal**: Keep current implementation working, add export capability

**Tasks**:
1. ✅ **Keep UserDefaults persistence** - It works, don't break it
2. 🔄 **Add file export function** - Convert Assessment → file structure
3. 🔄 **Add PDF export** - Use existing template + signature
4. ⏳ **Add file import function** - For testing/sync later

**Code Changes**:
```swift
// New StorageExporter.swift
class StorageExporter {
    func exportAssessment(_ assessment: Assessment, to directory: URL) throws {
        // Write header.json
        let header = makeHeader(from: assessment)
        try writeJSON(header, to: directory.appendingPathComponent("header.json"))
        
        // Write answers.json
        let answers = flattenAnswers(from: assessment.domains)
        try writeJSON(answers, to: directory.appendingPathComponent("answers.json"))
        
        // Write computed.json
        let computed = makeComputed(from: assessment)
        try writeJSON(computed, to: directory.appendingPathComponent("computed.json"))
    }
    
    private func flattenAnswers(from domains: [Domain]) -> [String: Any] {
        var result: [String: Any] = [:]
        for domain in domains {
            let prefix = "d\(domain.number)"
            for (key, value) in domain.answers {
                // Convert "q1_alcohol" → "d1.substances.alcohol"
                let fieldPath = "\(prefix).\(key)"
                result[fieldPath] = value.toJSON()
            }
        }
        return result
    }
}
```

**Outcome**: 
- Current app keeps working
- Can export assessments to proposed format
- PDF generation uses exported files
- Ready for demo

### Phase 2: File-Based Primary Storage (Post-Demo) 🔄

**Goal**: Migrate to file-based storage as primary, deprecate UserDefaults

**Tasks**:
1. **Create AssessmentFileStore** - New storage layer
2. **Implement atomic writes** - tmp/ folder + move
3. **Add index.json management** - Fast list view
4. **Add audit logging** - Append-only trail
5. **Migrate existing data** - UserDefaults → files
6. **Add file protection** - HIPAA compliance
7. **Update AssessmentStore** - Use new backend

**Code Changes**:
```swift
// New AssessmentFileStore.swift
@MainActor
class AssessmentFileStore: ObservableObject {
    private let documentsURL: URL
    private let indexURL: URL
    
    func createAssessment() async throws -> Assessment {
        let assessment = Assessment()
        let dir = assessmentDirectory(for: assessment.id)
        
        // Create directory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        
        // Write header.json
        try await writeHeader(assessment, to: dir)
        
        // Write answers.json (empty)
        try await writeAnswers([:], to: dir)
        
        // Write computed.json
        try await writeComputed(assessment, to: dir)
        
        // Append to audit.log
        try await appendAudit("create", assessment: assessment)
        
        // Update index.json
        try await updateIndex(add: assessment)
        
        return assessment
    }
    
    func updateAnswers(_ answers: [String: AnswerValue], for assessmentId: UUID) async throws {
        let dir = assessmentDirectory(for: assessmentId)
        let tmpDir = dir.appendingPathComponent("../tmp", isDirectory: true)
        
        // Atomic write: tmp → move
        let tmpFile = tmpDir.appendingPathComponent("answers.json")
        try await writeJSON(answers, to: tmpFile)
        
        let finalFile = dir.appendingPathComponent("answers.json")
        try FileManager.default.moveItem(at: tmpFile, to: finalFile)
        
        // Append to audit.log
        try await appendAudit("update", answers: answers, assessmentId: assessmentId)
        
        // Update computed.json
        let computed = calculateComputed(from: answers)
        try await writeComputed(computed, to: dir)
        
        // Update index.json updated_at
        try await updateIndexTimestamp(assessmentId)
    }
}
```

### Phase 3: Sync & Advanced Features (Future) ⏳

**Goal**: Enable cloud sync and multi-device support

**Tasks**:
1. **Add sync worker** - Watch answers.json for changes
2. **Implement conflict resolution** - Last-write-wins or merge
3. **Add SQLite index** - Fast search across assessments
4. **Add amend workflow** - Parent assessment pointers
5. **Add bulk export** - ZIP all assessments

---

## Field Path Mapping

### Current Key Format
```swift
Domain.answers = [
    "q1_substances_alcohol": .single(.string("daily")),
    "q2_last_use_date": .text("2025-11-12")
]
```

### Proposed Key Format (Dot Notation)
```json
{
  "d1.substances.alcohol.frequency": "daily",
  "d1.substances.alcohol.lastUseDate": "2025-11-12"
}
```

### Migration Function
```swift
extension Domain {
    func toFieldPathAnswers() -> [String: Any] {
        var result: [String: Any] = [:]
        let prefix = "d\(number)"
        
        for (key, value) in answers {
            // Convert snake_case to dot.notation
            let parts = key.split(separator: "_")
            let camelKey = parts.enumerated().map { index, part in
                index == 0 ? String(part) : part.capitalized
            }.joined()
            
            let fieldPath = "\(prefix).\(camelKey)"
            result[fieldPath] = value.toJSON()
        }
        
        return result
    }
}
```

---

## Decision Matrix

| Criteria | UserDefaults (Current) | File-Based (Proposed) | Hybrid (Recommended) |
|----------|------------------------|----------------------|----------------------|
| **Demo Ready** | ✅ Works now | ❌ Weeks of work | ✅ Works now + export |
| **Inspectable** | ❌ Binary blob | ✅ JSON files | ✅ Export to files |
| **Audit Trail** | ❌ None | ✅ Full history | ⚠️ Add later |
| **PDF Export** | ❌ Hard | ✅ Built-in | ✅ Export + render |
| **Sync Ready** | ❌ Monolithic | ✅ Incremental | ⚠️ Export-based |
| **Security** | ⚠️ Basic | ✅ File protection | ✅ Can add protection |
| **Complexity** | ✅ Simple | ❌ Complex | ⚠️ Medium |
| **Performance** | ✅ Fast (in-memory) | ⚠️ Disk I/O | ✅ Fast + export |
| **Testing Burden** | ✅ Low | ❌ High | ⚠️ Medium |

### Recommendation: **Hybrid Approach**

**For Demo (Next 2 Weeks)**:
- ✅ Keep UserDefaults as primary storage
- ✅ Add export layer for PDF generation
- ✅ Test export format matches proposed spec
- ✅ Validate PDF rendering works

**Post-Demo (Future Sprints)**:
- 🔄 Migrate to file-based primary storage
- 🔄 Add audit logging
- 🔄 Add sync capability
- 🔄 Add SQLite index for search

**Rationale**:
- Don't break working persistence before demo
- Get PDF export working ASAP (critical for demo)
- Validate proposed format with real data
- Migrate when we have time to test thoroughly

---

## Implementation Checklist

### Phase 1: Export Layer (This Sprint) ✅

- [ ] Create `StorageExporter.swift`
  - [ ] `exportAssessment(_:to:)` - Full export
  - [ ] `makeHeader(from:)` - Convert to header.json schema
  - [ ] `flattenAnswers(from:)` - Convert Domain.answers to field paths
  - [ ] `makeComputed(from:)` - Extract severity, progress, flags
  - [ ] `writeJSON(_:to:)` - Atomic file write

- [ ] Create `PDFExporter.swift`
  - [ ] Load template PDF
  - [ ] Fill form fields from answers.json
  - [ ] Add signature image
  - [ ] Save to artifacts/ folder
  - [ ] Create frozen bundle.json

- [ ] Add export tests
  - [ ] Test header.json schema matches spec
  - [ ] Test answers.json uses correct field paths
  - [ ] Test computed.json has all required fields
  - [ ] Test PDF renders correctly
  - [ ] Test bundle.json is complete snapshot

- [ ] Wire up to UI
  - [ ] Add "Export PDF" button to assessment detail
  - [ ] Show export progress
  - [ ] Handle export errors gracefully
  - [ ] Allow viewing exported PDF

### Phase 2: File-Based Storage (Post-Demo) 🔄

- [ ] Create `AssessmentFileStore.swift`
  - [ ] Directory structure setup
  - [ ] index.json management
  - [ ] Atomic write operations
  - [ ] Audit log appending
  - [ ] File protection setup

- [ ] Migration script
  - [ ] Export all UserDefaults assessments
  - [ ] Validate exported files
  - [ ] Switch to file store
  - [ ] Archive old UserDefaults data

- [ ] Update AssessmentStore
  - [ ] Use AssessmentFileStore as backend
  - [ ] Maintain same public API
  - [ ] Add migration on first launch

### Phase 3: Advanced Features (Future) ⏳

- [ ] Sync implementation
- [ ] SQLite index
- [ ] Amend workflow
- [ ] Bulk export

---

## Questions for Product Owner

1. **Timeline**: When do you need PDF export for demo?
   - Answer determines if we do hybrid or rush full migration

2. **Security**: What FileProtectionType level required?
   - `.completeUntilFirstUserAuthentication` (proposed)
   - `.complete` (max security, more restrictive)

3. **Audit Requirements**: What level of audit detail?
   - Field-level changes (proposed)
   - Assessment-level events only (simpler)

4. **Sync Priority**: When do we need cross-device sync?
   - Determines when we do Phase 2 migration

5. **Search Requirements**: Do we need SQLite index?
   - How many assessments per device expected?
   - What search fields most important?

---

## Conclusion

**We have a solid foundation** with field-path-like storage in `Domain.answers` and working persistence via UserDefaults.

**The proposed file-based architecture** is excellent for production but requires significant effort to implement safely.

**Recommended approach**: Hybrid strategy
- Phase 1: Add export layer → Get PDF working for demo
- Phase 2: Migrate to files → Get audit + sync benefits
- Phase 3: Advanced features → Search, sync, amend workflow

**Next Action**: Review this document with team, decide on timeline for Phase 1 export implementation.
