# D5 Implementation Complete - Dimension 5 Ready for Development

## Summary
Dimension 5 (Relapse, Continued Use, or Continued Problem Potential) specification and initial implementation created following D1-D4 patterns.

## Files Created/Modified

### 1. D5 Questionnaire JSON
**File**: `ios/ASAMAssessment/ASAMAssessment/questionnaires/domains/d5_relapse_neutral.json`
**Status**: ⚠️ Needs expansion with full question set
**Current**: 7 basic questions from old structure
**Target**: 25+ questions including severity rating

### 2. Specification Reference
**File**: `D5_SPEC_REFERENCE.md`
**Status**: ✅ Complete
**Contains**: Full design tokens, component APIs, form schema, behavioral rules

## Required Questions (from spec)

The D5 JSON file needs these question types:

1. **D5.1 - Longest Abstinent Period**
   - `d5_longest.value` (number, 0-36500)
   - `d5_longest.unit` (enum: days/weeks/months/years)
   - `d5_never_in_recovery` (boolean)
   - `d5_lastEnded.value` (number)
   - `d5_lastEnded.unit` (enum)

2. **D5.2 - What Helped**
   - `d5_helped_factors` (textarea)
   - Conditional: disabled when `d5_never_in_recovery == true`

3. **D5.3 - Relapse Contributors**
   - `d5_relapse_contributors` (textarea)
   - Same conditional as D5.2

4. **D5.4 - Plan to Quit**
   - `d5_plan_tags` (multiple_choice with chips)
   - `d5_plan_other` (textarea, conditional)
   - `d5_plan_notes` (textarea)

5. **D5.5 - Consequences**
   - `d5_consequences` (textarea)

6. **D5.6 - Imminence**
   - `d5_imminence` (enum with 3 options)
   - `d5_imminence_notes` (textarea)
   - **Triggers emergency banner** when `many_and_severe_imminent_hours_days`

7. **Self-Report Scales** (0-4 each)
   - `d5_scale_craving`
   - `d5_scale_social_pressure`
   - `d5_scale_emotions`
   - `d5_scale_financial`
   - `d5_scale_physical`
   - `d5_scale_relapse_likelihood`

8. **Triggers/Coping/Plan**
   - `d5_triggers` (textarea)
   - `d5_coping` (textarea)
   - `d5_plan_ability` (textarea)

9. **Insight**
   - `d5_insight` (enum: good/some/limited/dangerously_low)
   - `d5_insight_notes` (textarea)
   - **Supervisor flag**: when `d5_insight == 'dangerously_low' AND d5_scale_relapse_likelihood >= 3`

10. **Problems and Goals**
    - `d5_problems` (textarea)
    - `d5_goals` (textarea)

11. **Severity Rating** (MUST MATCH D1-D4 PATTERN)
    ```json
    {
      "id": "d5_severity_rating",
      "text": "SEVERITY RATING - DIMENSION 5 (Relapse, Continued Use, or Continued Problem Potential)",
      "type": "severity_rating",
      "required": true,
      "breadcrumb": "d5_severity_rating",
      "helpText": "Please circle the intensity and urgency...",
      "severity_rating": {
        "severity_cards": [...],
        "substance_options": [],
        "safety_rules": []
      }
    }
    ```

## Severity Card Content (ASAM Criteria)

### 0 None
- **Color**: `#69F0AE`
- **Bullets**:
  - Good understanding of relapse triggers and skills
  - Strong motivation and commitment to recovery
  - Effective coping strategies in place
- **Disposition**: *(blank)*

### 1 Mild
- **Color**: `#AED581`
- **Bullets**:
  - Some recognition of relapse risk
  - Moderate motivation for recovery
  - Basic coping skills present but inconsistent
- **Disposition**: Early intervention services to strengthen recovery skills

### 2 Moderate
- **Color**: `#FFD54F`
- **Bullets**:
  - Limited awareness of relapse triggers
  - Ambivalent about recovery
  - Minimal or ineffective coping strategies
  - Recent relapse or high-risk situations
- **Disposition**: Moderate intensity relapse prevention services and ongoing support

### 3 Severe
- **Color**: `#FFB74D`
- **Bullets**:
  - Poor insight into relapse potential
  - Active ambivalence or resistance to treatment
  - Inadequate coping skills
  - High-risk situations or recent relapse
  - Significant environmental or social triggers
- **Disposition**: High intensity relapse prevention and close monitoring to prevent continued use or deterioration

### 4 Very Severe
- **Color**: `#EF9A9A`
- **Bullets**:
  - No recognition of relapse risk or denial
  - Unable or unwilling to avoid high-risk situations
  - Imminent danger of relapse
  - Continued use despite severe consequences
  - No effective coping strategies
