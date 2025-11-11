#!/bin/bash
# ASAM_App Restore Point Script
# Created: November 10, 2025 - 9:37:46 PM

set -e

RESTORE_TAG="restore-point-20251110_213746"
RESTORE_COMMIT="ee91ee5"

echo "🔖 ASAM_App Restore Point Manager"
echo "=================================="
echo "Restore Tag: $RESTORE_TAG"
echo "Commit: $RESTORE_COMMIT"
echo ""

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "agent" ] || [ ! -d "ios" ]; then
    echo "❌ Error: Must run from ASAM_App root directory"
    exit 1
fi

# Show current status
echo "📍 Current Status:"
git log --oneline -5
echo ""

echo "🔄 Restoration Options:"
echo "1) Hard reset (DESTRUCTIVE - loses all changes after restore point)"
echo "2) Create new branch from restore point (SAFE)"
echo "3) Show restore point details"
echo "4) Cancel"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo "⚠️  WARNING: This will DESTROY all changes after the restore point!"
        read -p "Type 'CONFIRM' to proceed: " confirm
        if [ "$confirm" = "CONFIRM" ]; then
            echo "🔄 Hard resetting to restore point..."
            git reset --hard $RESTORE_TAG
            echo "✅ Successfully restored to: $RESTORE_TAG"
        else
            echo "❌ Operation cancelled"
        fi
        ;;
    2)
        echo "🌿 Creating new branch from restore point..."
        branch_name="restore-branch-$(date +%Y%m%d_%H%M%S)"
        git checkout -b $branch_name $RESTORE_TAG
        echo "✅ Created and switched to branch: $branch_name"
        echo "📍 You are now on a clean restore point branch"
        ;;
    3)
        echo "📋 Restore Point Details:"
        echo "========================"
        git show --stat $RESTORE_TAG
        echo ""
        echo "📄 Documentation:"
        if [ -f "RESTORE_POINT_20251110_213746.md" ]; then
            head -20 RESTORE_POINT_20251110_213746.md
        fi
        ;;
    4)
        echo "❌ Operation cancelled"
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac