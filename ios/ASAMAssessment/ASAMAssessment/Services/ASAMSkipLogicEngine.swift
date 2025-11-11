//
//  ASAMSkipLogicEngine.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation
import Combine

/// Engine for handling ASAM skip logic and conditional question flow
@MainActor
class ASAMSkipLogicEngine: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var currentQuestionPath: [String] = []
    @Published private(set) var visibleQuestions: Set<String> = []
    @Published private(set) var requiredQuestions: Set<String> = []
    
    private let assessment: ASAMAssessment
    private var response: ASAMAssessmentResponse
    
    // MARK: - Initialization
    
    init(assessment: ASAMAssessment, response: ASAMAssessmentResponse) {
        self.assessment = assessment
        self.response = response
        calculateInitialQuestionVisibility()
    }
    
    // MARK: - Public Methods
    
    /// Determine if a question should be shown based on current answers
    func shouldShowQuestion(_ questionId: String) -> Bool {
        guard let question = assessment.getQuestion(by: questionId) else {
            return false
        }
        
        // If no skip logic, always show required questions
        guard let skipLogic = question.skipLogic, !skipLogic.isEmpty else {
            return question.isRequired
        }
        
        // Evaluate all skip conditions
        for condition in skipLogic {
            let result = evaluateSkipCondition(condition)
            
            switch condition.action {
            case .skip:
                if result { return false }  // Skip if condition is true
            case .show:
                if !result { return false } // Show only if condition is true
            case .require:
                if result {
                    requiredQuestions.insert(questionId)
                }
            case .optional:
                if result {
                    requiredQuestions.remove(questionId)
                }
            case .jumpTo:
                // Handle jump logic separately
                continue
            }
        }
        
        return true
    }
    
    /// Get the next question that should be shown
    func getNextQuestion(after questionId: String) -> String? {
        // Check if current question triggers follow-up questions
        if let followUps = getTriggeredFollowUpQuestions(for: questionId) {
            for followUp in followUps {
                if shouldShowQuestion(followUp) {
                    return followUp
                }
            }
        }
        
        // Check for jump-to logic
        if let jumpTarget = getJumpTarget(for: questionId) {
            return jumpTarget
        }
        
        // Default: get next question in sequence
        return getNextQuestionInSequence(after: questionId)
    }
    
    /// Update question visibility when an answer changes
    func updateForAnswerChange(questionId: String, newAnswer: ASAMAnswerValue) {
        // Update response
        // TODO: Fix - response.answers is immutable, need to refactor ASAMAssessmentResponse
        // response.answers[questionId] = newAnswer
        
        // Recalculate visibility for all questions that might be affected
        recalculateQuestionVisibility()
        
        // Update current path
        updateCurrentQuestionPath(lastAnswered: questionId)
    }
    
    /// Get all questions that should be visible in current context
    func getVisibleQuestionsForDimension(_ dimensionId: Int) -> [ASAMQuestion] {
        guard let dimension = assessment.getDimension(by: dimensionId) else {
            return []
        }
        
        return dimension.allQuestions.filter { shouldShowQuestion($0.id) }
    }
    
    /// Check if a question is required based on current answers and skip logic
    func isQuestionRequired(_ questionId: String) -> Bool {
        guard let question = assessment.getQuestion(by: questionId) else {
            return false
        }
        
        // Start with question's base requirement
        var isRequired = question.isRequired
        
        // Apply skip logic modifications
        if let skipLogic = question.skipLogic {
            for condition in skipLogic {
                let result = evaluateSkipCondition(condition)
                
                switch condition.action {
                case .require where result:
                    isRequired = true
                case .optional where result:
                    isRequired = false
                default:
                    break
                }
            }
        }
        
        return isRequired && shouldShowQuestion(questionId)
    }
    
    /// Get completion percentage for current dimension
    func getCompletionPercentage(for dimensionId: Int) -> Double {
        let visibleQuestions = getVisibleQuestionsForDimension(dimensionId)
        let requiredQuestions = visibleQuestions.filter { isQuestionRequired($0.id) }
        
        guard !requiredQuestions.isEmpty else { return 1.0 }
        
        let answeredQuestions = requiredQuestions.filter { 
            response.hasAnswer(for: $0.id) 
        }
        
        return Double(answeredQuestions.count) / Double(requiredQuestions.count)
    }
    
    // MARK: - Private Methods
    
    private func calculateInitialQuestionVisibility() {
        visibleQuestions.removeAll()
        requiredQuestions.removeAll()
        
        for dimension in assessment.dimensions {
            for question in dimension.allQuestions {
                if shouldShowQuestion(question.id) {
                    visibleQuestions.insert(question.id)
                    
                    if isQuestionRequired(question.id) {
                        requiredQuestions.insert(question.id)
                    }
                }
            }
        }
    }
    
    private func recalculateQuestionVisibility() {
        let oldVisible = visibleQuestions
        let oldRequired = requiredQuestions
        
        calculateInitialQuestionVisibility()
        
        // Notify of changes if visibility changed
        if oldVisible != visibleQuestions || oldRequired != requiredQuestions {
            objectWillChange.send()
        }
    }
    
    private func evaluateSkipCondition(_ condition: ASAMSkipCondition) -> Bool {
        guard let dependentAnswer = response.getAnswer(for: condition.dependsOn) else {
            // If dependent question not answered, condition is false
            return false
        }
        
        return compareAnswerValues(dependentAnswer, condition.condition, condition.value)
    }
    
    private func compareAnswerValues(_ actual: ASAMAnswerValue, 
                                   _ operator: ASAMConditionOperator, 
                                   _ expected: ASAMAnswerValue) -> Bool {
        switch `operator` {
        case .equals:
            return actual == expected
            
        case .notEquals:
            return actual != expected
            
        case .greaterThan:
            return compareNumeric(actual, expected, >)
            
        case .lessThan:
            return compareNumeric(actual, expected, <)
            
        case .contains:
            return actual.stringValue.localizedCaseInsensitiveContains(expected.stringValue)
            
        case .isEmpty:
            return actual.stringValue.isEmpty
            
        case .isNotEmpty:
            return !actual.stringValue.isEmpty
        }
    }
    
    private func compareNumeric(_ lhs: ASAMAnswerValue, 
                              _ rhs: ASAMAnswerValue, 
                              _ operation: (Double, Double) -> Bool) -> Bool {
        let lhsValue: Double
        let rhsValue: Double
        
        switch lhs {
        case .integer(let value):
            lhsValue = Double(value)
        case .double(let value):
            lhsValue = value
        default:
            return false
        }
        
        switch rhs {
        case .integer(let value):
            rhsValue = Double(value)
        case .double(let value):
            rhsValue = value
        default:
            return false
        }
        
        return operation(lhsValue, rhsValue)
    }
    
    private func getTriggeredFollowUpQuestions(for questionId: String) -> [String]? {
        guard let question = assessment.getQuestion(by: questionId),
              let answer = response.getAnswer(for: questionId) else {
            return nil
        }
        
        // Check if question has follow-up questions defined
        if let followUps = question.followUpQuestions {
            return followUps
        }
        
        // Check if specific answer option triggers follow-ups
        if let options = question.options {
            for option in options {
                if ASAMAnswerValue.string(option.value) == answer,
                   let triggeredFollowUps = option.triggersFollowUp {
                    return triggeredFollowUps
                }
            }
        }
        
        return nil
    }
    
    private func getJumpTarget(for questionId: String) -> String? {
        guard let question = assessment.getQuestion(by: questionId),
              let answer = response.getAnswer(for: questionId) else {
            return nil
        }
        
        // Check for jump-to logic in skip conditions
        if let skipLogic = question.skipLogic {
            for condition in skipLogic {
                if condition.action == .jumpTo && evaluateSkipCondition(condition) {
                    return condition.dependsOn // In jump-to, dependsOn contains target question ID
                }
            }
        }
        
        // Check if answer option has skip-to target
        if let options = question.options {
            for option in options {
                if ASAMAnswerValue.string(option.value) == answer,
                   let skipTo = option.skipTo {
                    return skipTo
                }
            }
        }
        
        return nil
    }
    
    private func getNextQuestionInSequence(after questionId: String) -> String? {
        // Find current question and return next in dimension order
        for dimension in assessment.dimensions {
            let questions = dimension.allQuestions
            if let currentIndex = questions.firstIndex(where: { $0.id == questionId }) {
                let nextIndex = currentIndex + 1
                
                // Look for next visible question in same dimension
                for i in nextIndex..<questions.count {
                    let nextQuestion = questions[i]
                    if shouldShowQuestion(nextQuestion.id) {
                        return nextQuestion.id
                    }
                }
                
                // If no more questions in this dimension, go to next dimension
                let nextDimensionId = dimension.id + 1
                if let nextDimension = assessment.getDimension(by: nextDimensionId) {
                    for question in nextDimension.allQuestions {
                        if shouldShowQuestion(question.id) {
                            return question.id
                        }
                    }
                }
            }
        }
        
        return nil // No more questions
    }
    
    private func updateCurrentQuestionPath(lastAnswered: String) {
        if !currentQuestionPath.contains(lastAnswered) {
            currentQuestionPath.append(lastAnswered)
        }
        
        // Remove questions that are no longer visible
        currentQuestionPath = currentQuestionPath.filter { visibleQuestions.contains($0) }
    }
}

