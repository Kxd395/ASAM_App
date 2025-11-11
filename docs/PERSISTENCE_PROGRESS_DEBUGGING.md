# Persistence and Progress Bar Debugging Guide

**Created**: November 11, 2025  
**Status**: Implementation & Testing Guide  
**Priority**: P0 - Critical User Experience Issues

---

## Overview

This document provides a comprehensive plan for debugging and fixing two critical issues:

1. **Progress Bar Not Updating When Fields Are Removed**
2. **Persistence Not Working Correctly**

---

## Issue 1: Progress Bar Update Problem

### Problem Description

The progress bar does not update correctly when form fields are removed from an assessment. Progress only increases when fields are added, but does not decrease when fields are removed.

### Root Cause Analysis

The issue stems from three potential problems:

1. **Progress calculation doesn't account for field removal**
2. **UI doesn't reactively update when answer count changes**
3. **Domain completion status not recalculated on field removal**

### Solution Implementation

#### Step 1: Enhanced Progress Calculation

Created `/ios/ASAMAssessment/ASAMAssessment/Services/ProgressTrackingFix.swift` with:

```swift
extension Domain {
    func calculateProgress() -> Double {
        // Count only non-empty, valid answers
        let validAnswers = answers.filter { _, value in
            switch value {
            case .none: return false
            case .text(let str): return !str.isEmpty
            // ... other types
            }
        }
        return Double(validAnswers.count) / Double(max(answers.count, 1))
    }
}
```

**Key Features**:
- Filters out `.none` answers
- Handles empty text fields
- Returns 0.0 for empty domains
- Provides debug logging

#### Step 2: Update ContentView Answer Removal Logic

Modify `DomainDetailView.saveDomainAnswers()` in ContentView.swift:

```swift
private func saveDomainAnswers(_ newAnswers: [String: AnswerValue]) {
    guard let currentAssessment = assessmentStore.currentAssessment else { return }
    
    var updatedAssessment = currentAssessment
    
    if let domainIndex = updatedAssessment.domains.firstIndex(where: { $0.id == domain.id }) {
        // Store old count for logging
        let oldCount = updatedAssessment.domains[domainIndex].answers.count
        
        // Update answers - this handles both additions AND removals
        updatedAssessment.domains[domainIndex].answers = newAnswers
        
        let newCount = newAnswers.count
        print("📊 Answer count changed: \(oldCount) → \(newCount) (Δ \(newCount - oldCount))")
        
        // Recalculate completion status
        let requiredQuestions = questionnaire?.questions.filter { $0.required } ?? []
        let answeredRequired = requiredQuestions.filter { question in
            if let answer = newAnswers[question.id], case .none = answer {
                return false
            }
            return newAnswers[question.id] != nil
        }
        
        updatedAssessment.domains[domainIndex].isComplete = 
            (answeredRequired.count == requiredQuestions.count)
        
        // Force UI update by saving to store
        assessmentStore.updateAssessment(updatedAssessment)
        
        // Log progress change
        let progress = updatedAssessment.domains[domainIndex].calculateProgress()
        print("✅ Progress updated: \(String(format: "%.0f%%", progress * 100))")
    }
}
```

#### Step 3: Add Visual Progress Component

Use the new `AssessmentProgressView` component in your assessment overview:

```swift
struct AssessmentOverviewView: View {
    let assessment: Assessment
    @EnvironmentObject private var assessmentStore: AssessmentStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add progress tracking component
                AssessmentProgressView(assessment: assessment)
                
                // ... rest of your overview UI
            }
        }
    }
}
```

#### Step 4: Debug Visualization

Add the `ProgressDebugView` for development/testing:

```swift
#if DEBUG
ProgressDebugView(assessment: assessment)
#endif
```

This shows:
- Assessment ID
- Per-domain answer counts
- Completion status
- Severity levels
- Progress percentages
- Answer keys

###Verification Steps

1. **Test Field Addition**:
   ```
   - Open domain
   - Answer 3 questions → Progress should increase
   - Check debug view shows 3 answers
   ```

2. **Test Field Removal**:
   ```
   - Remove 1 answer (clear/delete)
   - Progress should decrease
   - Check debug view shows 2 answers
   - Completion status should update if required question removed
   ```

3. **Test Complete Flow**:
   ```
   - Answer all required questions → Domain complete
   - Remove 1 required answer → Domain incomplete
   - Progress bar should reflect both changes
   ```

---

## Issue 2: Persistence Not Working

### Problem Description

Assessment data, including answers and progress, is not persisting correctly when navigating between views or after app restart.

### Root Cause Analysis

