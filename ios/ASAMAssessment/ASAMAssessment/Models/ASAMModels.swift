//
//  ASAMModels.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Compliance and Mode Configuration

/// Compliance modes for ASAM implementation
enum ASAMComplianceMode: String, CaseIterable, Codable {
    case licensed = "licensed"      // Full ASAM text, marks, official templates
    case neutral = "neutral"        // Generic labels, no ASAM marks, paraphrased content
    
    var displayName: String {
        switch self {
        case .licensed: return "Licensed ASAM Implementation"
        case .neutral: return "Internal Neutral Mode"
        }
    }
}

/// Field source tracking for traceability
enum ASAMFieldSource: String, Codable {
    case asamForm = "asam_form"           // From official ASAM assessment form
    case clinicAdded = "clinic_added"     // Added by clinic (not in ASAM form)
    case systemAdded = "system_added"     // System convenience field
    
    var displayTag: String {
        switch self {
        case .asamForm: return ""  // No tag needed - official content
        case .clinicAdded: return "Clinic-added (not in ASAM form)"
        case .systemAdded: return "System field"
        }
    }
}

/// Represents the version of ASAM criteria being used
enum ASAMVersion: String, CaseIterable, Codable {
    case v3_2013 = "v3_2013"  // Assessment form, 0-4 severity
    case v4_2024 = "v4_2024"  // Level-of-care, A-E risk ratings
    
    var displayName: String {
        switch self {
        case .v3_2013:
            return "ASAM v3 (2013) - Assessment Form"
        case .v4_2024:
            return "ASAM v4 (2024) - Level of Care"
        }
    }
    
    var shortName: String {
        switch self {
        case .v3_2013: return "v3"
        case .v4_2024: return "v4"
        }
    }
}

/// Main ASAM Assessment container
struct ASAMAssessment: Codable, Identifiable {
    let id: UUID
    let patientId: String
    let version: ASAMVersion
    var dimensions: [ASAMDimension]  // Mutable
    var overallScore: ASAMOverallScore?  // Mutable
    var recommendations: [String]  // Mutable
    let createdAt: Date
    var completedAt: Date?  // Mutable
    var lastModified: Date  // Mutable
    
    init(patientId: String, version: ASAMVersion) {
        self.id = UUID()
        self.patientId = patientId
        self.version = version
        self.dimensions = ASAMDimension.defaultDimensions(for: version)
        self.overallScore = nil
        self.recommendations = []
        self.createdAt = Date()
        self.completedAt = nil
        self.lastModified = Date()
    }
}

/// ASAM dimension (1-6 for both v3 and v4)
struct ASAMDimension: Codable, Identifiable {
    let id: Int // 1-6
    let name: String
    let shortName: String
    let subdimensions: [ASAMSubdimension]?  // v4 only
    let questions: [ASAMQuestion]
    let score: ASAMDimensionScore?
    let isRequired: Bool
    
    static func defaultDimensions(for version: ASAMVersion) -> [ASAMDimension] {
        switch version {
        case .v3_2013:
            return [
                ASAMDimension(id: 1, name: "Acute Intoxication & Withdrawal Potential", shortName: "D1", subdimensions: nil, questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 2, name: "Biomedical Conditions & Complications", shortName: "D2", subdimensions: nil, questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 3, name: "Emotional, Behavioral, or Cognitive Conditions", shortName: "D3", subdimensions: nil, questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 4, name: "Readiness to Change", shortName: "D4", subdimensions: nil, questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 5, name: "Relapse, Continued Use, or Continued Problem Potential", shortName: "D5", subdimensions: nil, questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 6, name: "Recovery/Living Environment", shortName: "D6", subdimensions: nil, questions: [], score: nil, isRequired: true)
            ]
        case .v4_2024:
            return [
                ASAMDimension(id: 1, name: "Acute Intoxication, Withdrawal & Addiction Medication Needs", shortName: "D1", 
                            subdimensions: [
                                ASAMSubdimension(id: "D1_intox", name: "Intoxication", questions: []),
                                ASAMSubdimension(id: "D1_withdrawal", name: "Withdrawal", questions: []),
                                ASAMSubdimension(id: "D1_medication", name: "Addiction Medication", questions: [])
                            ], questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 2, name: "Biomedical Conditions", shortName: "D2", subdimensions: nil, questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 3, name: "Emotional, Behavioral, or Cognitive Conditions", shortName: "D3",
                            subdimensions: [
                                ASAMSubdimension(id: "D3_acute", name: "Acute Psychiatric Symptoms", questions: []),
                                ASAMSubdimension(id: "D3_persistent", name: "Persistent Disability", questions: [])
                            ], questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 4, name: "Readiness/Imminent Risk of Use", shortName: "D4", subdimensions: nil, questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 5, name: "Recovery Environment", shortName: "D5", subdimensions: nil, questions: [], score: nil, isRequired: true),
                ASAMDimension(id: 6, name: "Continued Use/Relapse Potential", shortName: "D6", subdimensions: nil, questions: [], score: nil, isRequired: false) // v4 combines this differently
            ]
        }
    }
}

