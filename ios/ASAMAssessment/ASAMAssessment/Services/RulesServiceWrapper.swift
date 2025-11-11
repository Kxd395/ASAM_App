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

// MARK: - Resilient Bundle Resolver

/// Resilient JSON resolver: handles both folder references AND flattened bundles
/// Tries: 1) rules/ subdirectory, 2) bundle root, 3) scan all paths
fileprivate func resolveJSON(_ name: String, bundle: Bundle) -> URL? {
    // 1) Preferred: inside rules/ subdirectory (blue folder reference)
    if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "rules") {
        return url
    }
    // 2) Flattened (yellow group fallback): root of bundle
    if let url = bundle.url(forResource: name, withExtension: "json") {
        return url
    }
    // 3) Last resort: scan all json and match basename
    let matches = bundle.paths(forResourcesOfType: "json", inDirectory: nil)
        .filter { $0.hasSuffix("/\(name).json") || $0.contains("/rules/\(name).json") }
    return matches.first.map(URL.init(fileURLWithPath:))
}

// MARK: - Rules Preflight

enum RulesPreflight {
    case ok
    case degraded(String)

    static func check(_ bundle: Bundle = .main) -> RulesPreflight {
        // Use resilient resolver for preflight
        guard let wmURL = resolveJSON("wm_ladder", bundle: bundle),
              let locURL = resolveJSON("loc_indication.guard", bundle: bundle),
              let opURL = resolveJSON("operators", bundle: bundle) else {
            return .degraded("Missing required rules files (wm_ladder, loc_indication.guard, or operators)")
        }

        do {
            _ = try RulesService(
                bundle: bundle,
                wmRulesFile: wmURL.path,
                locRulesFile: locURL.path,
                operatorsFile: opURL.path
            )
            return .ok
        } catch {
            return .degraded("Rules unavailable: \(error.localizedDescription)")
        }
    }
}

// MARK: - Rules Checksum

struct RulesChecksum: Codable {
    let sha256Full: String   // Full 64-char hex for audit/provenance
    let version: String
    let timestamp: Date
    let manifest: String     // JSON array of {file, sha256, bytes}

    /// Short 12-char hash for display in footers
    var sha256Short: String {
        String(sha256Full.prefix(12)).uppercased()
    }

    /// Canonical data read: normalize line endings to LF, ensure UTF-8
    private static func canonicalData(for url: URL) throws -> Data {
        var data = try Data(contentsOf: url)
        // Normalize line endings for cross-platform determinism
        if let str = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n"),
           let normalized = str.data(using: .utf8) {
            data = normalized
        }
        return data
    }

    static func compute(bundle: Bundle = .main, subdir: String = "rules") -> RulesChecksum? {
        // Canonical file list (must match documented audit inputs)
        // Order matters for deterministic hash
        let filenames = ["anchors.json",
                        "wm_ladder.json",
                        "loc_indication.guard.json",
                        "validation_rules.json",
                        "operators.json"]

        var manifestEntries: [[String: Any]] = []
        var concat = Data()

        for filename in filenames {
            let resource = filename.replacingOccurrences(of: ".json", with: "")

            // Use resilient resolver instead of strict subdirectory lookup
            guard let url = resolveJSON(resource, bundle: bundle) else {
                print("❌ Missing file: \(filename) (tried rules/, root, and full scan)")
                return nil
            }

            guard let data = try? canonicalData(for: url) else {
                print("❌ Cannot read file: \(filename)")
                return nil
            }

            concat.append(data)
            let fileHash = SHA256.hash(data: data)
            let fileHashString = fileHash.compactMap { String(format: "%02x", $0) }.joined()

            manifestEntries.append([
                "file": filename,
                "sha256": fileHashString,
                "bytes": data.count
            ])
        }

        let fullHash = SHA256.hash(data: concat)
        let fullHashString = fullHash.compactMap { String(format: "%02x", $0) }.joined()

        // Pretty-print manifest for auditors
        let manifestData = try? JSONSerialization.data(
            withJSONObject: manifestEntries,
            options: [.prettyPrinted, .sortedKeys]
        )
        let manifestJSON = manifestData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        return RulesChecksum(
            sha256Full: fullHashString,  // Full 64-char
            version: "v4",
            timestamp: Date(),
            manifest: manifestJSON
        )
    }
}

