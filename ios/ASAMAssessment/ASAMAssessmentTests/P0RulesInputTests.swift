//
//  P0RulesInputTests.swift
//  ASAMAssessmentTests
//
//  Tests for T-0025 and T-0026: Verify substance context and clinical flags
//  are correctly passed to rules engine and affect recommendations
//

import XCTest
@testable import ASAMAssessment

final class P0RulesInputTests: XCTestCase {

    // MARK: - Domain 1 Context Tests (T-0025)

    func testD1Context_OpioidWithdrawal_GeneratesCorrectJSON() {
        // Given: Assessment with opioid substance
        var assessment = Assessment()
        assessment.substances = [
            SubstanceRow(
                substanceGroup: .opioid,
                lastUseHours: 12,
                cows: 15,
                route: [.iv, .oral]
            )
        ]

        // When: Extract d1Context
        let context = assessment.d1Context()

        // Then: Verify JSON structure
        XCTAssertNotNil(context["substances"])

        if let substances = context["substances"] as? [[String: Any]],
           let firstSubstance = substances.first {
            XCTAssertEqual(firstSubstance["substance_group"] as? String, "opioid")
            XCTAssertEqual(firstSubstance["last_use_hours"] as? Int, 12)
            XCTAssertEqual(firstSubstance["cows"] as? Int, 15)

            if let routes = firstSubstance["route"] as? [String] {
                XCTAssertTrue(routes.contains("IV"))
                XCTAssertTrue(routes.contains("oral"))
            } else {
                XCTFail("Route array not found in substance context")
            }
        } else {
            XCTFail("Failed to extract substance from context")
        }
    }

    func testD1Context_MultipleSubstances_AllIncluded() {
        // Given: Assessment with multiple substances
        var assessment = Assessment()
        assessment.substances = [
            SubstanceRow(substanceGroup: .opioid, lastUseHours: 12, cows: 15, route: [.iv]),
            SubstanceRow(substanceGroup: .alcohol, lastUseHours: 48, ciwa: 18, route: [.oral])
        ]

        // When: Extract d1Context
        let context = assessment.d1Context()

        // Then: Both substances present
        if let substances = context["substances"] as? [[String: Any]] {
            XCTAssertEqual(substances.count, 2)

            let groups = substances.compactMap { $0["substance_group"] as? String }
            XCTAssertTrue(groups.contains("opioid"))
            XCTAssertTrue(groups.contains("alcohol"))
        } else {
            XCTFail("Expected array of substances")
        }
    }

    func testD1Context_EmptySubstances_ReturnsEmptyArray() {
        // Given: Assessment with no substances
        let assessment = Assessment()

        // When: Extract d1Context
        let context = assessment.d1Context()

        // Then: Empty array
        if let substances = context["substances"] as? [[String: Any]] {
            XCTAssertEqual(substances.count, 0)
        } else {
            XCTFail("Expected empty array")
        }
    }

    // MARK: - Clinical Flags Tests (T-0026)

    func testFlags_AllFalse_GeneratesCorrectDict() {
        // Given: Assessment with all flags false
        var assessment = Assessment()
        assessment.vitalsUnstable = false
        assessment.pregnant = false
        assessment.noWithdrawalSigns = false
        assessment.acutePsych = false

        // When: Extract flags
        let flags = assessment.flags()

        // Then: All false
        XCTAssertEqual(flags["vitals_unstable"], false)
        XCTAssertEqual(flags["pregnant"], false)
        XCTAssertEqual(flags["no_withdrawal_signs"], false)
        XCTAssertEqual(flags["acute_psych"], false)
    }

    func testFlags_SomeFlagsTrue_GeneratesCorrectDict() {
        // Given: Assessment with some flags true
        var assessment = Assessment()
        assessment.vitalsUnstable = true
        assessment.pregnant = false
        assessment.noWithdrawalSigns = false
        assessment.acutePsych = true

        // When: Extract flags
        let flags = assessment.flags()

        // Then: Correct values
        XCTAssertEqual(flags["vitals_unstable"], true)
        XCTAssertEqual(flags["pregnant"], false)
        XCTAssertEqual(flags["no_withdrawal_signs"], false)
        XCTAssertEqual(flags["acute_psych"], true)
    }

    // MARK: - Integration Tests: Rules Engine with Real Data

