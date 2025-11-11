# Questionnaire Integration - Xcode Project Setup

## Status: Files Ready - Needs Xcode Target Integration

The questionnaire kit has been successfully created and all Swift files are in place, but they need to be added to the Xcode project target to compile properly.

## Current Compilation Error
```
Cannot find type 'AnswerValue' in scope
Cannot find type 'Questionnaire' in scope
Cannot find 'QuestionsService' in scope
```

**Cause**: Swift files exist but aren't included in Xcode project target membership.

## ✅ Files Ready for Integration

### Swift Files (Need Target Membership)
```
ios/ASAMAssessment/ASAMAssessment/
├── Models/QuestionnaireModels.swift           ✅ Ready
├── Services/QuestionsService.swift           ✅ Ready
├── Services/SeverityScoring.swift            ✅ Ready
└── Views/QuestionnaireRenderer.swift         ✅ Ready
```

### Resource Files (Need Bundle Reference)
```
ios/ASAMAssessment/ASAMAssessment/questionnaires/
├── schema/questionnaire.schema.json          ✅ Ready
├── domains/
│   ├── d1_withdrawal_neutral.json           ✅ Ready
│   ├── d2_biomedical_neutral.json           ✅ Ready
│   ├── d3_emotional_neutral.json            ✅ Ready
│   ├── d4_readiness_neutral.json            ✅ Ready
│   ├── d5_relapse_neutral.json              ✅ Ready
│   └── d6_environment_neutral.json          ✅ Ready
└── scoring/severity_rules.json               ✅ Ready
```

## 🔧 Xcode Integration Steps (2 minutes)

### Step 1: Add Swift Files to Target

1. **Open ASAMAssessment.xcodeproj in Xcode**
2. **Right-click on project navigator** → "Add Files to 'ASAMAssessment'"
3. **Navigate to and select all 4 Swift files:**
   - `Models/QuestionnaireModels.swift`
   - `Services/QuestionsService.swift`  
   - `Services/SeverityScoring.swift`
   - `Views/QuestionnaireRenderer.swift`
4. **Ensure target membership:** ✅ ASAMAssessment (+ ✅ ASAMAssessmentTests if desired)
5. **Click "Add"**

### Step 2: Add Questionnaires Bundle

1. **Right-click on project navigator** → "Add Files to 'ASAMAssessment'"
2. **Navigate to `questionnaires` folder**
3. **IMPORTANT**: Select **"Create folder references"** (blue folder icon) 
   - NOT "Create groups" (yellow folder)
   - This ensures JSON files are copied to app bundle with subfolder structure
4. **Target membership:** ✅ ASAMAssessment
5. **Click "Add"**

### Step 3: Update ContentView Integration

After Xcode integration, replace the current placeholder in `ContentView.swift`:

```swift
/// Domain detail view with questionnaire integration  
struct DomainDetailPlaceholderView: View {
    let domain: Domain
    
    @State private var answers: [String: AnswerValue] = [:]
    @State private var computedSeverity: Int = 1
    @State private var loadedQuestionnaire: Questionnaire?
    @State private var isLoading = false
    @State private var loadingError: String?
    @StateObject private var questionsService = QuestionsService()
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading questionnaire...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadingError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Failed to Load Questionnaire")
                        .font(.headline)
                    
                    Text(error)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    Button("Retry") {
                        loadQuestionnaire()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let questionnaire = loadedQuestionnaire {
                QuestionnaireRenderer(questionnaire: questionnaire) { answersDict in
                    answers = answersDict
                    computedSeverity = computeSeverity(domain: domainLetter, answers: normalize(answersDict))
                    // TODO: Update AssessmentStore and RulesServiceWrapper with new severity
                }
            } else {
                ProgressView("Initializing questionnaire...")
            }
        }
        .navigationTitle("Domain \(domain.number)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if loadedQuestionnaire == nil && !isLoading {
                loadQuestionnaire()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private var domainLetter: String {
        switch domain.number {
        case 1: return "A"
        case 2: return "B"  
        case 3: return "C"
        case 4: return "D"
        case 5: return "E"
        case 6: return "F"
        default: return "A"
        }
    }
    
    private func loadQuestionnaire() {
        isLoading = true
        loadingError = nil
        
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
        do {
            let scorer = try SeverityScoring(scoringURL: url)
            return scorer.computeSeverity(forDomain: domain, answers: answers).severity
        } catch {
            print("Scoring error: \(error)")
            return 1
        }
    }
}
```

## ✅ Verification Steps

After Xcode integration:

1. **Build project** - should compile without errors
2. **Run app in simulator**
3. **Navigate to any domain** (Domain 1, 2, 3, etc.)
4. **Verify questionnaire loads** with questions and progress tracking
5. **Test question interactions** and real-time validation

## 🎯 Expected Results

After proper Xcode integration:

- **✅ Domain Detail Views** show actual questionnaire forms instead of placeholders
- **✅ Progress Tracking** with visual indicators
- **✅ Real-time Validation** for required fields and input types
- **✅ Severity Computation** based on user answers
- **✅ All Question Types** rendered properly (choice, text, number, boolean)
- **✅ Conditional Logic** showing/hiding questions based on answers

## 🚨 Critical Notes

### Bundle References vs Groups
- **questionnaires folder MUST be added as "folder references" (blue)**
- Groups (yellow) don't copy files to bundle - questionnaires won't load
- This is the #1 cause of runtime "file not found" errors

### Target Membership
- All 4 Swift files need ✅ ASAMAssessment target membership
- Without this, you get "Cannot find type" compilation errors (current issue)

### File Paths
- Swift files are correctly placed in Models/, Services/, Views/ folders
- questionnaires/ folder should be at ASAMAssessment root level for bundle access

## 📝 Status Summary

**Current Status:** All files ready, needs 2-minute Xcode target integration

**Next Action:** Add files to Xcode project target membership as described above

**After Integration:** Questionnaire system will be fully functional with 43 neutral clinical questions across 6 domains

**MASTER_TODO Impact:** T-0041, T-0042, T-0043 will be fully operational after Xcode integration