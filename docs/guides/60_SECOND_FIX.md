# 60-SECOND BLUE FOLDER FIX - Quick Start

**Status**: Ready to execute  
**Time**: 60 seconds  
**Benefit**: Fixes "Rules Engine Unavailable" banner

---

## The Problem

Your app bundle can't find `rules/wm_ladder.json` because:
- `rules/` is a **yellow group** (organizational only)
- Files are copied individually to bundle root (flattened)
- `Bundle.url(..., subdirectory:"rules")` returns `nil`

**Note**: Code is now resilient (has fallbacks), but you should still fix the structure properly.

---

## The Fix (60 seconds)

### 1. Delete Yellow Group (10 sec)
- Project navigator → select `rules` (yellow)
- Right-click → Delete → **Remove References**

### 2. Re-add as Blue Folder (20 sec)
- Right-click project → **"Add Files to ASAMAssessment…"**
- Select `ios/ASAMAssessment/ASAMAssessment/rules/` **folder**
- Options:
  - ✅ **Create folder references** (blue icon)
  - ✅ ASAMAssessment target
  - ✅ ASAMAssessmentTests target
- Add

### 3. Verify (10 sec)
- Target → Build Phases → Copy Bundle Resources
- Should see: **rules** (Type: Folder)
- NOT: Individual JSON files

### 4. Clean + Rebuild (20 sec)
- Product → Clean Build Folder (⇧⌘K)
- Delete app from simulator
- Product → Run (⌘R)

---

## Expected Result

### Before:
```
❌ MISSING rules/wm_ladder.json
⚠️ Rules engine degraded
```

### After:
```
✅ rules/wm_ladder.json size=8192
✅ Rules engine loaded successfully
🔒 Rules: v4 [A1B2C3D4E5F6]
```

---

## Verify File Names

Must be **exact** (case-sensitive):
- `wm_ladder.json`
- `loc_indication.guard.json`
- `anchors.json`
- `validation_rules.json`
- `operators.json`

Folder: `rules/` (lowercase)

---

## If Still Failing

Add build-phase guard to get clear error:
1. Target → Build Phases → "+" → Run Script
2. Name: "Verify Rules Bundle"
3. Script: `"${PROJECT_DIR}/scripts/verify-rules-build-phase.sh"`
4. Move before "Copy Bundle Resources"

Build will fail with exact problem if structure wrong.

---

## Documentation

- Full details: `docs/reviews/RESILIENT_RESOLVER_COMPLETE.md`
- Diagnostic probe: `docs/reviews/DIAGNOSTIC_PROBE_ADDED.md`
- Build guard: `scripts/verify-rules-build-phase.sh`

---

**Do it now → 60 seconds → Banner disappears → App works**
