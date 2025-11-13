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
                            .foregroundColor(.primary)
                            .frame(width: 180, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))

                        // Scale option columns with color coding
                        ForEach(metadata.scaleOptions) { option in
                            Text(option.label)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 8)
                                .background(colorForScore(option.score).opacity(0.9))
                        }
                    }
                    .padding(.vertical, 0)

                    Divider()

                    // Impact items
                    ForEach(Array(metadata.impactItems.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            HStack(spacing: 4) {
                                // Life area label
                                Text(item.label)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(width: 180, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .background(Color.white)

                                // Rating buttons
                                ForEach(metadata.scaleOptions) { option in
                                    Button(action: {
                                        selectOption(for: item.id, value: option.value)
                                    }) {
                                        ZStack {
                                            // Background with column color or white
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(selections[item.id] == option.value
                                                    ? colorForScore(option.score)
                                                    : Color.white)

                                            // Border
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(
                                                    selections[item.id] == option.value
                                                        ? colorForScore(option.score)
                                                        : Color.gray.opacity(0.4),
                                                    lineWidth: selections[item.id] == option.value ? 2 : 1
                                                )

                                            // Checkmark when selected
                                            if selections[item.id] == option.value {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 16, weight: .bold))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
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
                                        set: { updateNote(for: item.id, text: $0) }
                                    ))
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
    }

    private func selectOption(for itemId: String, value: String) {
        selections[itemId] = value
        saveAnswer()
    }

    private func updateNote(for itemId: String, text: String) {
        notes[itemId] = text
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
        case 0: return Color(red: 72/255, green: 187/255, blue: 120/255)  // Green #48bb78
        case 1: return Color(red: 132/255, green: 204/255, blue: 22/255) // Lime #84cc16
        case 2: return Color(red: 250/255, green: 204/255, blue: 21/255) // Yellow #facc15
        case 3: return Color(red: 251/255, green: 146/255, blue: 60/255) // Orange #fb923c
        case 4: return Color(red: 239/255, green: 68/255, blue: 68/255)  // Red #ef4444
        default: return .gray
        }
    }
}
