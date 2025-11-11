#!/usr/bin/env bash
# verify-rules-bundle.sh
# Post-build verification that rules/ folder is packaged correctly
#
# Usage: ./scripts/verify-rules-bundle.sh [app-bundle-path]
# If no path provided, auto-detects from xcodebuild settings

set -euo pipefail

APP="${1:-}"
if [[ -z "${APP}" ]]; then
  echo "🔍 Auto-detecting app bundle path..."
  SETTINGS=$(xcodebuild -project ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj \
             -scheme ASAMAssessment -showBuildSettings 2>/dev/null)
  TARGET_BUILD_DIR=$(awk -F= '/ TARGET_BUILD_DIR / {gsub(/^ +| +$/,"",$2); print $2}' <<<"$SETTINGS")
  WRAPPER_NAME=$(awk -F= '/ WRAPPER_NAME / {gsub(/^ +| +$/,"",$2); print $2}' <<<"$SETTINGS")
  APP="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
fi

echo "🔍 Inspecting bundle: $APP"

if [[ ! -d "$APP" ]]; then
  echo "❌ Bundle not found at: $APP"
  echo "   Run xcodebuild first, or pass the .app path as an argument"
  exit 1
fi

# Canonical file list (must match RulesChecksum.compute)
REQUIRED=(
  "rules/anchors.json"
  "rules/wm_ladder.json"
  "rules/loc_indication.guard.json"
  "rules/validation_rules.json"
  "rules/operators.json"
)

echo ""
echo "Checking canonical rules files:"
MISSING=0
for f in "${REQUIRED[@]}"; do
  if [[ ! -f "$APP/$f" ]]; then
    echo "❌ MISSING: $f"
    MISSING=$((MISSING+1))
  else
    echo "✅ $f"
  fi
done

# Enforce only JSON files in rules/ (no .md, .DS_Store, etc.)
if [[ -d "$APP/rules" ]]; then
  BAD=$(find "$APP/rules" -type f ! -name '*.json' -print 2>/dev/null || true)
  if [[ -n "$BAD" ]]; then
    echo ""
    echo "❌ Non-JSON files found under rules/:"
    echo "$BAD"
    echo "   Only .json files should be packaged in production"
    exit 2
  fi
fi

if [[ $MISSING -gt 0 ]]; then
  echo ""
  echo "❌ rules/ folder reference not packaged correctly"
  echo "   Expected: Blue folder reference in Xcode with subdirectory preservation"
  echo "   Found: Files at bundle root or missing"
  exit 1
fi

echo ""
echo "✅ rules/ folder packaged correctly (blue folder reference)"
exit 0
