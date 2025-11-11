//
//  ASAMDimension3Builder.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation

/// Builder for ASAM Dimension 3 with proper risk assessment structure
struct ASAMDimension3Builder {
    
    // MARK: - Dimension 3 Questions
    
    /// Build suicide risk assessment with discrete yes/no fields as required
    static func buildSuicideRiskAssessment(complianceMode: ASAMComplianceMode) -> [ASAMQuestion] {
        var questions: [ASAMQuestion] = []
        
        // Main suicide thoughts question
        let mainSuicideText = complianceMode == .licensed ? 
            "Have you had thoughts of hurting yourself? Have you had thoughts that you would be better off dead? Please describe:" :
            "Have you had thoughts of self-harm or that you would be better off dead? Please describe:"
        
        let mainSuicideQuestion = ASAMQuestion(
            id: "D3_suicide_thoughts",
            questionNumber: "3.11",
            text: mainSuicideText,
            helpText: "This is a critical safety assessment. Provide detailed response.",
            type: .text,
            options: nil,
            validation: ASAMQuestionValidation(required: true, minLength: 1, maxLength: 1000, minValue: nil, maxValue: nil, pattern: nil, customMessage: "Response required for safety assessment"),
            skipLogic: nil,
            followUpQuestions: ["D3_suicide_today", "D3_suicide_acted"],
            riskWeighting: ASAMRiskWeighting(weight: 5.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 3,
            subdimensionId: nil
        )
        questions.append(mainSuicideQuestion)
        
        // Sub-question a: Today? (discrete yes/no field as required)
        let todayText = complianceMode == .licensed ? 
            "*If yes: Are you having these thoughts today?" :
            "Are you having these thoughts today?"
        
        let todayQuestion = ASAMQuestion(
            id: "D3_suicide_today",
            questionNumber: "3.11a",
            text: todayText,
            helpText: "Critical for immediate safety assessment.",
            type: .boolean,
            options: [
                ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 5, triggersFollowUp: ["D3_suicide_plan", "D3_suicide_access"], skipTo: nil),
                ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 1, triggersFollowUp: nil, skipTo: nil)
            ],
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: [
                ASAMSkipCondition(
                    dependsOn: "D3_suicide_thoughts",
                    condition: .isEmpty,
                    value: ASAMAnswerValue.null,
                    action: .skip
                )
            ],
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 5.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 3,
            subdimensionId: nil
        )
        questions.append(todayQuestion)
        
        // Sub-question b: Ever acted? (discrete yes/no field as required)
        let actedText = complianceMode == .licensed ? 
            "Have you ever acted on these feelings to hurt yourself?" :
            "Have you ever acted on these feelings to harm yourself?"
        
