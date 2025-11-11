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
        .onChange(of: selectedAssessment) { _, newSelection in
            // Keep currentAssessment in sync with selectedAssessment
            if let assessment = newSelection {
                assessmentStore.currentAssessment = assessment
                print("🔄 ContentView: Selected assessment changed to \(String(assessment.id.uuidString.prefix(8)))")
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
        ExpandableSidebarView(
            assessment: assessment, 
            selectedSection: $selectedSection,
            onSafetyReview: { showSafetyBanner = true },
            onRulesDiagnostics: { showRulesDiagnostics = true },
            onGenerateLOC: { generateLOCRecommendation(for: assessment) }
        )
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
        
        // Ensure currentAssessment is set immediately
        assessmentStore.currentAssessment = assessment

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
        case .domains: return "6 clinical domains"
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
    @EnvironmentObject private var assessmentStore: AssessmentStore
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
                                
                                // Show answer count for debugging
                                if !domain.answers.isEmpty {
                                    Text("Answers: \(domain.answers.count)")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
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
                    DomainDetailView(domain: domain, assessment: assessment)
                } else {
                    Text("Domain not found")
                }
            }
            .onAppear {
                // Set current assessment when domains list appears
                assessmentStore.currentAssessment = assessment
                print("🔄 DomainsListView appeared - set current assessment to \(String(assessment.id.uuidString.prefix(8)))")
            }
        }
    }
}

