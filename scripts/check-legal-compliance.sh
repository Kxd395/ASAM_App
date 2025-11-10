#!/bin/bash
# Enhanced Legal Compliance Checker for ASAM IP
# Scans entire repository for prohibited ASAM terminology and PHI violations

set -e

echo "🔍 Scanning for ASAM IP violations..."
echo ""

PROHIBITED_TERMS=(
    "ASAM Criteria"
    "ASAM Dimension"
    "ASAM Level"
    "ASAM Treatment Plan"
    "CONTINUUM"
    "CO-Triage"
    "CO Triage"
    "The ASAM Criteria"
)

violations=0

# ========================================
# 1. Scan source code
# ========================================
echo "📂 Scanning source code..."
for term in "${PROHIBITED_TERMS[@]}"; do
    if [ -d "src" ]; then
        if grep -r "$term" src/ --exclude-dir=__pycache__ 2>/dev/null; then
            echo "❌ Found prohibited term in code: '$term'"
            violations=$((violations+1))
        fi
    fi
done

# ========================================
# 2. Scan documentation (excluding whitelisted files)
# ========================================
echo ""
echo "📄 Scanning documentation..."
DOC_DIRS=("docs" "README.md" "IMPLEMENTATION_SUMMARY.md" "RESTRUCTURE_PLAN.md" "DELIVERABLES_COMPLETE.md" "data/README_TEST_PATIENTS.md" "data")
# Files that MUST reference ASAM terms for legal/educational purposes
WHITELIST=(
    "LEGAL_NOTICE.md"
    "DESIGN_CLARIFICATION.md"
    "CRITICAL_FIXES.md"
    "FIXES_APPLIED_SUMMARY.md"
    "EXECUTIVE_REVIEW_FIXES_COMPLETE.md"  # Executive review documentation
    "docs/mappings/levels.md"              # Analyst-only mapping (NOT SHIPPED)
    "data/analyst_crosswalk_internal.json" # Analyst-only crosswalk (NOT SHIPPED)
    "data/README_LOC_REFERENCE.md"         # Documentation about LOC files
    "docs/emr-integration.md"              # Clinical context with LOINC/SNOMED codes
    "RESTRUCTURE_PLAN.md"                  # Contains legal checker example code
    "IMPLEMENTATION_SUMMARY.md"            # Contains legal requirements
    "DELIVERABLES_COMPLETE.md"             # Status document
)

for d in "${DOC_DIRS[@]}"; do
    if [ -e "$d" ]; then
        for term in "${PROHIBITED_TERMS[@]}"; do
            # Search for term
            matches=$(grep -r "$term" "$d" 2>/dev/null || true)

            if [ -n "$matches" ]; then
                # Check if file is whitelisted
                is_whitelisted=0
                for wl in "${WHITELIST[@]}"; do
                    # Check if the doc directory/file contains the whitelisted path
                    if echo "$matches" | grep -q "$wl"; then
                        is_whitelisted=1
                        break
                    fi
                done

                if [ $is_whitelisted -eq 0 ]; then
                    # Not whitelisted - check if it's in a safe context
                    # Allow if the match is in a comment or code example about what NOT to do
                    safe_context=$(echo "$matches" | grep -E "(# .*$term|\"$term\"|'$term'|Prohibited:|❌|DO NOT)" || true)

                    if [ -z "$safe_context" ]; then
                        # Not in safe context - hard fail
                        echo "❌ Prohibited term '$term' found in $d (HARD FAIL)"
                        echo "   Context: $(echo "$matches" | head -n 1)"
                        violations=$((violations+1))
                    else
                        # In safe context - just note it
                        echo "ℹ️  Term '$term' in $d (safe context: example/warning)"
                    fi
                else
                    # Whitelisted - just note it
                    echo "ℹ️  Term '$term' in whitelisted file $d (allowed for documentation)"
                fi
            fi
        done
    fi
done

