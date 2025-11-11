# Questionnaire Integration Guide

## Quick Integration (60 seconds)

### 1. Add Questionnaires Folder to Xcode

1. **Delete any existing questionnaire references** (yellow folders)
2. **Add Files to "ASAMAssessment"** → select the `questionnaires` folder
3. In the add dialog: **Create folder references** (blue folders)
4. Target membership: **ASAMAssessment** + **ASAMAssessmentTests**

### 2. Add Swift Files to Target

Drag these files into your Xcode project with target membership = **ASAMAssessment**:

- `QuestionnaireModels.swift`
- `QuestionsService.swift` 
- `QuestionnaireRenderer.swift`
- `SeverityScoring.swift`

### 3. Update DomainDetailPlaceholderView

Replace the placeholder implementation with actual questionnaire rendering:

```swift
import SwiftUI

struct DomainDetailView: View {
    let domainLetter: String // "A"..."F"
    @State private var answers: [String: AnswerValue] = [:]
    @State private var severity: Int = 1
    @StateObject private var questionsService = QuestionsService()

    var body: some View {
        VStack {
            if let questionnaire = loadedQuestionnaire {
                QuestionnaireRenderer(questionnaire: questionnaire) { answersDict in
                    answers = answersDict
                    severity = computeSeverity(domain: domainLetter, answers: normalize(answersDict))
                    // TODO: Update AssessmentStore and RulesServiceWrapper
                }
            } else {
                ProgressView("Loading questionnaire...")
                    .onAppear {
                        loadQuestionnaire()
                    }
            }
        }
        .navigationTitle("Domain \(domainLetter)")
        .navigationBarTitleDisplayMode(.large)
    }
    
    @State private var loadedQuestionnaire: Questionnaire?
    @State private var isLoading = false
    @State private var loadingError: String?
    
    private func loadQuestionnaire() {
        isLoading = true
        Task {
            do {
                let questionnaire = try await questionsService.loadQuestionnaire(forDomain: domainLetter)
                await MainActor.run {
                    loadedQuestionnaire = questionnaire
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    loadingError = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    // Convert AnswerValue -> plain Any for scoring
    private func normalize(_ answersDict: [String: AnswerValue]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in answersDict {
            switch value {
            case .text(let s): result[key] = s
            case .number(let d): result[key] = d
            case .bool(let b): result[key] = b
            case .single(let qv):
                switch qv {
                case .bool(let b): result[key] = b
                case .number(let d): result[key] = d 
                case .string(let s): result[key] = s
                }
            case .multi(let set):
                result[key] = set.map { v -> String in
                    switch v {
                    case .bool(let b): return String(b)
                    case .number(let d): return String(d)
                    case .string(let s): return s
                    }
                }
            case .none: break
            }
        }
        return result
    }

    private func computeSeverity(domain: String, answers: [String: Any]) -> Int {
        guard let url = Bundle.main.url(forResource: "severity_rules",
                                        withExtension: "json",
                                        subdirectory: "questionnaires/scoring") else { return 1 }
        if let scorer = try? SeverityScoring(scoringURL: url) {
            return scorer.computeSeverity(forDomain: domain, answers: answers).severity
        }
        return 1
    }
}
```

## Architecture Overview

### Components

1. **QuestionnaireModels.swift**: Core data models for questionnaires, questions, answers, and responses
2. **QuestionsService.swift**: Service for loading and validating questionnaires from JSON files
3. **SeverityScoring.swift**: Scoring engine that computes domain severities based on answers
4. **QuestionnaireRenderer.swift**: SwiftUI view component that renders questions and collects answers

### Data Flow

```
JSON Files → QuestionsService → QuestionnaireRenderer → AnswerValue
                                        ↓
SeverityScoring ← normalized answers ←─────┘
      ↓
DomainSeverity → AssessmentStore → RulesServiceWrapper
```

### File Structure

```
questionnaires/
├── schema/
│   └── questionnaire.schema.json     # JSON schema for validation
├── domains/
│   ├── d1_withdrawal_neutral.json    # Domain A questionnaire
│   ├── d2_biomedical_neutral.json    # Domain B questionnaire
│   ├── d3_emotional_neutral.json     # Domain C questionnaire
│   ├── d4_readiness_neutral.json     # Domain D questionnaire
│   ├── d5_relapse_neutral.json       # Domain E questionnaire
│   └── d6_environment_neutral.json   # Domain F questionnaire
└── scoring/
    └── severity_rules.json           # Scoring rules and thresholds
```

## Features

### Question Types Supported

- **Single Choice**: Radio button selection
- **Multiple Choice**: Checkbox selection  
- **Text Input**: Free text with validation
- **Number Input**: Numeric input with min/max validation
- **Boolean**: Yes/No toggle

### Advanced Features

- **Conditional Visibility**: Questions can be hidden/shown based on answers to other questions
- **Answer Validation**: Type-specific validation with custom rules
- **Breadcrumb Mapping**: Developer hints for field correspondence
- **Progress Tracking**: Visual progress indicator
- **Scoring Integration**: Automatic severity computation

### Validation Rules

- Required field validation
- Text length validation
- Numeric range validation  
- Pattern matching (regex)
- Cross-question dependencies

## Testing

### Validation Test Case

Use `tests/fixtures/qa_case_001.json` to validate scoring:

```swift
func testScoringAccuracy() {
    // Load test fixture
    guard let url = Bundle.main.url(forResource: "qa_case_001", withExtension: "json", subdirectory: "tests/fixtures"),
          let data = try? Data(contentsOf: url),
          let testCase = try? JSONDecoder().decode(TestCase.self, from: data) else {
        XCTFail("Could not load test case")
        return
    }
    
    // Test each domain
    let scorer = try! SeverityScoring()
    for (domain, answers) in testCase.domainAnswers {
        let severity = scorer.computeSeverity(forDomain: domain, answers: answers)
        let expected = testCase.expectedSeverities[domain]!
        
        XCTAssertEqual(severity.severity, expected.severity, "Domain \(domain) severity mismatch")
        XCTAssertTrue(expected.scoreRange[0] <= severity.score && severity.score <= expected.scoreRange[1], 
                     "Domain \(domain) score out of range")
    }
}
```

## Next Steps

1. **T-0044**: Add required-question validation + progress tracking
2. **T-0045**: Persist answers to AssessmentStore with per-domain ownership
3. **T-0046**: Add schema validation in CI for questionnaires  
4. **T-0047**: Localize questionnaires (e.g., es-US) + unit preferences

## Troubleshooting

### Common Issues

1. **"Questionnaire file not found"**: Ensure questionnaires folder added as blue folder references
2. **"Cannot find type 'Questionnaire'"**: Add Swift files to target membership
3. **Scoring returns default values**: Check severity_rules.json is in bundle

### Debug Tips

- Use breadcrumb fields to trace answer flow
- Check console for QuestionsService validation errors
- Verify bundle structure with `Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "questionnaires")`