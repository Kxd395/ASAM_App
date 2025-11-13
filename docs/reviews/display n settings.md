
Great screenshots. Here is a blunt checklist of what your Settings screen and the left drawer are missing, plus concrete fixes.

# Settings - what is missing and what to add

**A. Privacy, security, and PHI**

* App lock: Face ID or passcode with auto-lock timer, Require unlock after X minutes, Lock on background.
* PHI screen safety: Blur in app switcher, Block iCloud backup, Screenshot redaction toggle.
* Data retention: Local-only store selector, retention days for drafts, hard delete vs archive.
* Export controls: Include identifiers on PDF yes/no, redact free text yes/no, watermark Draft, include rationale sections yes/no.

**B. Patient and session defaults**

* Required intake fields before starting: Name, DOB, MRN, FIN, Encounter date, Clinician name and credentials, Facility. Let the user set which are required.
* Session naming rule: pattern editor like `{LastName}_{MRN}_{YYYYMMDD}_{HHmm}`.
* Default severity guidance: show guidance cards on by default or compact.
* Default quick responses: manage favorites and order per domain.

**C. Storage and persistence**

* Storage backend picker for the demo: UserDefaults, File based JSON, SQLite. Show storage path and file count.
* Manual backup and restore to .zip, Import assessment JSON, Clear cache, Reset app.
* Autosave interval slider and Save on navigate toggle.

**D. Accessibility and input**

* Reduce motion, Haptics on tap, Dyslexic friendly font toggle, Voice input permission, Always show large radios, Always show keyboard on numeric fields.
* Date format and locale, 12h or 24h time, Units for durations, Big number pad for numeric questions.

**E. Appearance and layout**

* Density: Comfortable or Compact for form rows.
* Show guidance text: Always, On demand, Hidden by default.
* Card expansion: Expand first item only, Remember per section.
* Badge controls: show field keys, show version tags, show counts.

**F. Calculators and clinical helpers**

* Enable CIWA-Ar, COWS, PHQ-9 helpers, ASAM risk matrix links, Show hint chips.
* Emergency banner behavior: allow dismiss, require rationale on dismiss.

**G. Logging and QA**

* Debug mode toggle: show field ids, validation toasts, timing overlay.
* Crash and analytics opt in, Send logs now, Email support with session bundle.

**H. About and legal**

* Version, Build, Commit hash, Config profile, Licenses, Data policy, Terms.

# Left panel and drawer - issues and fixes

**Problems seen**

* Mixed concepts. The left rail mixes navigation sections and domain list in one column and the separate sessions drawer piles on another list. Cognitive load is high.
* Low density and repeated labels. Every row uses a big tile footprint with little information.
* Weak affordances. It is hard to see which item is active, what is filtered, and what actions exist.
* Drafts list covers the content area and does not give context or quick filters.

**Redesign plan**

1. **Three column iPad layout**

   * Column 1: Sessions list. Always visible on large width. Includes Search, filters (Mine, Draft, Completed, Flagged), sort by Updated, severity badges, and quick swipe actions for Duplicate, Export, Delete.
   * Column 2: Assessment navigator. Sections at top (Overview, Problems, LOC, Validation, Export). Domains listed below with small progress rings and severity chips. Collapsible.
   * Column 3: Form content. Sticky header with domain title, patient header chip row, Mark Complete button.

2. **Sessions list content model**

   * Row shows Patient name, MRN, Session ID, Updated time, Status chips: Draft, Sev3, Banner.
   * Tap opens. Long press opens context menu. Swipe right to pin, swipe left to delete.

3. **Domain list improvements**

   * Tiny progress ring and count, severity color dot, optional warning icon when emergency triggers exist.
   * Collapse the section header “Clinical Domains” once a domain is open to give the form more room.

4. **Drawer behavior**

   * Convert the overlay drawer to a true primary column. On small width it becomes a modal with dimming and explicit Close.
   * Provide keyboard shortcuts: Cmd+1 Overview, Cmd+2 Problems, digits 3 to 8 for Domains, Cmd+J open Sessions, Cmd+E export.

