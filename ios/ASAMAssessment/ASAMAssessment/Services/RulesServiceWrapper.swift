//
//  RulesServiceWrapper.swift
//  ASAMAssessment
//
//  SwiftUI-compatible wrapper for RulesService
//  Handles initialization errors gracefully with production hardening
//

import Foundation
import SwiftUI
import Combine
import CryptoKit

// MARK: - Rules Preflight

enum RulesPreflight {
    case ok
    case degraded(String)

    static func check(_ bundle: Bundle = .main) -> RulesPreflight {
        do {
            _ = try RulesService(
                bundle: bundle,
                wmRulesFile: "rules/wm_ladder.json",
                locRulesFile: "rules/loc_indication.guard.json",
                operatorsFile: "rules/operators.json"
            )
            return .ok
        } catch {
            return .degraded("Rules unavailable: \(error.localizedDescription)")
        }
    }
}

// MARK: - Rules Checksum

struct RulesChecksum {
    let sha256: String
    let version: String
    let timestamp: Date

    static func compute(bundle: Bundle = .main) -> RulesChecksum? {
        guard let wmURL = bundle.url(forResource: "wm_ladder", withExtension: "json", subdirectory: "rules"),
              let locURL = bundle.url(forResource: "loc_indication.guard", withExtension: "json", subdirectory: "rules"),
              let opURL = bundle.url(forResource: "operators", withExtension: "json", subdirectory: "rules") else {
            return nil
        }

        let combined = try? [wmURL, locURL, opURL]
            .compactMap { try? Data(contentsOf: $0) }
            .reduce(Data()) { $0 + $1 }

        guard let data = combined else { return nil }

        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

        return RulesChecksum(
            sha256: String(hashString.prefix(12)),  // 12-char prefix
            version: "1.1.0",
            timestamp: Date()
        )
    }
}

// MARK: - ASAM Version

enum ASAMVersion: String, CaseIterable {
    case v3 = "ASAM 3"
    case v4 = "ASAM 4"
}

// MARK: - Rules Service Wrapper

@MainActor
final class RulesServiceWrapper: ObservableObject {
    @Published var isAvailable = false
    @Published var errorMessage: String?
    @Published var checksum: RulesChecksum?

    @AppStorage("asam_version") var asamVersion: ASAMVersion = .v4

    private var svc: RulesService?
    private var debounceTask: Task<Void, Never>?
    private var lastResult: (wm: WMOutcome, loc: LOCOutcome)?

    init(bundle: Bundle = .main) {
        Task { @MainActor in
            await self.initialize(bundle: bundle)
        }
    }

    @MainActor
    private func initialize(bundle: Bundle) async {
        let preflight = RulesPreflight.check(bundle)

        switch preflight {
        case .ok:
            do {
                self.svc = try RulesService(
                    bundle: bundle,
                    wmRulesFile: "rules/wm_ladder.json",
                    locRulesFile: "rules/loc_indication.guard.json",
                    operatorsFile: "rules/operators.json"
                )
                self.isAvailable = true
                self.errorMessage = nil
                self.checksum = RulesChecksum.compute(bundle: bundle)

                if let checksum = self.checksum {
                    print("✅ Rules engine loaded successfully")
                    print("🔒 Rules: v\(checksum.version) [\(checksum.sha256)]")
                }
            } catch {
                self.isAvailable = false
                self.errorMessage = error.localizedDescription
                print("❌ Rules engine failed: \(error.localizedDescription)")
            }

        case .degraded(let message):
            self.isAvailable = false
            self.errorMessage = message
            print("⚠️ Rules engine degraded: \(message)")
        }
    }

    // MARK: - LOC Calculation with Adaptive Debouncing

