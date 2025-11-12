//
//  CategorizedHealthIssuesView.swift
//  ASAMAssessment
//
//  Compact, searchable, categorized health issues checklist for Dimension 2
//  Features: search, sort (category/A-Z), collapsible categories, selected drawer, multi-select dropdowns
//

import SwiftUI

struct CategorizedHealthIssuesView: View {
    let question: Question
    @Binding var answer: AnswerValue
    
    @State private var searchQuery: String = ""
    @State private var sortMode: SortMode = .category
    @State private var expandedCategories: Set<String> = []
    @State private var selectedItems: [String: HealthIssueSelection] = [:]
    
    enum SortMode: String, CaseIterable {
        case category = "Category"
        case alphabetical = "A to Z"
    }
    
    private var categories: [HealthIssueCategory] {
        question.categorizedHealthIssues?.categories ?? []
    }
    
    private var macros: [String] {
        question.categorizedHealthIssues?.macros ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Search and Sort
                searchAndSortSection
                
                // Selected Items Drawer
                if !selectedItems.isEmpty {
                    selectedDrawer
                }
                
                // Categories
                categoriesSection
                
                // Macros
                if !macros.isEmpty {
                    macrosSection
                }
            }
            .padding()
        }
        .onAppear {
            loadExistingAnswer()
            // Auto-expand first category and any with selected items
            if expandedCategories.isEmpty {
                expandedCategories.insert(categories.first?.id ?? "")
            }
        }
        .onChange(of: selectedItems) { _ in
            saveAnswer()
        }
    }
    
    // MARK: - Search and Sort Section
    
    private var searchAndSortSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Search box
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Find an item", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Sort toggle
            HStack(spacing: 16) {
                Text("Sort:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(SortMode.allCases, id: \.self) { mode in
                    Button(action: { sortMode = mode }) {
                        HStack(spacing: 6) {
                            Image(systemName: sortMode == mode ? "circle.fill" : "circle")
                                .font(.caption)
                            Text(mode.rawValue)
                                .font(.subheadline)
                        }
                        .foregroundColor(sortMode == mode ? .blue : .primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Selected Drawer
    
    private var selectedDrawer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: clearAll) {
                    Text("Clear all")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Selected chips
            FlowLayout(spacing: 8) {
                ForEach(Array(selectedItems.keys.sorted()), id: \.self) { itemId in
                    if let item = findItem(id: itemId) {
                        selectedChip(item: item)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func selectedChip(item: HealthIssueItem) -> some View {
        Button(action: { toggleItem(item.id) }) {
            HStack(spacing: 4) {
                Text(item.label)
                    .font(.caption)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.blue)
            )
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        ForEach(filteredAndGroupedCategories, id: \.id) { category in
            categoryView(category)
        }
    }
    
    private var filteredAndGroupedCategories: [HealthIssueCategory] {
        let filtered = filterCategories()
        
        if sortMode == .alphabetical {
            // Flatten all items and sort alphabetically
            let allItems = filtered.flatMap { $0.items }.sorted { $0.label < $1.label }
            return [HealthIssueCategory(id: "all", title: "All Items", items: allItems)]
        } else {
            return filtered
        }
    }
    
    private func filterCategories() -> [HealthIssueCategory] {
        guard !searchQuery.isEmpty else { return categories }
        
        let query = searchQuery.lowercased()
        return categories.compactMap { category in
            let matchingItems = category.items.filter {
                $0.label.lowercased().contains(query) ||
                category.title.lowercased().contains(query)
            }
            guard !matchingItems.isEmpty else { return nil }
            return HealthIssueCategory(id: category.id, title: category.title, items: matchingItems)
        }
    }
    
    private func categoryView(_ category: HealthIssueCategory) -> some View {
        let isExpanded = expandedCategories.contains(category.id) || sortMode == .alphabetical
        let selectedCount = category.items.filter { selectedItems.keys.contains($0.id) }.count
        
        return VStack(alignment: .leading, spacing: 12) {
            // Category header
            if sortMode == .category {
                Button(action: { toggleCategory(category.id) }) {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(category.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("(\(selectedCount)/\(category.items.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(isExpanded ? "Hide" : "Show")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Items grid
            if isExpanded {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 16)
                    ],
                    spacing: 12
                ) {
                    ForEach(category.items) { item in
                        itemView(item)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
    
    // MARK: - Item View
    
    private func itemView(_ item: HealthIssueItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Checkbox
            Button(action: { toggleItem(item.id) }) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: selectedItems.keys.contains(item.id) ? "checkmark.square.fill" : "square")
                        .font(.body)
                        .foregroundColor(selectedItems.keys.contains(item.id) ? .blue : .secondary)
                    
                    Text(item.label)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Multi-select dropdown or text input if checked
            if selectedItems.keys.contains(item.id) {
                if let options = item.multiSelectOptions, !options.isEmpty {
                    multiSelectDropdown(item: item, options: options)
                } else if item.requiresNote {
                    textInput(item: item)
                }
            }
        }
    }
    
    // MARK: - Multi-Select Dropdown
    
    private func multiSelectDropdown(item: HealthIssueItem, options: [HealthIssueOption]) -> some View {
        let selection = selectedItems[item.id]
        let selectedOptions = Set(selection?.multiSelectValues ?? [])
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Select \(item.label.lowercased()):")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Selected chips
            if !selectedOptions.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(Array(selectedOptions).sorted(), id: \.self) { optionId in
                        if let option = options.first(where: { $0.id == optionId }) {
                            optionChip(option: option, item: item)
                        }
                    }
                }
            }
            
            // Dropdown menu
            Menu {
                ForEach(options) { option in
                    Button(action: { toggleMultiSelectOption(item: item, optionId: option.id) }) {
                        HStack {
                            Text(option.label)
                            if selectedOptions.contains(option.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Add option...")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
                .foregroundColor(.primary)
            }
            
            // "Other" text input if Other option is selected
            if selectedOptions.contains("__OTHER__") || selectedOptions.contains("other") {
                TextField("Specify other", text: Binding(
                    get: { selectedItems[item.id]?.noteText ?? "" },
                    set: { newValue in
                        if var selection = selectedItems[item.id] {
                            selection.noteText = newValue
                            selectedItems[item.id] = selection
                        }
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.subheadline)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
    
    private func optionChip(option: HealthIssueOption, item: HealthIssueItem) -> some View {
        Button(action: { toggleMultiSelectOption(item: item, optionId: option.id) }) {
            HStack(spacing: 4) {
                Text(option.label)
                    .font(.caption)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.2))
            )
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Text Input
    
    private func textInput(item: HealthIssueItem) -> some View {
        TextField("Specify", text: Binding(
            get: { selectedItems[item.id]?.noteText ?? "" },
            set: { newValue in
                if var selection = selectedItems[item.id] {
                    selection.noteText = newValue
                    selectedItems[item.id] = selection
                } else {
                    selectedItems[item.id] = HealthIssueSelection(noteText: newValue)
                }
            }
        ))
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .font(.subheadline)
        .padding(.leading, 28)
    }
    
    // MARK: - Macros Section
    
    private var macrosSection: some View {
        HStack(spacing: 12) {
            ForEach(macros, id: \.self) { macro in
                Button(action: { handleMacro(macro) }) {
                    Text(macroLabel(macro))
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func macroLabel(_ macro: String) -> String {
        switch macro {
        case "none_of_the_above":
            return "None of the above"
        case "reviewed_unchanged":
            return "Reviewed and unchanged"
        default:
            return macro.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleCategory(_ categoryId: String) {
        if expandedCategories.contains(categoryId) {
            expandedCategories.remove(categoryId)
        } else {
            expandedCategories.insert(categoryId)
        }
    }
    
    private func toggleItem(_ itemId: String) {
        if selectedItems.keys.contains(itemId) {
            selectedItems.removeValue(forKey: itemId)
        } else {
            selectedItems[itemId] = HealthIssueSelection()
            // Auto-expand the category containing this item
            if let category = categories.first(where: { $0.items.contains(where: { $0.id == itemId }) }) {
                expandedCategories.insert(category.id)
            }
        }
    }
    
    private func toggleMultiSelectOption(item: HealthIssueItem, optionId: String) {
        var selection = selectedItems[item.id] ?? HealthIssueSelection()
        var values = Set(selection.multiSelectValues ?? [])
        
        if values.contains(optionId) {
            values.remove(optionId)
        } else {
            values.insert(optionId)
        }
        
        selection.multiSelectValues = Array(values)
        selectedItems[item.id] = selection
    }
    
    private func findItem(id: String) -> HealthIssueItem? {
        for category in categories {
            if let item = category.items.first(where: { $0.id == id }) {
                return item
            }
        }
        return nil
    }
    
    private func clearAll() {
        selectedItems.removeAll()
    }
    
    private func handleMacro(_ macro: String) {
        switch macro {
        case "none_of_the_above":
            clearAll()
        case "reviewed_unchanged":
            // Set a flag in the answer if needed
            break
        default:
            break
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadExistingAnswer() {
        // Parse from text JSON format
        guard case .text(let jsonString) = answer,
              let jsonData = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let selectedDict = dict["selected"] as? [String: Any] else {
            return
        }
        
        for (itemId, value) in selectedDict {
            if let valueDict = value as? [String: Any] {
                var selection = HealthIssueSelection()
                selection.noteText = valueDict["note"] as? String
                
                if let multiSelect = valueDict["multi_select"] as? [String] {
                    selection.multiSelectValues = multiSelect
                }
                
                selectedItems[itemId] = selection
            }
        }
    }
    
    private func saveAnswer() {
        var resultDict: [String: Any] = [:]
        
        for (itemId, selection) in selectedItems {
            var selectionDict: [String: Any] = ["checked": true]
            
            if let note = selection.noteText, !note.isEmpty {
                selectionDict["note"] = note
            }
            
            if let multiSelect = selection.multiSelectValues, !multiSelect.isEmpty {
                selectionDict["multi_select"] = multiSelect
            }
            
            resultDict[itemId] = selectionDict
        }
        
        // Encode to JSON string
        let fullDict = ["selected": resultDict]
        if let jsonData = try? JSONSerialization.data(withJSONObject: fullDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            answer = .text(jsonString)
        }
    }
}

// MARK: - Helper Models

struct HealthIssueSelection: Equatable {
    var noteText: String?
    var multiSelectValues: [String]?
}

// MARK: - Flow Layout for Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
