# Storage Export Implementation - Sprint Plan

**Date**: November 13, 2025  
**Goal**: Add file-based export for PDF generation while keeping UserDefaults working  
**Effort**: ~8-12 hours  
**Status**: Ready to Start

---

## Overview

Add export capability to convert current Assessment model to the proposed file-based format without breaking existing persistence. This enables PDF generation and validates the storage spec before full migration.

---

## Sprint Tasks

### Task 1: Create StorageExporter (3-4 hours)

**File**: `ios/ASAMAssessment/ASAMAssessment/Services/StorageExporter.swift`

**Responsibilities**:
- Export Assessment → directory with header/answers/computed JSON files
- Convert Domain.answers to field_path notation
- Atomic file writes for safety

**Code Skeleton**:
```swift
import Foundation

class StorageExporter {
    
    // MARK: - Public API
    
    /// Export assessment to file-based format
    func export(assessment: Assessment, to baseURL: URL) async throws -> URL {
        let assessmentDir = baseURL
            .appendingPathComponent("assessments")
            .appendingPathComponent(assessment.id.uuidString)
        
        // Create directory structure
        try FileManager.default.createDirectory(
            at: assessmentDir,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        
        // Write all files
        try await writeHeader(assessment, to: assessmentDir)
        try await writeAnswers(assessment, to: assessmentDir)
        try await writeComputed(assessment, to: assessmentDir)
        
        return assessmentDir
    }
    
    // MARK: - Header Generation
    
    private func writeHeader(_ assessment: Assessment, to dir: URL) async throws {
        let header: [String: Any] = [
            "patient": [
                "fullName": "REDACTED",  // PHI - get from assessment
                "dateOfBirth": "REDACTED",
                "sexAtBirth": "REDACTED",
                "identifiers": [
                    ["system": "urn:ein:mrn", "value": "REDACTED"]
                ]
            ],
            "encounter": [
                "identifiers": [
                    ["system": "urn:ein:fin", "value": "REDACTED"]
                ],
                "startDateTime": ISO8601DateFormatter().string(from: assessment.createdAt),
                "location": "REDACTED",
                "service": "ASAM Assessment"
            ],
            "clinician": [
                "userId": assessment.assessorId,
                "name": "REDACTED",
                "credentials": "REDACTED"
            ],
            "assessment": [
                "instrumentVersion": "ASAM_Paper_v2025-11-10",
                "consentSigned": true,
                "consentTimestamp": ISO8601DateFormatter().string(from: assessment.createdAt),
                "sourceProvenance": "manual"
            ]
        ]
        
        try await writeJSON(header, to: dir.appendingPathComponent("header.json"))
    }
    
    // MARK: - Answers Flattening
    
    private func writeAnswers(_ assessment: Assessment, to dir: URL) async throws {
        var answers: [String: Any] = [:]
        
        // Flatten all domain answers
        for domain in assessment.domains {
            let domainAnswers = flattenDomainAnswers(domain)
            answers.merge(domainAnswers) { _, new in new }
        }
        
        let answersDoc: [String: Any] = [
            "version": 1,
            "answers": answers,
            "prefill": [:],  // TODO: EHR integration
            "provenance": [
                "deviceId": await UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "1.0.0"
            ]
        ]
        
        try await writeJSON(answersDoc, to: dir.appendingPathComponent("answers.json"))
    }
    
    private func flattenDomainAnswers(_ domain: Domain) -> [String: Any] {
        var result: [String: Any] = [:]
        let prefix = "d\(domain.number)"
        
        for (key, value) in domain.answers {
            // Convert key to field_path notation
            let fieldPath = "\(prefix).\(key)"
            
            // Convert AnswerValue to JSON-compatible type
            result[fieldPath] = convertAnswerValue(value)
        }
        
        return result
    }
    
    private func convertAnswerValue(_ value: AnswerValue) -> Any {
        switch value {
        case .text(let str):
            return str
        case .number(let num):
            return num
        case .bool(let bool):
            return bool
        case .single(let qv):
            return convertQuestionValue(qv)
        case .multi(let set):
            return set.map { convertQuestionValue($0) }
        case .substanceGrid(let assessments):
            return assessments.map { $0.toJSON() }
        case .impactGrid(let grid):
            return grid.toJSON()
        case .none:
            return NSNull()
        }
    }
    
    private func convertQuestionValue(_ value: QuestionValue) -> Any {
        switch value {
        case .string(let str):
            return str
        case .number(let num):
            return num
        case .bool(let bool):
            return bool
        }
    }
    
    // MARK: - Computed State
    
    private func writeComputed(_ assessment: Assessment, to dir: URL) async throws {
        let computed: [String: Any] = [
            "version": 1,
            "severity": [
                "d1": assessment.domains[0].severity,
                "d2": assessment.domains[1].severity,
                "d3": assessment.domains[2].severity,
                "d4": assessment.domains[3].severity,
                "d5": assessment.domains[4].severity,
                "d6": assessment.domains[5].severity,
                "overall": assessment.domains.map(\.severity).max() ?? 0
            ],
            "emergency": [
                "active": assessment.vitalsUnstable || assessment.acutePsych,
                "triggers": emergencyTriggers(assessment),
                "firstTriggeredAt": NSNull(),  // TODO: Track this
                "acknowledgedAt": NSNull()
            ],
            "progress": [
                "requiredAnswered": totalAnsweredQuestions(assessment),
                "requiredTotal": totalRequiredQuestions(assessment)
            ]
        ]
        
        try await writeJSON(computed, to: dir.appendingPathComponent("computed.json"))
    }
    
    private func emergencyTriggers(_ assessment: Assessment) -> [String] {
        var triggers: [String] = []
        
        if assessment.vitalsUnstable {
            triggers.append("vitals_unstable")
        }
        if assessment.acutePsych {
            triggers.append("acute_psych")
        }
        
        // Check domain-specific triggers
        // TODO: Add field_path triggers from answers
        
        return triggers
    }
    
    private func totalAnsweredQuestions(_ assessment: Assessment) -> Int {
        assessment.domains.reduce(0) { total, domain in
            total + domain.answers.filter { _, value in
                if case .none = value { return false }
                return true
            }.count
        }
    }
    
    private func totalRequiredQuestions(_ assessment: Assessment) -> Int {
        // TODO: Get from questionnaire schema
        return 92  // Placeholder
    }
    
    // MARK: - File I/O
    
    private func writeJSON(_ object: [String: Any], to url: URL) async throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        
        // Atomic write: write to temp, then move
        let tempURL = url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).tmp")
        try data.write(to: tempURL, options: .atomic)
        
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: url)
    }
}

// MARK: - Extensions for JSON Conversion

extension SubstanceAssessment {
    func toJSON() -> [String: Any] {
        [
            "substance": substance,
            "frequency": frequency.rawValue,
            "lastUse": lastUse,
            "route": route
        ]
    }
}

extension ImpactGridAnswer {
    func toJSON() -> [String: Any] {
        [
            "impacts": impacts.map { area, level in
                [area: level.rawValue]
            }
        ]
    }
}
```

