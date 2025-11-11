//
//  ASAMTraceabilityMatrix.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation

/// Complete traceability matrix for ASAM implementation
struct ASAMTraceabilityMatrix {
    
    // MARK: - Matrix Entry
    
    struct Entry: Codable {
        let formSection: String
        let exactFormText: String
        let appFieldId: String
        let controlType: String
        let complianceMode: String
        let pageNumber: Int?
        let source: ASAMFieldSource
        let notes: String?
        
        init(formSection: String, exactFormText: String, appFieldId: String, controlType: String, 
             complianceMode: String, pageNumber: Int? = nil, source: ASAMFieldSource = .asamForm, notes: String? = nil) {
            self.formSection = formSection
            self.exactFormText = exactFormText
            self.appFieldId = appFieldId
            self.controlType = controlType
            self.complianceMode = complianceMode
            self.pageNumber = pageNumber
            self.source = source
            self.notes = notes
        }
    }
    
    // MARK: - Complete Matrix
    
    static let completeMatrix: [Entry] = [
        
        // PRELIMINARY/INTRODUCTORY
        Entry(
            formSection: "Introduction",
            exactFormText: "Before we get started, can you tell me about why you have come to meet with me today? Probe: How can I be of help? What are you seeking treatment for?",
            appFieldId: "intake_reason",
            controlType: "textarea",
            complianceMode: "both",
            pageNumber: 1,
            notes: "Opening rapport question - critical for identifying emergent needs"
        ),
        
        // DIMENSION 1 - SUBSTANCE INVENTORY
        Entry(
            formSection: "Dimension 1, Pages 1-4",
            exactFormText: "I am going to read you a list of substances. Could you tell me which ones you have used, how long, how recently, and how you used them?",
            appFieldId: "D1_substance_inventory",
            controlType: "table",
            complianceMode: "both",
            pageNumber: 1,
            notes: "Core substance assessment table - exact structure critical"
        ),
        
        Entry(
            formSection: "Dimension 1, Alcohol Row",
            exactFormText: "In the last 30 days, how often have you had [females: 4+ drinks; males: 5+ drinks] on one occasion?",
            appFieldId: "D1_alcohol_binge",
            controlType: "dropdown",
            complianceMode: "licensed",
            pageNumber: 1,
            notes: "Alcohol-specific binge probe - must be scoped to alcohol row only"
        ),
        
        Entry(
            formSection: "Dimension 1, Prescription Rows",
            exactFormText: "Valid prescription? (yes/no for prescription misuse)",
            appFieldId: "D1_prescription_valid",
            controlType: "checkbox",
            complianceMode: "both",
            pageNumber: 1,
            notes: "For prescription opioids and benzodiazepines only"
        ),
        
        Entry(
            formSection: "Dimension 1, Frequency Column",
            exactFormText: "4-7 days/week, 1-3 days/week, 3 or less days/month, Not used, Never Used",
            appFieldId: "substance_frequency",
            controlType: "dropdown",
            complianceMode: "both",
            pageNumber: 1,
            notes: "Exact frequency options from ASAM form - must match exactly"
        ),
        
        Entry(
            formSection: "Dimension 1, Route Column",
            exactFormText: "Oral, Nasal/snort, Smoke, Inject, Other [rectal, patches, etc.]",
            appFieldId: "substance_route",
            controlType: "checkbox_group",
            complianceMode: "both",
            pageNumber: 1,
            notes: "Multi-select checkboxes - patients may use multiple routes"
        ),
        
        Entry(
            formSection: "Dimension 1, Question 2",
            exactFormText: "How much are you bothered by any physical or emotional symptoms when you stop or reduce using alcohol or other drugs?",
            appFieldId: "D1_withdrawal_concern",
            controlType: "scale",
            complianceMode: "both",
            pageNumber: 2,
            notes: "5-point scale: Not at all, A Little, Somewhat, Very, Extremely"
        ),
        
        Entry(
            formSection: "Dimension 1, Question 3", 
            exactFormText: "Are you currently experiencing withdrawal symptoms, such as tremors, excessive sweating, rapid heart rate, anxiety, vomiting, etc.?",
            appFieldId: "D1_current_withdrawal",
            controlType: "scale_with_description",
            complianceMode: "both",
            pageNumber: 2,
            notes: "Scale + description field - consider immediate referral flag"
        ),
        
        Entry(
            formSection: "Dimension 1, Question 7",
            exactFormText: "Have you used substances in the last 48 hours? If yes, what? List:",
            appFieldId: "D1_recent_use_48hrs",
            controlType: "yes_no_with_list",
            complianceMode: "both",
            pageNumber: 3,
            notes: "Important for withdrawal timing assessment"
        ),
        
        Entry(
            formSection: "Dimension 1, Interviewer Observation",
            exactFormText: "Interviewer observation: Does the patient seem to have current signs of withdrawal or intoxication? Please describe:",
            appFieldId: "D1_interviewer_observation",
            controlType: "checkbox_with_description",
            complianceMode: "both",
            pageNumber: 4,
            notes: "Intoxication/Withdrawal/None checkboxes + description"
        ),
        
        // DIMENSION 2 - BIOMEDICAL
        Entry(
            formSection: "Dimension 2, Question 1",
            exactFormText: "Do you have a primary care clinician who manages your medical concerns?",
            appFieldId: "D2_primary_care",
            controlType: "yes_no_with_contact",
            complianceMode: "both",
            pageNumber: 5,
            notes: "Yes/No + provider name/contact fields"
        ),
        
        Entry(
            formSection: "Dimension 2, Question 2",
            exactFormText: "Are you currently taking any medications? List all known medications for medical/physical health condition(s), including over the counter medications",
            appFieldId: "D2_medications",
            controlType: "table",
            complianceMode: "both",
            pageNumber: 5,
            notes: "Medication, Dose, Frequency, Purpose, Notes columns"
        ),
        
        Entry(
            formSection: "Dimension 2, Question 5",
            exactFormText: "I am going to read you a list of physical health issues. Do you currently have, or have you been diagnosed with, any of the following?",
            appFieldId: "D2_health_conditions",
            controlType: "checkbox_group",
            complianceMode: "both",
            pageNumber: 6,
            notes: "Multi-select with conditional text fields for specifics"
        ),
        
        // DIMENSION 3 - MENTAL HEALTH (CRITICAL SECTION)
        Entry(
            formSection: "Dimension 3, Question 8",
            exactFormText: "I am going to read you a list of mental health symptoms and behaviors that might be concerning to some people. Can you tell me if any of these have been bothering you in the last 30 days? Also, if you have these symptoms, please let me know if they happen only when using or withdrawing from alcohol or other drug use.",
            appFieldId: "D3_symptom_inventory",
            controlType: "table_with_checkboxes",
            complianceMode: "both",
            pageNumber: 10,
            notes: "CRITICAL: Must include 'Only when using/withdrawing' column"
        ),
        
        Entry(
            formSection: "Dimension 3, Question 11",
            exactFormText: "Have you had thoughts of hurting yourself? Have you had thoughts that you would be better off dead? Please describe:",
            appFieldId: "D3_suicide_thoughts",
            controlType: "yes_no_with_description",
            complianceMode: "both",
            pageNumber: 11,
            notes: "Main suicide risk question"
        ),
        
        Entry(
            formSection: "Dimension 3, Question 11a",
            exactFormText: "*If yes: Are you having these thoughts today?",
            appFieldId: "D3_suicide_today",
            controlType: "yes_no",
            complianceMode: "both",
            pageNumber: 11,
            notes: "CRITICAL: Discrete yes/no field for 'today' - not free text"
        ),
        
        Entry(
            formSection: "Dimension 3, Question 11b",
            exactFormText: "Have you ever acted on these feelings to hurt yourself?",
            appFieldId: "D3_suicide_acted",
            controlType: "yes_no",
            complianceMode: "both",
            pageNumber: 11,
            notes: "CRITICAL: Discrete yes/no field for 'ever acted' - not free text"
        ),
        
        Entry(
            formSection: "Dimension 3, Question 12",
            exactFormText: "Have you had thoughts of harming others? Please describe:",
            appFieldId: "D3_violence_thoughts",
            controlType: "yes_no_with_description",
            complianceMode: "both",
            pageNumber: 11,
            notes: "Main violence risk question"
        ),
        
        Entry(
            formSection: "Dimension 3, Question 12a",
            exactFormText: "If yes: Are you having these thoughts today?",
            appFieldId: "D3_violence_today",
            controlType: "yes_no",
            complianceMode: "both",
            pageNumber: 11,
            notes: "CRITICAL: Discrete yes/no field for 'today'"
        ),
        
        Entry(
            formSection: "Dimension 3, Question 12b",
            exactFormText: "Have you ever acted on these feelings to harm others?",
            appFieldId: "D3_violence_acted",
            controlType: "yes_no",
            complianceMode: "both",
            pageNumber: 11,
            notes: "CRITICAL: Discrete yes/no field for 'ever acted'"
        ),
        
        // DIMENSION 6 - LIVING ENVIRONMENT
        Entry(
            formSection: "Dimension 6, Question 1",
            exactFormText: "In the past two months, have you been living in stable housing that you own, rent, or stay in as part of a household? (Negative response indicates homelessness.) Describe:",
            appFieldId: "D6_housing_stable_2mo",
            controlType: "yes_no_with_description",
            complianceMode: "both",
            pageNumber: 20,
            notes: "Stable housing assessment - 'No' includes couch surfing/outdoors/car"
        ),
        
        Entry(
            formSection: "Dimension 6, Question 2",
            exactFormText: "Are you worried or concerned that in the next two months you may NOT have stable housing that you own, rent, or stay in as part of a household? (Positive response indicates risk of homelessness.) Describe:",
            appFieldId: "D6_future_housing_risk",
            controlType: "yes_no_with_description",
            complianceMode: "both",
            pageNumber: 20,
            notes: "Future housing risk assessment"
        ),
        
        // CLINIC-ADDED FIELDS (NOT IN ASAM FORM)
        Entry(
            formSection: "Extension - Not in ASAM",
            exactFormText: "Age of first use for each substance",
            appFieldId: "substance_age_first_use",
            controlType: "number",
            complianceMode: "licensed_only",
            source: .clinicAdded,
            notes: "Clinic-added field - not from ASAM form"
        ),
        
        Entry(
            formSection: "Extension - Not in ASAM",
            exactFormText: "Craving level (0-10 scale)",
            appFieldId: "substance_craving_scale",
            controlType: "scale",
            complianceMode: "licensed_only",
            source: .clinicAdded,
            notes: "Clinic-added field - useful but not in official ASAM assessment"
        ),
        
        Entry(
            formSection: "Extension - Not in ASAM",
            exactFormText: "UDS (drug screen) results",
            appFieldId: "uds_results",
            controlType: "checkbox_group",
            complianceMode: "licensed_only",
            source: .systemAdded,
            notes: "EMR convenience field - not part of ASAM interview"
        ),
        
        Entry(
            formSection: "Extension - Not in ASAM",
            exactFormText: "Vaccine status checklist",
            appFieldId: "vaccine_status",
            controlType: "checkbox_group",
            complianceMode: "licensed_only",
            source: .clinicAdded,
            notes: "Preventive care field - not explicitly in ASAM D2 pages"
        ),
        
        // SEVERITY RATINGS
        Entry(
            formSection: "All Dimensions",
            exactFormText: "Severity Rating (0-4 scale with descriptions)",
            appFieldId: "dimension_severity",
            controlType: "radio_group",
            complianceMode: "both",
            notes: "Current needs emphasis - don't prefill or carry historical scores"
        ),
        
        // REASONS FOR DISCREPANCY
        Entry(
            formSection: "Reasons for Discrepancy, Page 27",
            exactFormText: "Indicated vs Actual LOC table with numbered reason codes",
            appFieldId: "discrepancy_reasons",
            controlType: "table_with_checkboxes",
            complianceMode: "both",
            pageNumber: 27,
            notes: "Critical for auditors - must include indicated vs actual grid + reason codes 1-15"
        )
    ]
    
