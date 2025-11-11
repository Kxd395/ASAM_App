//
//  SafetyReviewDiagnostic.swift
//  ASAM Assessment Application
//
//  Diagnostic tool to test safety review functionality
//

import SwiftUI

struct SafetyReviewDiagnostic: View {
    @State private var showSafetyReview = false
    @StateObject private var auditService = AuditService()
    @StateObject private var settings = AppSettings()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Safety Review Diagnostic")
                .font(.title)
                .padding()
            
            Button("Test Safety Review") {
                showSafetyReview = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            Text("Tap the button above to test the safety review sheet functionality")
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showSafetyReview) {
            SafetyReviewSheet(
                isPresented: $showSafetyReview,
                assessmentId: UUID()
            ) { result in
                print("✅ Safety Review Completed!")
                print("Action: \(result.action.rawValue)")
                print("Notes: \(result.notes)")
                print("Acknowledged: \(result.acknowledged)")
            }
            .environmentObject(settings)
            .environmentObject(auditService)
        }
    }
}

#Preview {
    SafetyReviewDiagnostic()
}