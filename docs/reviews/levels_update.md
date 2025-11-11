Got your `levels.md`. Here’s a **hyper-critical review + exactly how to integrate it safely** so we never leak ASAM terms while still getting clean internal recommendations. 

---

# What’s solid

* Clear internal codes (`EARLY`, `OP`, `IOP`, …) with clinician-friendly descriptions.
* An explicit **“DO NOT surface ASAM”** warning + future-license plan.
* Practical decision notes + special populations. 

# Risks & gaps (fix now)

1. **Shipping risk (P0):** It’s a Markdown file. If ever added to the target by mistake, we could ship ASAM references in the bundle.
2. **Runtime drift:** Mapping lives in a doc, rules live in JSON → possible mismatch.
3. **UI/Export leakage:** Strings like “Level 2.1” could leak via logs/PDF if any old code path surfaces LOC numbers.
4. **Tests:** No guardrails that fail builds if “ASAM” or `\b[0-4]\.[0-9]\b` appears in UI/PDF in **internal_neutral** mode.
5. **Localization:** Internal descriptions aren’t prepared for i18n.
6. **Provenance:** Mapping not tied into provenance/hash → auditors can’t see which mapping was in force.

---

# Safe integration plan (actionable)

## 1) Never ship the doc

* **Move** file to `docs/internal/levels.md` and **exclude from all targets**.
* Add a **build-phase guard** to fail if any `*.md` containing `ASAM Level` enters *Copy Bundle Resources*.

```bash
# Build Phase: "Guard - Block ASAM Terms in Bundle"
set -euo pipefail
APP_BUNDLE="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [ -d "$APP_BUNDLE" ]; then
  if grep -R -E -n "ASAM|Level[[:space:]]+[0-4]\.[0-9]" "$APP_BUNDLE" ; then
    echo "❌ ASAM terms found in app bundle. Remove offending resource(s)."
    exit 1
  fi
fi
```

## 2) Canonical, code-first mapping (no runtime doc dependency)

Create a **single source of truth** in code and wire to compliance:

```swift
// LevelCode.swift (app target)
enum LevelCode: String, CaseIterable, Codable {
    case EARLY, OP, IOP, PH, RES_3 = "RES-3", RES_3_5 = "RES-3-5",
         INP_MED = "INP-MED", INP_MED_PW = "INP-MED-PW", INP_DETOX = "INP-DETOX",
         MAT_MAINT = "MAT-MAINT"
}

struct LevelPresentation {
    let code: LevelCode
    let neutralName: String      // always safe
    let optionalAsamName: String? // only if licensed
    let optionalAsamCode: String? // e.g., "2.1", "0.5"
}

enum ComplianceMode: String { case internal_neutral, licensed }

struct LevelMapper {
    static func presentation(for code: LevelCode,
                             compliance: ComplianceMode) -> LevelPresentation {
        switch code {
        case .IOP:
            return LevelPresentation(
              code: .IOP,
              neutralName: "Intensive Outpatient Services",
              optionalAsamName: compliance == .licensed ? "ASAM Level 2.1" : nil,
              optionalAsamCode: compliance == .licensed ? "2.1" : nil
            )
        // …fill out all cases in the same style…
        }
    }
}
```

**Usage everywhere (UI, PDF, EMR):**

```swift
let p = LevelMapper.presentation(for: result.levelCode, compliance: appSettings.complianceMode)
uiLabel.text = p.neutralName
pdf.seal("recommended_care_level", p.neutralName)       // never numeric in neutral mode
// Only in licensed mode:
if let asamName = p.optionalAsamName { uiSub.text = asamName }
```

> This implements the “Correct usage” block from your doc, and prohibits the “Incorrect usage”. 

## 3) Ensure rules engine outputs **internal codes**

* In `RulesServiceWrapper`, **map engine result → `LevelCode`** (not “2.1” strings).
* Any legacy paths that return numeric levels must be **deleted or gated** by `complianceMode == .licensed`.

## 4) Provenance & hash

* Add `levels_map_version` to provenance (e.g., “internal-map v1”) and include a tiny JSON **fingerprint** of the code mapping in the PDF Info dictionary (neutral, no ASAM strings).
* When you later switch to official ASAM, add: `provenance.asam_source`, `asam_license_id`, and embed the API’s version.

