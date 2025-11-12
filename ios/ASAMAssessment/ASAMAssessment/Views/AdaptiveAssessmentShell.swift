//
//  AdaptiveAssessmentShell.swift
//  ASAMAssessment
//
//  Adaptive layout system with sidebar/top/focus modes
//  Created on 2025-11-12
//

import SwiftUI

// MARK: - Layout Mode

enum LayoutMode: String, CaseIterable, Codable {
    case auto = "auto"
    case sidebar = "sidebar"
    case top = "top"
    case focus = "focus"
    
    var label: String {
        switch self {
        case .auto: return "Auto"
        case .sidebar: return "Sidebar"
        case .top: return "Top"
        case .focus: return "Focus"
        }
    }
    
    var icon: String {
        switch self {
        case .auto: return "rectangle.3.group"
        case .sidebar: return "sidebar.left"
        case .top: return "menubar.rectangle"
        case .focus: return "rectangle.inset.filled"
        }
    }
}

// MARK: - Domain Status

struct DomainStatus: Identifiable {
    let id: String
    let label: String
    let badge: String?
    let tone: StatusTone
    let progress: Double // 0.0 to 1.0
    let currentRating: String?
    let issueCount: Int
}

enum StatusTone {
    case amber, blue, green, red, gray
    
    var color: Color {
        switch self {
        case .amber: return .orange
        case .blue: return .blue
        case .green: return .green
        case .red: return .red
        case .gray: return .gray
        }
    }
}

// MARK: - Issue Item

struct IssueItem: Identifiable {
    let id: String
    let domain: String
    let title: String
    let severity: IssueSeverity
}

enum IssueSeverity {
    case error, warning, info
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Adaptive Assessment Shell

struct AdaptiveAssessmentShell<Content: View>: View {
    @AppStorage("layoutMode") private var layoutMode: LayoutMode = .auto
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showJumpPalette = false
    
    let domains: [DomainStatus]
    let issues: [IssueItem]
    let currentDomain: String?
    let onDomainSelect: (String) -> Void
    let onIssueSelect: (String) -> Void
    let content: Content
    
    init(
        domains: [DomainStatus],
        issues: [IssueItem] = [],
        currentDomain: String? = nil,
        onDomainSelect: @escaping (String) -> Void = { _ in },
        onIssueSelect: @escaping (String) -> Void = { _ in },
        @ViewBuilder content: () -> Content
    ) {
        self.domains = domains
        self.issues = issues
        self.currentDomain = currentDomain
        self.onDomainSelect = onDomainSelect
        self.onIssueSelect = onIssueSelect
        self.content = content()
    }
    
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    private var effectiveMode: LayoutMode {
        if layoutMode == .auto {
            return isWideLayout ? .sidebar : .top
        }
        return layoutMode
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top utility bar - always visible
                topUtilityBar
                
                // Main content based on effective mode
                switch effectiveMode {
                case .sidebar, .auto:
                    sidebarLayout
                case .top:
                    topLayout
                case .focus:
                    focusLayout
                }
            }
        }
        .sheet(isPresented: $showJumpPalette) {
            JumpPaletteView(
                domains: domains,
                issues: issues,
                onSelect: { id in
                    onDomainSelect(id)
                    showJumpPalette = false
                }
            )
        }
    }
    
    // MARK: - Top Utility Bar
    
    private var topUtilityBar: some View {
        HStack(spacing: 12) {
            Text("Assessment")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Mode switcher
            ModeSwitch(mode: $layoutMode)
            
            // Jump button
            Button(action: { showJumpPalette = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                    Text("⌘J")
                        .font(.system(size: 11, design: .monospaced))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Sidebar Layout
    
    private var sidebarLayout: some View {
        HStack(spacing: 0) {
            // Left sidebar - 320pt wide
            SideNav(
                domains: domains,
                issues: issues,
                currentDomain: currentDomain,
                onDomainSelect: onDomainSelect,
                onIssueSelect: onIssueSelect
            )
            .frame(width: 320)
            
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(.separator))
            
            // Main content
            ScrollView {
                content
                    .padding()
            }
        }
    }
    
    // MARK: - Top Layout
    
    private var topLayout: some View {
        VStack(spacing: 0) {
            // Top chip navigation
            TopChipsNav(
                domains: domains,
                currentDomain: currentDomain,
                onDomainSelect: onDomainSelect,
                onFocusMode: { layoutMode = .focus }
            )
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator))
            
            // Main content
            ScrollView {
                content
                    .padding()
            }
        }
    }
    
    // MARK: - Focus Layout
    
    private var focusLayout: some View {
        ZStack {
            ScrollView {
                content
                    .padding()
                    .padding(.bottom, 80)
            }
            
            // Floating back button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        layoutMode = isWideLayout ? .sidebar : .top
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                            Text("Back to nav")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
                    .padding(16)
                }
            }
        }
    }
}

