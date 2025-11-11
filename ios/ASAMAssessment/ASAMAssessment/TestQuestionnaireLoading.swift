//
//  TestQuestionnaireLoading.swift
//  ASAMAssessment
//
//  Test script to verify questionnaire loading
//

import Foundation

func testQuestionnaireLoading() {
    let service = QuestionsService()
    
    print("🧪 Testing questionnaire loading...")
    
    // Test all domains
    let domains = ["1", "2", "3", "4", "5", "6"]
    
    for domain in domains {
        do {
            let data = try service.loadQuestionnaireData(forDomain: domain)
            print("✅ Domain \(domain): Successfully loaded \(data.count) bytes")
            
            // Try to parse the JSON to verify it's valid
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let title = jsonObject["title"] as? String,
                   let questions = jsonObject["questions"] as? [Any] {
                    print("   📋 Title: \(title)")
                    print("   ❓ Questions count: \(questions.count)")
                }
            }
        } catch {
            print("❌ Domain \(domain): Failed with error: \(error)")
        }
    }
}