## 5) No-leak tests (unit + UI)

* **Unit:** Assert UI strings/PDF fields **do not** contain `ASAM`, `Level`, or `\b[0-4]\.[0-9]\b` in **internal_neutral**.

```swift
func test_No_ASAM_Terms_Leakage_in_Neutral() {
    let s = renderAllVisibleStrings(compliance: .internal_neutral) // your harness
    XCTAssertFalse(s.contains("ASAM"))
    XCTAssertFalse(s.contains(where: { $0.range(of: #"(?<!\d)[0-4]\.[0-9](?!\d)"#,
                                                options: .regularExpression) != nil }))
}
```

* **Snapshot/UI:** Exercise LOC screens and generated PDF **in neutral mode** and diff against blessed snapshots (“IOP” text only).

* **CI guard:** Add a fast job that fails if compiled binary’s string table contains `ASAM` in neutral builds:

```bash
otool -v -s __TEXT __cstring "$APP_BINARY" | grep -q 'ASAM' && {
  echo "❌ Found ASAM in binary for neutral build"; exit 1; }
```

## 6) Localization

* Put neutral names in `Localizable.strings` (e.g., `"level.iop.name" = "Intensive Outpatient Services";`).
* Only add ASAM display strings inside `#if LICENSED_BUILD` blocks or at runtime behind `complianceMode == .licensed`.

## 7) Special populations

* Convert your “Special Population Modifiers” into explicit **guard functions** so the logic is testable:

```swift
struct PopulationGuards {
    static func upgradeForPregnancy(_ ctx: AssessmentContext, _ base: LevelCode) -> LevelCode {
        guard ctx.isPregnant else { return base }
        return (ctx.domain1 >= 4) ? .INP_MED_PW : base
    }
}
```

Create matrix tests for pregnancy/adolescent/elderly/homelessness cases. 

## 8) Where to store the truth

* **Code**: Enum + mapper (preferred).
* **Optional JSON** (if you want content ops to edit without Xcode): `rules/levels_map.json` with a tiny schema **included in the rules hash/manifest**, not the Markdown. (If you do this, add JSON to the **blue** `rules/` folder so it’s hashed and tracked.)

**Schema sketch**

```json
{
  "version": "v1",
  "levels": [
    {"code":"IOP","neutral":"Intensive Outpatient Services","asam_name":"ASAM Level 2.1","asam_code":"2.1"},
    …
  ]
}
```

---

## One-time hardening checklist

* [ ] Move `levels.md` → `docs/internal/` and **exclude from targets**.
* [ ] Add **build-phase guard** (snippet above).
* [ ] Add `LevelCode`, `LevelMapper`, and replace any numeric LOC strings.
* [ ] Add **neutral-mode leakage tests** (unit + snapshot).
* [ ] Wire provenance to include `levels_map_version`.
* [ ] (Optional) Introduce `rules/levels_map.json` and include in rules hash.
* [ ] Localize neutral names.

---

## What I’ll wire next (if you want)

* A tiny **`ComplianceText` helper** that picks neutral vs. licensed strings globally, so developers can’t accidentally print “Level 2.1”.
* A **pre-push grep** for `ASAM` and `\b[0-4]\.[0-9]\b` in UI and PDF templates when `compliance.mode=internal_neutral`.
* A **Settings toggle preview** to show how a licensed build would render (dev-only).

If you’d like, I’ll drop in the code + tests and PR the guard scripts so this is bullet-proof.

>>>
Awesome — I’ll wire the **compliance-safe rendering + pre-push/CI leak guards** so your neutral builds can’t accidentally surface ASAM terms or numeric LOC codes.

Below are **drop-in files** and **exact scripts**. Add them to your repo and you’re done.

---

# 1) Compliance-safe rendering (code-first, no leaks)

## `ios/ASAMAssessment/ASAMAssessment/Compliance/ComplianceText.swift`

