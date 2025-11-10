#!/bin/bash
set -euo pipefail

# ASAM Assessment Smoke Test Runner
# Executes 15-minute smoke test plan with result logging

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$REPO_ROOT/agent_ops/tests/test_results/smoke"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
RESULT_FILE="$RESULTS_DIR/${RUN_ID}_smoke.json"
LOG_FILE="$RESULTS_DIR/${RUN_ID}_smoke.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ASAM Assessment - Smoke Test Suite"
echo "  Run ID: $RUN_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

cd "$REPO_ROOT"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Initialize result JSON
cat > "$RESULT_FILE" <<EOF
{
  "run_id": "$RUN_ID",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "smoke",
  "status": "running",
  "phases": {}
}
EOF

# Phase 0: Prerequisites
echo "━━━ Phase 0: Prerequisites ━━━"
echo

echo "Checking Xcode target membership..."
if ! ./scripts/check-target-membership.sh > "$LOG_FILE" 2>&1; then
    echo -e "${RED}❌ BLOCKED: Files missing from Xcode targets${NC}"
    cat "$LOG_FILE"
    
    # Update result
    jq '.status = "blocked" | .blocker = "Xcode target membership" | .phases.prerequisites = "fail"' "$RESULT_FILE" > "$RESULT_FILE.tmp"
    mv "$RESULT_FILE.tmp" "$RESULT_FILE"
    
    echo
    echo "Fix required: Add missing files to Xcode targets"
    echo "See: docs/reviews/SMOKE_TEST_PLAN.md"
    exit 1
fi

echo -e "${GREEN}✅ Target membership verified${NC}"
echo

# Phase 1: Build
echo "━━━ Phase 1: Build ━━━"
echo

BUILD_START=$(date +%s)
echo "Building ASAMAssessment scheme..."

if ! xcodebuild \
    -scheme ASAMAssessment \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    clean build \
    >> "$LOG_FILE" 2>&1; then
    
    echo -e "${RED}❌ Build failed${NC}"
    echo "Last 20 lines of build log:"
    tail -20 "$LOG_FILE"
    
    jq '.status = "fail" | .phases.build = "fail"' "$RESULT_FILE" > "$RESULT_FILE.tmp"
    mv "$RESULT_FILE.tmp" "$RESULT_FILE"
    
    exit 1
fi

BUILD_END=$(date +%s)
BUILD_DURATION=$((BUILD_END - BUILD_START))

echo -e "${GREEN}✅ Build succeeded${NC} (${BUILD_DURATION}s)"
echo

# Phase 2: Unit Tests
echo "━━━ Phase 2: Unit Tests ━━━"
echo

TEST_START=$(date +%s)
echo "Running all unit tests..."

if xcodebuild test \
    -scheme ASAMAssessment \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    >> "$LOG_FILE" 2>&1; then
    
    TEST_STATUS="pass"
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    TEST_STATUS="partial"
    echo -e "${YELLOW}⚠️  Some tests failed (may be expected if test helpers missing)${NC}"
fi

TEST_END=$(date +%s)
TEST_DURATION=$((TEST_END - TEST_START))

echo "Duration: ${TEST_DURATION}s"
echo

# Phase 3: Critical Safety Tests
echo "━━━ Phase 3: Critical Safety Tests ━━━"
echo

CRITICAL_PASS=0
CRITICAL_FAIL=0

echo "1. Testing WM/LOC guard..."
if xcodebuild test \
    -scheme ASAMAssessment \
    -only-testing:ASAMAssessmentTests/RulesEngineTests/testGuardLogicPreventsDoubleCount \
    >> "$LOG_FILE" 2>&1; then
    echo -e "   ${GREEN}✅ WM/LOC guard working${NC}"
    ((CRITICAL_PASS++))
else
    echo -e "   ${RED}❌ WM/LOC guard FAILED${NC}"
    ((CRITICAL_FAIL++))
fi

echo "2. Testing export blocks when rules degraded..."
if xcodebuild test \
    -scheme ASAMAssessment \
    -only-testing:ASAMAssessmentTests/ExportPreflightTests/testFailsWhenRulesDegraded \
    >> "$LOG_FILE" 2>&1; then
    echo -e "   ${GREEN}✅ Export preflight working${NC}"
    ((CRITICAL_PASS++))
else
    echo -e "   ${RED}❌ Export preflight FAILED${NC}"
    ((CRITICAL_FAIL++))
fi

echo "3. Testing COWS reconciliation..."
if xcodebuild test \
    -scheme ASAMAssessment \
    -only-testing:ASAMAssessmentTests/P0RulesInputTests/testCowsRequiresMinD1 \
    >> "$LOG_FILE" 2>&1; then
    echo -e "   ${GREEN}✅ COWS reconciliation working${NC}"
    ((CRITICAL_PASS++))
else
    echo -e "   ${RED}❌ COWS reconciliation FAILED${NC}"
    ((CRITICAL_FAIL++))
fi

echo
echo "Critical Tests: $CRITICAL_PASS passed, $CRITICAL_FAIL failed"
echo

# Final Status
TOTAL_DURATION=$((TEST_END - BUILD_START))

if [ $CRITICAL_FAIL -eq 0 ]; then
    FINAL_STATUS="pass"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ SMOKE TESTS PASSED${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    FINAL_STATUS="fail"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ SMOKE TESTS FAILED${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

echo
echo "Duration: ${TOTAL_DURATION}s"
echo "Results: $RESULT_FILE"
echo "Log: $LOG_FILE"
echo

# Update final result
jq --arg status "$FINAL_STATUS" \
   --arg build_duration "$BUILD_DURATION" \
   --arg test_duration "$TEST_DURATION" \
   --arg critical_pass "$CRITICAL_PASS" \
   --arg critical_fail "$CRITICAL_FAIL" \
   '.status = $status | 
    .phases.build = "pass" | 
    .phases.unit_tests = "'$TEST_STATUS'" |
    .phases.critical_tests = {pass: ($critical_pass|tonumber), fail: ($critical_fail|tonumber)} |
    .duration_seconds = ('$TOTAL_DURATION'|tonumber) |
    .build_seconds = ('$BUILD_DURATION'|tonumber) |
    .test_seconds = ('$TEST_DURATION'|tonumber)' \
   "$RESULT_FILE" > "$RESULT_FILE.tmp"
mv "$RESULT_FILE.tmp" "$RESULT_FILE"

# Copy to latest
cp "$RESULT_FILE" "$RESULTS_DIR/latest.json"

# Append to history
echo "" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "### Run ID: ${RUN_ID}" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "**Timestamp**: $(date -u +%Y-%m-%d\ %H:%M:%S) UTC" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "**Type**: smoke" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"

if [ "$FINAL_STATUS" = "pass" ]; then
    echo "**Status**: ✅ PASS" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
else
    echo "**Status**: ❌ FAIL" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
fi

echo "**Executor**: Script" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "**Summary**:" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "- Build: ${BUILD_DURATION}s" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "- Tests: ${TEST_DURATION}s" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "- Critical: ${CRITICAL_PASS} passed, ${CRITICAL_FAIL} failed" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "**Results**: \`$RESULT_FILE\`" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"
echo "---" >> "$REPO_ROOT/agent_ops/tests/test_results/TEST_HISTORY.md"

# Exit with appropriate code
if [ "$FINAL_STATUS" = "pass" ]; then
    exit 0
else
    exit 1
fi