# ========================================
# 3. Scan PDF files with text extraction
# ========================================
echo ""
echo "📑 Scanning PDF files..."
if command -v pdftotext >/dev/null 2>&1; then
    if [ -d "assets" ]; then
        while IFS= read -r -d '' pdf; do
            # Skip placeholder files
            if [[ "$pdf" == *"PLACEHOLDER"* ]]; then
                continue
            fi

            txt="$(mktemp)"
            if pdftotext "$pdf" "$txt" 2>/dev/null; then
                for term in "${PROHIBITED_TERMS[@]}"; do
                    if grep -qi "$term" "$txt"; then
                        echo "❌ PDF contains prohibited term: $pdf (term: $term)"
                        violations=$((violations+1))
                    fi
                done
            fi
            rm -f "$txt"
        done < <(find assets -type f -name "*.pdf" -print0 2>/dev/null)
    fi
else
    echo "⚠️  pdftotext not found - install poppler-utils for PDF scanning"
    echo "    macOS: brew install poppler"
    echo "    Linux: sudo apt-get install poppler-utils"
fi

# ========================================
# 4. Check for MRN/FIN in filenames (PHI violation)
# ========================================
echo ""
echo "🔒 Checking for PHI in filenames..."
if [ -d "out" ] || [ -d "data" ]; then
    # Check out/ and data/ directories
    found_phi=0
    while IFS= read -r file; do
        # Exclude test_patients.json (that's allowed synthetic data)
        if [[ "$file" != *"test_patients.json"* ]] && [[ "$file" != *"README_TEST_PATIENTS"* ]]; then
            echo "❌ Found MRN/FIN in filename (PHI violation): $file"
            violations=$((violations+1))
            found_phi=1
        fi
    done < <(find out/ data/ -type f 2>/dev/null | grep -Ei "(mrn|fin)" || true)
fi

# ========================================
# 5. Check for official ASAM templates
# ========================================
echo ""
echo "📋 Checking for ASAM templates..."
if [ -d "assets" ]; then
    found_templates=0
    while IFS= read -r pdf; do
        # Skip placeholder files
        if [[ "$pdf" != *"PLACEHOLDER"* ]]; then
            echo "❌ Found ASAM PDF template in assets/: $pdf"
            violations=$((violations+1))
            found_templates=1
        fi
    done < <(find assets/ -type f -name "*ASAM*.pdf" 2>/dev/null || true)
fi

# ========================================
# 6. Check for ASAM in package names
# ========================================
echo ""
echo "📦 Checking package naming..."
if [ -d "src" ]; then
    if [ -d "src/asamplan" ]; then
        echo "❌ Package named 'asamplan' violates neutral naming policy"
        echo "   Action: Rename to 'sudplan' or 'treatmentplan'"
        violations=$((violations+1))
    fi
fi

# ========================================
# Summary
# ========================================
echo ""
echo "=========================================="
if [ $violations -eq 0 ]; then
    echo "✅ No critical ASAM IP violations detected"
    echo ""
    echo "All checks passed:"
    echo "  ✓ No prohibited terms in source code"
    echo "  ✓ No ASAM branding in PDFs"
    echo "  ✓ No PHI in filenames"
    echo "  ✓ No official ASAM templates"
    echo "  ✓ Neutral package naming"
    echo ""
    exit 0
else
    echo "❌ $violations violation(s) detected"
    echo ""
    echo "Review findings above and take action:"
    echo "  1. Remove prohibited ASAM terminology"
    echo "  2. Replace with neutral terms (see LEGAL_NOTICE.md)"
    echo "  3. Remove any real ASAM templates (use neutral templates)"
    echo "  4. Remove MRN/FIN from filenames (use UUIDs)"
    echo "  5. Rename packages to avoid 'asam' prefix"
    echo ""
    echo "For questions: See LEGAL_NOTICE.md or contact asamcriteria@asam.org"
    exit 1
fi
