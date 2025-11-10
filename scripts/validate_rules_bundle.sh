#!/bin/bash
#
# validate_rules_bundle.sh
# ASAMAssessment Build Phase Script
#
# Validates rules bundle presence and computes checksum
# Fails fast if rules files missing (prevents silent failures in production)
#

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Validating Rules Bundle..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Determine rules directory based on build environment
if [ -n "$TARGET_BUILD_DIR" ]; then
    # Xcode build
    RULES_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/rules"
else
    # Manual testing
    RULES_DIR="$(dirname "$0")/../ios/ASAMAssessment/ASAMAssessment/Resources/rules"
fi

echo "Rules directory: $RULES_DIR"

# Required rules files
REQUIRED_FILES=(
    "wm_ladder.json"
    "loc_indication.guard.json"
    "operators.json"
)

# Check presence of each file
MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    FILE_PATH="$RULES_DIR/$file"
    if [ -f "$FILE_PATH" ]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        MISSING_FILES+=("$file")
    fi
done

# Fail if any files missing
if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ BUILD FAILED: Missing rules files"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Missing: ${MISSING_FILES[*]}"
    echo ""
    echo "Rules files must be present in the bundle for the app to function."
    echo "Add rules/ folder as a blue folder reference in Xcode Resources."
    exit 1
fi

# Compute SHA-256 checksum of all rules files
echo ""
echo "🔐 Computing checksum..."

if [ -d "$RULES_DIR" ]; then
    # Compute combined checksum
    CHECKSUM=$(cat "$RULES_DIR"/*.json | shasum -a 256 | awk '{print $1}')
    SHORT_HASH="${CHECKSUM:0:12}"

    # Write checksum to bundle
    echo "$CHECKSUM" > "$RULES_DIR/rules.bundle.sha256"

    echo "✅ Rules bundle validated: $SHORT_HASH"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ BUILD PASSED: Rules bundle ready"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "⚠️ Rules directory not found in build products"
    echo "This is expected during initial setup. Will validate in app bundle."
fi

exit 0
