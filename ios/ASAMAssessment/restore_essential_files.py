#!/usr/bin/env python3
"""
Script to add missing essential Swift files to the Xcode project build target.
This ensures all necessary files are included for the app to build and run correctly.
"""

import subprocess
import os
import uuid

# Essential files that need to be in the build target
ESSENTIAL_FILES = [
    ("AppDelegate.swift", "AppDelegate.swift"),
    ("Views/ContentView.swift", "ContentView.swift"),
    ("Views/QuestionnaireRenderer.swift", "QuestionnaireRenderer.swift"),
    ("Views/RobustTextField.swift", "RobustTextField.swift"),
    ("Services/ASAMService.swift", "ASAMService.swift"),
    ("Services/ASAMDimension1Builder.swift", "ASAMDimension1Builder.swift"),
    ("Services/ASAMDimension3Builder.swift", "ASAMDimension3Builder.swift"),
    ("Services/ASAMSkipLogicEngine.swift", "ASAMSkipLogicEngine.swift"),
    ("Services/ASAMSubstanceInventoryBuilder.swift", "ASAMSubstanceInventoryBuilder.swift"),
    ("Utilities/TextInputManager.swift", "TextInputManager.swift"),
    ("Utilities/TimeUtility.swift", "TimeUtility.swift"),
    ("Utils/PDFMetadataScrubber.swift", "PDFMetadataScrubber.swift"),
    ("Views/SettingsView.swift", "SettingsView.swift"),
    ("Diagnostics/SafetyReviewDiagnostic.swift", "SafetyReviewDiagnostic.swift"),
]

def generate_uuid():
    """Generate a unique UUID for Xcode file references."""
    return uuid.uuid4().hex[:24].upper()

def check_file_exists(filepath):
    """Check if a file exists in the ASAMAssessment directory."""
    full_path = os.path.join("ASAMAssessment", filepath)
    exists = os.path.exists(full_path)
    print(f"  {'✓' if exists else '✗'} {filepath}")
    return exists

def main():
    os.chdir("/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment")
    
    print("=" * 70)
    print("iOS Project Restoration - Essential Files Check")
    print("=" * 70)
    print()
    
    print("Checking which essential files exist:")
    print("-" * 70)
    
    existing_files = []
    missing_files = []
    
    for filepath, filename in ESSENTIAL_FILES:
        if check_file_exists(filepath):
            existing_files.append((filepath, filename))
        else:
            missing_files.append((filepath, filename))
    
    print()
    print(f"Summary: {len(existing_files)} files exist, {len(missing_files)} files missing")
    print()
    
    if missing_files:
        print("⚠️  Missing files:")
        for filepath, filename in missing_files:
            print(f"    - {filepath}")
        print()
    
    print("=" * 70)
    print("Next Steps:")
    print("=" * 70)
    print()
    print("To add these files to Xcode project:")
    print("1. Open Xcode")
    print("2. Right-click on the appropriate folder in Project Navigator")
    print("3. Select 'Add Files to ASAMAssessment...'")
    print("4. Select the files from the list above")
    print("5. Make sure 'Copy items if needed' is UNCHECKED")
    print("6. Make sure 'Add to targets: ASAMAssessment' is CHECKED")
    print()
    print("Files to add:")
    for filepath, filename in existing_files:
        print(f"  • {filepath}")
    print()
    
    # Create a reference document
    with open("ESSENTIAL_FILES_CHECKLIST.md", "w") as f:
        f.write("# Essential Files Checklist\n\n")
        f.write("## Files Currently in Build Target\n\n")
        f.write("Run this command to see current files:\n")
        f.write("```bash\n")
        f.write('grep "\\.swift in Sources" ASAMAssessment.xcodeproj/project.pbxproj | grep -v "fileRef\\|isa"\n')
        f.write("```\n\n")
        f.write("## Essential Files That Should Be Added\n\n")
        for filepath, filename in existing_files:
            f.write(f"- [ ] {filepath}\n")
        f.write("\n")
        if missing_files:
            f.write("## Missing Files (Need to be Created or Located)\n\n")
            for filepath, filename in missing_files:
                f.write(f"- [ ] {filepath}\n")
            f.write("\n")
        f.write("## Archived Files (Duplicates)\n\n")
        f.write("The following duplicate files have been moved to `_archived_files/duplicates/`:\n\n")
        f.write("- RulesProvenance.swift (duplicate - kept version in Services/)\n")
        f.write("- RulesServiceWrapper.swift (duplicate - kept version in Services/)\n")
    
    print("✓ Created ESSENTIAL_FILES_CHECKLIST.md")
    print()

if __name__ == "__main__":
    main()
