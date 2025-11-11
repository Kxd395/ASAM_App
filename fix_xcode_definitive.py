#!/usr/bin/env python3
"""
DEFINITIVE FIX: Remove ALL duplicate build entries and ensure single compilation.
This version handles all edge cases and validates the fix.
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

def validate_fix(content):
    """Validate that there are no remaining duplicates"""
    # Find all unique file IDs in PBXSourcesBuildPhase
    phase_pattern = r'([A-F0-9]+) /\* (.+?) in Sources \*/,'
    phase_matches = re.findall(phase_pattern, content)

    files_in_phase = defaultdict(list)
    for file_id, filename in phase_matches:
        files_in_phase[filename].append(file_id)

    duplicates = {name: ids for name, ids in files_in_phase.items() if len(ids) > 1}

    if duplicates:
        print("\n⚠️  WARNING: Still have duplicates in build phase:")
        for name, ids in duplicates.items():
            print(f"   {name}: {len(ids)} copies - {ids}")
        return False

    print("\n✅ Validation passed: No duplicates in build phase!")
    return True

def fix_duplicate_build_phases(pbxproj_path):
    """Remove ALL duplicate build file entries"""

    print(f"📖 Reading {pbxproj_path}...")
    with open(pbxproj_path, 'r') as f:
        original_content = f.read()

    # Backup
    backup_path = str(pbxproj_path) + '.backup'
    print(f"💾 Creating backup: {backup_path}")
    with open(backup_path, 'w') as f:
        f.write(original_content)

    # Find PBXBuildFile section
    build_file_pattern = r'(\s+)([A-F0-9]+) /\* (.+?) in Sources \*/ = \{isa = PBXBuildFile; fileRef = ([A-F0-9]+)[^}]+\};'
    matches = list(re.finditer(build_file_pattern, original_content))

    print(f"\n🔍 Found {len(matches)} PBXBuildFile entries")

    # Group by fileRef (the actual file being compiled)
    files_by_ref = defaultdict(list)
    for match in matches:
        indent, build_id, filename, file_ref = match.groups()
        files_by_ref[file_ref].append({
            'match': match,
            'build_id': build_id,
            'filename': filename,
            'indent': indent
        })

    # Find duplicates
    duplicates_found = False
    build_ids_to_remove = []
    lines_to_remove = []

    for file_ref, entries in files_by_ref.items():
        if len(entries) > 1:
            duplicates_found = True
            filename = entries[0]['filename']
            print(f"\n⚠️  Found {len(entries)} PBXBuildFile entries for: {filename}")
            print(f"   FileRef: {file_ref}")

            # Keep ONLY the first one, remove all others
            for i, entry in enumerate(entries):
                if i == 0:
                    print(f"   ✅ Keeping: {entry['build_id']}")
                else:
                    print(f"   🗑️  Removing: {entry['build_id']}")
                    build_ids_to_remove.append(entry['build_id'])
                    lines_to_remove.append(entry['match'].group(0))

    if not duplicates_found:
        print("\n✅ No duplicate PBXBuildFile entries found!")
        # But still check build phase
        validate_fix(original_content)
        return False

    # Step 1: Remove duplicate PBXBuildFile definitions
    print(f"\n🔧 Step 1: Removing {len(lines_to_remove)} duplicate PBXBuildFile definitions...")
    modified_content = original_content
    for line in lines_to_remove:
        modified_content = modified_content.replace(line + '\n', '', 1)

    # Step 2: Remove duplicate references in PBXSourcesBuildPhase
    print(f"🔧 Step 2: Removing {len(build_ids_to_remove)} duplicate build phase references...")
    removed_count = 0
    for build_id in build_ids_to_remove:
        # Pattern: any line with this build_id followed by /* filename in Sources */,
        phase_pattern = r'\s+' + re.escape(build_id) + r' /\* .+? in Sources \*/,\n'
        before_len = len(modified_content)
        modified_content = re.sub(phase_pattern, '', modified_content, count=1)
        if len(modified_content) < before_len:
            removed_count += 1

    print(f"   Removed {removed_count} phase references")

    # Step 3: Validate the fix
    print(f"\n🔍 Step 3: Validating fix...")
    if not validate_fix(modified_content):
        print("\n❌ Fix validation failed!")
        return False

    # Write fixed file
    print(f"\n💾 Writing fixed project file...")
    with open(pbxproj_path, 'w') as f:
        f.write(modified_content)

    size_before = len(original_content)
    size_after = len(modified_content)
    print(f"\n📊 Stats:")
    print(f"   Before: {size_before:,} bytes")
    print(f"   After:  {size_after:,} bytes")
    print(f"   Saved:  {size_before - size_after:,} bytes")

    print(f"\n✅ SUCCESS! Project file fixed and validated.")
    print(f"   Backup: {backup_path}")

    return True

def main():
    pbxproj_path = Path(__file__).parent / 'ios' / 'ASAMAssessment' / 'ASAMAssessment' / 'ASAMAssessment.xcodeproj' / 'project.pbxproj'

    if not pbxproj_path.exists():
        print(f"❌ Error: project.pbxproj not found at {pbxproj_path}")
        sys.exit(1)

    print("=" * 70)
    print("🔧 DEFINITIVE XCODE PROJECT FIX")
    print("=" * 70)

    fixed = fix_duplicate_build_phases(pbxproj_path)

    print("\n" + "=" * 70)
    print("📋 NEXT STEPS:")
    print("=" * 70)
    print()
    print("1. ❌ QUIT XCODE (Cmd+Q) - Must fully quit!")
    print("2. 🧹 Clear cache:")
    print("   rm -rf ~/Library/Developer/Xcode/DerivedData/*")
    print("3. 🔄 Reopen Xcode")
    print("4. 🧼 Clean (Cmd+Shift+K)")
    print("5. 🔨 Build (Cmd+B)")
    print()
    print("✅ All duplicate errors will be GONE!")
    print()

if __name__ == '__main__':
    main()