5. **Global search**

   * Search bar that finds questions and jumps to them. Results scoped to current session or all sessions.

6. **Patient header**

   * Compact header above the form showing Name, DOB, MRN, FIN, Encounter, Clinician. Edit opens a small sheet.

7. **Validation surfacing**

   * Show a red badge count on Validation in the left rail. Tapping it jumps to the first error.

# Quick action items

* Add Settings sections: Privacy, Patient defaults, Storage, Accessibility, Clinical helpers, Logging, About.
* Implement App Lock, Export controls, Retention, Backup and Import.
* Promote Sessions to the permanent first column with search and filters.
* Reduce left rail density and add severity and progress micro badges.
* Add patient header and global search.

If you want, I can draft a JSON schema for `AppSettings` and a Swift model plus a lightweight Settings screen checklist for your QA pass.



>>>

Great screenshots. What you have now is very barebones: text size, sheet size, theme, two accessibility toggles, and About (version/build). For a clinical assessment app, here is what I consider missing, grouped by priority. I give a default, why it matters, and any pitfalls.

# Must have settings (patient safety, privacy, workflow)

1. App lock and privacy

* Face ID or Touch ID lock, PIN fallback. Default on.
* Auto lock after X minutes of inactivity. Default 5 min.
* Blur app in app switcher. Default on.
  Reason: prevents casual PHI exposure. Pitfall: do not block during active emergency flows.

2. Data retention and purge

* Local data retention window (days). Default 30.
* “Erase all local data” button with double confirmation.
* Redact on export by default. Toggle to include PHI when clinically required.
  Reason: demo mode without EMR still stores PHI. Pitfall: explain exactly what gets wiped.

3. Export defaults

* Default export format (PDF, JSON, both). Default PDF+JSON.
* Default file name template. Example: `ASAM_{MRN}_{SessionID}_{YYYYMMDD_HHMM}`.
* Footer controls: facility logo, disclaimer, reviewer name, version of ASAM content.
* Include severity rationale by default.
  Reason: consistent documentation and audits.

4. Emergency and safety thresholds

* Toggle “Auto emergency banners.” Default on.
* Threshold editor for each dimension trigger. Example: “D3 ideation today = emergency”.
* Option to require rationale on sev 3 or 4. Default on.
  Reason: makes your red flags configurable and auditable.

5. Patient identifiers capture

* Session header defaults: name, DOB, MRN, FIN, encounter date, site.
* Toggle “Require identifiers before assessment.” Default on.
  Reason: your PDFs must link to a patient even in demo mode. Store locally and tag as demo if no EMR.

6. Consent and screenshots

* Capture consent signature required. Default off for demo, on for production.
* Disable screenshots setting for high security environments.
  Reason: compliance guardrail.

# Strongly recommended (quality, speed, accessibility)

7. Language and locale

* App language. Default English. Add Spanish pack toggle.
* Date format and time format. Default device locale.
  Reason: consistent interview flow and bilingual exports.

8. Haptics and sound

* Toggle haptic feedback on key actions. Default on.
* Discreet alert sound on emergency banner. Default off.
  Reason: sensory cues reduce misses. Pitfall: hospital noise policies.

9. Input helpers

* Numeric keypad for number fields. Default on.
* Default Likert style (vertical or horizontal).
* Auto advance on selection. Default on.
  Reason: faster data entry and fewer taps.

10. Quick responses and chips manager

* Enable quick-add chips. Default on.
* Manage lists per question group. Example: withdrawal symptom chips.
* Reset to defaults.
  Reason: teams want to tune their chips without code.

11. Validation strictness

* Mode: Advisory or Strict. Default Advisory for demo.
* Show field codes (like “Field: disorientation”). Default off.
  Reason: trainers like to see internal keys, clinicians do not.

12. Progress and completion rules

* Require severity rating to mark domain complete. Default on.
* Auto complete when all required answered. Default on.
  Reason: prevents half finished PDFs.

13. Autosave and sync behavior

* Autosave interval. Default 1 second debounce.
* Save on navigation toggle. Default on.
* Wi-Fi only sync (future EMR). Default on.
  Reason: deterministic persistence.

