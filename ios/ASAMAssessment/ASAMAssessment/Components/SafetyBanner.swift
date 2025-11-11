//
//  SafetyBanner.swift
//  ASAM Assessment Application
//
//  CRITICAL: Stop-ship safety banner with mandatory audit logging
//  Must be acknowledged with action type before proceeding
//  WCAG 2.1 AA Compliant
//

import SwiftUI

/// Safety Banner Component - Modal implementation with audit trail
struct SafetyBanner: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auditService: AuditService

    let assessmentId: UUID
    @Binding var isPresented: Bool
    @State private var selectedAction: SafetyAction?
    @State private var notes: String = ""
    @State private var hasAcknowledged: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Warning")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Clinical Safety Alert")
                                .font(.headline)
                                .foregroundStyle(.red)

                            Text("Review safety considerations before proceeding with assessment")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("⚠️ MANDATORY REVIEW")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Section {
                    Text("• Immediate risk of harm to self or others")
                    Text("• Active withdrawal requiring medical supervision")
                    Text("• Severe mental health crisis")
                    Text("• Inability to care for basic needs")

                    if hasAcknowledged {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Acknowledged")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("IMMEDIATE ESCALATION CRITERIA")
                } footer: {
                    Text("If any of these conditions are present, escalate immediately to emergency services")
                        .font(.caption)
                }

                Section {
                    Picker("Action Taken", selection: $selectedAction) {
                        Text("Select action...").tag(Optional<SafetyAction>.none)
                        ForEach(SafetyAction.allCases) { action in
                            Text(action.rawValue).tag(Optional(action))
                        }
                    }
                    .accessibilityLabel("Select safety action taken")

                    if selectedAction != nil {
                        TextField("Notes (required)", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .accessibilityLabel("Safety review notes")
                            .accessibilityHint("Describe the action taken and current status")
                    }
                } header: {
                    Text("REQUIRED ACTION")
                } footer: {
                    Text("Document action taken before continuing assessment")
                        .font(.caption)
                }

                Section {
                    Toggle(isOn: $hasAcknowledged) {
                        Text("I have reviewed safety criteria and documented appropriate action")
                            .font(.system(size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.15))
                    }
                    .tint(.red)
                    .accessibilityLabel("Acknowledge safety review")
                }
            }
            .navigationTitle("Safety Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        auditService.logEvent(
                            .safetyBannerDismissed,
                            actor: "assessor",
                            assessmentId: assessmentId,
                            notes: "Safety banner dismissed without acknowledgment"
                        )
                        isPresented = false
                        dismiss()
                    }
                    .accessibilityLabel("Cancel safety review")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        handleContinue()
                    }
                    .disabled(!canContinue)
                    .accessibilityLabel("Continue with assessment")
                    .accessibilityHint(canContinue ? "Safety review complete, proceed with assessment" : "Complete all required fields to continue")
                }
            }
        }
        .interactiveDismissDisabled(!hasAcknowledged)  // Prevent swipe to dismiss
    }

    private var canContinue: Bool {
        hasAcknowledged && selectedAction != nil && !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleContinue() {
        guard let action = selectedAction else { return }

        // Log to audit trail (NO PHI)
        auditService.logEvent(
            .safetyBannerAcknowledged,
            actor: "assessor",
            assessmentId: assessmentId,
            action: "Safety review completed: \(action.rawValue)",
            notes: "Action taken documented. Notes length: \(notes.count) chars"  // Don't log actual notes (may contain PHI)
        )

        isPresented = false
        dismiss()
    }
}

/// Safety action types
enum SafetyAction: String, CaseIterable, Identifiable {
    case noRiskIdentified = "No immediate risk identified"
    case monitoringPlan = "Monitoring plan established"
    case escalated = "Escalated to supervisor/emergency services"
    case consultRequested = "Consultation requested"
    case transportArranged = "Emergency transport arranged"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .noRiskIdentified: return "checkmark.shield"
        case .monitoringPlan: return "eye.circle"
        case .escalated: return "exclamationmark.triangle.fill"
        case .consultRequested: return "person.2"
        case .transportArranged: return "cross.case.fill"
        }
    }

    var color: Color {
        switch self {
        case .noRiskIdentified: return .green
        case .monitoringPlan: return .blue
        case .escalated: return .red
        case .consultRequested: return .orange
        case .transportArranged: return .red
        }
    }
}

#Preview {
    SafetyBanner(assessmentId: UUID(), isPresented: .constant(true))
        .environmentObject(AuditService())
}
