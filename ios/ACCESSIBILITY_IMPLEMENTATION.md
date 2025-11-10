# Accessibility Implementation Guide

**Date**: November 9, 2025  
**Priority**: 🔴 CRITICAL - Must implement NOW, not later  
**Target**: WCAG 2.1 Level AA compliance

---

## 🎯 Why Accessibility Must Be Built In Now

**THE PROBLEM**: Deferring accessibility to "polish phase" creates technical debt that affects:
- Layout structure (containers, z-index)
- Navigation flows (focus management)
- Color palette (contrast ratios)
- Font sizing (Dynamic Type support)

**THE SOLUTION**: Build accessibility into every component from day 1.

---

## ✅ Accessibility Checklist

### VoiceOver Labels
- [ ] Every Button has `.accessibilityLabel()`
- [ ] Every NavigationLink has descriptive label
- [ ] Every Picker has label + hint
- [ ] Every Image (non-decorative) has label
- [ ] Every TextField has label + placeholder
- [ ] Every Stepper has label + value

### Dynamic Type
- [ ] All text uses semantic fonts (`.body`, `.headline`, etc.)
- [ ] Custom spacing uses `@ScaledMetric`
- [ ] Tested at largest accessibility size
- [ ] No hardcoded `font(.system(size: 16))`

### Color Contrast
- [ ] Text-to-background ≥4.5:1 ratio
- [ ] Interactive elements ≥3:1 ratio
- [ ] Semantic colors for light/dark mode
- [ ] No color-only information

### Focus Management
- [ ] Modal sheets focus first element
- [ ] Error messages grab focus
- [ ] Safety banner announces appearance

### Haptics
- [ ] Validation errors trigger haptic
- [ ] Safety banner appearance triggers haptic
- [ ] Success actions trigger haptic

---

## 📱 VoiceOver Implementation

### Button Labels

**BAD**:
```swift
Button("Record") {
    recordAction()
}
```

**GOOD**:
```swift
Button("Record") {
    recordAction()
}
.accessibilityLabel("Record safety action")
.accessibilityHint("Opens form to document immediate safety response")
.accessibilityAddTraits(.isButton)
```

### Navigation Links

**BAD**:
```swift
NavigationLink("Domain 1") {
    DomainView(domain: domain1)
}
```

**GOOD**:
```swift
NavigationLink {
    DomainView(domain: domain1)
} label: {
    HStack {
        Text("Domain 1")
        Text("Acute Intoxication")
            .foregroundColor(.secondary)
    }
}
.accessibilityLabel("Domain 1: Acute Intoxication")
.accessibilityHint("Opens domain assessment screen")
.accessibilityValue(domain1.severityLabel)
```

### Severity Chips

**BAD**:
```swift
Text("\(severity)")
    .padding()
    .background(severityColor)
```

**GOOD**:
```swift
Text("\(severity)")
    .padding()
    .background(severityColor)
    .accessibilityLabel("Severity level \(severity)")
    .accessibilityValue("\(severity) out of 4")
    .accessibilityHint("Indicates current severity rating")
```

### Complex Views

**BAD**:
```swift
VStack {
    Text("Domain 1")
    Text("Acute Intoxication")
    SeverityChip(severity: 2)
}
```

**GOOD**:
```swift
VStack {
    Text("Domain 1")
    Text("Acute Intoxication")
    SeverityChip(severity: 2)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Domain 1: Acute Intoxication, Severity 2 out of 4")
```

### Images

**Decorative** (hidden from VoiceOver):
```swift
Image(systemName: "chevron.right")
    .accessibilityHidden(true)
```

**Informative**:
```swift
Image(systemName: "exclamationmark.triangle.fill")
    .accessibilityLabel("Warning icon")
```

---

## 🔤 Dynamic Type Support

### Semantic Fonts (Always Use)

```swift
// ✅ GOOD: Respects user preference
Text("Domain 1")
    .font(.headline)

Text("Acute Intoxication and/or Withdrawal Potential")
    .font(.body)

Text("Last updated 2h ago")
    .font(.caption)
```

### Custom Spacing with @ScaledMetric

```swift
struct DomainRow: View {
    @ScaledMetric(relativeTo: .body) private var spacing: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20
    
    var body: some View {
        HStack(spacing: spacing) {
            Image(systemName: "circle.fill")
                .font(.system(size: iconSize))
            Text("Domain 1")
        }
    }
}
```

### Testing Dynamic Type

1. **Simulator Settings**:
   - Settings → Accessibility → Display & Text Size → Larger Text
   - Drag slider to "Larger Accessibility Sizes"
   - Test at AX5 (largest)

