#!/usr/bin/env python3
"""
Fix duplicate build phase entries in Xcode project.pbxproj file.
This script removes duplicate file references from the compile sources section.
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

def fix_duplicate_build_phases(pbxproj_path):
    """Remove duplicate build file entries from project.pbxproj"""

    print(f"📖 Reading {pbxproj_path}...")
    with open(pbxproj_path, 'r') as f:
        content = f.read()

    # Find all PBXBuildFile entries
    build_file_pattern = r'(\s+)([A-F0-9]+) /\* (.+?) in Sources \*/ = \{isa = PBXBuildFile;'
    matches = list(re.finditer(build_file_pattern, content))

    print(f"\n🔍 Found {len(matches)} build file entries")

    # Group by filename to find duplicates
    files_by_name = defaultdict(list)
    for match in matches:
        indent, file_id, filename = match.groups()
        files_by_name[filename].append((match, file_id, indent))

    # Find duplicates
    duplicates_found = False
    file_ids_to_remove = []
    entries_to_remove = []

    for filename, entries in files_by_name.items():
        if len(entries) > 1:
            duplicates_found = True
            print(f"\n⚠️  Found {len(entries)} entries for: {filename}")
            # Keep first, mark rest for removal
            for i, (match, file_id, indent) in enumerate(entries[1:], 1):
                print(f"   🗑️  Removing duplicate #{i+1}: {file_id}")
                entries_to_remove.append(match.group(0))
                file_ids_to_remove.append(file_id)

    if not duplicates_found:
        print("\n✅ No duplicates found!")
        return False

    # Backup original
    backup_path = str(pbxproj_path) + '.backup'
    print(f"\n💾 Creating backup: {backup_path}")
    with open(backup_path, 'w') as f:
        f.write(content)

    # Remove duplicates from PBXBuildFile section
    print(f"\n🔧 Removing {len(entries_to_remove)} duplicate PBXBuildFile entries...")
    modified_content = content
    for entry in entries_to_remove:
        modified_content = modified_content.replace(entry + '\n', '', 1)

    # Remove duplicates from PBXSourcesBuildPhase section
    print(f"🔧 Removing {len(file_ids_to_remove)} duplicate build phase references...")
    for file_id in file_ids_to_remove:
        # Remove lines like: "807C8C322EC1897400F7AE37 /* ASAMAssessmentApp.swift in Sources */,"
        phase_pattern = r'\s+' + file_id + r' /\* .+? in Sources \*/,\n'
        modified_content = re.sub(phase_pattern, '', modified_content)

    # Write fixed file
    print("💾 Writing fixed project file...")
    with open(pbxproj_path, 'w') as f:
        f.write(modified_content)

    print(f"\n✅ Fixed! Backup saved to: {backup_path}")
    return True

def main():
    pbxproj_path = Path(__file__).parent / 'ios' / 'ASAMAssessment' / 'ASAMAssessment' / 'ASAMAssessment.xcodeproj' / 'project.pbxproj'

    if not pbxproj_path.exists():
        print(f"❌ Error: project.pbxproj not found at {pbxproj_path}")
        sys.exit(1)

    print("🔧 Xcode Project Duplicate Build Phase Fixer")
    print("=" * 60)

    fixed = fix_duplicate_build_phases(pbxproj_path)

    if fixed:
        print("\n📋 Next steps:")
        print("  1. Open Xcode")
        print("  2. Product → Clean Build Folder (Cmd+Shift+K)")
        print("  3. Product → Build (Cmd+B)")
        print("  4. All duplicate errors should be gone! ✅")
    else:
        print("\n💡 If you're still seeing errors, try:")
        print("  1. Quit Xcode")
        print("  2. rm -rf ~/Library/Developer/Xcode/DerivedData/*")
        print("  3. Reopen Xcode and build")

if __name__ == '__main__':
    main()
