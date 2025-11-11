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
    @Published var currentAssessment: Assessment? {
        didSet {
            if let assessment = currentAssessment {
                print("🔄 AssessmentStore: Current assessment set to \(String(assessment.id.uuidString.prefix(8)))")
                // Save current assessment to UserDefaults immediately for persistence
                saveCurrentAssessmentId(assessment.id)
            } else {
                print("🔄 AssessmentStore: Current assessment cleared")
                saveCurrentAssessmentId(nil)
            }
        }
    }
    
    // MARK: - Persistence Keys
    private let assessmentsKey = "stored_assessments"
    private let currentAssessmentKey = "current_assessment_id"

    init() {
        loadPersistedAssessments()
        loadCurrentAssessment()
        print("📂 AssessmentStore: Loaded \(assessments.count) persisted assessments")
    }

    /// Create new assessment
    func createAssessment() -> Assessment {
        let assessment = Assessment()
        assessments.append(assessment)
        currentAssessment = assessment
        persistAssessments() // Save to storage immediately
        print("✅ AssessmentStore: Created new assessment \(String(assessment.id.uuidString.prefix(8)))")
        return assessment
    }

    /// Update existing assessment
    func updateAssessment(_ assessment: Assessment) {
        if let index = assessments.firstIndex(where: { $0.id == assessment.id }) {
            var updated = assessment
            updated.updatedAt = Date()
            assessments[index] = updated

            // PERSIST IMMEDIATELY after update to the assessments array
            persistAssessments()
            
            // THEN update currentAssessment if it's the same ID
            if currentAssessment?.id == assessment.id {
                currentAssessment = updated
                print("📊 AssessmentStore: Updated current assessment \(String(assessment.id.uuidString.prefix(8)))")
            }
            
            // Notify that the assessment was updated (for UI refresh)
            print("📊 AssessmentStore: Updated assessment \(String(assessment.id.uuidString.prefix(8))) - domains with answers: \(assessment.domains.filter { !$0.answers.isEmpty }.count)")
            
            // Force a UI update by triggering objectWillChange
            objectWillChange.send()
        } else {
            print("❌ AssessmentStore: Could not find assessment \(String(assessment.id.uuidString.prefix(8))) to update")
        }
    }

    /// Delete assessment
    func deleteAssessment(_ assessment: Assessment) {
        assessments.removeAll { $0.id == assessment.id }
        if currentAssessment?.id == assessment.id {
            currentAssessment = nil
        }
        persistAssessments() // Save after deletion
        print("🗑️ AssessmentStore: Deleted assessment \(String(assessment.id.uuidString.prefix(8)))")
    }

    /// Get assessment by ID
    func getAssessment(id: UUID) -> Assessment? {
        return assessments.first { $0.id == id }
    }
    
    /// Force refresh of current assessment from stored assessments
    func refreshCurrentAssessment() {
        guard let currentId = currentAssessment?.id else { return }
        if let refreshed = assessments.first(where: { $0.id == currentId }) {
            currentAssessment = refreshed
            print("🔄 AssessmentStore: Refreshed current assessment from storage")
        }
    }
    
    // MARK: - Persistence Methods
    
    /// Save all assessments to UserDefaults
    private func persistAssessments() {
        do {
            let data = try JSONEncoder().encode(assessments)
            UserDefaults.standard.set(data, forKey: assessmentsKey)
            
            // Enhanced debug logging
            if let currentAssessment = currentAssessment {
                let domainAnswersCount = currentAssessment.domains.map { "\($0.number):\($0.answers.count)" }.joined(separator: ", ")
                print("💾 AssessmentStore: Persisted \(assessments.count) assessments - Current: [\(domainAnswersCount)]")
            } else {
                print("💾 AssessmentStore: Persisted \(assessments.count) assessments to storage")
            }
            
            // Force UserDefaults to synchronize
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ AssessmentStore: Failed to persist assessments: \(error)")
        }
    }
    
    /// Load assessments from UserDefaults
    private func loadPersistedAssessments() {
        guard let data = UserDefaults.standard.data(forKey: assessmentsKey) else {
            print("📂 AssessmentStore: No persisted assessments found")
            return
        }
        
        do {
            assessments = try JSONDecoder().decode([Assessment].self, from: data)
            print("📂 AssessmentStore: Loaded \(assessments.count) assessments from storage")
        } catch {
            print("❌ AssessmentStore: Failed to load persisted assessments: \(error)")
            assessments = []
        }
    }
    
    /// Save current assessment ID to UserDefaults
    private func saveCurrentAssessmentId(_ id: UUID?) {
        if let id = id {
            UserDefaults.standard.set(id.uuidString, forKey: currentAssessmentKey)
            print("💾 AssessmentStore: Saved current assessment ID: \(String(id.uuidString.prefix(8)))")
        } else {
            UserDefaults.standard.removeObject(forKey: currentAssessmentKey)
            print("💾 AssessmentStore: Cleared current assessment ID")
        }
    }
    
    /// Load current assessment from UserDefaults
    private func loadCurrentAssessment() {
        guard let idString = UserDefaults.standard.string(forKey: currentAssessmentKey),
              let id = UUID(uuidString: idString) else {
            print("📂 AssessmentStore: No current assessment ID found")
            return
        }
        
        currentAssessment = assessments.first { $0.id == id }
        if currentAssessment != nil {
            print("📂 AssessmentStore: Restored current assessment: \(String(id.uuidString.prefix(8)))")
        } else {
            print("⚠️ AssessmentStore: Current assessment ID found but assessment not in storage: \(String(id.uuidString.prefix(8)))")
        }
    }
}
