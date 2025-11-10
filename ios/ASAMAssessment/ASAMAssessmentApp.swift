//
//  ASAMAssessmentApp.swift
//  ASAM Assessment Application
//
//  Created: November 9, 2025
//  HIPAA Compliant | WCAG 2.1 AA | iOS 16+
//

import SwiftUI

@main
struct ASAMAssessmentApp: App {
    @StateObject private var assessmentStore = AssessmentStore()
    @StateObject private var auditService = AuditService()
    @StateObject private var locService = LOCService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(assessmentStore)
                .environmentObject(auditService)
                .environmentObject(locService)
                .onAppear {
                    // Log app launch (no PHI)
                    auditService.logEvent(.appLaunched, actor: "system", notes: "App started")
                }
        }
    }
}
