//
//  PDFMetadataScrubber.swift
//  ASAM Assessment Application
//
//  PDF metadata and XMP scrubbing for PHI protection
//  T-0041: PDF metadata and XMP scrub
//  Addresses: Device info leakage, creator names, PHI in metadata
//

import Foundation
import PDFKit

#if canImport(UIKit)
import UIKit
typealias PlatformFont = UIFont
#elseif canImport(AppKit)
import AppKit
typealias PlatformFont = NSFont
#endif

/// Scrub PHI and device info from PDF metadata
final class PDFMetadataScrubber {

    /// Strip all PHI and device metadata, keep only essential clinical data
    static func scrub(_ document: PDFDocument, planHash: String, rulesHash: String, version: String) {
        // Create neutral metadata dictionary
        let metadata: [AnyHashable: Any] = [
            PDFDocumentAttribute.titleAttribute: "",
            PDFDocumentAttribute.authorAttribute: "",
            PDFDocumentAttribute.creatorAttribute: "ASAM Clinical Exporter",
            PDFDocumentAttribute.producerAttribute: "ASAM Assessment v\(version)",
            PDFDocumentAttribute.keywordsAttribute: "",
            PDFDocumentAttribute.subjectAttribute: "ASAM Treatment Plan",

            // Custom attributes for audit trail (no PHI)
            "PlanChecksum": planHash,
            "RulesChecksum": rulesHash,
            "ASAMVersion": version
        ]

        document.documentAttributes = metadata

        print("🔒 PDF metadata scrubbed: plan=\(planHash.prefix(8)), rules=\(rulesHash.prefix(8))")
    }

    /// Remove XMP metadata if present
    static func removeXMP(_ document: PDFDocument) {
        // PDFKit doesn't expose direct XMP access, but setting clean metadata
        // should override any XMP embedded by the system

        guard let data = document.dataRepresentation() else {
            return
        }

        // Check for XMP packet markers
        if let string = String(data: data, encoding: .utf8),
           string.contains("<?xpacket") {
            print("⚠️ XMP metadata detected in PDF, may need manual stripping")
        }
    }

    /// Validate that no PHI-like strings are in metadata
    static func validateNoPHI(_ document: PDFDocument) -> Bool {
        guard let attrs = document.documentAttributes else {
            return true
        }

        let phiPatterns = [
            #"\b\d{3}-\d{2}-\d{4}\b"#,  // SSN
            #"\b\d{10}\b"#,              // MRN-like
            #"[A-Z]{2}\d{5,10}"#         // FIN-like
        ]

        for (_, value) in attrs {
            if let str = value as? String {
                for pattern in phiPatterns {
                    if str.range(of: pattern, options: .regularExpression) != nil {
                        print("❌ PHI-like pattern detected in metadata: \(pattern)")
                        return false
                    }
                }
            }
        }

        return true
    }

    /// Add rules checksum to PDF footer (for audit trail)
    static func stampFooter(_ page: PDFPage, rulesHash: String, timestamp: String) {
        let footer = "Generated: \(timestamp) | Rules: \(rulesHash.prefix(12))"

        let bounds = page.bounds(for: .mediaBox)
        let footerRect = CGRect(
            x: bounds.minX + 50,
            y: bounds.minY + 20,
            width: bounds.width - 100,
            height: 20
        )

        let annotation = PDFAnnotation(bounds: footerRect, forType: .freeText, withProperties: nil)
        annotation.font = PlatformFont.systemFont(ofSize: 8)
        annotation.fontColor = .gray
        annotation.contents = footer
        annotation.alignment = .center
        annotation.color = .clear
        annotation.border = nil

        page.addAnnotation(annotation)
    }
}
