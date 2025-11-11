//
//  ExportPreflightTests.swift
//  ASAMAssessmentTests
//
//  Tests for T-0028: Verify export blocking when rules degraded
//

import XCTest
@testable import ASAMAssessment

final class ExportPreflightTests: XCTestCase {

    // MARK: - Export Preflight Tests

    func testExportPreflight_RulesUnavailable_BlocksExport() {
        // Given: Assessment complete but rules unavailable
        var assessment = Assessment()
        assessment.locRecommendation = LOCRecommendation(
            code: "2.1",
            name: "IOP",
            confidence: 0.9,
            reasoning: ["Test"]
        )

        // Mark all gates as passed
        for i in 0..<assessment.validationGates.count {
            assessment.validationGates[i].isPassed = true
        }

        // Rules service degraded
        let rulesService = RulesServiceWrapper()
        rulesService.isAvailable = false
        rulesService.errorMessage = "Rules files missing"

        // When: Check preflight
        let result = ExportPreflight.check(
            assessment: assessment,
            rulesService: rulesService,
            provenance: nil,
            complianceMode: .internal_neutral,
            templatePath: nil
        )

        // Then: Export blocked
        switch result {
        case .success:
            XCTFail("Expected export to be blocked when rules unavailable")
        case .failure(let error):
            if case .rulesUnavailable(let message) = error {
                XCTAssertEqual(message, "Rules files missing")
            } else {
                XCTFail("Expected rulesUnavailable error, got: \(error)")
            }
        }
    }

    func testExportPreflight_AssessmentIncomplete_BlocksExport() {
        // Given: Rules available but assessment incomplete
        var assessment = Assessment()
        // Don't set locRecommendation or pass gates

        let rulesService = RulesServiceWrapper()
        rulesService.isAvailable = true

        // When: Check preflight
        let result = ExportPreflight.check(
            assessment: assessment,
            rulesService: rulesService,
            provenance: nil,
            complianceMode: .internal_neutral,
            templatePath: nil
        )

        // Then: Export blocked
        switch result {
        case .success:
            XCTFail("Expected export to be blocked for incomplete assessment")
        case .failure(let error):
            if case .assessmentIncomplete = error {
                // Expected
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected assessmentIncomplete error, got: \(error)")
            }
        }
    }

    func testExportPreflight_AllValid_AllowsExport() {
        // Given: Everything valid
        var assessment = Assessment()
        assessment.locRecommendation = LOCRecommendation(
            code: "2.1",
            name: "IOP",
            confidence: 0.9,
            reasoning: ["Test"]
        )

        // Mark all gates passed
        for i in 0..<assessment.validationGates.count {
            assessment.validationGates[i].isPassed = true
        }

        let rulesService = RulesServiceWrapper()
        rulesService.isAvailable = true

        // When: Check preflight
        let result = ExportPreflight.check(
            assessment: assessment,
            rulesService: rulesService,
            provenance: nil,
            complianceMode: .internal_neutral,
            templatePath: nil
        )

        // Then: Export allowed
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure(let error):
            XCTFail("Expected export to succeed, got error: \(error)")
        }
    }

    func testExportPreflight_ValidationGateFailed_BlocksExport() {
        // Given: One validation gate failed
        var assessment = Assessment()
        assessment.locRecommendation = LOCRecommendation(
            code: "2.1",
            name: "IOP",
            confidence: 0.9,
            reasoning: ["Test"]
        )

        // Leave one gate unpassed
        for i in 0..<assessment.validationGates.count - 1 {
            assessment.validationGates[i].isPassed = true
        }
        assessment.validationGates[assessment.validationGates.count - 1].isPassed = false
        assessment.validationGates[assessment.validationGates.count - 1].errorMessage = "Not completed"

        let rulesService = RulesServiceWrapper()
        rulesService.isAvailable = true

        // When: Check preflight
        let result = ExportPreflight.check(
            assessment: assessment,
            rulesService: rulesService,
            provenance: nil,
            complianceMode: .internal_neutral,
            templatePath: nil
        )

        // Then: Export blocked
        switch result {
        case .success:
            XCTFail("Expected export to be blocked with failed validation gate")
        case .failure(let error):
            if case .validationFailed(let errors) = error {
                XCTAssertFalse(errors.isEmpty)
            } else {
                XCTFail("Expected validationFailed error, got: \(error)")
            }
        }
    }

    func testCanExport_QuickCheck_MatchesFullCheck() {
        // Given: Various assessment states
        var assessment = Assessment()
        assessment.locRecommendation = LOCRecommendation(
            code: "2.1",
            name: "IOP",
            confidence: 0.9,
            reasoning: ["Test"]
        )

        for i in 0..<assessment.validationGates.count {
            assessment.validationGates[i].isPassed = true
        }

        let rulesService = RulesServiceWrapper()
        rulesService.isAvailable = true

        // When/Then: Quick check matches full check
        let canExport = ExportPreflight.canExport(
            assessment: assessment,
            rulesService: rulesService
        )

        let fullResult = ExportPreflight.check(
            assessment: assessment,
            rulesService: rulesService,
            provenance: nil,
            complianceMode: .internal_neutral,
            templatePath: nil
        )

        switch fullResult {
        case .success:
            XCTAssertTrue(canExport)
        case .failure:
            XCTAssertFalse(canExport)
        }
    }

    // MARK: - Performance Tests

    func testPreflightPerformance() {
        // Given: Valid assessment
        var assessment = Assessment()
        assessment.locRecommendation = LOCRecommendation(
            code: "2.1",
            name: "IOP",
            confidence: 0.9,
            reasoning: ["Test"]
        )

        for i in 0..<assessment.validationGates.count {
            assessment.validationGates[i].isPassed = true
        }

        let rulesService = RulesServiceWrapper()
        rulesService.isAvailable = true

        // When/Then: Measure performance
        measure {
            _ = ExportPreflight.check(
                assessment: assessment,
                rulesService: rulesService,
                provenance: nil,
                complianceMode: .internal_neutral,
                templatePath: nil
            )
        }
    }
}
