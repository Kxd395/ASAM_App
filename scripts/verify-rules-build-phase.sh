#!/bin/bash
# Build Phase Guard: Verify Rules Bundle Structure
# Prevents shipping app with broken bundle structure
# Add to Build Phases → Run Script (before "Copy Bundle Resources")

set -e  # Exit on error

RULES_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/rules"

echo "🔍 Verifying rules bundle structure..."

# Check if rules folder exists in bundle
if [ ! -d "$RULES_DIR" ]; then
    echo "❌ ERROR: rules/ folder not found in bundle"
    echo "   Expected: $RULES_DIR"
    echo "   This means 'rules' is not added as a blue folder reference."
    echo ""
    echo "Fix:"
    echo "1. Remove yellow 'rules' group (Remove References)"
    echo "2. Add rules/ folder with 'Create folder references' (blue)"
    echo "3. Verify target membership: ASAMAssessment + ASAMAssessmentTests"
    exit 1
fi

# Required files (must match RulesChecksum.compute())
REQUIRED_FILES=(
    "anchors.json"
    "wm_ladder.json"
    "loc_indication.guard.json"
    "validation_rules.json"
    "operators.json"
)

MISSING_FILES=()

for FILE in "${REQUIRED_FILES[@]}"; do
    FILE_PATH="$RULES_DIR/$FILE"
    if [ ! -f "$FILE_PATH" ]; then
        MISSING_FILES+=("$FILE")
    else
        FILE_SIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null || echo "0")
        if [ "$FILE_SIZE" -eq 0 ]; then
            echo "⚠️  WARNING: $FILE is empty (0 bytes)"
        else
            echo "✅ $FILE ($FILE_SIZE bytes)"
        fi
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo ""
    echo "❌ ERROR: Missing required rules files:"
    for FILE in "${MISSING_FILES[@]}"; do
        echo "   - $FILE"
    done
    echo ""
    echo "Expected location: $RULES_DIR"
    echo ""
    echo "Fix:"
    echo "1. Verify files exist in: ios/ASAMAssessment/ASAMAssessment/rules/"
    echo "2. Remove yellow 'rules' group (Remove References)"
    echo "3. Add rules/ folder with 'Create folder references' (blue)"
    echo "4. Check Copy Bundle Resources lists 'rules' (Type: Folder)"
    exit 1
fi

echo "✅ Rules bundle structure verified (${#REQUIRED_FILES[@]} files found)"
exit 0
