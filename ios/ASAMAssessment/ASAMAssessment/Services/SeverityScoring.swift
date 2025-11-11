//
//  SeverityScoring.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation
import Combine

class SeverityScoring: ObservableObject {
    
    // MARK: - Properties
    
    private let scoringRules: ScoringRules
    
    // MARK: - Initialization
    
    init(scoringURL: URL) throws {
        let data = try Data(contentsOf: scoringURL)
        self.scoringRules = try JSONDecoder().decode(ScoringRules.self, from: data)
    }
    
    convenience init() throws {
        guard let url = Bundle.main.url(
            forResource: "severity_rules",
            withExtension: "json",
            subdirectory: "questionnaires/scoring"
        ) else {
            throw ScoringError.configurationNotFound
        }
        try self.init(scoringURL: url)
    }
    
    // MARK: - Public Methods
    
    func computeSeverity(forDomain domain: String, answers: [String: Any]) -> DomainSeverity {
        let domainKey = domain.uppercased()
        
        guard let domainConfig = scoringRules.domains[domainKey] else {
            return createDefaultSeverity(for: domain, reason: "Domain configuration not found")
        }
        
        // Check for override conditions first
        if let override = checkOverrides(domainConfig: domainConfig, answers: answers) {
            return DomainSeverity(
                domain: domain,
                severity: override.severity,
                score: Double(override.severity),
                description: domainConfig.scoring.thresholds.severityDescription(for: override.severity),
                computedAt: Date(),
                overrideReason: override.reason
            )
        }
        
        // Compute weighted average score
        let score = computeWeightedScore(domainConfig: domainConfig, answers: answers)
        let severity = determineSeverityLevel(score: score, thresholds: domainConfig.scoring.thresholds)
        
        return DomainSeverity(
            domain: domain,
            severity: severity,
            score: score,
            description: domainConfig.scoring.thresholds.severityDescription(for: severity),
            computedAt: Date(),
            overrideReason: nil
        )
    }
    
    func computeAllSeverities(answers: [String: [String: Any]]) -> [DomainSeverity] {
        let domains = ["A", "B", "C", "D", "E", "F"]
        return domains.compactMap { domain in
            guard let domainAnswers = answers[domain] else { return nil }
            return computeSeverity(forDomain: domain, answers: domainAnswers)
        }
    }
    
    func validateScoringRules() -> [String] {
        var errors: [String] = []
        
        // Validate each domain configuration
        for (domain, config) in scoringRules.domains {
            errors.append(contentsOf: validateDomainConfig(domain: domain, config: config))
        }
        
        return errors
    }
    
    // MARK: - Private Methods
    
    private func checkOverrides(domainConfig: DomainConfig, answers: [String: Any]) -> OverrideResult? {
        for override in domainConfig.scoring.overrides ?? [] {
            if isOverrideConditionMet(condition: override.condition, answers: answers) {
                return OverrideResult(severity: override.severity, reason: override.reason)
            }
        }
        return nil
    }
    
    private func isOverrideConditionMet(condition: OverrideCondition, answers: [String: Any]) -> Bool {
        guard let answer = answers[condition.question] else { return false }
        
        // Handle different answer types
        switch condition.operator {
        case "equals":
            return isEqual(answer: answer, target: condition.value)
        case "contains":
            return contains(answer: answer, target: condition.value)
        default:
            return false
        }
    }
    
    private func isEqual(answer: Any, target: Any) -> Bool {
        // Convert both to string for comparison
        let answerStr = String(describing: answer)
        let targetStr = String(describing: target)
        return answerStr == targetStr
    }
    
    private func contains(answer: Any, target: Any) -> Bool {
        let answerStr = String(describing: answer).lowercased()
        let targetStr = String(describing: target).lowercased()
        return answerStr.contains(targetStr)
    }
    
    private func computeWeightedScore(domainConfig: DomainConfig, answers: [String: Any]) -> Double {
        let criticalQuestions = domainConfig.scoring.criticalQuestions
        var totalScore = 0.0
        var questionCount = 0
        
        for questionId in criticalQuestions {
            if let answer = answers[questionId] {
                let score = extractScore(from: answer)
                totalScore += score
                questionCount += 1
            }
        }
        
        // Include non-critical questions with lower weight
        for (questionId, answer) in answers {
            if !criticalQuestions.contains(questionId) {
                let score = extractScore(from: answer) * 0.5  // Half weight for non-critical
                totalScore += score
                questionCount += 1
            }
        }
        
        guard questionCount >= scoringRules.globalRules.minimumQuestionsRequired else {
            return Double(scoringRules.globalRules.defaultSeverityIfInsufficientData)
        }
        
        return questionCount > 0 ? totalScore / Double(questionCount) : 1.0
    }
    
