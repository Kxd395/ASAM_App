//
//  Assessment.swift
//  ASAM Assessment Application
//
//  HIPAA Compliant Data Model
//  No PHI in logs or exports without explicit consent
//

import Foundation
import SwiftUI

/// Main assessment entity - represents a single ASAM assessment session
struct Assessment: Identifiable, Codable, Hashable {
    let id: UUID
    var createdAt: Date
    var updatedAt: Date
    var status: AssessmentStatus

    // Metadata (NO PHI)
    var assessorId: String  // Opaque ID, not name
    var facilityId: String  // Opaque ID, not name
    var sessionId: String   // For audit trail

    // Assessment Data
    var domains: [Domain]
    var problems: [Problem]
    var locRecommendation: LOCRecommendation?

    // Domain 1 Substance Context
    var substances: [SubstanceRow]

    // Clinical Flags
    var vitalsUnstable: Bool
    var pregnant: Bool
    var noWithdrawalSigns: Bool
    var acutePsych: Bool

    // Validation state
    var validationGates: [ValidationGate]
    var isComplete: Bool {
        validationGates.allSatisfy { $0.isPassed }
    }

    init(id: UUID = UUID()) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = .draft
        self.assessorId = ""
        self.facilityId = ""
        self.sessionId = UUID().uuidString
        self.domains = Domain.allDomains()
        self.problems = []
        self.locRecommendation = nil
        self.substances = []
        self.vitalsUnstable = false
        self.pregnant = false
        self.noWithdrawalSigns = false
        self.acutePsych = false
        self.validationGates = ValidationGate.allGates()
    }
    
    // MARK: - Progress Tracking (Fix for field removal issue)
    
    /// Calculate overall assessment progress
    /// Returns value between 0.0 and 1.0
    func calculateOverallProgress() -> Double {
        guard !domains.isEmpty else { return 0.0 }
        
        let domainProgresses = domains.map { $0.calculateProgress() }
        let totalProgress = domainProgresses.reduce(0, +) / Double(domains.count)
        
        print("📊 Overall assessment progress: \(String(format: "%.0f%%", totalProgress * 100))")
        print("📊 Domain breakdown: \(domains.map { "D\($0.number): \($0.completionPercentage)%" }.joined(separator: ", "))")
        
        return totalProgress
    }
    
    /// Get completion percentage (0-100)
    var completionPercentage: Int {
        Int(calculateOverallProgress() * 100)
    }
    
    /// Get number of completed domains
    var completedDomainsCount: Int {
        domains.filter { $0.isComplete }.count
    }
    
    /// Get number of domains with any answers
    var startedDomainsCount: Int {
        domains.filter { !$0.answers.isEmpty }.count
    }
}

/// Assessment status enum
enum AssessmentStatus: String, Codable, CaseIterable, Hashable {
    case draft = "Draft"
    case inProgress = "In Progress"
    case review = "Under Review"
    case complete = "Complete"
    case archived = "Archived"

    var color: Color {
        switch self {
        case .draft: return .gray
        case .inProgress: return .blue
        case .review: return .orange
        case .complete: return .green
        case .archived: return .secondary
        }
    }

    var icon: String {
        switch self {
        case .draft: return "doc"
        case .inProgress: return "pencil.circle"
        case .review: return "eye"
        case .complete: return "checkmark.circle"
        case .archived: return "archivebox"
        }
    }
}

/// Domain represents one of the 6 ASAM dimensions
struct Domain: Identifiable, Codable, Hashable {
    let id: UUID
    let number: Int  // 1-6
    let title: String
    var severity: Int  // 0-4 (0=none, 4=extreme)
    var notes: String
    var isComplete: Bool
    var answers: [String: AnswerValue]  // Store questionnaire answers

    static func allDomains() -> [Domain] {
        [
            Domain(id: UUID(), number: 1, title: "Acute Intoxication/Withdrawal", severity: 0, notes: "", isComplete: false, answers: [:]),
            Domain(id: UUID(), number: 2, title: "Biomedical Conditions", severity: 0, notes: "", isComplete: false, answers: [:]),
            Domain(id: UUID(), number: 3, title: "Emotional/Behavioral Conditions", severity: 0, notes: "", isComplete: false, answers: [:]),
            Domain(id: UUID(), number: 4, title: "Readiness to Change", severity: 0, notes: "", isComplete: false, answers: [:]),
            Domain(id: UUID(), number: 5, title: "Relapse/Continued Use", severity: 0, notes: "", isComplete: false, answers: [:]),
            Domain(id: UUID(), number: 6, title: "Recovery Environment", severity: 0, notes: "", isComplete: false, answers: [:])
        ]
    }
    
