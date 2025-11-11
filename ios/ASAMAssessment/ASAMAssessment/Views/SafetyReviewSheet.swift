//
//  SafetyReviewSheet.swift
//  ASAM Assessment Application
//
//  Enhanced Safety Review with auto-focus, stable keyboard handling,
//  validation, haptics, and Settings integration
//  WCAG 2.1 AA Compliant
//

import SwiftUI
import UIKit
import Combine

/// Safety action types with validation requirements
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
    
    /// Whether notes are required for this action
    var notesRequired: Bool {
        return true // All safety actions require notes
    }
    
    /// Minimum notes length required
    var minNotesLength: Int {
        switch self {
        case .noRiskIdentified: return 10
        case .monitoringPlan: return 15
        case .escalated: return 20
        case .consultRequested: return 15
        case .transportArranged: return 20
        }
    }
    
    /// Default notes stub to help user get started
    var defaultNotes: String {
        switch self {
        case .noRiskIdentified: return "No immediate risk identified. "
        case .monitoringPlan: return "Monitoring plan established. "
        case .escalated: return "Escalated due to immediate safety concern. "
        case .consultRequested: return "Consultation requested for "
        case .transportArranged: return "Emergency transport arranged. "
        }
    }
}

/// Audit event types for safety review
enum AuditEventType {
    case safetyBannerAcknowledged
    case safetyBannerDismissed
}

/// Mock AuditService for now (replace with real implementation)
class AuditService: ObservableObject {
    func logEvent(_ event: AuditEventType, actor: String, assessmentId: UUID, action: String? = nil, notes: String) {
        print("📝 Audit: \(event) by \(actor) for \(assessmentId)")
        if let action = action { print("   Action: \(action)") }
        print("   Notes: \(notes)")
    }
}

/// Mock AppSettings for now (replace with real implementation)
class AppSettings: ObservableObject {
    @Published var reduceMotion: Bool = false
}

/// Result of safety review completion
struct SafetyReviewResult {
    let action: SafetyAction
    let notes: String
    let acknowledged: Bool
}

/// Enhanced Safety Review Sheet with auto-focus and stable keyboard behavior
struct SafetyReviewSheet: View {
    enum Field { case notes }

    // MARK: - Bindings
    @Binding var isPresented: Bool
    let assessmentId: UUID
    let onContinue: (SafetyReviewResult) -> Void

    // MARK: - State
    @State private var actionTaken: SafetyAction? = nil
    @State private var notes: String = ""
    @State private var acknowledged = false
    @State private var showInlineError = false
    @State private var detent: PresentationDetent = .large

