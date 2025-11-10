//
//  SafetyReviewSheet.swift
//  ASAM Assessment Application
//
//  Enhanced Safety Review with auto-focus, stable keyboard handling,
//  validation, haptics, and Settings integration
//  WCAG 2.1 AA Compliant
//

import SwiftUI
import Combine

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
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
                .ignoresSafeArea(.keyboard, edges: .bottom)     // prevents sheet "jump"
                .onChange(of: actionTaken) { _, newValue in
                    guard newValue != nil else { return }
                    // Allow picker to collapse before focusing.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        // Optional: auto-stub notes for the common case
                        if notes.isEmpty, newValue == .noRiskIdentified {
                            notes = "No immediate risk identified. "
                        }
                        focusedField = .notes
                        withAppropriateAnimation {
                            proxy.scrollTo("notes", anchor: .bottom)
                        }
                    }
                }
            }
            .navigationTitle("Safety Review")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents(preferredDetents)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true) // must complete
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
            .frame(minHeight: 120)
            .padding(12)
            .background(.background, in: .rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1)
            )
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .accessibilityIdentifier("notesField")
            .accessibilityLabel("Safety review notes")
            .accessibilityHint("Describe the action taken and current status")
    }

    // MARK: - Logic

    private var canContinue: Bool {
        (actionTaken != nil) &&
        !notes.trimmed.isEmpty &&
        acknowledged
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

    private var preferredDetents: Set<PresentationDetent> {
        // Settings-aware detents for iPad/large text
        if dts >= .accessibility2 {
            return [.fraction(0.6), .large]
        }
        // Honor settings default (large by default for safety review)
        return [.large, .medium]
    }

    private func withAppropriateAnimation(_ block: @escaping () -> Void) {
        if settings.reduceMotion {
            block()
        } else {
            withAnimation(.easeInOut(duration: 0.25), block)
        }
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
