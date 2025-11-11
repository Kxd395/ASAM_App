//
//  ComplianceConfig.swift
//  ASAMAssessment
//
//  COMPILE FIX #5: Typed compliance mode (not free string)
//  Single source of truth for compliance state
//

import Foundation
import SwiftUI
import Combine

/// Compliance mode determines IP restrictions and feature availability
enum ComplianceMode: String, Codable {
    case internal_neutral  // Default: No ASAM trademarks, neutral terminology
    case licensed_asam     // Licensed: Full ASAM branding and official templates
}

/// Global compliance configuration
/// Use `ComplianceConfig.current` throughout the app
class ComplianceConfig: ObservableObject {
    static let shared = ComplianceConfig()
    
    @AppStorage("compliance.mode") var mode: ComplianceMode = .internal_neutral
    @AppStorage("asam.license.id") var asamLicenseId: String?
    @AppStorage("legal.notice.version") var legalNoticeVersion: String = "1.0"
    
    private init() {}
    
    /// Check if licensed mode is allowed
    var canUseLicensedMode: Bool {
        guard let licenseId = asamLicenseId else { return false }
        return !licenseId.isEmpty
    }
    
    /// Set licensed mode (requires valid license ID)
    func setLicensedMode(licenseId: String) throws {
        guard !licenseId.isEmpty else {
            throw ComplianceError.missingLicenseId
        }
        self.asamLicenseId = licenseId
        self.mode = .licensed_asam
    }
    
    /// Reset to neutral mode
    func setNeutralMode() {
        self.mode = .internal_neutral
    }
}

enum ComplianceError: Error, LocalizedError {
    case missingLicenseId
    case officialTemplateInNeutralMode
    case bannedAssetInBundle
    
    var errorDescription: String? {
        switch self {
        case .missingLicenseId:
            return "Cannot enable licensed mode without a valid ASAM license ID"
        case .officialTemplateInNeutralMode:
            return "Cannot use official ASAM template in internal_neutral mode"
        case .bannedAssetInBundle:
            return "Banned ASAM asset found in app bundle"
        }
    }
}
