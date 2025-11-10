//
//  SubstanceRowSheet.swift
//  ASAMAssessment
//
//  Modal sheet for editing substance use details (Domain 1 context)
//  T-0025: P0 critical for rules engine to fire accurate LOC recommendations
//

import SwiftUI

struct SubstanceRowSheet: View {
    @Binding var row: SubstanceRow
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Substance Group Section
                Section {
                    Picker("Substance Type", selection: $row.substanceGroup) {
                        ForEach(SubstanceGroup.allCases, id: \.self) { group in
                            Text(group.displayName).tag(group)
                        }
                    }
                } header: {
                    Text("Substance Information")
                } footer: {
                    Text("Select the primary substance category")
                }
                
                // Timeline Section
                Section {
                    if let hours = row.lastUseHours {
                        Stepper(value: Binding(
                            get: { hours },
                            set: { row.lastUseHours = $0 }
                        ), in: 0...720, step: 1) {
                            Text("Last use: \(hours) hours ago")
                        }
                    } else {
                        Button("Set Last Use Time") {
                            row.lastUseHours = 24
                        }
                    }
                    
                    if row.lastUseHours != nil {
                        Button("Clear Last Use Time", role: .destructive) {
                            row.lastUseHours = nil
                        }
                    }
                } header: {
                    Text("Use Timeline")
                } footer: {
                    Text("Time since most recent use (0-720 hours / 30 days)")
                }
                
                // Withdrawal Assessment Scores
                if row.substanceGroup == .opioid {
                    Section {
                        if let cows = row.cows {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("COWS Score: \(cows)")
                                    .font(.headline)
                                
                                Slider(value: Binding(
                                    get: { Double(cows) },
                                    set: { row.cows = Int($0) }
                                ), in: 0...48, step: 1)
                                
                                HStack {
                                    Text("None (0)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Moderate (13-24)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Severe (>36)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Button("Add COWS Assessment") {
                                row.cows = 0
                            }
                        }
                        
                        if row.cows != nil {
                            Button("Clear COWS Score", role: .destructive) {
                                row.cows = nil
                            }
                        }
                    } header: {
                        Text("Clinical Opiate Withdrawal Scale (COWS)")
                    } footer: {
                        Text("Objective assessment of opioid withdrawal severity (0-48)")
                    }
                }
                
                if row.substanceGroup == .alcohol {
                    Section {
                        if let ciwa = row.ciwa {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CIWA-Ar Score: \(ciwa)")
                                    .font(.headline)
                                
                                Slider(value: Binding(
                                    get: { Double(ciwa) },
                                    set: { row.ciwa = Int($0) }
                                ), in: 0...67, step: 1)
                                
                                HStack {
                                    Text("Minimal (<10)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Moderate (10-20)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Severe (>20)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Button("Add CIWA-Ar Assessment") {
                                row.ciwa = 0
                            }
                        }
                        
                        if row.ciwa != nil {
                            Button("Clear CIWA-Ar Score", role: .destructive) {
                                row.ciwa = nil
                            }
                        }
                    } header: {
                        Text("CIWA-Ar Assessment")
                    } footer: {
                        Text("Clinical Institute Withdrawal Assessment for Alcohol (0-67)")
                    }
                }
                
                // Route of Administration
                Section {
                    ForEach(RouteOfUse.allCases, id: \.self) { route in
                        Toggle(isOn: Binding(
                            get: { row.route.contains(route) },
                            set: { isOn in
                                if isOn {
                                    row.route.insert(route)
                                } else {
                                    row.route.remove(route)
                                }
                            }
                        )) {
                            HStack {
                                Text(route.displayName)
                                if route == .iv {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Route of Administration")
                } footer: {
                    Text("Select all routes that apply (multiple selections allowed)")
                }
            }
            .navigationTitle("Substance Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Substance List View

struct SubstanceListSection: View {
    @Binding var substances: [SubstanceRow]
    @State private var editingSubstance: SubstanceRow?
    @State private var showingSheet = false
    
    var body: some View {
        Section {
            ForEach($substances) { $substance in
                Button {
                    editingSubstance = substance
                    showingSheet = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(substance.substanceGroup.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let hours = substance.lastUseHours {
                                Text("Last use: \(hours)h ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let cows = substance.cows {
                                Text("COWS: \(cows)")
                                    .font(.caption)
                                    .foregroundColor(cowsColor(cows))
                            }
                            
                            if let ciwa = substance.ciwa {
                                Text("CIWA: \(ciwa)")
                                    .font(.caption)
                                    .foregroundColor(ciwaColor(ciwa))
                            }
                            
                            if !substance.route.isEmpty {
                                Text("Route: \(routesSummary(substance.route))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                substances.remove(atOffsets: indexSet)
            }
            
            Button {
                let newSubstance = SubstanceRow()
                substances.append(newSubstance)
                editingSubstance = newSubstance
                showingSheet = true
            } label: {
                Label("Add Substance", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Substances")
        } footer: {
            Text("Document all substances used. Clinical scores (COWS/CIWA) drive withdrawal management recommendations.")
        }
        .sheet(isPresented: $showingSheet) {
            if let index = substances.firstIndex(where: { $0.id == editingSubstance?.id }) {
                SubstanceRowSheet(row: $substances[index])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func cowsColor(_ score: Int) -> Color {
        if score < 5 { return .green }
        if score < 13 { return .yellow }
        if score < 25 { return .orange }
        return .red
    }
    
    private func ciwaColor(_ score: Int) -> Color {
        if score < 8 { return .green }
        if score < 15 { return .yellow }
        if score < 20 { return .orange }
        return .red
    }
    
    private func routesSummary(_ routes: Set<RouteOfUse>) -> String {
        let sorted = routes.sorted { $0.rawValue < $1.rawValue }
        if sorted.count <= 2 {
            return sorted.map { $0.displayName }.joined(separator: ", ")
        } else {
            return "\(sorted.first?.displayName ?? "") + \(sorted.count - 1) more"
        }
    }
}

// MARK: - Preview

#Preview("Substance Sheet") {
    @Previewable @State var sample = SubstanceRow(
        substanceGroup: .opioid,
        lastUseHours: 12,
        cows: 15,
        route: [.iv, .oral]
    )
    
    SubstanceRowSheet(row: $sample)
}

#Preview("Substance List") {
    @Previewable @State var substances = [
        SubstanceRow(substanceGroup: .opioid, lastUseHours: 12, cows: 15, route: [.iv]),
        SubstanceRow(substanceGroup: .alcohol, lastUseHours: 48, ciwa: 12, route: [.oral])
    ]
    
    Form {
        SubstanceListSection(substances: $substances)
    }
}
