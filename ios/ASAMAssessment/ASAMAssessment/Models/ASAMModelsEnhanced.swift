//
//  ASAMModelsEnhanced.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Traceability

/// Traceability information for questions
struct ASAMQuestionTraceability: Codable {
    let formSection: String        // e.g., "Dimension 1, Page 2"
    let formPageNumber: Int?       // Page number in ASAM PDF
    let exactFormText: String?     // Exact text from form (licensed mode only)
    let neutralText: String?       // Paraphrased text for neutral mode
    let appFieldId: String         // App control ID
    let source: ASAMFieldSource    // Where this question comes from
    let complianceNotes: String?   // Special compliance considerations
}

// MARK: - Enhanced Substance Models

/// Substance profile matching official ASAM form structure exactly
struct ASAMEnhancedSubstanceProfile: Codable, Identifiable {
    let id: UUID
    let substance: ASAMSubstanceType
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
    
    // Alcohol specific fields (conditional)
    let averageDrinksPerDay: Double?  // for alcohol only
    let bingeFrequency: String?  // "In the last 30 days, how often have you had [4+/5+ drinks] on one occasion?"
    
    // Prescription misuse (for rx substances only)
    let hasValidPrescription: Bool?  // "Valid prescription? yes/no"
    
    // Additional tracking
    let source: ASAMFieldSource
    let complianceMode: ASAMComplianceMode
    
    init(substance: ASAMSubstanceType, complianceMode: ASAMComplianceMode = .licensed) {
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
        self.source = .asamForm
        self.complianceMode = complianceMode
    }
}

/// Substance types from official ASAM form
enum ASAMSubstanceType: String, CaseIterable, Codable {
    case alcohol = "alcohol"
    case heroinFentanylOtherNonRxOpioids = "heroin_fentanyl_other_non_rx_opioids"
    case prescriptionOpioids = "prescription_opioids"
    case benzodiazepines = "benzodiazepines"
    case stimulants = "stimulants"
    case cannabis = "cannabis"
    case nicotine = "nicotine"
    case other1 = "other_1"
    case other2 = "other_2"
    case other3 = "other_3"
    
    var displayName: String {
        switch self {
        case .alcohol: return "Alcohol"
        case .heroinFentanylOtherNonRxOpioids: return "Heroin/Fentanyl/Other Non-Prescription Opioids"
        case .prescriptionOpioids: return "Prescription Opioids"
        case .benzodiazepines: return "Benzodiazepines"
        case .stimulants: return "Stimulants"
        case .cannabis: return "Cannabis"
        case .nicotine: return "Nicotine"
        case .other1: return "Other Drug #1"
        case .other2: return "Other Drug #2"
        case .other3: return "Other Drug #3"
        }
    }
    
    var neutralDisplayName: String {
        switch self {
        case .alcohol: return "Substance A"
        case .heroinFentanylOtherNonRxOpioids: return "Substance B"
        case .prescriptionOpioids: return "Substance C"
        case .benzodiazepines: return "Substance D"
        case .stimulants: return "Substance E"
        case .cannabis: return "Substance F"
        case .nicotine: return "Substance G"
        case .other1: return "Substance H"
        case .other2: return "Substance I"
        case .other3: return "Substance J"
        }
    }
    
    var isAlcohol: Bool {
        return self == .alcohol
    }
    
    var requiresValidPrescriptionField: Bool {
        switch self {
        case .prescriptionOpioids, .benzodiazepines:
            return true
        default:
            return false
        }
    }
    
    var supportsAlcoholSpecificFields: Bool {
        return self == .alcohol
    }
}

// MARK: - Dimension 3 Enhanced Models

/// Mental health symptom assessment matching ASAM form
struct ASAMDimension3Symptom: Codable {
    let id: String
    let category: ASAMSymptomCategory
    let symptomText: String
    let presentPast30Days: Bool
    let onlyWhenUsingOrWithdrawing: Bool  // Critical ASAM form field
    let notes: String?
}