        let actedQuestion = ASAMQuestion(
            id: "D3_suicide_acted",
            questionNumber: "3.11b",
            text: actedText,
            helpText: "History of suicide attempts significantly increases risk.",
            type: .boolean,
            options: [
                ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 4, triggersFollowUp: ["D3_suicide_method", "D3_suicide_when"], skipTo: nil),
                ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: nil)
            ],
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: [
                ASAMSkipCondition(
                    dependsOn: "D3_suicide_thoughts", 
                    condition: .isEmpty,
                    value: ASAMAnswerValue.null,
                    action: .skip
                )
            ],
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 4.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 3,
            subdimensionId: nil
        )
        questions.append(actedQuestion)
        
        return questions
    }
    
    /// Build violence risk assessment with discrete yes/no fields
    static func buildViolenceRiskAssessment(complianceMode: ASAMComplianceMode) -> [ASAMQuestion] {
        var questions: [ASAMQuestion] = []
        
        // Main violence thoughts question
        let mainViolenceText = complianceMode == .licensed ? 
            "Have you had thoughts of harming others? Please describe:" :
            "Have you had thoughts of harming other people? Please describe:"
        
        let mainViolenceQuestion = ASAMQuestion(
            id: "D3_violence_thoughts",
            questionNumber: "3.12",
            text: mainViolenceText,
            helpText: "Critical safety assessment for harm to others.",
            type: .text,
            options: nil,
            validation: ASAMQuestionValidation(required: true, minLength: 1, maxLength: 1000, minValue: nil, maxValue: nil, pattern: nil, customMessage: "Response required for safety assessment"),
            skipLogic: nil,
            followUpQuestions: ["D3_violence_today", "D3_violence_acted"],
            riskWeighting: ASAMRiskWeighting(weight: 5.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 3,
            subdimensionId: nil
        )
        questions.append(mainViolenceQuestion)
        
        // Sub-question a: Today? (discrete yes/no field)
        let todayText = complianceMode == .licensed ? 
            "If yes: Are you having these thoughts today?" :
            "Are you having these thoughts today?"
        
        let todayQuestion = ASAMQuestion(
            id: "D3_violence_today", 
            questionNumber: "3.12a",
            text: todayText,
            helpText: "Immediate risk assessment for violence.",
            type: .boolean,
            options: [
                ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 5, triggersFollowUp: ["D3_violence_plan", "D3_violence_target"], skipTo: nil),
                ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 1, triggersFollowUp: nil, skipTo: nil)
            ],
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: [
                ASAMSkipCondition(
                    dependsOn: "D3_violence_thoughts",
                    condition: .isEmpty,
                    value: ASAMAnswerValue.null,
                    action: .skip
                )
            ],
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 5.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 3,
            subdimensionId: nil
        )
        questions.append(todayQuestion)
        
        // Sub-question b: Ever acted? (discrete yes/no field)
        let actedText = complianceMode == .licensed ? 
            "Have you ever acted on these feelings to harm others?" :
            "Have you ever acted on these feelings to harm others?"
        
        let actedQuestion = ASAMQuestion(
            id: "D3_violence_acted",
            questionNumber: "3.12b", 
            text: actedText,
            helpText: "History of violence significantly increases risk.",
            type: .boolean,
            options: [
                ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 4, triggersFollowUp: ["D3_violence_details"], skipTo: nil),
                ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 0, triggersFollowUp: nil, skipTo: nil)
            ],
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: [
                ASAMSkipCondition(
                    dependsOn: "D3_violence_thoughts",
                    condition: .isEmpty,
                    value: ASAMAnswerValue.null,
                    action: .skip
                )
            ],
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 4.0, category: .severe, v3SeverityContribution: 4, v4RiskContribution: "E"),
            isRequired: true,
            dimensionId: 3,
            subdimensionId: nil
        )
        questions.append(actedQuestion)
        
        return questions
    }
    
    /// Build mental health symptom inventory with "only when using/withdrawing" flag
    static func buildSymptomInventoryQuestion(complianceMode: ASAMComplianceMode) -> ASAMQuestion {
        
        let licensedText = """
        I am going to read you a list of mental health symptoms and behaviors that might be concerning to some people. Can you tell me if any of these have been bothering you in the last 30 days? Also, if you have these symptoms, please let me know if they happen only when using or withdrawing from alcohol or other drug use.
        
        (Please include symptoms observed by interviewer, even if patient is not aware)
        """
        
        let neutralText = """
        Please indicate if any of these mental health symptoms have been present in the last 30 days. For each symptom you report, please indicate if it occurs only when using or withdrawing from substances.
        
        Include clinically observed symptoms even if not self-reported.
        """
        
        _ = ASAMQuestionTraceability(
            formSection: "Dimension 3, Mental Health Symptom Table",
            formPageNumber: 10,
            exactFormText: licensedText,
            neutralText: neutralText,
            appFieldId: "D3_symptom_inventory",
            source: .asamForm,
            complianceNotes: "Critical: Must include 'Only when using/withdrawing' column"
        )
        
        return ASAMQuestion(
            id: "D3_symptom_inventory",
            questionNumber: "3.8",
            text: complianceMode == .licensed ? licensedText : neutralText,
            helpText: "The 'only when using/withdrawing' distinction is critical for differential diagnosis.",
            type: .multipleChoice,
            options: buildSymptomOptions(),
            validation: ASAMQuestionValidation(required: true, minLength: nil, maxLength: nil, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: nil,
            followUpQuestions: ["D3_symptoms_substance_related"],
            riskWeighting: ASAMRiskWeighting(weight: 3.0, category: .high, v3SeverityContribution: 3, v4RiskContribution: "D"),
            isRequired: true,
            dimensionId: 3,
            subdimensionId: nil
        )
    }
    
    // MARK: - Private Helpers
    
    private static func buildSymptomOptions() -> [ASAMQuestionOption] {
        return [
            // Mood category
            ASAMQuestionOption(id: "depression_sadness", text: "Depression/Sadness", value: "depression_sadness", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "mood_swings", text: "Mood swings", value: "mood_swings", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "mania_hypomania", text: "Mania/Hypomania", value: "mania_hypomania", riskLevel: 3, triggersFollowUp: nil, skipTo: nil),
            
            // Anxiety category  
            ASAMQuestionOption(id: "anxiety", text: "Anxiety", value: "anxiety", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "panic_attacks", text: "Panic attacks", value: "panic_attacks", riskLevel: 3, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "phobias", text: "Phobias", value: "phobias", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            
            // Psychosis category
            ASAMQuestionOption(id: "paranoia", text: "Paranoia", value: "paranoia", riskLevel: 3, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "hallucinations", text: "Hallucinations", value: "hallucinations", riskLevel: 4, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "delusions", text: "Delusions", value: "delusions", riskLevel: 4, triggersFollowUp: nil, skipTo: nil),
            
            // Other
            ASAMQuestionOption(id: "sleep_problems", text: "Sleep problems", value: "sleep_problems", riskLevel: 1, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "concentration", text: "Concentration problems", value: "concentration", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "memory", text: "Memory problems", value: "memory", riskLevel: 2, triggersFollowUp: nil, skipTo: nil),
            ASAMQuestionOption(id: "none", text: "None of the above", value: "none", riskLevel: 0, triggersFollowUp: nil, skipTo: nil)
        ]
    }
    
    /// Build the critical follow-up question for substance relationship
    static func buildSubstanceRelatedSymptomsQuestion(complianceMode: ASAMComplianceMode) -> ASAMQuestion {
        
        let licensedText = "Are these issues (listed in the table above) either caused or made worse by alcohol and/or other drug use? Please describe:"
        let neutralText = "Are these mental health symptoms caused or worsened by substance use? Please describe:"
        
        return ASAMQuestion(
            id: "D3_symptoms_substance_related",
            questionNumber: "3.9",
            text: complianceMode == .licensed ? licensedText : neutralText,
            helpText: "Critical for determining if symptoms are substance-induced or co-occurring.",
            type: .text,
            options: [
                ASAMQuestionOption(id: "yes", text: "Yes", value: "yes", riskLevel: 1, triggersFollowUp: nil, skipTo: nil),
                ASAMQuestionOption(id: "no", text: "No", value: "no", riskLevel: 3, triggersFollowUp: nil, skipTo: nil),
                ASAMQuestionOption(id: "not_sure", text: "Not sure", value: "not_sure", riskLevel: 2, triggersFollowUp: nil, skipTo: nil)
            ],
            validation: ASAMQuestionValidation(required: true, minLength: 1, maxLength: 500, minValue: nil, maxValue: nil, pattern: nil, customMessage: nil),
            skipLogic: [
                ASAMSkipCondition(
                    dependsOn: "D3_symptom_inventory",
                    condition: .equals,
                    value: ASAMAnswerValue.string("none"),
                    action: .skip
                )
            ],
            followUpQuestions: nil,
            riskWeighting: ASAMRiskWeighting(weight: 2.0, category: .moderate, v3SeverityContribution: 2, v4RiskContribution: "C"),
            isRequired: true,
            dimensionId: 3,
            subdimensionId: nil
        )
    }
}

// MARK: - Dimension 3 Symptom Tracking

/// Data structure for tracking symptoms with substance relationship
struct SymptomEntry: Identifiable, Codable {
    let id: UUID
    let symptom: String
    let category: ASAMSymptomCategory
    let presentPast30Days: Bool
    let onlyWhenUsingOrWithdrawing: Bool  // Critical ASAM form field
    let notes: String?
    let observedByInterviewer: Bool  // Even if patient not aware
    
    init(symptom: String, category: ASAMSymptomCategory) {
        self.id = UUID()
        self.symptom = symptom
        self.category = category
        self.presentPast30Days = false
        self.onlyWhenUsingOrWithdrawing = false
        self.notes = nil
        self.observedByInterviewer = false
    }
    
    /// Calculate risk contribution
    var riskContribution: Int {
        var risk = 0
        
        if presentPast30Days {
            risk += category == .psychosis ? 3 : 2
        }
        
        // If only when using/withdrawing, lower risk for ongoing MH needs
        if onlyWhenUsingOrWithdrawing {
            risk = max(0, risk - 1)
        }
        
        // Observed symptoms may be more severe if patient unaware
        if observedByInterviewer && !presentPast30Days {
            risk += 1
        }
        
        return risk
    }
}