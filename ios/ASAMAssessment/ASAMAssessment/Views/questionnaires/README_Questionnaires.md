# ASAM Assessment Questionnaires Kit

## Overview

This kit provides a complete, **drop-in solution** for adding clinical assessment questionnaires to the ASAM iOS app. The kit includes neutral questionnaires for all 6 ASAM domains, scoring engine, Swift scaffolding, and integration documentation.

## What's Included

### 📋 Questionnaires (Neutral & IP-Safe)
- **Domain A**: Acute Intoxication/Withdrawal (7 questions)
- **Domain B**: Biomedical Conditions (7 questions)
- **Domain C**: Emotional/Psychiatric (7 questions) 
- **Domain D**: Readiness to Change (7 questions)
- **Domain E**: Relapse/Continued Use (7 questions)
- **Domain F**: Recovery Environment (8 questions)

### 🏗️ Swift Architecture
- **QuestionnaireModels.swift**: Core data models with Codable support
- **QuestionsService.swift**: JSON loading and validation service  
- **SeverityScoring.swift**: Rule-based scoring engine
- **QuestionnaireRenderer.swift**: SwiftUI view components

### 🎯 Scoring System
- **severity_rules.json**: Configurable scoring thresholds and overrides
- **qa_case_001.json**: Golden test case for validation
- Supports weighted averages, critical questions, and override conditions

### 📚 Documentation
- **QUESTIONNAIRE_INTEGRATION.md**: 60-second integration guide
- **LEGAL_NEUTRALITY_NOTICE.md**: IP-safety and compliance guidance

## Quick Start (60 Seconds)

1. **Add Questionnaires Folder**
   - Add `questionnaires/` as **blue folder references** in Xcode
   - Target: ASAMAssessment

2. **Add Swift Files**  
   - Drag 4 Swift files into project with ASAMAssessment target membership

3. **Update Domain Views**
   ```swift
   // Replace DomainDetailPlaceholderView with:
   QuestionnaireRenderer(questionnaire: questionnaire) { answers in
       // Handle answers and compute severity
   }
   ```

## Features

### 🎨 UI Components
- Adaptive question rendering (choice, text, number, boolean)
- Progress tracking with visual indicators
- Conditional question visibility
- Real-time validation feedback
- Accessibility support

### 🔧 Validation Engine  
- Required field enforcement
- Type-specific validation (regex, ranges)
- Cross-question dependencies  
- Error messaging and user guidance

### 📊 Scoring Engine
- Domain-specific severity computation (1-4 scale)
- Weighted question importance
- Override conditions for critical responses
- Configurable thresholds and rules

### 🗂️ Data Management
- JSON-based questionnaire definitions
- Structured answer collection
- Progress persistence
- Response validation

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ JSON Files      │────│ QuestionsService│────│QuestionnaireView│
│ (questionnaires)│    │ (loading)       │    │ (rendering)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ SeverityScoring │────│ Answer Analysis │────│ User Answers    │
│ (computation)   │    │ (normalization) │    │ (AnswerValue)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## File Structure

```
questionnaires/
├── schema/
│   └── questionnaire.schema.json          # JSON Schema validation
├── domains/
│   ├── d1_withdrawal_neutral.json         # Domain A (Withdrawal)
│   ├── d2_biomedical_neutral.json         # Domain B (Biomedical)
│   ├── d3_emotional_neutral.json          # Domain C (Emotional)
│   ├── d4_readiness_neutral.json          # Domain D (Readiness)
│   ├── d5_relapse_neutral.json            # Domain E (Relapse)
│   └── d6_environment_neutral.json        # Domain F (Environment)
└── scoring/
    └── severity_rules.json                # Scoring configuration

ios/
├── Models/
│   └── QuestionnaireModels.swift          # Data models
├── Services/
│   ├── QuestionsService.swift             # JSON loading
│   └── SeverityScoring.swift              # Score computation
└── Views/
    └── QuestionnaireRenderer.swift        # UI components

tests/fixtures/
└── qa_case_001.json                       # Test validation case

docs/
├── QUESTIONNAIRE_INTEGRATION.md           # Integration guide
└── LEGAL_NEUTRALITY_NOTICE.md             # IP compliance
```

## Question Types Supported

| Type | Description | Validation |
|------|-------------|------------|
| `single_choice` | Radio button selection | Required options |
| `multiple_choice` | Checkbox selection | Multi-select |
| `text` | Free text input | Length, pattern |
| `number` | Numeric input | Min/max range |
| `boolean` | Yes/No toggle | Simple validation |

## Scoring Algorithm

1. **Load Domain Rules**: Read scoring configuration for domain
2. **Check Overrides**: Apply critical condition overrides first  
3. **Weighted Average**: Compute score using critical + standard questions
4. **Threshold Mapping**: Map score to severity level (1-4)
5. **Result Assembly**: Create DomainSeverity with metadata

## Integration Status

### ✅ Complete (Ready to Use)
- **T-0041**: Domain A–F questionnaire JSON (neutral) 
- **T-0042**: QuestionnaireRenderer and domain detail integration
- **T-0043**: SeverityScoring wired to domain severities

### 🔄 Next Steps (MASTER_TODO Updated)
- **T-0044**: Required-question validation + progress tracking
- **T-0045**: Persist answers to AssessmentStore  
- **T-0046**: Add schema validation in CI
- **T-0047**: Localize questionnaires (es-US) + unit preferences

## Testing

### Manual Testing
1. Build and run app in simulator
2. Navigate to any domain detail view
3. Complete questionnaire and verify scoring
4. Check console for validation errors

### Automated Testing  
```swift
func testQuestionnaireScoringAccuracy() {
    let scorer = try! SeverityScoring()
    let answers = ["a01": "moderate", "a02": "drowsy", "a03": "mild"]
    let severity = scorer.computeSeverity(forDomain: "A", answers: answers)
    XCTAssertEqual(severity.severity, 2) // Expected: moderate severity
}
```

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| "Questionnaire file not found" | Add questionnaires folder as **blue references** |
| "Cannot find type 'Questionnaire'" | Add Swift files to ASAMAssessment target |
| Scoring returns default (2) | Check severity_rules.json in app bundle |
| Questions don't render | Verify JSON format against schema |

### Debug Commands

```swift
// Check bundle resources
print(Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "questionnaires"))

// Validate questionnaire loading
let service = QuestionsService()
do {
    let questionnaire = try service.loadQuestionnaire(forDomain: "A")
    print("✅ Domain A loaded: \(questionnaire.questions.count) questions")
} catch {
    print("❌ Failed to load: \(error)")
}
```

## License & Compliance

⚠️ **Important**: This kit provides neutral clinical assessment questions that are IP-safe for development and testing. For production deployment with ASAM branding or terminology, obtain appropriate ASAM licensing.

See `LEGAL_NEUTRALITY_NOTICE.md` for complete compliance guidance.

---

**Version**: 1.0.0  
**Created**: 2025-11-11  
**Updated**: 2025-11-11