enum ASAMSymptomCategory: String, CaseIterable, Codable {
    case mood = "mood"
    case anxiety = "anxiety"  
    case psychosis = "psychosis"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .mood: return "Mood"
        case .anxiety: return "Anxiety"
        case .psychosis: return "Psychosis"
        case .other: return "Other"
        }
    }
}

/// Suicide risk assessment with discrete fields matching ASAM form exactly
struct ASAMSuicideRiskAssessment: Codable {
    let thoughtsOfHurtingSelf: Bool
    let thoughtsBetterOffDead: Bool
    let description: String?
    
    // Sub-questions with discrete fields as required
    let havingThoughtsToday: Bool?      // "Are you having these thoughts today?"
    let everActedOnFeelings: Bool?      // "Have you ever acted on these feelings to hurt yourself?"
    
    let assessedAt: Date
    let assessedBy: String?
}

/// Violence risk assessment with discrete fields matching ASAM form exactly
struct ASAMViolenceRiskAssessment: Codable {
    let thoughtsOfHarmingOthers: Bool
    let description: String?
    
    // Sub-questions with discrete fields
    let havingThoughtsToday: Bool?      // "Are you having these thoughts today?"
    let everActedOnFeelings: Bool?      // "Have you ever acted on these feelings to harm others?"
    
    let assessedAt: Date
    let assessedBy: String?
}

// MARK: - Enhanced Question Models

/// Enhanced question with full traceability and compliance
struct ASAMEnhancedQuestion: Codable, Identifiable {
    let id: String
    let questionNumber: String?
    
    // Compliance-aware text
    let licensedText: String        // Exact ASAM form text
    let neutralText: String         // Paraphrased for neutral mode
    let helpText: String?
    
    let type: ASAMQuestionType
    let options: [ASAMQuestionOption]?
    let validation: ASAMQuestionValidation?
    let skipLogic: [ASAMSkipCondition]?
    let followUpQuestions: [String]?
    let riskWeighting: ASAMRiskWeighting?
    let isRequired: Bool
    let dimensionId: Int
    let subdimensionId: String?
    
    // Traceability and compliance
    let traceability: ASAMQuestionTraceability
    
    /// Get text appropriate for compliance mode
    func getText(for mode: ASAMComplianceMode) -> String {
        switch mode {
        case .licensed: return licensedText
        case .neutral: return neutralText
        }
    }
    
    /// Check if this question should be shown in given compliance mode
    func shouldShow(in mode: ASAMComplianceMode) -> Bool {
        switch traceability.source {
        case .asamForm: return true  // Always show official content
        case .clinicAdded, .systemAdded: 
            return mode == .licensed  // Only show extensions in licensed mode
        }
    }
}

// MARK: - Configuration and Settings

/// Global configuration for ASAM implementation
struct ASAMImplementationConfig: Codable {
    let complianceMode: ASAMComplianceMode
    let enableExtensionFields: Bool  // Show clinic-added fields
    let rulesHash: String?          // For licensed mode validation
    let legalVersion: String?       // Legal compliance version
    let lastUpdated: Date
    
    static let `default` = ASAMImplementationConfig(
        complianceMode: .neutral,
        enableExtensionFields: false,
        rulesHash: nil,
        legalVersion: nil,
        lastUpdated: Date()
    )
}

// MARK: - Quality Assurance Helpers

/// Quality check results for implementation compliance
struct ASAMQualityCheckResult: Codable {
    let passesComplianceCheck: Bool
    let issues: [ASAMQualityIssue]
    let checkedAt: Date
    let checkedBy: String?
}

struct ASAMQualityIssue: Codable {
    let severity: ASAMIssueSeverity
    let category: String
    let description: String
    let fieldId: String?
    let recommendation: String
}

enum ASAMIssueSeverity: String, CaseIterable, Codable {
    case critical = "critical"      // Blocks compliance
    case major = "major"           // Significant alignment issue
    case minor = "minor"           // Cosmetic or minor drift
    case suggestion = "suggestion"  // Improvement opportunity
}