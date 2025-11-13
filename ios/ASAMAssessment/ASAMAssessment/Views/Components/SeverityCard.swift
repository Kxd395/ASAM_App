//
//  SeverityCard.swift
//  ASAMAssessment
//
//  Reusable severity rating card component
//

import SwiftUI

struct SeverityCard: View {
    let option: SeverityOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with colored dot and title
                HStack(spacing: 8) {
                    Circle()
                        .fill(option.tone.color)
                        .frame(width: 12, height: 12)

                    Text(option.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()
                }

                // Clinical criteria bullets
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(option.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.caption)
                            Text(bullet)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Disposition strip
                if !option.disposition.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disposition:")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Text(option.disposition)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(6)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? option.tone.color : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? option.tone.color.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: 0
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        SeverityCard(
            option: D2SeverityContent.options[2],
            isSelected: false,
            onSelect: {}
        )

        SeverityCard(
            option: D2SeverityContent.options[4],
            isSelected: true,
            onSelect: {}
        )
    }
    .padding()
}
