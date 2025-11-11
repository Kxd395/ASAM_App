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
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // For debugging
            
            let data = try encoder.encode(assessments)
            let dataSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
            
            print("💾 Persisting \(assessments.count) assessments (\(dataSize))")
            print("💾 Current assessment: \(currentAssessment?.id.uuidString.prefix(8) ?? "none")")
            
            // Enhanced debug logging - log domain answers for current assessment
            if let currentAssessment = currentAssessment {
                let domainAnswersCount = currentAssessment.domains.map { "\($0.number):\($0.answers.count)" }.joined(separator: ", ")
                print("💾 Current assessment domains [Domain:Answers]: [\(domainAnswersCount)]")
                
                let completedCount = currentAssessment.completedDomainsCount
                let startedCount = currentAssessment.startedDomainsCount
                let progress = currentAssessment.completionPercentage
                print("💾 Progress: \(progress)% (\(completedCount) complete, \(startedCount) started)")
            }
            
            UserDefaults.standard.set(data, forKey: assessmentsKey)
            
            // Force UserDefaults to synchronize
            UserDefaults.standard.synchronize()
            
            print("✅ Persistence complete - data synchronized to disk")
            
        } catch {
            print("❌ PERSISTENCE FAILED: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
            if let encodingError = error as? EncodingError {
                switch encodingError {
                case .invalidValue(let value, let context):
                    print("❌ Invalid value at \(context.codingPath): \(value)")
                default:
                    print("❌ Encoding error: \(encodingError)")
                }
            }
        }
    }
    
    /// Load assessments from UserDefaults
    private func loadPersistedAssessments() {
        guard let data = UserDefaults.standard.data(forKey: assessmentsKey) else {
            print("📂 No persisted assessments found (first launch or no data yet)")
            return
        }
        
        let dataSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        print("📂 Loading persisted data (\(dataSize))")
        
        do {
            let decoder = JSONDecoder()
            assessments = try decoder.decode([Assessment].self, from: data)
            
            print("✅ Loaded \(assessments.count) assessments successfully")
            
            // Verify data integrity - log assessment details
            for assessment in assessments {
                let answerCounts = assessment.domains.map { $0.answers.count }
                let totalAnswers = answerCounts.reduce(0, +)
                let progress = assessment.completionPercentage
                print("📂   Assessment \(assessment.id.uuidString.prefix(8)): \(totalAnswers) total answers, \(progress)% complete")
                print("📂     Domain breakdown: \(assessment.domains.map { "D\($0.number):\($0.answers.count)" }.joined(separator: ", "))")
            }
            
        } catch {
            print("❌ FAILED TO LOAD ASSESSMENTS: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
            
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("❌ Data corrupted at \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("❌ Key '\(key)' not found at \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for \(type) at \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for \(type) at \(context.codingPath)")
                @unknown default:
                    print("❌ Unknown decoding error: \(decodingError)")
                }
            }
            
            print("⚠️  Resetting to empty assessment list - corrupted data archived")
            assessments = []
            
            // Archive corrupted data for forensics
            let timestamp = Date().timeIntervalSince1970
            UserDefaults.standard.set(data, forKey: "corrupted_backup_\(timestamp)")
            print("📦 Corrupted data backed up to: corrupted_backup_\(timestamp)")
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
