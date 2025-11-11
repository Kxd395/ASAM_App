//
//  ClinicalFlagsSection.swift
//  ASAMAssessment
//
//  Clinical indicators section for assessment forms
//  T-0026: P0 critical for rules engine to fire accurate LOC recommendations
//

import SwiftUI

struct ClinicalFlagsSection: View {
    @Binding var vitalsUnstable: Bool
    @Binding var pregnant: Bool
    @Binding var noWithdrawalSigns: Bool
    @Binding var acutePsych: Bool

    var body: some View {
        Section {
            Toggle(isOn: $vitalsUnstable) {
                HStack {
                    Image(systemName: vitalsUnstable ? "heart.fill" : "heart")
                        .foregroundColor(vitalsUnstable ? .red : .secondary)
                    Text("Vitals Unstable")
                }
            }

            Toggle(isOn: $pregnant) {
                HStack {
                    Image(systemName: pregnant ? "figure.and.child.holdinghands" : "figure")
                        .foregroundColor(pregnant ? .pink : .secondary)
                    Text("Pregnant")
                }
            }

            Toggle(isOn: $noWithdrawalSigns) {
                HStack {
                    Image(systemName: noWithdrawalSigns ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(noWithdrawalSigns ? .green : .secondary)
                    Text("No Withdrawal Signs")
                }
            }

            Toggle(isOn: $acutePsych) {
                HStack {
                    Image(systemName: acutePsych ? "exclamationmark.triangle.fill" : "brain")
                        .foregroundColor(acutePsych ? .orange : .secondary)
                    Text("Acute Psychiatric Risk")
                }
            }
        } header: {
            Text("Clinical Indicators")
        } footer: {
            Text("These flags influence withdrawal management and level of care recommendations")
        }
    }
}

// MARK: - Preview

#Preview("Clinical Flags") {
    @Previewable @State var vitalsUnstable = false
    @Previewable @State var pregnant = false
    @Previewable @State var noWithdrawalSigns = true
    @Previewable @State var acutePsych = false

    Form {
        ClinicalFlagsSection(
            vitalsUnstable: $vitalsUnstable,
            pregnant: $pregnant,
            noWithdrawalSigns: $noWithdrawalSigns,
            acutePsych: $acutePsych
        )
    }
}
