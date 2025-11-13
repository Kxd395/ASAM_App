# Storage Architecture Analysis - Executive Summary

**Date**: November 13, 2025  
**Requested By**: Product Owner  
**Prepared By**: Development Team  
**Status**: ✅ Analysis Complete

---

## Question

> "Do we have something like this with all the fields from the questionnaire set up?"
> *[Referring to proposed file-based storage architecture with header.json, answers.json, computed.json, audit.log, and PDF artifacts]*

---

## Answer: YES, Partially ✅

We have **solid foundation** with field-path-like storage already working, but missing the file-based structure.

---

## What We Already Have ✅

### 1. Field-Path Storage (Working Now)

**Current Implementation**:
```swift
// Domain.swift
struct Domain {
    var answers: [String: AnswerValue]  // ✅ Field-path-like dictionary!
}

// Example answers stored today:
[
    "q1_substances_alcohol": .single(.string("1-3_days_per_week")),
    "q2_last_use_date": .text("2025-11-12"),
    "q3_withdrawal": .bool(true),
    "q3_withdrawal_symptoms": .multi([.string("tremor"), .string("sweating")])
]
```

**What This Means**:
- ✅ We already use dictionary keys like "q1_substances_alcohol"
- ✅ Easy to convert to proposed format: "d1.substances.alcohol.frequency"
- ✅ All answer types supported (text, number, bool, multi-select, grids)
- ✅ Persistence working via UserDefaults

### 2. Assessment Metadata (Working Now)

**Current Implementation**:
```swift
struct Assessment {
    let id: UUID                      // ✅ Matches assessment_id
    var createdAt: Date               // ✅ Matches started_at
    var updatedAt: Date               // ✅ Matches updated_at
    var status: AssessmentStatus      // ✅ Matches status (draft/complete)
    
    var assessorId: String            // ✅ Matches clinician.userId
    var facilityId: String            // ✅ Matches encounter.location
    
    var domains: [Domain]             // ✅ Matches d1-d6 data
    var locRecommendation: LOCRecommendation?  // ✅ Already computed
}
```

### 3. Progress Tracking (Working Now)

**Current Implementation**:
```swift
// Assessment.swift
func calculateOverallProgress() -> Double {
    // Counts answered vs required questions
}

var completedDomainsCount: Int {
    domains.filter { $0.isComplete }.count
}
```

**What This Means**:
- ✅ Can generate `computed.json` progress section
- ✅ Already tracking "requiredAnswered" and "requiredTotal"

### 4. Severity Storage (Working Now)

**Current Implementation**:
```swift
struct Domain {
    var severity: Int  // 0-4 rating
}
```

**What This Means**:
- ✅ Can generate `computed.json` severity section
- ✅ Already have d1-d6 severities stored

---

## What We're Missing ❌

### 1. File-Based Storage Structure

**Current**: Single UserDefaults blob  
**Proposed**: Separate files per concern

```
Missing:
Documents/ASAM/
├─ index.json          ❌ Load all assessments instead
├─ assessments/<id>/
│  ├─ header.json      ❌ Mixed in Assessment object
│  ├─ answers.json     ❌ Mixed in Domain.answers arrays
│  ├─ computed.json    ❌ Mixed in Assessment/Domain
│  ├─ audit.log        ❌ No audit trail
│  └─ artifacts/
│     ├─ .pdf          ❌ No PDF export yet
│     └─ _bundle.json  ❌ No frozen snapshots
```

### 2. Audit Trail

**Current**: No change tracking  
**Proposed**: Append-only log

```
Missing:
{"ts":"2025-11-13T16:21:11Z","actor":"kdial","action":"create","field":"d1.alcohol","old":null,"new":"daily"}
```

### 3. PDF Export

**Current**: Template exists but not wired up  
**Proposed**: Full export with signature

```
Missing:
- Load template
- Fill form fields from answers
- Add signature image
- Save to artifacts/
```

### 4. Header Separation

**Current**: Demographics mixed in Assessment  
**Proposed**: Separate header.json

```
Missing:
- Patient demographics in header.json
- Consent tracking
- Encounter details
- Clinician info
```

---

## Comparison Table

| Feature | Current | Proposed | Gap |
|---------|---------|----------|-----|
| **Field-path answers** | ✅ `Domain.answers` dict | ✅ `answers.json` | **Minor** - just key format |
| **Assessment metadata** | ✅ `Assessment` struct | ✅ `header.json` | **Small** - restructure only |
| **Progress tracking** | ✅ `calculateProgress()` | ✅ `computed.json` | **Small** - export existing |
| **Severity storage** | ✅ `Domain.severity` | ✅ `computed.json` | **Small** - export existing |
| **Status tracking** | ✅ `AssessmentStatus` | ✅ `index.json` | **Small** - export existing |
| **File-based storage** | ❌ UserDefaults | ✅ Separate files | **LARGE** - new system |
| **Audit trail** | ❌ None | ✅ `audit.log` | **MEDIUM** - new feature |
| **PDF export** | ❌ Not wired | ✅ `artifacts/` | **LARGE** - needs work |
| **File protection** | ❌ Basic | ✅ FileProtectionType | **SMALL** - config change |