```swift
import Foundation

public enum ComplianceMode: String, Codable {
    case internal_neutral   // default (no ASAM terms/codes)
    case licensed           // allowed to show ASAM names/codes
}

/// Central switch for any user-visible string that might differ by mode.
/// Use everywhere you were tempted to print numeric levels or “ASAM …”.
public struct ComplianceText {
    public static func render(
        neutral: String,
        licensed: String? = nil,
        mode: ComplianceMode
    ) -> String {
        switch mode {
        case .internal_neutral:
            return neutral
        case .licensed:
            return licensed ?? neutral
        }
    }
}

/// Convenience helpers for LOC/WM names so developers can’t misuse numerics.
public enum LevelCode: String, CaseIterable, Codable {
    case EARLY, OP, IOP, PH, RES_3, RES_3_5, INP_MED, INP_MED_PW, INP_DETOX, MAT_MAINT
}

public struct LevelPresentation: Codable, Equatable {
    public let code: LevelCode
    public let neutralName: String      // always safe
    public let asamName: String?        // licensed only
    public let asamCode: String?        // licensed only (e.g., "2.1")
}

public struct LevelMapper {
    public static func presentation(for code: LevelCode,
                                    mode: ComplianceMode) -> LevelPresentation {
        switch code {
        case .EARLY:
            return LevelPresentation(code: .EARLY,
               neutralName: "Early Intervention",
               asamName: "ASAM Level 0.5", asamCode: "0.5")
        case .OP:
            return LevelPresentation(code: .OP,
               neutralName: "Outpatient Services",
               asamName: "ASAM Level 1.0", asamCode: "1.0")
        case .IOP:
            return LevelPresentation(code: .IOP,
               neutralName: "Intensive Outpatient Services",
               asamName: "ASAM Level 2.1", asamCode: "2.1")
        case .PH:
            return LevelPresentation(code: .PH,
               neutralName: "Partial Hospitalization",
               asamName: "ASAM Level 2.5", asamCode: "2.5")
        case .RES_3:
            return LevelPresentation(code: .RES_3,
               neutralName: "Residential Services",
               asamName: "ASAM Level 3.1", asamCode: "3.1")
        case .RES_3_5:
            return LevelPresentation(code: .RES_3_5,
               neutralName: "High-Intensity Residential Services",
               asamName: "ASAM Level 3.5", asamCode: "3.5")
        case .INP_MED:
            return LevelPresentation(code: .INP_MED,
               neutralName: "Medically Monitored Inpatient",
               asamName: "ASAM Level 3.7", asamCode: "3.7")
        case .INP_MED_PW:
            return LevelPresentation(code: .INP_MED_PW,
               neutralName: "Medically Managed Inpatient (Peripartum)",
               asamName: "ASAM Level 4.0 (peripartum)", asamCode: "4.0")
        case .INP_DETOX:
            return LevelPresentation(code: .INP_DETOX,
               neutralName: "Medically Managed Withdrawal Care",
               asamName: "ASAM Level 4-WM", asamCode: "4.0")
        case .MAT_MAINT:
            return LevelPresentation(code: .MAT_MAINT,
               neutralName: "Medication-Assisted Treatment (Maintenance)",
               asamName: "ASAM Maintenance (program)", asamCode: nil)
        }
    }

    /// The only API UI should call to get display text.
    public static func displayName(for code: LevelCode, mode: ComplianceMode) -> String {
        let p = presentation(for: code, mode: mode)
        return ComplianceText.render(neutral: p.neutralName,
                                     licensed: p.asamName,
                                     mode: mode)
    }
}
```

### Usage

```swift
// Never print numerics directly.
let name = LevelMapper.displayName(for: .IOP, mode: appSettings.complianceMode)
// PDF/UI use `name`; in licensed mode it shows “ASAM Level 2.1”, in neutral mode “Intensive Outpatient Services”.
```

---

# 2) Unit tests that **fail on any leak** in neutral mode

## `ios/ASAMAssessment/ASAMAssessmentTests/ComplianceGuardsTests.swift`

