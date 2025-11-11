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
    
    // MARK: - Initialization
    
    init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }
    
    // MARK: - Public Methods
    
    func loadQuestionnaireData(forDomain domain: String) throws -> Data {
        let domainKey = domain.uppercased()
        
        // Map domain to filename
        let filename = domainFilename(for: domainKey)
        
        // Debug: List all available JSON resources
        print("🔍 QuestionsService: Looking for resource '\(filename).json'")
        if let resourcePath = bundle.path(forResource: filename, ofType: "json") {
            print("✅ Found resource at: \(resourcePath)")
        } else {
            print("❌ Resource not found. Available JSON resources:")
            let resourcePaths = bundle.paths(forResourcesOfType: "json", inDirectory: nil)
            for path in resourcePaths {
                let resourceName = (path as NSString).lastPathComponent
                print("   - \(resourceName)")
            }
        }
        
        // Load from bundle
        guard let url = bundle.url(
            forResource: filename,
            withExtension: "json"
        ) else {
            throw NSError(domain: "QuestionsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Questionnaire file not found: \(filename)"])
        }
        
        return try Data(contentsOf: url)
    }
    
    // MARK: - Private Methods
    
    private func domainFilename(for domain: String) -> String {
        switch domain.uppercased() {
        case "A", "1", "DOMAIN1", "DOMAIN 1": return "d1_withdrawal_enhanced"
        case "B", "2", "DOMAIN2", "DOMAIN 2": return "d2_biomedical_neutral"
        case "C", "3", "DOMAIN3", "DOMAIN 3": return "d3_emotional_neutral"
        case "D", "4", "DOMAIN4", "DOMAIN 4": return "d4_readiness_neutral"
        case "E", "5", "DOMAIN5", "DOMAIN 5": return "d5_relapse_neutral"
        case "F", "6", "DOMAIN6", "DOMAIN 6": return "d6_environment_neutral"
        default:
            // Log the attempted domain for debugging
            print("🔍 QuestionsService: Unknown domain '\(domain)', falling back to d1_withdrawal_enhanced")
            return "d1_withdrawal_enhanced" // fallback to enhanced version
        }
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