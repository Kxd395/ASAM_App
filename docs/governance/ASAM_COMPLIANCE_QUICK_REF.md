# ASAM IP Compliance - Quick Reference

**Last Updated**: November 10, 2025  
**Current Mode**: Internal Neutral (no license)

---

## 🚦 Compliance Modes

### Internal Neutral (Default)
- ✅ Safe for internal enterprise use
- ✅ No ASAM license required
- ❌ Cannot use ASAM trademarks
- ❌ Cannot distribute to App Store/TestFlight
- ✅ Can distribute internally via MDM

### Licensed ASAM (Requires License)
- ✅ Can use ASAM branding
- ✅ Can use official templates
- ✅ Can distribute publicly
- 📄 Requires license agreement: asamcriteria@asam.org

---

## 🔒 Enforcement Mechanisms

### 1. Build-Time
- **Compliance Gate**: Blocks TestFlight/App Store builds in neutral mode
- **Override**: Set `ALLOW_PUBLIC_DISTRIBUTION_INTERNAL_NEUTRAL=true` for enterprise

### 2. CI/CD
- **asam-guard.yml**: Scans for trademark violations
- **tools/asam_guard.sh**: Local pre-commit validation

### 3. Runtime
- **Export Preflight**: Blocks ASAM templates unless licensed
- **UI Labels**: Auto-switches to neutral terminology
- **PDF Metadata**: Stripped in neutral mode

### 4. Provenance
- **Rules Hash**: SHA256 of all rules, logged on launch
- **PDF Footer**: Contains plan_hash + rules_hash + legal_version
- **Audit Events**: `rules_loaded` event with hash

---

## 📋 Banned Tokens (Neutral Mode)

❌ **NEVER** use in UI/exports when `complianceMode = .internal_neutral`:
- "ASAM"
- "CONTINUUM"
- "CO-Triage"
- Specific dimension names from ASAM books

✅ **USE** neutral alternatives:
- "Domain A", "Domain B" (not "ASAM Dimension 1")
- "Level 2.1" (not "ASAM Level 2.1")
- "Assessment" (not "ASAM Assessment")

---

## 🛠️ Developer Commands

### Check for violations locally
```bash
./tools/asam_guard.sh
```

### Test CI guard
```bash
# Inject test violation
echo "This is an ASAM test" > test_violation.txt
git add test_violation.txt
# Push and watch CI fail
```

### Switch to licensed mode (in code)
```swift
let compliance = ComplianceConfig.shared
try compliance.setLicensedMode(licenseId: "ASAM-2025-0001")
```

### Verify current mode
```swift
print(ComplianceConfig.shared.complianceMode)
// Output: internal_neutral or licensed_asam
```

---

## ✅ Pre-Deployment Checklist

- [ ] Run `./tools/asam_guard.sh` - passes with no violations
- [ ] CI `asam-guard` job passes on latest commit
- [ ] Legal screen accessible at Settings > Legal
- [ ] PDF export shows correct footer (plan + rules + legal version)
- [ ] UI shows "Source: Internal Assessment" (not ASAM)
- [ ] Compliance mode set correctly for deployment target
- [ ] License ID configured if using licensed mode

---

## 📞 Contacts

**For ASAM Licensing**:  
Email: asamcriteria@asam.org  
Purpose: Obtain license to use ASAM branding/templates

**For Technical Issues**:  
See: `agent_ops/docs/ASAM_IP_COMPLIANCE_ENFORCEMENT.md`

---

## 📚 Documentation Links

- Full Implementation Guide: `agent_ops/docs/ASAM_IP_COMPLIANCE_ENFORCEMENT.md`
- Legal Notice: `docs/governance/LEGAL_NOTICE_ASAM.md`
- Citations: `docs/governance/CITATIONS.md`
- Compliance Report: `docs/COMPLIANCE_REPORT.md` (post-implementation)

---

## ⚠️ Common Mistakes

### ❌ Wrong
```swift
// UI Label
Text("ASAM Dimension 1")

// PDF Template
let template = "ASAM_Official_Template.pdf"

// Build for TestFlight in neutral mode
ALLOW_PUBLIC_DISTRIBUTION_INTERNAL_NEUTRAL=false
```

### ✅ Correct
```swift
// UI Label
Text(complianceMode == .internal_neutral ? "Domain A" : "ASAM Dimension 1")

// PDF Template
let template = complianceMode == .internal_neutral 
    ? "Internal_Neutral_Template.pdf" 
    : "ASAM_Official_Template.pdf"

// Build for enterprise MDM in neutral mode
ALLOW_PUBLIC_DISTRIBUTION_INTERNAL_NEUTRAL=true // Enterprise only
```

---

**Remember**: When in doubt, stay in neutral mode. It's always compliant for internal use.