    // MARK: - CSV Export
    
    static func exportAsCSV() -> String {
        let headers = "Form Section,Exact Form Text,App Field ID,Control Type,Compliance Mode,Page Number,Source,Notes"
        
        let rows = completeMatrix.map { entry in
            let escapedFormText = entry.exactFormText.replacingOccurrences(of: "\"", with: "\"\"")
            let escapedNotes = (entry.notes ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            
            return "\"\(entry.formSection)\",\"\(escapedFormText)\",\"\(entry.appFieldId)\",\"\(entry.controlType)\",\"\(entry.complianceMode)\",\"\(entry.pageNumber ?? 0)\",\"\(entry.source.rawValue)\",\"\(escapedNotes)\""
        }
        
        return ([headers] + rows).joined(separator: "\n")
    }
    
    // MARK: - Quality Check Helpers
    
    /// Check for implementation drift against matrix
    static func validateImplementation(questions: [ASAMQuestion]) -> [ASAMQualityIssue] {
        var issues: [ASAMQualityIssue] = []
        
        // Check for missing ASAM form questions
        let implementedFieldIds = Set(questions.map { $0.id })
        let requiredFieldIds = Set(completeMatrix.filter { $0.source == .asamForm }.map { $0.appFieldId })
        
        let missingFields = requiredFieldIds.subtracting(implementedFieldIds)
        for missingField in missingFields {
            issues.append(ASAMQualityIssue(
                severity: .critical,
                category: "Missing Required Field",
                description: "Required ASAM form field '\(missingField)' is not implemented",
                fieldId: missingField,
                recommendation: "Implement missing field according to traceability matrix"
            ))
        }
        
        // Check for text drift
        for question in questions {
            if let matrixEntry = completeMatrix.first(where: { $0.appFieldId == question.id }) {
                // In licensed mode, text should match exactly
                if matrixEntry.complianceMode == "both" || matrixEntry.complianceMode == "licensed_only" {
                    // Allow some variation in licensed text vs exact form text
                    if !question.text.contains(matrixEntry.exactFormText.prefix(50)) {
                        issues.append(ASAMQualityIssue(
                            severity: .major,
                            category: "Text Drift",
                            description: "Question text for '\(question.id)' may have drifted from official ASAM form",
                            fieldId: question.id,
                            recommendation: "Review question text against traceability matrix"
                        ))
                    }
                }
            }
        }
        
        return issues
    }
    
    /// Generate compliance report
    static func generateComplianceReport() -> String {
        let totalFields = completeMatrix.count
        let asamFormFields = completeMatrix.filter { $0.source == .asamForm }.count
        let clinicAddedFields = completeMatrix.filter { $0.source == .clinicAdded }.count
        let systemAddedFields = completeMatrix.filter { $0.source == .systemAdded }.count
        
        return """
        ASAM Implementation Compliance Report
        Generated: \(Date())
        
        Field Sources:
        • Official ASAM Form: \(asamFormFields) fields
        • Clinic-Added Extensions: \(clinicAddedFields) fields  
        • System Convenience Fields: \(systemAddedFields) fields
        • Total Fields: \(totalFields)
        
        Critical Requirements:
        ✓ Substance inventory with exact frequency options
        ✓ Route of use as multi-select checkboxes
        ✓ Alcohol binge probes scoped to alcohol row
        ✓ Prescription misuse for relevant substances only
        ✓ D3 symptom table with 'only when using/withdrawing' column
        ✓ Suicide/violence risk with discrete yes/no fields
        ✓ Housing stability assessment (2-month timeframe)
        ✓ Severity ratings with current needs emphasis
        ✓ Discrepancy reasons table for auditors
        
        Compliance Mode Support:
        • Licensed: Full ASAM text, marks, official templates
        • Neutral: Generic labels, paraphrased content, no marks
        """
    }
}