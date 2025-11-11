//
//  SubstanceGridView.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import SwiftUI

struct SubstanceGridView: View {
    let question: Question
    @Binding var answer: AnswerValue
    let validationError: String?
    
    @State private var substanceAssessments: [SubstanceAssessment] = []
    @State private var showingSubstanceSelector = false
    @State private var availableSubstanceOptions: [SubstanceDefinition] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with description
            if let description = question.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            
            // Current substance assessments
            ForEach(substanceAssessments) { assessment in
                SubstanceAssessmentRow(
                    assessment: binding(for: assessment),
                    substanceDefinition: substanceDefinition(for: assessment.substanceId),
                    onRemove: {
                        removeSubstance(assessment.id)
                    }
                )
                .padding(.bottom, 8)
            }
            
            // Add substance button
            Button(action: {
                showingSubstanceSelector = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Substance")
                }
                .foregroundColor(.accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
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
        .onAppear {
            setupInitialData()
        }
        .onChange(of: substanceAssessments) { _ in
            updateAnswer()
        }
        .sheet(isPresented: $showingSubstanceSelector) {
            SubstanceSelectorSheet(
                availableSubstances: availableSubstanceOptions,
                currentSubstances: substanceAssessments.map { $0.substanceId },
                onSubstanceSelected: { substanceId in
                    addSubstance(substanceId)
                }
            )
        }
    }
    
    private func setupInitialData() {
        availableSubstanceOptions = question.availableSubstances ?? []
        
        switch answer {
        case .substanceGrid(let assessments):
            substanceAssessments = assessments
        case .none:
            substanceAssessments = []
        default:
            substanceAssessments = []
        }
    }
    
    private func binding(for assessment: SubstanceAssessment) -> Binding<SubstanceAssessment> {
        Binding(
            get: { assessment },
            set: { newValue in
                if let index = substanceAssessments.firstIndex(where: { $0.id == assessment.id }) {
                    substanceAssessments[index] = newValue
                }
            }
        )
    }
    
    private func substanceDefinition(for substanceId: String) -> SubstanceDefinition? {
        availableSubstanceOptions.first { $0.id == substanceId }
    }
    
    private func addSubstance(_ substanceId: String) {
        let newAssessment = SubstanceAssessment(
            id: UUID().uuidString,
            substanceId: substanceId,
            neverUsed: false,
            lastUseDate: nil,
            durationYears: nil,
            durationMonths: nil,
            frequency30Days: nil,
            routes: [],
            conditionalAnswers: [:]
        )
        substanceAssessments.append(newAssessment)
        showingSubstanceSelector = false
    }
    
    private func removeSubstance(_ assessmentId: String) {
        substanceAssessments.removeAll { $0.id == assessmentId }
    }
    
    private func updateAnswer() {
        answer = .substanceGrid(substanceAssessments)
    }
}

// MARK: - Substance Assessment Row

struct SubstanceAssessmentRow: View {
    @Binding var assessment: SubstanceAssessment
    let substanceDefinition: SubstanceDefinition?
    let onRemove: () -> Void
    
