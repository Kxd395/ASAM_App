//
//  SeverityContent.swift
//  ASAMAssessment
//
//  Domain 2 Severity Rating Content
//  Clinical criteria and disposition guidance
//

import Foundation
import SwiftUI

/// Severity rating option with clinical criteria
struct SeverityOption: Identifiable, Hashable {
    let id = UUID()
    let value: Int
    let title: String
    let bullets: [String]
    let disposition: String
    let tone: SeverityTone
    let emergencyList: [String]?

    init(value: Int, title: String, bullets: [String], disposition: String, tone: SeverityTone, emergencyList: [String]? = nil) {
        self.value = value
        self.title = title
        self.bullets = bullets
        self.disposition = disposition
        self.tone = tone
        self.emergencyList = emergencyList
    }
}

/// Color tone for severity levels
enum SeverityTone {
    case green
    case amber
    case orange
    case red

    var color: Color {
        switch self {
        case .green: return .green
        case .amber: return .yellow
        case .orange: return .orange
        case .red: return .red
        }
    }

    var hexColor: String {
        switch self {
        case .green: return "#10B981"
        case .amber: return "#F59E0B"
        case .orange: return "#F97316"
        case .red: return "#EF4444"
        }
    }
}

/// Domain 2 Severity Rating Content
struct D2SeverityContent {
    static let options: [SeverityOption] = [
        SeverityOption(
            value: 0,
            title: "0 None",
            bullets: [
                "Fully functional/no significant pain or discomfort"
            ],
            disposition: "Regular follow up, low intensity services for controlled conditions",
            tone: .green
        ),
        SeverityOption(
            value: 1,
            title: "1 Mild",
            bullets: [
                "Mild symptoms interfering minimally with daily functioning",
                "Able to cope with physical discomfort"
            ],
            disposition: "Regular follow up, low intensity services for controlled conditions",
            tone: .green
        ),
        SeverityOption(
            value: 2,
            title: "2 Moderate",
            bullets: [
                "Acute or chronic biomedical problems are non-life-threatening but are neglected and need new or different treatment",
                "Health issues moderately impacting ADLs and independent living",
                "Sufficient support to manage medical problems at home with medical intervention"
            ],
            disposition: "Priority follow up and evaluation for new/uncontrolled conditions",
            tone: .amber
        ),
        SeverityOption(
            value: 3,
            title: "3 Severe",
            bullets: [
                "Poorly controlled medical problems requiring evaluation",
                "Poor ability to cope with medical problems",
                "Insufficient support to manage medical problems independently",
                "Difficulty with ADLs and/or independent living"
            ],
            disposition: "Need for evaluation and treatment, including medical monitoring in conjunction with 24-hour nursing to ensure stabilization",
            tone: .orange
        ),
        SeverityOption(
            value: 4,
            title: "4 Very Severe",
            bullets: [
                "Unstable condition with severe medical problems, including but not limited to:",
                "• Emergent chest pain",
                "• Delirium tremens (DTs)",
                "• Unstable pregnancy",
                "• Vomiting bright red blood",
                "• Withdrawal seizure in the past 24 hours",
                "• Recurrent seizures"
            ],
            disposition: "Need for evaluation and treatment, including medical monitoring in conjunction with 24-hour nursing to ensure stabilization",
            tone: .red,
            emergencyList: [
                "Emergent chest pain",
                "Delirium tremens",
                "Unstable pregnancy",
                "Vomiting bright red blood",
                "Withdrawal seizure in past 24 hours",
                "Recurrent seizures"
            ]
        )
    ]
}
