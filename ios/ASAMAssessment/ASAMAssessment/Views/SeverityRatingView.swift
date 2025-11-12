//
//  SeverityRatingView.swift
//  ASAMAssessment
//
//  Dimension 1 Severity Rating with clinical decision support
//  Implements ASAM Criteria 3rd Edition severity assessment
//

import SwiftUI

struct SeverityRatingView: View {
    let question: Question
    @Binding var answer: AnswerValue
    @EnvironmentObject private var assessmentStore: AssessmentStore
    
    @State private var selectedRating: Int?
    @State private var rationale: String = ""
    @State private var selectedSubstances: Set<String> = []
    @State private var substanceText: [String: String] = [:]  // For text inputs
    @State private var additionalComments: String = ""
    @State private var showRationaleError: Bool = false
    
    private var metadata: SeverityRatingMetadata? {
        question.severityRating
    }
    
    private var cards: [SeverityCard] {
        metadata?.cards ?? []
    }
    
    private var substanceOptions: [SubstanceOption] {
        metadata?.substanceOptions ?? []
    }
    
    private var safetyRules: [SafetyRule] {
        metadata?.safetyRules ?? []
    }
    
    // Check if rating triggers safety warnings
    private var activeSafetyRules: [SafetyRule] {
        guard let rating = selectedRating else { return [] }
        return safetyRules.filter { rule in
            evaluateSafetyCondition(rule.condition, rating: rating)
        }
    }
    
    // Check for substance-specific warnings
    private var hasHighRiskSubstances: Bool {
        let rating = selectedRating ?? 0
        return rating >= 2 && (selectedSubstances.contains("alcohol") || selectedSubstances.contains("benzodiazepines"))
    }
    