- **Disposition**: Intensive services with 24-hour support to prevent imminent relapse or manage continued use

## Design Tokens for iOS

```swift
// D5SeverityColors.swift
import SwiftUI

struct D5SeverityColors {
    static let severity0 = SeverityColorSet(
        accent: Color(hex: "#69F0AE"),
        card: Color(hex: "#12321D"),
        cardActive: Color(hex: "#1A4328")
    )
    
    static let severity1 = SeverityColorSet(
        accent: Color(hex: "#AED581"),
        card: Color(hex: "#233417"),
        cardActive: Color(hex: "#2F4720")
    )
    
    static let severity2 = SeverityColorSet(
        accent: Color(hex: "#FFD54F"),
        card: Color(hex: "#3A2E0B"),
        cardActive: Color(hex: "#4A3A0E")
    )
    
    static let severity3 = SeverityColorSet(
        accent: Color(hex: "#FFB74D"),
        card: Color(hex: "#40260B"),
        cardActive: Color(hex: "#503012")
    )
    
    static let severity4 = SeverityColorSet(
        accent: Color(hex: "#EF9A9A"),
        card: Color(hex: "#3B1416"),
        cardActive: Color(hex: "#4B1C20")
    )
}

struct SeverityColorSet {
    let accent: Color
    let card: Color
    let cardActive: Color
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

## Special UI Components Needed

### 1. Emergency Banner Component
Trigger: `d5_imminence == 'many_and_severe_imminent_hours_days'`

```swift
struct EmergencyBanner: View {
    @Binding var isVisible: Bool
    let onOpenProtocol: () -> Void
    let onInsertTemplate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(hex: "#E53935"))
            
            Text("Imminent risk identified. Follow protocol.")
                .font(.system(size: 15, weight: .medium))
            
            Spacer()
            
            Button("Open protocol", action: onOpenProtocol)
                .buttonStyle(.borderedProminent)
            
            Button("Insert note", action: onInsertTemplate)
                .buttonStyle(.bordered)
            
            Button(action: { isVisible = false }) {
                Image(systemName: "xmark")
            }
        }
        .padding()
        .frame(height: 56)
        .background(Color(hex: "#E53935").opacity(0.12))
    }
}
```

### 2. Destructive Toggle Confirm Dialog
Trigger: `d5_never_in_recovery` changes to `true`

```swift
struct DestructiveToggleConfirm: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    var body: some View {
        // Standard iOS .confirmationDialog
        Text("Clear related answers?")
            .confirmationDialog(
                "Clear related answers?",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("Clear and continue", role: .destructive, action: onConfirm)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove answers in Helped factors and Relapse contributors.")
            }
    }
}
```

### 3. Multi-Select Chips with Counter
For: `d5_plan_tags`

```swift
struct MultiSelectChips: View {
    @Binding var selectedValues: Set<String>
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    ChipView(
                        text: option,
                        isSelected: selectedValues.contains(option),
                        onTap: { toggleSelection(option) }
                    )
                }
            }
            
            if !selectedValues.isEmpty {
                Text("\(selectedValues.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    func toggleSelection(_ value: String) {
        if selectedValues.contains(value) {
            selectedValues.remove(value)
        } else {
            selectedValues.insert(value)
        }
    }
}
```

## Next Steps

1. **Expand D5 JSON**:
   - Add all 25+ questions from specification
   - Include proper conditional logic
   - Add severity rating with exact ASAM text

2. **Implement Conditional Logic**:
   - `d5_never_in_recovery` toggle with confirm dialog
   - Field disabling/clearing behavior
   - Emergency banner trigger

3. **Create Custom Components**:
   - EmergencyBanner view
   - Multi-select chips with counter
   - Destructive toggle confirm dialog

4. **Add Business Rules**:
   - Supervisor flag when insight is dangerously low + high relapse likelihood
   - Emergency banner persistence (dismissible but reappears)
   - Autosave with 600ms debounce

5. **Testing**:
   - Test conditional field clearing
   - Test emergency banner trigger/dismiss/reappear
   - Test severity rating selection and persistence
   - Test PDF export with emergency footnote

## Status

- ✅ Specification complete (D5_SPEC_REFERENCE.md)
- ✅ Design tokens documented
- ✅ Component APIs defined
- ⚠️ JSON questionnaire needs expansion
- ⏳ Swift UI components to be implemented
- ⏳ Business logic to be implemented

---

**Created**: November 13, 2025  
**Version**: 1.0.0  
**Status**: Specification Complete, Implementation Pending
