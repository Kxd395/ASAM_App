//
//  ASAMService.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation
import Combine

/// Main service for managing ASAM assessments
@MainActor
class ASAMService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentAssessment: ASAMAssessment?
    @Published private(set) var currentResponse: ASAMAssessmentResponse?
    @Published private(set) var skipLogicEngine: ASAMSkipLogicEngine?
    @Published private(set) var isLoading = false
    @Published private(set) var error: ASAMServiceError?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let storageManager: ASAMStorageManager
    
    // MARK: - Initialization
    
    init(storageManager: ASAMStorageManager = ASAMStorageManager()) {
        self.storageManager = storageManager
    }
    
    // MARK: - Assessment Management
    
    /// Create a new ASAM assessment
    func createAssessment(for patientId: String, version: ASAMVersion) async throws {
        isLoading = true
        error = nil
        
        do {
            // Create new assessment with appropriate dimensions
            var assessment = ASAMAssessment(patientId: patientId, version: version)
            
            // Build dimensions based on version
            switch version {
            case .v3_2013:
                let dimensions = buildV3Dimensions()
                assessment.dimensions = dimensions
            case .v4_2024:
                let dimensions = buildV4Dimensions()
                assessment.dimensions = dimensions
            }
            
            // Create response
            let response = ASAMAssessmentResponse(assessmentId: assessment.id, patientId: patientId)
            
            // Save to storage
            try await storageManager.saveAssessment(assessment)
            try await storageManager.saveResponse(response)
            
            // Set current state
            currentAssessment = assessment
            currentResponse = response
            skipLogicEngine = ASAMSkipLogicEngine(assessment: assessment, response: response)
            
            isLoading = false
            
        } catch {
            isLoading = false
            self.error = .creationFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Load existing assessment
    func loadAssessment(id: UUID) async throws {
        isLoading = true
        error = nil
        
        do {
            guard let assessment = try await storageManager.loadAssessment(id: id) else {
                throw ASAMServiceError.assessmentNotFound
            }
            
            guard let response = try await storageManager.loadResponse(assessmentId: id) else {
                throw ASAMServiceError.responseNotFound
            }
            
            currentAssessment = assessment
            currentResponse = response
            skipLogicEngine = ASAMSkipLogicEngine(assessment: assessment, response: response)
            
            isLoading = false
            
        } catch {
            isLoading = false
            self.error = .loadingFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Answer a question
    func answerQuestion(_ questionId: String, answer: ASAMAnswerValue) async throws {
        guard var response = currentResponse else {
            throw ASAMServiceError.noActiveAssessment
        }
        
        guard let assessment = currentAssessment else {
            throw ASAMServiceError.noActiveAssessment
        }
        
        // Validate answer
        if let question = assessment.getQuestion(by: questionId) {
            try validateAnswer(answer, for: question)
        }
        
        // Update response
        response.answers[questionId] = answer
        response.lastAnsweredQuestion = questionId
        response.lastModified = Date()
        response.completionPercentage = assessment.completionPercentage(response: response)
        response.isComplete = response.completionPercentage >= 1.0
        
        // Update skip logic
        skipLogicEngine?.updateForAnswerChange(questionId: questionId, newAnswer: answer)
        
        // Save changes
        try await storageManager.saveResponse(response)
        
        currentResponse = response
    }
    
    /// Add substance profile
    func addSubstanceProfile(_ profile: ASAMSubstanceProfile) async throws {
        guard var response = currentResponse else {
            throw ASAMServiceError.noActiveAssessment
        }
        
        // Remove any existing profile for same substance
        response.substanceProfiles.removeAll { $0.substance == profile.substance }
        
        // Add new profile
        response.substanceProfiles.append(profile)
        response.lastModified = Date()
        
        // Save changes
        try await storageManager.saveResponse(response)
        
        currentResponse = response
    }
    
    /// Add clinical scale score
    func addClinicalScale(_ scale: ASAMClinicalScale) async throws {
        guard var response = currentResponse else {
            throw ASAMServiceError.noActiveAssessment
        }
        
        // Remove any existing scale with same name
        response.clinicalScales.removeAll { $0.name == scale.name }
        
        // Add new scale
        response.clinicalScales.append(scale)
        response.lastModified = Date()
        
        // Save changes
        try await storageManager.saveResponse(response)
        
        currentResponse = response
    }
    
    /// Complete assessment and calculate scores
    func completeAssessment() async throws {
        guard var assessment = currentAssessment,
              let response = currentResponse else {
            throw ASAMServiceError.noActiveAssessment
        }
        
        isLoading = true
        
        do {
            // Calculate scores based on version
            let overallScore: ASAMOverallScore
            
            switch assessment.version {
            case .v3_2013:
                overallScore = try calculateV3Scores(assessment: assessment, response: response)
            case .v4_2024:
                overallScore = try calculateV4Scores(assessment: assessment, response: response)
            }
            
            // Generate recommendations
            let recommendations = generateRecommendations(assessment: assessment, response: response, scores: overallScore)
            
            // Update assessment
            assessment.overallScore = overallScore
            assessment.recommendations = recommendations
            assessment.completedAt = Date()
            assessment.lastModified = Date()
            
            // Save completed assessment
            try await storageManager.saveAssessment(assessment)
            
            currentAssessment = assessment
            isLoading = false
            
        } catch {
            isLoading = false
            self.error = .scoringFailed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get current dimension
    func getCurrentDimension() -> ASAMDimension? {
        guard let assessment = currentAssessment else { return nil }
        
        // Find first incomplete dimension
        for dimension in assessment.dimensions {
            let questions = dimension.allQuestions.filter { skipLogicEngine?.shouldShowQuestion($0.id) ?? true }
            let required = questions.filter { $0.isRequired }
            let answered = required.filter { currentResponse?.hasAnswer(for: $0.id) ?? false }
            
            if answered.count < required.count {
                return dimension
            }
        }
        
        return assessment.dimensions.first // Default to first dimension
    }
    
    /// Get next question to answer
    func getNextQuestion() -> ASAMQuestion? {
        guard let assessment = currentAssessment,
              let skipLogic = skipLogicEngine else { return nil }
        
        if let lastAnswered = currentResponse?.lastAnsweredQuestion {
            if let nextQuestionId = skipLogic.getNextQuestion(after: lastAnswered),
               let nextQuestion = assessment.getQuestion(by: nextQuestionId) {
                return nextQuestion
            }
        }
        
        // Find first unanswered question
        for dimension in assessment.dimensions {
            let questions = skipLogic.getVisibleQuestionsForDimension(dimension.id)
            for question in questions {
                if skipLogic.isQuestionRequired(question.id) && !(currentResponse?.hasAnswer(for: question.id) ?? false) {
                    return question
                }
            }
        }
        
        return nil
    }
    
    /// Get completion percentage for dimension
    func getCompletionPercentage(for dimensionId: Int) -> Double {
        return skipLogicEngine?.getCompletionPercentage(for: dimensionId) ?? 0.0
    }
    
    /// Get overall completion percentage
    func getOverallCompletionPercentage() -> Double {
        guard let assessment = currentAssessment else { return 0.0 }
        
        let dimensionPercentages = assessment.dimensions.map { getCompletionPercentage(for: $0.id) }
        guard !dimensionPercentages.isEmpty else { return 0.0 }
        
        return dimensionPercentages.reduce(0, +) / Double(dimensionPercentages.count)
    }
    
    // MARK: - Private Methods
    
    private func buildV3Dimensions() -> [ASAMDimension] {
        return [
            ASAMDimension1Builder.buildV3Dimension1()
            // TODO: Add other dimensions as they're implemented
            // ASAMDimension2Builder.buildV3Dimension2(),
            // ASAMDimension3Builder.buildV3Dimension3(),
            // ASAMDimension4Builder.buildV3Dimension4(),
            // ASAMDimension5Builder.buildV3Dimension5(),
            // ASAMDimension6Builder.buildV3Dimension6()
        ]
    }
    
    private func buildV4Dimensions() -> [ASAMDimension] {
        return [
            ASAMDimension1Builder.buildV4Dimension1()
            // TODO: Add other dimensions as they're implemented
        ]
    }
    
    private func validateAnswer(_ answer: ASAMAnswerValue, for question: ASAMQuestion) throws {
        guard let validation = question.validation else { return }
        
        if validation.required {
            switch answer {
            case .null:
                throw ASAMServiceError.validationFailed("Answer is required")
            case .string(let value) where value.isEmpty:
                throw ASAMServiceError.validationFailed("Answer cannot be empty")
            default:
                break
            }
        }
        
        // Validate string length
        if case .string(let value) = answer {
            if let minLength = validation.minLength, value.count < minLength {
                throw ASAMServiceError.validationFailed("Answer must be at least \(minLength) characters")
            }
            if let maxLength = validation.maxLength, value.count > maxLength {
                throw ASAMServiceError.validationFailed("Answer must be no more than \(maxLength) characters")
            }
        }
        
        // Validate numeric range
        if case .integer(let value) = answer {
            if let minValue = validation.minValue, Double(value) < minValue {
                throw ASAMServiceError.validationFailed("Answer must be at least \(minValue)")
            }
            if let maxValue = validation.maxValue, Double(value) > maxValue {
                throw ASAMServiceError.validationFailed("Answer must be no more than \(maxValue)")
            }
        }
        
        if case .double(let value) = answer {
            if let minValue = validation.minValue, value < minValue {
                throw ASAMServiceError.validationFailed("Answer must be at least \(minValue)")
            }
            if let maxValue = validation.maxValue, value > maxValue {
                throw ASAMServiceError.validationFailed("Answer must be no more than \(maxValue)")
            }
        }
    }
    
    private func calculateV3Scores(assessment: ASAMAssessment, response: ASAMAssessmentResponse) throws -> ASAMOverallScore {
        var dimensionSeverities: [Int: Int] = [:]
        
        // Calculate severity for each dimension (0-4 scale)
        for dimension in assessment.dimensions {
            let severity = calculateDimensionSeverity(dimension: dimension, response: response)
            dimensionSeverities[dimension.id] = severity
        }
        
        let overallSeverity = dimensionSeverities.values.max() ?? 0
        let recommendedLevel = getV3RecommendedLevel(severities: dimensionSeverities)
        
        let v3Scores = ASAMv3OverallScore(
            dimensionSeverities: dimensionSeverities,
            overallSeverity: overallSeverity,
            recommendedLevel: recommendedLevel,
            clinicalNotes: nil
        )
        
        return ASAMOverallScore(
            version: .v3_2013,
            v3Scores: v3Scores,
            v4Scores: nil,
            calculatedAt: Date(),
            calculatedBy: "ASAMService"
        )
    }
    
    private func calculateV4Scores(assessment: ASAMAssessment, response: ASAMAssessmentResponse) throws -> ASAMOverallScore {
        var dimensionRiskRatings: [Int: String] = [:]
        var subdimensionScores: [String: ASAMSubdimensionScore] = [:]
        
        // Calculate risk ratings for each dimension (A-E scale)
        for dimension in assessment.dimensions {
            let riskRating = calculateDimensionRiskRating(dimension: dimension, response: response)
            dimensionRiskRatings[dimension.id] = riskRating
            
            // Calculate subdimension scores if present
            if let subdimensions = dimension.subdimensions {
                for subdimension in subdimensions {
                    let score = calculateSubdimensionScore(subdimension: subdimension, response: response)
                    subdimensionScores[subdimension.id] = score
                }
            }
        }
        
        let levelOfCare = determineLevelOfCare(riskRatings: dimensionRiskRatings)
        
        let v4Scores = ASAMv4OverallScore(
            dimensionRiskRatings: dimensionRiskRatings,
            levelOfCare: levelOfCare,
            subdimensionScores: subdimensionScores,
            clinicalRationale: nil
        )
        
        return ASAMOverallScore(
            version: .v4_2024,
            v3Scores: nil,
            v4Scores: v4Scores,
            calculatedAt: Date(),
            calculatedBy: "ASAMService"
        )
    }
    
    private func calculateDimensionSeverity(dimension: ASAMDimension, response: ASAMAssessmentResponse) -> Int {
        // Simplified severity calculation - would need full ASAM algorithm
        let questions = dimension.allQuestions
        var totalRisk = 0
        var weightedQuestions = 0
        
        for question in questions {
            if let _ = response.getAnswer(for: question.id),
               let weighting = question.riskWeighting,
               let contribution = weighting.v3SeverityContribution {
                totalRisk += contribution
                weightedQuestions += 1
            }
        }
        
        guard weightedQuestions > 0 else { return 0 }
        
        let averageRisk = Double(totalRisk) / Double(weightedQuestions)
        return min(Int(round(averageRisk)), 4)
    }
    
    private func calculateDimensionRiskRating(dimension: ASAMDimension, response: ASAMAssessmentResponse) -> String {
        // Simplified risk rating calculation - would need full ASAM v4 algorithm
        let questions = dimension.allQuestions
        var maxRisk = "A"
        
        for question in questions {
            if let _ = response.getAnswer(for: question.id),
               let weighting = question.riskWeighting,
               let riskRating = weighting.v4RiskContribution {
                if riskRating > maxRisk {
                    maxRisk = riskRating
                }
            }
        }
        
        return maxRisk
    }
    
    private func calculateSubdimensionScore(subdimension: ASAMSubdimension, response: ASAMAssessmentResponse) -> ASAMSubdimensionScore {
        // Calculate subdimension risk rating
        let riskRating = calculateDimensionRiskRating(
            dimension: ASAMDimension(id: 0, name: "", shortName: "", subdimensions: nil, questions: subdimension.questions, score: nil, isRequired: false),
            response: response
        )
        
        return ASAMSubdimensionScore(
            subdimensionId: subdimension.id,
            riskRating: riskRating,
            contributingFactors: [],
            clinicalNotes: nil
        )
    }
    
    private func getV3RecommendedLevel(severities: [Int: Int]) -> String? {
        let maxSeverity = severities.values.max() ?? 0
        
        switch maxSeverity {
        case 0: return "Self-help or no treatment needed"
        case 1: return "Level 1.0 - Outpatient Services"
        case 2: return "Level 2.1 - Intensive Outpatient"
        case 3: return "Level 3.5 - Clinically Managed High-Intensity Residential"
        case 4: return "Level 3.7 - Medically Monitored or Level 4.0 - Medically Managed"
        default: return nil
        }
    }
    
    private func determineLevelOfCare(riskRatings: [Int: String]) -> ASAMLevelOfCare {
        // Simplified level-of-care determination
        let maxRisk = riskRatings.values.max() ?? "A"
        
        switch maxRisk {
        case "A": return .level_1_0
        case "B": return .level_2_1
        case "C": return .level_2_5
        case "D": return .level_3_5
        case "E": return .level_3_7
        default: return .level_1_0
        }
    }
    
    private func generateRecommendations(assessment: ASAMAssessment, response: ASAMAssessmentResponse, scores: ASAMOverallScore) -> [String] {
        var recommendations: [String] = []
        
        switch assessment.version {
        case .v3_2013:
            if let v3Scores = scores.v3Scores {
                recommendations.append("Overall severity level: \(v3Scores.overallSeverity)")
                if let level = v3Scores.recommendedLevel {
                    recommendations.append("Recommended level of care: \(level)")
                }
            }
        case .v4_2024:
            if let v4Scores = scores.v4Scores {
                recommendations.append("Recommended level of care: \(v4Scores.levelOfCare.displayName)")
                recommendations.append(v4Scores.levelOfCare.description)
            }
        }
        
        return recommendations
    }
}

// MARK: - Error Types

enum ASAMServiceError: LocalizedError {
    case noActiveAssessment
    case assessmentNotFound
    case responseNotFound
    case creationFailed(String)
    case loadingFailed(String)
    case validationFailed(String)
    case scoringFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noActiveAssessment:
            return "No active assessment found"
        case .assessmentNotFound:
            return "Assessment not found"
        case .responseNotFound:
            return "Response not found"
        case .creationFailed(let message):
            return "Failed to create assessment: \(message)"
        case .loadingFailed(let message):
            return "Failed to load assessment: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .scoringFailed(let message):
            return "Scoring failed: \(message)"
        }
    }
}

// MARK: - Storage Manager (Placeholder)

/// Storage manager for ASAM assessments (would integrate with GRDB or Core Data)
class ASAMStorageManager {
    
    func saveAssessment(_ assessment: ASAMAssessment) async throws {
        // TODO: Implement storage persistence
        print("Saving assessment: \(assessment.id)")
    }
    
    func loadAssessment(id: UUID) async throws -> ASAMAssessment? {
        // TODO: Implement storage retrieval
        print("Loading assessment: \(id)")
        return nil
    }
    
    func saveResponse(_ response: ASAMAssessmentResponse) async throws {
        // TODO: Implement response persistence
        print("Saving response: \(response.id)")
    }
    
    func loadResponse(assessmentId: UUID) async throws -> ASAMAssessmentResponse? {
        // TODO: Implement response retrieval
        print("Loading response for assessment: \(assessmentId)")
        return nil
    }
}