/// Subdimension for ASAM v4 (more granular assessment areas)
struct ASAMSubdimension: Codable, Identifiable {
    let id: String
    let name: String
    let questions: [ASAMQuestion]
    
    init(id: String, name: String, questions: [ASAMQuestion]) {
        self.id = id
        self.name = name
        self.questions = questions
    }
}

// MARK: - Question Models with Skip Logic

/// Enhanced question model with skip logic and conditional branching
struct ASAMQuestion: Codable, Identifiable {
    let id: String  // e.g., "Q11", "Q12", "D1_substance_inventory"
    let questionNumber: String?  // v4 uses "Q11", v3 might use "1.1"
    let text: String
    let helpText: String?
    let type: ASAMQuestionType
    let options: [ASAMQuestionOption]?
    let validation: ASAMQuestionValidation?
    let skipLogic: [ASAMSkipCondition]?
    let followUpQuestions: [String]?  // Question IDs triggered by specific answers
    let riskWeighting: ASAMRiskWeighting?
    let isRequired: Bool
    let dimensionId: Int
    let subdimensionId: String?
}

// Convenience initializer for simple questions
extension ASAMQuestion {
    init(id: String, questionNumber: String? = nil, text: String, type: ASAMQuestionType, 
         dimensionId: Int, subdimensionId: String? = nil, isRequired: Bool = true) {
        self.id = id
        self.questionNumber = questionNumber
        self.text = text
        self.helpText = nil
        self.type = type
        self.options = nil
        self.validation = nil
        self.skipLogic = nil
        self.followUpQuestions = nil
        self.riskWeighting = nil
        self.isRequired = isRequired
        self.dimensionId = dimensionId
        self.subdimensionId = subdimensionId
    }
}

/// Question types supporting both ASAM v3 and v4
enum ASAMQuestionType: String, Codable {
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case text = "text"
    case number = "number"
    case date = "date"
    case dateTime = "date_time"
    case scale = "scale"  // e.g., "Not at all" to "Extremely"
    case boolean = "boolean"
    case substanceInventory = "substance_inventory"  // Special compound question for D1
    case clinicalScale = "clinical_scale"  // CIWA, COWS, etc.
    case interviewerObservation = "interviewer_observation"
    case medicationList = "medication_list"
    case followUpConditional = "follow_up_conditional"  // Conditional based on previous answer
}

/// Question options for choice-based questions
struct ASAMQuestionOption: Codable, Identifiable {
    let id: String
    let text: String
    let value: String
    let riskLevel: Int?  // 0-4 for scoring
    let triggersFollowUp: [String]?  // Question IDs to show if this option is selected
    let skipTo: String?  // Question ID to skip to if this option is selected
}

/// Question validation rules
struct ASAMQuestionValidation: Codable {
    let required: Bool
    let minLength: Int?
    let maxLength: Int?
    let minValue: Double?
    let maxValue: Double?
    let pattern: String?  // Regex pattern
    let customMessage: String?
}

/// Skip logic conditions for complex question flow
struct ASAMSkipCondition: Codable {
    let dependsOn: String  // Previous question ID
    let condition: ASAMConditionOperator
    let value: ASAMAnswerValue
    let action: ASAMSkipAction
}

