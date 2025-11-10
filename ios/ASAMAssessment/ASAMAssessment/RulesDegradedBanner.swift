//
//  RulesDegradedBanner.swift
//  ASAMAssessment
//
//  Warning banner for degraded rules engine state
//

import SwiftUI

struct RulesDegradedBanner: View {
    let message: String
    @State private var showDiagnostics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rules Engine Unavailable")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Using 2.1 fallback. Export disabled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showDiagnostics = true
                } label: {
                    Label("Details", systemImage: "info.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showDiagnostics) {
            RulesDiagnosticsView(message: message)
        }
    }
}

struct RulesDiagnosticsView: View {
    let message: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rules Engine Status")
                                .font(.headline)
                            Text("Degraded")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Status")
                }
                
                Section {
                    Text(message)
                        .font(.body)
                } header: {
                    Text("Error Details")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• All LOC recommendations defaulting to 2.1 Intensive Outpatient")
                        Text("• WM recommendations unavailable")
                        Text("• PDF export is blocked")
                        Text("• Assessment can be saved as draft")
                    }
                    .font(.subheadline)
                } header: {
                    Text("Impact")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Verify rules files exist in app bundle:")
                        Text("   • rules/wm_ladder.json")
                        Text("   • rules/loc_indication.guard.json")
                        Text("   • rules/operators.json")
                            .padding(.bottom, 8)
                        
                        Text("2. Check file permissions and bundle configuration")
                            .padding(.bottom, 8)
                        
                        Text("3. If issue persists, reinstall the application")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } header: {
                    Text("Troubleshooting")
                }
            }
            .navigationTitle("Rules Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Banner") {
    VStack {
        RulesDegradedBanner(message: "Rules files not found in bundle")
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Diagnostics") {
    RulesDiagnosticsView(message: "Rules files not found in bundle")
}
