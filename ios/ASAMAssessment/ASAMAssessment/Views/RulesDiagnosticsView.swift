//
//  RulesDiagnosticsView.swift
//  ASAM Assessment Application
//
//  Diagnostics screen for rules engine troubleshooting
//  Production polish for clinician training and support
//

import SwiftUI

struct RulesDiagnosticsView: View {
    @EnvironmentObject private var rulesService: RulesServiceWrapper
    @State private var showRawJSON = false
    @State private var wmJSON = ""
    @State private var locJSON = ""

    var body: some View {
        Form {
            Section("Status") {
                statusRow(
                    label: "Rules Engine",
                    value: rulesService.isAvailable ? "Available" : "Degraded",
                    color: rulesService.isAvailable ? .green : .red
                )

                if let checksum = rulesService.checksum {
                    statusRow(label: "Version", value: checksum.version, color: .primary)
                    statusRow(label: "Checksum", value: checksum.sha256Short, color: .secondary)
                }

                if let loaded = rulesService.loadedAt {
                    statusRow(label: "Loaded At", value: loaded.formatted(), color: .secondary)
                }
            }

            if !rulesService.isAvailable {
                Section("Error Details") {
                    if let error = rulesService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Label("Export functionality is disabled", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }

                Section("Impact") {
                    bulletPoint("WM recommendation unavailable")
                    bulletPoint("LOC placement recommendation unavailable")
                    bulletPoint("PDF export blocked until rules restored")
                    bulletPoint("Manual clinical judgment required")
                }

                Section("Troubleshooting") {
                    troubleshootingStep("1. Verify rules files exist in app bundle")
                    troubleshootingStep("2. Check file permissions")
                    troubleshootingStep("3. Reinstall app if corrupted")
                    troubleshootingStep("4. Contact support if issue persists")
                }
            }

            Section("Raw Rules Data") {
                Button("View WM Ladder JSON") {
                    loadWMJSON()
                    showRawJSON = true
                }

                Button("View LOC Guard JSON") {
                    loadLOCJSON()
                    showRawJSON = true
                }
            }

            Section("Test Probes") {
                Button("Reload Rules Engine") {
                    Task {
                        await rulesService.reinitialize()
                    }
                }

                Button("Simulate Degraded State") {
                    // For training purposes
                    print("⚠️ Simulating degraded state...")
                }
                .foregroundColor(.orange)
            }
        }
        .navigationTitle("Rules Diagnostics")
        .sheet(isPresented: $showRawJSON) {
            NavigationStack {
                ScrollView {
                    Text(wmJSON.isEmpty ? locJSON : wmJSON)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
                .navigationTitle("Raw JSON")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showRawJSON = false
                        }
                    }
                }
            }
        }
    }

    private func statusRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .bold()
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top) {
            Text("•")
            Text(text)
                .font(.caption)
        }
    }

    private func troubleshootingStep(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func loadWMJSON() {
        if let url = Bundle.main.url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules"),
           let data = try? Data(contentsOf: url),
           let string = String(data: data, encoding: .utf8) {
            wmJSON = string
        } else {
            wmJSON = "Error: Could not load WM ladder JSON"
        }
    }

    private func loadLOCJSON() {
        if let url = Bundle.main.url(forResource: "loc_indication.guard", withExtension: "json", subdirectory: "rules"),
           let data = try? Data(contentsOf: url),
           let string = String(data: data, encoding: .utf8) {
            locJSON = string
        } else {
            locJSON = "Error: Could not load LOC guard JSON"
        }
    }
}

#Preview {
    NavigationStack {
        RulesDiagnosticsView()
            .environmentObject(RulesServiceWrapper())
    }
}
