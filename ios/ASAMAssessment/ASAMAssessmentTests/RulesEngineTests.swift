//
//  RulesEngineTests.swift
//  ASAMAssessmentTests
//
//  Tests rules engine against 12 golden test fixtures
//  Validates WM indication, LOC recommendation, and guard logic
//

import XCTest
@testable import ASAMAssessment

final class RulesEngineTests: XCTestCase {

    func testFixturesPass() throws {
        // Load rules engine with bundled rules
        let bundle = Bundle(for: Self.self)
        let rulesService = try RulesService(
            bundle: bundle,
            wmRulesFile: "rules/wm_ladder",
            locRulesFile: "rules/loc_indication.guard",
            operatorsFile: "rules/operators"
        )

        // Find all fixture files
        guard let fixturesURL = bundle.url(forResource: "agent_ops/tests/fixtures", withExtension: nil) else {
            XCTFail("Fixtures directory not found in test bundle")
            return
        }

        let fileManager = FileManager.default
        let fixtureFiles = try fileManager.contentsOfDirectory(at: fixturesURL, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("case_") && $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        XCTAssertGreaterThan(fixtureFiles.count, 0, "No fixture files found")

        // Test each fixture
        for fixtureURL in fixtureFiles {
            let data = try Data(contentsOf: fixtureURL)
            let fixture = try JSONSerialization.jsonObject(with: data) as! [String: Any]

            let input = fixture["input"] as! [String: Any]
            let expected = fixture["expected"] as! [String: Any]

            let severities = input["severities"] as! [String: Int]
            let d1Context = input["d1"] as? [String: Any] ?? [:]
            let flags = input["flags"] as? [String: Bool] ?? [:]

            // Evaluate
            let result = rulesService.evaluate(
                severities: severities,
                d1Context: d1Context,
                flags: flags
            )

            // Extract expected values
            let expectedWM = expected["wm"] as! [String: Any]
            let expectedLOC = expected["loc"] as! [String: Any]

            let expectedWMIndication = expectedWM["indicated"] as! String
            let expectedWMCandidates = expectedWM["candidate_levels"] as! [String]
            let expectedLOCIndication = expectedLOC["indicated"] as! String

            // Verify WM indication
            XCTAssertEqual(
                result.wm.indication,
                expectedWMIndication,
                "WM indication mismatch in \(fixtureURL.lastPathComponent)"
            )

            // Verify WM candidate levels (order matters for guard logic)
            XCTAssertEqual(
                result.wm.candidateLevels,
                expectedWMCandidates,
                "WM candidates mismatch in \(fixtureURL.lastPathComponent)"
            )

            // Verify LOC recommendation
            XCTAssertEqual(
                result.loc.recommendation,
                expectedLOCIndication,
                "LOC recommendation mismatch in \(fixtureURL.lastPathComponent)"
            )

            print("✅ \(fixtureURL.lastPathComponent): WM=\(result.wm.indication) LOC=\(result.loc.recommendation)")
        }

        print("\n✅ All \(fixtureFiles.count) fixtures passed")
    }

    func testGuardLogicPreventsDoubleCount() throws {
        // Specific test for T-0022 guard logic
        // When WM indicates 3.7/4.0, LOC SHOULD ALSO escalate to 3.7/4.0
        // Guard prevents DOUBLE-COUNTING, not escalation itself

        let bundle = Bundle(for: Self.self)
        let rulesService = try RulesService(
            bundle: bundle,
            wmRulesFile: "rules/wm_ladder.json",
            locRulesFile: "rules/loc_indication.guard.json",
            operatorsFile: "rules/operators.json"
        )

        // Opioid acute withdrawal scenario (should trigger WM 3.7/4.0)
        let severities = ["A": 4, "B": 1, "C": 1, "D": 1, "E": 2, "F": 1]  // A-F keys
        let d1Context: [String: Any] = [
            "substances": [
                ["substance_group": "opioid", "last_use_hours": 12, "cows": 15]
            ]
        ]
        let flags: [String: Bool] = [:]

        let result = rulesService.evaluate(
            severities: severities,
            d1Context: d1Context,
            flags: flags
        )

        // WM should include 3.7 or 4.0
        XCTAssertTrue(
            result.wm.candidateLevels.contains("3.7") || result.wm.candidateLevels.contains("4.0"),
            "Expected WM to include 3.7 or 4.0 for acute opioid withdrawal"
        )

        // LOC should ALSO be 3.7 or 4.0 (escalation)
        XCTAssertTrue(
            ["3.7", "4.0"].contains(result.loc.recommendation),
            "LOC should escalate to 3.7/4.0 when WM indicates it"
        )

        // Verify it's the escalation rule (guard logic working)
        XCTAssertEqual(
            result.loc.ruleId,
            "loc_wm_escalation",
            "Should use loc_wm_escalation rule, not double-counting from base rules"
        )

        print("✅ Guard logic test passed: WM=\(result.wm.indication) LOC=\(result.loc.recommendation) via \(result.loc.ruleId ?? "nil")")
    }

    func testRulesServiceWrapperFallback() throws {
        // Test that wrapper handles missing files gracefully
        let wrapper = RulesServiceWrapper()

        // If rules failed to load, should still return safe default
        if !wrapper.isAvailable {
            let mockAssessment = Assessment()
            let recommendation = wrapper.calculateLOC(for: mockAssessment)

            XCTAssertEqual(recommendation.level, "2.1", "Fallback should return 2.1 (ASAM 4 standard)")
            XCTAssertEqual(recommendation.confidence, "low", "Fallback should have low confidence")
            XCTAssertTrue(
                recommendation.reasoning.contains("Rules engine unavailable"),
                "Fallback should explain why"
            )
        }
    }

    // MARK: - Production Hardening Tests

    func testRuleIdUniqueness() throws {
        let bundle = Bundle(for: Self.self)
        let rulesService = try RulesService(
            bundle: bundle,
            wmRulesPath: "rules/wm_ladder.json",
            locRulesPath: "rules/loc_indication.guard.json",
            operatorsPath: "rules/operators.json"
        )

        // Get all rule IDs from both engines
        let wmRules = rulesService.wmEngine.rules
        let locRules = rulesService.locEngine.rules

        // Check WM rule ID uniqueness
        let wmIds = wmRules.map { $0.ruleId }
        XCTAssertEqual(
            wmIds.count,
            Set(wmIds).count,
            "WM rule IDs must be unique. Found duplicates: \(wmIds.filter { id in wmIds.filter { $0 == id }.count > 1 })"
        )

        // Check LOC rule ID uniqueness
        let locIds = locRules.map { $0.ruleId }
        XCTAssertEqual(
            locIds.count,
            Set(locIds).count,
            "LOC rule IDs must be unique. Found duplicates: \(locIds.filter { id in locIds.filter { $0 == id }.count > 1 })"
        )

        print("✅ Rule ID uniqueness verified: \(wmIds.count) WM rules, \(locIds.count) LOC rules")
    }

    func testPrecedenceStrictlyDescending() throws {
        let bundle = Bundle(for: Self.self)
        let rulesService = try RulesService(
            bundle: bundle,
            wmRulesPath: "rules/wm_ladder.json",
            locRulesPath: "rules/loc_indication.guard.json",
            operatorsPath: "rules/operators.json"
        )

        // Check WM precedence
        let wmRules = rulesService.wmEngine.rules
        let wmPrecedences = wmRules.map { $0.precedence }

        XCTAssertEqual(
            wmPrecedences,
            wmPrecedences.sorted(by: >),
            "WM precedences must be strictly descending (highest first)"
        )

        XCTAssertEqual(
            wmPrecedences.count,
            Set(wmPrecedences).count,
            "WM precedences must be unique (no ties)"
        )

        // Check LOC precedence
        let locRules = rulesService.locEngine.rules
        let locPrecedences = locRules.map { $0.precedence }

        XCTAssertEqual(
            locPrecedences,
            locPrecedences.sorted(by: >),
            "LOC precedences must be strictly descending (highest first)"
        )

        XCTAssertEqual(
            locPrecedences.count,
            Set(locPrecedences).count,
            "LOC precedences must be unique (no ties)"
        )

        print("✅ Precedence ordering verified: WM [\(wmPrecedences.first ?? 0)...\(wmPrecedences.last ?? 0)], LOC [\(locPrecedences.first ?? 0)...\(locPrecedences.last ?? 0)]")
    }

    func testWMWithoutLOCEscalation() throws {
        // Test that LOC doesn't escalate when WM doesn't trigger it
        let bundle = Bundle(for: Self.self)
        let rulesService = try RulesService(
            bundle: bundle,
            wmRulesPath: "rules/wm_ladder.json",
            locRulesPath: "rules/loc_indication.guard.json",
            operatorsPath: "rules/operators.json"
        )

        // Scenario: Moderate Domain 5 elevation (E=3), rest low
        // Should suggest WM 2.1-2.7 range, but LOC should stay at 2.1 base
        let severities = ["A": 1, "B": 1, "C": 1, "D": 1, "E": 3, "F": 1]
        let d1Context: [String: Any] = [:]
        let flags: [String: Bool] = [:]

        let result = rulesService.evaluate(
            severities: severities,
            d1Context: d1Context,
            flags: flags
        )

        // WM might suggest 2.7 or higher
        print("ℹ️ WM indication: \(result.wm.indication)")

        // LOC should NOT escalate to 3.1+ without specific triggers
        XCTAssertFalse(
            ["3.1", "3.5", "3.7", "4.0"].contains(result.loc.recommendation),
            "LOC should not escalate to residential/inpatient without WM 3.7/4.0 or high D2/D3"
        )

        // Most likely 2.1 or 2.5
        XCTAssertTrue(
            ["2.1", "2.5"].contains(result.loc.recommendation),
            "LOC should be 2.1 or 2.5 for moderate E elevation alone"
        )

        print("✅ No spurious escalation: WM=\(result.wm.indication) LOC=\(result.loc.recommendation)")
    }

    func testResourceResolutionMainBundle() throws {
        // Verify rules can load from main bundle
        let rulesService = try RulesService(
            bundle: .main,
            wmRulesPath: "rules/wm_ladder.json",
            locRulesPath: "rules/loc_indication.guard.json",
            operatorsPath: "rules/operators.json"
        )

        XCTAssertNotNil(rulesService.wmEngine)
        XCTAssertNotNil(rulesService.locEngine)

        print("✅ Rules loaded from main bundle")
    }

    func testResourceResolutionTestBundle() throws {
        // Verify rules can load from test bundle
        let bundle = Bundle(for: Self.self)
        let rulesService = try RulesService(
            bundle: bundle,
            wmRulesPath: "rules/wm_ladder.json",
            locRulesPath: "rules/loc_indication.guard.json",
            operatorsPath: "rules/operators.json"
        )

        XCTAssertNotNil(rulesService.wmEngine)
        XCTAssertNotNil(rulesService.locEngine)

        print("✅ Rules loaded from test bundle")
    }
}
