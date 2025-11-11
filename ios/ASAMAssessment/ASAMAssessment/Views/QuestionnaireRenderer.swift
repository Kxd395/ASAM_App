//
//  QuestionnaireRenderer.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import SwiftUI

struct QuestionnaireRenderer: View {
    
    // MARK: - Properties
    
    let questionnaire: Questionnaire
    let initialAnswers: [String: AnswerValue]  // Initial answers to load
    let onAnswersChanged: ([String: AnswerValue]) -> Void
    
    @State private var answers: [String: AnswerValue] = [:]
    @State private var validationErrors: [String: String] = [:]
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Initializers
    
    init(
        questionnaire: Questionnaire,
        initialAnswers: [String: AnswerValue] = [:],
        onAnswersChanged: @escaping ([String: AnswerValue]) -> Void
    ) {
        self.questionnaire = questionnaire
        self.initialAnswers = initialAnswers
        self.onAnswersChanged = onAnswersChanged
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                questionnaireHeader
                
                // Questions
                ForEach(questionnaire.questions) { question in
                    if question.isVisible(given: answers) {
                        QuestionView(
                            question: question,
                            answer: Binding(
                                get: { answers[question.id] ?? .none },
                                set: { newValue in
                                    answers[question.id] = newValue
                                    validateQuestion(question)
                                    onAnswersChanged(answers)
                                }
                            ),
                            validationError: validationErrors[question.id]
                        )
                    }
                }
                
                // Progress indicator
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .padding(.top)
                
                Text("Progress: \(Int(progressValue * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .onAppear {
            initializeAnswers()
        }
    }
    
    // MARK: - Subviews
    
    private var questionnaireHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(questionnaire.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let description = questionnaire.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Domain \(questionnaire.domain)", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("v\(questionnaire.version)", systemImage: "number")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Private Methods
    
    private var progressValue: Double {
        let visibleQuestions = questionnaire.questions.filter { $0.isVisible(given: answers) }
        guard !visibleQuestions.isEmpty else { return 0 }
        
        let answeredCount = visibleQuestions.filter { question in
            if let answer = answers[question.id], case .none = answer {
                return false
            }
            return answers[question.id] != nil
        }.count
        
        return Double(answeredCount) / Double(visibleQuestions.count)
    }
    
    private func initializeAnswers() {
        // Initialize with provided initial answers first, then fill gaps with .none
        answers = initialAnswers
        
        for question in questionnaire.questions {
            if answers[question.id] == nil {
                answers[question.id] = AnswerValue.none
            }
        }
        
        // Notify about initial state
        onAnswersChanged(answers)
    }
    
    private func validateQuestion(_ question: Question) {
        if let answer = answers[question.id] {
            if question.validateAnswer(answer) {
                validationErrors.removeValue(forKey: question.id)
            } else {
                validationErrors[question.id] = "Invalid answer for this question"
            }
        } else if question.required {
            validationErrors[question.id] = "This question is required"
        } else {
            validationErrors.removeValue(forKey: question.id)
        }
    }
}

// MARK: - Question View

struct QuestionView: View {
    let question: Question
    @Binding var answer: AnswerValue
    let validationError: String?
    
