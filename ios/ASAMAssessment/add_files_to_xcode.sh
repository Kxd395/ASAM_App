#!/bin/bash
# Script to add missing essential files to Xcode project
# This uses Xcode's command-line tools for safer integration

PROJECT_DIR="/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment"
XCODEPROJ="$PROJECT_DIR/ASAMAssessment.xcodeproj"

echo "=================================="
echo "Adding Essential Files to Xcode"
echo "=================================="
echo ""

# List of files to add (relative to PROJECT_DIR)
FILES_TO_ADD=(
    "AppDelegate.swift"
    "Views/ContentView.swift"
    "Views/QuestionnaireRenderer.swift"
    "Views/RobustTextField.swift"
    "Views/SettingsView.swift"
    "Services/ASAMService.swift"
    "Services/ASAMDimension1Builder.swift"
    "Services/ASAMDimension3Builder.swift"
    "Services/ASAMSkipLogicEngine.swift"
    "Services/ASAMSubstanceInventoryBuilder.swift"
    "Utilities/TextInputManager.swift"
    "Utilities/TimeUtility.swift"
    "Utils/PDFMetadataScrubber.swift"
    "Diagnostics/SafetyReviewDiagnostic.swift"
)

cd "$PROJECT_DIR" || exit 1

echo "Step 1: Verifying files exist..."
echo "----------------------------------"
missing=0
for file in "${FILES_TO_ADD[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file (MISSING)"
        ((missing++))
    fi
done

echo ""
if [ $missing -gt 0 ]; then
    echo "⚠️  WARNING: $missing files are missing!"
    echo "Please check the files exist before continuing."
    exit 1
fi

echo "✓ All files verified!"
echo ""
echo "Step 2: To add these files to Xcode:"
echo "----------------------------------"
echo "1. Open Xcode with the project"
echo "2. In Xcode, for each folder:"
echo ""
echo "   For ROOT files (AppDelegate.swift):"
echo "   - Right-click 'ASAMAssessment' folder in Navigator"
echo "   - Choose 'Add Files to ASAMAssessment...'"
echo "   - Select: AppDelegate.swift"
echo "   - ✓ Add to targets: ASAMAssessment"
echo "   - ✗ Copy items if needed (uncheck)"
echo ""
echo "   For Views folder:"
echo "   - Right-click 'Views' folder"
echo "   - Choose 'Add Files to ASAMAssessment...'"
echo "   - Select: ContentView.swift, QuestionnaireRenderer.swift,"
echo "             RobustTextField.swift, SettingsView.swift"
echo "   - ✓ Add to targets: ASAMAssessment"
echo "   - ✗ Copy items if needed (uncheck)"
echo ""
echo "   For Services folder:"
echo "   - Right-click 'Services' folder"
echo "   - Choose 'Add Files to ASAMAssessment...'"
echo "   - Select all 5 ASAM*.swift files"
echo "   - ✓ Add to targets: ASAMAssessment"
echo "   - ✗ Copy items if needed (uncheck)"
echo ""
echo "   Repeat for Utilities and Utils folders"
echo ""
echo "=================================="
echo "Files to Add Summary:"
echo "=================================="
for file in "${FILES_TO_ADD[@]}"; do
    echo "  • $file"
done
echo ""
echo "✓ Script complete!"