    @State private var showingConditionalQuestions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with substance name and remove button
            HStack {
                Text(substanceDefinition?.name ?? "Unknown Substance")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            // Never used toggle
            Toggle("Never Used", isOn: .init(
                get: { assessment.neverUsed },
                set: { newValue in
                    assessment = SubstanceAssessment(
                        id: assessment.id,
                        substanceId: assessment.substanceId,
                        neverUsed: newValue,
                        lastUseDate: newValue ? nil : assessment.lastUseDate,
                        durationYears: newValue ? nil : assessment.durationYears,
                        durationMonths: newValue ? nil : assessment.durationMonths,
                        frequency30Days: newValue ? nil : assessment.frequency30Days,
                        routes: newValue ? [] : assessment.routes,
                        conditionalAnswers: newValue ? [:] : assessment.conditionalAnswers
                    )
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .orange))
            
            if !assessment.neverUsed {
                // Usage details
                VStack(alignment: .leading, spacing: 8) {
                    // Last use date
                    DatePicker(
                        "Date of last use:",
                        selection: .init(
                            get: { assessment.lastUseDate ?? Date() },
                            set: { newDate in
                                assessment = SubstanceAssessment(
                                    id: assessment.id,
                                    substanceId: assessment.substanceId,
                                    neverUsed: assessment.neverUsed,
                                    lastUseDate: newDate,
                                    durationYears: assessment.durationYears,
                                    durationMonths: assessment.durationMonths,
                                    frequency30Days: assessment.frequency30Days,
                                    routes: assessment.routes,
                                    conditionalAnswers: assessment.conditionalAnswers
                                )
                            }
                        ),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    
                    // Duration
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Years of use:")
                                .font(.caption)
                            TextField("Years", value: .init(
                                get: { assessment.durationYears ?? 0 },
                                set: { newValue in
                                    assessment = SubstanceAssessment(
                                        id: assessment.id,
                                        substanceId: assessment.substanceId,
                                        neverUsed: assessment.neverUsed,
                                        lastUseDate: assessment.lastUseDate,
                                        durationYears: newValue > 0 ? newValue : nil,
                                        durationMonths: assessment.durationMonths,
                                        frequency30Days: assessment.frequency30Days,
                                        routes: assessment.routes,
                                        conditionalAnswers: assessment.conditionalAnswers
                                    )
                                }
                            ), format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Months:")
                                .font(.caption)
                            TextField("Months", value: .init(
                                get: { assessment.durationMonths ?? 0 },
                                set: { newValue in
                                    assessment = SubstanceAssessment(
                                        id: assessment.id,
                                        substanceId: assessment.substanceId,
                                        neverUsed: assessment.neverUsed,
                                        lastUseDate: assessment.lastUseDate,
                                        durationYears: assessment.durationYears,
                                        durationMonths: newValue > 0 ? newValue : nil,
                                        frequency30Days: assessment.frequency30Days,
                                        routes: assessment.routes,
                                        conditionalAnswers: assessment.conditionalAnswers
                                    )
                                }
                            ), format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        }
                    }
                    
                    // Frequency in last 30 days
                    VStack(alignment: .leading) {
                        Text("Frequency in last 30 days:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        let frequencyOptions = [
                            ("daily", "4-7 days/week"),
                            ("regular", "1-3 days/week"),
                            ("occasional", "3 or less days/month"),
                            ("not_used", "Not used")
                        ]
                        
                        ForEach(frequencyOptions, id: \.0) { value, label in
                            Button(action: {
                                assessment = SubstanceAssessment(
                                    id: assessment.id,
                                    substanceId: assessment.substanceId,
                                    neverUsed: assessment.neverUsed,
                                    lastUseDate: assessment.lastUseDate,
                                    durationYears: assessment.durationYears,
                                    durationMonths: assessment.durationMonths,
                                    frequency30Days: value,
                                    routes: assessment.routes,
                                    conditionalAnswers: assessment.conditionalAnswers
                                )
                            }) {
                                HStack {
                                    Image(systemName: assessment.frequency30Days == value ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(assessment.frequency30Days == value ? .accentColor : .secondary)
                                    Text(label)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 2)
                        }
                    }
                    
                    // Routes of administration
                    VStack(alignment: .leading) {
                        Text("Routes (Select all that apply):")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        let routeOptions = [
                            ("oral", "Oral"),
                            ("nasal", "Nasal/snort"),
                            ("smoke", "Smoke"),
                            ("inject", "Inject"),
                            ("other", "Other (rectal, patches, etc.)")
                        ]
                        
                        ForEach(routeOptions, id: \.0) { value, label in
                            Button(action: {
                                var newRoutes = assessment.routes
                                if newRoutes.contains(value) {
                                    newRoutes.remove(value)
                                } else {
                                    newRoutes.insert(value)
                                }
                                
                                assessment = SubstanceAssessment(
                                    id: assessment.id,
                                    substanceId: assessment.substanceId,
                                    neverUsed: assessment.neverUsed,
                                    lastUseDate: assessment.lastUseDate,
                                    durationYears: assessment.durationYears,
                                    durationMonths: assessment.durationMonths,
                                    frequency30Days: assessment.frequency30Days,
                                    routes: newRoutes,
                                    conditionalAnswers: assessment.conditionalAnswers
                                )
                            }) {
                                HStack {
                                    Image(systemName: assessment.routes.contains(value) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(assessment.routes.contains(value) ? .accentColor : .secondary)
                                    Text(label)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 2)
                        }
                    }
                    
                    // Conditional questions toggle
                    if let conditionalQuestions = substanceDefinition?.conditionalQuestions, !conditionalQuestions.isEmpty {
                        Button(action: {
                            showingConditionalQuestions.toggle()
                        }) {
                            HStack {
                                Text("Additional Questions")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: showingConditionalQuestions ? "chevron.up" : "chevron.down")
                            }
                            .foregroundColor(.accentColor)
                        }
                        .padding(.top, 8)
                        
                        if showingConditionalQuestions {
                            ForEach(conditionalQuestions) { conditionalQuestion in
                                ConditionalQuestionView(
                                    question: conditionalQuestion,
                                    answer: .init(
                                        get: { assessment.conditionalAnswers[conditionalQuestion.id] ?? .string("") },
                                        set: { newValue in
                                            var newConditionalAnswers = assessment.conditionalAnswers
                                            newConditionalAnswers[conditionalQuestion.id] = newValue
                                            assessment = SubstanceAssessment(
                                                id: assessment.id,
                                                substanceId: assessment.substanceId,
                                                neverUsed: assessment.neverUsed,
                                                lastUseDate: assessment.lastUseDate,
                                                durationYears: assessment.durationYears,
                                                durationMonths: assessment.durationMonths,
                                                frequency30Days: assessment.frequency30Days,
                                                routes: assessment.routes,
                                                conditionalAnswers: newConditionalAnswers
                                            )
                                        }
                                    )
                                )
                            }
                        }
                    }
                }
                .padding(.leading, 16)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Substance Selector Sheet

struct SubstanceSelectorSheet: View {
    let availableSubstances: [SubstanceDefinition]
    let currentSubstances: [String]
    let onSubstanceSelected: (String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var availableOptions: [SubstanceDefinition] {
        availableSubstances.filter { !currentSubstances.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            List(availableOptions) { substance in
                Button(action: {
                    onSubstanceSelected(substance.id)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(substance.name)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "plus")
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Add Substance")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Conditional Question View

struct ConditionalQuestionView: View {
    let question: ConditionalQuestion
    @Binding var answer: QuestionValue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.text)
                .font(.subheadline)
                .fontWeight(.medium)
            
            switch question.type {
            case "number":
                TextField("Enter number", value: .init(
                    get: {
                        if case .number(let value) = answer {
                            return value
                        }
                        return 0
                    },
                    set: { newValue in
                        answer = .number(newValue)
                    }
                ), format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                
            case "boolean":
                Toggle("Yes", isOn: .init(
                    get: {
                        if case .bool(let value) = answer {
                            return value
                        }
                        return false
                    },
                    set: { newValue in
                        answer = .bool(newValue)
                    }
                ))
                
            case "single_choice":
                if let options = question.options {
                    ForEach(options) { option in
                        Button(action: {
                            answer = option.value
                        }) {
                            HStack {
                                Image(systemName: answer == option.value ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(answer == option.value ? .accentColor : .secondary)
                                Text(option.label)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                    }
                }
                
            default:
                TextField("Enter text", text: .init(
                    get: {
                        if case .string(let value) = answer {
                            return value
                        }
                        return ""
                    },
                    set: { newValue in
                        answer = .string(newValue)
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#if DEBUG
struct SubstanceGridView_Previews: PreviewProvider {
    static var previews: some View {
        SubstanceGridView(
            question: mockSubstanceQuestion,
            answer: .constant(.none),
            validationError: nil
        )
        .padding()
    }
    
    private static var mockSubstanceQuestion: Question {
        Question(
            id: "d1_04",
            text: "Substance Use Assessment",
            type: .dynamicSubstanceGrid,
            required: true,
            breadcrumb: "substance_assessment",
            visibleIf: nil,
            options: nil,
            validation: nil,
            description: "Complete assessment for each substance used. Use 'Add Substance' to assess additional substances.",
            substanceTemplate: nil,
            availableSubstances: [
                SubstanceDefinition(
                    id: "alcohol",
                    name: "Alcohol",
                    conditionalQuestions: [
                        ConditionalQuestion(
                            id: "alcohol_avg_drinks",
                            text: "Average drinks per drinking day",
                            type: "number",
                            visibleIf: nil,
                            validation: Validation(min: 0, max: 50, pattern: nil, minLength: nil, maxLength: nil),
                            options: nil
                        )
                    ]
                ),
                SubstanceDefinition(
                    id: "cannabis",
                    name: "Cannabis/Marijuana",
                    conditionalQuestions: nil
                )
            ]
        )
    }
}
#endif