// MARK: - ASAM Version

enum ASAMVersion: String, CaseIterable {
    case v3 = "ASAM 3"
    case v4 = "ASAM 4"
}

// MARK: - Rules Service Wrapper

/// COMPILE FIX #3: Rules state enum for preflight checks
enum RulesState: Equatable {
    case healthy
    case degraded(String)
}

@MainActor
final class RulesServiceWrapper: ObservableObject {
    @Published var isAvailable = false
    @Published var errorMessage: String?
    @Published var checksum: RulesChecksum?
    @Published var rulesState: RulesState = .degraded("Uninitialized")  // COMPILE FIX #3
    @Published var loadedAt: Date?  // Track when rules loaded successfully

    @AppStorage("asam_version") var asamVersion: ASAMVersion = .v4

    private var svc: RulesService?
    private var debounceTask: Task<Void, Never>?
    private var lastResult: (wm: WMOutcome, loc: LOCOutcome)?

    init(bundle: Bundle = .main) {
        Task { @MainActor in
            await self.initialize(bundle: bundle)
        }
    }

    /// Public method to reinitialize rules engine (for diagnostics/retry)
    func reinitialize(bundle: Bundle = .main) async {
        await initialize(bundle: bundle)
    }

    @MainActor
    private func initialize(bundle: Bundle) async {
        // HYPER-CRITICAL DIAGNOSTIC: Prove files exist in runtime bundle
        debugRulesBundle(bundle)

        let preflight = RulesPreflight.check(bundle)

        switch preflight {
        case .ok:
            do {
                // Use resilient resolver to find files (handles both folder ref and flattened)
                guard let wmURL = resolveJSON("wm_ladder", bundle: bundle),
                      let locURL = resolveJSON("loc_indication.guard", bundle: bundle),
                      let opURL = resolveJSON("operators", bundle: bundle) else {
                    throw RulesServiceError.missing("Required rules files not found in bundle")
                }

                self.svc = try RulesService(
                    bundle: bundle,
                    wmRulesFile: wmURL.path,
                    locRulesFile: locURL.path,
                    operatorsFile: opURL.path
                )
                self.isAvailable = true
                self.errorMessage = nil
                self.rulesState = .healthy  // COMPILE FIX #3
                self.loadedAt = Date()  // Record successful load time
                self.checksum = RulesChecksum.compute(bundle: bundle)

                if let checksum = self.checksum {
                    print("✅ Rules engine loaded successfully")
                    print("🔒 Rules: v\(checksum.version) [\(checksum.sha256Short)]")
                    print("📋 Full hash: \(checksum.sha256Full)")
                    print("📄 Manifest: \(checksum.manifest)")
                }
            } catch {
                self.isAvailable = false
                self.errorMessage = error.localizedDescription
                self.rulesState = .degraded(error.localizedDescription)  // COMPILE FIX #3
                self.loadedAt = nil  // Clear load time on failure
                print("❌ Rules engine failed: \(error.localizedDescription)")
            }

        case .degraded(let message):
            self.isAvailable = false
            self.errorMessage = message
            self.rulesState = .degraded(message)  // COMPILE FIX #3
            self.loadedAt = nil  // Clear load time when degraded
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

    /// HYPER-CRITICAL DIAGNOSTIC: Prove files exist in runtime bundle
    /// Call before any parse to definitively show bundle structure
    private func debugRulesBundle(_ bundle: Bundle = .main) {
        let want = [
            "anchors.json",
            "wm_ladder.json",
            "loc_indication.guard.json",
            "validation_rules.json",
            "operators.json"
        ]
        print("📦 bundle.rules dir = \(bundle.bundleURL.path)")
        for f in want {
            if let url = bundle.url(forResource: (f as NSString).deletingPathExtension,
                                    withExtension: (f as NSString).pathExtension,
                                    subdirectory: "rules"),
               let data = try? Data(contentsOf: url) {
                print("✅ rules/\(f) size=\(data.count)")
            } else {
                print("❌ MISSING rules/\(f)")
            }
        }
    }
}