enum ASAMConditionOperator: String, Codable {
    case equals = "equals"
    case notEquals = "not_equals"
    case greaterThan = "greater_than"
    case lessThan = "less_than"
    case contains = "contains"
    case isEmpty = "is_empty"
    case isNotEmpty = "is_not_empty"
}

enum ASAMSkipAction: String, Codable {
    case skip = "skip"           // Skip this question
    case show = "show"           // Show this question
    case require = "require"     // Make this question required
    case optional = "optional"   // Make this question optional
    case jumpTo = "jump_to"      // Jump to specific question ID
}

/// Risk weighting for scoring calculations
struct ASAMRiskWeighting: Codable {
    let weight: Double
    let category: ASAMRiskCategory
    let v3SeverityContribution: Int?  // 0-4 contribution to dimension severity
    let v4RiskContribution: String?   // A-E contribution to risk rating
}

enum ASAMRiskCategory: String, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case severe = "severe"
}

// MARK: - Answer Models

/// Universal answer value supporting all question types
enum ASAMAnswerValue: Codable, Equatable {
    case string(String)
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case date(Date)
    case array([String])
    case substanceProfile(ASAMSubstanceProfile)
    case clinicalScale(ASAMClinicalScale)
    case null
    
    var stringValue: String {
        switch self {
        case .string(let value): return value
        case .integer(let value): return "\(value)"
        case .double(let value): return "\(value)"
        case .boolean(let value): return value ? "true" : "false"
        case .date(let value): return ISO8601DateFormatter().string(from: value)
        case .array(let values): return values.joined(separator: ", ")
        case .substanceProfile(let profile): return profile.substance
        case .clinicalScale(let scale): return "\(scale.name): \(scale.score)"
        case .null: return ""
        }
    }
}

/// Substance profile matching official ASAM form structure
struct ASAMSubstanceProfile: Codable, Identifiable, Equatable {
    let id: UUID
    let substance: String  // alcohol, heroin/fentanyl/other_non_rx_opioids, rx_opioids, benzodiazepines, stimulants, cannabis, nicotine, other
    let otherSubstanceText: String?
    
    // Duration (Years/Months estimate) - matches ASAM form
    let durationYears: Int?
    let durationMonths: Int?
    
    // Frequency in last 30 days - exact ASAM form options
    let frequencyLast30Days: ASAMFrequencyCategory
    
    // Route (checkboxes: Oral, Nasal/snort, Smoke, Inject, Other) - multi-select
    let routesOfUse: [ASAMRouteOfUse]
    
    // Date of last use
    let dateLastUse: Date?
    
    // Alcohol specific
    let averageDrinksPerDay: Double?  // for alcohol only
    let bingeFrequency: String?  // "In the last 30 days, how often have you had [4+/5+ drinks] on one occasion?"
    
    // Prescription misuse (for rx substances only)
    let hasValidPrescription: Bool?  // "Valid prescription? yes/no"
    
    init(substance: String) {
        self.id = UUID()
        self.substance = substance
        self.otherSubstanceText = nil
        self.durationYears = nil
        self.durationMonths = nil
        self.frequencyLast30Days = .neverUsed
        self.routesOfUse = []
        self.dateLastUse = nil
        self.averageDrinksPerDay = nil
        self.bingeFrequency = nil
        self.hasValidPrescription = nil
    }
}

/// Frequency categories matching ASAM form exactly
enum ASAMFrequencyCategory: String, CaseIterable, Codable {
    case fourToSevenDaysPerWeek = "4-7_days_week"
    case oneToThreeDaysPerWeek = "1-3_days_week" 
    case threeDaysOrLessPerMonth = "3_or_less_days_month"
    case notUsed = "not_used"
    case neverUsed = "never_used"
    
    var displayName: String {
        switch self {
        case .fourToSevenDaysPerWeek: return "4-7 days/week"
        case .oneToThreeDaysPerWeek: return "1-3 days/week"
        case .threeDaysOrLessPerMonth: return "3 or less days/month"
        case .notUsed: return "Not used"
        case .neverUsed: return "Never Used"
        }
    }
    
