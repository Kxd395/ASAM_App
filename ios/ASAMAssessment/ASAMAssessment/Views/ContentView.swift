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
    @State private var selectedDomain: Domain?  // Track specific domain selection
    @State private var directDomainNavigation: Bool = false  // Enable direct domain navigation
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
            selectedDomain: $selectedDomain,  // Pass selectedDomain binding
            directDomainNavigation: $directDomainNavigation,  // Pass directDomainNavigation binding
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
                // Check if we have a direct domain navigation
                if directDomainNavigation, let domain = selectedDomain {
                    DomainDetailView(domain: domain, assessment: assessment)
                } else {
                    DomainsListView(assessment: assessment)
                }
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
        .navigationTitle(directDomainNavigation && selectedDomain != nil ? selectedDomain!.title : section.title)
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
    @State private var isEditMode = false  // Track if domain is in edit mode
    @State private var showCompletionAlert = false  // Show confirmation when completing
    @State private var isSaving = false  // NEW: Flag to prevent infinite save loop

    // Get current domain state from store
    private var currentDomainFromStore: Domain? {
        assessmentStore.currentAssessment?.domains.first(where: { $0.id == domain.id })
    }

    // Check if domain is complete
    private var isDomainComplete: Bool {
        currentDomainFromStore?.isComplete ?? false
    }

    // Check if all required questions are answered
    private var allRequiredQuestionsAnswered: Bool {
        guard let questionnaire = questionnaire else { return false }
        let requiredQuestions = questionnaire.questions.filter { $0.required }
        let answeredRequired = requiredQuestions.filter { question in
            if let answer = answers[question.id], case .none = answer {
                return false
            }
            return answers[question.id] != nil
        }
        return answeredRequired.count == requiredQuestions.count
    }

    // Check if domain can be marked complete (either all questions OR severity set)
    private var canMarkComplete: Bool {
        // Option 1: All required questions answered
        if allRequiredQuestionsAnswered {
            return true
        }

        // Option 2: Severity rating is set (override completion)
        if let currentDomain = currentDomainFromStore {
            return currentDomain.severity > 0
        }

        return false
    }

    // Helper text for completion requirements
    private var completionRequirementText: String {
        if allRequiredQuestionsAnswered {
            return "All required questions completed"
        } else if let currentDomain = currentDomainFromStore, currentDomain.severity > 0 {
            return "Severity rating set (override enabled)"
        } else {
            return "Complete all questions OR set severity rating"
        }
    }

    // MARK: - Main Content (extracted to avoid compiler timeout)

    @ViewBuilder
    private var mainScrollContent: some View {
        if isLoading {
            loadingView
        } else if let errorMessage = errorMessage {
            errorView(message: errorMessage)
        } else if let questionnaire = questionnaire {
            questionnaireContent(questionnaire: questionnaire)
        } else {
            noDataView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading questionnaire...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Failed to load questionnaire")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                loadQuestionnaire()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func questionnaireContent(questionnaire: Questionnaire) -> some View {
        ZStack {
            QuestionnaireRenderer(
                questionnaire: questionnaire,
                initialAnswers: answers
            ) { newAnswers in
                guard !isSaving else {
                    print("⏸️  Skipping save callback - already saving")
                    return
                }
                self.answers = newAnswers
                saveDomainAnswers(newAnswers)
                print("📝 Answers updated for Domain \(domain.number): \(newAnswers.count) answers")
            }
            .disabled(isDomainComplete && !isEditMode)
            .opacity(isDomainComplete && !isEditMode ? 0.6 : 1.0)

            if isDomainComplete && !isEditMode {
                completionOverlay
            }
        }
        .onChange(of: assessmentStore.currentAssessment) { _, newCurrentAssessment in
            guard !isSaving else {
                print("⏸️  Skipping answer refresh during save operation")
                return
            }

            if let newAssessment = newCurrentAssessment,
               let updatedDomain = newAssessment.domains.first(where: { $0.id == domain.id }) {
                answers = updatedDomain.answers
                print("🔄 Refreshed answers for Domain \(domain.number) due to current assessment change: \(answers.count) answers")
            }
        }
    }

    private var completionOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Domain Complete")
                .font(.title2)
                .fontWeight(.semibold)

            Text("This domain has been marked as complete.\nTap 'Edit' in the toolbar to make changes.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    private var noDataView: some View {
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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    mainScrollContent

                    if questionnaire != nil {
                        severityPickerSection
                    }
                }
            }

            if questionnaire != nil {
                domainActionBar
            }
        }
        .navigationTitle("Domain \(domain.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isDomainComplete {
                    Button(isEditMode ? "Done Editing" : "Edit") {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }
                    .foregroundColor(isEditMode ? .green : .blue)
                }
            }
        }
        .alert("Mark Domain as Complete?", isPresented: $showCompletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Mark Complete") {
                markDomainComplete()
            }
        } message: {
            Text("This will finalize Domain \(domain.number). You can still edit it later if needed.")
        }
        .task {
            loadQuestionnaire()
        }
        .onAppear {
            // Always load answers from the current assessment in the store
            if let currentAssessment = assessmentStore.currentAssessment,
               let currentDomain = currentAssessment.domains.first(where: { $0.id == domain.id }) {
                answers = currentDomain.answers
                // Set edit mode based on completion status
                isEditMode = false
                print("🔄 Domain \(domain.number) view appeared - loaded \(answers.count) saved answers from current assessment")
            } else {
                // Fallback: find the assessment that contains this domain and set it as current
                if let assessmentWithDomain = assessmentStore.assessments.first(where: { $0.domains.contains(where: { $0.id == domain.id }) }) {
                    assessmentStore.currentAssessment = assessmentWithDomain
                    if let domainInAssessment = assessmentWithDomain.domains.first(where: { $0.id == domain.id }) {
                        answers = domainInAssessment.answers
                        print("🔄 Domain \(domain.number) view appeared - set current assessment and loaded \(answers.count) answers")
                    }
                } else {
                    // Final fallback to the domain parameter
                    answers = domain.answers
                    print("🔄 Domain \(domain.number) view appeared - loaded \(answers.count) answers from domain parameter (final fallback)")
                }
            }
        }
    }

    // MARK: - Domain Action Bar

    @ViewBuilder
    private var severityPickerSection: some View {
        // Domain 2 uses rich card interface
        if domain.number == 2 {
            d2RichSeverityPicker
        } else {
            // Other domains use simple circular buttons
            VStack(spacing: 0) {
                Divider()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Severity Rating")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Required to override completion")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    // Severity Picker (0-4)
                    HStack(spacing: 8) {
                        ForEach(0...4, id: \.self) { severity in
                            Button(action: {
                                updateSeverity(severity)
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(currentDomainFromStore?.severity == severity ? severityColor(severity) : Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)

                                    Text("\(severity)")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .foregroundColor(currentDomainFromStore?.severity == severity ? .white : .primary)
                                }
                            }
                            .disabled(isDomainComplete && !isEditMode)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
    }

    // Rich severity picker for Domain 2 - Full card-based interface
    @ViewBuilder
    private var d2RichSeverityPicker: some View {
        VStack(spacing: 16) {
            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Select Severity Rating:")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Keyboard shortcuts: press 0 to 4 to select rating")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            ScrollView {
                d2RichCardGrid
            }
            .frame(maxHeight: 400)

            if currentDomainFromStore?.severity == 4 {
                d2EmergencyBanner
            }

            // Invisible buttons for keyboard shortcuts (Domain 2 only)
            if domain.number == 2 {
                HStack(spacing: 0) {
                    Button("") { updateSeverity(0) }.keyboardShortcut("0", modifiers: []).opacity(0).frame(width: 0, height: 0)
                    Button("") { updateSeverity(1) }.keyboardShortcut("1", modifiers: []).opacity(0).frame(width: 0, height: 0)
                    Button("") { updateSeverity(2) }.keyboardShortcut("2", modifiers: []).opacity(0).frame(width: 0, height: 0)
                    Button("") { updateSeverity(3) }.keyboardShortcut("3", modifiers: []).opacity(0).frame(width: 0, height: 0)
                    Button("") { updateSeverity(4) }.keyboardShortcut("4", modifiers: []).opacity(0).frame(width: 0, height: 0)
                }
                .frame(width: 0, height: 0)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .opacity(isDomainComplete && !isEditMode ? 0.6 : 1.0)
    }

    @ViewBuilder
    private var d2RichCardGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            d2Card(value: 0, title: "0 None", color: .gray, bullet1: "Fully functional/no significant pain", bullet2: "")
            d2Card(value: 1, title: "1 Mild", color: .green, bullet1: "Mild symptoms interfering minimally", bullet2: "Able to cope with discomfort")
            d2Card(value: 2, title: "2 Moderate", color: .yellow, bullet1: "Non-life-threatening but neglected", bullet2: "Health issues impacting ADLs")
            d2Card(value: 3, title: "3 Severe", color: .orange, bullet1: "Poorly controlled medical problems", bullet2: "Poor ability to cope")
            d2Card(value: 4, title: "4 Very Severe", color: .red, bullet1: "Unstable condition", bullet2: "DTs, chest pain, seizures")
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var d2EmergencyBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emergency risk. Consider ED now.")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 2))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func d2Card(value: Int, title: String, color: Color, bullet1: String, bullet2: String) -> some View {
        let isSelected = currentDomainFromStore?.severity == value

        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                updateSeverity(value)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle().fill(color).frame(width: 12, height: 12)
                    Text(title).font(.subheadline).fontWeight(.semibold)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    if !bullet1.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").font(.caption)
                            Text(bullet1).font(.caption)
                        }
                    }
                    if !bullet2.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").font(.caption)
                            Text(bullet2).font(.caption)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? color : Color.clear, lineWidth: 2))
            .shadow(color: isSelected ? color.opacity(0.3) : Color.clear, radius: isSelected ? 8 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDomainComplete && !isEditMode)
    }

    @ViewBuilder
    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 0: return .gray
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }

    private func updateSeverity(_ severity: Int) {
        guard let currentAssessment = assessmentStore.currentAssessment,
              let domainIndex = currentAssessment.domains.firstIndex(where: { $0.id == domain.id }) else {
            return
        }

        var updatedAssessment = currentAssessment
        updatedAssessment.domains[domainIndex].severity = severity

        assessmentStore.updateAssessment(updatedAssessment)

        print("✅ Domain \(domain.number) severity updated to \(severity)")

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    @ViewBuilder
    private var domainActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                // Progress indicator
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ProgressView(value: currentDomainFromStore?.calculateProgress() ?? 0)
                            .progressViewStyle(.linear)
                            .frame(width: 120)

                        Text("\(Int((currentDomainFromStore?.calculateProgress() ?? 0) * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Action buttons
                if isDomainComplete && !isEditMode {
                    // Already complete - show status
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Complete")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    // In progress or editing - show complete button
                    Button(action: {
                        if canMarkComplete {
                            showCompletionAlert = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: canMarkComplete ? "checkmark.circle.fill" : "checkmark.circle")
                            Text("Mark Complete")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(canMarkComplete ? Color.green : Color.gray.opacity(0.3))
                        .foregroundColor(canMarkComplete ? .white : .gray)
                        .cornerRadius(10)
                    }
                    .disabled(!canMarkComplete)

                    // Show helper text
                    if !canMarkComplete {
                        Text(completionRequirementText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Helper Methods

    private func markDomainComplete() {
        guard let currentAssessment = assessmentStore.currentAssessment,
              let domainIndex = currentAssessment.domains.firstIndex(where: { $0.id == domain.id }) else {
            return
        }

        var updatedAssessment = currentAssessment
        updatedAssessment.domains[domainIndex].isComplete = true

        // Save to store
        assessmentStore.updateAssessment(updatedAssessment)

        // Exit edit mode
        isEditMode = false

        print("✅ Domain \(domain.number) marked as complete")

        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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

                    // CRITICAL FIX: Load saved answers from current assessment in store, not from stale domain parameter
                    if let currentAssessment = assessmentStore.currentAssessment,
                       let currentDomain = currentAssessment.domains.first(where: { $0.id == domain.id }) {
                        self.answers = currentDomain.answers
                        print("✅ Successfully loaded questionnaire for Domain \(domain.number): \(parsedQuestionnaire.questions.count) questions, \(self.answers.count) saved answers")
                    } else {
                        // Fallback to domain parameter only if current assessment not available
                        self.answers = domain.answers
                        print("✅ Successfully loaded questionnaire for Domain \(domain.number): \(parsedQuestionnaire.questions.count) questions, \(self.answers.count) answers (fallback)")
                    }
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
        // Set flag to prevent infinite loop
        isSaving = true
        defer {
            // Reset flag after a short delay to ensure all onChange handlers complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSaving = false
            }
        }

        // Always get the current assessment from the store to ensure we have the latest version
        guard let currentAssessment = assessmentStore.currentAssessment else {
            print("❌ No current assessment available for saving answers")
            return
        }

        var updatedAssessment = currentAssessment

        print("💾 Saving answers for Domain \(domain.number) - Current Assessment: \(String(currentAssessment.id.uuidString.prefix(8)))")

        // Update the domain with new answers
        if let domainIndex = updatedAssessment.domains.firstIndex(where: { $0.id == domain.id }) {
            // Store previous answers for comparison - CRITICAL FOR TRACKING FIELD REMOVAL
            let previousAnswers = updatedAssessment.domains[domainIndex].answers
            let oldCount = previousAnswers.count

            // Update with new answers (this handles BOTH additions and removals)
            updatedAssessment.domains[domainIndex].answers = newAnswers

            let newCount = newAnswers.count
            let delta = newCount - oldCount

            // ENHANCED LOGGING for field addition/removal tracking
            print("💾 New answers: \(newCount) questions answered")
            print("📊 Answer count changed: \(oldCount) → \(newCount) (Δ\(delta > 0 ? "+" : "")\(delta))")

            if delta < 0 {
                print("⬇️  Field removal detected: \(abs(delta)) answer(s) removed")
            } else if delta > 0 {
                print("⬆️  Field addition detected: \(delta) answer(s) added")
            }

            // Calculate severity score based on new answers
            do {
                let severityScoring = try SeverityScoring()
                let domainIdentifier = String(UnicodeScalar(64 + domain.number)!) // 1→A, 2→B, etc.

                // Convert AnswerValue to scoring-compatible format
                var scoringAnswers: [String: Any] = [:]
                for (questionId, answerValue) in newAnswers {
                    switch answerValue {
                    case .text(let text):
                        scoringAnswers[questionId] = text
                    case .number(let num):
                        scoringAnswers[questionId] = num
                    case .bool(let bool):
                        scoringAnswers[questionId] = bool
                    case .single(let value):
                        if case .number(let num) = value {
                            scoringAnswers[questionId] = num
                        } else if case .string(let str) = value {
                            scoringAnswers[questionId] = str
                        }
                    case .multi(let values):
                        scoringAnswers[questionId] = Array(values)
                    case .substanceGrid(_):
                        // Handle substance grid if needed
                        break
                    case .impactGrid(_):
                        // Handle impact grid if needed
                        break
                    case .none:
                        // Don't include empty answers
                        break
                    }
                }

                let domainSeverity = severityScoring.computeSeverity(forDomain: domainIdentifier, answers: scoringAnswers)
                updatedAssessment.domains[domainIndex].severity = domainSeverity.severity

                print("🧮 Calculated severity for Domain \(domain.number): \(domainSeverity.severity) (score: \(String(format: "%.2f", domainSeverity.score)))")

            } catch {
                print("⚠️ Failed to calculate severity for Domain \(domain.number): \(error)")
            }

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

            // Save the updated assessment - this will handle currentAssessment sync internally
            assessmentStore.updateAssessment(updatedAssessment)

            // ENHANCED LOGGING: Calculate and log progress after save
            let domainProgress = updatedAssessment.domains[domainIndex].calculateProgress()
            let overallProgress = updatedAssessment.calculateOverallProgress()

            print("✅ Successfully saved \(newAnswers.count) answers for Domain \(domain.number)")
            print("📊 Domain \(domain.number) progress: \(String(format: "%.0f%%", domainProgress * 100))")
            print("📊 Overall assessment progress: \(String(format: "%.0f%%", overallProgress * 100))")
            print("📋 Domain \(domain.number) complete: \(updatedAssessment.domains[domainIndex].isComplete), Severity: \(updatedAssessment.domains[domainIndex].severity)")
            print("🔍 Field count change: \(oldCount) → \(newCount)")
        } else {
            print("❌ Could not find domain \(domain.number) with ID \(domain.id) in current assessment")
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
    @Binding var selectedDomain: Domain?  // Change from @State to @Binding
    @Binding var directDomainNavigation: Bool  // Add binding for direct navigation
    let onSafetyReview: () -> Void
    let onRulesDiagnostics: () -> Void
    let onGenerateLOC: () -> Void

    @EnvironmentObject private var rulesService: RulesServiceWrapper
    @EnvironmentObject private var uploadQueue: UploadQueue

    @State private var expandedSections: Set<String> = ["Assessment"] // Default expanded

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
                // All Domains overview option
                NavigationLink(value: NavigationSection.domains) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Domains")
                                .font(.subheadline)
                            Text("Overview of all 6 domains")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.grid.3x3")
                            .foregroundStyle(.purple)
                    }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    // Reset direct navigation when viewing all domains
                    directDomainNavigation = false
                    selectedDomain = nil
                })
                .accessibilityLabel("All Domains, Overview of all 6 domains")

                ForEach(assessment.domains) { domain in
                    DomainNavigationRow(
                        domain: domain,
                        isSelected: selectedSection == .domains && selectedDomain?.id == domain.id
                    )
                    .onTapGesture {
                        print("🔵 Domain clicked: \(domain.number) - \(domain.title)")
                        print("🔵 Before state update - selectedSection: \(String(describing: selectedSection)), selectedDomain: \(String(describing: selectedDomain?.number))")

                        // Update domain first
                        selectedDomain = domain

                        // Force section change to trigger List update
                        // If already on domains, briefly set to nil then back
                        if selectedSection == .domains {
                            selectedSection = nil
                            // Use DispatchQueue to ensure state update propagates
                            DispatchQueue.main.async {
                                selectedSection = .domains
                                directDomainNavigation = true
                            }
                        } else {
                            selectedSection = .domains
                            directDomainNavigation = true
                        }

                        print("🔵 After state update - selectedSection: \(String(describing: selectedSection)), selectedDomain: \(String(describing: selectedDomain?.number))")
                    }
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
    @EnvironmentObject private var assessmentStore: AssessmentStore

    // Get the live domain state from the store
    private var currentDomain: Domain {
        assessmentStore.currentAssessment?.domains.first(where: { $0.id == domain.id }) ?? domain
    }

    var body: some View {
        let _ = print("🟢 DomainNavigationRow rendering - Domain \(domain.number): isSelected = \(isSelected), isComplete = \(currentDomain.isComplete)")

        HStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Domain \(domain.number)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(currentDomain.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack {
                        // Completion Status - Use currentDomain to get live state
                        Label {
                            Text(currentDomain.isComplete ? "Complete" : "In Progress")
                                .font(.caption2)
                        } icon: {
                            Image(systemName: currentDomain.isComplete ? "checkmark.circle.fill" : "circle.dotted")
                        }
                        .foregroundStyle(currentDomain.isComplete ? .green : .orange)

                        Spacer()

                        // Answer Count Indicator - Use currentDomain
                        if !currentDomain.answers.isEmpty {
                            Text("\(currentDomain.answers.count)")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }

                        // Severity Indicator with Color - Use currentDomain
                        if currentDomain.severity > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(severityColorForSidebar(currentDomain.severity))
                                    .frame(width: 8, height: 8)

                                Text("\(currentDomain.severity)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(severityColorForSidebar(currentDomain.severity))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(severityColorForSidebar(currentDomain.severity).opacity(0.15))
                            .cornerRadius(4)
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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)  // Use .blue instead of .accent
        )
    }

    private func severityColorForSidebar(_ severity: Int) -> Color {
        switch severity {
        case 0: return .gray
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
}

