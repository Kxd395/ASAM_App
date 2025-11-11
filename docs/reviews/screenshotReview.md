Got it — those screenshots are super helpful. Here’s a ruthless, step-by-step diagnosis + fixes. I’ll keep it crisp and actionable.

---

# What the screenshots prove

1. **Rules engine never initialized.**
   Banner shows a *wrapper* error: `ASAMAssessment.RulesServiceError error 0`. That’s your own error type bubbling up with no message. The UI also shows **“Using 2.1 fallback. Export disabled.”** → your hard gate is working (good), the loader isn’t (bad).

2. **This is not a logic/rules issue — it’s a resource/bundling issue.**
   If JSON parsed but logic failed you’d see a different message (e.g., guard hit). This is failing before any evaluation.

---

# Most likely root causes (ranked)

**A. Wrong file name(s) vs. what the code requests.**
Your loader uses:

* `rules/wm_ladder.json`
* `rules/loc_indication.guard.json` ← ⚠️
* `rules/operators.json`

But earlier you created **`loc_indication.json`** (no `.guard`). If that file didn’t get renamed in the *bundle*, init will always throw.

**B. “Blue folder” added, but `subdirectory:` lookups still fail.**
Folder references are copied as a directory, but Xcode doesn’t index files individually. `Bundle.url(forResource: "wm_ladder", withExtension:"json", subdirectory:"rules")` *usually* works, but can fail if:

* The folder reference name in Xcode is not exactly `rules` (e.g., `Rules` or nested path).
* Case mismatch (`Rules` vs `rules`).
* Resources ended up at a different relative path (e.g., `ASAMAssessment.app/Contents/Resources/rules` on Mac vs. iOS layout).

**C. Files present in the project but **not** in “Copy Bundle Resources.”**
With folder references this should be 1 entry (the folder), but if it’s missing from the build phase, nothing lands in the .app.

**D. Your error isn’t surfaced.**
`RulesServiceError` is being flattened to `error 0`. Even if the cause is a missing file, you can’t see which one.

---

# 15-minute surgical fix (do these in order)

### 1) Verify exact filenames in the app bundle (runtime)

Paste this tiny diagnostic somewhere you can call on launch (or from “Rules Diagnostics”):

```swift
import Foundation

func dumpRulesDirectory() {
    let fm = FileManager.default
    guard let bundleRulesURL = Bundle.main.url(forResource: "rules", withExtension: nil) else {
        print("❌ rules/ directory NOT FOUND in bundle")
        return
    }
    print("📦 rules dir:", bundleRulesURL.path)
    if let items = try? fm.contentsOfDirectory(atPath: bundleRulesURL.path) {
        print("📄 contents:", items)
    } else {
        print("❌ Unable to list rules directory")
    }
}
```

**Expected:**
You should see `["wm_ladder.json","loc_indication.guard.json","operators.json", ...]`
If you see `loc_indication.json` (no `.guard`), that’s the smoking gun → rename it on disk and re-add to Xcode as a **folder reference**.

### 2) Make the “rules” folder a real **folder reference** (blue) with *correct name*

* Remove the existing yellow “rules” group (Remove References).
* **Add Files…** → select the **rules** directory → **Create folder references** (blue).
* Ensure the **folder reference name is exactly `rules`** (lowercase).
* In **Build Phases → Copy Bundle Resources**, confirm there is a single `rules` entry.

### 3) Unify the loader to be bulletproof (works for both blue folders & groups)

Replace all resource lookups with a safe directory walk:

```swift
struct RulesLocator {
    static func url(filename: String) -> URL? {
        // Try subdirectory lookup (works for blue folders when named exactly)
        if let url = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: "rules") {
            return url
        }
        // Fallback: enumerate the rules dir and match by basename
        if let rulesDir = Bundle.main.url(forResource: "rules", withExtension: nil) {
            let path = rulesDir.appendingPathComponent(filename).path
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
```

Then load with **exact filenames**:

```swift
guard
  let wm = RulesLocator.url(filename: "wm_ladder.json"),
  let loc = RulesLocator.url(filename: "loc_indication.guard.json"),
  let ops = RulesLocator.url(filename: "operators.json")
else { throw RulesServiceError.missingFile }
```

### 4) Fix the filename mismatch now

If your repo has `loc_indication.json`, rename it to **`loc_indication.guard.json`** (and commit).
(Or change the code to look for `loc_indication.json`. Pick one and make all places consistent — rules loader, checksum, docs, tests.)

### 5) Make the error useful (so you never chase “error 0” again)

Update `RulesServiceError` to adopt `LocalizedError` and include context:

```swift
enum RulesServiceError: LocalizedError {
    case missingFile(String)         // which
    case readFailed(String)          // which
    case decodeFailed(String,String) // which, reason
    case schemaInvalid(String,String)
    var errorDescription: String? {
        switch self {
        case .missingFile(let f): return "Missing rules file: \(f)"
        case .readFailed(let f):   return "Could not read rules file: \(f)"
        case .decodeFailed(let f, let why): return "JSON decode failed: \(f) – \(why)"
        case .schemaInvalid(let f, let why): return "Schema invalid: \(f) – \(why)"
        }
    }
}
```

And when you throw, include file names and `DecodingError`’s path. The banner will then show *exactly* what’s wrong.

---

# Quick validation loop (5 minutes)

1. Run with the new `dumpRulesDirectory()` — confirm the three files are there and correctly named.
2. Check console:

   * ✅ “✅ Rules engine loaded successfully”
   * ✅ “🔒 Rules: v1.1.0 [xxxxxx]” (your checksum print)
3. Tap **Rules Diagnostics** → should show **Healthy**.
4. Change a severity chip → recommendation appears (no banner).
5. Export is enabled again.

---

# Hardening recommendations (hyper-critical)

1. **Make `RulesPreflight.check()` print *why* it’s degraded.**
   Right now the banner warns but doesn’t say *which file*. Add the `LocalizedError` message to the diagnostics modal by default.

2. **Checksum over canonical input must match loader reality.**
   You updated T-0029 to include `anchors.json`, `wm_ladder.json`, `loc_indication.guard.json`, `validation_rules.json`, `operators.json`. Ensure the **same filenames** are used in:

* Loader
* Checksum
* Tests
* Docs
  Mismatch here will bite later when auditors compare PDF footer hash to the bundle hash.

3. **CI guard for folder reference correctness.**
   Extend `check-target-membership.sh` to assert that the pbxproj contains a folder reference entry with `lastKnownFileType = folder; path = rules;`. Example grep:

```bash
grep -q 'path = rules;.*lastKnownFileType = folder;' ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj/project.pbxproj \
  || { echo "❌ rules folder reference missing or wrong name"; exit 1; }
```

4. **Case-sensitivity trap.**
   Mac dev is usually case-insensitive; iOS reading is effectively case-sensitive at runtime. Lock names to lowercase and enforce with CI (fail on `Rules`, `Operators.JSON`, etc.).

5. **Don’t swallow `DecodingError`.**
   When `JSONDecoder` fails, convert to human text including the keyPath:

```swift
catch let DecodingError.dataCorrupted(ctx) { 
   throw RulesServiceError.decodeFailed(file, ctx.debugDescription)
}
```

6. **Add a one-tap “Verify rules bundle” button** in the Diagnostics modal: lists files, sizes, first 32 bytes of each (hex), and the live SHA256. This gives you proof at the bedside.

---

# Tiny patch you can drop in now

**RulesServiceWrapper.initialize** — replace your preflight with noisy logging:

```swift
private func initialize(bundle: Bundle) async {
    func need(_ name: String) -> URL {
        guard let url = RulesLocator.url(filename: name) else {
            print("❌ Missing \(name) in bundle")
            self.errorMessage = "Missing \(name) in app bundle"
            self.isAvailable = false
            return URL(fileURLWithPath: "/dev/null") // will throw later
        }
        print("✅ Found \(name) at \(url.lastPathComponent)")
        return url
    }

    // Sanity list directory
    dumpRulesDirectory()

    let _ = need("wm_ladder.json")
    let _ = need("loc_indication.guard.json")
    let _ = need("operators.json")

    do {
        self.svc = try RulesService(
            bundle: bundle,
            wmRulesFile: "rules/wm_ladder.json",
            locRulesFile: "rules/loc_indication.guard.json",
            operatorsFile: "rules/operators.json"
        )
        self.isAvailable = true
        self.errorMessage = nil
        self.checksum = RulesChecksum.compute(bundle: bundle)
        print("✅ Rules engine loaded successfully")
    } catch {
        self.isAvailable = false
        self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        print("❌ Rules engine failed:", self.errorMessage ?? "unknown")
    }
}
```

---

# Acceptance check to green

* [ ] **App console** prints `✅ Rules engine loaded successfully`.
* [ ] **Diagnostics modal** shows **Healthy** and lists found files.
* [ ] **LOC rec** appears after changing any severity chip.
* [ ] **Export** button enabled (until you intentionally trip a gate).

If any of those fail after doing the steps above, send me the console lines from `dumpRulesDirectory()` — that will immediately pinpoint whether it’s a folder-reference or filename issue.

Want me to also draft the CI guard additions + pbxproj greps so this never regresses?