---

## Recommended Approach: Hybrid Strategy

### Phase 1: Export Layer (8-12 hours) ✅ READY TO START

**Goal**: Add export capability without breaking current persistence

**What We'll Build**:
```swift
class StorageExporter {
    func export(assessment: Assessment, to directory: URL) async throws {
        // Write header.json (from Assessment metadata)
        // Write answers.json (flatten all Domain.answers)
        // Write computed.json (from severity + progress)
    }
}

class PDFExporter {
    func export(answersFile: URL, templateURL: URL, signatureURL: URL) async throws {
        // Fill PDF form fields
        // Add signature
        // Save to artifacts/
    }
}
```

**Benefits**:
- ✅ Current app keeps working
- ✅ Get PDF export for demo
- ✅ Validate proposed format with real data
- ✅ No breaking changes

**Timeline**: 1-2 sprints (8-12 hours)

### Phase 2: File-Based Primary Storage (Post-Demo) 🔄

**Goal**: Migrate to files as primary, add audit logging

**What We'll Build**:
```swift
class AssessmentFileStore {
    func createAssessment() async throws
    func updateAnswers(_ answers: [String: Any], for id: UUID) async throws
    func appendAuditLog(_ event: AuditEvent) async throws
}
```

**Timeline**: 2-3 sprints (16-24 hours)

### Phase 3: Sync & Advanced Features (Future) ⏳

**Goal**: Cloud sync, search, amend workflow

---

## Documentation Created

1. **[STORAGE_ARCHITECTURE_COMPARISON.md](docs/specs/STORAGE_ARCHITECTURE_COMPARISON.md)** (3,000+ lines)
   - Detailed analysis of current vs proposed
   - Gap analysis with code examples
   - Migration strategies
   - Decision matrix

2. **[STORAGE_EXPORT_SPRINT_PLAN.md](docs/specs/STORAGE_EXPORT_SPRINT_PLAN.md)** (1,000+ lines)
   - Phase 1 implementation tasks
   - Code skeletons for StorageExporter and PDFExporter
   - Test cases
   - Acceptance criteria
   - 8-12 hour effort estimate

---

## Key Insights

### ✅ Good News

1. **We already have field-path storage** - `Domain.answers` dictionary is 90% of the way there
2. **Data model aligns** - Assessment struct maps cleanly to proposed schema
3. **Persistence works** - UserDefaults confirmed via tests
4. **Export is straightforward** - Can convert current format to proposed without breaking changes

### ⚠️ Challenges

1. **PDF export needs work** - Template exists but not wired to form fields
2. **Audit trail is new** - Need to track all changes for compliance
3. **File I/O complexity** - Atomic writes, error handling, directory management
4. **Testing burden** - More edge cases with file-based storage

### 🎯 Recommended Next Steps

1. **Review storage comparison document** (20 min)
2. **Decide on Phase 1 timeline** - When do you need PDF export?
3. **Assign Phase 1 implementation** - StorageExporter + PDFExporter
4. **Schedule demo** - Show exported files + PDF rendering
5. **Plan Phase 2 migration** - Post-demo when we have time to test thoroughly

---

## Questions for Product Owner

1. **PDF Export Urgency**: When do you need PDF export working?
   - Next week → Do Phase 1 now (8-12 hours)
   - Next month → Can take time for Phase 2 full migration

2. **File Protection Level**: What security do you need?
   - `.completeUntilFirstUserAuthentication` (proposed - good for demo)
   - `.complete` (max security - more restrictive)

3. **Audit Detail**: What level of tracking?
   - Field-level changes (proposed - full audit)
   - Assessment-level events (simpler - basic tracking)

4. **Sync Priority**: When do you need cross-device sync?
   - Soon → Do Phase 2 migration ASAP
   - Later → Keep UserDefaults for now, export for PDF only

---

## Conclusion

**YES, we have the foundation!** 

Our current `Domain.answers` dictionary IS field-path storage - just needs formatting changes. We can export to the proposed file structure without breaking existing persistence.

**Recommended**: Start Phase 1 export layer this sprint (8-12 hours) to get PDF working for demo, then migrate to file-based primary storage post-demo when we have time to test thoroughly.

**Next Action**: Review [STORAGE_ARCHITECTURE_COMPARISON.md](docs/specs/STORAGE_ARCHITECTURE_COMPARISON.md) and [STORAGE_EXPORT_SPRINT_PLAN.md](docs/specs/STORAGE_EXPORT_SPRINT_PLAN.md), then decide on timeline.
