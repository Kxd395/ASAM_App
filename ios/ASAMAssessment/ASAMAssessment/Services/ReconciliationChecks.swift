//
//  ReconciliationChecks.swift
//  ASAMAssessment
//
//  FIX #3: Cross-validation between flags, substance context, and domain ratings
//  Prevents contradictions like COWS 14 with D1 severity 1
//

import Foundation
import Combine

struct ReconciliationCheck {
    let id: String
    let severity: ReconciliationSeverity
    let message: String
    let suggestedFix: ReconciliationFix?
}

enum ReconciliationSeverity {
    case blocker   // Must fix before export
    case warning   // Should fix but can proceed
    case suggestion  // Optional improvement
}

struct ReconciliationFix {
    let action: String
    let newValue: Int
    let rationale: String
}

struct ReconciliationValidator {
    
    /// FIX #3: Check for contradictions between withdrawal scales and D1 severity
    /// Returns blocking errors if COWS/CIWA contradict domain A rating
    static func validateWithdrawalAlignment(
        substances: [SubstanceRow],
        domainASeverity: Int,
        flags: ClinicalFlags
    ) -> [ReconciliationCheck] {
        var checks: [ReconciliationCheck] = []
        
        // Check 1: High COWS requires minimum D1 severity
        if let maxCOWS = substances.compactMap({ $0.cows }).max(), maxCOWS > 0 {
            let minD1 = cowsToMinimumD1(cowsScore: maxCOWS)
            
            if domainASeverity < minD1 {
                checks.append(ReconciliationCheck(
                    id: "cows_d1_mismatch",
                    severity: .blocker,
                    message: "COWS score of \(maxCOWS) requires Domain A severity ≥ \(minD1), but current rating is \(domainASeverity)",
                    suggestedFix: ReconciliationFix(
                        action: "Set Domain A severity to \(minD1)",
                        newValue: minD1,
                        rationale: "COWS \(maxCOWS) indicates moderate-to-severe withdrawal"
                    )
                ))
            }
        }
        
        // Check 2: High CIWA requires minimum D1 severity
        if let maxCIWA = substances.compactMap({ $0.ciwa }).max(), maxCIWA > 0 {
            let minD1 = ciwaToMinimumD1(ciwaScore: maxCIWA)
            
            if domainASeverity < minD1 {
                checks.append(ReconciliationCheck(
                    id: "ciwa_d1_mismatch",
                    severity: .blocker,
                    message: "CIWA score of \(maxCIWA) requires Domain A severity ≥ \(minD1), but current rating is \(domainASeverity)",
                    suggestedFix: ReconciliationFix(
                        action: "Set Domain A severity to \(minD1)",
                        newValue: minD1,
                        rationale: "CIWA \(maxCIWA) indicates alcohol withdrawal risk"
                    )
                ))
            }
        }
        
        // Check 3: "No withdrawal signs" contradicts high D1 severity
        if flags.noWithdrawalSigns && domainASeverity > 1 {
            checks.append(ReconciliationCheck(
                id: "no_withdrawal_high_d1",
                severity: .blocker,
                message: "Cannot set 'No withdrawal signs' when Domain A severity is \(domainASeverity)",
                suggestedFix: ReconciliationFix(
                    action: "Set Domain A severity to 1 or uncheck flag",
                    newValue: 1,
                    rationale: "No withdrawal signs = minimal intoxication/withdrawal"
                )
            ))
        }
        
        return checks
    }
    
    /// FIX #4: Validate that unstable vitals block ambulatory WM recommendations
    /// CLINICAL LOGIC FIX #7: Check WM candidate list, not LOC string
    /// WM candidates depend on ASAM edition:
    ///   - v3: 1-WM, 2-WM, 3.2-WM, 3.7-WM, 4-WM
    ///   - v4 integrated: 1.7, 2.7, 3.7, 4.0 (with WM capability)
    static func validateVitalsStableForAmbulatoryWM(
        flags: ClinicalFlags,
        wmCandidates: [String],  // FIXED: Accept WM candidates, not LOC string
        asamVersion: ASAMVersion = .v4_2024
    ) -> [ReconciliationCheck] {
        var checks: [ReconciliationCheck] = []
        
        // Define ambulatory WM levels by edition
        let ambulatoryWMLevels: [String]
        switch asamVersion {
        case .v3_2013:
            ambulatoryWMLevels = ["1-WM", "2-WM", "3.2-WM"]  // v3 non-residential WM
        case .v4_2024:
            ambulatoryWMLevels = ["1.7", "2.7"]  // v4 integrated ambulatory WM
        }
        
        // Block ambulatory WM if vitals unstable
        if flags.vitalsUnstable {
            let unsafeWMMatches = wmCandidates.filter { ambulatoryWMLevels.contains($0) }
            
            if !unsafeWMMatches.isEmpty {
                checks.append(ReconciliationCheck(
                    id: "unstable_vitals_ambulatory_wm",
                    severity: .blocker,
                    message: "Cannot recommend ambulatory WM levels \(unsafeWMMatches.joined(separator: ", ")) with unstable vitals. Patient requires medically managed setting (3.7 or 4.0).",
                    suggestedFix: nil  // Must be medically managed
                ))
            }
        }
        
        return checks
    }
    
    /// FIX #4: Validate recent use with "no withdrawal signs"
    static func validateRecentUseAlignment(
        substances: [SubstanceRow],
        flags: ClinicalFlags
    ) -> [ReconciliationCheck] {
        var checks: [ReconciliationCheck] = []
        
        if flags.noWithdrawalSigns {
            // If flagged "no withdrawal", recent use (<24h) is suspicious
            let recentUse = substances.filter { ($0.lastUseHours ?? 999) <= 24 }
            
            if !recentUse.isEmpty {
                let substanceList = recentUse.map { $0.substanceGroup.rawValue }.joined(separator: ", ")
                checks.append(ReconciliationCheck(
                    id: "no_withdrawal_recent_use",
                    severity: .warning,
                    message: "Recent substance use (\(substanceList)) documented but 'No withdrawal signs' is checked",
                    suggestedFix: nil
                ))
            }
        }
        
        return checks
    }
    
    // MARK: - Thresholds
    
    /// Map COWS score to minimum Domain A severity
    /// Source: Clinical standards for opioid withdrawal
    private static func cowsToMinimumD1(cowsScore: Int) -> Int {
        switch cowsScore {
        case 0...4:
            return 1  // Minimal withdrawal
        case 5...12:
            return 2  // Mild-moderate withdrawal
        case 13...24:
            return 3  // Moderate withdrawal (WM indicated)
        case 25...36:
            return 3  // Moderately severe withdrawal
        default:  // 37+
            return 4  // Severe withdrawal (medically managed WM)
        }
    }
    
    /// Map CIWA score to minimum Domain A severity
    /// Source: Clinical Institute Withdrawal Assessment for Alcohol
    private static func ciwaToMinimumD1(ciwaScore: Int) -> Int {
        switch ciwaScore {
        case 0...7:
            return 1  // Minimal withdrawal
        case 8...15:
            return 2  // Mild-moderate withdrawal
        case 16...20:
            return 3  // Moderate withdrawal (monitoring)
        default:  // 21+
            return 3  // Severe withdrawal (inpatient)
        }
    }
}

// MARK: - Clinical Flags Helper

struct ClinicalFlags {
    let vitalsUnstable: Bool
    let pregnant: Bool
    let noWithdrawalSigns: Bool
    let acutePsych: Bool
}
