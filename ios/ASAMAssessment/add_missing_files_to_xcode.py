#!/usr/bin/env python3
"""
Script to add missing essential Swift files to Xcode project.pbxproj file.
This programmatically modifies the project file to include all necessary files.
"""

import re
import os

# File configurations: (path_in_project, display_name, file_ref_id, build_file_id)
FILES_TO_ADD = [
    ("AppDelegate.swift", "AppDelegate.swift", "80EF00012EC4000000000001", "80EF00012EC4000000000002"),
    ("Views/ContentView.swift", "ContentView.swift", "80EF00012EC4000000000003", "80EF00012EC4000000000004"),
    ("Views/QuestionnaireRenderer.swift", "QuestionnaireRenderer.swift", "80EF00012EC4000000000005", "80EF00012EC4000000000006"),
    ("Views/RobustTextField.swift", "RobustTextField.swift", "80EF00012EC4000000000007", "80EF00012EC4000000000008"),
    ("Services/ASAMService.swift", "ASAMService.swift", "80EF00012EC4000000000009", "80EF00012EC400000000000A"),
    ("Services/ASAMDimension1Builder.swift", "ASAMDimension1Builder.swift", "80EF00012EC400000000000B", "80EF00012EC400000000000C"),
    ("Services/ASAMDimension3Builder.swift", "ASAMDimension3Builder.swift", "80EF00012EC400000000000D", "80EF00012EC400000000000E"),
    ("Services/ASAMSkipLogicEngine.swift", "ASAMSkipLogicEngine.swift", "80EF00012EC400000000000F", "80EF00012EC4000000000010"),
    ("Services/ASAMSubstanceInventoryBuilder.swift", "ASAMSubstanceInventoryBuilder.swift", "80EF00012EC4000000000011", "80EF00012EC4000000000012"),
    ("Utilities/TextInputManager.swift", "TextInputManager.swift", "80EF00012EC4000000000013", "80EF00012EC4000000000014"),
    ("Utilities/TimeUtility.swift", "TimeUtility.swift", "80EF00012EC4000000000015", "80EF00012EC4000000000016"),
    ("Utils/PDFMetadataScrubber.swift", "PDFMetadataScrubber.swift", "80EF00012EC4000000000017", "80EF00012EC4000000000018"),
    ("Views/SettingsView.swift", "SettingsView.swift", "80EF00012EC4000000000019", "80EF00012EC400000000001A"),
    ("Diagnostics/SafetyReviewDiagnostic.swift", "SafetyReviewDiagnostic.swift", "80EF00012EC400000000001B", "80EF00012EC400000000001C"),
]

def read_project_file():
    """Read the project.pbxproj file."""
    path = "/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj/project.pbxproj"
    with open(path, 'r') as f:
        return f.read()

def write_project_file(content):
    """Write the project.pbxproj file."""
    path = "/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj/project.pbxproj"
    # Create backup
    with open(path + ".backup", 'w') as f:
        f.write(content)
    print(f"✓ Created backup: {path}.backup")
    
    with open(path, 'w') as f:
        f.write(content)
    print(f"✓ Updated: {path}")

def add_pbxbuildfile_entries(content):
    """Add PBXBuildFile entries at the beginning of the section."""
    # Find the first PBXBuildFile entry
    match = re.search(r'(/\* Begin PBXBuildFile section \*/\n)', content)
    if not match:
        print("ERROR: Could not find PBXBuildFile section")
        return content
    
    insert_pos = match.end()
    
    entries = []
    for path, name, file_ref, build_id in FILES_TO_ADD:
        # Check if already exists
        if build_id in content:
            print(f"  ⊘ {name} already has PBXBuildFile entry")
            continue
        entry = f"\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {name} */; }};\n"
        entries.append(entry)
        print(f"  + Adding PBXBuildFile entry for {name}")
    
    if entries:
        content = content[:insert_pos] + ''.join(entries) + content[insert_pos:]
    
    return content

def add_pbxfilereference_entries(content):
    """Add PBXFileReference entries."""
    # Find the PBXFileReference section
    match = re.search(r'(/\* Begin PBXFileReference section \*/\n)', content)
    if not match:
        print("ERROR: Could not find PBXFileReference section")
        return content
    
    insert_pos = match.end()
    
    entries = []
    for path, name, file_ref, build_id in FILES_TO_ADD:
        # Check if already exists
        if file_ref in content:
            print(f"  ⊘ {name} already has PBXFileReference entry")
            continue
        entry = f"\t\t{file_ref} /* {name} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};\n"
        entries.append(entry)
        print(f"  + Adding PBXFileReference entry for {name}")
    
    if entries:
        content = content[:insert_pos] + ''.join(entries) + content[insert_pos:]
    
    return content

def add_to_sources_build_phase(content):
    """Add files to the Sources build phase."""
    # Find the main app's Sources build phase (should have many entries)
    pattern = r'(80366E822EC0735E008403F4 /\* Sources \*/ = \{[^}]+files = \(\n)'
    match = re.search(pattern, content)
    
    if not match:
        print("ERROR: Could not find Sources build phase")
        return content
    
    insert_pos = match.end()
    
    entries = []
    for path, name, file_ref, build_id in FILES_TO_ADD:
        # Check if already in build phase
        search_pattern = f"{build_id} /\\* {name} in Sources \\*/"
        if re.search(search_pattern, content):
            print(f"  ⊘ {name} already in Sources build phase")
            continue
        entry = f"\t\t\t\t{build_id} /* {name} in Sources */,\n"
        entries.append(entry)
        print(f"  + Adding {name} to Sources build phase")
    
    if entries:
        content = content[:insert_pos] + ''.join(entries) + content[insert_pos:]
    
    return content

def main():
    print("=" * 70)
    print("Adding Missing Files to Xcode Project")
    print("=" * 70)
    print()
    
    # Read project file
    print("Reading project.pbxproj...")
    content = read_project_file()
    print(f"✓ Read {len(content)} characters")
    print()
    
    # Add PBXBuildFile entries
    print("Step 1: Adding PBXBuildFile entries...")
    content = add_pbxbuildfile_entries(content)
    print()
    
    # Add PBXFileReference entries
    print("Step 2: Adding PBXFileReference entries...")
    content = add_pbxfilereference_entries(content)
    print()
    
    # Add to Sources build phase
    print("Step 3: Adding to Sources build phase...")
    content = add_to_sources_build_phase(content)
    print()
    
    # Write updated file
    print("Writing updated project file...")
    write_project_file(content)
    print()
    
    print("=" * 70)
    print("✓ Complete!")
    print("=" * 70)
    print()
    print("Next steps:")
    print("1. Open Xcode")
    print("2. Clean build folder (Cmd+Shift+K)")
    print("3. Build project (Cmd+B)")
    print()

if __name__ == "__main__":
    main()