    var riskLevel: Int {
        switch self {
        case .fourToSevenDaysPerWeek: return 4
        case .oneToThreeDaysPerWeek: return 3
        case .threeDaysOrLessPerMonth: return 2
        case .notUsed: return 1
        case .neverUsed: return 0
        }
    }
}

/// Route of use options matching ASAM form exactly
enum ASAMRouteOfUse: String, CaseIterable, Codable {
    case oral = "oral"
    case nasal = "nasal_snort"  // "Nasal/snort"
    case smoke = "smoke"
    case inject = "inject"
    case other = "other"  // "Other [rectal, patches, etc.]"
    
    var displayName: String {
        switch self {
        case .oral: return "Oral"
        case .nasal: return "Nasal/snort"
        case .smoke: return "Smoke"
        case .inject: return "Inject"
        case .other: return "Other (rectal, patches, etc.)"
        }
    }
    
    var riskLevel: Int {
        switch self {
        case .inject: return 4
        case .smoke: return 3
        case .nasal: return 2
        case .oral: return 1
        case .other: return 1
        }
    }
}

/// Clinical scale scores (CIWA, COWS, etc.)
struct ASAMClinicalScale: Codable, Equatable {
    let name: String  // "CIWA-Ar", "COWS"
    let score: Int
    let maxScore: Int
    let administeredAt: Date
    let administeredBy: String?
    let interpretation: String?  // "Mild", "Moderate", "Severe"
}

// MARK: - Scoring Models

/// Overall assessment scoring supporting both v3 and v4
struct ASAMOverallScore: Codable {
    let version: ASAMVersion
    let v3Scores: ASAMv3OverallScore?
    let v4Scores: ASAMv4OverallScore?
    let calculatedAt: Date
    let calculatedBy: String?
}

/// ASAM v3 scoring (0-4 severity per dimension)
struct ASAMv3OverallScore: Codable {
    let dimensionSeverities: [Int: Int]  // Dimension ID -> Severity (0-4)
    let overallSeverity: Int  // Highest dimension severity
    let recommendedLevel: String?
    let clinicalNotes: String?
}

/// ASAM v4 scoring (A-E risk ratings and level-of-care determination)
struct ASAMv4OverallScore: Codable {
    let dimensionRiskRatings: [Int: String]  // Dimension ID -> Risk Rating (A-E)
    let levelOfCare: ASAMLevelOfCare
    let subdimensionScores: [String: ASAMSubdimensionScore]?
    let clinicalRationale: String?
}

/// Individual dimension scoring
struct ASAMDimensionScore: Codable {
    let dimensionId: Int
    let version: ASAMVersion
    let v3Severity: Int?  // 0-4
    let v4RiskRating: String?  // A-E
    let subdimensionScores: [ASAMSubdimensionScore]?
    let clinicalJustification: String?
    let scoredAt: Date
}

/// Subdimension scoring for v4
struct ASAMSubdimensionScore: Codable {
    let subdimensionId: String
    let riskRating: String  // A-E
    let contributingFactors: [String]
    let clinicalNotes: String?
}

/// Level of care recommendations for ASAM v4
enum ASAMLevelOfCare: String, CaseIterable, Codable {
    case level_1_0 = "1.0"  // Outpatient Services
    case level_2_1 = "2.1"  // Intensive Outpatient
    case level_2_5 = "2.5"  // Partial Hospitalization
    case level_3_1 = "3.1"  // Clinically Managed Low-Intensity Residential
    case level_3_3 = "3.3"  // Clinically Managed Population-Specific High-Intensity Residential
    case level_3_5 = "3.5"  // Clinically Managed High-Intensity Residential
    case level_3_7 = "3.7"  // Medically Monitored Intensive Inpatient
    case level_4_0 = "4.0"  // Medically Managed Intensive Inpatient
    
    var displayName: String {
        switch self {
        case .level_1_0: return "1.0 - Outpatient Services"
        case .level_2_1: return "2.1 - Intensive Outpatient"
        case .level_2_5: return "2.5 - Partial Hospitalization"
        case .level_3_1: return "3.1 - Clinically Managed Low-Intensity Residential"
        case .level_3_3: return "3.3 - Clinically Managed Population-Specific High-Intensity Residential"
        case .level_3_5: return "3.5 - Clinically Managed High-Intensity Residential"
        case .level_3_7: return "3.7 - Medically Monitored Intensive Inpatient"
        case .level_4_0: return "4.0 - Medically Managed Intensive Inpatient"
        }
    }
    