Potential issues identified in `AssessmentStore.swift`:

1. **UserDefaults not synchronizing**
2. **JSON encoding failures (silent)**
3. **currentAssessment not persisting across app launches**
4. **Race conditions during rapid updates**
5. **Domain answers not being included in persistence**

### Debugging Implementation

#### Step 1: Enhanced Logging

Add comprehensive logging to `AssessmentStore.swift`:

```swift
private func persistAssessments() {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // For debugging
        
        let data = try encoder.encode(assessments)
        let dataSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        
        print("💾 Persisting \(assessments.count) assessments (\(dataSize))")
        print("💾 Current assessment: \(currentAssessment?.id.uuidString.prefix(8) ?? "none")")
        
        // Log domain answers for current assessment
        if let current = currentAssessment {
            for domain in current.domains {
                print("💾   Domain \(domain.number): \(domain.answers.count) answers, complete: \(domain.isComplete)")
            }
        }
        
        UserDefaults.standard.set(data, forKey: assessmentsKey)
        UserDefaults.standard.synchronize()
        
        print("✅ Persistence complete")
        
    } catch {
        print("❌ PERSISTENCE FAILED: \(error)")
        print("❌ Error details: \(error.localizedDescription)")
        if let encodingError = error as? EncodingError {
            print("❌ Encoding error: \(encodingError)")
        }
    }
}
```

#### Step 2: Verification on Load

Add verification to `loadPersistedAssessments()`:

```swift
private func loadPersistedAssessments() {
    guard let data = UserDefaults.standard.data(forKey: assessmentsKey) else {
        print("📂 No persisted data found (first launch?)")
        return
    }
    
    let dataSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    print("📂 Loading persisted data (\(dataSize))")
    
    do {
        let decoder = JSONDecoder()
        assessments = try decoder.decode([Assessment].self, from: data)
        
        print("✅ Loaded \(assessments.count) assessments")
        
        // Verify data integrity
        for assessment in assessments {
            let answerCounts = assessment.domains.map { $0.answers.count }
            let totalAnswers = answerCounts.reduce(0, +)
            print("📂   Assessment \(assessment.id.uuidString.prefix(8)): \(totalAnswers) total answers across \(assessment.domains.count) domains")
        }
        
    } catch {
        print("❌ FAILED TO LOAD: \(error)")
        print("❌ Data may be corrupted - resetting to empty")
        assessments = []
        
        // Archive corrupted data for forensics
        UserDefaults.standard.set(data, forKey: "corrupted_backup_\(Date().timeIntervalSince1970)")
    }
}
```

#### Step 3: Add Manual Persistence Tests

Create test methods in AssessmentStore:

```swift
#if DEBUG
/// Test method: Verify persistence round-trip
func testPersistence() -> Bool {
    let testAssessment = createAssessment()
    var updated = testAssessment
    updated.domains[0].answers = ["test_key": .text("test_value")]
    updateAssessment(updated)
    
    // Force save
    persistAssessments()
    
    // Create new store to test load
    let newStore = AssessmentStore()
    
    guard let loaded = newStore.assessments.first(where: { $0.id == testAssessment.id }) else {
        print("❌ Test persistence failed: Assessment not found")
        return false
    }
    
    guard loaded.domains[0].answers["test_key"] != nil else {
        print("❌ Test persistence failed: Answer not found")
        return false
    }
    
    print("✅ Persistence test passed")
    return true
}

/// Test method: Verify UserDefaults is writable
func testUserDefaultsWritable() -> Bool {
    let testKey = "persistence_test_\(UUID().uuidString)"
    let testValue = "test_value"
    
    UserDefaults.standard.set(testValue, forKey: testKey)
    UserDefaults.standard.synchronize()
    
    guard let read = UserDefaults.standard.string(forKey: testKey) else {
        print("❌ UserDefaults not writable")
        return false
    }
    
    UserDefaults.standard.removeObject(forKey: testKey)
    
    guard read == testValue else {
        print("❌ UserDefaults value mismatch")
        return false
    }
    
    print("✅ UserDefaults writable test passed")
    return true
}
#endif
```

### Testing Protocol

#### Unit Tests (PersistenceTests.swift)

Created comprehensive test suite with:

1. **Basic Persistence** Tests:
   - `testAssessmentCreationPersists()` - New assessments save
   - `testDomainAnswersPersist()` - Answers survive reload
   - `testCurrentAssessmentPersists()` - Current selection persists
   - `testMultipleAssessmentsPersist()` - Multiple assessments work