/// Domain detail view with actual questionnaire loading
struct DomainDetailView: View {
    let domain: Domain
    let assessment: Assessment  // Add assessment parameter
    @EnvironmentObject private var assessmentStore: AssessmentStore
    @StateObject private var questionsService = QuestionsService()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var questionnaire: Questionnaire?
    @State private var answers: [String: AnswerValue] = [:]
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading questionnaire...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Failed to load questionnaire")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        loadQuestionnaire()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let questionnaire = questionnaire {
                QuestionnaireRenderer(
                    questionnaire: questionnaire,
                    initialAnswers: answers  // Pass saved answers
                ) { newAnswers in
                    self.answers = newAnswers
                    saveDomainAnswers(newAnswers)
                    print("📝 Answers updated for Domain \(domain.number): \(newAnswers.count) answers")
                }
            } else {
                VStack(spacing: 16) {
                    Text("No questionnaire data available")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Button("Load Questionnaire") {
                        loadQuestionnaire()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle("Domain \(domain.number)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadQuestionnaire()
        }
        .onAppear {
            // Load saved answers when view appears and sync current assessment
            answers = domain.answers
            print("🔄 Domain \(domain.number) view appeared - loaded \(answers.count) saved answers")
            
            // Ensure this assessment is set as current for proper save handling
            if let currentAssessment = assessmentStore.assessments.first(where: { $0.domains.contains(where: { $0.id == domain.id }) }) {
                assessmentStore.currentAssessment = currentAssessment
                print("🔄 Set current assessment to \(String(currentAssessment.id.uuidString.prefix(8))) for domain \(domain.number)")
            }
        }
    }
    
    private func loadQuestionnaire() {
        isLoading = true
        errorMessage = nil
        questionnaire = nil
        
        Task {
            do {
                let domainIdentifier = "\(domain.number)" // Pass domain number as string
                let jsonData = try questionsService.loadQuestionnaireData(forDomain: domainIdentifier)
                
                // Parse JSON data into Questionnaire object
                let decoder = JSONDecoder()
                let parsedQuestionnaire = try decoder.decode(Questionnaire.self, from: jsonData)
                
                await MainActor.run {
                    self.questionnaire = parsedQuestionnaire
                    self.isLoading = false
                    // Load saved answers after questionnaire loads
                    self.answers = domain.answers
                    print("✅ Successfully loaded questionnaire for Domain \(domain.number): \(parsedQuestionnaire.questions.count) questions")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                print("🚫 Failed to load questionnaire for domain \(domain.number): \(error)")
            }
        }
    }
    
    private func saveDomainAnswers(_ newAnswers: [String: AnswerValue]) {
        // Use the assessment parameter directly instead of relying on currentAssessment
        var updatedAssessment = assessment
        
        print("💾 Saving answers for Domain \(domain.number) - Assessment: \(String(assessment.id.uuidString.prefix(8)))")
        
        // Update the domain with new answers
        if let domainIndex = updatedAssessment.domains.firstIndex(where: { $0.id == domain.id }) {
            updatedAssessment.domains[domainIndex].answers = newAnswers
            
            // Check if domain is complete based on required questions
            let questionnaireCopy = questionnaire
            let requiredQuestions = questionnaireCopy?.questions.filter { $0.required } ?? []
            let answeredRequiredQuestions = requiredQuestions.filter { question in
                if let answer = newAnswers[question.id], case .none = answer {
                    return false
                }
                return newAnswers[question.id] != nil
            }
            updatedAssessment.domains[domainIndex].isComplete = (answeredRequiredQuestions.count == requiredQuestions.count)
            
            // Save the updated assessment
            assessmentStore.updateAssessment(updatedAssessment)
            
            // Also ensure current assessment is updated for real-time sync
            assessmentStore.currentAssessment = updatedAssessment
            
            print("✅ Successfully saved \(newAnswers.count) answers for Domain \(domain.number), Complete: \(updatedAssessment.domains[domainIndex].isComplete)")
        } else {
            print("❌ Could not find domain \(domain.number) with ID \(domain.id) in assessment")
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

// MARK: - Expandable Sidebar View

struct ExpandableSidebarView: View {
    let assessment: Assessment
    @Binding var selectedSection: NavigationSection?
    let onSafetyReview: () -> Void
    let onRulesDiagnostics: () -> Void
    let onGenerateLOC: () -> Void
    
    @EnvironmentObject private var rulesService: RulesServiceWrapper
    @EnvironmentObject private var uploadQueue: UploadQueue
    
    @State private var expandedSections: Set<String> = ["Assessment"] // Default expanded
    @State private var selectedDomain: Domain?
    
    var body: some View {
        List(selection: $selectedSection) {
            // Main Assessment Sections
            ExpandableSection(
                title: "Assessment",
                icon: "doc.text",
                isExpanded: expandedSections.contains("Assessment")
            ) {
                toggleSection("Assessment")
            } content: {
                // Overview
                NavigationLink(value: NavigationSection.overview) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Overview")
                                .font(.subheadline)
                            Text("Assessment summary")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.blue)
                    }
                }
                .accessibilityLabel("Overview, Assessment summary")
                
                // Problems
                NavigationLink(value: NavigationSection.problems) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Problems")
                                .font(.subheadline)
                            Text("Clinical problems")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
                .accessibilityLabel("Problems, Clinical problems")
                
                // LOC Recommendation
                NavigationLink(value: NavigationSection.locRecommendation) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LOC Recommendation")
                                .font(.subheadline)
                            Text("Level of care")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundStyle(.green)
                    }
                }
                .accessibilityLabel("LOC Recommendation, Level of care")
                
                // Validation
                NavigationLink(value: NavigationSection.validation) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Validation")
                                .font(.subheadline)
                            Text("Completeness check")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "checkmark.seal")
                            .foregroundStyle(.indigo)
                    }
                }
                .accessibilityLabel("Validation, Completeness check")
                
                // Export
                NavigationLink(value: NavigationSection.export) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export")
                                .font(.subheadline)
                            Text("Generate PDF")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.teal)
                    }
                }
                .accessibilityLabel("Export, Generate PDF")
            }
            
            // Clinical Domains Section
            ExpandableSection(
                title: "Clinical Domains",
                icon: "square.grid.3x3",
                isExpanded: expandedSections.contains("Domains")
            ) {
                toggleSection("Domains")
            } content: {
                ForEach(assessment.domains) { domain in
                    DomainNavigationRow(
                        domain: domain,
                        isSelected: selectedSection == .domains && selectedDomain?.id == domain.id,
                        action: {
                            selectedDomain = domain
                            selectedSection = .domains
                        }
                    )
                }
            }
            
            // Actions Section
            ExpandableSection(
                title: "Actions",
                icon: "wrench.and.screwdriver",
                isExpanded: expandedSections.contains("Actions")
            ) {
                toggleSection("Actions")
            } content: {
                // Safety Review
                Button {
                    onSafetyReview()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Review Safety")
                                .font(.subheadline)
                            Text("Safety criteria check")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundStyle(.red)
                    }
                }
                .accessibilityLabel("Review safety criteria")
                
                // Calculate LOC
                Button {
                    onGenerateLOC()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Calculate LOC")
                                .font(.subheadline)
                            Text(assessment.isComplete ? "Generate recommendation" : "Complete domains first")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "function")
                            .foregroundStyle(assessment.isComplete ? .blue : .gray)
                    }
                }
                .disabled(!assessment.isComplete)
                .accessibilityLabel("Calculate level of care recommendation")
                .accessibilityHint(assessment.isComplete ? "Generate recommendation" : "Complete all domains first")
                
                // Rules Diagnostics
                Button {
                    onRulesDiagnostics()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rules Diagnostics")
                                .font(.subheadline)
                            Text("Engine status check")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "stethoscope")
                            .foregroundStyle(rulesService.isAvailable ? .blue : .orange)
                    }
                }
                .accessibilityLabel("View rules engine diagnostics")
                
                // Upload Queue Status
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
                    .padding(.leading, 32) // Align with other items
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
    
    private func toggleSection(_ section: String) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }
}

// MARK: - Expandable Section View

struct ExpandableSection<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    let toggleAction: () -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        Section {
            if isExpanded {
                content
            }
        } header: {
            Button(action: toggleAction) {
                HStack {
                    Label {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: icon)
                            .foregroundStyle(.blue)  // Use .blue instead of .accent
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Domain Navigation Row

struct DomainNavigationRow: View {
    let domain: Domain
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Domain \(domain.number)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(domain.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        // Completion Status
                        Label {
                            Text(domain.isComplete ? "Complete" : "In Progress")
                                .font(.caption2)
                        } icon: {
                            Image(systemName: domain.isComplete ? "checkmark.circle.fill" : "circle.dotted")
                        }
                        .foregroundStyle(domain.isComplete ? .green : .orange)
                        
                        Spacer()
                        
                        // Answer Count Indicator
                        if !domain.answers.isEmpty {
                            Text("\(domain.answers.count) answers")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        
                        // Severity Indicator
                        if domain.severity > 0 {
                            Text("Severity: \(domain.severity)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)  // Use .blue instead of .accent
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)  // Use .blue instead of .accent
        )
    }
}