    private func extractScore(from answer: Any) -> Double {
        // If answer is a dictionary with score, use that
        if let dict = answer as? [String: Any],
           let score = dict["score"] as? Double {
            return score
        }
        
        // If answer is a number, use it directly
        if let number = answer as? Double {
            return max(1.0, min(4.0, number))  // Clamp to 1-4 range
        }
        
        if let number = answer as? Int {
            return Double(max(1, min(4, number)))
        }
        
        // For string answers, try to map to numeric score
        if let string = answer as? String {
            return scoreForStringAnswer(string)
        }
        
        // Default score
        return 2.0
    }
    
    private func scoreForStringAnswer(_ answer: String) -> Double {
        let lowercased = answer.lowercased()
        
        // Map common answer patterns to scores
        switch lowercased {
        case "none", "no", "never", "excellent", "stable", "independent":
            return 1.0
        case "mild", "low", "good", "occasional", "minimal":
            return 2.0
        case "moderate", "some", "fair", "frequent":
            return 3.0
        case "severe", "high", "poor", "constant", "dependent":
            return 4.0
        default:
            return 2.0
        }
    }
    
    private func determineSeverityLevel(score: Double, thresholds: SeverityThresholds) -> Int {
        if score <= thresholds.level1.max {
            return 1
        } else if score <= thresholds.level2.max {
            return 2
        } else if score <= thresholds.level3.max {
            return 3
        } else {
            return 4
        }
    }
    
    private func createDefaultSeverity(for domain: String, reason: String) -> DomainSeverity {
        return DomainSeverity(
            domain: domain,
            severity: scoringRules.globalRules.defaultSeverityIfInsufficientData,
            score: Double(scoringRules.globalRules.defaultSeverityIfInsufficientData),
            description: "Default severity due to insufficient data",
            computedAt: Date(),
            overrideReason: reason
        )
    }
    
    private func validateDomainConfig(domain: String, config: DomainConfig) -> [String] {
        var errors: [String] = []
        
        // Validate critical questions
        if config.scoring.criticalQuestions.isEmpty {
            errors.append("Domain \(domain): No critical questions defined")
        }
        
        // Validate thresholds
        let thresholds = config.scoring.thresholds
        if thresholds.level1.max >= thresholds.level2.max {
            errors.append("Domain \(domain): Level 1 max should be less than Level 2 max")
        }
        
        return errors
    }
}

// MARK: - Supporting Models

struct ScoringRules: Codable {
    let version: String
    let description: String
    let domains: [String: DomainConfig]
    let globalRules: GlobalRules
    
    enum CodingKeys: String, CodingKey {
        case version, description, domains
        case globalRules = "global_rules"
    }
}

struct DomainConfig: Codable {
    let name: String
    let scoring: ScoringConfig
}

struct ScoringConfig: Codable {
    let method: String
    let criticalQuestions: [String]
    let thresholds: SeverityThresholds
    let overrides: [ScoringOverride]?
    
    enum CodingKeys: String, CodingKey {
        case method, thresholds, overrides
        case criticalQuestions = "critical_questions"
    }
}

struct SeverityThresholds: Codable {
    let level1: ThresholdLevel
    let level2: ThresholdLevel
    let level3: ThresholdLevel
    let level4: ThresholdLevel
    
    enum CodingKeys: String, CodingKey {
        case level1 = "level_1"
        case level2 = "level_2"
        case level3 = "level_3"
        case level4 = "level_4"
    }
    
    func severityDescription(for level: Int) -> String {
        switch level {
        case 1: return level1.description
        case 2: return level2.description
        case 3: return level3.description
        case 4: return level4.description
        default: return "Unknown severity level"
        }
    }
}

struct ThresholdLevel: Codable {
    let min: Double
    let max: Double
    let description: String
}

struct ScoringOverride: Codable {
    let condition: OverrideCondition
    let severity: Int
    let reason: String
}

struct OverrideCondition: Codable {
    let question: String
    let `operator`: String
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case question, value
        case `operator` = "operator"
    }
}

struct GlobalRules: Codable {
    let minimumQuestionsRequired: Int
    let defaultSeverityIfInsufficientData: Int
    let scoreAggregation: ScoreAggregation
    
    enum CodingKeys: String, CodingKey {
        case minimumQuestionsRequired = "minimum_questions_required"
        case defaultSeverityIfInsufficientData = "default_severity_if_insufficient_data"
        case scoreAggregation = "score_aggregation"
    }
}

struct ScoreAggregation: Codable {
    let method: String
    let description: String
}

// MARK: - Helper Types

private struct OverrideResult {
    let severity: Int
    let reason: String
}

enum ScoringError: LocalizedError {
    case configurationNotFound
    case invalidConfiguration(String)
    case insufficientData
    
    var errorDescription: String? {
        switch self {
        case .configurationNotFound:
            return "Scoring configuration file not found"
        case .invalidConfiguration(let reason):
            return "Invalid scoring configuration: \(reason)"
        case .insufficientData:
            return "Insufficient data to compute severity score"
        }
    }
}