    var description: String {
        switch self {
        case .level_1_0: return "Outpatient treatment suitable for motivated patients with stable environment"
        case .level_2_1: return "Intensive outpatient treatment 9+ hours/week, multiple days"
        case .level_2_5: return "Day treatment program, returning home evenings"
        case .level_3_1: return "Residential treatment with lower intensity clinical services"
        case .level_3_3: return "Residential treatment for special populations (adolescents, women with children)"
        case .level_3_5: return "High-intensity residential treatment with 24-hour structured programming"
        case .level_3_7: return "Medically monitored residential treatment with nursing care available"
        case .level_4_0: return "Medically managed intensive inpatient treatment in hospital setting"
        }
    }
}

// MARK: - Assessment Response Model

/// Complete assessment response containing all answers
struct ASAMAssessmentResponse: Codable, Identifiable {
    let id: UUID
    let assessmentId: UUID
    let patientId: String
    var answers: [String: ASAMAnswerValue]  // Question ID -> Answer (mutable)
    var substanceProfiles: [ASAMSubstanceProfile]  // Mutable
    var clinicalScales: [ASAMClinicalScale]  // Mutable
    let interviewerNotes: [String: String]  // Question ID -> Notes
    var isComplete: Bool  // Mutable
    var completionPercentage: Double  // Mutable
    var lastAnsweredQuestion: String?  // Mutable
    let createdAt: Date
    var lastModified: Date  // Mutable
    
    init(assessmentId: UUID, patientId: String) {
        self.id = UUID()
        self.assessmentId = assessmentId
        self.patientId = patientId
        self.answers = [:]
        self.substanceProfiles = []
        self.clinicalScales = []
        self.interviewerNotes = [:]
        self.isComplete = false
        self.completionPercentage = 0.0
        self.lastAnsweredQuestion = nil
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    /// Get answer for specific question
    func getAnswer(for questionId: String) -> ASAMAnswerValue? {
        return answers[questionId]
    }
    
    /// Check if question has been answered
    func hasAnswer(for questionId: String) -> Bool {
        return answers[questionId] != nil
    }
    
    /// Get substance profile for specific substance
    func getSubstanceProfile(for substance: String) -> ASAMSubstanceProfile? {
        return substanceProfiles.first { $0.substance == substance }
    }
    
    /// Get clinical scale by name
    func getClinicalScale(named name: String) -> ASAMClinicalScale? {
        return clinicalScales.first { $0.name == name }
    }
}

// MARK: - Extensions for Convenience

extension ASAMDimension {
    /// Get all questions including subdimension questions
    var allQuestions: [ASAMQuestion] {
        var allQuestions = questions
        if let subdimensions = subdimensions {
            for subdimension in subdimensions {
                allQuestions.append(contentsOf: subdimension.questions)
            }
        }
        return allQuestions
    }
    
    /// Get question by ID
    func getQuestion(by id: String) -> ASAMQuestion? {
        return allQuestions.first { $0.id == id }
    }
}

extension ASAMAssessment {
    /// Get dimension by ID
    func getDimension(by id: Int) -> ASAMDimension? {
        return dimensions.first { $0.id == id }
    }
    
    /// Get question by ID across all dimensions
    func getQuestion(by id: String) -> ASAMQuestion? {
        for dimension in dimensions {
            if let question = dimension.getQuestion(by: id) {
                return question
            }
        }
        return nil
    }
    
    /// Check if assessment is complete
    var isComplete: Bool {
        return completedAt != nil
    }
    
    /// Calculate completion percentage
    func completionPercentage(response: ASAMAssessmentResponse) -> Double {
        let allQuestions = dimensions.flatMap { $0.allQuestions }
        let requiredQuestions = allQuestions.filter { $0.isRequired }
        
        guard !requiredQuestions.isEmpty else { return 0.0 }
        
        let answeredRequired = requiredQuestions.filter { question in
            response.hasAnswer(for: question.id)
        }
        
        return Double(answeredRequired.count) / Double(requiredQuestions.count)
    }
}