// MARK: - ASAM Version-Specific Skip Logic

extension ASAMSkipLogicEngine {
    
    /// Get ASAM v3 specific question flow
    func getV3QuestionFlow(for dimensionId: Int) -> [String] {
        guard assessment.version == .v3_2013 else { return [] }
        
        // Implement v3-specific question ordering and flow
        switch dimensionId {
        case 1: // Acute Intoxication & Withdrawal
            return getV3Dimension1Flow()
        case 2: // Biomedical Conditions
            return getV3Dimension2Flow()
        case 3: // Emotional/Behavioral/Cognitive
            return getV3Dimension3Flow()
        case 4: // Readiness to Change
            return getV3Dimension4Flow()
        case 5: // Relapse Potential
            return getV3Dimension5Flow()
        case 6: // Recovery Environment
            return getV3Dimension6Flow()
        default:
            return []
        }
    }
    
    /// Get ASAM v4 specific question flow with Q-numbers
    func getV4QuestionFlow(for dimensionId: Int, subdimensionId: String? = nil) -> [String] {
        guard assessment.version == .v4_2024 else { return [] }
        
        switch dimensionId {
        case 1: // Acute Intoxication, Withdrawal & Addiction Medication
            if let subdim = subdimensionId {
                switch subdim {
                case "D1_intox":
                    return ["Q11", "Q12"]
                case "D1_withdrawal":
                    return ["Q13", "Q14", "Q15", "Q15a", "Q15b", "Q16", "Q16a"]
                case "D1_medication":
                    return ["Q17", "Q17a", "Q17b"]
                default:
                    return []
                }
            }
            return ["Q11", "Q12", "Q13", "Q14", "Q15", "Q15a", "Q15b", "Q16", "Q16a", "Q17", "Q17a", "Q17b", "Q18"]
        case 2: // Biomedical Conditions
            return ["Q19", "Q20", "Q20a", "Q20b", "Q21", "Q22", "Q23"]
        case 3: // Emotional/Behavioral/Cognitive
            // Complex subdimension logic for v4
            return getV4Dimension3Flow(subdimensionId: subdimensionId)
        case 4: // Readiness/Imminent Risk
            return getV4Dimension4Flow()
        case 5: // Recovery Environment
            return getV4Dimension5Flow()
        default:
            return []
        }
    }
    
