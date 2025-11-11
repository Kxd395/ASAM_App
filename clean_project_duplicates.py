#!/usr/bin/env python3
"""
Remove references to deleted duplicate files from project.pbxproj
"""

import re
from pathlib import Path
from collections import defaultdict

def clean_project_file(pbxproj_path):
    """Remove build entries for files that were in the root (wrong location)"""

    pbxproj_path = Path(pbxproj_path)

    # Read file
    with open(pbxproj_path, 'r') as f:
        content = f.read()

    # Backup
    backup_path = str(pbxproj_path) + '.backup3'
    with open(backup_path, 'w') as f:
        f.write(content)

    print(f"✅ Created backup: {backup_path}")

    # Files that were deleted from root (wrong location)
    deleted_files = [
        'ClinicalFlagsSection.swift',
        'ComplianceConfig.swift',
        'DatabaseManager.swift',
        'ExportPreflight.swift',
        'FlagsSection.swift',
        'MDMWipeHandler.swift',
        'NetworkSanityChecker.swift',
        'ReconciliationChecks.swift',
        'RulesDegradedBanner.swift',
        'RulesDiagnosticsView.swift',
        'RulesProvenance.swift',
        'SubstanceRow.swift',
        'SubstanceRowSheet.swift',
        'SubstanceSheet.swift',
        'TokenProvider.swift',
        'UploadQueue.swift',
    ]

    # For each deleted file, find ALL its PBXBuildFile entries
    # Keep only ONE (the one in the correct subdirectory)
    pattern = r'([A-F0-9]+) /\* (.+?) in Sources \*/ = \{isa = PBXBuildFile; fileRef = ([A-F0-9]+)'

    # Group by filename
    files_by_name = defaultdict(list)
    for match in re.finditer(pattern, content):
        build_id, filename, file_ref = match.groups()
        files_by_name[filename].append({
            'build_id': build_id,
            'file_ref': file_ref,
            'match': match.group(0)
        })

    # For each file that had duplicates, keep only first entry
    removed_count = 0
    for filename in deleted_files:
        if filename in files_by_name:
            entries = files_by_name[filename]
            if len(entries) > 1:
                print(f"\n⚠️  {filename} has {len(entries)} entries")
                # Keep first, remove others
                for i, entry in enumerate(entries):
                    if i == 0:
                        print(f"   ✅ Keeping: {entry['build_id']}")
                    else:
                        print(f"   ❌ Removing: {entry['build_id']}")
                        # Remove the PBXBuildFile definition
                        pattern_to_remove = f"{entry['build_id']} /\\* {filename} in Sources \\*/ = {{isa = PBXBuildFile; fileRef = {entry['file_ref']} /\\* {filename} \\*/; }};"
                        content = re.sub(re.escape(pattern_to_remove), '', content)

                        # Remove from build phase
                        phase_pattern = f"{entry['build_id']} /\\* {filename} in Sources \\*/,"
                        content = re.sub(re.escape(phase_pattern), '', content)

                        removed_count += 1

    # Write fixed file
    with open(pbxproj_path, 'w') as f:
        f.write(content)

    print(f"\n✅ Removed {removed_count} duplicate entries")
    print(f"💾 Saved to: {pbxproj_path}")

    # Verify
    for filename in deleted_files:
        count = content.count(f'{filename} in Sources')
        if count > 2:
            print(f"⚠️  WARNING: {filename} still has {count} references (expected 2)")
        elif count == 2:
            print(f"✅ {filename}: {count} references (correct)")

if __name__ == '__main__':
    pbxproj = '/Users/kevindialmb/Downloads/ASAM_App/ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj/project.pbxproj'
    clean_project_file(pbxproj)