# Nice to have (polish, operations, support)

14. Theme and layout

* Font choice (system, open dyslexic).
* Sidebar density (compact, comfy).
* Orientation lock.
  Reason: accessibility and ergonomics.

15. Clinical modules

* Show CIWA and COWS helpers. Default off in demo.
* Show PDMP prompt when opioids selected. Default off in demo.
  Reason: roadmap toggles without forking builds.

16. Organizational profile

* Facility name, logo, address, NPI, contact.
* Default reviewer signature block.
  Reason: makes exports usable instantly.

17. Analytics and crash reporting

* Privacy friendly analytics opt in. Default off.
* Crash logs opt in. Default on device only.
  Reason: meet hospital policies and keep supportable.

18. Developer and QA mode

* Log level.
* Export logs and current assessment JSON.
* Seed demo patients toggle.
* Reset local store.
  Reason: faster triage during pilots.

19. Keyboard and accessibility

* Larger tap targets (already present).
* High contrast (already present).
* Dynamic type overrides for cards and chips.
* VoiceOver hints for severity selections.
  Reason: measurable accessibility gains.

20. Backup and restore of configuration

* Export settings JSON.
* Import settings JSON.
  Reason: roll out identical setups across iPads.

# Suggested Settings structure (keys and defaults)

```json
{
  "security": {
    "biometricLock": true,
    "pinFallback": true,
    "autoLockMinutes": 5,
    "blurInSwitcher": true,
    "allowScreenshots": false
  },
  "patientIdentifiers": {
    "requireBeforeAssessment": true,
    "fields": ["name","dob","mrn","fin","encounterDate","site"]
  },
  "data": {
    "retentionDays": 30,
    "eraseAllLocalButton": true,
    "redactOnExportByDefault": true
  },
  "export": {
    "formats": ["pdf","json"],
    "filenameTemplate": "ASAM_{MRN}_{SessionID}_{YYYYMMDD_HHMM}",
    "includeLogo": true,
    "includeDisclaimers": true,
    "requireRationaleSev>=3": true
  },
  "emergency": {
    "autoBanners": true,
    "thresholds": {
      "d1": ["currentWithdrawal && lastUse<=48h"],
      "d3": ["ideation.today==true","psychosis==true"],
      "d6": ["relationship.weapon||killThreat||mightKill"]
    }
  },
  "ui": {
    "textSize": "system",
    "theme": "system",
    "sheetSize": "comfort",
    "orientationLock": false
  },
  "locale": {
    "language": "en",
    "secondaryLanguage": "es",
    "dateFormat": "device",
    "timeFormat24h": false
  },
  "input": {
    "numericKeypad": true,
    "likertLayout": "horizontal",
    "autoAdvance": true,
    "showFieldCodes": false
  },
  "chips": {
    "enable": true,
    "manageInApp": true
  },
  "validation": {
    "mode": "advisory"
  },
  "progress": {
    "requireSeverityForCompletion": true,
    "autoCompleteWhenValid": true
  },
  "autosave": {
    "debounceMs": 1000,
    "saveOnNavigate": true
  },
  "org": {
    "facilityName": "",
    "logoPath": "",
    "address": "",
    "npi": "",
    "contactPhone": ""
  },
  "qa": {
    "logLevel": "info",
    "exportLogs": true,
    "seedDemoData": false,
    "resetStore": false
  }
}
```

# Placement in the UI

Add these sections to your Settings sheet:

* Privacy and Security
* Patient Identifiers
* Data and Retention
* Export
* Emergency Rules
* Language and Locale
* Input and Validation
* Progress and Completion
* Organization
* Developer and QA
* About

Short toggles on first level, details in subpages for Export, Emergency Rules, and Organization.

# Quick wins to add this week

* App lock, auto lock, blur in switcher
* Require identifiers before starting
* Export defaults and filename template
* Redact on export by default
* Emergency banners toggle and rationale requirement
* Log level and export logs

If you want, I can draft the SwiftUI Settings models and a simple `AppStorage` wiring in the next pass so you can drop it in.

>>>>