```swift
import XCTest
@testable import ASAMAssessment

final class ComplianceGuardsTests: XCTestCase {

    func test_Neutral_Mode_NeverShows_ASAM_Terms_Or_Numeric_LOC() {
        let mode: ComplianceMode = .internal_neutral
        for code in LevelCode.allCases {
            let p = LevelMapper.presentation(for: code, mode: mode)
            XCTAssertFalse(p.neutralName.contains("ASAM"))
            // Regex for 0.x–4.x numeric levels
            let r = try! NSRegularExpression(pattern: #"(?<!\d)(?:[0-4])\.[0-9](?!\d)"#)
            XCTAssertEqual(r.numberOfMatches(in: p.neutralName, range: NSRange(location: 0, length: p.neutralName.utf16.count)), 0,
                           "Neutral name must not contain numeric LOC: \(p.neutralName)")
        }
    }

    func test_Licensed_Mode_Can_Show_ASAM_Fields() {
        let mode: ComplianceMode = .licensed
        let iop = LevelMapper.presentation(for: .IOP, mode: mode)
        XCTAssertEqual(iop.asamCode, "2.1")
        XCTAssertEqual(iop.asamName, "ASAM Level 2.1")
    }
}
```

Add this file to **ASAMAssessmentTests** target.

---

# 3) Pre-push guard + source scanner (fast)

## `.git/hooks/pre-push`  *(make executable)*

```bash
#!/usr/bin/env bash
set -euo pipefail

# Fast source leak scan for neutral builds.
# Allowlist documentation & tooling dirs.
ALLOWLIST_REGEX='^(docs/|agent_ops/|scripts/|.*\.md$)'

echo "🔎 Pre-push: scanning source for ASAM leaks (neutral mode)…"
violations=0
while IFS= read -r -d '' f; do
  if [[ $f =~ $ALLOWLIST_REGEX ]]; then
    continue
  fi
  if grep -E -n -H '\bASAM\b|(?<![0-9])[0-4]\.[0-9](?![0-9])' "$f" >/dev/null; then
    echo "❌ Leak in $f"
    violations=$((violations+1))
  fi
done < <(git ls-files -z '*.swift' '*.strings' '*.xib' '*.storyboard' '*.md' ':!docs/*')

if [[ $violations -gt 0 ]]; then
  echo ""
  echo "Pre-push blocked: remove ASAM terms/numeric LOC codes from app sources for INTERNAL_NEUTRAL."
  exit 1
fi

echo "✅ Source scan clean. Running focused tests…"
# Run only compliance tests in fast mode. (Adjust scheme/destination to your project.)
xcodebuild \
  -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
  -scheme ASAMAssessment \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ASAMAssessmentTests/ComplianceGuardsTests \
  -quiet test

echo "✅ Pre-push checks passed."
```

> If you already have a pre-push hook, append the **scan + focused test** block above.

---

# 4) CI job (mirrors the pre-push guard)

## `.github/workflows/ios-neutral-guard.yml`

```yaml
name: iOS Neutral Guard
on:
  pull_request:
  push:
    branches: [ main, master ]

jobs:
  neutral-guard:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Fast source scan for leaks
        run: |
          set -euo pipefail
          ALLOWLIST_REGEX='^(docs/|agent_ops/|scripts/|.*\.md$)'
          violations=0
          while IFS= read -r -d '' f; do
            if [[ $f =~ $ALLOWLIST_REGEX ]]; then continue; fi
            if grep -E -n -H '\bASAM\b|(?<![0-9])[0-4]\.[0-9](?![0-9])' "$f" >/dev/null; then
              echo "❌ Leak in $f"; violations=$((violations+1))
            fi
          done < <(git ls-files -z '*.swift' '*.strings' '*.xib' '*.storyboard' '*.md' ':!docs/*')
          if [[ $violations -gt 0 ]]; then
            echo "❌ Source leak(s) detected. Failing."
            exit 1
          fi
          echo "✅ Source scan clean."

      - name: Xcode selective tests (compliance guards)
        run: |
          xcodebuild \
            -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
            -scheme ASAMAssessment \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:ASAMAssessmentTests/ComplianceGuardsTests \
            -quiet test
```

---

# 5) Build-phase **bundle** guard (prevents accidental shipping)