    // MARK: - Progress Tracking (Fix for field removal issue)
    
    /// Calculate completion progress for this domain
    /// Returns value between 0.0 and 1.0
    func calculateProgress() -> Double {
        guard !answers.isEmpty else { return 0.0 }
        
        // Count non-empty answers
        let validAnswers = answers.filter { _, value in
            switch value {
            case .none:
                return false
            case .text(let str):
                return !str.isEmpty
            case .number(_), .bool(_), .single(_), .multi(_), .substanceGrid(_):
                return true
            }
        }
        
        // For now, use a simple ratio
        // TODO: Integrate with questionnaire to get total required questions
        let progress = Double(validAnswers.count) / Double(max(answers.count, 1))
        
        print("📊 Domain \(number) progress: \(validAnswers.count)/\(answers.count) = \(String(format: "%.0f%%", progress * 100))")
        
        return progress
    }
    
    /// Calculate completion percentage (0-100)
    var completionPercentage: Int {
        Int(calculateProgress() * 100)
    }
}

/// Problem - clinical problem identified during assessment
struct Problem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var severity: ProblemSeverity
    var relatedDomains: [Int]  // Domain numbers
    var createdAt: Date

    init(id: UUID = UUID(), title: String, description: String, severity: ProblemSeverity, relatedDomains: [Int]) {
        self.id = id
        self.title = title
        self.description = description
        self.severity = severity
        self.relatedDomains = relatedDomains
        self.createdAt = Date()
    }
}

enum ProblemSeverity: String, Codable, CaseIterable, Hashable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case extreme = "Extreme"

    var color: Color {
        switch self {
        case .mild: return .green
        case .moderate: return .yellow
        case .severe: return .orange
        case .extreme: return .red
        }
    }
}

/// LOC Recommendation - Level of Care recommendation
struct LOCRecommendation: Codable, Hashable {
    let code: String  // e.g., "RES-WM" from neutral taxonomy
    let name: String  // e.g., "Level 3.7-WM"
    let confidence: Double  // 0.0-1.0
    let reasoning: [String]  // Decision trace for "Why?" explainability
    let generatedAt: Date

    init(code: String, name: String, confidence: Double, reasoning: [String]) {
        self.code = code
        self.name = name
        self.confidence = confidence
        self.reasoning = reasoning
        self.generatedAt = Date()
    }
}

/// Validation Gate - ensures assessment completeness
struct ValidationGate: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    var isPassed: Bool
    var errorMessage: String?

    static func allGates() -> [ValidationGate] {
        [
            ValidationGate(id: UUID(), title: "All Domains Assessed", description: "All 6 dimensions must be evaluated", isPassed: false, errorMessage: nil),
            ValidationGate(id: UUID(), title: "Clinical Problems Documented", description: "At least one problem must be identified", isPassed: false, errorMessage: nil),
            ValidationGate(id: UUID(), title: "LOC Recommendation Generated", description: "Level of care must be calculated", isPassed: false, errorMessage: nil),
            ValidationGate(id: UUID(), title: "Safety Review Completed", description: "Safety banner must be addressed", isPassed: false, errorMessage: nil)
        ]
    }
}

// MARK: - Rules Engine Integration
extension Assessment {
    /// Convert domains array to dictionary for rules engine
    /// Maps domains 1-6 to A-F keys (ASAM standard)
    func domainSeverities() -> [String: Int] {
        var result: [String: Int] = [:]
        for domain in domains {
            // Map 1→A, 2→B, 3→C, 4→D, 5→E, 6→F
            let key = String(UnicodeScalar(64 + domain.number)!)
            // Strictly clamp to 0-4 range to prevent invalid input to rules engine
            result[key] = max(0, min(4, domain.severity))
        }
        return result
    }

    /// Extract Domain 1 context for substance-specific rules
    func d1Context() -> [String: Any] {
        // Convert substances array to JSON format for rules engine
        let substancesJSON = substances.map { $0.toJSON() }
        return ["substances": substancesJSON]
    }

    /// Convert assessment flags to dictionary for rules engine
    func flags() -> [String: Bool] {
        return [
            "vitals_unstable": vitalsUnstable,
            "pregnant": pregnant,
            "no_withdrawal_signs": noWithdrawalSigns,
            "acute_psych": acutePsych
        ]
    }
}
