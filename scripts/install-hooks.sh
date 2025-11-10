#!/usr/bin/env bash
# Install pre-commit and pre-push hooks for ASAM Assessment project
set -euo pipefail

echo "🔧 Installing Git hooks for ASAM Assessment..."

# Verify we're in git repo
if [ ! -d .git ]; then
  echo "❌ Error: Not in a git repository root"
  exit 1
fi

# Make scripts executable
echo "📝 Setting executable permissions..."
chmod +x scripts/check-anchors-vs-map.py 2>/dev/null || true
chmod +x scripts/pre-commit 2>/dev/null || true
chmod +x scripts/pre-push

# Install pre-commit hook
if [ -f scripts/pre-commit ]; then
  echo "🪝 Installing pre-commit hook..."
  ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
  echo "   ✅ pre-commit hook installed"
else
  echo "   ⚠️  scripts/pre-commit not found, skipping"
fi

# Install pre-push hook
if [ -f scripts/pre-push ]; then
  echo "🪝 Installing pre-push hook..."
  ln -sf ../../scripts/pre-push .git/hooks/pre-push
  echo "   ✅ pre-push hook installed"
else
  echo "   ⚠️  scripts/pre-push not found, skipping"
fi

# Verify installation
echo ""
echo "🔍 Verifying installation..."
if [ -L .git/hooks/pre-commit ]; then
  echo "   ✅ pre-commit: $(ls -l .git/hooks/pre-commit | awk '{print $NF}')"
else
  echo "   ⚠️  pre-commit: not installed"
fi

if [ -L .git/hooks/pre-push ]; then
  echo "   ✅ pre-push: $(ls -l .git/hooks/pre-push | awk '{print $NF}')"
else
  echo "   ⚠️  pre-push: not installed"
fi

echo ""
echo "✅ Git hooks installation complete!"
echo ""
echo "📚 Quick Reference:"
echo "   • Pre-commit: Validates anchors when rules/mapping change"
echo "   • Pre-push: Runs iOS tests with -DSTRICT_ANCHORS"
echo "   • Bypass pre-commit: SKIP_HOOKS=1 git commit"
echo "   • Bypass pre-push: SKIP_PREPUSH=1 git push"
echo ""
echo "📖 Full documentation: docs/guides/PRE_PUSH_HOOK_SETUP.md"
echo ""
echo "🧪 Test your hooks:"
echo "   # Test pre-commit (if installed)"
echo "   echo '# test' >> rules/README.md && git add rules/README.md && git commit -m 'Test'"
echo ""
echo "   # Test pre-push"
echo "   echo '# test' >> ios/README.md && git add ios/README.md"
echo "   git commit -m 'Test pre-push' && git push"
echo ""

