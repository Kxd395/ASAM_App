#!/usr/bin/env python3
"""
Fix malformed project.pbxproj lines that have multiple entries concatenated
without proper newlines.
"""

import re
from pathlib import Path

def fix_malformed_lines(pbxproj_path):
    """Split lines that have multiple PBXBuildFile entries concatenated"""

    pbxproj_path = Path(pbxproj_path)

    # Read file
    with open(pbxproj_path, 'r') as f:
        content = f.read()

    # Backup
    backup_path = str(pbxproj_path) + '.backup2'
    with open(backup_path, 'w') as f:
        f.write(content)

    print(f"Created backup: {backup_path}")

    # Pattern: find lines with multiple PBXBuildFile entries
    # These will have multiple occurrences of "= {isa = PBXBuildFile"
    lines = content.split('\n')
    fixed_lines = []
    fixes_applied = 0

    for line in lines:
        # Count how many PBXBuildFile entries are on this line
        entries = line.split(' = {isa = PBXBuildFile')

        if len(entries) > 2:  # More than one entry on this line
            print(f"\n⚠️  Found malformed line with {len(entries)-1} entries:")
            print(f"   Original: {line[:100]}...")

            # Extract the indentation from the original line
            indent = len(line) - len(line.lstrip())
            indent_str = line[:indent]

            # Use regex to find all complete entries
            # Pattern: UUID /* filename */ = {isa = PBXBuildFile; ... };
            entry_pattern = r'([A-F0-9]+\s+/\*[^*]+\*/\s+=\s+\{isa = PBXBuildFile;[^}]+\};)'
            matches = re.findall(entry_pattern, line)

            if matches:
                print(f"   Found {len(matches)} complete entries")
                for match in matches:
                    # Add proper indentation
                    fixed_lines.append(indent_str + match.lstrip())
                fixes_applied += 1
            else:
                # Couldn't parse, keep original
                fixed_lines.append(line)
        else:
            # Normal line, keep as is
            fixed_lines.append(line)

    # Reconstruct content
    fixed_content = '\n'.join(fixed_lines)

    # Write fixed file
    with open(pbxproj_path, 'w') as f:
        f.write(fixed_content)

    print(f"\n✅ Fixed {fixes_applied} malformed lines")
    print(f"   Backup: {backup_path}")

    # Verify
    with open(pbxproj_path, 'r') as f:
        verification = f.read()

    # Check for remaining duplicates
    time_count = verification.count('Time.swift in Sources')
    print("\n📊 Verification:")
    print(f"   Time.swift references: {time_count}")

    return fixes_applied

if __name__ == '__main__':
    pbxproj = '/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj/project.pbxproj'
    fix_malformed_lines(pbxproj)
