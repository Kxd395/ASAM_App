# Settings Migration Quick Reference Card

## 🎯 What Changed

**Old Way** (Deprecated):
```swift
@EnvironmentObject var settings: AppSettings
settings.textSizeIndex  // @AppStorage - brittle
```

**New Way** (Use This):
```swift
@EnvironmentObject var settings: SettingsStore
settings.ui_textSizeIndex  // @Published with UserDefaults bridge
```

---

## 🚀 Getting Started (3 Steps)

### 1. Update Your View
```swift
import SwiftUI

struct MyView: View {
    @EnvironmentObject var settings: SettingsStore  // Changed from AppSettings
    
    var body: some View {
        Text("Size: \(settings.ui_textSizeIndex)")     // Changed property name
            .font(.body)
        
        Toggle("High Contrast", isOn: $settings.ui_highContrast)
    }
}
```

### 2. Property Name Changes
| Old Name | New Name | Category |
|----------|----------|----------|
| `textSizeIndex` | `ui_textSizeIndex` | Display |
| `defaultSheetDetentIndex` | `ui_defaultSheetDetentIndex` | Display |
| `complianceMode` | `compliance_mode` | Compliance |
| `showCalculators` | `clinical_showCalculators` | Clinical |

**Pattern**: `category_propertyName` (e.g., `ui_*`, `clinical_*`, `rules_*`)

### 3. Access Singleton (Rare)
```swift
// Most views: use @EnvironmentObject
@EnvironmentObject var settings: SettingsStore

// Direct access (services, etc.):
let settings = SettingsStore.shared
print(settings.compliance_mode)
```

---

## 📦 All Settings Categories

### Display & Layout (`ui_*`)
```swift
settings.ui_textSizeIndex: Int           // 0-8
settings.ui_defaultSheetDetentIndex: Int // 0=compact, 1=comfort, 2=full
settings.ui_highContrast: Bool
settings.ui_reduceMotion: Bool
settings.ui_largerHitTargets: Bool
settings.ui_sidebarDensity: String       // "comfortable" | "compact"
```

### Clinical (`clinical_*`)
```swift
settings.clinical_showCalculators: Bool
settings.clinical_autoAdvanceAfterReview: Bool
settings.clinical_confirmBeforeSubmit: Bool
settings.clinical_allowSkipOptional: Bool
settings.clinical_symptomSeverityThreshold: Int  // 1-5
settings.clinical_riskScoringAlgorithm: String   // "standard" | "conservative"
```

### Rules (`rules_*`)
```swift
settings.rules_edition: String           // "v3.2", "v3.3"
settings.rules_channel: String           // "stable" | "beta" | "local"
settings.rules_autoUpdate: Bool
settings.rules_showProvenance: Bool
```

### Compliance (`compliance_*`) ⚠️ P0-Critical
```swift
settings.compliance_mode: String                // "internal_neutral" | "licensed"
settings.compliance_asamLicenseId: String
settings.compliance_templateGuard: Bool
settings.compliance_exportStrictness: String    // "strict" | "permissive"
settings.isMDMManaged: Bool                     // Read-only (computed)
```

### Privacy (`privacy_*`)
```swift
settings.privacy_maskPHI: Bool
settings.privacy_redactScreenshots: Bool
settings.privacy_requireFaceID: Bool
settings.privacy_idleLockMinutes: Int    // 1-15
```

### Export (`export_*`)
```swift
settings.export_paperSize: String               // "letter" | "a4"
settings.export_includeWatermark: Bool
settings.export_flattenPDF: Bool
settings.export_embedProvenance: Bool
settings.export_attachOriginalJSON: Bool
settings.export_filenameTemplate: String
```

### Developer (`dev_*`) #if DEBUG only
```swift
#if DEBUG
settings.dev_showBreadcrumbs: Bool
settings.dev_diagnosticsOverlay: Bool
#endif
```

---

## 🔒 Compliance Locking (P0)