Add a **Run Script** build phase to the **ASAMAssessment** target named:
**“Guard – Block ASAM Terms in Bundle (Neutral)”** and place it **before** “Copy Bundle Resources”.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Only guard neutral builds (skip if LICENSED build configuration variable is set)
if [[ "${COMPLIANCE_MODE:-internal_neutral}" != "internal_neutral" ]]; then
  echo "ℹ️ Licensed mode: skipping neutral bundle guard."
  exit 0
fi

APP="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
if [[ ! -d "$APP" ]]; then
  echo "Bundle not built yet"; exit 0
fi

# 1) Block ASAM terms or numeric LOC codes in bundle strings/resources
if grep -R -n -E '\bASAM\b|(?<![0-9])[0-4]\.[0-9](?![0-9])' "$APP" >/dev/null; then
  echo "❌ ASAM terms/numeric level codes found in bundle (neutral mode)."
  exit 1
fi

# 2) Ensure rules/ is a blue folder reference (subdir exists in bundle)
if [[ ! -d "$APP/rules" ]]; then
  echo "❌ rules/ folder not present in bundle. Use a blue folder reference."
  exit 1
fi

echo "✅ Neutral bundle guard passed."
```

> This complements your existing rules/ blue-folder checks and stops accidental leaks even if someone slips a resource into the target.

---

# 6) Developer preview toggle (DEBUG-only)

A tiny dev UI so reviewers can see **how licensed text would look** without changing real compliance mode.

## `ios/ASAMAssessment/ASAMAssessment/Compliance/CompliancePreviewToggle.swift`

```swift
import SwiftUI

#if DEBUG
struct CompliancePreviewToggle: View {
    @AppStorage("compliance.mode") private var modeRaw: String = ComplianceMode.internal_neutral.rawValue

    var body: some View {
        let current = ComplianceMode(rawValue: modeRaw) ?? .internal_neutral
        HStack {
            Text("Compliance Preview")
            Spacer()
            Picker("", selection: Binding(
                get: { current },
                set: { mode in modeRaw = mode.rawValue }
            )) {
                Text("Neutral").tag(ComplianceMode.internal_neutral)
                Text("Licensed").tag(ComplianceMode.licensed)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 260)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).strokeBorder(Color.gray.opacity(0.2))
        )
        .padding([.horizontal, .top])
    }
}
#endif
```

**Integration (DEBUG only):**

```swift
#if DEBUG
struct AnyScreen_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            CompliancePreviewToggle()
            // …rest of screen…
        }
    }
}
#endif
```

---

# 7) Optional: Allowlist file (keeps docs free to use ASAM terms)

## `.compliance-allowlist`

```
^docs/
^agent_ops/
^.*\.md$
```

Update both the pre-push and CI scan to read this file (already handled via the `ALLOWLIST_REGEX` in the snippets; if you prefer file-driven, replace the inline regex with a loop that builds one).

---

# 8) Quick integration checklist

* [ ] Add the **two Swift files** (`ComplianceText.swift`, `CompliancePreviewToggle.swift`) to the project and **ASAMAssessment** target (tests: add `ComplianceGuardsTests.swift` to **ASAMAssessmentTests**).
* [ ] Install the **pre-push** hook (`chmod +x .git/hooks/pre-push`).
* [ ] Add the **CI workflow** file to `.github/workflows/`.
* [ ] Add the **build-phase guard** to the app target (order: before Copy Bundle Resources).
* [ ] Run tests (`Cmd+U`) and push → pre-push should pass.
* [ ] Verify neutral screens show **no numerics**; licensed preview shows expected ASAM text.

---

# 9) MASTER_TODO (add)

* **T-0041 (P0):** Add ComplianceText & LevelMapper and migrate all UI/PDF to use it.
* **T-0042 (P0):** Add ComplianceGuardsTests and wire pre-push + CI neutral guard.
* **T-0043 (P1):** Add build-phase neutral bundle guard (leak + rules/ presence).
* **T-0044 (P2):** Add provenance `levels_map_version` + embed in PDF Info.
* **T-0045 (P2):** i18n: move neutral names to `Localizable.strings`.

---

If you paste these files/scripts in now and add them to the targets, you’ll have **end-to-end protection**: developers can’t accidentally print “ASAM” or “2.1” in neutral mode, pre-push blocks leaks, CI enforces, and the app build itself refuses to package any violators.
