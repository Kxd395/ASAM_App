//
//  ExportPreflight.swift
//  ASAMAssessment
//
//  Export preflight checks before allowing PDF generation
//  T-0028: P1 - Block export when rules degraded or assessment incomplete
//

import Foundation

struct ExportPreflight {
    enum ExportError: LocalizedError {
        case rulesUnavailable(String)
        case assessmentIncomplete
        case validationFailed([String])
        case complianceViolation(String)
        
        var errorDescription: String? {
            switch self {
            case .rulesUnavailable(let message):
                return "Cannot export: Rules engine unavailable.\n\(message)"
            case .assessmentIncomplete:
                return "Cannot export: Assessment must be complete before exporting"
            case .validationFailed(let errors):
                return "Cannot export: The following validation gates must pass:\n\(errors.joined(separator: "\n"))"
            case .complianceViolation(let message):
                return "Cannot export: \(message)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .rulesUnavailable:
                return "Check that rules JSON files are present in the app bundle and properly formatted"
            case .assessmentIncomplete:
                return "Complete all 6 domains and document clinical problems"
            case .validationFailed:
                return "Review the validation gates section for details"
            case .complianceViolation:
                return "Ensure compliance settings are configured correctly"
            }
        }
    }
    
    /// Perform all preflight checks before export
    ///
    /// - Parameters:
    ///   - assessment: The assessment to validate
    ///   - rulesService: The rules service wrapper
    /// - Returns: Result indicating success or specific failure reason
    static func check(
        assessment: Assessment,
        rulesService: RulesServiceWrapper
    ) -> Result<Void, ExportError> {
        // Rule 1: Rules engine must be available (CRITICAL - T-0028)
        if !rulesService.isAvailable {
            let message = rulesService.errorMessage ?? "Unknown error"
            return .failure(.rulesUnavailable(message))
        }
        
        // Rule 2: Assessment must be marked complete
        if !assessment.isComplete {
            return .failure(.assessmentIncomplete)
        }
        
        // Rule 3: All validation gates must pass
        let failedGates = assessment.validationGates.filter { !$0.isPassed }
        if !failedGates.isEmpty {
            let errors = failedGates.compactMap { gate -> String? in
                if let msg = gate.errorMessage {
                    return "• \(gate.title): \(msg)"
                } else {
                    return "• \(gate.title): Not passed"
                }
            }
            return .failure(.validationFailed(errors))
        }
        
        // Rule 4: LOC recommendation must exist
        if assessment.locRecommendation == nil {
            return .failure(.validationFailed([
                "• LOC recommendation missing",
                "Run the rules engine to calculate level of care"
            ]))
        }
        
        return .success(())
    }
    
    /// Quick check - returns true if export is allowed
    static func canExport(assessment: Assessment, rulesService: RulesServiceWrapper) -> Bool {
        switch check(assessment: assessment, rulesService: rulesService) {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

// MARK: - Export Button Component

import SwiftUI

struct ExportButton: View {
    let assessment: Assessment
    @ObservedObject var rulesService: RulesServiceWrapper
    let action: () -> Void
    
    @State private var showingPreflightError = false
    @State private var preflightError: ExportPreflight.ExportError?
    
    var body: some View {
        Button {
            let result = ExportPreflight.check(
                assessment: assessment,
                rulesService: rulesService
            )
            
            switch result {
            case .success:
                action()
            case .failure(let error):
                preflightError = error
                showingPreflightError = true
            }
        } label: {
            Label("Export PDF", systemImage: "square.and.arrow.up")
        }
        .disabled(!canExport)
        .alert("Export Blocked", isPresented: $showingPreflightError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = preflightError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.localizedDescription)
                    
                    if let suggestion = error.recoverySuggestion {
                        Text("\nSuggestion: \(suggestion)")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var canExport: Bool {
        ExportPreflight.canExport(assessment: assessment, rulesService: rulesService)
    }
}

// MARK: - Convenience View Modifier

struct ExportPreflightModifier: ViewModifier {
    let assessment: Assessment
    @ObservedObject var rulesService: RulesServiceWrapper
    @Binding var isExportAllowed: Bool
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateExportStatus()
            }
            .onChange(of: assessment.isComplete) { _, _ in
                updateExportStatus()
            }
            .onChange(of: rulesService.isAvailable) { _, _ in
                updateExportStatus()
            }
    }
    
    private func updateExportStatus() {
        isExportAllowed = ExportPreflight.canExport(
            assessment: assessment,
            rulesService: rulesService
        )
    }
}

extension View {
    func exportPreflight(
        assessment: Assessment,
        rulesService: RulesServiceWrapper,
        isAllowed: Binding<Bool>
    ) -> some View {
        modifier(ExportPreflightModifier(
            assessment: assessment,
            rulesService: rulesService,
            isExportAllowed: isAllowed
        ))
    }
}