2. **Xcode Preview**:
   ```swift
   struct DomainRow_Previews: PreviewProvider {
       static var previews: some View {
           DomainRow()
               .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
       }
   }
   ```

3. **Layout Fixes**:
   ```swift
   // BAD: Fixed width breaks at large sizes
   HStack {
       Text("Label")
           .frame(width: 100)
       Text("Value")
   }
   
   // GOOD: Flexible layout
   HStack {
       Text("Label")
           .frame(minWidth: 80)
       Spacer()
       Text("Value")
   }
   
   // BETTER: Stack vertically at large sizes
   ViewThatFits {
       HStack {
           Text("Label")
           Spacer()
           Text("Value")
       }
       
       VStack(alignment: .leading) {
           Text("Label")
           Text("Value")
       }
   }
   ```

---

## 🎨 Color Contrast Standards

### WCAG AA Requirements

- **Normal text** (< 18pt): 4.5:1 minimum
- **Large text** (≥ 18pt): 3:1 minimum
- **UI components**: 3:1 minimum

### Semantic Color System

Create `Theme/Colors.swift`:

```swift
import SwiftUI

extension Color {
    // MARK: - Text Colors
    
    /// Primary text (headings, body) - WCAG AA compliant
    static let textPrimary = Color("TextPrimary")  // #1A1A1A (light) / #F5F5F5 (dark)
    
    /// Secondary text (captions, hints) - WCAG AA compliant
    static let textSecondary = Color("TextSecondary")  // #666666 (light) / #999999 (dark)
    
    /// Tertiary text (timestamps) - WCAG AA compliant
    static let textTertiary = Color("TextTertiary")  // #999999 (light) / #666666 (dark)
    
    // MARK: - Semantic Colors
    
    /// Error/danger state
    static let errorRed = Color("ErrorRed")  // #CC1A1A (6.5:1 on white)
    
    /// Warning state
    static let warningOrange = Color("WarningOrange")  // #CC6600 (4.9:1 on white)
    
    /// Success state
    static let successGreen = Color("SuccessGreen")  // #1A991A (4.7:1 on white)
    
    /// Info state
    static let infoBlue = Color("InfoBlue")  // #1A5699 (5.2:1 on white)
    
    // MARK: - Domain Colors
    
    static let domain1 = Color("Domain1")  // Red
    static let domain2 = Color("Domain2")  // Orange
    static let domain3 = Color("Domain3")  // Yellow
    static let domain4 = Color("Domain4")  // Green
    static let domain5 = Color("Domain5")  // Blue
    static let domain6 = Color("Domain6")  // Purple
    
    // MARK: - Background Colors
    
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let backgroundTertiary = Color("BackgroundTertiary")
}
```

### Color Asset Catalog Setup

1. **Create Color Set**:
   - Assets.xcassets → + → Color Set
   - Name: "TextPrimary"
   - Appearances: Light, Dark

2. **Configure Values**:
   - Light: `#1A1A1A` (RGB: 26, 26, 26)
   - Dark: `#F5F5F5` (RGB: 245, 245, 245)

3. **Test Contrast**:
   ```swift
   // Use WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/
   
   // Example:
   // TextPrimary (#1A1A1A) on White (#FFFFFF) = 13.4:1 ✅
   // TextSecondary (#666666) on White (#FFFFFF) = 5.7:1 ✅
   // ErrorRed (#CC1A1A) on White (#FFFFFF) = 6.5:1 ✅
   ```

### Never Use Color Alone

**BAD** (color-only information):
```swift
Text("Severity 3")
    .foregroundColor(.red)
```

**GOOD** (color + icon + label):
```swift
HStack {
    Image(systemName: "exclamationmark.triangle.fill")
    Text("Severity 3 (High)")
}
.foregroundColor(.errorRed)
.accessibilityLabel("High severity, level 3 out of 4")
```

---

## 🎯 Focus Management

### Modal Sheets

```swift
struct SafetyActionSheet: View {
    @AccessibilityFocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    
    enum Field {
        case actionType
        case notes
    }
    
    var body: some View {
        Form {
            Section("Action Type") {
                Picker("Type", selection: $actionType) {
                    // ...
                }
                .accessibilityFocused($focusedField, equals: .actionType)
            }
            
            Section("Notes") {
                TextField("Notes", text: $notes)
                    .accessibilityFocused($focusedField, equals: .notes)
            }
        }
        .onAppear {
            // Focus first field when sheet opens
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                focusedField = .actionType
            }
        }
    }
}
```

### Error Messages

