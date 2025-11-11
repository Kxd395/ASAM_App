//
//  ContentView.swift
//  ASAM Assessment Application
//
//  Main NavigationSplitView shell with 3-panel layout
//  T-0001: Implement NavigationSplitView shell and screens
//  WCAG 2.1 AA Compliant
//

import SwiftUI
import UIKit  // For ShareSheet (UIActivityViewController)

struct ContentView: View {
    @EnvironmentObject private var assessmentStore: AssessmentStore
    @EnvironmentObject private var auditService: AuditService
    @EnvironmentObject private var rulesService: RulesServiceWrapper  // NEW: Rules engine
    @EnvironmentObject private var networkChecker: NetworkSanityChecker  // NEW: Network monitoring
    @EnvironmentObject private var uploadQueue: UploadQueue  // NEW: Upload queue
    @EnvironmentObject private var settings: AppSettings  // NEW: Display settings

    @State private var selectedAssessment: Assessment?
    @State private var selectedSection: NavigationSection?
    @State private var showSafetyBanner: Bool = false
    @State private var safetyBannerDetent: PresentationDetent = .large  // NEW: For resizable sheets
    @State private var showNewAssessmentSheet: Bool = false
    @State private var showRulesDiagnostics: Bool = false  // NEW: Rules diagnostics
    @State private var showNetworkAlert: Bool = false  // NEW: Network warning
    @State private var showSettings: Bool = false  // NEW: Settings sheet
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        VStack(spacing: 0) {
            // NEW: Show degraded rules banner if rules engine unavailable
            if !rulesService.isAvailable {
                RulesDegradedBanner(message: rulesService.errorMessage ?? "Rules engine unavailable")
                    .onTapGesture {
                        showRulesDiagnostics = true
                    }
            }

            NavigationSplitView(columnVisibility: $columnVisibility) {
            // SIDEBAR: Assessment List
            assessmentListView
                .navigationTitle("Assessments")
                .toolbar {
                    // NEW: Network status indicator
                    ToolbarItem(placement: .topBarLeading) {
                        networkStatusIndicator
                    }
                    
                    // NEW: Settings button
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .accessibilityLabel("Open settings")
                    }

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
                SafetyReviewSheet(
                    isPresented: $showSafetyBanner,
                    assessmentId: assessmentId
                ) { result in
                    // Handle safety review completion
                    // Store result in assessment if needed
                    print("Safety review completed - Action: \(result.action.rawValue)")
                }
                .environmentObject(settings)
                .environmentObject(auditService)
            }
        }
        .sheet(isPresented: $showNewAssessmentSheet) {
            NewAssessmentSheet(isPresented: $showNewAssessmentSheet)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showRulesDiagnostics) {
            NavigationStack {
                RulesDiagnosticsView()
                    .navigationTitle("Rules Diagnostics")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showRulesDiagnostics = false
                            }
                        }
                    }
            }
            .environmentObject(rulesService)
        }
        .alert("Network Issue Detected", isPresented: $showNetworkAlert) {
            Button("OK", role: .cancel) {}
            Button("Retry") {
                Task {
                    await networkChecker.performActiveProbe()
                }
            }
        } message: {
            networkAlertMessage
        }
        .onAppear {
            // Show safety banner on first launch
            if selectedAssessment != nil && !UserDefaults.standard.bool(forKey: "safety_banner_shown") {
                showSafetyBanner = true
                UserDefaults.standard.set(true, forKey: "safety_banner_shown")
            }
        }
        } // Close VStack
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

                // NEW: Rules diagnostics button
                Button {
                    showRulesDiagnostics = true
                } label: {
                    Label("Rules Diagnostics", systemImage: "stethoscope")
                        .foregroundStyle(rulesService.isAvailable ? .blue : .orange)
                }
                .accessibilityLabel("View rules engine diagnostics")

                // NEW: Upload queue status
                if !uploadQueue.jobs.isEmpty {
                    HStack {
                        Label("\(uploadQueue.jobs.count) uploads queued", systemImage: "arrow.up.circle")
                            .foregroundStyle(.orange)
                        Spacer()
                        if uploadQueue.jobs.contains(where: { $0.attempt > 0 }) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                    .font(.caption)
                }
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
        let recommendation = rulesService.calculateLOC(for: assessment)  // NEW: Use rules engine
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
    @State private var path: [Int] = []  // Navigation path by domain number
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(assessment.domains) { domain in
                    NavigationLink(value: domain.number) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Domain \(domain.number): \(domain.title)")
                                    .font(.subheadline)
                                Text("Severity: \(domain.severity)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .accessibilityLabel("Domain \(domain.number), \(domain.title), Severity \(domain.severity)")
                    }
                }
            }
            .navigationTitle("Domains")
            .navigationDestination(for: Int.self) { domainNumber in
                if let domain = assessment.domains.first(where: { $0.number == domainNumber }) {
                    DomainDetailPlaceholderView(domain: domain)
                } else {
                    Text("Domain not found")
                }
            }
        }
    }
}