    private var hasStimulants: Bool {
        !substanceText["stimulants", default: ""].isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                // Reference information
                referenceSection
                
                // Safety banner (if triggered)
                if !activeSafetyRules.isEmpty {
                    ForEach(Array(activeSafetyRules.enumerated()), id: \.offset) { _, rule in
                        safetyBanner(for: rule)
                    }
                }
                
                // Substance-specific warnings
                if hasHighRiskSubstances {
                    withdrawalManagementReminder
                }
                
                if hasStimulants {
                    stimulantWarning
                }
                
                // Severity rating cards
                severityCardsSection
                
                // Rationale (shown after selection)
                if selectedRating != nil {
                    rationaleSection
                }
                
                // Substance selection
                substanceSection
                
                // Additional comments
                commentsSection
                
                // Interviewer instructions
                interviewerInstructions
            }
            .padding()
        }
        .onAppear {
            loadExistingAnswer()
        }
        .onChange(of: selectedRating) { oldValue, newValue in
            saveAnswer()
            // Require rationale for high severity
            if let rating = newValue, rating >= 3 {
                showRationaleError = rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            } else {
                showRationaleError = false
            }
        }
        .onChange(of: rationale) { _, _ in
            saveAnswer()
            if let rating = selectedRating, rating >= 3 {
                showRationaleError = rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
        .onChange(of: selectedSubstances) { _, _ in
            saveAnswer()
        }
        .onChange(of: substanceText) { _, _ in
            saveAnswer()
        }
        .onChange(of: additionalComments) { _, _ in
            saveAnswer()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Compact instruction text
            Text("Please circle the intensity and urgency of the patient's CURRENT needs for services based on the information collected in Dimension 1:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Main question title - responsive sizing
            Text(question.text)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.cardTitle)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            if question.required {
                HStack(spacing: 4) {
                    Image(systemName: "asterisk")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("Required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Reference Section
    
    private var referenceSection: some View {
        // Collapsible in compact width, always visible in regular
        DisclosureGroup("Guidance & References") {
            VStack(alignment: .leading, spacing: 8) {
                Text("For guidance assessing risk, please see Risk Rating Matrices in The ASAM Criteria, 3rd ed.:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    referenceItem(substance: "Alcohol", pages: "147-154")
                    referenceItem(substance: "Sedatives/Hypnotics", pages: "155-161")
                    referenceItem(substance: "Opioids", pages: "162 (Risk Assessment Matrix)")
                }
                .padding(.leading, 8)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Stimulant withdrawal from cathinones (bath salts) or high dose prescription amphetamines can be associated with intense psychotic events needing higher level of care")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .font(.caption)
        .tint(.blue)
    }
    
    private func referenceItem(substance: String, pages: String) -> some View {
        HStack {
            Text("•")
            Text("For \(substance), see pages \(pages)")
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    // MARK: - Safety Banners
    
    private func safetyBanner(for rule: SafetyRule) -> some View {
        let isCritical = rule.severity == "critical"
        
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCritical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(isCritical ? .red : .orange)
                .font(.title3)
            
            Text(rule.banner)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isCritical ? .red : .orange)
            
            Spacer()
        }
        .padding()
        .background(isCritical ? Color.safetyBannerCritical : Color.safetyBannerWarning)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCritical ? Color.safetyBannerCriticalBorder : Color.safetyBannerWarningBorder, lineWidth: 2)
        )
        .cornerRadius(8)
    }
    
    private var withdrawalManagementReminder: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundColor(.blue)
            Text("Review WM pathway")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var stimulantWarning: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.purple)
            Text("Assess for psychotic symptoms and consider higher level of care if present")
                .font(.caption)
                .foregroundColor(.purple)
        }
        .padding(12)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Severity Cards Section
    
    private var severityCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Severity Rating:")
                .font(.headline)
                .foregroundColor(.cardTitle)
            
            // Wrapped grid layout with minimum card width - no horizontal scroll
            // Cards wrap to multiple rows based on available width
            // minWidth: 220px ensures cards never get too skinny
            // 1fr allows them to grow but stay equal width per row
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 220, maximum: .infinity), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(cards) { card in
                    severityCard(card)
                }
            }
            
            // Keyboard shortcut hint
            Text("Keyboard shortcuts: Press 0-4 to select rating")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Severity rating selection")
    }
    
    private func severityCard(_ card: SeverityCard) -> some View {
        let isSelected = selectedRating == card.rating
        let bgColor = Color.severityCardBackground(colorHex: card.color)
        let borderColor = Color.severityCardBorder(colorHex: card.border)
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRating = card.rating
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Title with color swatch
                HStack(alignment: .center, spacing: 8) {
                    // Color swatch
                    RoundedRectangle(cornerRadius: 4)
                        .fill(borderColor)
                        .frame(width: 16, height: 16)
                    
                    Text(card.title)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.cardTitle)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.body)
                    }
                }
                
                // Bullet points (always visible)
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(card.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.cardText)
                            Text(bullet)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.cardText)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(nil)
                        }
                    }
                }
                
                // Push disposition to bottom
                Spacer(minLength: 8)
                
                // Disposition strip (always at bottom if present)
                if !card.disposition.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Disposition:")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.cardDisposition)
                        
                        Text(card.disposition)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.cardText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(bgColor.opacity(0.25))
                    .cornerRadius(6)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? bgColor.opacity(0.15) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? borderColor : Color(.separator),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .shadow(
                color: isSelected ? borderColor.opacity(0.3) : Color.clear,
                radius: isSelected ? 6 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minHeight: 200) // Minimum height for consistent grid
        .accessibilityLabel("\(card.title). \(card.bullets.joined(separator: ". "))")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
    
    // MARK: - Rationale Section
    
    private var rationaleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Rationale")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let rating = selectedRating, rating >= 3 {
                    Text("(Required for Severe/Very Severe)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            TextEditor(text: $rationale)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(showRationaleError ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            if rationale.isEmpty {
                Text("Brief note supporting the selected rating")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if showRationaleError {
                Text("Rationale is required for severity rating 3 or 4")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Substance Section
    
    private var substanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Substance(s) Driving Severity:")
                .font(.headline)
                .foregroundColor(.cardTitle)
            
            ForEach(substanceOptions) { option in
                if option.type == "checkbox" {
                    checkboxOption(option)
                } else {
                    textOption(option)
                }
            }
        }
    }
    
    private func checkboxOption(_ option: SubstanceOption) -> some View {
        Button(action: {
            if selectedSubstances.contains(option.id) {
                selectedSubstances.remove(option.id)
            } else {
                selectedSubstances.insert(option.id)
            }
        }) {
            HStack {
                Image(systemName: selectedSubstances.contains(option.id) ? "checkmark.square.fill" : "square")
                    .foregroundColor(selectedSubstances.contains(option.id) ? .blue : .gray)
                Text(option.label)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func textOption(_ option: SubstanceOption) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(option.label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("Enter substance name", text: Binding(
                get: { substanceText[option.id, default: ""] },
                set: { substanceText[option.id] = $0 }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Comments:")
                .font(.headline)
                .foregroundColor(.cardTitle)
            
            // Quick chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickChip("CIWA score documented")
                    quickChip("COWS score documented")
                    quickChip("Recent ED visit for withdrawal")
                    quickChip("No acute symptoms reported today")
                }
            }
            
            TextEditor(text: $additionalComments)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private func quickChip(_ text: String) -> some View {
        Button(action: {
            if additionalComments.isEmpty {
                additionalComments = text
            } else {
                additionalComments += "; " + text
            }
        }) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(16)
        }
    }
    
    // MARK: - Interviewer Instructions
    
    private var interviewerInstructions: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "book.fill")
                .foregroundColor(.indigo)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Interviewer Instructions:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
                
                Text("For help assessing D1, see ASAM Criteria, 3rd ed., the textbox titled, \"Dimension 1 Assessment Considerations Include\" on page 44.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    
    private func evaluateSafetyCondition(_ condition: String, rating: Int) -> Bool {
        // Simple condition parser for "rating >= 3", "rating == 4", etc.
        if condition.contains(">=") {
            let parts = condition.split(separator: " ")
            if parts.count >= 3, let threshold = Int(parts[2]) {
                return rating >= threshold
            }
        } else if condition.contains("==") {
            let parts = condition.split(separator: " ")
            if parts.count >= 3, let threshold = Int(parts[2]) {
                return rating == threshold
            }
        }
        return false
    }
    
    private func loadExistingAnswer() {
        // Load from answer if available - AnswerValue is .text(String) with JSON
        guard case .text(let jsonString) = answer else { return }
        guard let data = jsonString.data(using: .utf8) else { return }
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        if let rating = dict["rating"] as? Int {
            selectedRating = rating
        }
        if let ratText = dict["rationale"] as? String {
            rationale = ratText
        }
        if let subs = dict["substances"] as? [String: Any] {
            // Load checkboxes
            for key in ["alcohol", "opioids", "benzodiazepines"] {
                if let value = subs[key] as? Bool, value {
                    selectedSubstances.insert(key)
                }
            }
            // Load text fields
            if let stimText = subs["stimulants"] as? String {
                substanceText["stimulants"] = stimText
            }
            if let other1 = subs["other1"] as? String {
                substanceText["other1"] = other1
            }
            if let other2 = subs["other2"] as? String {
                substanceText["other2"] = other2
            }
        }
        if let comments = dict["comments"] as? String {
            additionalComments = comments
        }
    }
    
    private func saveAnswer() {
        var result: [String: Any] = [:]
        
        if let rating = selectedRating {
            result["rating"] = rating
        }
        
        if !rationale.isEmpty {
            result["rationale"] = rationale
        }
        
        var substances: [String: Any] = [:]
        for sub in ["alcohol", "opioids", "benzodiazepines"] {
            substances[sub] = selectedSubstances.contains(sub)
        }
        if let stimText = substanceText["stimulants"], !stimText.isEmpty {
            substances["stimulants"] = stimText
        }
        if let other1 = substanceText["other1"], !other1.isEmpty {
            substances["other1"] = other1
        }
        if let other2 = substanceText["other2"], !other2.isEmpty {
            substances["other2"] = other2
        }
        result["substances"] = substances
        
        if !additionalComments.isEmpty {
            result["comments"] = additionalComments
        }
        
        // Convert to JSON string for .text case
        if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            answer = .text(jsonString)
        }
    }
}