**Tests**:
```swift
// StorageExporterTests.swift
class StorageExporterTests: XCTestCase {
    
    func testExportCreatesCorrectStructure() async throws {
        let assessment = createTestAssessment()
        let exporter = StorageExporter()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        let exportedDir = try await exporter.export(assessment: assessment, to: tempDir)
        
        // Verify directory structure
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportedDir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportedDir.appendingPathComponent("header.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportedDir.appendingPathComponent("answers.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportedDir.appendingPathComponent("computed.json").path))
    }
    
    func testAnswersUseFieldPathNotation() async throws {
        let assessment = createTestAssessment()
        assessment.domains[0].answers = [
            "q1_alcohol": .single(.string("daily")),
            "q2_last_use": .text("2025-11-12")
        ]
        
        let exporter = StorageExporter()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let exportedDir = try await exporter.export(assessment: assessment, to: tempDir)
        
        let answersURL = exportedDir.appendingPathComponent("answers.json")
        let data = try Data(contentsOf: answersURL)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let answers = json["answers"] as! [String: Any]
        
        // Verify field_path notation
        XCTAssertNotNil(answers["d1.q1_alcohol"])
        XCTAssertNotNil(answers["d1.q2_last_use"])
    }
}
```

---

### Task 2: Create PDFExporter (4-5 hours)

**File**: `ios/ASAMAssessment/ASAMAssessment/Services/PDFExporter.swift`