    // MARK: - Environment
    @FocusState private var focusedField: Field?
    @Environment(\.dynamicTypeSize) private var dts
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var auditService: AuditService

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {

                        // --- Header / Alert
                        headerCard

                        // --- Criteria list
                        escalationCriteriaCard

                        // --- Required Action
                        Section {
                            actionPicker

                            notesEditor
                                .id("notes")
                                .focused($focusedField, equals: .notes)

                            if showInlineError && notes.trimmed.isEmpty {
                                Text("Notes are required.")
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityIdentifier("notesError")
                            }
                        } header: {
                            Text("REQUIRED ACTION")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // --- Acknowledgement
                        Toggle("I have reviewed safety criteria and documented appropriate action",
                               isOn: $acknowledged)
                            .toggleStyle(.switch)
                            .tint(.red)
                            .accessibilityIdentifier("ackToggle")
                        
                        // --- Helper text showing what's needed
                        continueHelper
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
                .ignoresSafeArea(.keyboard, edges: .bottom)     // prevents sheet "jump"
                .onChange(of: actionTaken) { oldValue, newValue in
                    guard newValue != nil else { return }
                    // Auto-prefill notes if empty
                    if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        notes = newValue!.defaultNotes
                    }
                    // Short delay to avoid keyboard-induced detent snap
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        focusedField = .notes
                        withAppropriateAnimation {
                            proxy.scrollTo("notes", anchor: .bottom)
                        }
                    }
                }
            }
            .navigationTitle("Safety Review")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.large, .medium], selection: $detent)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true) // must complete
            .onAppear {
                // Open at full height by default, user can resize
                detent = .large
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        auditService.logEvent(
                            .safetyBannerDismissed,
                            actor: "assessor",
                            assessmentId: assessmentId,
                            notes: "Safety review cancelled without completion"
                        )
                        isPresented = false
                    }
                    .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { validateAndContinue() }
                        .disabled(!canContinue)
                        .accessibilityIdentifier("continueButton")
                        .accessibilityHint(canContinue ? "Safety review complete, proceed" : "Complete all required fields")
                }
            }
            .accessibilityIdentifier("safetyReviewSheet")
            .onAppear {
                // If the action is preselected upstream, focus notes.
                if actionTaken != nil && notes.isEmpty {
                    DispatchQueue.main.async { focusedField = .notes }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
                .accessibilityLabel("Warning")

            VStack(alignment: .leading, spacing: 6) {
                Text("Clinical Safety Alert")
                    .font(.headline)
                    .foregroundStyle(.red)

                Text("Review safety considerations before proceeding with assessment")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.red.opacity(0.08), in: .rect(cornerRadius: 14))
        .accessibilityIdentifier("alertCard")
    }

    private var escalationCriteriaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IMMEDIATE ESCALATION CRITERIA")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            bullet("Immediate risk of harm to self or others")
            bullet("Active withdrawal requiring medical supervision")
            bullet("Severe mental health crisis")
            bullet("Inability to care for basic needs")

            Text("If any of these conditions are present, escalate immediately to emergency services")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
            Text(text)
        }
        .accessibilityElement(children: .combine)
    }

    private var actionPicker: some View {
        Picker("Action Taken", selection: $actionTaken) {
            Text("Select action...").tag(Optional<SafetyAction>.none)
            ForEach(SafetyAction.allCases) { action in
                HStack {
                    Image(systemName: action.icon)
                    Text(action.rawValue)
                }
                .tag(Optional(action))
            }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("actionPicker")
        .accessibilityLabel("Select safety action taken")
    }

    @ViewBuilder private var notesEditor: some View {
        TextEditor(text: $notes)
            .frame(minHeight: 160)
            .padding(12)
            .background(.background, in: .rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1)
            )
            .autocapitalization(.sentences)
            .accessibilityIdentifier("notesField")
            .accessibilityLabel("Safety review notes")
            .accessibilityHint("Describe the action taken and current status")
    }

    // MARK: - Logic

    private var canContinue: Bool {
        guard let action = actionTaken else { return false }
        
        // Check if notes meet requirements for this action
        let notesOK = action.notesRequired
            ? notes.trimmingCharacters(in: .whitespacesAndNewlines).count >= action.minNotesLength
            : true
        
        return notesOK && acknowledged
    }
    
    @ViewBuilder private var continueHelper: some View {
        if actionTaken == nil {
            HelperRow(icon: "exclamationmark.circle", text: "Select an action")
        } else if let action = actionTaken, action.notesRequired,
                  notes.trimmingCharacters(in: .whitespacesAndNewlines).count < action.minNotesLength {
            HelperRow(icon: "square.and.pencil", text: "Add a brief note (\(action.minNotesLength) chars minimum)")
        } else if !acknowledged {
            HelperRow(icon: "checkmark.circle", text: "Acknowledge review")
        }
    }

    private func validateAndContinue() {
        guard canContinue else {
            // Focus notes + inline error + gentle haptic
            showInlineError = true
            focusedField = .notes
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        // Log to audit trail (NO PHI)
        auditService.logEvent(
            .safetyBannerAcknowledged,
            actor: "assessor",
            assessmentId: assessmentId,
            action: "Safety review completed: \(actionTaken!.rawValue)",
            notes: "Action documented. Notes length: \(notes.count) chars"
        )

        onContinue(.init(action: actionTaken!, notes: notes.trimmed, acknowledged: acknowledged))
        isPresented = false
    }

    private func withAppropriateAnimation(_ block: @escaping () -> Void) {
        if settings.reduceMotion {
            block()
        } else {
            withAnimation(.easeInOut(duration: 0.25), block)
        }
    }
}

// MARK: - Helper Row Component
private struct HelperRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        Label(text, systemImage: icon)
            .foregroundStyle(.secondary)
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}

// MARK: - String helper
private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Preview
#Preview {
    SafetyReviewSheet(
        isPresented: .constant(true),
        assessmentId: UUID()
    ) { result in
        print("Action: \(result.action.rawValue)")
        print("Notes: \(result.notes)")
    }
    .environmentObject(AppSettings())
    .environmentObject(AuditService())
}
