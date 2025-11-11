//
//  RulesProvenance.swift
//  ASAMAssessment
//
//  T-0029: Rules hash provenance tracking for audit trail
//  Ensures every PDF and audit event contains the rules version used
//

import Foundation
import CryptoKit
import PDFKit  // COMPILE FIX #1: Required for PDFDocument extension

#if canImport(UIKit)
import UIKit   // iOS
typealias PlatformFont = UIFont
#elseif canImport(AppKit)
import AppKit  // macOS
typealias PlatformFont = NSFont
#endif

/// Rules provenance information for audit trail
/// FIX #1: Canonical provenance with exact footer format
struct RulesProvenance: Codable {
    let rulesetHash: String  // Full SHA256 (64 hex chars)
    let rulesManifest: String  // JSON: [{"file": "anchors.json", "hash": "..."}]
    let rulesVersion: String  // e.g., "v4"
    let timestamp: Date
    let legalNoticeVersion: String

    /// Deterministic PDF footer with uppercase hex
    /// Format: "Plan <8> | Seal <12> | Rules <12> | Legal v1.0 | Mode <mode>"
    /// Example: "Plan 7F9C2A1B | Seal A3B2C1D4E5F6 | Rules 9C3A1B4D2E5F | Legal v1.0 | Mode internal_neutral"
    func pdfFooterText(planId: String, planHash: String, complianceMode: String) -> String {
        let planIdShort = String(planId.prefix(8)).uppercased()
        let planHashShort = String(planHash.prefix(12)).uppercased()
        let rulesHashShort = String(rulesetHash.prefix(12)).uppercased()
        return "Plan \(planIdShort) | Seal \(planHashShort) | Rules \(rulesHashShort) | Legal v\(legalNoticeVersion) | Mode \(complianceMode)"
    }

    /// Format for audit event
    func auditEventPayload() -> [String: Any] {
        [
            "ruleset_hash": rulesetHash,
            "rules_manifest": rulesManifest,
            "rules_version": rulesVersion,
            "rules_timestamp": ISO8601DateFormatter().string(from: timestamp),
            "legal_notice_version": legalNoticeVersion
        ]
    }
}

extension RulesChecksum {
    /// Convert to provenance record
    func toProvenance(legalVersion: String = "1.0") -> RulesProvenance {
        RulesProvenance(
            rulesetHash: self.sha256,  // Full 64-char hash
            rulesManifest: self.manifest,  // JSON manifest
            rulesVersion: self.version,
            timestamp: self.timestamp,
            legalNoticeVersion: legalVersion
        )
    }
}

// MARK: - Global Rules Provenance Storage

/// Singleton for app-wide rules provenance tracking
class RulesProvenanceTracker {
    static let shared = RulesProvenanceTracker()

    private(set) var currentProvenance: RulesProvenance?
    private(set) var currentChecksum: RulesChecksum?  // Store checksum for verification

    private init() {}

    /// Record rules provenance on app launch
    func recordRulesLoaded(checksum: RulesChecksum, legalVersion: String = "1.0") {
        self.currentChecksum = checksum
        self.currentProvenance = checksum.toProvenance(legalVersion: legalVersion)

        // Log audit event
        print("📋 Rules loaded:")
        print("   Version: \(checksum.version)")
        print("   Hash: \(checksum.sha256Short)...")
        print("   Legal: v\(legalVersion)")
    }

    /// Get current provenance for PDF export
    func provenanceForExport() -> RulesProvenance? {
        return currentProvenance
    }
}

// MARK: - PDF Footer Stamping

extension PDFDocument {
    /// Add rules provenance footer to all pages
    /// T-0029: Required for compliance audit trail
    /// COMPILE FIX #1: Corrected signature to match pdfFooterText(planId:planHash:complianceMode:)
    func stampProvenanceFooter(
        planId: String,
        planHash: String,
        complianceMode: String,
        rulesProvenance: RulesProvenance
    ) {
        let footerText = rulesProvenance.pdfFooterText(
            planId: planId,
            planHash: planHash,
            complianceMode: complianceMode
        )
        let timestamp = ISO8601DateFormatter().string(from: Date())

        for pageIndex in 0..<pageCount {
            guard let page = page(at: pageIndex) else { continue }

            let bounds = page.bounds(for: .cropBox)

            // Main provenance footer (bottom right)
            let provenanceAnnotation = PDFAnnotation(
                bounds: CGRect(
                    x: bounds.width - 300,
                    y: 20,
                    width: 280,
                    height: 12
                ),
                forType: .freeText,
                withProperties: nil
            )
            // COMPILE FIX #1: NSFont→UIFont for iOS
            provenanceAnnotation.font = PlatformFont.monospacedSystemFont(ofSize: 7, weight: .regular)
            provenanceAnnotation.fontColor = .lightGray
            provenanceAnnotation.alignment = .right
            provenanceAnnotation.contents = footerText
            provenanceAnnotation.backgroundColor = .clear
            provenanceAnnotation.border = nil

            page.addAnnotation(provenanceAnnotation)

            // Timestamp footer (bottom left)
            let timestampAnnotation = PDFAnnotation(
                bounds: CGRect(
                    x: 36,
                    y: 20,
                    width: 200,
                    height: 12
                ),
                forType: .freeText,
                withProperties: nil
            )
            // COMPILE FIX #1: NSFont→UIFont for iOS
            timestampAnnotation.font = PlatformFont.monospacedSystemFont(ofSize: 7, weight: .regular)
            timestampAnnotation.fontColor = .lightGray
            timestampAnnotation.alignment = .left
            timestampAnnotation.contents = "Generated: \(timestamp)"
            timestampAnnotation.backgroundColor = .clear
            timestampAnnotation.border = nil

            page.addAnnotation(timestampAnnotation)
        }
    }
}

// MARK: - Example Usage

/*
 // On app launch (in ASAMAssessmentApp.swift):

 Task { @MainActor in
     if let checksum = RulesChecksum.compute() {
         RulesProvenanceTracker.shared.recordRulesLoaded(
             checksum: checksum,
             legalVersion: "1.0"
         )
     }
 }

 // During PDF export:

 guard let provenance = RulesProvenanceTracker.shared.provenanceForExport() else {
     throw ExportError.rulesProvenanceMissing
 }

 pdfDocument.stampProvenanceFooter(
     planHash: planHash,
     rulesProvenance: provenance
 )
 */
