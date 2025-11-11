# ASAM Assessment Application

**⚠️ LEGAL NOTICE**: This application is not affiliated with or endorsed by the American Society of Addiction Medicine. See [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) for full IP compliance requirements.

**Production-Ready iOS Application** for Substance Use Disorder Assessment with comprehensive ASAM-aligned criteria, offline capability, and clinical compliance features.

---

## 🎯 Project Status

**Last Updated**: November 11, 2025

- ✅ **BUILD STATUS**: iOS app compiles successfully (**BUILD SUCCEEDED** - Nov 11, 2025)
- ✅ **Core Functionality**: All assessment features working
- ✅ **Requirements Approved**: See [`INDEX.md`](INDEX.md) for complete status
- ✅ **Test Data Created**: 10 synthetic patients covering all scenarios
- ✅ **Legal Framework**: IP compliance guide and prohibited terms list
- ✅ **Quality Fixes**: ASAM compliance and critical build fixes complete
- ✅ **Repository Clean**: All temporary build artifacts archived
- ⏳ **Accessibility**: WCAG 2.1 AA compliance pending

---

## 🚀 Quick Start

### **New to the Project?** Start Here (30 minutes)

1. **[INDEX.md](INDEX.md)** - Single source of truth for all project documentation
2. **[QUICK_START.md](QUICK_START.md)** - Get running immediately  
3. **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Understand organization
4. **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines

### **iOS Development**

1. **Open Project**: `ios/ASAMAssessment/ASAMAssessment/ASAMAssessment.xcodeproj`
2. **Build**: ⌘+B (should succeed with 3 warnings)
3. **Run**: ⌘+R (iOS Simulator or device)
4. **Reference**: [`ios/QUICK_REFERENCE.md`](ios/QUICK_REFERENCE.md)

### **Python Agent CLI**

```bash
# Validate assessment plan
python3 agent/asm.py plan.validate --in data/plan.sample.json

# Calculate plan hash
python3 agent/asm.py plan.hash --in data/plan.sample.json

# Export to PDF (requires Swift CLI build)
bash scripts/build-swift-cli.sh
python3 agent/asm.py pdf.export --plan data/plan.sample.json --pdf assets/template.pdf --out out/plan.pdf
```

---

## 📚 Key Documents

### **Essential Reading**

| Document | Purpose | Priority |
|----------|---------|----------|
| [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) | **READ FIRST** - ASAM IP compliance | 🔴 Critical |
| [`INDEX.md`](INDEX.md) | Master index - Single Source of Truth | 🔴 Critical |
| [`CHANGELOG.md`](CHANGELOG.md) | Version history and changes | 🟢 Reference |

### **Development Guides**

| Document | Purpose |
|----------|---------|
| [`ios/QUICK_REFERENCE.md`](ios/QUICK_REFERENCE.md) | iOS development quick start |
| [`ios/PROJECT_STATUS.md`](ios/PROJECT_STATUS.md) | Current iOS implementation status |
| [`docs/emr-integration.md`](docs/emr-integration.md) | FHIR R4 integration guide |
| [`agent_ops/docs/MASTER_TODO.md`](agent_ops/docs/MASTER_TODO.md) | Current task tracking |

### **Governance & Compliance**

| Document | Purpose |
|----------|---------|
| [`docs/governance/AGENT_CONSTITUTION.md`](docs/governance/AGENT_CONSTITUTION.md) | Core principles and safety rules |
| [`docs/governance/SECURITY.md`](docs/governance/SECURITY.md) | Security requirements |
| [`.github/GITHUB_RULES.md`](.github/GITHUB_RULES.md) | Repository standards |

### **Architecture & Data**

| Document | Purpose |
|----------|---------|
| [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md) | Repository organization |
| [`data/README_TEST_PATIENTS.md`](data/README_TEST_PATIENTS.md) | Test data documentation |
| [`data/README_LOC_REFERENCE.md`](data/README_LOC_REFERENCE.md) | Level of care reference system |

---

## 🏗️ Project Structure

