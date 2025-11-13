//
//  D2SeveritySection.swift
//  ASAMAssessment
//
//  Domain 2 Severity Rating Section
//  Rich card-based severity selector with emergency alerts
//

import SwiftUI

struct D2SeveritySection: View {
    @Binding var selectedSeverity: Int
    @State private var showEmergencyAlert = false

    var selectedOption: SeverityOption? {
        D2SeverityContent.options.first { $0.value == selectedSeverity }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header section
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Severity Rating:")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Tap a card to select the appropriate severity level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // Severity cards grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(D2SeverityContent.options) { option in
                        SeverityCard(
                            option: option,
                            isSelected: selectedSeverity == option.value,
                            onSelect: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedSeverity = option.value
                                }

                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()

                                // Show emergency alert if severity 4
                                if option.value == 4 {
                                    showEmergencyAlert = true
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Emergency banner for severity 4
            if selectedSeverity == 4, let emergencyOption = D2SeverityContent.options.first(where: { $0.value == 4 }) {
                emergencyBanner(for: emergencyOption)
            }
        }
        .padding(.vertical)
    }

    @ViewBuilder
    private func emergencyBanner(for option: SeverityOption) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                Text("EMERGENCY ALERT")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
            }

            Text("Emergency risk. Consider ED evaluation now.")
                .font(.subheadline)
                .fontWeight(.semibold)

            if let emergencyList = option.emergencyList {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Watch for:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(emergencyList, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.caption)
                            Text(item)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    D2SeveritySection(selectedSeverity: .constant(3))
}
