//
//  PersistenceTests.swift
//  ASAMAssessmentTests
//
//  Created by Agent on 2025-11-11
//  Tests for AssessmentStore persistence behavior
//

import XCTest
@testable import ASAMAssessment

@MainActor
final class PersistenceTests: XCTestCase {
    
    var store: AssessmentStore!
    let testUserDefaultsSuite = "com.asam.test"
    
    override func setUp() async throws {
        // Use a separate UserDefaults suite for testing
        UserDefaults.standard.removePersistentDomain(forName: testUserDefaultsSuite)
        store = AssessmentStore()
        
        // Clear any existing test data
        UserDefaults.standard.removeObject(forKey: "stored_assessments")
        UserDefaults.standard.removeObject(forKey: "current_assessment_id")
        UserDefaults.standard.synchronize()
        
        // Reinitialize store after clearing
        store = AssessmentStore()
    }
    
    override func tearDown() async throws {
        // Clean up test data
        UserDefaults.standard.removeObject(forKey: "stored_assessments")
        UserDefaults.standard.removeObject(forKey: "current_assessment_id")
        UserDefaults.standard.synchronize()
        store = nil
    }
    
    // MARK: - Basic Persistence Tests
    
    func testAssessmentCreationPersists() throws {
        // Given
        let initialCount = store.assessments.count
        
        // When
        let newAssessment = store.createAssessment()
        
        // Then
        XCTAssertEqual(store.assessments.count, initialCount + 1, "Assessment should be added to store")
        XCTAssertEqual(store.currentAssessment?.id, newAssessment.id, "Current assessment should be set")
        
        // Verify persistence by creating new store
        let reloadedStore = AssessmentStore()
        XCTAssertEqual(reloadedStore.assessments.count, initialCount + 1, "Assessment should persist across store instances")
        XCTAssertEqual(reloadedStore.currentAssessment?.id, newAssessment.id, "Current assessment should persist")
    }
    
    func testDomainAnswersPersist() throws {
        // Given
        let assessment = store.createAssessment()
        var updatedAssessment = assessment
        
        // When - Add answers to first domain
        guard !updatedAssessment.domains.isEmpty else {
            XCTFail("Assessment should have domains")
            return
        }
        
        var domain = updatedAssessment.domains[0]
        domain.answers = [
            "question1": .text("Test answer"),
            "question2": .number(5),
            "question3": .bool(true)
        ]
        updatedAssessment.domains[0] = domain
        store.updateAssessment(updatedAssessment)
        
        // Then - Verify answers persist
        let reloadedStore = AssessmentStore()
        guard let reloadedAssessment = reloadedStore.assessments.first(where: { $0.id == assessment.id }) else {
            XCTFail("Assessment should persist")
            return
        }
        
        XCTAssertEqual(reloadedAssessment.domains[0].answers.count, 3, "Domain answers should persist")
        XCTAssertNotNil(reloadedAssessment.domains[0].answers["question1"], "Individual answer should persist")
    }
    
    func testCurrentAssessmentPersists() throws {
        // Given
        let assessment1 = store.createAssessment()
        let assessment2 = store.createAssessment()
        
        // When - Set second assessment as current
        store.currentAssessment = assessment2
        
        // Then - Verify current assessment persists
        let reloadedStore = AssessmentStore()
        XCTAssertEqual(reloadedStore.currentAssessment?.id, assessment2.id, "Current assessment should persist correctly")
        XCTAssertNotEqual(reloadedStore.currentAssessment?.id, assessment1.id, "Should not persist wrong assessment")
    }
    