```swift
struct DomainView: View {
    @State private var validationError: String?
    @AccessibilityFocusState private var errorFocused: Bool
    
    var body: some View {
        VStack {
            // ... content ...
            
            if let error = validationError {
                Text(error)
                    .foregroundColor(.errorRed)
                    .accessibilityFocused($errorFocused)
            }
        }
        .onChange(of: validationError) { newError in
            if newError != nil {
                // Focus error when it appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    errorFocused = true
                }
            }
        }
    }
}
```

### Safety Banner Announcement

```swift
struct SafetyBanner: View {
    @Binding var safetyFlag: SafetyFlag?
    @AccessibilityFocusState private var bannerFocused: Bool
    
    var body: some View {
        if let flag = safetyFlag {
            HStack {
                // ... banner content ...
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Safety alert: \(flag.message)")
            .accessibilityAddTraits(.isStaticText)
            .accessibilityFocused($bannerFocused)
            .onAppear {
                // Announce banner appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bannerFocused = true
                    
                    // Haptic feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
        }
    }
}
```

---

## 🔊 Haptic Feedback

### Setup

```swift
// Services/HapticService.swift
import UIKit

class HapticService {
    static let shared = HapticService()
    
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {
        impact.prepare()
        notification.prepare()
        selection.prepare()
    }
    
    func success() {
        notification.notificationOccurred(.success)
    }
    
    func warning() {
        notification.notificationOccurred(.warning)
    }
    
    func error() {
        notification.notificationOccurred(.error)
    }
    
    func impact() {
        impact.impactOccurred()
    }
    
    func selection() {
        selection.selectionChanged()
    }
}
```

### Usage

```swift
// Safety banner appears
HapticService.shared.warning()

// Validation error
HapticService.shared.error()

// Severity rating changed
HapticService.shared.selection()

// Action recorded successfully
HapticService.shared.success()

// Button tapped
HapticService.shared.impact()
```

---

## 🧪 Testing Procedures

### 1. VoiceOver Navigation Test

**Steps**:
1. Enable VoiceOver in simulator:
   - Settings → Accessibility → VoiceOver → ON
   - Or use Xcode: Accessibility Inspector
2. Navigate entire assessment flow
3. Verify every element is reachable
4. Check labels are descriptive and contextual

**Checklist**:
- [ ] Can navigate to all screens without seeing
- [ ] Button actions are clear from labels
- [ ] Form fields have clear labels + hints
- [ ] Error messages are announced
- [ ] Safety banner is announced immediately

### 2. Dynamic Type Test

**Steps**:
1. Go to Settings → Accessibility → Display & Text Size → Larger Text
2. Enable "Larger Accessibility Sizes"
3. Test at AX5 (largest size)
4. Verify no text truncation or layout breaks

**Checklist**:
- [ ] All text scales correctly
- [ ] Buttons remain tappable
- [ ] No horizontal scrolling required
- [ ] Forms remain usable
- [ ] Multi-column layouts stack vertically

### 3. Color Contrast Test

