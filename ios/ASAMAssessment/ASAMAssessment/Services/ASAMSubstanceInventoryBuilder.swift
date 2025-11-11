//
//  ASAMSubstanceInventoryBuilder.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation

/// Builder for official ASAM substance inventory matching form exactly
struct ASAMSubstanceInventoryBuilder {
    
    // MARK: - Main Substance Inventory Question
    
    /// Build the substance inventory table question matching ASAM form structure
    static func buildSubstanceInventoryQuestion(complianceMode: ASAMComplianceMode) -> ASAMQuestion {
        
        let licensedText = """
        I am going to read you a list of substances. Could you tell me which ones you have used, how long, how recently, and how you used them?
        
        For each substance:
        • Duration (Years/Months estimate)
        • Frequency in last 30 days
        • Route of use (check all that apply)
        • Date of last use
        • Additional substance-specific questions
        """
        
        let neutralText = """
        Please provide information about your substance use patterns:
        
        For each substance category:
        • How long have you used it?
        • How often in the last month?
        • How do you typically use it?
        • When did you last use it?
        """
        
        _ = ASAMQuestionTraceability(
            formSection: "Dimension 1, Pages 1-4",
            formPageNumber: 1,
            exactFormText: licensedText,
            neutralText: neutralText,
            appFieldId: "D1_substance_inventory",
            source: .asamForm,
            complianceNotes: "Core ASAM assessment - table format required"
        )
        
        return ASAMQuestion(
            id: "D1_substance_inventory",
            questionNumber: "1.1",
            text: complianceMode == .licensed ? licensedText : neutralText,
            helpText: "This comprehensive inventory assesses substance use patterns for withdrawal risk calculation.",
            type: .substanceInventory,
            options: nil,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: "At least one substance must be assessed"),
            skipLogic: nil,
            followUpQuestions: buildFollowUpQuestions(),
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .high, v3SeverityContribution: 3, v4RiskContribution: "D"),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: nil
        )
    }
    
    // MARK: - Substance-Specific Questions
    
    /// Build alcohol-specific binge question (scoped to alcohol row)
    static func buildAlcoholBingeQuestion(complianceMode: ASAMComplianceMode) -> ASAMQuestion {
        
        let licensedText = "In the last 30 days, how often have you had [females: 4+ drinks; males: 5+ drinks] on one occasion?"
        let neutralText = "In the last 30 days, how often have you had multiple drinks on one occasion?"
        
        let options = [
            ASAMQuestionOption(id: "never", text: "Never", value: "never", riskLevel: 0, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "1-2_times", text: "1-2 times", value: "1-2_times", riskLevel: 1, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "3-5_times", text: "3-5 times", value: "3-5_times", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "6-10_times", text: "6-10 times", value: "6-10_times", riskLevel: 3, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "more_than_10", text: "More than 10 times", value: "more_than_10", riskLevel: 4, triggersFollowUp: nil, skipTo: nil)
        ]
        
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "D1_substance_inventory.alcohol",
                condition: .equals,
                value: ASAMAnswerValue.string("never_used"),
                action: .skip
            )
        ]
        
        _ = ASAMQuestionTraceability(
            formSection: "Dimension 1, Alcohol Row",
            formPageNumber: 1,
            exactFormText: licensedText,
            neutralText: neutralText,
            appFieldId: "D1_alcohol_binge",
            source: .asamForm,
            complianceNotes: "Must be scoped to alcohol row only - not global"
        )
        
        return ASAMQuestion(
            id: "D1_alcohol_binge",
            questionNumber: "1.1a",
            text: complianceMode == .licensed ? licensedText : neutralText,
            helpText: "Binge drinking increases withdrawal risk.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.0, category: .high, v3SeverityContribution: 2, v4RiskContribution: "C"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: nil
        )
    }
    
    /// Build prescription misuse questions (for relevant substances only)
    static func buildPrescriptionMisuseQuestions(complianceMode: ASAMComplianceMode) -> [ASAMQuestion] {
        var questions: [ASAMQuestion] = []
        
        // Prescription opioids misuse
        let opioidMisuseText = complianceMode == .licensed ? 
            "Valid prescription? (for prescription opioids)" :
            "Do you have a valid prescription for these medications?"
        
        let opioidQuestion = ASAMQuestion(
            id: "D1_prescription_opioids_valid",
            questionNumber: "1.1b",
            text: opioidMisuseText,
            helpText: "Check PDMP for validation. Misuse includes refilling too often or off-label use.",
            type: .boolean,
            options: [
                ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 0, triggersFollowUp: nil, skipTo: nil),
                ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 3, triggersFollowUp: ["D1_opioid_misuse_details"], skipTo: nil)
            ],
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: [
                ASAMSkipCondition(
                    dependsOn: "D1_substance_inventory.prescription_opioids",
                    condition: .equals,
                    value: ASAMAnswerValue.string("never_used"),
                    action: .skip
                )
            ],
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.5, category: .high, v3SeverityContribution: 3, v4RiskContribution: "D"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: nil
        )
        questions.append(opioidQuestion)
        
        // Benzodiazepines misuse
        let benzoMisuseText = complianceMode == .licensed ? 
            "Valid prescription? (for benzodiazepines)" :
            "Do you have a valid prescription for these medications?"
        
        let benzoQuestion = ASAMQuestion(
            id: "D1_benzodiazepines_valid",
            questionNumber: "1.1c",
            text: benzoMisuseText,
            helpText: "Benzodiazepine withdrawal can be life-threatening after 6 months daily use.",
            type: .boolean,
            options: [
                ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 0, triggersFollowUp: nil, skipTo: nil),
                ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 4, triggersFollowUp: ["D1_benzo_misuse_details"], skipTo: nil)
            ],
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: [
                ASAMSkipCondition(
                    dependsOn: "D1_substance_inventory.benzodiazepines",
                    condition: .equals,
                    value: ASAMAnswerValue.string("never_used"),
                    action: .skip
                )
            ],
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: nil
        )
        questions.append(benzoQuestion)
        
        return questions
    }
    
    /// Build substance withdrawal timing questions matching ASAM form
    static func buildWithdrawalTimingQuestions(complianceMode: ASAMComplianceMode) -> [ASAMQuestion] {
        var questions: [ASAMQuestion] = []
        
        // Question about recent use (last 48 hours)
        let recentUseText = complianceMode == .licensed ? 
            "Have you used substances in the last 48 hours? If yes, what? List:" :
            "Have you used any substances in the last 2 days? Please list:"
        
        let recentUseQuestion = ASAMQuestion(
            id: "D1_recent_use_48hrs",
            questionNumber: "1.7",
            text: recentUseText,
            helpText: "Important for withdrawal timing. Note onset times: short-acting opioids 8-24 hrs.",
            type: .text,
            options: nil,
            validation: ASAMQuestionValidation(required: true, minLength: 0, maxLength: 500, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.0, category: .moderate, v3SeverityContribution: 2, v4RiskContribution: "C"),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: nil
        )
        questions.append(recentUseQuestion)
        
        // Interviewer observation of intoxication/withdrawal
        let observationText = complianceMode == .licensed ? 
            "Interviewer observation: Does the patient seem to have current signs of withdrawal or intoxication? Please describe:" :
            "Clinical observation: Are there current signs of withdrawal or intoxication? Describe:"
        
        let observationQuestion = ASAMQuestion(
            id: "D1_interviewer_observation",
            questionNumber: "1.8",
            text: observationText,
            helpText: "Signs include disinhibition, sedation, slurred speech, tremors, sweating, etc.",
            type: .interviewerObservation,
            options: [
                ASAMQuestionOption(id: "intoxication", text: "Intoxication", value: "intoxication", riskLevel: 3, triggersFollowUp: ["D1_intox_details"], skipTo: nil),
                ASAMQuestionOption(id: "withdrawal", text: "Withdrawal", value: "withdrawal", riskLevel: 4, triggersFollowUp: ["D1_withdrawal_details"], skipTo: nil),
                ASAMQuestionOption(id: "none", text: "None", value: "none", riskLevel: 0, triggersFollowUp: nil, skipTo: nil)
            ],
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: nil
        )
        questions.append(observationQuestion)
        
        return questions
    }
    
    // MARK: - Private Helpers
    
    private static func buildFollowUpQuestions() -> [String] {
        return [
            "D1_alcohol_binge",
            "D1_prescription_opioids_valid",
            "D1_benzodiazepines_valid",
            "D1_recent_use_48hrs",
            "D1_interviewer_observation"
        ]
    }
}

