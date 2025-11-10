#!/bin/bash
# FIX #12: Validate Xcode target membership for P0 files
# Ensures all new Swift files are properly added to build targets
# Usage: ./scripts/check-target-membership.sh

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

PROJECT_PATH="ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj/project.pbxproj"

echo "🔍 Checking Xcode target membership for P0 files..."

# Required files that must be in app target
REQUIRED_APP_FILES=(
    "Views/SubstanceRowSheet.swift"
    "Views/ClinicalFlagsSection.swift"
    "Services/ExportPreflight.swift"
    "Services/RulesProvenance.swift"
    "Services/ReconciliationChecks.swift"
    "Services/RulesServiceWrapper.swift"
)

# Required files that must be in test target
REQUIRED_TEST_FILES=(
    "ASAMAssessmentTests/P0RulesInputTests.swift"
    "ASAMAssessmentTests/ExportPreflightTests.swift"
    "ASAMAssessmentTests/RulesProvenanceTests.swift"
)

VIOLATIONS=0

# Check if project file exists
if [ ! -f "$PROJECT_PATH" ]; then
    echo "❌ Project file not found: $PROJECT_PATH"
    exit 1
fi

echo "📋 Checking app target files..."
for file in "${REQUIRED_APP_FILES[@]}"; do
    if grep -q "$file" "$PROJECT_PATH"; then
        echo "  ✅ $file"
    else
        echo "  ❌ MISSING: $file"
        VIOLATIONS=$((VIOLATIONS+1))
    fi
done

echo ""
echo "🧪 Checking test target files..."
for file in "${REQUIRED_TEST_FILES[@]}"; do
    if grep -q "$file" "$PROJECT_PATH"; then
        echo "  ✅ $file"
    else
        echo "  ❌ MISSING: $file"
        VIOLATIONS=$((VIOLATIONS+1))
    fi
done

# Check that rules/ directory has dual target membership
echo ""
echo "📁 Checking rules/ directory..."
if grep -q "rules/wm_ladder.json" "$PROJECT_PATH"; then
    echo "  ✅ rules/ directory present"
else
    echo "  ⚠️  rules/ directory may not be in targets"
fi

echo ""
if [ $VIOLATIONS -gt 0 ]; then
    echo "❌ Found $VIOLATIONS missing files in Xcode targets"
    echo ""
    echo "To fix:"
    echo "1. Open ASAMAssessment.xcodeproj in Xcode"
    echo "2. For each missing file:"
    echo "   - Right-click project navigator → Add Files"
    echo "   - OR select file → File Inspector → check 'ASAMAssessment' target"
    echo "3. Run this script again to verify"
    exit 1
fi

echo "✅ All P0 files are properly added to Xcode targets"
exit 0