// MARK: - Mode Switch

struct ModeSwitch: View {
    @Binding var mode: LayoutMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(LayoutMode.allCases, id: \.self) { layoutMode in
                Button(action: { mode = layoutMode }) {
                    HStack(spacing: 4) {
                        Image(systemName: layoutMode.icon)
                            .font(.system(size: 10))
                        Text(layoutMode.label)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(mode == layoutMode ? .primary : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(mode == layoutMode ? Color(.systemGray5) : Color.clear)
                }
                .buttonStyle(.plain)
                
                if layoutMode != LayoutMode.allCases.last {
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(Color(.separator))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .cornerRadius(6)
    }
}

// MARK: - Side Nav

struct SideNav: View {
    let domains: [DomainStatus]
    let issues: [IssueItem]
    let currentDomain: String?
    let onDomainSelect: (String) -> Void
    let onIssueSelect: (String) -> Void
    
    @State private var expandedSections: Set<String> = ["issues", "domains"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Overall progress
                overallProgress
                
                // Issues section
                if !issues.isEmpty {
                    issuesSection
                }
                
                // Domains section
                domainsSection
                
                // Quick actions
                quickActionsSection
                
                // Keyboard shortcuts
                keyboardShortcutsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var overallProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Domains")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            let totalProgress = domains.reduce(0.0) { $0 + $1.progress } / Double(domains.count)
            
            HStack {
                ProgressView(value: totalProgress)
                    .tint(.blue)
                
                Text("\(Int(totalProgress * 100))%")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var issuesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { toggleSection("issues") }) {
                HStack {
                    Image(systemName: expandedSections.contains("issues") ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Issues (\(issues.count))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundColor(.primary)
            }
            
            if expandedSections.contains("issues") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(issues) { issue in
                        Button(action: { onIssueSelect(issue.id) }) {
                            HStack(spacing: 8) {
                                Image(systemName: issue.severity.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(issue.severity.color)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(issue.domain)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Text(issue.title)
                                        .font(.system(size: 12))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var domainsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { toggleSection("domains") }) {
                HStack {
                    Image(systemName: expandedSections.contains("domains") ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Domains")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundColor(.primary)
            }
            
            if expandedSections.contains("domains") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(domains) { domain in
                        DomainRow(
                            domain: domain,
                            isSelected: currentDomain == domain.id,
                            onSelect: { onDomainSelect(domain.id) }
                        )
                    }
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quick Actions")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 4) {
                QuickActionButton(icon: "star.fill", label: "Jump to severity")
                QuickActionButton(icon: "syringe", label: "Jump to vaccines")
                QuickActionButton(icon: "plus.circle", label: "Add from D2")
            }
        }
    }
    
    private var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Keyboard")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 4) {
                ShortcutRow(key: "0-4", action: "Set rating")
                ShortcutRow(key: "⌘J", action: "Jump palette")
                ShortcutRow(key: "Tab", action: "Next field")
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
    
    private func toggleSection(_ section: String) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }
}

// MARK: - Domain Row

struct DomainRow: View {
    let domain: DomainStatus
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 3)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .trim(from: 0, to: domain.progress)
                        .stroke(domain.tone.color, lineWidth: 3)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                    
                    if let rating = domain.currentRating {
                        Text(rating)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(domain.label)
                        .font(.system(size: 13, weight: .medium))
                    
                    if domain.issueCount > 0 {
                        Text("\(domain.issueCount) issue\(domain.issueCount == 1 ? "" : "s")")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    } else {
                        Text("\(Int(domain.progress * 100))% complete")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let badge = domain.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(domain.tone.color)
                        .cornerRadius(12)
                }
            }
            .padding(10)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shortcut Row

struct ShortcutRow: View {
    let key: String
    let action: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray6))
                .cornerRadius(4)
            
            Text(action)
            
            Spacer()
        }
    }
}

// MARK: - Top Chips Nav

struct TopChipsNav: View {
    let domains: [DomainStatus]
    let currentDomain: String?
    let onDomainSelect: (String) -> Void
    let onFocusMode: () -> Void
    
    @State private var showMore = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(domains) { domain in
                    DomainChip(
                        domain: domain,
                        isSelected: currentDomain == domain.id,
                        onSelect: { onDomainSelect(domain.id) }
                    )
                }
                
                Spacer()
                
                // More button
                Button(action: { showMore = true }) {
                    Text("More")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                }
                
                // Focus button
                Button(action: onFocusMode) {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.inset.filled")
                            .font(.system(size: 10))
                        Text("Focus")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Domain Chip

struct DomainChip: View {
    let domain: DomainStatus
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Text(domain.label)
                    .font(.system(size: 13, weight: .medium))
                
                if let badge = domain.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray4))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? domain.tone.color : Color(.systemGray6))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Jump Palette View

struct JumpPaletteView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    let domains: [DomainStatus]
    let issues: [IssueItem]
    let onSelect: (String) -> Void
    
    var filteredDomains: [DomainStatus] {
        if searchText.isEmpty {
            return domains
        }
        return domains.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredIssues: [IssueItem] {
        if searchText.isEmpty {
            return issues
        }
        return issues.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.domain.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Jump to domain or issue...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                List {
                    if !filteredIssues.isEmpty {
                        Section("Issues") {
                            ForEach(filteredIssues) { issue in
                                Button(action: {
                                    onSelect(issue.id)
                                }) {
                                    HStack {
                                        Image(systemName: issue.severity.icon)
                                            .foregroundColor(issue.severity.color)
                                        VStack(alignment: .leading) {
                                            Text(issue.title)
                                            Text(issue.domain)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Section("Domains") {
                        ForEach(filteredDomains) { domain in
                            Button(action: {
                                onSelect(domain.id)
                            }) {
                                HStack {
                                    Circle()
                                        .fill(domain.tone.color)
                                        .frame(width: 8, height: 8)
                                    Text(domain.label)
                                    Spacer()
                                    if let rating = domain.currentRating {
                                        Text(rating)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Jump To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct AdaptiveAssessmentShell_Previews: PreviewProvider {
    static var previews: some View {
        let sampleDomains = [
            DomainStatus(id: "d1", label: "D1: Severity", badge: "2", tone: .amber, progress: 0.8, currentRating: "2", issueCount: 0),
            DomainStatus(id: "d2", label: "D2: Biomedical", badge: "3", tone: .blue, progress: 0.6, currentRating: nil, issueCount: 3),
            DomainStatus(id: "d3", label: "D3: Emotional", badge: nil, tone: .green, progress: 0.9, currentRating: "1", issueCount: 0),
            DomainStatus(id: "d4", label: "D4: Readiness", badge: nil, tone: .gray, progress: 0.3, currentRating: nil, issueCount: 1),
        ]
        
        let sampleIssues = [
            IssueItem(id: "i1", domain: "D2", title: "Required: Health conditions", severity: .error),
            IssueItem(id: "i2", domain: "D2", title: "Missing: Vaccination history", severity: .warning),
            IssueItem(id: "i3", domain: "D4", title: "Review: Treatment goals", severity: .info),
        ]
        
        AdaptiveAssessmentShell(
            domains: sampleDomains,
            issues: sampleIssues,
            currentDomain: "d1"
        ) {
            VStack {
                Text("Assessment Content Here")
                    .font(.largeTitle)
                    .padding()
                Spacer()
            }
        }
    }
}
