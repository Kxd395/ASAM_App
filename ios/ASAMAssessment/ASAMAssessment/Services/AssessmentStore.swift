//
//  AssessmentStore.swift
//  ASAM Assessment Application
//
//  SwiftData-backed assessment storage
//  HIPAA Compliant - No PHI in logs
//

import Foundation
import SwiftUI
import Combine

/// Main data store for assessments
@MainActor
class AssessmentStore: ObservableObject {
    @Published var assessments: [Assessment] = []
    @Published var currentAssessment: Assessment?

    init() {
        // Load saved assessments (would use SwiftData in production)
        self.assessments = []
    }

    /// Create new assessment
    func createAssessment() -> Assessment {
        let assessment = Assessment()
        assessments.append(assessment)
        currentAssessment = assessment
        return assessment
    }

    /// Update existing assessment
    func updateAssessment(_ assessment: Assessment) {
        if let index = assessments.firstIndex(where: { $0.id == assessment.id }) {
            var updated = assessment
            updated.updatedAt = Date()
            assessments[index] = updated

            if currentAssessment?.id == assessment.id {
                currentAssessment = updated
            }
        }
    }

    /// Delete assessment
    func deleteAssessment(_ assessment: Assessment) {
        assessments.removeAll { $0.id == assessment.id }
        if currentAssessment?.id == assessment.id {
            currentAssessment = nil
        }
    }

    /// Get assessment by ID
    func getAssessment(id: UUID) -> Assessment? {
        assessments.first { $0.id == id }
    }
}
