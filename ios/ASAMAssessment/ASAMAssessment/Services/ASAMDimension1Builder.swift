//
//  ASAMDimension1Builder.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation

/// Builder for ASAM Dimension 1: Acute Intoxication & Withdrawal Potential
struct ASAMDimension1Builder {
    
    // MARK: - Public Methods
    
    /// Build Dimension 1 for ASAM v3
    static func buildV3Dimension1() -> ASAMDimension {
        let questions = [
            buildSubstanceInventoryQuestion(),
            buildWithdrawalConcernQuestion(),
            buildCurrentWithdrawalQuestion(),
            buildWithdrawalSeverityQuestion(),
            buildSevereWithdrawalHistoryQuestion(),
            buildCIWAScoreQuestion(),
            buildCOWSScoreQuestion()
        ]
        
        return ASAMDimension(
            id: 1,
            name: "Acute Intoxication & Withdrawal Potential",
            shortName: "D1",
            subdimensions: nil,
            questions: questions,
            score: nil,
            isRequired: true
        )
    }
    
    /// Build Dimension 1 for ASAM v4
    static func buildV4Dimension1() -> ASAMDimension {
        let subdimensions = [
            buildIntoxicationSubdimension(),
            buildWithdrawalSubdimension(),
            buildMedicationSubdimension()
        ]
        
        return ASAMDimension(
            id: 1,
            name: "Acute Intoxication, Withdrawal & Addiction Medication Needs",
            shortName: "D1",
            subdimensions: subdimensions,
            questions: [buildInterviewerAssessmentQuestion()],
            score: nil,
            isRequired: true
        )
    }
    
    // MARK: - ASAM v3 Questions
    
    private static func buildSubstanceInventoryQuestion() -> ASAMQuestion {
        let question = ASAMQuestion(
            id: "D1_substance_inventory",
            text: "For each substance you use, please provide the following information:",
            type: .substanceInventory,
            dimensionId: 1
        )
        
        // This would be a complex compound question handling multiple substances
        // Implementation would create a dynamic UI for each substance type
        
        return question
    }
    