// MARK: - Substance Inventory UI Components

/// Data structure for substance inventory table row
struct SubstanceInventoryRow: Identifiable {
    let id = UUID()
    let substance: ASAMSubstanceType
    let complianceMode: ASAMComplianceMode
    
    var displayName: String {
        switch complianceMode {
        case .licensed: return substance.displayName
        case .neutral: return substance.neutralDisplayName
        }
    }
    
    // Form fields
    var durationYears: Int = 0
    var durationMonths: Int = 0
    var frequencyLast30Days: ASAMFrequencyCategory = .neverUsed
    var routesOfUse: Set<ASAMRouteOfUse> = []
    var dateLastUse: Date?
    
    // Alcohol-specific (conditional)
    var averageDrinksPerDay: Double?
    var bingeFrequency: String?
    
    // Prescription-specific (conditional) 
    var hasValidPrescription: Bool?
    
    // Additional tracking
    var notes: String = ""
    
    /// Whether this row should show prescription fields
    var shouldShowPrescriptionFields: Bool {
        return substance.requiresValidPrescriptionField
    }
    
    /// Whether this row should show alcohol fields
    var shouldShowAlcoholFields: Bool {
        return substance.supportsAlcoholSpecificFields
    }
    
    /// Calculate risk score for this substance
    func calculateRiskScore() -> Int {
        var risk = 0
        
        // Frequency risk
        risk += frequencyLast30Days.riskLevel
        
        // Route risk (highest route)
        if let maxRouteRisk = routesOfUse.map({ $0.riskLevel }).max() {
            risk += maxRouteRisk
        }
        
        // Prescription misuse risk
        if shouldShowPrescriptionFields, hasValidPrescription == false {
            risk += 3
        }
        
        // Duration risk (longer = higher tolerance = higher withdrawal risk)
        let totalMonths = (durationYears * 12) + durationMonths
        if totalMonths > 24 { risk += 2 }
        else if totalMonths > 12 { risk += 1 }
        
        return min(risk, 4) // Cap at 4 (ASAM scale)
    }
}