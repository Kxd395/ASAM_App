# D4 Decoder Fix - Swift Compatibility ✅

## Issue
D4 questionnaire was failing to load with error:
```
Failed to load questionnaire for domain 4: keyNotFound(CodingKeys(stringValue: "substance_options", intValue: nil)
```

## Root Cause
The Swift `SeverityRatingMetadata` struct requires these fields:
- `severity_cards` (required)
- `substance_options` (required)
- `safety_rules` (required)
- `reference_pages` (optional)

D4 only had `severity_cards`, causing a decoding error.

## Solution
Added the missing required fields to D4's severity_rating question:

```json
{
  "id": "d4_severity_rating",
  "type": "severity_rating",
  "severity_rating": {
    "severity_cards": [...],
    "substance_options": [],      // ✅ Added (empty - not applicable for D4)
    "safety_rules": []             // ✅ Added (empty - D4 has no safety rules)
  }
}
```

## Changes Made

### File Modified
`ios/ASAMAssessment/ASAMAssessment/questionnaires/domains/d4_readiness_neutral.json`
- Version: `2.2.0` → `2.2.2`
- Added `substance_options: []`
- Added `safety_rules: []`

### Why Empty Arrays?

**substance_options**: 
- D1 uses this for withdrawal substance tracking (alcohol, opioids, benzodiazepines, etc.)
- D4 is about readiness to change, not substance-specific withdrawal
- Empty array satisfies Swift decoder without adding unnecessary UI elements

**safety_rules**: 
- D1 has critical safety banners for high severity ratings
- D4 readiness assessment doesn't have the same acute safety concerns
- Empty array satisfies decoder without triggering safety alerts

## Validation Results

✅ JSON syntax valid  
✅ All required fields present  
✅ severity_cards: 5 cards (0-4)  
✅ substance_options: empty array  
✅ safety_rules: empty array  
✅ Structure matches Swift SeverityRatingMetadata decoder requirements  

## Swift Model Reference

```swift
struct SeverityRatingMetadata: Codable {
    let cards: [SeverityCardData]
    let substanceOptions: [SubstanceOption]      // Required
    let safetyRules: [SafetyRule]                // Required
    let referencePages: [String: String]?        // Optional

    enum CodingKeys: String, CodingKey {
        case cards = "severity_cards"
        case substanceOptions = "substance_options"
        case safetyRules = "safety_rules"
        case referencePages = "reference_pages"
    }
}
```

## Testing

**Expected Behavior:**
1. Navigate to Domain 4 in app
2. Questionnaire loads successfully (no error message)
3. All 19 questions + severity rating question display
4. Severity rating shows 5 colored cards (0 None → 4 Very Severe)
5. No substance checkboxes appear (empty array)
6. No safety banners appear (empty array)

---

**Fix Applied**: November 13, 2025  
**Version**: 2.2.2  
**Status**: ✅ Ready for Testing  
**Error**: Resolved - `keyNotFound` decoder error fixed
