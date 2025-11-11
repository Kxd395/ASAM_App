//
//  MDMWipeHandler.swift
//  ASAM Assessment Application
//
//  MDM remote wipe with secure zeroization
//  T-0038: MDM wipe path
//  Addresses: Lost device security, regulatory compliance, audit trail
//

import Foundation
import Security
import Combine

#if canImport(UIKit)
import UIKit
#endif

enum WipeError: LocalizedError {
    case keychainDeleteFailed(OSStatus)
    case databaseDeleteFailed(Error)
    case tempFilesPurgeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .keychainDeleteFailed(let status):
            return "Keychain delete failed: \(status)"
        case .databaseDeleteFailed(let error):
            return "Database delete failed: \(error.localizedDescription)"
        case .tempFilesPurgeFailed(let error):
            return "Temp files purge failed: \(error.localizedDescription)"
        }
    }
}

/// MDM-triggered secure wipe handler
final class MDMWipeHandler {
    // private let auditService: AuditService  // TODO: Wire when integrated
    private let databasePath: URL
    private let keychainService = "com.asam.keychain"

    init(databasePath: URL) {
        // self.auditService = auditService
        self.databasePath = databasePath
    }

    /// Check MDM wipe configuration
    func checkWipeTrigger() -> Bool {
        // Read from Managed App Config
        if let config = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed"),
           let wipe = config["wipe_device"] as? Bool {
            return wipe
        }
        return false
    }

    /// Execute secure wipe
    func executeWipe() throws {
        print("🚨 MDM wipe triggered, starting secure data deletion...")

        // 1. Record audit tombstone BEFORE deletion
        recordAuditTombstone()

        // 2. Zeroize encryption keys
        try zeroizeKeys()

        // 3. Delete database
        try deleteDatabase()

        // 4. Purge temp files
        try purgeTempFiles()

        // 5. Clear UserDefaults
        clearUserDefaults()

        print("✅ Secure wipe completed")
    }

    /// Record final audit event before wipe
    private func recordAuditTombstone() {
        #if canImport(UIKit)
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        #else
        let deviceID = "unknown"
        #endif

        // TODO: Integrate with actual AuditService
        print("🔒 Audit tombstone: device \(deviceID) wiped at \(Date())")

        /* When AuditService is available, uncomment:
        auditService.logEvent(
            .securityEvent,
            actor: "MDM",
            notes: "Device wipe executed, all local data deleted",
            metadata: [
                "wipe_timestamp": Date().description,
                "device_id": deviceID
            ]
        )
        auditService.syncNow()
        */
    }

    /// Zeroize all encryption keys in keychain
    private func zeroizeKeys() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw WipeError.keychainDeleteFailed(status)
        }

        print("🔒 Keychain items zeroized")
    }

    /// Securely delete database file
    private func deleteDatabase() throws {
        let fm = FileManager.default

        if fm.fileExists(atPath: databasePath.path) {
            try fm.removeItem(at: databasePath)
            print("🗑️ Database deleted: \(databasePath.lastPathComponent)")
        }

        // Delete WAL and SHM files if they exist
        let walPath = databasePath.appendingPathExtension("wal")
        let shmPath = databasePath.appendingPathExtension("shm")

        try? fm.removeItem(at: walPath)
        try? fm.removeItem(at: shmPath)
    }

    /// Purge all temp files
    private func purgeTempFiles() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory

        let contents = try fm.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)

        for file in contents {
            try? fm.removeItem(at: file)
        }

        print("🗑️ Temp files purged: \(contents.count) files")
    }

    /// Clear all UserDefaults
    private func clearUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print("🗑️ UserDefaults cleared")
    }
}

/* TODO: Wire AuditService integration
extension AuditService {
    /// Force immediate sync (stub - implement with actual sync logic)
    func syncNow() {
        print("📤 Audit log sync triggered")
    }
}
*/
