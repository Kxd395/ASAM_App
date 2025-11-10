//
//  FlagsSection.swift
//  ASAMAssessment
//
//  Clinical flags/risk indicators for rules engine
//

import SwiftUI

struct FlagsSection: View {
    @Binding var vitalsUnstable: Bool
    @Binding var pregnant: Bool
    @Binding var noWithdrawalSigns: Bool
    @Binding var acutePsych: Bool

    var body: some View {
        Section {
            Toggle(isOn: $vitalsUnstable) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vitals Unstable")
                        .font(.body)
                    Text("Blood pressure, heart rate, or temperature outside safe range")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $pregnant) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pregnant")
                        .font(.body)
                    Text("Currently pregnant or suspected pregnancy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $noWithdrawalSigns) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No Withdrawal Signs")
                        .font(.body)
                    Text("Patient not showing physiological withdrawal symptoms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $acutePsych) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Acute Psychiatric Crisis")
                        .font(.body)
                    Text("Active psychosis, severe depression, or suicidality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label("Clinical Flags", systemImage: "flag.fill")
        } footer: {
            Text("These flags affect LOC and WM recommendations")
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    Form {
        FlagsSection(
            vitalsUnstable: .constant(false),
            pregnant: .constant(false),
            noWithdrawalSigns: .constant(true),
            acutePsych: .constant(false)
        )
    }
}