    @Environment(\.colorScheme) var colorScheme
    @State private var textInput: String = ""
    @State private var numberInput: Double = 0
    @State private var boolInput: Bool = false
    @State private var singleSelection: QuestionValue?
    @State private var multipleSelection: Set<QuestionValue> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question text with required indicator
            HStack {
                Text(question.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if question.required {
                    Text("*")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            
            // Question input based on type
            questionInputView
            
            // Breadcrumb hint (for development)
            if let breadcrumb = question.breadcrumb {
                Text("Field: \(breadcrumb)")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Validation error
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 1, x: 0, y: 1)
        )
        .onAppear {
            setupInitialValues()
        }
        .onChange(of: answer) { _, _ in
            updateLocalState()
        }
    }
    
    @ViewBuilder
    private var questionInputView: some View {
        switch question.type {
        case .text:
            VStack(alignment: .leading, spacing: 12) {
                // Quick response checkboxes
                Text("Quick responses:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("N/A") {
                        textInput = "N/A"
                        answer = .text(textInput)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Did not answer") {
                        textInput = "Did not answer"
                        answer = .text(textInput)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Other") {
                        textInput = "Other"
                        answer = .text(textInput)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Clear") {
                        textInput = ""
                        answer = .text(textInput)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
                
                // Text field for custom input
                TextField("Enter your answer or use quick responses above", text: $textInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: textInput) { _, _ in
                        answer = .text(textInput)
                    }
            }
            
        case .number:
            HStack {
                TextField("Enter number", value: $numberInput, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .onChange(of: numberInput) { _, _ in
                        answer = .number(numberInput)
                    }
                
                if let validation = question.validation {
                    VStack(alignment: .leading, spacing: 2) {
                        if let min = validation.min {
                            Text("Min: \(min, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        if let max = validation.max {
                            Text("Max: \(max, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
        case .boolean:
            Toggle(isOn: $boolInput) {
                Text("Yes")
            }
            .onChange(of: boolInput) { _, _ in
                answer = .bool(boolInput)
            }
            
        case .singleChoice:
            if let options = question.options {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(options) { option in
                        Button(action: {
                            singleSelection = option.value
                            answer = .single(option.value)
                        }) {
                            HStack {
                                Image(systemName: singleSelection == option.value ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(singleSelection == option.value ? .accentColor : .secondary)
                                
                                Text(option.label)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if let score = option.score {
                                    Text("(\(score, specifier: "%.0f"))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
            }
            
        case .multipleChoice:
            if let options = question.options {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(options) { option in
                        Button(action: {
                            if multipleSelection.contains(option.value) {
                                multipleSelection.remove(option.value)
                            } else {
                                multipleSelection.insert(option.value)
                            }
                            answer = .multi(multipleSelection)
                        }) {
                            HStack {
                                Image(systemName: multipleSelection.contains(option.value) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(multipleSelection.contains(option.value) ? .accentColor : .secondary)
                                
                                Text(option.label)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if let score = option.score {
                                    Text("(\(score, specifier: "%.0f"))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                    }
                }
            }
            
        case .dynamicSubstanceGrid:
            SubstanceGridView(
                question: question,
                answer: $answer,
                validationError: validationError
            )
        }
    }
    
    private func setupInitialValues() {
        switch answer {
        case .text(let value):
            textInput = value
        case .number(let value):
            numberInput = value
        case .bool(let value):
            boolInput = value
        case .single(let value):
            singleSelection = value
        case .multi(let values):
            multipleSelection = values
        case .substanceGrid:
            // Handled by SubstanceGridView
            break
        case .none:
            // Keep defaults
            break
        }
    }
    
    private func updateLocalState() {
        switch answer {
        case .text(let value):
            textInput = value
        case .number(let value):
            numberInput = value
        case .bool(let value):
            boolInput = value
        case .single(let value):
            singleSelection = value
        case .multi(let values):
            multipleSelection = values
        case .substanceGrid:
            // Handled by SubstanceGridView
            break
        case .none:
            textInput = ""
            numberInput = 0
            boolInput = false
            singleSelection = nil
            multipleSelection.removeAll()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct QuestionnaireRenderer_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireRenderer(
            questionnaire: mockQuestionnaire,
            onAnswersChanged: { answers in
                print("Answers changed: \(answers)")
            }
        )
        .padding()
    }
    
    private static var mockQuestionnaire: Questionnaire {
        Questionnaire(
            id: "a1_withdrawal_neutral",
            title: "Domain A: Acute Intoxication and/or Withdrawal Potential",
            domain: "A",
            version: "1.0.0",
            description: "Assessment of current acute intoxication and withdrawal potential",
            questions: [
                Question(
                    id: "a01",
                    text: "Is the patient currently showing signs of intoxication?",
                    type: .singleChoice,
                    required: true,
                    breadcrumb: "intoxication_present",
                    visibleIf: nil,
                    options: [
                        QuestionOption(value: .string("none"), label: "No signs of intoxication", score: 1),
                        QuestionOption(value: .string("mild"), label: "Mild intoxication signs", score: 2),
                        QuestionOption(value: .string("moderate"), label: "Moderate intoxication", score: 3),
                        QuestionOption(value: .string("severe"), label: "Severe intoxication", score: 4)
                    ],
                    validation: nil,
                    description: nil,
                    substanceTemplate: nil,
                    availableSubstances: nil
                )
            ]
        )
    }
}
#endif