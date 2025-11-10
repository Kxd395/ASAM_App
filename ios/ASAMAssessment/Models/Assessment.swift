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
struct Assessment: Identifiable, Codable {
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
        self.validationGates = ValidationGate.allGates()
    }
}

/// Assessment status enum
enum AssessmentStatus: String, Codable, CaseIterable {
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
struct Domain: Identifiable, Codable {
    let id: UUID
    let number: Int  // 1-6
    let title: String
    var severity: Int  // 0-4 (0=none, 4=extreme)
    var notes: String
    var isComplete: Bool

    static func allDomains() -> [Domain] {
        [
            Domain(id: UUID(), number: 1, title: "Acute Intoxication/Withdrawal", severity: 0, notes: "", isComplete: false),
            Domain(id: UUID(), number: 2, title: "Biomedical Conditions", severity: 0, notes: "", isComplete: false),
            Domain(id: UUID(), number: 3, title: "Emotional/Behavioral Conditions", severity: 0, notes: "", isComplete: false),
            Domain(id: UUID(), number: 4, title: "Readiness to Change", severity: 0, notes: "", isComplete: false),
            Domain(id: UUID(), number: 5, title: "Relapse/Continued Use", severity: 0, notes: "", isComplete: false),
            Domain(id: UUID(), number: 6, title: "Recovery Environment", severity: 0, notes: "", isComplete: false)
        ]
    }
}

/// Problem - clinical problem identified during assessment
struct Problem: Identifiable, Codable {
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

enum ProblemSeverity: String, Codable, CaseIterable {
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
struct LOCRecommendation: Codable {
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
struct ValidationGate: Identifiable, Codable {
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
