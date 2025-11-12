//
//  QuestionnaireModels.swift
//  ASAMAssessment
//
//  Created by Agent on 2025-11-11
//  Copyright © 2025 AxxessPhilly. All rights reserved.
//

import Foundation

// MARK: - Core Questionnaire Models

struct Questionnaire: Codable, Identifiable {
    let id: String
    let title: String
    let domain: String
    let version: String
    let description: String?
    let questions: [Question]
}

// MARK: - Substance Assessment Models

struct SubstanceTemplate: Codable {
    let neverUsed: FieldDefinition
    let lastUseDate: FieldDefinition?
    let durationYears: FieldDefinition?
    let durationMonths: FieldDefinition?
    let frequency30Days: FieldDefinition
    let routes: FieldDefinition
    
    enum CodingKeys: String, CodingKey {
        case neverUsed = "never_used"
        case lastUseDate = "last_use_date"
        case durationYears = "duration_years"
        case durationMonths = "duration_months"
        case frequency30Days = "frequency_30_days"
        case routes
    }
}

struct FieldDefinition: Codable {
    let type: String
    let label: String
    let requiredIfUsed: Bool?
    let disablesOtherFields: Bool?
    let validation: Validation?
    let options: [QuestionOption]?
    
    enum CodingKeys: String, CodingKey {
        case type, label, validation, options
        case requiredIfUsed = "required_if_used"
        case disablesOtherFields = "disables_other_fields"
    }
}

struct SubstanceDefinition: Codable, Identifiable {
    let id: String
    let name: String
    let conditionalQuestions: [ConditionalQuestion]?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case conditionalQuestions = "conditional_questions"
    }
}

struct ConditionalQuestion: Codable, Identifiable {
    let id: String
    let text: String
    let type: String
    let visibleIf: ConditionalVisibility?
    let validation: Validation?
    let options: [QuestionOption]?
    
    enum CodingKeys: String, CodingKey {
        case id, text, type, validation, options
        case visibleIf = "visible_if"
    }
}

struct ConditionalVisibility: Codable {
    let globalCondition: String
    let `operator`: String
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case globalCondition = "global_condition"
        case `operator`
        case value
    }
}

struct SubstanceAssessment: Codable, Hashable, Identifiable {
    let id: String
    let substanceId: String
    let neverUsed: Bool
    let lastUseDate: Date?
    let durationYears: Int?
    let durationMonths: Int?
    let frequency30Days: String?
    let routes: Set<String>
    let conditionalAnswers: [String: QuestionValue]
    
    enum CodingKeys: String, CodingKey {
        case id, substanceId, neverUsed, lastUseDate, durationYears, durationMonths, frequency30Days, routes, conditionalAnswers
    }
}

// MARK: - Repeater Field Definition

struct RepeaterField: Codable, Identifiable {
    let id: String
    let label: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case id, label, type
    }
}

// MARK: - Severity Rating Structures

struct SeverityCard: Codable, Identifiable {
    let rating: Int
    let title: String
    let color: String
    let border: String
    let icon: String
    let bullets: [String]
    let disposition: String
    
    var id: Int { rating }
    
    enum CodingKeys: String, CodingKey {
        case rating, title, color, border, icon, bullets, disposition
    }
}

struct SubstanceOption: Codable, Identifiable {
    let id: String
    let label: String
    let type: String  // "checkbox" or "text"
    
    enum CodingKeys: String, CodingKey {
        case id, label, type
    }
}

struct SafetyRule: Codable {
    let condition: String  // e.g., "rating >= 3"
    let banner: String
    let severity: String   // "warning", "critical"
    
    enum CodingKeys: String, CodingKey {
        case condition, banner, severity
    }
}

struct SeverityRatingMetadata: Codable {
    let cards: [SeverityCard]
    let substanceOptions: [SubstanceOption]
    let safetyRules: [SafetyRule]
    let referencePages: [String: String]?  // e.g., ["alcohol": "147-154"]
    
    enum CodingKeys: String, CodingKey {
        case cards = "severity_cards"
        case substanceOptions = "substance_options"
        case safetyRules = "safety_rules"
        case referencePages = "reference_pages"
    }
}

// MARK: - Categorized Health Issues (D2)

struct HealthIssueCategory: Codable, Identifiable {
    let id: String
    let title: String
    let items: [HealthIssueItem]
}

struct HealthIssueItem: Codable, Identifiable {
    let id: String
    let label: String
    let requiresNote: Bool
    let multiSelectOptions: [HealthIssueOption]?
    