    func testMultipleAssessmentsPersist() throws {
        // Given
        let count = 5
        var createdIds: [UUID] = []
        
        // When - Create multiple assessments
        for _ in 0..<count {
            let assessment = store.createAssessment()
            createdIds.append(assessment.id)
        }
        
        // Then - All should persist
        let reloadedStore = AssessmentStore()
        XCTAssertEqual(reloadedStore.assessments.count, count, "All assessments should persist")
        
        for id in createdIds {
            XCTAssertNotNil(reloadedStore.assessments.first(where: { $0.id == id }), "Assessment \(id) should persist")
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyStorePersistence() throws {
        // Given - Fresh store with no assessments
        let emptyStore = AssessmentStore()
        
        // Then
        XCTAssertTrue(emptyStore.assessments.isEmpty, "Empty store should have no assessments")
        XCTAssertNil(emptyStore.currentAssessment, "Empty store should have no current assessment")
    }
    
    func testAssessmentUpdatePersists() throws {
        // Given
        let assessment = store.createAssessment()
        var updatedAssessment = assessment
        
        // When - Update assessment properties
        updatedAssessment.status = .inProgress
        updatedAssessment.assessorId = "test-assessor-123"
        updatedAssessment.vitalsUnstable = true
        store.updateAssessment(updatedAssessment)
        
        // Then - Changes should persist
        let reloadedStore = AssessmentStore()
        guard let reloadedAssessment = reloadedStore.assessments.first(where: { $0.id == assessment.id }) else {
            XCTFail("Updated assessment should persist")
            return
        }
        
        XCTAssertEqual(reloadedAssessment.status, .inProgress, "Status update should persist")
        XCTAssertEqual(reloadedAssessment.assessorId, "test-assessor-123", "AssessorId update should persist")
        XCTAssertTrue(reloadedAssessment.vitalsUnstable, "Flags update should persist")
    }
    
    func testDomainCompletionPersists() throws {
        // Given
        let assessment = store.createAssessment()
        var updatedAssessment = assessment
        
        // When - Mark domain as complete
        updatedAssessment.domains[0].isComplete = true
        updatedAssessment.domains[0].severity = 3
        store.updateAssessment(updatedAssessment)
        
        // Then - Completion status should persist
        let reloadedStore = AssessmentStore()
        guard let reloadedAssessment = reloadedStore.assessments.first(where: { $0.id == assessment.id }) else {
            XCTFail("Assessment should persist")
            return
        }
        
        XCTAssertTrue(reloadedAssessment.domains[0].isComplete, "Domain completion should persist")
        XCTAssertEqual(reloadedAssessment.domains[0].severity, 3, "Domain severity should persist")
    }
    
    func testAssessmentDeletionPersists() throws {
        // Given
        let assessment1 = store.createAssessment()
        let assessment2 = store.createAssessment()
        
        // When - Delete first assessment
        store.deleteAssessment(assessment1)
        
        // Then - Deletion should persist
        let reloadedStore = AssessmentStore()
        XCTAssertEqual(reloadedStore.assessments.count, 1, "Should have 1 assessment after deletion")
        XCTAssertNil(reloadedStore.assessments.first(where: { $0.id == assessment1.id }), "Deleted assessment should not persist")
        XCTAssertNotNil(reloadedStore.assessments.first(where: { $0.id == assessment2.id }), "Non-deleted assessment should persist")
    }
    
    // MARK: - Data Integrity Tests
    
    func testAnswerTypesPersist() throws {
        // Given
        let assessment = store.createAssessment()
        var updatedAssessment = assessment
        
        // When - Add all types of answers
        var domain = updatedAssessment.domains[0]
        domain.answers = [
            "text_q": .text("Sample text"),
            "number_q": .number(42),
            "bool_q": .bool(true),
            "single_q": .single(.string("option1")),
            "multi_q": .multi(Set(["opt1", "opt2", "opt3"])),
            "none_q": .none
        ]
        updatedAssessment.domains[0] = domain
        store.updateAssessment(updatedAssessment)
        
        // Then - All answer types should persist correctly
        let reloadedStore = AssessmentStore()
        guard let reloadedAssessment = reloadedStore.assessments.first(where: { $0.id == assessment.id }) else {
            XCTFail("Assessment should persist")
            return
        }
        
        let persistedAnswers = reloadedAssessment.domains[0].answers
        
        if case .text(let text) = persistedAnswers["text_q"] {
            XCTAssertEqual(text, "Sample text", "Text answer should persist")
        } else {
            XCTFail("Text answer type not preserved")
        }
        
        if case .number(let num) = persistedAnswers["number_q"] {
            XCTAssertEqual(num, 42, "Number answer should persist")
        } else {
            XCTFail("Number answer type not preserved")
        }
        
        if case .bool(let bool) = persistedAnswers["bool_q"] {
            XCTAssertTrue(bool, "Bool answer should persist")
        } else {
            XCTFail("Bool answer type not preserved")
        }
        
        if case .multi(let values) = persistedAnswers["multi_q"] {
            XCTAssertEqual(values.count, 3, "Multi-select answer should persist all values")
        } else {
            XCTFail("Multi-select answer type not preserved")
        }
    }
    
    func testSubstanceDataPersists() throws {
        // Given
        let assessment = store.createAssessment()
        var updatedAssessment = assessment
        
        // When - Add substance data
        let substance = SubstanceRow(
            substance: "Alcohol",
            neverUsed: false,
            lastUseDate: Date(),
            frequency30Days: 15,
            routes: ["oral"]
        )
        updatedAssessment.substances = [substance]
        store.updateAssessment(updatedAssessment)
        
        // Then - Substance data should persist
        let reloadedStore = AssessmentStore()
        guard let reloadedAssessment = reloadedStore.assessments.first(where: { $0.id == assessment.id }) else {
            XCTFail("Assessment should persist")
            return
        }
        
        XCTAssertEqual(reloadedAssessment.substances.count, 1, "Substance data should persist")
        XCTAssertEqual(reloadedAssessment.substances[0].substance, "Alcohol", "Substance name should persist")
        XCTAssertEqual(reloadedAssessment.substances[0].frequency30Days, 15, "Substance frequency should persist")
    }
    
    // MARK: - Progress Tracking Tests
    
    func testProgressDataPersists() throws {
        // Given
        let assessment = store.createAssessment()
        var updatedAssessment = assessment
        
        // When - Add answers to multiple domains
        for (index, _) in updatedAssessment.domains.enumerated() {
            var domain = updatedAssessment.domains[index]
            domain.answers = [
                "q\(index)_1": .text("Answer 1"),
                "q\(index)_2": .text("Answer 2")
            ]
            domain.isComplete = (index % 2 == 0) // Alternate completion
            domain.severity = index % 5 // Vary severity
            updatedAssessment.domains[index] = domain
        }
        store.updateAssessment(updatedAssessment)
        
        // Then - Progress state should persist accurately
        let reloadedStore = AssessmentStore()
        guard let reloadedAssessment = reloadedStore.assessments.first(where: { $0.id == assessment.id }) else {
            XCTFail("Assessment should persist")
            return
        }
        
        for (index, domain) in reloadedAssessment.domains.enumerated() {
            XCTAssertEqual(domain.answers.count, 2, "Domain \(index + 1) should have 2 answers")
            XCTAssertEqual(domain.isComplete, (index % 2 == 0), "Domain \(index + 1) completion should persist")
            XCTAssertEqual(domain.severity, index % 5, "Domain \(index + 1) severity should persist")
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentUpdates() async throws {
        // Given
        let assessment = store.createAssessment()
        
        // When - Perform multiple updates concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask { @MainActor in
                    var updated = assessment
                    var domain = updated.domains[0]
                    domain.answers["concurrent_\(i)"] = .number(Double(i))
                    updated.domains[0] = domain
                    self.store.updateAssessment(updated)
                }
            }
        }
        
        // Then - Final state should be consistent
        let reloadedStore = AssessmentStore()
        guard let reloadedAssessment = reloadedStore.assessments.first(where: { $0.id == assessment.id }) else {
            XCTFail("Assessment should persist")
            return
        }
        
        // At least some updates should persist
        XCTAssertFalse(reloadedAssessment.domains[0].answers.isEmpty, "Some concurrent updates should persist")
    }
    
    // MARK: - Performance Tests
    
    func testLargeDataSetPersistence() throws {
        // Given - Assessment with many answers
        let assessment = store.createAssessment()
        var updatedAssessment = assessment
        
        // When - Add 100 answers per domain
        for (domainIndex, _) in updatedAssessment.domains.enumerated() {
            var domain = updatedAssessment.domains[domainIndex]
            for i in 0..<100 {
                domain.answers["bulk_q_\(i)"] = .text("Answer \(i)")
            }
            updatedAssessment.domains[domainIndex] = domain
        }
        
        let startTime = Date()
        store.updateAssessment(updatedAssessment)
        let saveTime = Date().timeIntervalSince(startTime)
        
        // Then - Should save in reasonable time (< 1 second)
        XCTAssertLessThan(saveTime, 1.0, "Large dataset should save in under 1 second")
        
        // Verify data persisted correctly
        let reloadStartTime = Date()
        let reloadedStore = AssessmentStore()
        let loadTime = Date().timeIntervalSince(reloadStartTime)
        
        XCTAssertLessThan(loadTime, 1.0, "Large dataset should load in under 1 second")
        
        guard let reloadedAssessment = reloadedStore.assessments.first(where: { $0.id == assessment.id }) else {
            XCTFail("Assessment should persist")
            return
        }
        
        for domain in reloadedAssessment.domains {
            XCTAssertEqual(domain.answers.count, 100, "All 100 answers should persist for each domain")
        }
    }
}
