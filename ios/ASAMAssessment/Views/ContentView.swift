//
//  ContentView.swift
//  ASAM Assessment Application
//
//  Main NavigationSplitView shell with 3-panel layout
//  T-0001: Implement NavigationSplitView shell and screens
//  WCAG 2.1 AA Compliant
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var assessmentStore: AssessmentStore
    @EnvironmentObject private var auditService: AuditService
    @EnvironmentObject private var locService: LOCService

    @State private var selectedAssessment: Assessment?
    @State private var selectedSection: NavigationSection?
    @State private var showSafetyBanner: Bool = false
    @State private var showNewAssessmentSheet: Bool = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // SIDEBAR: Assessment List
            assessmentListView
                .navigationTitle("Assessments")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            createNewAssessment()
                        } label: {
                            Label("New Assessment", systemImage: "plus.circle.fill")
                        }
                        .accessibilityLabel("Create new assessment")
                    }
                }
        } content: {
            // MIDDLE: Section Navigation
            if let assessment = selectedAssessment {
                sectionNavigationView(for: assessment)
                    .navigationTitle("Assessment Details")
            } else {
                ContentUnavailableView(
                    "No Assessment Selected",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Select an assessment from the sidebar or create a new one")
                )
            }
        } detail: {
            // DETAIL: Selected Section Content
            if let assessment = selectedAssessment,
               let section = selectedSection {
                sectionDetailView(for: assessment, section: section)
            } else {
                ContentUnavailableView(
                    "Select a Section",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Choose a section to view details")
                )
            }
        }
        .sheet(isPresented: $showSafetyBanner) {
            if let assessmentId = selectedAssessment?.id {
                SafetyBanner(assessmentId: assessmentId, isPresented: $showSafetyBanner)
            }
        }
        .sheet(isPresented: $showNewAssessmentSheet) {
            NewAssessmentSheet(isPresented: $showNewAssessmentSheet)
        }
        .onAppear {
            // Show safety banner on first launch
            if selectedAssessment != nil && !UserDefaults.standard.bool(forKey: "safety_banner_shown") {
                showSafetyBanner = true
                UserDefaults.standard.set(true, forKey: "safety_banner_shown")
            }
        }
    }

    // MARK: - Assessment List View

    private var assessmentListView: some View {
        List(selection: $selectedAssessment) {
            if assessmentStore.assessments.isEmpty {
                ContentUnavailableView(
                    "No Assessments",
                    systemImage: "doc.text",
                    description: Text("Create your first assessment to get started")
                )
            } else {
                ForEach(assessmentStore.assessments) { assessment in
                    AssessmentRowView(assessment: assessment)
                        .tag(assessment)
                        .accessibilityLabel("Assessment created \(assessment.createdAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .onDelete(perform: deleteAssessments)
            }
        }
    }

    // MARK: - Section Navigation View

    private func sectionNavigationView(for assessment: Assessment) -> some View {
        List(selection: $selectedSection) {
            Section("Assessment") {
                ForEach(NavigationSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.subheadline)
                                Text(section.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: section.icon)
                                .foregroundStyle(section.color)
                        }
                    }
                    .accessibilityLabel("\(section.title), \(section.description)")
                }
            }

            Section("Actions") {
                Button {
                    showSafetyBanner = true
                } label: {
                    Label("Review Safety", systemImage: "exclamationmark.shield")
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("Review safety criteria")

                Button {
                    generateLOCRecommendation(for: assessment)
                } label: {
                    Label("Calculate LOC", systemImage: "function")
                }
                .disabled(!assessment.isComplete)
                .accessibilityLabel("Calculate level of care recommendation")
                .accessibilityHint(assessment.isComplete ? "Generate recommendation" : "Complete all domains first")
            }
        }
    }

    // MARK: - Section Detail View

    private func sectionDetailView(for assessment: Assessment, section: NavigationSection) -> some View {
        Group {
            switch section {
            case .overview:
                AssessmentOverviewView(assessment: assessment)
            case .domains:
                DomainsListView(assessment: assessment)
            case .problems:
                ProblemsListView(assessment: assessment)
            case .locRecommendation:
                LOCRecommendationView(assessment: assessment)
            case .validation:
                ValidationView(assessment: assessment)
            case .export:
                ExportView(assessment: assessment)
            }
        }
        .navigationTitle(section.title)
    }

    // MARK: - Actions

    private func createNewAssessment() {
        let assessment = assessmentStore.createAssessment()
        selectedAssessment = assessment
        selectedSection = .overview

        auditService.logEvent(
            .assessmentCreated,
            actor: "assessor",
            assessmentId: assessment.id,
            notes: "New assessment created"
        )

        // Show safety banner for new assessment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showSafetyBanner = true
        }
    }

    private func deleteAssessments(at offsets: IndexSet) {
        for index in offsets {
            let assessment = assessmentStore.assessments[index]
            auditService.logEvent(
                .assessmentDeleted,
                actor: "assessor",
                assessmentId: assessment.id,
                notes: "Assessment deleted"
            )
            assessmentStore.deleteAssessment(assessment)
        }
    }

    private func generateLOCRecommendation(for assessment: Assessment) {
        let recommendation = locService.calculateLOC(for: assessment)
        var updated = assessment
        updated.locRecommendation = recommendation
        assessmentStore.updateAssessment(updated)

        auditService.logEvent(
            .locGenerated,
            actor: "system",
            assessmentId: assessment.id,
            action: "LOC calculated",
            notes: "Recommendation: \(recommendation.code) with confidence \(String(format: "%.0f%%", recommendation.confidence * 100))"
        )
    }
}

