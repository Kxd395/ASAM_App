#!/usr/bin/env python3

import os
import subprocess
import sys

def find_missing_files():
    """Find files that exist on disk but might have broken references in Xcode"""
    project_root = "/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment"
    
    # Files that commonly have reference issues
    critical_files = [
        "ASAMAssessmentApp.swift",
        "Models/AppSettings.swift", 
        "Models/Assessment.swift",
        "Models/QuestionnaireModels.swift",
        "Models/SubstanceRow.swift",
        "Services/AssessmentStore.swift",
        "Services/QuestionsService.swift",
        "Services/SeverityScoring.swift",
        "Services/RulesService.swift",
        "Services/LOCService.swift",
        "Views/ContentView.swift",
        "Views/SettingsView.swift",
        "Views/QuestionnaireRenderer.swift",
        "Utils/PDFMetadataScrubber.swift",
        "Utils/Time.swift",
        "Utils/ExportUtils.swift"
    ]
    
    missing_files = []
    existing_files = []
    
    for file_path in critical_files:
        full_path = os.path.join(project_root, file_path)
        if os.path.exists(full_path):
            existing_files.append(file_path)
            print(f"✅ Found: {file_path}")
        else:
            missing_files.append(file_path)
            print(f"❌ Missing: {file_path}")
    
    print(f"\n📊 Summary:")
    print(f"   Existing files: {len(existing_files)}")
    print(f"   Missing files: {len(missing_files)}")
    
    return missing_files, existing_files

def suggest_xcode_fixes():
    """Suggest manual steps to fix Xcode references"""
    print(f"\n🔧 To fix missing file references in Xcode:")
    print(f"1. Open ASAMAssessment.xcodeproj in Xcode")
    print(f"2. For each file marked with 'M' (missing):")
    print(f"   - Right-click the file in Project Navigator")
    print(f"   - Choose 'Show in Finder' (if available) or 'Delete'")
    print(f"   - If deleted, drag the file back from Finder to the correct group")
    print(f"3. Alternatively, try Product → Clean Build Folder")
    print(f"4. Then Build the project")

if __name__ == "__main__":
    print("🔍 Scanning for missing file references...")
    missing, existing = find_missing_files()
    suggest_xcode_fixes()