//
//  RulesProvenance.swift
//  ASAMAssessment
//
//  T-0029: Rules hash provenance tracking for audit trail
//  Ensures every PDF and audit event contains the rules version used
//

import Foundation
import CryptoKit

/// Rules provenance information for audit trail
struct RulesProvenance: Codable {
    let rulesHash: String  // 12-char SHA256 prefix
    let rulesVersion: String
    let timestamp: Date
    let legalNoticeVersion: String
    
    /// Short hash for PDF footer (first 12 chars)
    var shortHash: String {
        String(rulesHash.prefix(12))
    }
    
    /// Format for PDF footer
    /// Example: "Plan: 7f9c2a1b | Rules: 9c3a1b4d2e5f | Legal: v1.0"
    func pdfFooterText(planHash: String) -> String {
        "Plan: \(planHash.prefix(8)) | Rules: \(shortHash) | Legal: v\(legalNoticeVersion)"
    }
    
    /// Format for audit event
    func auditEventPayload() -> [String: Any] {
        [
            "rules_hash": rulesHash,
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
            rulesHash: self.sha256,
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
    
    private init() {}
    
    /// Record rules provenance on app launch
    func recordRulesLoaded(checksum: RulesChecksum, legalVersion: String = "1.0") {
        self.currentProvenance = checksum.toProvenance(legalVersion: legalVersion)
        
        // Log audit event
        print("📋 Rules loaded:")
        print("   Version: \(checksum.version)")
        print("   Hash: \(checksum.sha256.prefix(12))...")
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
    func stampProvenanceFooter(
        planHash: String,
        rulesProvenance: RulesProvenance
    ) {
        let footerText = rulesProvenance.pdfFooterText(planHash: planHash)
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
            provenanceAnnotation.font = NSFont.monospacedSystemFont(ofSize: 7, weight: .regular)
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
            timestampAnnotation.font = NSFont.monospacedSystemFont(ofSize: 7, weight: .regular)
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
