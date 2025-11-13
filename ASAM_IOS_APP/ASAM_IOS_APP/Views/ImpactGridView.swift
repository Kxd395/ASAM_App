//
//  ImpactGridView.swift
//  Treatment Plan Assistant
//
//  Created by Agent on 2025-11-12
//  D4 Life Areas Impact Assessment Grid
//

import SwiftUI

struct ImpactGridView: View {
    let question: Question
    let metadata: ImpactGridMetadata
    @Binding var answer: AnswerValue?
    
    @State private var selections: [String: String] = [:]  // [itemId: scaleValue]
    @State private var notes: [String: String] = [:]  // [itemId: note text]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text(question.text)
                .font(.headline)
                .padding(.horizontal)
            
            if let helpText = question.helpText {
                Text(helpText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Impact grid
            ScrollView {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 4) {
                        // Life area column
                        Text("Life Area")
                            .font(.caption.bold())
                            .frame(width: 120, alignment: .leading)
                            .padding(.horizontal, 8)
                        
                        // Scale option columns
                        ForEach(metadata.scaleOptions) { option in
                            Text(option.label)
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    
                    Divider()
                    
                    // Impact items
                    ForEach(Array(metadata.impactItems.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            HStack(spacing: 4) {
                                // Life area label
                                Text(item.label)
                                    .font(.body)
                                    .frame(width: 120, alignment: .leading)
                                    .padding(.horizontal, 8)
                                
                                // Rating buttons
                                ForEach(metadata.scaleOptions) { option in
                                    Button(action: {
                                        selectOption(for: item.id, value: option.value)
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selections[item.id] == option.value ? colorForScore(option.score) : Color.gray.opacity(0.1))
                                            
                                            if selections[item.id] == option.value {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                                    .font(.caption.bold())
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 40)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            // Note field if required
                            if item.requiresNote, let note = notes[item.id] ?? "" as String?, !note.isEmpty || selections[item.id] != nil {
                                HStack {
                                    Text("Note:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    TextField("Additional details...", text: Binding(
                                        get: { notes[item.id] ?? "" },
                                        set: { newValue in
                                            // Update local state immediately for responsive UI
                                            notes[item.id] = newValue
                                        }
                                    ), onCommit: {
                                        // Save only when user is done editing
                                        saveAnswer()
                                    })
                                    .textFieldStyle(.roundedBorder)
                                    .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                            }
                            
                            if index < metadata.impactItems.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .onAppear {
            loadAnswer()
        }
        .onChange(of: notes) { _, _ in
            // Save answer whenever notes change (after onCommit debounce)
            saveAnswer()
        }
    }
    
    private func selectOption(for itemId: String, value: String) {
        selections[itemId] = value
        saveAnswer()
    }
    
    private func loadAnswer() {
        // Load from existing answer if present
        // For now, initialize with empty selections
        if case .impactGrid(let gridData) = answer {
            selections = gridData.selections
            notes = gridData.notes
        }
    }
    
    private func saveAnswer() {
        // Save answer in impact grid format
        answer = .impactGrid(ImpactGridAnswer(
            selections: selections,
            notes: notes
        ))
    }
    
    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 0: return .gray
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
}
