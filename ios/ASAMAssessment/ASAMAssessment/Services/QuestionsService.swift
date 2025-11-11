//
//  QuestionsService.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation
import Combine

class QuestionsService: ObservableObject {
    
    // MARK: - Properties
    
    private let bundle: Bundle
    private var loadedQuestionnaires: [String: Questionnaire] = [:]
    
    // MARK: - Initialization
    
    init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }
    
    // MARK: - Public Methods
    
    func loadQuestionnaire(forDomain domain: String) throws -> Questionnaire {
        let domainKey = domain.uppercased()
        
        // Return cached if available
        if let cached = loadedQuestionnaires[domainKey] {
            return cached
        }
        
        // Map domain to filename
        let filename = domainFilename(for: domainKey)
        
        // Load from bundle
        guard let url = bundle.url(
            forResource: filename,
            withExtension: "json",
            subdirectory: "questionnaires/domains"
        ) else {
            throw QuestionnaireError.fileNotFound(filename)
        }
        
        let data = try Data(contentsOf: url)
        let questionnaire = try JSONDecoder().decode(Questionnaire.self, from: data)
        
        // Cache and return
        loadedQuestionnaires[domainKey] = questionnaire
        return questionnaire
    }
    
    func loadAllQuestionnaires() throws -> [Questionnaire] {
        let domains = ["A", "B", "C", "D", "E", "F"]
        return try domains.map { try loadQuestionnaire(forDomain: $0) }
    }
    
    func validateQuestionnaire(_ questionnaire: Questionnaire) -> [String] {
        var errors: [String] = []
        
        // Basic validation
        if questionnaire.questions.isEmpty {
            errors.append("Questionnaire must contain at least one question")
        }
        
        // Check for duplicate question IDs
        let questionIds = questionnaire.questions.map { $0.id }
        let uniqueIds = Set(questionIds)
        if questionIds.count != uniqueIds.count {
            errors.append("Questionnaire contains duplicate question IDs")
        }
        
        // Validate each question
        for question in questionnaire.questions {
            errors.append(contentsOf: validateQuestion(question, in: questionnaire))
        }
        
        return errors
    }
    
    func preloadAllQuestionnaires() {
        Task {
            do {
                _ = try await loadAllQuestionnaires()
            } catch {
                print("Failed to preload questionnaires: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func domainFilename(for domain: String) -> String {
        switch domain {
        case "A": return "d1_withdrawal_neutral"
        case "B": return "d2_biomedical_neutral"
        case "C": return "d3_emotional_neutral"
        case "D": return "d4_readiness_neutral"
        case "E": return "d5_relapse_neutral"
        case "F": return "d6_environment_neutral"
        default:
            return "d1_withdrawal_neutral" // fallback
        }
    }
    
    private func validateQuestion(_ question: Question, in questionnaire: Questionnaire) -> [String] {
        var errors: [String] = []
        
        // Validate question ID format
        if !question.id.matches(pattern: "^[a-f]\\d{2}$") {
            errors.append("Question ID '\(question.id)' does not match required format (e.g., a01)")
        }
        
        // Validate domain prefix matches questionnaire domain
        let expectedPrefix = questionnaire.domain.lowercased()
        if !question.id.lowercased().hasPrefix(expectedPrefix) {
            errors.append("Question ID '\(question.id)' should start with '\(expectedPrefix)'")
        }
        
        // Validate question text
        if question.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Question '\(question.id)' has empty text")
        }
        
        // Validate options for choice questions
        if [.singleChoice, .multipleChoice].contains(question.type) {
            if question.options?.isEmpty != false {
                errors.append("Question '\(question.id)' requires options for choice type")
            }
        }
        
        // Validate visibility conditions
        if let visibleIf = question.visibleIf {
            let referencedQuestionExists = questionnaire.questions.contains { $0.id == visibleIf.question }
            if !referencedQuestionExists {
                errors.append("Question '\(question.id)' references non-existent question '\(visibleIf.question)' in visibility condition")
            }
        }
        
        return errors
    }
}

// MARK: - Error Types

enum QuestionnaireError: LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case validationFailed([String])
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Questionnaire file not found: \(filename)"
        case .invalidFormat(let reason):
            return "Invalid questionnaire format: \(reason)"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        }
    }
}

// MARK: - Extensions

private extension String {
    func matches(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

// MARK: - Async Support

extension QuestionsService {
    func loadAllQuestionnaires() async throws -> [Questionnaire] {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let questionnaires = try loadAllQuestionnaires()
                continuation.resume(returning: questionnaires)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func loadQuestionnaire(forDomain domain: String) async throws -> Questionnaire {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let questionnaire = try loadQuestionnaire(forDomain: domain)
                continuation.resume(returning: questionnaire)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}