    /// FIX #5: Evaluate WM and LOC with adaptive debouncing
    /// Safety-critical changes (flags, severity chips) bypass debounce
    /// - Parameters:
    ///   - assessment: Assessment to evaluate
    ///   - bypassDebounce: If true, evaluates immediately (for safety flags)
    func evaluate(_ assessment: Assessment, bypassDebounce: Bool = false) -> (wm: WMOutcome, loc: LOCOutcome)? {
        // FIX #5: Immediate evaluation for safety-critical changes
        if bypassDebounce {
            return performCalculation(assessment)
        }
        
        // Cancel previous debounce
        debounceTask?.cancel()

        // Return cached result immediately if available
        if let last = lastResult {
            // Kick off debounced recalculation in background
            scheduleCalculation(assessment)
            return last
        }

        // No cache, calculate synchronously
        return performCalculation(assessment)
    }

    private func scheduleCalculation(_ assessment: Assessment) {
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce for text inputs

            guard !Task.isCancelled else { return }

            let result = performCalculation(assessment)
            self.lastResult = result
        }
    }

    private func performCalculation(_ assessment: Assessment) -> (wm: WMOutcome, loc: LOCOutcome)? {
        guard isAvailable, let svc = svc else { return nil }

        let result = svc.evaluate(
            severities: assessment.domainSeverities(),
            d1Context: assessment.d1Context(),
            flags: assessment.flags()
        )

        return (wm: result.wm, loc: result.loc)
    }

    /// Convert to LOCRecommendation format for backward compatibility
    func calculateLOC(for assessment: Assessment) -> LOCRecommendation {
        guard let result = evaluate(assessment) else {
            // Fallback to 2.1 IOP (ASAM standard fallback, not 0.5)
            return LOCRecommendation(
                code: "2.1",
                name: "Intensive Outpatient (Fallback - Rules Unavailable)",
                confidence: 0.3,
                reasoning: ["Rules engine unavailable", "Using fallback recommendation"]
            )
        }

        // Map rules engine output to LOCRecommendation format
        let wmIndicatedText = result.wm.indicated ? "indicated" : "not indicated"
        let wmCandidates = result.wm.candidateLevels.joined(separator: ", ")
        let wmInfo = "WM: \(wmIndicatedText) [\(wmCandidates)]"

        // Combine all reasoning
        var allReasoning = ["Based on rules engine evaluation", wmInfo]
        allReasoning.append(contentsOf: result.loc.why)

        return LOCRecommendation(
            code: result.loc.indicated,
            name: locDescription(for: result.loc.indicated),
            confidence: 0.9,
            reasoning: allReasoning
        )
    }

    // MARK: - Level Descriptions

    func locDescription(for level: String) -> String {
        switch level {
        case "0.5":
            return "0.5 Early Intervention"
        case "1.0":
            return "1.0 Outpatient Services"
        case "2.1":
            return "2.1 Intensive Outpatient"
        case "2.5":
            return "2.5 Partial Hospitalization"
        case "3.1":
            return "3.1 Clinically Managed Low-Intensity Residential"
        case "3.3":
            if asamVersion == .v3 {
                return "3.3 Clinically Managed Medium-Intensity Residential"
            } else {
                return "Level 3.3 (deprecated in ASAM 4)"
            }
        case "3.5":
            return "3.5 Clinically Managed High-Intensity Residential"
        case "3.7":
            return "3.7 Medically Monitored Intensive Inpatient"
        case "4.0":
            return "4.0 Medically Managed Intensive Inpatient"
        default:
            return "Assessment Required"
        }
    }

    func wmDescription(for level: String) -> String {
        switch level {
        case "1.0":
            return "1.0 Ambulatory Withdrawal Management"
        case "2.1":
            return "2.1 Ambulatory Withdrawal Management with Extended On-Site Monitoring"
        case "2.5":
            return "2.5 Ambulatory Withdrawal Management"
        case "3.2":
            return "3.2 Clinically Managed Residential Withdrawal Management"
        case "3.7":
            return "3.7 Medically Monitored Inpatient Withdrawal Management"
        case "4.0":
            return "4.0 Medically Managed Intensive Inpatient Withdrawal Management"
        default:
            return "Unknown WM Level: \(level)"
        }
    }
}