    private static func buildWithdrawalConcernQuestion() -> ASAMQuestion {
        let question = ASAMQuestion(
            id: "D1_withdrawal_concern",
            text: "How much are you bothered by physical or emotional symptoms when you stop or reduce your substance use?",
            type: .scale,
            dimensionId: 1
        )
        
        // Add scale options
        let options = [
            ASAMQuestionOption(id: "0", text: "Not at all", value: "0", riskLevel: 0, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "1", text: "Slightly", value: "1", riskLevel: 1, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "2", text: "Moderately", value: "2", riskLevel: 2, triggersFollowUp: ["D1_current_withdrawal"], skipTo: nil),
            ASAMQuestionOption(id: "3", text: "Considerably", value: "3", riskLevel: 3, triggersFollowUp: ["D1_current_withdrawal", "D1_withdrawal_severity"], skipTo: nil),
            ASAMQuestionOption(id: "4", text: "Extremely", value: "4", riskLevel: 4, triggersFollowUp: ["D1_current_withdrawal", "D1_withdrawal_severity", "D1_severe_withdrawal_history"], skipTo: nil)
        ]
        
        return ASAMQuestion(
            id: question.id,
            questionNumber: "1.2",
            text: question.text,
            helpText: "This assesses your awareness of withdrawal symptoms and their impact on your functioning.",
            type: question.type,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: 0, maxValue: 4, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 1.0, category: .moderate, v3SeverityContribution: 1, v4RiskContribution: nil),
            isRequired: true,
            dimensionId: question.dimensionId,
            subdimensionId: question.subdimensionId
        )
    }
    
    private static func buildCurrentWithdrawalQuestion() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "tremors", text: "Tremors", value: "tremors", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "sweating", text: "Sweating", value: "sweating", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "rapid_heart", text: "Rapid heart rate", value: "rapid_heart", riskLevel: 3, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "nausea", text: "Nausea/Vomiting", value: "nausea", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "anxiety", text: "Anxiety", value: "anxiety", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "none", text: "None of the above", value: "none", riskLevel: 0, triggersFollowUp: nil, skipTo: nil)
        ]
        
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "D1_withdrawal_concern",
                condition: .lessThan,
                value: .integer(2),
                action: .skip
            )
        ]
        
        return ASAMQuestion(
            id: "D1_current_withdrawal",
            questionNumber: "1.3",
            text: "Are you currently experiencing any of the following withdrawal symptoms?",
            helpText: "Check all that apply. These symptoms should occur when you haven't used your substance recently.",
            type: .multipleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 1.5, category: .high, v3SeverityContribution: 2, v4RiskContribution: nil),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: nil
        )
    }
    
    private static func buildWithdrawalSeverityQuestion() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "0", text: "No symptoms", value: "0", riskLevel: 0, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "1", text: "Mild discomfort", value: "1", riskLevel: 1, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "2", text: "Moderate discomfort, manageable", value: "2", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "3", text: "Severe discomfort, difficult to manage", value: "3", riskLevel: 3, triggersFollowUp: ["D1_severe_withdrawal_history"], skipTo: nil),
            ASAMQuestionOption(id: "4", text: "Extreme discomfort, unable to function", value: "4", riskLevel: 4, triggersFollowUp: ["D1_severe_withdrawal_history", "D1_medical_withdrawal"], skipTo: nil)
        ]
        
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "D1_withdrawal_concern",
                condition: .lessThan,
                value: .integer(3),
                action: .skip
            )
        ]
        
        return ASAMQuestion(
            id: "D1_withdrawal_severity",
            questionNumber: "1.4",
            text: "How uncomfortable would your withdrawal symptoms become without treatment?",
            helpText: "Consider the worst withdrawal you've experienced or expect to experience.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.0, category: .high, v3SeverityContribution: 3, v4RiskContribution: nil),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: nil
        )
    }
    
    private static func buildSevereWithdrawalHistoryQuestion() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "never", text: "Never needed medical care", value: "never", riskLevel: 0, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "medical_care", text: "Needed medical care for withdrawal", value: "medical_care", riskLevel: 3, triggersFollowUp: ["D1_withdrawal_location"], skipTo: nil),
            ASAMQuestionOption(id: "seizures", text: "Had seizures during withdrawal", value: "seizures", riskLevel: 4, triggersFollowUp: ["D1_withdrawal_location", "D1_seizure_details"], skipTo: nil),
            ASAMQuestionOption(id: "delirium", text: "Experienced delirium (confusion, hallucinations)", value: "delirium", riskLevel: 4, triggersFollowUp: ["D1_withdrawal_location", "D1_delirium_details"], skipTo: nil)
        ]
        
        return ASAMQuestion(
            id: "D1_severe_withdrawal_history",
            questionNumber: "1.5",
            text: "Have you ever needed medical care for withdrawal or experienced severe withdrawal symptoms?",
            helpText: "This includes emergency room visits, hospitalizations, seizures, or delirium tremens (DTs).",
            type: .multipleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.5, category: .severe, v3SeverityContribution: 4, v4RiskContribution: nil),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: nil
        )
    }
    
    private static func buildCIWAScoreQuestion() -> ASAMQuestion {
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "D1_substance_inventory",
                condition: .contains,
                value: .string("alcohol"),
                action: .show
            )
        ]
        
        return ASAMQuestion(
            id: "D1_ciwa_score",
            questionNumber: "1.6",
            text: "CIWA-Ar Score (Clinical Institute Withdrawal Assessment for Alcohol - Revised)",
            helpText: "To be completed by clinician if patient reports alcohol use. Score range: 0-67",
            type: .clinicalScale,
            options: nil,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: 0, maxValue: 67, pattern: nil, customMessage: "CIWA-Ar score must be between 0 and 67"),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: nil
        )
    }
    
    private static func buildCOWSScoreQuestion() -> ASAMQuestion {
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "D1_substance_inventory",
                condition: .contains,
                value: .string("opioid"),
                action: .show
            )
        ]
        
        return ASAMQuestion(
            id: "D1_cows_score",
            questionNumber: "1.7",
            text: "COWS Score (Clinical Opiate Withdrawal Scale)",
            helpText: "To be completed by clinician if patient reports opioid use. Score range: 0-48",
            type: .clinicalScale,
            options: nil,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: 0, maxValue: 48, pattern: nil, customMessage: "COWS score must be between 0 and 48"),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: nil
        )
    }
    
    // MARK: - ASAM v4 Subdimensions
    
    private static func buildIntoxicationSubdimension() -> ASAMSubdimension {
        let questions = [
            buildQ11Question(), // Interviewer observation
            buildQ12Question()  // Patient self-report
        ]
        
        return ASAMSubdimension(id: "D1_intox", name: "Intoxication", questions: questions)
    }
    
    private static func buildWithdrawalSubdimension() -> ASAMSubdimension {
        let questions = [
            buildQ13Question(), // Current withdrawal
            buildQ14Question(), // Withdrawal severity
            buildQ15Question(), // Medical care history
            buildQ15aQuestion(), // Where treated
            buildQ15bQuestion(), // Severe symptoms
            buildQ16Question(), // Treatment history
            buildQ16aQuestion() // Completion barriers
        ]
        
        return ASAMSubdimension(id: "D1_withdrawal", name: "Withdrawal", questions: questions)
    }
    
    private static func buildMedicationSubdimension() -> ASAMSubdimension {
        let questions = [
            buildQ17Question(), // Addiction medications
            buildQ17aQuestion(), // Specify medication
            buildQ17bQuestion() // Effectiveness
        ]
        
        return ASAMSubdimension(id: "D1_medication", name: "Addiction Medication", questions: questions)
    }
    
    // MARK: - ASAM v4 Questions
    
    private static func buildQ11Question() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 4, triggersFollowUp: ["Q11_details"], skipTo: nil),
            ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: "Q12")
        ]
        
        return ASAMQuestion(
            id: "Q11",
            questionNumber: "Q11",
            text: "Based on recent use, is the patient intoxicated or at imminent risk for withdrawal?",
            helpText: "Interviewer observation based on patient presentation and reported recent use.",
            type: .interviewerObservation,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .severe, v3SeverityContribution: nil, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: "D1_intox"
        )
    }
    
    private static func buildQ12Question() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 3, triggersFollowUp: ["Q12_substance", "Q12_intensity"], skipTo: nil),
            ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: "Q13")
        ]
        
        return ASAMQuestion(
            id: "Q12",
            questionNumber: "Q12",
            text: "Are you feeling the effects of any substances right now?",
            helpText: "This includes alcohol, drugs, or medications that might affect your thinking or behavior.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.0, category: .moderate, v3SeverityContribution: nil, v4RiskContribution: "C"),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: "D1_intox"
        )
    }
    
    private static func buildQ13Question() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "yes_now", text: "Yes, experiencing withdrawal now", value: "yes_now", riskLevel: 4, triggersFollowUp: ["Q14"], skipTo: nil),
            ASAMQuestionOption(id: "yes_soon", text: "Yes, expect to experience withdrawal soon", value: "yes_soon", riskLevel: 3, triggersFollowUp: ["Q14"], skipTo: nil),
            ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: "Q15")
        ]
        
        return ASAMQuestion(
            id: "Q13",
            questionNumber: "Q13",
            text: "Are you experiencing withdrawal now or do you think you will soon?",
            helpText: "Withdrawal symptoms occur when stopping or reducing substance use.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.5, category: .high, v3SeverityContribution: nil, v4RiskContribution: "D"),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: "D1_withdrawal"
        )
    }
    
    private static func buildQ14Question() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "mild", text: "Mild discomfort", value: "mild", riskLevel: 1, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "moderate", text: "Moderate discomfort", value: "moderate", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "severe", text: "Severe discomfort", value: "severe", riskLevel: 3, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "life_threatening", text: "Potentially life-threatening", value: "life_threatening", riskLevel: 4, triggersFollowUp: ["Q14_medical_urgency"], skipTo: nil)
        ]
        
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "Q13",
                condition: .equals,
                value: .string("no"),
                action: .skip
            )
        ]
        
        return ASAMQuestion(
            id: "Q14",
            questionNumber: "Q14",
            text: "How uncomfortable would your withdrawal symptoms become without treatment?",
            helpText: "Consider the severity based on your past experience or current symptoms.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .severe, v3SeverityContribution: nil, v4RiskContribution: "E"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: "D1_withdrawal"
        )
    }
    
    private static func buildQ15Question() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 3, triggersFollowUp: ["Q15a"], skipTo: nil),
            ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: "Q16")
        ]
        
        return ASAMQuestion(
            id: "Q15",
            questionNumber: "Q15",
            text: "Have you ever needed medical care for withdrawal?",
            helpText: "This includes emergency room visits, hospitalization, or outpatient medical treatment for withdrawal symptoms.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.0, category: .high, v3SeverityContribution: nil, v4RiskContribution: "D"),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: "D1_withdrawal"
        )
    }
    
    private static func buildQ15aQuestion() -> ASAMQuestion {
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "Q15",
                condition: .equals,
                value: .string("no"),
                action: .skip
            )
        ]
        
        return ASAMQuestion(
            id: "Q15a",
            questionNumber: "Q15a",
            text: "Where were you treated for withdrawal?",
            helpText: "Describe the setting (emergency room, hospital, outpatient clinic, etc.)",
            type: .text,
            options: nil,
            validation: ASAMQuestionValidation(required: false, minLength: 1, maxLength: 500, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: ["Q15b"],
            riskWeighting: nil,
            isRequired: false,
            dimensionId: 1,
            subdimensionId: "D1_withdrawal"
        )
    }
    
    private static func buildQ15bQuestion() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "seizures", text: "Seizures", value: "seizures", riskLevel: 4, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "delirium", text: "Delirium/confusion", value: "delirium", riskLevel: 4, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "hallucinations", text: "Hallucinations", value: "hallucinations", riskLevel: 4, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "severe_agitation", text: "Severe agitation", value: "severe_agitation", riskLevel: 3, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "none", text: "None of the above", value: "none", riskLevel: 1, triggersFollowUp: nil, skipTo: nil)
        ]
        
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "Q15",
                condition: .equals,
                value: .string("no"),
                action: .skip
            )
        ]
        
        return ASAMQuestion(
            id: "Q15b",
            questionNumber: "Q15b",
            text: "Have you had severe withdrawal symptoms like seizures or delirium?",
            helpText: "Check all that apply for any withdrawal episodes you've experienced.",
            type: .multipleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .severe, v3SeverityContribution: nil, v4RiskContribution: "E"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: "D1_withdrawal"
        )
    }
    
    private static func buildQ16Question() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 1, triggersFollowUp: ["Q16a"], skipTo: nil),
            ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: "Q17")
        ]
        
        return ASAMQuestion(
            id: "Q16",
            questionNumber: "Q16",
            text: "Have you received substance use treatment before?",
            helpText: "This includes any type of substance use treatment: inpatient, outpatient, counseling, etc.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: nil,
            isRequired: true,
            dimensionId: 1,
            subdimensionId: "D1_withdrawal"
        )
    }
    
    private static func buildQ16aQuestion() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: nil)
        ]
        
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "Q16",
                condition: .equals,
                value: .string("no"),
                action: .skip
            )
        ]
        
        return ASAMQuestion(
            id: "Q16a",
            questionNumber: "Q16a",
            text: "Did cravings or withdrawal prevent you from completing treatment?",
            helpText: "Think about your most recent treatment episode.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 1.5, category: .moderate, v3SeverityContribution: nil, v4RiskContribution: "C"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: "D1_withdrawal"
        )
    }
    
    private static func buildQ17Question() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 1, triggersFollowUp: ["Q17a"], skipTo: nil),
            ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: "Q18")
        ]
        
        return ASAMQuestion(
            id: "Q17",
            questionNumber: "Q17",
            text: "Are you now taking, or have you ever taken, prescribed medication to help control cravings or other unwanted symptoms?",
            helpText: "This includes medications like buprenorphine, methadone, naltrexone, acamprosate, etc.",
            type: .singleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: nil,
            isRequired: true,
            dimensionId: 1,
            subdimensionId: "D1_medication"
        )
    }
    
    private static func buildQ17aQuestion() -> ASAMQuestion {
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "Q17",
                condition: .equals,
                value: .string("no"),
                action: .skip
            )
        ]
        
        return ASAMQuestion(
            id: "Q17a",
            questionNumber: "Q17a",
            text: "Please specify the medication(s):",
            helpText: "List all addiction medications you are taking or have taken (e.g., buprenorphine, methadone, naltrexone, acamprosate, disulfiram).",
            type: .medicationList,
            options: nil,
            validation: ASAMQuestionValidation(required: false, minLength: 1, maxLength: 500, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: ["Q17b"],
            riskWeighting: nil,
            isRequired: false,
            dimensionId: 1,
            subdimensionId: "D1_medication"
        )
    }
    
    private static func buildQ17bQuestion() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "very_effective", text: "Very effective", value: "very_effective", riskLevel: 0, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "somewhat_effective", text: "Somewhat effective", value: "somewhat_effective", riskLevel: 1, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "not_effective", text: "Not effective", value: "not_effective", riskLevel: 2, triggersFollowUp: ["Q17b_reasons"], skipTo: nil),
            ASAMQuestionOption(id: "side_effects", text: "Caused problematic side effects", value: "side_effects", riskLevel: 2, triggersFollowUp: ["Q17b_side_effects"], skipTo: nil),
            ASAMQuestionOption(id: "dose_issues", text: "Had dose adjustment difficulties", value: "dose_issues", riskLevel: 1, triggersFollowUp: ["Q17b_dose_details"], skipTo: nil)
        ]
        
        let skipLogic = [
            ASAMSkipCondition(
                dependsOn: "Q17",
                condition: .equals,
                value: .string("no"),
                action: .skip
            )
        ]
        
        return ASAMQuestion(
            id: "Q17b",
            questionNumber: "Q17b",
            text: "How has the medication worked for you?",
            helpText: "Consider effectiveness on cravings, withdrawal symptoms, and any dose-adjustment difficulties.",
            type: .multipleChoice,
            options: options,
            validation: ASAMQuestionValidation(required: false, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: skipLogic,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 1.0, category: .moderate, v3SeverityContribution: nil, v4RiskContribution: "B"),
            isRequired: false,
            dimensionId: 1,
            subdimensionId: "D1_medication"
        )
    }
    
    private static func buildInterviewerAssessmentQuestion() -> ASAMQuestion {
        let options = [
            ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 4, triggersFollowUp: ["Q18_rationale"], skipTo: nil),
            ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: nil)
        ]
        
        return ASAMQuestion(
            id: "Q18",
            questionNumber: "Q18",
            text: "Do you think the patient needs medically managed care for intoxication, withdrawal, or addiction medication initiation/titration?",
            helpText: "Interviewer assessment based on all D1 responses. Provide rationale if yes.",
            type: .interviewerObservation,
            options: options,
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .severe, v3SeverityContribution: nil, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 1,
            subdimensionId: nil
        )
    }
}