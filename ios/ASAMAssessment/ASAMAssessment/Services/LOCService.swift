//
//  LOCService.swift
//  ASAM Assessment Application
//
//  Level of Care calculation using neutral taxonomy
//  Loads from data/loc_reference_neutral.json
//

import Foundation
import SwiftUI
import Combine

/// LOC Service - calculates Level of Care recommendations
@MainActor
class LOCService: ObservableObject {
    @Published var locReference: [LOCLevel] = []
    @Published var isLoaded: Bool = false

    init() {
        loadLOCReference()
    }

    /// Load LOC reference from neutral JSON
    private func loadLOCReference() {
        // In production, load from bundle or data directory
        // For now, create sample data matching data/loc_reference_neutral.json structure

        locReference = [
            LOCLevel(code: "EIO", name: "Level 0.5", description: "Early Intervention", minSeverity: 0, maxSeverity: 1),
            LOCLevel(code: "OP-REG", name: "Level 1", description: "Outpatient Regular", minSeverity: 1, maxSeverity: 2),
            LOCLevel(code: "IOP", name: "Level 2.1", description: "Intensive Outpatient", minSeverity: 2, maxSeverity: 3),
            LOCLevel(code: "PHP", name: "Level 2.5", description: "Partial Hospitalization", minSeverity: 2, maxSeverity: 3),
            LOCLevel(code: "RES-STD", name: "Level 3.1", description: "Clinically Managed Low-Intensity Residential", minSeverity: 3, maxSeverity: 4),
            LOCLevel(code: "RES-HIGH", name: "Level 3.5", description: "Clinically Managed High-Intensity Residential", minSeverity: 3, maxSeverity: 4),
            LOCLevel(code: "RES-WM", name: "Level 3.7-WM", description: "Medically Monitored Intensive Inpatient - Withdrawal Management", minSeverity: 4, maxSeverity: 4),
            LOCLevel(code: "MED-WM", name: "Level 4-WM", description: "Medically Managed Intensive Inpatient - Withdrawal Management", minSeverity: 4, maxSeverity: 4),
            LOCLevel(code: "ACUTE", name: "Level 4", description: "Medically Managed Intensive Inpatient", minSeverity: 4, maxSeverity: 4)
        ]

        isLoaded = true
    }

    /// Calculate LOC recommendation based on domain severities
    func calculateLOC(for assessment: Assessment) -> LOCRecommendation {
        // Calculate average severity across all domains
        let completedDomains = assessment.domains.filter { $0.isComplete }
        guard !completedDomains.isEmpty else {
            return LOCRecommendation(
                code: "PENDING",
                name: "Assessment Incomplete",
                confidence: 0.0,
                reasoning: ["Complete all domain assessments to generate recommendation"]
            )
        }

        let avgSeverity = Double(completedDomains.map { $0.severity }.reduce(0, +)) / Double(completedDomains.count)
        let maxSeverity = completedDomains.map { $0.severity }.max() ?? 0

        // Find matching LOC level
        let matchingLevel = locReference.first { level in
            avgSeverity >= Double(level.minSeverity) && avgSeverity <= Double(level.maxSeverity)
        } ?? locReference.first!

        // Build reasoning trace for explainability
        var reasoning: [String] = []
        reasoning.append("Average severity across \(completedDomains.count) domains: \(String(format: "%.1f", avgSeverity))")
        reasoning.append("Highest domain severity: \(maxSeverity)")

        for domain in completedDomains.filter({ $0.severity >= 3 }) {
            reasoning.append("Domain \(domain.number) (\(domain.title)): Severity \(domain.severity)")
        }

        reasoning.append("Recommended LOC: \(matchingLevel.name) (\(matchingLevel.code))")

        // Calculate confidence (higher with more complete domains)
        let confidence = Double(completedDomains.count) / 6.0

        return LOCRecommendation(
            code: matchingLevel.code,
            name: matchingLevel.name,
            confidence: confidence,
            reasoning: reasoning
        )
    }

    /// Get LOC level by code
    func getLOCLevel(code: String) -> LOCLevel? {
        locReference.first { $0.code == code }
    }
}

/// LOC Level definition from neutral taxonomy
struct LOCLevel: Identifiable, Codable {
    let id: UUID
    let code: String
    let name: String
    let description: String
    let minSeverity: Int
    let maxSeverity: Int

    init(code: String, name: String, description: String, minSeverity: Int, maxSeverity: Int) {
        self.id = UUID()
        self.code = code
        self.name = name
        self.description = description
        self.minSeverity = minSeverity
        self.maxSeverity = maxSeverity
    }
}