    enum CodingKeys: String, CodingKey {
        case id, label
        case requiresNote = "requires_note"
        case multiSelectOptions = "multi_select_options"
    }
}

struct HealthIssueOption: Codable, Identifiable {
    let id: String
    let label: String
    let isOtherOption: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, label
        case isOtherOption = "is_other"
    }
}

struct CategorizedHealthIssuesMetadata: Codable {
    let categories: [HealthIssueCategory]
    let macros: [String]?  // e.g., ["none_of_the_above", "reviewed_unchanged"]
    
    enum CodingKeys: String, CodingKey {
        case categories
        case macros
    }
}

struct Question: Codable, Identifiable {
    let id: String
    let text: String
    let type: QuestionType
    let required: Bool
    let breadcrumb: String?
    let visibleIf: VisibilityCondition?
    let options: [QuestionOption]?
    let validation: Validation?
    let description: String?
    let helpText: String?  // Support both description and helpText
    let repeaterFields: [RepeaterField]?  // For repeater type questions
    let substanceTemplate: SubstanceTemplate?
    let availableSubstances: [SubstanceDefinition]?
    let severityRating: SeverityRatingMetadata?  // For severity_rating type
    let categorizedHealthIssues: CategorizedHealthIssuesMetadata?  // For categorized_health_issues type
    
    // Explicit initializer with default values for new optional parameters
    init(
        id: String,
        text: String,
        type: QuestionType,
        required: Bool,
        breadcrumb: String? = nil,
        visibleIf: VisibilityCondition? = nil,
        options: [QuestionOption]? = nil,
        validation: Validation? = nil,
        description: String? = nil,
        helpText: String? = nil,
        repeaterFields: [RepeaterField]? = nil,
        substanceTemplate: SubstanceTemplate? = nil,
        availableSubstances: [SubstanceDefinition]? = nil,
        severityRating: SeverityRatingMetadata? = nil,
        categorizedHealthIssues: CategorizedHealthIssuesMetadata? = nil
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.required = required
        self.breadcrumb = breadcrumb
        self.visibleIf = visibleIf
        self.options = options
        self.validation = validation
        self.description = description
        self.helpText = helpText
        self.repeaterFields = repeaterFields
        self.substanceTemplate = substanceTemplate
        self.availableSubstances = availableSubstances
        self.severityRating = severityRating
        self.categorizedHealthIssues = categorizedHealthIssues
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, type, required, breadcrumb, options, validation, description
        case helpText = "helpText"
        case visibleIf = "visible_if"
        case repeaterFields = "repeater_fields"
        case substanceTemplate = "substance_template"
        case availableSubstances = "available_substances"
        case severityRating = "severity_rating"
        case categorizedHealthIssues = "categorized_health_issues"
    }
}

enum QuestionType: String, Codable, CaseIterable {
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case text = "text"
    case textarea = "textarea"
    case number = "number"
    case boolean = "boolean"
    case repeater = "repeater"
    case monthYear = "month_year"
    case dynamicSubstanceGrid = "dynamic_substance_grid"
    case severityRating = "severity_rating"  // D1 severity rating cards
    case categorizedHealthIssues = "categorized_health_issues"  // D2 compact searchable health issues
}

struct QuestionOption: Codable, Identifiable {
    let value: QuestionValue
    let label: String
    let score: Double?
    
    var id: String {
        switch value {
        case .string(let str): return str
        case .number(let num): return String(num)
        case .bool(let bool): return String(bool)
        }
    }
}

struct VisibilityCondition: Codable {
    let question: String
    let `operator`: ConditionOperator
    let value: QuestionValue
    
    enum ConditionOperator: String, Codable {
        case equals
        case notEquals = "not_equals"
        case greaterThan = "greater_than"
        case lessThan = "less_than"
        case contains
    }
}

struct Validation: Codable {
    let min: Double?
    let max: Double?
    let pattern: String?
    let minLength: Int?
    let maxLength: Int?
    
    enum CodingKeys: String, CodingKey {
        case min, max, pattern
        case minLength = "min_length"
        case maxLength = "max_length"
    }
}

// MARK: - Answer Models

enum QuestionValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .number(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode QuestionValue"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }
}

