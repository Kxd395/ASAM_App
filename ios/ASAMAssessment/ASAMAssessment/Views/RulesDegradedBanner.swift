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
            RulesDiagnosticsView()
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