2. **Edge Case** Tests:
   - `testEmptyStorePersistence()` - Handles no data
   - `testAssessmentUpdatePersists()` - Updates save correctly
   - `testDomainCompletionPersists()` - Completion status saves
   - `testAssessmentDeletionPersists()` - Deletions work

3. **Data Integrity** Tests:
   - `testAnswerTypesPersist()` - All answer types encode/decode
   - `testSubstanceDataPersists()` - Complex data structures work
   - `testProgressDataPersists()` - Progress state accurate

4. **Performance** Tests:
   - `testLargeDataSetPersistence()` - 600+ answers across 6 domains
   - Verify save time < 1 second
   - Verify load time < 1 second

#### Manual Testing Steps

1. **Fresh Install Test**:
   ```
   1. Delete app from simulator
   2. Build and run
   3. Create new assessment
   4. Add answers to Domain 1
   5. Force quit app (Cmd+Shift+H + swipe up)
   6. Relaunch app
   7. Verify: Assessment exists with all answers
   ```

2. **Navigation Test**:
   ```
   1. Create assessment
   2. Navigate to Domain 1, add 3 answers
   3. Navigate to Domain 2, add 2 answers
   4. Return to Domain 1
   5. Verify: 3 answers still present
   6. Navigate to overview
   7. Verify: Progress shows correctly
   ```

3. **Answer Removal Test**:
   ```
   1. Create assessment with 5 answers in Domain 1
   2. Note progress percentage
   3. Remove 2 answers (clear/delete)
   4. Verify: Progress decreases
   5. Navigate away and back
   6. Verify: Only 3 answers remain
   ```

4. **Multiple Assessments Test**:
   ```
   1. Create Assessment A, add data
   2. Create Assessment B, add data
   3. Switch between A and B multiple times
   4. Verify: Each maintains its own data
   5. Force quit and relaunch
   6. Verify: Both assessments intact
   ```

#### Debugging Commands

Add these to your debug console during testing:

```swift
// Check UserDefaults directly
if let data = UserDefaults.standard.data(forKey: "stored_assessments") {
    print("Stored data size: \(data.count) bytes")
    if let assessments = try? JSONDecoder().decode([Assessment].self, from: data) {
        print("Decoded \(assessments.count) assessments")
    }
}

// Inspect current assessment
if let current = assessmentStore.currentAssessment {
    print("Current assessment: \(current.id)")
    print("Domains with answers: \(current.domains.filter { !$0.answers.isEmpty }.count)")
    for domain in current.domains where !domain.answers.isEmpty {
        print("  Domain \(domain.number): \(domain.answers.count) answers")
    }
}

// Force synchronize
UserDefaults.standard.synchronize()
```

---

## Common Issues and Solutions

### Issue: "JSON encoding failed"

**Symptoms**: Persistence logs show encoding errors

**Causes**:
- Non-codable property in model
- Circular references
- Invalid data types

**Solution**:
1. Check all properties in `Assessment`, `Domain`, `AnswerValue` are `Codable`
2. Add custom encoding if needed:
   ```swift
   enum CodingKeys: String, CodingKey {
       case id, createdAt, domains
       // Exclude non-codable properties
   }
   ```

### Issue: "Data loads but answers missing"

**Symptoms**: Assessment exists but answers are empty

**Causes**:
- Answers not included in `Codable` implementation
- updateAssessment() called before answers set
- Race condition in UI updates

**Solution**:
1. Verify `Domain.answers` is in `CodingKeys`
2. Ensure `persistAssessments()` called AFTER answers updated
3. Add delay if needed:
   ```swift
   DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
       self.assessmentStore.updateAssessment(updatedAssessment)
   }
   ```

### Issue: "Progress bar doesn't update"

**Symptoms**: Progress stuck at old value

**Causes**:
- View not observing `@Published` properties
- Progress calculation cached
- UI not redrawing

**Solution**:
1. Ensure view has `@EnvironmentObject var assessmentStore: AssessmentStore`
2. Force recalculation:
   ```swift
   assessmentStore.objectWillChange.send()
   ```
3. Use `@State` for local progress tracking with explicit updates

### Issue: "Current assessment not restored"

**Symptoms**: App launches with no selected assessment

**Causes**:
- `currentAssessmentKey` not saved
- Assessment ID doesn't match any loaded assessment
- Timing issue in initialization

**Solution**:
1. Verify `saveCurrentAssessmentId()` called in `currentAssessment.didSet`
2. Check ID exists in loaded assessments:
   ```swift
   if let id = UUID(uuidString: idString),
      let found = assessments.first(where: { $0.id == id }) {
       currentAssessment = found
   }
   ```
3. Log restoration process for debugging

---

## Performance Considerations

### UserDefaults Limits

