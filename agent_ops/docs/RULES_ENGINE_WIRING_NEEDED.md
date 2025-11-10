# Rules Engine Integration Status

**Date:** 2025-11-09  
**Issue:** App builds but RulesEngine not being used

## 🔍 **Current Situation**

### ✅ What's Working
- App builds successfully
- Swift files (RulesEngine.swift, RulesService.swift) added to Xcode target
- JSON files (rules/*.json) bundled with app
- Safety Review dialog works (T-0002)
- Assessment creation works

### ❌ What's NOT Working
**RulesService is not wired up!** The app is still using the old `LOCService` with hardcoded logic.

Current setup in `ASAMAssessmentApp.swift`:
```swift
@StateObject private var locService = LOCService()  // ❌ OLD
```

Should be:
```swift
@StateObject private var rulesService = RulesService()  // ✅ NEW
```

## 🎯 **What Needs to Happen**

### Step 1: Add Helper Methods to Assessment Model

The Assessment model needs methods to convert its data for the rules engine:

**File:** `ios/ASAMAssessment/ASAMAssessment/Models/Assessment.swift`

Add these methods:
```swift
extension Assessment {
    /// Convert domains array to dictionary for rules engine
    func domainSeverities() -> [String: Int] {
        var result: [String: Int] = [:]
        for domain in domains {
            result["d\(domain.number)"] = domain.severity
        }
        return result
    }
    
    /// Extract Domain 1 context for substance-specific rules
    func d1Context() -> [String: Any] {
        // TODO: Extract from Domain 1 notes or structured fields
        // For now, return empty - needs UI implementation
        return [:]
    }
    
    /// Convert assessment flags to dictionary
    func flags() -> [String: Bool] {
        // TODO: Add flag tracking to Assessment model
        // Examples: pregnant, vital_instability, acute_psych
        return [:]
    }
}
```

### Step 2: Create RulesService Wrapper

The current `RulesService` throws errors in init, but SwiftUI `@StateObject` can't handle throwing initializers.

**Create:** `ios/ASAMAssessment/ASAMAssessment/Services/RulesServiceWrapper.swift`

```swift
import Foundation
import SwiftUI

/// Wrapper for RulesService to handle initialization errors in SwiftUI
class RulesServiceWrapper: ObservableObject {
    private var rulesService: RulesService?
    @Published var isAvailable: Bool = false
    @Published var errorMessage: String?
    
    init() {
        do {
            self.rulesService = try RulesService()
            self.isAvailable = true
        } catch {
            self.isAvailable = false
            self.errorMessage = "Failed to load rules: \(error.localizedDescription)"
            print("❌ RulesService initialization failed: \(error)")
        }
    }
    
    /// Evaluate WM and LOC for an assessment
    func evaluate(assessment: Assessment) -> (wm: String, loc: String)? {
        guard let service = rulesService else {
            return nil
        }
        
        let severities = assessment.domainSeverities()
        let d1Context = assessment.d1Context()
        let flags = assessment.flags()
        
        let result = service.evaluate(
            severities: severities,
            d1Context: d1Context,
            flags: flags
        )
        
        return (wm: result.wm.indication, loc: result.loc.recommendation)
    }
    
    /// Convert old LOCService format for backward compatibility
    func calculateLOC(for assessment: Assessment) -> LOCRecommendation {
        guard let result = evaluate(assessment: assessment) else {
            // Fallback to safe default if rules engine unavailable
            return LOCRecommendation(
                level: "0.5",
                description: "Early Intervention",
                confidence: "low",
                reasoning: ["Rules engine unavailable", "Using fallback recommendation"]
            )
        }
        
        // Map rules engine output to LOCRecommendation format
        return LOCRecommendation(
            level: result.loc,
            description: locDescription(for: result.loc),
            confidence: "high",
            reasoning: ["Based on rules engine evaluation", "WM: \(result.wm)"]
        )
    }
    
    private func locDescription(for level: String) -> String {
        switch level {
        case "0.5": return "Early Intervention"
        case "1.0": return "Outpatient Services"
        case "2.1": return "Intensive Outpatient"
        case "2.5": return "Partial Hospitalization"
        case "3.1": return "Clinically Managed Low-Intensity Residential"
        case "3.3": return "Clinically Managed Population-Specific High-Intensity Residential"
        case "3.5": return "Clinically Managed High-Intensity Residential"
        case "3.7": return "Medically Monitored Intensive Inpatient"
        case "4.0": return "Medically Managed Intensive Inpatient"
        default: return "Assessment Required"
        }
    }
}
```

### Step 3: Wire Up in App

**File:** `ios/ASAMAssessment/ASAMAssessment/ASAMAssessmentApp.swift`

Replace LOCService with RulesServiceWrapper:

```swift
@main
struct ASAMAssessmentApp: App {
    @StateObject private var assessmentStore = AssessmentStore()
    @StateObject private var auditService = AuditService()
    @StateObject private var rulesService = RulesServiceWrapper()  // ✅ NEW
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(assessmentStore)
                .environmentObject(auditService)
                .environmentObject(rulesService)  // ✅ NEW
                .onAppear {
                    auditService.logEvent(.appLaunched, actor: "system", notes: "App started")
                    
                    // Log rules engine status
                    if rulesService.isAvailable {
                        print("✅ Rules engine loaded successfully")
                    } else if let error = rulesService.errorMessage {
                        print("❌ Rules engine error: \(error)")
                    }
                }
        }
    }
}
```

### Step 4: Update ContentView

**File:** `ios/ASAMAssessment/ASAMAssessment/Views/ContentView.swift`

Change the environment object:

```swift
@EnvironmentObject private var rulesService: RulesServiceWrapper  // Change from LOCService
```

The `generateLOCRecommendation` method should work as-is since `RulesServiceWrapper` has the same `calculateLOC` method signature.

## 🚀 **Quick Integration Steps**

1. **Add helper methods to Assessment.swift** (Step 1 above)
2. **Create RulesServiceWrapper.swift** (Step 2 above - new file)
3. **Update ASAMAssessmentApp.swift** (Step 3 above)
4. **Update ContentView.swift** (Step 4 above - one line change)
5. **Build and run** (Cmd+R)

## 🧪 **Testing**

After wiring up:

1. Create a new assessment
2. Set some domain severities (e.g., D1 = 3, D3 = 2)
3. Navigate to generate LOC recommendation
4. Check Xcode console for:
   - ✅ "Rules engine loaded successfully"
   - Rule evaluation logs from RulesEngine.swift
   - LOC recommendation output

## ⚠️ **Important Notes**

- **d1Context() and flags()** are currently returning empty dictionaries
  - Rules requiring substance data or flags won't fire
  - This is fine for initial testing
  - Will need UI implementation for full functionality

- **RulesServiceWrapper** provides graceful fallback
  - If rules files not found, app won't crash
  - Shows error message in console
  - Returns safe default recommendation

- **Backward compatible**
  - Same `calculateLOC(for:)` API as LOCService
  - Minimal changes to existing views
  - Easy to revert if needed

## 📊 **Next Steps After Wiring**

Once rules engine is working:

1. **Add substance tracking** to Domain 1 (for d1Context)
2. **Add flag fields** to Assessment model (pregnant, vitals, etc.)
3. **Create XCTests** with the 12 test fixtures
4. **Verify against golden outputs** from test cases
5. **Implement Problems Module** (T-0003 onwards)

---

**Status:** 🔴 **BLOCKED** - Rules engine code ready but not wired to app  
**Priority:** 🔥 **HIGH** - This is the critical integration step  
**Effort:** ⏱️ **20 minutes** - Follow 4 steps above