// MARK: - Navigation Section Enum

enum NavigationSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case domains = "Domains"
    case problems = "Problems"
    case locRecommendation = "LOC Recommendation"
    case validation = "Validation"
    case export = "Export"

    var id: String { rawValue }

    var title: String { rawValue }

    var description: String {
        switch self {
        case .overview: return "Assessment summary"
        case .domains: return "6 ASAM dimensions"
        case .problems: return "Clinical problems"
        case .locRecommendation: return "Level of care"
        case .validation: return "Completeness check"
        case .export: return "Generate PDF"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "doc.text"
        case .domains: return "square.grid.3x3"
        case .problems: return "exclamationmark.triangle"
        case .locRecommendation: return "chart.bar.doc.horizontal"
        case .validation: return "checkmark.seal"
        case .export: return "square.and.arrow.up"
        }
    }

    var color: Color {
        switch self {
        case .overview: return .blue
        case .domains: return .purple
        case .problems: return .orange
        case .locRecommendation: return .green
        case .validation: return .indigo
        case .export: return .teal
        }
    }
}

// MARK: - Supporting Views (Placeholders)

struct AssessmentRowView: View {
    let assessment: Assessment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(assessment.status.rawValue, systemImage: assessment.status.icon)
                    .font(.caption)
                    .foregroundStyle(assessment.status.color)
                Spacer()
                Text(assessment.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("Session: \(assessment.sessionId.prefix(8))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if assessment.isComplete {
                Label("Complete", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NewAssessmentSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        Text("New Assessment Form")
            .navigationTitle("New Assessment")
    }
}

struct AssessmentOverviewView: View {
    let assessment: Assessment
    var body: some View {
        Text("Overview for \(assessment.sessionId)")
    }
}

struct DomainsListView: View {
    let assessment: Assessment
    var body: some View {
        List(assessment.domains) { domain in
            VStack(alignment: .leading) {
                Text("Domain \(domain.number): \(domain.title)")
                Text("Severity: \(domain.severity)")
                    .font(.caption)
            }
        }
    }
}

struct ProblemsListView: View {
    let assessment: Assessment
    var body: some View {
        List(assessment.problems) { problem in
            Text(problem.title)
        }
    }
}

struct LOCRecommendationView: View {
    let assessment: Assessment
    var body: some View {
        if let rec = assessment.locRecommendation {
            VStack {
                Text("Recommended: \(rec.name)")
                Text("Code: \(rec.code)")
            }
        } else {
            Text("No recommendation yet")
        }
    }
}

struct ValidationView: View {
    let assessment: Assessment
    var body: some View {
        List(assessment.validationGates) { gate in
            HStack {
                Image(systemName: gate.isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(gate.isPassed ? .green : .red)
                Text(gate.title)
            }
        }
    }
}

struct ExportView: View {
    let assessment: Assessment
    var body: some View {
        Text("Export options")
    }
}

#Preview {
    ContentView()
        .environmentObject(AssessmentStore())
        .environmentObject(AuditService())
        .environmentObject(LOCService())
}
