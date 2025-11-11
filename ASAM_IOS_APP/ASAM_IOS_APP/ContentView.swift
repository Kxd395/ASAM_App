//
//  ContentView.swift
//  ASAM_IOS_APP
//
//  Created by Kevin Dial on 11/9/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var questionsService = QuestionsService()
    @State private var selectedDomain = "1"
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                Text("Treatment Plan Assistant")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Domain Selection
                Picker("Select Domain", selection: $selectedDomain) {
                    Text("Domain 1: Withdrawal").tag("1")
                    Text("Domain 2: Biomedical").tag("2")
                    Text("Domain 3: Emotional").tag("3")
                    Text("Domain 4: Readiness").tag("4")
                    Text("Domain 5: Relapse").tag("5")
                    Text("Domain 6: Environment").tag("6")
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Domain Content
                DomainDetailView(domain: selectedDomain, questionsService: questionsService)
            }
            .navigationTitle("ASAM Assessment")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DomainDetailView: View {
    let domain: String
    let questionsService: QuestionsService
    
    @State private var questionnaire: Questionnaire?
    @State private var answers: [String: AnswerValue] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading questionnaire...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
            } else if let error = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Error Loading Questionnaire")
                        .font(.headline)
                        .padding(.top)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if let questionnaire = questionnaire {
                QuestionnaireRenderer(
                    questionnaire: questionnaire,
                    onAnswersChanged: { newAnswers in
                        answers = newAnswers
                        print("Answers updated: \(newAnswers)")
                    }
                )
            }
        }
        .onAppear {
            loadQuestionnaire()
        }
        .onChange(of: domain) { _ in
            loadQuestionnaire()
        }
    }
    
    private func loadQuestionnaire() {
        isLoading = true
        errorMessage = nil
        
        do {
            // Map domain numbers to letters for QuestionsService
            let domainLetter = mapDomainNumberToLetter(domain)
            print("🚀 Loading questionnaire for domain \(domain) -> letter: \(domainLetter)")
            
            let loadedQuestionnaire = try questionsService.loadQuestionnaire(forDomain: domainLetter)
            print("✅ Loaded questionnaire: \(loadedQuestionnaire.title)")
            print("📊 Total questions: \(loadedQuestionnaire.questions.count)")
            
            // Debug first few questions
            for (index, question) in loadedQuestionnaire.questions.prefix(5).enumerated() {
                print("   Q\(index + 1): \(question.id) (\(question.type)) - \(question.text.prefix(60))...")
            }
            
            questionnaire = loadedQuestionnaire
            isLoading = false
        } catch {
            print("❌ Error loading questionnaire: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func mapDomainNumberToLetter(_ domain: String) -> String {
        switch domain {
        case "1": return "A"
        case "2": return "B" 
        case "3": return "C"
        case "4": return "D"
        case "5": return "E"
        case "6": return "F"
        default: return "A"
        }
    }
}

#Preview {
    ContentView()
}