    // MARK: - Private Flow Methods
    
    private func getV3Dimension1Flow() -> [String] {
        return [
            "D1_substance_inventory",
            "D1_withdrawal_concern",
            "D1_current_withdrawal", 
            "D1_withdrawal_severity",
            "D1_severe_withdrawal_history"
        ]
    }
    
    private func getV3Dimension2Flow() -> [String] {
        return [
            "D2_primary_care",
            "D2_current_medications",
            "D2_medical_concerns",
            "D2_last_medical_visit",
            "D2_health_conditions",
            "D2_infectious_issues",
            "D2_medical_stability",
            "D2_additional_treatment_needed",
            "D2_substance_related_medical",
            "D2_immunization_status",
            "D2_pregnancy_status",
            "D2_functional_impact"
        ]
    }
    
    private func getV3Dimension3Flow() -> [String] {
        return [
            "D3_cognitive_status",
            "D3_mental_health_symptoms",
            "D3_symptom_impact",
            "D3_substance_relationship",
            "D3_psychosis",
            "D3_self_harm",
            "D3_harm_others",
            "D3_treatment_goals"
        ]
    }
    
    private func getV3Dimension4Flow() -> [String] {
        return [
            "D4_substance_impact",
            "D4_change_belief",
            "D4_treatment_need",
            "D4_stage_of_change",
            "D4_problem_severity",
            "D4_past_attempts",
            "D4_treatment_barriers",
            "D4_change_desire",
            "D4_social_pressures",
            "D4_goals_concerns"
        ]
    }
    
    private func getV3Dimension5Flow() -> [String] {
        return [
            "D5_longest_abstinence",
            "D5_abstinence_methods",
            "D5_relapse_triggers",
            "D5_change_plan",
            "D5_consequences",
            "D5_trigger_severity",
            "D5_worst_triggers",
            "D5_insight_assessment"
        ]
    }
    
    private func getV3Dimension6Flow() -> [String] {
        return [
            "D6_housing_stability",
            "D6_household_composition",
            "D6_employment_education",
            "D6_income_sources",
            "D6_free_time",
            "D6_learning_challenges",
            "D6_support_needs",
            "D6_social_services",
            "D6_legal_issues",
            "D6_veteran_status",
            "D6_peer_support",
            "D6_living_environment",
            "D6_safety_assessment",
            "D6_environmental_analysis"
        ]
    }
    
    private func getV4Dimension3Flow(subdimensionId: String?) -> [String] {
        if let subdim = subdimensionId {
            switch subdim {
            case "D3_acute":
                return ["Q31", "Q32", "Q33", "Q34", "Q35"]
            case "D3_persistent":
                return ["Q36", "Q37", "Q38", "Q39"]
            default:
                return []
            }
        }
        return ["Q31", "Q32", "Q33", "Q34", "Q35", "Q36", "Q37", "Q38", "Q39"]
    }
    
    private func getV4Dimension4Flow() -> [String] {
        return ["Q41", "Q42", "Q43", "Q44", "Q45", "Q46", "Q47", "Q47a"]
    }
    
    private func getV4Dimension5Flow() -> [String] {
        return ["Q51", "Q52", "Q53", "Q54", "Q55"]
    }
}