/// Domain detail view - questionnaire integration pending Xcode target inclusion
struct DomainDetailPlaceholderView: View {
    let domain: Domain
    
    var body: some View {
        Form {
            Section {
                Text("Domain \(domain.number)")
                    .font(.headline)
                Text(domain.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Text("Severity: \(domain.severity)")
                Stepper("Adjust Severity", value: .constant(domain.severity), in: 0...4)
                    .disabled(true)
            } header: {
                Text("CURRENT SEVERITY")
            } footer: {
                Text("Questionnaire files ready - pending Xcode target membership integration.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("✅ Questionnaire JSON files created")
                            .font(.callout)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("✅ Swift models and services ready")
                            .font(.callout)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("✅ Scoring engine implemented")
                            .font(.callout)
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Add Swift files to Xcode project target to activate")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("QUESTIONNAIRE INTEGRATION STATUS")
            }
            
            Section {
                Text("Files Location:")
                    .font(.callout)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Models/QuestionnaireModels.swift")
                    Text("• Services/QuestionsService.swift") 
                    Text("• Services/SeverityScoring.swift")
                    Text("• Views/QuestionnaireRenderer.swift")
                    Text("• questionnaires/ directory")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("READY FOR XCODE INTEGRATION")
            }
        }
        .navigationTitle("Domain \(domain.number)")
        .navigationBarTitleDisplayMode(.inline)
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
    @EnvironmentObject var rulesService: RulesServiceWrapper
    @EnvironmentObject var auditService: AuditService
    
    @State private var selectedTemplate: ComplianceMode = .internal_neutral
    @State private var showingExportSheet = false
    @State private var exportedURL: URL?
    
    var body: some View {
        Form {
            Section {
                Picker("Template", selection: $selectedTemplate) {
                    Text("Internal/Neutral").tag(ComplianceMode.internal_neutral)
                    Text("Licensed ASAM").tag(ComplianceMode.licensed_asam)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("COMPLIANCE MODE")
            } footer: {
                Text("Internal/Neutral mode for unlicensed use. Licensed mode requires ASAM license.")
                    .font(.caption)
            }
            
            Section {
                ExportButton(
                    assessment: assessment,
                    rulesService: rulesService
                ) {
                    performExport()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            } header: {
                Text("EXPORT")
            } footer: {
                if !rulesService.isAvailable {
                    Text("Export is disabled until rules engine loads successfully.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Section {
                if let checksum = rulesService.checksum {
                    LabeledContent("Rules Version", value: checksum.version)
                    LabeledContent("Rules Hash", value: checksum.sha256Short)
                }
                LabeledContent("Assessment ID", value: String(assessment.id.uuidString.prefix(8)).uppercased())
            } header: {
                Text("PROVENANCE")
            }
        }
        .navigationTitle("Export")
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportedURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func performExport() {
        // TODO: Implement actual PDF export
        // This is a placeholder for the export action
        print("🔄 Exporting assessment \(assessment.id) with template \(selectedTemplate)")
        
        auditService.logEvent(
            .pdfExported,
            actor: "assessor",
            assessmentId: assessment.id,
            action: "Export initiated with \(selectedTemplate.rawValue) template",
            notes: ""
        )
    }
}

// Share sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ContentView Extensions
extension ContentView {
    /// Network status indicator for toolbar
    @ViewBuilder
    private var networkStatusIndicator: some View {
        switch networkChecker.status {
        case .online:
            Label("Online", systemImage: "wifi")
                .foregroundStyle(.green)
                .font(.caption)
        case .offline:
            Label("Offline", systemImage: "wifi.slash")
                .foregroundStyle(.orange)
                .font(.caption)
        case .captivePortal:
            Label("Portal", systemImage: "wifi.exclamationmark")
                .foregroundStyle(.red)
                .font(.caption)
                .onTapGesture {
                    showNetworkAlert = true
                }
        case .tlsIntercepted:
            Label("TLS Issue", systemImage: "exclamationmark.shield")
                .foregroundStyle(.red)
                .font(.caption)
                .onTapGesture {
                    showNetworkAlert = true
                }
        case .clockSkewed:
            Label("Clock", systemImage: "clock.badge.exclamationmark")
                .foregroundStyle(.orange)
                .font(.caption)
                .onTapGesture {
                    showNetworkAlert = true
                }
        }
    }

    /// Network alert message based on status
    @ViewBuilder
    private var networkAlertMessage: some View {
        switch networkChecker.status {
        case .captivePortal:
            Text("You may be on a captive portal network (hotel/airport WiFi). Please sign in to the network before uploading data.")
        case .tlsIntercepted:
            Text("TLS certificate validation failed. Your network may be using a corporate proxy. Uploads are blocked for security.")
        case .clockSkewed:
            Text("Your device clock appears to be incorrect. Please check Settings > General > Date & Time and enable 'Set Automatically'.")
        case .offline:
            Text("No internet connection detected. Uploads will resume when connectivity is restored.")
        case .online:
            Text("Network is operating normally.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AssessmentStore())
        .environmentObject(AuditService())
        .environmentObject(LOCService())
}
