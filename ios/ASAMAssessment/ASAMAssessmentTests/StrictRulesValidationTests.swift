//
//  StrictRulesValidationTests.swift
//  ASAMAssessmentTests
//
//  Strict validation tests for rules engine integrity
//  Only runs when -DSTRICT_ANCHORS is set (pre-push hook)
//

import XCTest
@testable import ASAMAssessment

final class StrictRulesValidationTests: XCTestCase {
    
    // MARK: - Rule ID Uniqueness
    
    func testRuleIdUniqueness_Strict() throws {
        try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
        
        // Load rules from bundle
        guard let rulesURL = Bundle(for: Self.self).url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules"),
              let data = try? Data(contentsOf: rulesURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rules = json["rules"] as? [[String: Any]] else {
            XCTFail("Failed to load wm_ladder.json")
            return
        }
        
        // Extract all rule IDs
        var ruleIds = Set<String>()
        var duplicates = [String]()
        
        for rule in rules {
            if let ruleId = rule["id"] as? String {
                if ruleIds.contains(ruleId) {
                    duplicates.append(ruleId)
                }
                ruleIds.insert(ruleId)
            }
        }
        
        XCTAssertTrue(duplicates.isEmpty, "Duplicate rule IDs found: \(duplicates.joined(separator: ", "))")
    }
    
    // MARK: - Precedence Monotonicity
    
    func testPrecedenceMonotonicity_Strict() throws {
        try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
        
        guard let rulesURL = Bundle(for: Self.self).url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules"),
              let data = try? Data(contentsOf: rulesURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rules = json["rules"] as? [[String: Any]] else {
            XCTFail("Failed to load wm_ladder.json")
            return
        }
        
        // Check precedence values are monotonically increasing or consistent
        var lastPrecedence: Int?
        for (index, rule) in rules.enumerated() {
            if let precedence = rule["precedence"] as? Int {
                if let last = lastPrecedence {
                    XCTAssertGreaterThanOrEqual(precedence, last,
                        "Precedence violation at rule index \(index): \(precedence) < \(last)")
                }
                lastPrecedence = precedence
            }
        }
    }
    
    // MARK: - Required Fields Presence
    
    func testRequiredFieldsPresent_Strict() throws {
        try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
        
        guard let rulesURL = Bundle(for: Self.self).url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules"),
              let data = try? Data(contentsOf: rulesURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rules = json["rules"] as? [[String: Any]] else {
            XCTFail("Failed to load wm_ladder.json")
            return
        }
        
        let requiredFields = ["id", "description", "precedence", "condition"]
        
        for (index, rule) in rules.enumerated() {
            for field in requiredFields {
                XCTAssertNotNil(rule[field], "Rule at index \(index) missing required field '\(field)'")
            }
        }
    }
    
    // MARK: - Anchors Coverage
    
    func testAnchorsCoverage_Strict() throws {
        try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
        
        // Load anchors.json
        guard let anchorsURL = Bundle(for: Self.self).url(forResource: "anchors", withExtension: "json", subdirectory: "rules"),
              let data = try? Data(contentsOf: anchorsURL),
              let anchorsJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to load anchors.json")
            return
        }
        
        // Verify structure
        XCTAssertNotNil(anchorsJson["domains"], "anchors.json missing 'domains' key")
        XCTAssertNotNil(anchorsJson["flags"], "anchors.json missing 'flags' key")
        
        if let domains = anchorsJson["domains"] as? [String: Any] {
            XCTAssertFalse(domains.isEmpty, "domains should not be empty")
        }
    }
    
    // MARK: - LOC Rules Validation
    
    func testLOCRulesStructure_Strict() throws {
        try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
        
        guard let locURL = Bundle(for: Self.self).url(forResource: "loc_indication.guard", withExtension: "json", subdirectory: "rules"),
              let data = try? Data(contentsOf: locURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rules = json["rules"] as? [[String: Any]] else {
            XCTFail("Failed to load loc_indication.guard.json")
            return
        }
        
        XCTAssertFalse(rules.isEmpty, "LOC rules should not be empty")
        
        // Verify each rule has required LOC fields
        for (index, rule) in rules.enumerated() {
            XCTAssertNotNil(rule["id"], "LOC rule at index \(index) missing 'id'")
            XCTAssertNotNil(rule["condition"], "LOC rule at index \(index) missing 'condition'")
        }
    }
    
    // MARK: - Operators Validation
    
    func testOperatorsDefinition_Strict() throws {
        try XCTSkipUnless(StrictAnchors.enabled, "STRICT_ANCHORS not enabled")
        
        guard let operatorsURL = Bundle(for: Self.self).url(forResource: "operators", withExtension: "json", subdirectory: "rules"),
              let data = try? Data(contentsOf: operatorsURL),
              let operators = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to load operators.json")
            return
        }
        
        // Verify common operators are defined
        let requiredOperators = ["==", "!=", ">", "<", ">=", "<=", "in", "contains"]
        for op in requiredOperators {
            XCTAssertNotNil(operators[op], "Operator '\(op)' not defined in operators.json")
        }
    }
}