enum AnswerValue: Codable, Hashable {
    case text(String)
    case number(Double)
    case bool(Bool)
    case single(QuestionValue)
    case multi(Set<QuestionValue>)
    case substanceGrid([SubstanceAssessment])
    case none
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .none
            return
        }
        
        if let stringValue = try? container.decode(String.self) {
            self = .text(stringValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .number(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let substanceGridValue = try? container.decode([SubstanceAssessment].self) {
            self = .substanceGrid(substanceGridValue)
        } else if let arrayValue = try? container.decode([QuestionValue].self) {
            self = .multi(Set(arrayValue))
        } else if let singleValue = try? container.decode(QuestionValue.self) {
            self = .single(singleValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnswerValue"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .single(let value):
            try container.encode(value)
        case .multi(let values):
            try container.encode(Array(values))
        case .substanceGrid(let assessments):
            try container.encode(assessments)
        case .none:
            try container.encodeNil()
        }
    }
}

// MARK: - Assessment Models

struct QuestionnaireResponse: Codable {
    let questionnaireId: String
    let domain: String
    let responses: [String: AnswerValue]
    let startedAt: Date
    let completedAt: Date?
    let isComplete: Bool
    
    var progress: Double {
        guard !responses.isEmpty else { return 0.0 }
        let answeredCount = responses.values.filter { 
            if case .none = $0 { return false }
            return true
        }.count
        return Double(answeredCount) / Double(responses.count)
    }
}

struct DomainSeverity: Codable {
    let domain: String
    let severity: Int
    let score: Double
    let description: String
    let computedAt: Date
    let overrideReason: String?
}

// MARK: - Validation Extensions

extension Question {
    func isVisible(given answers: [String: AnswerValue]) -> Bool {
        guard let condition = visibleIf else { return true }
        
        guard let answer = answers[condition.question] else { return false }
        
        let answerValue: QuestionValue
        switch answer {
        case .single(let value):
            answerValue = value
        case .text(let text):
            answerValue = .string(text)
        case .number(let num):
            answerValue = .number(num)
        case .bool(let bool):
            answerValue = .bool(bool)
        case .multi, .none, .substanceGrid:
            return false
        }
        
        switch condition.operator {
        case .equals:
            return answerValue == condition.value
        case .notEquals:
            return answerValue != condition.value
        case .greaterThan:
            if case let .number(answerNum) = answerValue,
               case let .number(conditionNum) = condition.value {
                return answerNum > conditionNum
            }
            return false
        case .lessThan:
            if case let .number(answerNum) = answerValue,
               case let .number(conditionNum) = condition.value {
                return answerNum < conditionNum
            }
            return false
        case .contains:
            if case let .string(answerStr) = answerValue,
               case let .string(conditionStr) = condition.value {
                return answerStr.localizedCaseInsensitiveContains(conditionStr)
            }
            return false
        }
    }
    
    func validateAnswer(_ answer: AnswerValue) -> Bool {
        // Check required
        if required {
            switch answer {
            case .none:
                return false
            case .text(let str):
                if str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return false
                }
            case .substanceGrid(let assessments):
                // At least one substance should be assessed if required
                return !assessments.isEmpty
            default:
                break
            }
        }
        
        // Type-specific validation
        guard let validation = validation else { return true }
        
        switch (type, answer) {
        case (.text, .text(let text)):
            if let minLength = validation.minLength, text.count < minLength {
                return false
            }
            if let maxLength = validation.maxLength, text.count > maxLength {
                return false
            }
            if let pattern = validation.pattern {
                let regex = try? NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: text.utf16.count)
                return regex?.firstMatch(in: text, options: [], range: range) != nil
            }
            
        case (.number, .number(let num)):
            if let min = validation.min, num < min {
                return false
            }
            if let max = validation.max, num > max {
                return false
            }
            
        default:
            break
        }
        
        return true
    }
}

extension QuestionnaireResponse {
    func isValid(for questionnaire: Questionnaire) -> Bool {
        // Check all required questions are answered
        let requiredQuestions = questionnaire.questions.filter { $0.required }
        
        for question in requiredQuestions {
            guard question.isVisible(given: responses),
                  let answer = responses[question.id],
                  question.validateAnswer(answer) else {
                return false
            }
        }
        
        return true
    }
    
    func validationErrors(for questionnaire: Questionnaire) -> [String] {
        var errors: [String] = []
        
        for question in questionnaire.questions {
            guard question.isVisible(given: responses) else { continue }
            
            if let answer = responses[question.id] {
                if !question.validateAnswer(answer) {
                    errors.append("Invalid answer for question: \(question.text)")
                }
            } else if question.required {
                errors.append("Missing required answer for: \(question.text)")
            }
        }
        
        return errors
    }
}