- Maximum practical size: ~4 MB
- Recommended max: 1 MB
- Single assessment with 100 answers per domain (600 total): ~50-100 KB

### Optimization Strategies

1. **Defer Persistence**:
   ```swift
   private var saveTimer: Timer?
   
   func debouncedPersist() {
       saveTimer?.invalidate()
       saveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
           self?.persistAssessments()
       }
   }
   ```

2. **Background Persistence**:
   ```swift
   DispatchQueue.global(qos: .utility).async {
       let data = try? JSONEncoder().encode(self.assessments)
       DispatchQueue.main.async {
           UserDefaults.standard.set(data, forKey: self.assessmentsKey)
       }
   }
   ```

3. **Compression** (for large datasets):
   ```swift
   if let compressed = try? (data as NSData).compressed(using: .lzfse) as Data {
       UserDefaults.standard.set(compressed, forKey: assessmentsKey)
   }
   ```

---

## Next Steps

### Immediate Actions (P0)

1. ✅ **Created**: `ProgressTrackingFix.swift` with enhanced progress calculation
2. ✅ **Created**: `PersistenceTests.swift` with comprehensive test suite
3. ⏳ **TODO**: Add progress tracking to ContentView
4. ⏳ **TODO**: Enhance AssessmentStore logging
5. ⏳ **TODO**: Run unit tests and verify all pass

### Development Actions (P1)

1. ⏳ **TODO**: Integrate `AssessmentProgressView` into UI
2. ⏳ **TODO**: Add `ProgressDebugView` for development builds
3. ⏳ **TODO**: Add persistence debugging to Settings screen
4. ⏳ **TODO**: Create UI tests for progress updates
5. ⏳ **TODO**: Add analytics for persistence failures

### Documentation Actions (P2)

1. ⏳ **TODO**: Update user documentation with progress features
2. ⏳ **TODO**: Create troubleshooting guide for users
3. ⏳ **TODO**: Document data migration strategy for future versions

---

## Files Created/Modified

### New Files

1. `/ios/ASAMAssessment/ASAMAssessment/Services/ProgressTrackingFix.swift`
   - Progress calculation extensions
   - AssessmentProgressView component
   - DomainProgressRow component
   - ProgressDebugView for development

2. `/ios/ASAMAssessment/ASAMAssessmentTests/PersistenceTests.swift`
   - 15 comprehensive unit tests
   - Edge case coverage
   - Performance benchmarks

3. `/docs/PERSISTENCE_PROGRESS_DEBUGGING.md` (this file)
   - Complete debugging guide
   - Testing protocols
   - Troubleshooting reference

### Files to Modify

1. `/ios/ASAMAssessment/ASAMAssessment/Views/ContentView.swift`
   - Update `saveDomainAnswers()` with progress logging
   - Add progress calculation on answer removal
   - Integrate `AssessmentProgressView`

2. `/ios/ASAMAssessment/ASAMAssessment/Services/AssessmentStore.swift`
   - Enhanced logging in `persistAssessments()`
   - Verification in `loadPersistedAssessments()`
   - Add debug test methods

3. `/ios/ASAMAssessment/ASAMAssessment/Models/Assessment.swift`
   - Add `calculateOverallProgress()` method
   - Add `completionPercentage` computed property

---

## Testing Checklist

### Pre-Flight Checks

- [ ] All files compile without errors
- [ ] No force-unwrapping in persistence code
- [ ] All `Codable` conformances complete
- [ ] Debug logging in place

### Unit Test Suite

- [ ] All 15 persistence tests pass
- [ ] No test timeouts or hangs
- [ ] Performance tests under 1 second each
- [ ] No memory leaks detected

### Manual Testing

- [ ] Fresh install test passes
- [ ] Navigation test passes
- [ ] Answer removal test passes
- [ ] Multiple assessments test passes
- [ ] Progress bar updates on add
- [ ] Progress bar updates on remove
- [ ] Data persists across app restart

### Integration Testing

- [ ] Progress integrates with existing UI
- [ ] No conflicts with existing features
- [ ] Accessibility features still work
- [ ] Audit logging still functions

---

## Success Criteria

✅ **Issue 1 Resolved When**:
- Progress bar increases when fields added
- Progress bar decreases when fields removed
- Changes visible immediately in UI
- All domain progress bars accurate

✅ **Issue 2 Resolved When**:
- All 15 unit tests pass
- Manual testing checklist complete
- Answers persist across navigation
- Answers persist across app restart
- Current assessment restored on launch
- No data loss under normal usage

---

**Document Version**: 1.0  
**Last Updated**: November 11, 2025  
**Next Review**: After testing complete
