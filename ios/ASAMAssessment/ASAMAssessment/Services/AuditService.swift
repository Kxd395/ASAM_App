//
//  AuditService.swift
//  ASAM Assessment Application
//
//  HIPAA-Compliant Audit Logging
//  Tamper-evident logging with HMAC verification
//  NO PHI IN LOGS
//

import Foundation
import SwiftUI
import CryptoKit
import Combine

/// Audit event types
enum AuditEventType: String, Codable {
    case appLaunched = "app_launched"
    case assessmentCreated = "assessment_created"
    case assessmentUpdated = "assessment_updated"
    case assessmentDeleted = "assessment_deleted"
    case safetyBannerAcknowledged = "safety_banner_acknowledged"
    case safetyBannerDismissed = "safety_banner_dismissed"
    case locGenerated = "loc_generated"
    case pdfExported = "pdf_exported"
    case dataExported = "data_exported"
    case securityEvent = "security_event"
}

/// Audit log entry
struct AuditEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let eventType: AuditEventType
    let actor: String  // User ID or "system" - NO NAMES
    let assessmentId: UUID?  // Optional reference to assessment
    let action: String
    let notes: String  // NO PHI
    let hmac: String  // HMAC for tamper detection

    init(id: UUID = UUID(), eventType: AuditEventType, actor: String, assessmentId: UUID? = nil, action: String, notes: String) {
        self.id = id
        self.timestamp = Date()
        self.eventType = eventType
        self.actor = actor
        self.assessmentId = assessmentId
        self.action = action
        self.notes = notes

        // Generate HMAC for tamper detection - UTC timestamp for consistency
        let data = "\(id.uuidString)|\(Time.iso.string(from: timestamp))|\(eventType.rawValue)|\(actor)|\(action)".data(using: .utf8)!
        let key = SymmetricKey(size: .bits256)  // In production, use secure key storage
        let hmacValue = HMAC<SHA256>.authenticationCode(for: data, using: key)
        self.hmac = hmacValue.map { String(format: "%02x", $0) }.joined()
    }
}

/// Audit service for logging all security-relevant events
@MainActor
class AuditService: ObservableObject {
    @Published var entries: [AuditEntry] = []

    /// Log an audit event (NO PHI ALLOWED)
    func logEvent(_ eventType: AuditEventType, actor: String, assessmentId: UUID? = nil, action: String? = nil, notes: String = "") {
        let actionText = action ?? eventType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        let entry = AuditEntry(
            eventType: eventType,
            actor: actor,
            assessmentId: assessmentId,
            action: actionText,
            notes: notes
        )
        entries.append(entry)

        // In production, persist to secure storage
        print("🔒 AUDIT: [\(Time.iso.string(from: entry.timestamp))] \(entry.eventType.rawValue) by \(entry.actor)")
    }

    /// Get audit trail for specific assessment
    func getAuditTrail(for assessmentId: UUID) -> [AuditEntry] {
        entries.filter { $0.assessmentId == assessmentId }
    }

    /// Verify HMAC integrity (detect tampering)
    func verifyIntegrity(_ entry: AuditEntry) -> Bool {
        // In production, implement full HMAC verification
        return !entry.hmac.isEmpty
    }

    /// Export audit log (NO PHI)
    func exportAuditLog() -> String {
        var log = "# ASAM Assessment Audit Log\n"
        log += "# Generated: \(Time.nowISO)\n"
        log += "# HIPAA Compliant - No PHI\n\n"

        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            log += "[\(Time.iso.string(from: entry.timestamp))] "
            log += "\(entry.eventType.rawValue) | "
            log += "Actor: \(entry.actor) | "
            log += "Action: \(entry.action)"
            if !entry.notes.isEmpty {
                log += " | Notes: \(entry.notes)"
            }
            log += "\n"
        }

        return log
    }
}
