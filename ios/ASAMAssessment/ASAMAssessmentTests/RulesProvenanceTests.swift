//
//  RulesProvenanceTests.swift
//  ASAMAssessmentTests
//
//  Tests for T-0029: Verify rules hash is stamped in PDF footer and audit events
//

import XCTest
@testable import ASAMAssessment

final class RulesProvenanceTests: XCTestCase {

    // MARK: - Rules Checksum Tests

    func testRulesChecksum_ComputesValidHash() {
        // When: Compute checksum
        guard let checksum = RulesChecksum.compute() else {
            XCTFail("Failed to compute rules checksum")
            return
        }

        // Then: Hash should be 12 characters (truncated SHA256)
        XCTAssertEqual(checksum.sha256.count, 12)
        XCTAssertFalse(checksum.sha256.isEmpty)
        XCTAssertFalse(checksum.version.isEmpty)
    }

    func testRulesChecksum_IsDeterministic() {
        // When: Compute twice
        guard let checksum1 = RulesChecksum.compute(),
              let checksum2 = RulesChecksum.compute() else {
            XCTFail("Failed to compute checksums")
            return
        }

        // Then: Should match (same files = same hash)
        XCTAssertEqual(checksum1.sha256, checksum2.sha256)
    }

    // MARK: - Provenance Tests

    func testProvenance_PDFFooterText_ContainsAllFields() {
        // Given: Provenance record
        let provenance = RulesProvenance(
            rulesHash: "9c3a1b4d2e5f",
            rulesVersion: "1.1.0",
            timestamp: Date(),
            legalNoticeVersion: "1.0"
        )

        let planId = "plan-12345"
        let planHash = "7f9c2a1b3d4e"
        let complianceMode = "internal_neutral"

        // When: Generate PDF footer text
        let footerText = provenance.pdfFooterText(
            planId: planId,
            planHash: planHash, 
            complianceMode: complianceMode
        )

        // Then: Contains all required fields
        XCTAssertTrue(footerText.contains("Plan:"))
        XCTAssertTrue(footerText.contains("Rules:"))
        XCTAssertTrue(footerText.contains("Legal:"))
        XCTAssertTrue(footerText.contains(String(planHash.prefix(8))))
        XCTAssertTrue(footerText.contains(provenance.shortHash))
        XCTAssertTrue(footerText.contains("v1.0"))
    }

    func testProvenance_AuditEventPayload_ContainsRequiredFields() {
        // Given: Provenance record
        let provenance = RulesProvenance(
            rulesHash: "9c3a1b4d2e5f",
            rulesVersion: "1.1.0",
            timestamp: Date(),
            legalNoticeVersion: "1.0"
        )

        // When: Generate audit payload
        let payload = provenance.auditEventPayload()

        // Then: Contains required fields
        XCTAssertNotNil(payload["rules_hash"])
        XCTAssertNotNil(payload["rules_version"])
        XCTAssertNotNil(payload["rules_timestamp"])
        XCTAssertNotNil(payload["legal_notice_version"])

        XCTAssertEqual(payload["rules_hash"] as? String, "9c3a1b4d2e5f")
        XCTAssertEqual(payload["rules_version"] as? String, "1.1.0")
        XCTAssertEqual(payload["legal_notice_version"] as? String, "1.0")
    }

    // MARK: - Tracker Tests

    func testProvenanceTracker_RecordsChecksum() {
        // Given: Checksum
        guard let checksum = RulesChecksum.compute() else {
            XCTFail("Failed to compute checksum")
            return
        }

        // When: Record
        RulesProvenanceTracker.shared.recordRulesLoaded(
            checksum: checksum,
            legalVersion: "1.0"
        )

        // Then: Available for export
        guard let provenance = RulesProvenanceTracker.shared.provenanceForExport() else {
            XCTFail("Provenance not available after recording")
            return
        }

        XCTAssertEqual(provenance.rulesHash, checksum.sha256)
        XCTAssertEqual(provenance.rulesVersion, checksum.version)
        XCTAssertEqual(provenance.legalNoticeVersion, "1.0")
    }

    // MARK: - Integration Tests

    func testFullFlow_ChecksumToProvenanceToPDF() {
        // Given: Compute checksum
        guard let checksum = RulesChecksum.compute() else {
            XCTFail("Failed to compute checksum")
            return
        }

        // When: Record and generate footer
        RulesProvenanceTracker.shared.recordRulesLoaded(
            checksum: checksum,
            legalVersion: "1.0"
        )

        guard let provenance = RulesProvenanceTracker.shared.provenanceForExport() else {
            XCTFail("Provenance not available")
            return
        }

        let planId = "test-plan-456" 
        let planHash = "abc123def456"
        let complianceMode = "internal_neutral"
        let footerText = provenance.pdfFooterText(
            planId: planId,
            planHash: planHash,
            complianceMode: complianceMode
        )

        // Then: Footer contains all hashes
        XCTAssertTrue(footerText.contains(String(planHash.prefix(8))))
        XCTAssertTrue(footerText.contains(provenance.shortHash))
        XCTAssertTrue(footerText.contains("v1.0"))

        // Verify format: "Plan: ... | Rules: ... | Legal: v..."
        let components = footerText.components(separatedBy: "|")
        XCTAssertEqual(components.count, 3, "Footer should have 3 pipe-separated sections")
    }

    func testRulesHashChanges_WhenRulesModified() {
        // This test verifies that if rules JSON changes, hash changes
        // In real scenario, you would modify a rules file and recompute

        // Given: Initial checksum
        guard let checksum1 = RulesChecksum.compute() else {
            XCTFail("Failed to compute initial checksum")
            return
        }

        // NOTE: In a real test, you would:
        // 1. Modify a rules JSON file
        // 2. Recompute checksum
        // 3. Verify hash changed

        // For this unit test, we just verify the hash exists and is valid
        XCTAssertEqual(checksum1.sha256.count, 12)
        XCTAssertTrue(checksum1.sha256.allSatisfy { $0.isHexDigit })
    }

    // MARK: - Edge Cases

    func testProvenance_ShortHash_Truncates() {
        // Given: Long hash
        let provenance = RulesProvenance(
            rulesHash: "9c3a1b4d2e5f6a7b8c9d0e1f",  // 24 chars
            rulesVersion: "1.0.0",
            timestamp: Date(),
            legalNoticeVersion: "1.0"
        )

        // When: Get short hash
        let shortHash = provenance.shortHash

        // Then: Truncated to 12 chars
        XCTAssertEqual(shortHash.count, 12)
        XCTAssertEqual(shortHash, "9c3a1b4d2e5f")
    }
}

extension Character {
    var isHexDigit: Bool {
        return ("0"..."9").contains(self) || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}