    func testRulesEngine_OpioidWithdrawal_YieldsCorrectRecommendation() {
        // Given: Opioid withdrawal case (COWS 15, last use 12h)
        var assessment = Assessment()

        // Domain 1: Acute intoxication/withdrawal
        assessment.domains[0].severity = 3  // Moderate-severe

        // Add substance context
        assessment.substances = [
            SubstanceRow(
                substanceGroup: .opioid,
                lastUseHours: 12,
                cows: 15,  // Moderate withdrawal
                route: [.iv]
            )
        ]

        // Clinical flags
        assessment.vitalsUnstable = false
        assessment.pregnant = false
        assessment.noWithdrawalSigns = false
        assessment.acutePsych = false

        // When: Evaluate with rules service
        let rulesService = RulesServiceWrapper()

        // Wait for rules to load
        let expectation = XCTestExpectation(description: "Rules loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard rulesService.isAvailable else {
            XCTFail("Rules engine not available")
            return
        }

        let recommendation = rulesService.calculateLOC(for: assessment)

        // Then: Should recommend WM-capable level
        // Expected: 3.2-WM, 3.7-WM, or 4.0-WM based on COWS 15
        print("Recommendation: \(recommendation.name)")
        print("Reasoning: \(recommendation.reasoning.joined(separator: "\n"))")

        // Verify WM is in reasoning
        let reasoning = recommendation.reasoning.joined(separator: " ")
        XCTAssertTrue(
            reasoning.contains("WM") || reasoning.contains("withdrawal"),
            "Expected WM or withdrawal in reasoning for opioid case with COWS 15"
        )
    }

    func testRulesEngine_NoWithdrawalSigns_YieldsLowerLevel() {
        // Given: Assessment with no_withdrawal_signs = true
        var assessment = Assessment()

        // Domain 1: Minimal withdrawal
        assessment.domains[0].severity = 1

        // Substance but no withdrawal signs
        assessment.substances = [
            SubstanceRow(
                substanceGroup: .alcohol,
                lastUseHours: 72,  // 3 days ago
                route: [.oral]
            )
        ]

        // Flag: No withdrawal signs
        assessment.vitalsUnstable = false
        assessment.pregnant = false
        assessment.noWithdrawalSigns = true  // KEY FLAG
        assessment.acutePsych = false

        // When: Evaluate
        let rulesService = RulesServiceWrapper()

        let expectation = XCTestExpectation(description: "Rules loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard rulesService.isAvailable else {
            XCTFail("Rules engine not available")
            return
        }

        let recommendation = rulesService.calculateLOC(for: assessment)

        // Then: Should yield lower LOC (not WM)
        print("Recommendation: \(recommendation.name)")
        XCTAssertFalse(
            recommendation.name.contains("3.7") || recommendation.name.contains("4.0"),
            "Expected lower level when no_withdrawal_signs = true"
        )
    }

    func testRulesEngine_VitalsUnstable_EscalatesLevel() {
        // Given: Assessment with unstable vitals
        var assessment = Assessment()

        // Domain 1 & 2: Withdrawal + biomedical
        assessment.domains[0].severity = 2
        assessment.domains[1].severity = 3  // Biomedical complications

        // Substance
        assessment.substances = [
            SubstanceRow(
                substanceGroup: .alcohol,
                lastUseHours: 24,
                ciwa: 20,  // Severe withdrawal
                route: [.oral]
            )
        ]

        // Flag: Vitals unstable
        assessment.vitalsUnstable = true  // KEY FLAG
        assessment.pregnant = false
        assessment.noWithdrawalSigns = false
        assessment.acutePsych = false

        // When: Evaluate
        let rulesService = RulesServiceWrapper()

        let expectation = XCTestExpectation(description: "Rules loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        guard rulesService.isAvailable else {
            XCTFail("Rules engine not available")
            return
        }

        let recommendation = rulesService.calculateLOC(for: assessment)

        // Then: Should escalate to medically monitored (3.7) or managed (4.0)
        print("Recommendation: \(recommendation.name)")
        let reasoning = recommendation.reasoning.joined(separator: " ")
        XCTAssertTrue(
            recommendation.name.contains("3.7") || recommendation.name.contains("4.0") || reasoning.contains("medical"),
            "Expected medical monitoring when vitals_unstable = true and CIWA 20"
        )
    }

    // MARK: - Performance Tests

    func testD1Context_Performance() {
        // Given: Assessment with many substances
        var assessment = Assessment()
        assessment.substances = (0..<10).map { _ in
            SubstanceRow(
                substanceGroup: .opioid,
                lastUseHours: 12,
                cows: 15,
                route: [.iv, .oral, .nasal]
            )
        }

        // When/Then: Measure performance
        measure {
            _ = assessment.d1Context()
        }
    }
}