**Responsibilities**:
- Load PDF template from assets/
- Fill form fields from exported answers.json
- Add signature image
- Save to artifacts/ folder
- Create frozen bundle snapshot

**Dependencies**:
- PDF template: `assets/ASAM_TreatmentPlan_Template.pdf`
- Signature image: `assets/sample_signature.png`
- Field mapping: `FORM_FIELD_MAP.json`

**Code Skeleton**:
```swift
import PDFKit
import UIKit

class PDFExporter {
    
    private let formFieldMap: [String: String]  // field_path → PDF field name
    
    init() throws {
        // Load field mapping
        guard let mapURL = Bundle.main.url(forResource: "FORM_FIELD_MAP", withExtension: "json"),
              let mapData = try? Data(contentsOf: mapURL),
              let map = try? JSONDecoder().decode([String: String].self, from: mapData) else {
            throw PDFExportError.missingFieldMap
        }
        self.formFieldMap = map
    }
    
    func export(
        assessmentDir: URL,
        templateURL: URL,
        signatureURL: URL?,
        outputURL: URL
    ) async throws {
        // Load answers
        let answersURL = assessmentDir.appendingPathComponent("answers.json")
        let answersData = try Data(contentsOf: answersURL)
        let answersJSON = try JSONSerialization.jsonObject(with: answersData) as! [String: Any]
        let answers = answersJSON["answers"] as! [String: Any]
        
        // Load template
        guard let template = PDFDocument(url: templateURL) else {
            throw PDFExportError.invalidTemplate
        }
        
        // Fill form fields
        for (fieldPath, value) in answers {
            guard let pdfFieldName = formFieldMap[fieldPath] else {
                continue  // Skip unmapped fields
            }
            
            fillFormField(in: template, fieldName: pdfFieldName, value: value)
        }
        
        // Add signature if provided
        if let signatureURL = signatureURL,
           let signatureImage = UIImage(contentsOfFile: signatureURL.path) {
            addSignature(to: template, image: signatureImage)
        }
        
        // Save filled PDF
        template.write(to: outputURL)
        
        // Create frozen bundle
        try await createFrozenBundle(assessmentDir: assessmentDir, pdfURL: outputURL)
    }
    
    private func fillFormField(in document: PDFDocument, fieldName: String, value: Any) {
        // Find annotation with matching field name
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            for annotation in page.annotations {
                if annotation.fieldName == fieldName {
                    // Set annotation value based on type
                    if let widget = annotation as? PDFAnnotation {
                        widget.setValue(String(describing: value), forAnnotationKey: .widgetValue)
                    }
                }
            }
        }
    }
    
    private func addSignature(to document: PDFDocument, image: UIImage) {
        // Find signature field (usually last page)
        guard let lastPage = document.page(at: document.pageCount - 1) else { return }
        
        // Create image annotation
        let bounds = CGRect(x: 50, y: 50, width: 200, height: 100)  // TODO: Get from template
        let imageAnnotation = PDFAnnotation(bounds: bounds, forType: .stamp, withProperties: nil)
        imageAnnotation.contents = "Signature"
        
        // Add image (requires converting to PDF)
        // TODO: Implement image → PDF conversion
        
        lastPage.addAnnotation(imageAnnotation)
    }
    
    private func createFrozenBundle(assessmentDir: URL, pdfURL: URL) async throws {
        let bundleURL = assessmentDir
            .appendingPathComponent("artifacts")
            .appendingPathComponent("\(assessmentDir.lastPathComponent)_bundle.json")
        
        // Create artifacts directory
        try FileManager.default.createDirectory(
            at: bundleURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        // Read all JSON files
        let header = try Data(contentsOf: assessmentDir.appendingPathComponent("header.json"))
        let answers = try Data(contentsOf: assessmentDir.appendingPathComponent("answers.json"))
        let computed = try Data(contentsOf: assessmentDir.appendingPathComponent("computed.json"))
        
        // Create frozen snapshot
        let bundle: [String: Any] = [
            "version": 1,
            "frozenAt": ISO8601DateFormatter().string(from: Date()),
            "header": try JSONSerialization.jsonObject(with: header),
            "answers": try JSONSerialization.jsonObject(with: answers),
            "computed": try JSONSerialization.jsonObject(with: computed),
            "pdfPath": pdfURL.lastPathComponent
        ]
        
        let bundleData = try JSONSerialization.data(withJSONObject: bundle, options: .prettyPrinted)
        try bundleData.write(to: bundleURL)
    }
}

enum PDFExportError: Error {
    case missingFieldMap
    case invalidTemplate
    case missingAnswers
    case exportFailed(String)
}
```

