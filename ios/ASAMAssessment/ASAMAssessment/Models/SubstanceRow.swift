//
//  SubstanceRow.swift
//  ASAMAssessment
//
//  Data model for substance use context (Domain 1)
//

import Foundation
import Combine

struct SubstanceRow: Identifiable, Codable, Hashable {
    let id: UUID
    var substanceGroup: SubstanceGroup
    var lastUseHours: Int?
    var cows: Int?  // Clinical Opiate Withdrawal Scale (0-48)
    var ciwa: Int?  // Clinical Institute Withdrawal Assessment (0-67)
    var route: Set<RouteOfUse>

    init(
        id: UUID = UUID(),
        substanceGroup: SubstanceGroup = .alcohol,
        lastUseHours: Int? = nil,
        cows: Int? = nil,
        ciwa: Int? = nil,
        route: Set<RouteOfUse> = []
    ) {
        self.id = id
        self.substanceGroup = substanceGroup
        self.lastUseHours = lastUseHours
        self.cows = cows
        self.ciwa = ciwa
        self.route = route
    }

    /// Convert to JSON dict for rules engine
    func toJSON() -> [String: Any] {
        var dict: [String: Any] = [
            "substance_group": substanceGroup.rawValue
        ]

        if let hours = lastUseHours {
            dict["last_use_hours"] = hours
        }

        if let cowsScore = cows {
            dict["cows"] = cowsScore
        }

        if let ciwaScore = ciwa {
            dict["ciwa"] = ciwaScore
        }

        if !route.isEmpty {
            dict["route"] = route.map { $0.rawValue }
        }

        return dict
    }
}

// MARK: - Enums

enum SubstanceGroup: String, CaseIterable, Codable {
    case alcohol = "alcohol"
    case opioid = "opioid"
    case stimulant = "stimulant"
    case cannabis = "cannabis"
    case benzodiazepine = "benzodiazepine"
    case hallucinogen = "hallucinogen"
    case inhalant = "inhalant"
    case other = "other"

    var displayName: String {
        switch self {
        case .alcohol: return "Alcohol"
        case .opioid: return "Opioid"
        case .stimulant: return "Stimulant"
        case .cannabis: return "Cannabis"
        case .benzodiazepine: return "Benzodiazepine"
        case .hallucinogen: return "Hallucinogen"
        case .inhalant: return "Inhalant"
        case .other: return "Other"
        }
    }
}

enum RouteOfUse: String, CaseIterable, Codable, Hashable {
    case oral = "oral"
    case iv = "IV"
    case smoked = "smoked"
    case nasal = "nasal"
    case transdermal = "transdermal"
    case other = "other"

    var displayName: String {
        switch self {
        case .oral: return "Oral"
        case .iv: return "IV/Injection"
        case .smoked: return "Smoked"
        case .nasal: return "Nasal/Snorted"
        case .transdermal: return "Transdermal/Patch"
        case .other: return "Other"
        }
    }
}
