//
//  SubstanceSheet.swift
//  ASAMAssessment
//
//  Sheet for adding/editing substance use entries (Domain 1)
//

import SwiftUI

struct SubstanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var substance: SubstanceRow
    
    var body: some View {
        NavigationView {
            Form {
                Section("Substance Information") {
                    Picker("Substance Group", selection: $substance.substanceGroup) {
                        ForEach(SubstanceGroup.allCases, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                }
                
                Section("Usage Timeline") {
                    HStack {
                        Text("Last Use (hours ago)")
                        Spacer()
                        TextField("Hours", value: $substance.lastUseHours, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("Withdrawal Assessment") {
                    if substance.substanceGroup == .opioid {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COWS Score (0-48)")
                                .font(.subheadline)
                            HStack {
                                Text("0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: Binding(
                                    get: { Double(substance.cows ?? 0) },
                                    set: { substance.cows = Int($0) }
                                ), in: 0...48, step: 1)
                                Text("48")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(substance.cows ?? 0)")
                                    .font(.headline)
                                    .frame(width: 40)
                            }
                            Text(cowsInterpretation(substance.cows ?? 0))
                                .font(.caption)
                                .foregroundColor(cowsColor(substance.cows ?? 0))
                        }
                    }
                    
                    if substance.substanceGroup == .alcohol {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CIWA-Ar Score (0-67)")
                                .font(.subheadline)
                            HStack {
                                Text("0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: Binding(
                                    get: { Double(substance.ciwa ?? 0) },
                                    set: { substance.ciwa = Int($0) }
                                ), in: 0...67, step: 1)
                                Text("67")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(substance.ciwa ?? 0)")
                                    .font(.headline)
                                    .frame(width: 40)
                            }
                            Text(ciwaInterpretation(substance.ciwa ?? 0))
                                .font(.caption)
                                .foregroundColor(ciwaColor(substance.ciwa ?? 0))
                        }
                    }
                }
                
                Section("Route of Use") {
                    ForEach(RouteOfUse.allCases, id: \.self) { route in
                        Toggle(route.displayName, isOn: Binding(
                            get: { substance.route.contains(route) },
                            set: { isOn in
                                if isOn {
                                    substance.route.insert(route)
                                } else {
                                    substance.route.remove(route)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Substance Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - COWS Interpretation
    
    private func cowsInterpretation(_ score: Int) -> String {
        switch score {
        case 0...4: return "Minimal withdrawal"
        case 5...12: return "Mild withdrawal"
        case 13...24: return "Moderate withdrawal"
        case 25...36: return "Moderately severe withdrawal"
        default: return "Severe withdrawal"
        }
    }
    
    private func cowsColor(_ score: Int) -> Color {
        switch score {
        case 0...4: return .green
        case 5...12: return .yellow
        case 13...24: return .orange
        default: return .red
        }
    }
    
    // MARK: - CIWA Interpretation
    
    private func ciwaInterpretation(_ score: Int) -> String {
        switch score {
        case 0...7: return "Minimal withdrawal"
        case 8...15: return "Mild to moderate withdrawal"
        case 16...20: return "Moderate withdrawal"
        default: return "Severe withdrawal"
        }
    }
    
    private func ciwaColor(_ score: Int) -> Color {
        switch score {
        case 0...7: return .green
        case 8...15: return .yellow
        case 16...20: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    SubstanceSheet(substance: .constant(SubstanceRow(
        substanceGroup: .opioid,
        lastUseHours: 12,
        cows: 15
    )))
}