---

### Task 3: Wire Up to UI (2-3 hours)

**Files**:
- `ios/ASAMAssessment/ASAMAssessment/Views/AssessmentDetailView.swift`
- `ios/ASAMAssessment/ASAMAssessment/Views/ExportProgressView.swift`

**Changes**:
```swift
// Add to AssessmentDetailView
struct AssessmentDetailView: View {
    @State private var showExportSheet = false
    @State private var exportedPDFURL: URL?
    
    var body: some View {
        // ... existing view code ...
        
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Export PDF") {
                    showExportSheet = true
                }
                .disabled(assessment.status != .complete)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(assessment: assessment) { pdfURL in
                exportedPDFURL = pdfURL
            }
        }
        .sheet(item: $exportedPDFURL) { url in
            PDFViewer(url: url)
        }
    }
}

struct ExportSheet: View {
    let assessment: Assessment
    let onExport: (URL) -> Void
    
    @State private var isExporting = false
    @State private var progress: Double = 0
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Assessment PDF")
                .font(.headline)
            
            if isExporting {
                ProgressView(value: progress)
                Text("Exporting...")
            } else if let error = error {
                Text("Export failed: \(error.localizedDescription)")
                    .foregroundColor(.red)
                Button("Retry") {
                    Task { await performExport() }
                }
            } else {
                Button("Export") {
                    Task { await performExport() }
                }
            }
        }
        .padding()
    }
    
    private func performExport() async {
        isExporting = true
        progress = 0
        
        do {
            // Export to files
            progress = 0.3
            let exporter = StorageExporter()
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let assessmentDir = try await exporter.export(assessment: assessment, to: documentsURL)
            
            // Generate PDF
            progress = 0.6
            let pdfExporter = try PDFExporter()
            let templateURL = Bundle.main.url(forResource: "ASAM_TreatmentPlan_Template", withExtension: "pdf")!
            let signatureURL = Bundle.main.url(forResource: "sample_signature", withExtension: "png")
            
            let pdfURL = assessmentDir
                .appendingPathComponent("artifacts")
                .appendingPathComponent("asam_\(assessment.id.uuidString.prefix(8))_v1.pdf")
            
            try await pdfExporter.export(
                assessmentDir: assessmentDir,
                templateURL: templateURL,
                signatureURL: signatureURL,
                outputURL: pdfURL
            )
            
            progress = 1.0
            onExport(pdfURL)
            
        } catch {
            self.error = error
        }
        
        isExporting = false
    }
}
```

---

### Task 4: Testing (1-2 hours)

**Test Cases**:

1. **Export Structure**
   - ✅ Creates assessments/<id>/ directory
   - ✅ Writes header.json with correct schema
   - ✅ Writes answers.json with field_path keys
   - ✅ Writes computed.json with severity/progress
   - ✅ Sets file protection attributes

2. **PDF Generation**
   - ✅ Loads template successfully
   - ✅ Fills form fields from answers
   - ✅ Adds signature image
   - ✅ Saves to artifacts/ folder
   - ✅ Creates frozen bundle.json

3. **UI Integration**
   - ✅ Export button disabled for incomplete assessments
   - ✅ Shows progress during export
   - ✅ Displays exported PDF
   - ✅ Handles errors gracefully

---

## Acceptance Criteria

- [ ] Can export any Assessment to file-based format
- [ ] Exported files match proposed schema exactly
- [ ] PDF generation works with sample data
- [ ] UI shows export progress and results
- [ ] All tests passing
- [ ] No breaking changes to existing persistence
- [ ] Documentation updated

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| PDF template missing | Use placeholder, add TODO |
| Field mapping incomplete | Export all fields, map subset |
| Performance on large assessments | Async/await, show progress |
| File I/O errors | Comprehensive error handling |

---

## Next Steps

1. Review this plan with team
2. Assign tasks to developer(s)
3. Create feature branch: `feature/storage-export`
4. Implement Task 1-4 in order
5. Code review before merge
6. Test on device with real assessment data
7. Demo PDF export to stakeholders
