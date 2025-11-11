// SettingsView.swift
// In-app settings panel for display preferences (text size, sheet defaults, etc.)

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Display section: text size + sheet size preferences
                Section {
                    textSizeControl
                    sheetSizePicker
                } header: {
                    Text("Display")
                } footer: {
                    Text("Text size applies to all app content. Sheet size sets the default height for review screens.")
                }
                
                // Future controls section (placeholder)
                Section {
                    Toggle("Larger touch targets", isOn: .constant(false))
                        .disabled(true)
                        .foregroundStyle(.secondary)
                    
                    Toggle("High contrast mode", isOn: .constant(false))
                        .disabled(true)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("Additional controls coming soon.")
                }
                
                // App info section
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "001")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Text Size Control
    
    private var textSizeControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Text Size")
                    .font(.headline)
                Spacer()
                Text(settings.textSizeLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Slider(
                value: Binding(
                    get: { Double(settings.textSizeIndex) },
                    set: { settings.textSizeIndex = Int($0.rounded()) }
                ),
                in: 0...8,
                step: 1
            )
            
            HStack {
                Text("Smaller")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Larger")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Sheet Size Picker
    
    private var sheetSizePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default Sheet Size")
                .font(.headline)
            
            Picker("Default Sheet Size", selection: $settings.defaultSheetDetentIndex) {
                Text("Compact").tag(0)   // ~60% height
                Text("Comfort").tag(1)   // ~80% height (default)
                Text("Full").tag(2)      // Full screen
            }
            .pickerStyle(.segmented)
            
            Text("Sheets can be resized by dragging the handle.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