```
ASAM_App/
├── ios/                          # iOS SwiftUI Application
│   └── ASAMAssessment/           # Main iOS project
│       ├── Models/               # Data models (ASAM criteria)
│       ├── Services/             # Business logic & builders
│       ├── Views/                # SwiftUI views
│       └── Utilities/            # Helper functions
├── agent/                        # Python CLI tools
│   └── asm.py                    # Main agent CLI
├── data/                         # Reference data & test cases
│   ├── plan.sample.json          # Sample assessment plan
│   ├── test_patients.json        # 10 synthetic test cases
│   └── loc_reference_neutral.json # Level of care reference
├── docs/                         # Documentation
│   ├── governance/               # Project governance
│   ├── guides/                   # User & developer guides
│   ├── specs/                    # Technical specifications
│   └── archive/                  # Historical documents
├── scripts/                      # Build & automation scripts
├── tools/                        # Utility tools
└── agent_ops/                    # Agent automation framework
    ├── docs/                     # Agent documentation
    ├── rules/                    # Agent operational rules
    └── tools/                    # Agent utilities
```

---

## 📋 Features

### **Assessment Capabilities**

- ✅ **Six ASAM Dimensions**: Comprehensive multi-dimensional assessment
  - Dimension 1: Acute Intoxication/Withdrawal Potential
  - Dimension 2: Biomedical Conditions and Complications
  - Dimension 3: Emotional, Behavioral, or Cognitive Conditions
  - Dimension 4: Readiness to Change
  - Dimension 5: Relapse, Continued Use, or Problem Potential
  - Dimension 6: Recovery/Living Environment
  
- ✅ **Substance Inventory**: Track multiple substances with detailed patterns
- ✅ **Clinical Thresholds**: Evidence-based severity assessment
- ✅ **Skip Logic**: Intelligent question flow based on responses
- ✅ **Traceability**: Complete audit trail of all assessments

### **Technical Features**

- ✅ **Offline Capability**: Full functionality without network
- ✅ **Data Validation**: Comprehensive validation rules
- ✅ **JSON-Based**: Portable, standardized data format
- ✅ **PDF Export**: Generate formatted treatment plans
- ✅ **Hash Verification**: Cryptographic integrity checking
- ✅ **Modular Architecture**: Clean separation of concerns

### **Compliance & Safety**

- ✅ **IP Compliance**: No ASAM trademark usage
- ✅ **Neutral Language**: Generic clinical terminology
- ✅ **Audit Logging**: Complete activity tracking
- ✅ **Legal Framework**: Comprehensive compliance guide
- ⏳ **WCAG 2.1 AA**: Accessibility compliance (in progress)

---

## 🧪 Testing

### **Test Data**

10 synthetic patients covering diverse scenarios:
- Alcohol withdrawal with medical complications
- Polysubstance use with psychiatric comorbidity
- Opioid use in recovery
- Cannabis use with low severity
- Complex cases with multiple risk factors

See [`data/README_TEST_PATIENTS.md`](data/README_TEST_PATIENTS.md) for details.

### **Running Tests**

```bash
# iOS Unit Tests
cd ios/ASAMAssessment/ASAMAssessment
xcodebuild test -scheme ASAMAssessment -destination 'platform=iOS Simulator,name=iPhone 15'

# Python CLI Tests
cd tests
python3 -m pytest
```

---

## 🤝 Contributing

Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) for:
- Code style guidelines
- Commit message conventions
- Pull request process
- Testing requirements

### **Development Workflow**

1. Review [`INDEX.md`](INDEX.md) for current project status
2. Check [`agent_ops/docs/MASTER_TODO.md`](agent_ops/docs/MASTER_TODO.md) for open tasks
3. Follow guidelines in [`CONTRIBUTING.md`](CONTRIBUTING.md)
4. Ensure tests pass before submitting PR
5. Update documentation as needed

---

## 📄 License

See [`LICENSE`](LICENSE) for the full license text.

**Key Points**:
- Open source with attribution requirements
- No ASAM trademark usage permitted
- See [`LEGAL_NOTICE.md`](LEGAL_NOTICE.md) for IP compliance

---

## 📞 Support & Resources

- **Documentation**: [`INDEX.md`](INDEX.md) - Master index to all docs
- **Issues**: Check [`agent_ops/docs/MASTER_TODO.md`](agent_ops/docs/MASTER_TODO.md)
- **Architecture**: [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)
- **Governance**: [`docs/governance/AGENT_CONSTITUTION.md`](docs/governance/AGENT_CONSTITUTION.md)

---

## 📊 Project Statistics

- **iOS Source Files**: 50+ Swift files
- **Python CLI**: 1,200+ lines
- **Test Cases**: 10 synthetic patients
- **Documentation**: 100+ markdown files
- **Build Status**: ✅ **BUILD SUCCEEDED** (Nov 11, 2025)
- **Code Quality**: Production-ready with 3 minor warnings

---

**Last Updated**: November 11, 2025  
**Version**: 1.2.0  
**Status**: Active Development - iOS App Stable
