#!/bin/bash

# Enhanced Xcode target membership checker
# Checks ALL Swift files in Services/ and Views/ directories

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$REPO_ROOT/ios/ASAMAssessment/ASAMAssessment"
PBXPROJ="$PROJECT_DIR/ASAMAssessment.xcodeproj/project.pbxproj"

echo "🔍 Comprehensive Xcode Target Membership Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Check if pbxproj exists
if [ ! -f "$PBXPROJ" ]; then
    echo "❌ ERROR: project.pbxproj not found at $PBXPROJ"
    exit 1
fi

MISSING_COUNT=0
CHECKED_COUNT=0

# Function to check if file is in pbxproj
check_file() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    
    CHECKED_COUNT=$((CHECKED_COUNT + 1))
    
    if grep -q "$file_name" "$PBXPROJ"; then
        echo "  ✅ $file_path"
        return 0
    else
        echo "  ❌ MISSING: $file_path"
        MISSING_COUNT=$((MISSING_COUNT + 1))
        return 1
    fi
}

echo "📋 Checking Services/ directory..."
for file in "$PROJECT_DIR/Services"/*.swift; do
    if [ -f "$file" ]; then
        rel_path="Services/$(basename "$file")"
        check_file "$rel_path"
    fi
done

echo
echo "📋 Checking Views/ directory..."
for file in "$PROJECT_DIR/Views"/*.swift; do
    if [ -f "$file" ]; then
        rel_path="Views/$(basename "$file")"
        check_file "$rel_path"
    fi
done

echo
echo "🧪 Checking Test files..."
TEST_DIR="$PROJECT_DIR/../ASAMAssessmentTests"
if [ -d "$TEST_DIR" ]; then
    for file in "$TEST_DIR"/*.swift; do
        if [ -f "$file" ]; then
            rel_path="ASAMAssessmentTests/$(basename "$file")"
            check_file "$rel_path"
        fi
    done
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total files checked: $CHECKED_COUNT"
echo "Missing from targets: $MISSING_COUNT"
echo

if [ $MISSING_COUNT -eq 0 ]; then
    echo "✅ All files are properly added to Xcode targets"
    exit 0
else
    echo "❌ Found $MISSING_COUNT missing files in Xcode targets"
    echo
    echo "To fix:"
    echo "1. Open ASAMAssessment.xcodeproj in Xcode"
    echo "2. For each missing file:"
    echo "   - Locate file in Project Navigator"
    echo "   - Select file → File Inspector (right panel)"
    echo "   - Check appropriate target membership box"
    echo "3. Run this script again to verify"
    echo
    echo "See: docs/reviews/XCODE_TARGET_FIX_GUIDE.md"
    exit 1
fi
