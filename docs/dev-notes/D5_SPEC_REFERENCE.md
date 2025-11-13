# Dimension 5 - Relapse/Continued Use Implementation Reference

## Canonical Naming
- Product copy: **Dimension 5**
- Code prefix: `d5_*`
- File: `d5_relapse_neutral.json`
- Severity enum: `SeverityLevel = 0|1|2|3|4`
- Selected value key: `d5_severity_rating: SeverityLevel`

## Design Tokens (from spec)

### Color Palette
```
COLOR.BG            = #0F1115
COLOR.SURFACE       = #151821
COLOR.SURFACE_ALT   = #1C2030
COLOR.TEXT          = #E6E7EB
COLOR.TEXT_MUTED    = #C7C9D1
COLOR.BORDER        = #2A3042
COLOR.ERROR         = #E53935
COLOR.INFO          = #00B8D9
```

### Severity Colors
```swift
// For iOS implementation
struct D5SeverityTokens {
    static let sev0 = (accent: "#69F0AE", card: "#12321D", cardActive: "#1A4328")
    static let sev1 = (accent: "#AED581", card: "#233417", cardActive: "#2F4720")
    static let sev2 = (accent: "#FFD54F", card: "#3A2E0B", cardActive: "#4A3A0E")
    static let sev3 = (accent: "#FFB74D", card: "#40260B", cardActive: "#503012")
    static let sev4 = (accent: "#EF9A9A", card: "#3B1416", cardActive: "#4B1C20")
}
```

### Chip Colors
```
CHIP.bg             = #202538
CHIP.bgSelected     = #2B3150
CHIP.border         = #354064
```

## Question Schema

### D5.1 - Longest Time Abstinent
```json
{
  "id": "d5_1_longest_abstinent",
  "type": "duration_input",
  "fields": {
    "value": "d5_longest.value",
    "unit": "d5_longest.unit",
    "never_in_recovery": "d5_never_in_recovery"
  },
  "validation": {
    "min": 0,
    "max": 36500
  }
}
```

### D5.2 - What Helped
```json
{
  "id": "d5_2_helped_factors",
  "type": "textarea",
  "conditional": {
    "disabled_when": "d5_never_in_recovery == true",
    "clear_when": "d5_never_in_recovery == true"
  }
}
```

### D5.3 - Relapse Contributors
```json
{
  "id": "d5_3_relapse_contributors",
  "type": "textarea",
  "conditional": {
    "disabled_when": "d5_never_in_recovery == true",
    "clear_when": "d5_never_in_recovery == true"
  }
}
```

### D5.4 - Plan to Quit/Cut Back
```json
{
  "id": "d5_4_plan_tags",
  "type": "multi_select_chips",
  "show_counter": true
}
```

### D5.5 - Consequences if No Help
```json
{
  "id": "d5_5_consequences",
  "type": "textarea"
}
```

### D5.6 - Severity and Imminence
```json
{
  "id": "d5_6_imminence",
  "type": "single_choice",
  "options": [
    "few_or_mild_not_imminent",
    "some_not_severe_weeks_months",
    "many_and_severe_imminent_hours_days"
  ],
  "triggers_banner": "many_and_severe_imminent_hours_days"
}
```

### Self-Report Scales (0-4)
All use enum 0..4 for "Not at all" to "Extremely":
- `d5_scale_craving`
- `d5_scale_social_pressure`
- `d5_scale_emotions`
- `d5_scale_financial`
- `d5_scale_physical`
- `d5_scale_relapse_likelihood`

### Insight
```json
{
  "id": "d5_insight",
  "type": "single_choice",
  "options": ["good", "some", "limited", "dangerously_low"],
  "supervisor_flag_rule": "d5_insight == 'dangerously_low' AND d5_scale_relapse_likelihood >= 3"
}
```

## Severity Rating Structure

Must match D1-D4 pattern exactly:

```json
{
  "id": "d5_severity_rating",
  "text": "SEVERITY RATING - DIMENSION 5 (Relapse, Continued Use, or Continued Problem Potential)",
  "type": "severity_rating",
  "required": true,
  "breadcrumb": "d5_severity_rating",
  "helpText": "Please circle the intensity and urgency of the patient's CURRENT needs for services based on the information collected in Dimension 5",
  "severity_rating": {
    "severity_cards": [
      {
        "rating": 0,
        "title": "0 None",
        "color": "#69F0AE",
        "border": "#4CAF50",
        "icon": "checkmark.circle",
        "bullets": ["..."],
        "disposition": ""
      }
      // ... cards 1-4
    ],
    "substance_options": [],
    "safety_rules": []
  }
}
```

## Destructive Behavior Rules

### Never in Recovery Toggle
When `d5_never_in_recovery` changes to `true`:
1. Show confirm dialog:
   - Title: "Clear related answers?"
   - Body: "This will remove answers in Helped factors and Relapse contributors."
   - Buttons: "Clear and continue", "Cancel"
2. If confirmed, clear:
   - `d5_lastEnded.value`
   - `d5_lastEnded.unit`
   - `d5_helped_factors`
   - `d5_helped_tags`
   - `d5_relapse_contributors`
3. Disable those fields with note: "Not applicable. Patient reports never in recovery."

## Emergency Banner

Triggered when: `d5_imminence == 'many_and_severe_imminent_hours_days'`

Spec:
- Height: 56px
- Background: `COLOR.ERROR` at 12% opacity
- Icon: Warning in `COLOR.ERROR`
- Text: "Imminent risk identified. Follow protocol."
- Buttons: "Open protocol", "Insert note template"
- Dismissible for session, reappears on revisit if still true

## Accessibility Requirements

- Severity card role: `button`
- `aria-pressed` reflects selected state
- Label pattern: `aria-label="Severity 3, Severe. [bullets...] Disposition: [disposition...]"`
- Focus order: header → help link → cards 0-4 → rationale chip → toggles → fields
- Keyboard: 0-4 selects, Enter toggles, Esc collapses rationale
- Banner: `role="alert"`
- Contrast: min 4.5:1 for text, 3:1 for decorative accent chips

## Export/PDF Rules

- Severity chip: number + label, colored with severity accent
- Emergency footnote if banner ever triggered:
  - Dot: 8px, `COLOR.ERROR`
  - Text: "Imminent risk criteria were met in Dimension 5. See protocol notes."

## Implementation Checklist

- [ ] Use exact hex colors from spec (no tints)
- [ ] Cards render 1/2/3 columns per breakpoint
- [ ] Equal card heights with internal scroll if > 320px
- [ ] Rationale chip doesn't push content on first select
- [ ] Never-in-recovery toggle shows confirm dialog
- [ ] Dependent fields clear and disable correctly
- [ ] Banner appears only for imminent state
- [ ] Banner is dismissible and reappears if condition still true
- [ ] Multi-select chips show checkmark + "N selected" counter
- [ ] Autosave batches by section, 600ms debounce
- [ ] Offline queue with exponential backoff
- [ ] PDF includes colored chip and optional emergency footnote