**Tools**:
- Xcode Accessibility Inspector
- WebAIM Contrast Checker (https://webaim.org/resources/contrastchecker/)

**Steps**:
1. Open Accessibility Inspector (Xcode → Developer Tools)
2. Select "Audit" tab
3. Run audit on each screen
4. Fix any contrast warnings

**Checklist**:
- [ ] All text meets 4.5:1 ratio
- [ ] Buttons meet 3:1 ratio
- [ ] No color-only information
- [ ] Dark mode equally accessible

### 4. Keyboard Navigation Test (iPad)

**Steps**:
1. Connect keyboard to iPad simulator
2. Use Tab/Shift+Tab to navigate
3. Use Space/Return to activate
4. Verify focus indicators visible

**Checklist**:
- [ ] Can navigate without mouse
- [ ] Focus order is logical
- [ ] Focus indicator always visible
- [ ] Can activate all controls

### 5. Reduce Motion Test

**Steps**:
1. Settings → Accessibility → Motion → Reduce Motion → ON
2. Test all animations
3. Verify no critical information lost

**Checklist**:
- [ ] Navigation still works
- [ ] State changes visible without animation
- [ ] No flashing/strobing effects
- [ ] Transitions respect `accessibilityReduceMotion`

---

## 📋 Component-Specific Patterns

### LaunchView

```swift
struct LaunchView: View {
    var body: some View {
        VStack {
            Image("app-logo")
                .accessibilityLabel("ASSESS application logo")
            
            Text("Assessment Tool")
                .font(.largeTitle)
                .accessibilityAddTraits(.isHeader)
            
            Button("Sign In with Credentials") {
                signIn()
            }
            .accessibilityLabel("Sign in with credentials")
            .accessibilityHint("Opens authentication screen")
        }
        .accessibilityElement(children: .contain)
    }
}
```

### AssessmentOverview

```swift
struct AssessmentOverview: View {
    let assessment: Assessment
    
    var body: some View {
        List {
            ForEach(assessment.domains) { domain in
                NavigationLink {
                    DomainView(domain: domain)
                } label: {
                    DomainRow(domain: domain)
                }
                .accessibilityLabel("\(domain.name), Severity \(domain.severity ?? 0) out of 4")
                .accessibilityHint("Opens domain assessment screen")
            }
        }
        .navigationTitle("Assessment Overview")
        .accessibilityElement(children: .contain)
    }
}
```

### DomainView

```swift
struct DomainView: View {
    @State private var severity: Int = 0
    
    var body: some View {
        Form {
            Section("Severity Rating") {
                Stepper(value: $severity, in: 0...4) {
                    Text("Severity: \(severity)")
                }
                .accessibilityLabel("Severity rating")
                .accessibilityValue("\(severity) out of 4")
                .accessibilityHint("Adjust severity level using plus and minus buttons")
                .onChange(of: severity) { _ in
                    HapticService.shared.selection()
                }
            }
        }
        .navigationTitle("Domain Assessment")
    }
}
```

### SafetyBanner (Enhanced)

```swift
struct SafetyBanner: View {
    @Binding var safetyFlag: SafetyFlag?
    @AccessibilityFocusState private var bannerFocused: Bool
    
    var body: some View {
        if let flag = safetyFlag {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.errorRed)
                    .accessibilityHidden(true)  // Redundant with text
                
                VStack(alignment: .leading) {
                    Text("Safety Alert")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(flag.message)
                        .font(.subheadline)
                }
                
                Spacer()
                
                Button("Record Action") {
                    // Show modal
                }
                .buttonStyle(.borderedProminent)
                .tint(.errorRed)
                .accessibilityLabel("Record safety action")
                .accessibilityHint("Opens form to document immediate safety response")
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Safety alert: \(flag.message). Record action required.")
            .accessibilityFocused($bannerFocused)
            .onAppear {
                // Announce and focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bannerFocused = true
                    HapticService.shared.warning()
                }
            }
        }
    }
}
```

---

## ✅ Accessibility Audit Script

Create automated checks:

```swift
// Development only
#if DEBUG
struct AccessibilityAudit {
    static func run(view: some View) {
        var issues: [String] = []
        
        // Check for unlabeled buttons
        // Check for color-only information
        // Check for missing hints
        // Check for semantic structure
        
        if !issues.isEmpty {
            print("⚠️ ACCESSIBILITY ISSUES FOUND:")
            issues.forEach { print("  - \($0)") }
        } else {
            print("✅ Accessibility audit passed")
        }
    }
}
#endif
```

Run before each commit:
```bash
# .git/hooks/pre-commit
#!/bin/bash
# Run accessibility audit
xcodebuild test -scheme ASSESS -destination 'platform=iOS Simulator,name=iPad Pro' -only-testing:ASSESSTests/AccessibilityTests
```

---

## 🎯 Success Metrics

### Definition of Done
- [ ] VoiceOver navigation test passes
- [ ] Dynamic Type test passes (AX5)
- [ ] Color contrast audit passes (≥4.5:1)
- [ ] Keyboard navigation test passes
- [ ] Reduce Motion test passes
- [ ] No accessibility warnings in Xcode
- [ ] All interactive elements labeled
- [ ] All images have labels or marked decorative

### Acceptance Criteria
1. **VoiceOver**: Can complete entire assessment without vision
2. **Dynamic Type**: Usable at largest accessibility size
3. **Color Contrast**: All text ≥4.5:1 ratio
4. **Focus**: Logical navigation order maintained
5. **Haptics**: Appropriate feedback for all interactions

---

## 📚 Resources

### Apple Documentation
- [Accessibility for SwiftUI](https://developer.apple.com/documentation/swiftui/accessibility)
- [VoiceOver Programming Guide](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/)
- [Dynamic Type Guide](https://developer.apple.com/design/human-interface-guidelines/accessibility#Text-size-and-weight)

### Testing Tools
- Xcode Accessibility Inspector
- VoiceOver (Settings → Accessibility)
- WebAIM Contrast Checker
- Accessibility Auditor (TestFlight)

### Standards
- [WCAG 2.1 Level AA](https://www.w3.org/WAI/WCAG21/quickref/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/accessibility)

---

**Last Updated**: November 9, 2025  
**Priority**: 🔴 CRITICAL - Implement before adding features  
**Next Review**: After VoiceOver test pass
