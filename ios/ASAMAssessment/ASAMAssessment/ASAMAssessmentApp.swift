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
    @StateObject private var rulesService = RulesServiceWrapper()  // NEW: Rules engine
    @StateObject private var networkChecker = NetworkSanityChecker()  // NEW: Network monitoring
    @StateObject private var uploadQueue = UploadQueue()  // NEW: Idempotent upload queue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(assessmentStore)
                .environmentObject(auditService)
                .environmentObject(rulesService)  // NEW: Inject rules service
                .environmentObject(networkChecker)  // NEW: Inject network checker
                .environmentObject(uploadQueue)  // NEW: Inject upload queue
                .task {
                    // Perform initial network probe
                    await networkChecker.performActiveProbe()

                    // Start background upload processor
                    await processUploadQueue()
                }
                .onAppear {
                    // Log app launch (no PHI)
                    auditService.logEvent(.appLaunched, actor: "system", notes: "App started")

                    // Log rules engine status
                    if rulesService.isAvailable {
                        print("✅ Rules engine loaded successfully")
                    } else if let error = rulesService.errorMessage {
                        print("❌ Rules engine error: \(error)")
                    }
                }
        }
    }

    // MARK: - Background Upload Processor
    private func processUploadQueue() async {
        while true {
            try? await Task.sleep(for: .seconds(30))

            // Check network safety
            guard networkChecker.isSafeForUpload else {
                print("⏸️ Upload queue paused - network unsafe")
                continue
            }

            // Process pending uploads
            await uploadQueue.processPending { job in
                do {
                    // TODO: Replace with actual upload implementation
                    print("📤 Processing upload: \(job.documentId)")

                    // Simulate upload
                    try await Task.sleep(for: .seconds(1))

                    return true  // Success
                } catch {
                    print("❌ Upload failed: \(error)")
                    return false  // Retry
                }
            }
        }
    }
}