### In Release Builds
```swift
Section("Compliance & Legal") {
    #if DEBUG
    if settings.isMDMManaged {
        Text("Settings managed by MDM").foregroundStyle(.secondary)
    }
    Picker("Mode", selection: $settings.compliance_mode) { ... }
    #else
    Text("Compliance mode locked in Release builds")
        .foregroundStyle(.secondary)
    #endif
}
```

### MDM Configuration (for IT)
```xml
<dict>
    <key>compliance.mode</key>
    <string>internal_neutral</string>  <!-- or "licensed" -->
    
    <key>compliance.asamLicenseId</key>
    <string>ORG-12345-ASAM</string>
    
    <key>compliance.templateGuard</key>
    <true/>
</dict>
```

---

## 🧪 Common Patterns

### Computed Properties
```swift
// Text size as DynamicTypeSize
let dynamicType: DynamicTypeSize = settings.dynamicType

// Sheet detent
let detent: PresentationDetent = settings.defaultSheetDetent

// Human-readable labels
let label: String = settings.textSizeLabel  // "Default", "Large", etc.

// Compliance check
if settings.isLicensedMode {
    // Show ASAM branding
}
```

### Watching Changes (Services)
```swift
import Combine

class MyService {
    private var cancellables = Set<AnyCancellable>()
    
    init(settings: SettingsStore) {
        settings.$rules_edition
            .sink { [weak self] edition in
                self?.reloadRules(edition)
            }
            .store(in: &cancellables)
    }
}
```

### Sanitizing Filenames
```swift
let template = settings.export_filenameTemplate.sanitizedFilename
// "Plan_{id}_{date}" → "Plan_id_date" (no special chars)
```

---

## 🐛 Troubleshooting

### Problem: Settings not persisting
**Cause**: Old `AppSettings` still in use  
**Fix**: Change to `SettingsStore` everywhere

### Problem: Property not found
**Cause**: Property name changed (now prefixed with category)  
**Fix**: Use new naming: `ui_textSizeIndex` not `textSizeIndex`

### Problem: Compliance editable in Release
**Cause**: Missing `#if !DEBUG` guards  
**Fix**: Wrap Compliance section as shown above

### Problem: Changes not observed across screens
**Cause**: Using multiple instances instead of `.shared`  
**Fix**: Always use `@EnvironmentObject` or `.shared` singleton

---

## 🎓 Testing Your Changes

### Unit Test
```swift
func testSettingsPersist() {
    let store = SettingsStore.shared
    store.ui_textSizeIndex = 7
    
    // Simulate app restart
    let newStore = SettingsStore.shared
    XCTAssertEqual(newStore.ui_textSizeIndex, 7)
}
```

### UI Test
```swift
app.buttons["Settings"].tap()
app.sliders["Text Size"].adjust(toNormalizedSliderPosition: 0.8)
app.buttons["Done"].tap()

// Verify change applied
XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Large'")).firstMatch.exists)
```

---

## 📚 Resources

- **Full Guide**: `docs/guides/SETTINGS_ARCHITECTURE_OVERHAUL.md`
- **Implementation Summary**: `docs/guides/P0_FIXES_COMPLETE.md`
- **Original Spec**: `docs/reviews/settungs_update.md`

---

## 🚨 Breaking Changes

### Deprecated (Remove by next sprint)
- ❌ `AppSettings` class → Use `SettingsStore`
- ❌ `UserPrefs` class → Use `SettingsStore`
- ❌ Property names without prefixes → Use category prefixes

### Migration Timeline
- **Today**: `SettingsStore` available, old classes still work
- **This week**: Update all views to use `SettingsStore`
- **Next sprint**: Delete deprecated classes

---

## ✅ Checklist for New Features

When adding a new setting:

- [ ] Add `@Published` property to `SettingsStore`
- [ ] Add to `registerDefaults()`
- [ ] Add to `pullFromDefaults()`
- [ ] Add sink in `wireSaves()`
- [ ] Add UI control to `SettingsViewEnhanced`
- [ ] Add to migration if secure default needed
- [ ] Add unit test for persistence
- [ ] Update this quick reference

---

**Last Updated**: 2025-11-10  
**Owner**: Development Team  
**Questions**: See `docs/guides/P0_FIXES_COMPLETE.md`
