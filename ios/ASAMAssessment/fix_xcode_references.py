#!/usr/bin/env python3

import os
import re
import subprocess

def find_broken_references():
    """Find files referenced in Xcode project but with broken paths"""
    project_file = "/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj/project.pbxproj"
    
    print("🔍 Analyzing Xcode project file for broken references...")
    
    try:
        with open(project_file, 'r') as f:
            content = f.read()
        
        # Find Swift file references
        swift_files = re.findall(r'(\w+\.swift)', content)
        swift_files = list(set(swift_files))  # Remove duplicates
        
        print(f"\n📋 Found {len(swift_files)} Swift files referenced in project:")
        
        project_root = "/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment"
        missing_files = []
        existing_files = []
        
        for swift_file in sorted(swift_files):
            found = False
            # Search for file in common locations
            search_paths = [
                "",
                "Models/",
                "Views/", 
                "Services/",
                "Components/",
                "Utils/",
                "Utilities/",
                "Views/UIKit/"
            ]
            
            for path in search_paths:
                full_path = os.path.join(project_root, path, swift_file)
                if os.path.exists(full_path):
                    existing_files.append(f"{path}{swift_file}")
                    found = True
                    break
            
            if not found:
                missing_files.append(swift_file)
        
        print(f"\n✅ Files found on disk: {len(existing_files)}")
        for f in sorted(existing_files):
            print(f"   {f}")
        
        if missing_files:
            print(f"\n❌ Files missing from disk: {len(missing_files)}")
            for f in sorted(missing_files):
                print(f"   {f}")
        
        return missing_files, existing_files
        
    except Exception as e:
        print(f"❌ Error reading project file: {e}")
        return [], []

def suggest_fixes():
    print(f"\n🔧 To fix 'M' markers in Xcode:")
    print(f"1. Open ASAMAssessment.xcodeproj in Xcode")
    print(f"2. For each file with 'M' marker:")
    print(f"   • Right-click → Delete → Remove Reference")
    print(f"   • Drag the file back from Finder to correct group")
    print(f"3. Alternative: Select all files with 'M' → Delete → Remove Reference")
    print(f"   Then drag the entire folder structure back into Xcode")

if __name__ == "__main__":
    missing, existing = find_broken_references()
    suggest_fixes()
    
    if not missing and existing:
        print(f"\n✅ All files exist on disk - this is purely a Xcode reference issue")
        print(f"   Use the manual steps in Xcode to fix the 'M' markers")