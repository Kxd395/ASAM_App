#!/bin/bash
#
# Integration Script for Persistence & Progress Bar Fixes
# ASAM Assessment App
# Created: November 11, 2025
#

set -e  # Exit on error

echo "======================================"
echo "ASAM App - Integration Script"
echo "Persistence & Progress Bar Fixes"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/kevindialmb/Downloads/ASAM_App"
cd "$PROJECT_ROOT"

echo -e "${BLUE}Step 1: Verifying Files${NC}"
echo "--------------------------------------"

# Check if key files exist
FILES_TO_CHECK=(
    "ios/ASAMAssessment/ASAMAssessment/Services/ProgressTrackingFix.swift"
    "ios/ASAMAssessment/ASAMAssessmentTests/PersistenceTests.swift"
    "docs/PERSISTENCE_PROGRESS_DEBUGGING.md"
    "docs/PERSISTENCE_PROGRESS_SUMMARY.md"
    "docs/QUICK_REFERENCE_PERSISTENCE_PROGRESS.md"
)

ALL_FILES_EXIST=true
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} Found: $file"
    else
        echo -e "${RED}❌${NC} Missing: $file"
        ALL_FILES_EXIST=false
    fi
done

if [ "$ALL_FILES_EXIST" = false ]; then
    echo -e "\n${RED}ERROR: Not all required files exist!${NC}"
    echo "Please ensure all files are created before running this script."
    exit 1
fi

echo -e "\n${GREEN}✅ All required files found${NC}\n"

echo -e "${BLUE}Step 2: Checking Modified Files${NC}"
echo "--------------------------------------"

MODIFIED_FILES=(
    "ios/ASAMAssessment/ASAMAssessment/Models/Assessment.swift"
    "ios/ASAMAssessment/ASAMAssessment/Views/ContentView.swift"
    "ios/ASAMAssessment/ASAMAssessment/Services/AssessmentStore.swift"
)

for file in "${MODIFIED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} Modified: $file"
        # Show last modification date
        MOD_DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file")
        echo "   Last modified: $MOD_DATE"
    else
        echo -e "${RED}❌${NC} File not found: $file"
    fi
done

echo -e "\n${BLUE}Step 3: Git Status${NC}"
echo "--------------------------------------"
git status --short | head -20

echo -e "\n${BLUE}Step 4: Quick Reference Guide${NC}"
echo "--------------------------------------"
echo "Opening quick reference in default viewer..."
open "docs/QUICK_REFERENCE_PERSISTENCE_PROGRESS.md" 2>/dev/null || echo "Please manually open: docs/QUICK_REFERENCE_PERSISTENCE_PROGRESS.md"

echo -e "\n${YELLOW}⚠️  MANUAL STEPS REQUIRED${NC}"
echo "======================================"
echo ""
echo "The following steps MUST be completed in Xcode:"
echo ""
echo "1. Open Xcode Project:"
echo "   ${GREEN}open ios/ASAMAssessment/ASAMAssessment.xcodeproj${NC}"
echo ""
echo "2. Add ProgressTrackingFix.swift to main target:"
echo "   - Right-click 'Services' folder"
echo "   - Select 'Add Files...'"
echo "   - Choose: Services/ProgressTrackingFix.swift"
echo "   - Check: 'ASAMAssessment' target"
echo ""
echo "3. Add PersistenceTests.swift to test target:"
echo "   - Right-click 'ASAMAssessmentTests' folder"
echo "   - Select 'Add Files...'"
echo "   - Choose: PersistenceTests.swift"
echo "   - Check: 'ASAMAssessmentTests' target"
echo ""
echo "4. Build project: ${GREEN}Cmd+B${NC}"
echo ""
echo "5. Run tests: ${GREEN}Cmd+U${NC}"
echo "   Expected: ${GREEN}15/15 tests pass${NC}"
echo ""
echo "6. Review documentation:"
echo "   - Quick Start: docs/QUICK_REFERENCE_PERSISTENCE_PROGRESS.md"
echo "   - Full Guide: docs/PERSISTENCE_PROGRESS_DEBUGGING.md"
echo "   - Summary: docs/PERSISTENCE_PROGRESS_SUMMARY.md"
echo ""
echo "======================================"
echo -e "${GREEN}✅ Integration script complete${NC}"
echo "======================================"
echo ""
echo "Next: Follow manual steps above to complete integration"
echo ""
