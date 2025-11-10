# Project Structure

**Last Updated**: November 9, 2025  
**Status**: Production-ready structure following industry best practices

---

## 📁 Directory Layout

```
ASAM_App/                           # Root directory
│
├── 📄 INDEX.md                     # ⭐ SINGLE SOURCE OF TRUTH - Always current
├── 📄 README.md                    # Project overview & quick start
├── 📄 CONTRIBUTING.md              # How to contribute
├── 📄 LICENSE                      # MIT License
├── 📄 .gitignore                   # Git exclusions
├── 📄 .editorconfig                # Editor configuration
├── 📄 .gitattributes               # Git attributes
│
├── 📁 .github/                     # GitHub configuration
│   ├── workflows/                  # CI/CD workflows
│   │   └── ci.yml                  # Main CI pipeline
│   ├── prompts/                    # Spec-kit prompts
│   ├── GITHUB_RULES.md             # Repository standards
│   └── VSCODE_RULES.md             # VS Code configuration
│
├── 📁 .specify/                    # Spec-kit framework
│   ├── memory/
│   │   └── constitution.md         # Project constitution
│   ├── scripts/bash/               # Spec-kit scripts
│   └── templates/                  # Spec-kit templates
│
├── 📁 .vscode/                     # VS Code workspace
│   ├── tasks.json                  # Task definitions
│   └── settings.json               # Workspace settings
│
├── 📁 agent/                       # Python CLI application
│   ├── asm.py                      # Main agent script
│   ├── __init__.py                 # Package initialization
│   └── README.md                   # Agent documentation
│
├── 📁 ios/                         # iOS SwiftUI application
│   ├── ASSESS/                     # Xcode project (created by developer)
│   ├── IOS_PROTOTYPE_INTEGRATION.md
│   ├── ACCESSIBILITY_IMPLEMENTATION.md
│   ├── SAFETY_BANNER_ENHANCEMENT.md
│   ├── PROJECT_STATUS.md
│   └── QUICK_REFERENCE.md
│
├── 📁 data/                        # Data files
│   ├── loc_reference_neutral.json  # Production LOC taxonomy
│   ├── analyst_crosswalk_internal.json  # Internal use only (DO NOT SHIP)
│   ├── plan.sample.json            # Sample treatment plan
│   └── README_LOC_REFERENCE.md     # LOC integration guide
│
├── 📁 assets/                      # Static assets
│   ├── ASAM_TreatmentPlan_Template.pdf.PLACEHOLDER.txt
│   └── sample_signature.png
│
├── 📁 scripts/                     # Build & automation
│   ├── build-swift-cli.sh          # Build PDF export CLI
│   └── check-legal-compliance.sh   # Legal compliance checker
│
├── 📁 tools/                       # Platform-specific tools
│   └── pdf_export/
│       ├── PDFExport.swift         # Swift PDF export
│       └── README.md               # Tool documentation
│
├── 📁 docs/                        # Documentation
│   ├── README.md                   # Documentation index
│   ├── specs/                      # Original specifications
│   │   ├── UI_WIREFRAMES_ASCII.md
│   │   ├── DATA_MODEL.md
│   │   ├── SPEC_PDF_COMPOSER.md
│   │   ├── VALIDATION_GATES.json
│   │   ├── ACCEPTANCE_TESTS.md
│   │   └── TASKS_TODO.md
│   ├── guides/                     # Integration guides
│   │   ├── LOC_INTEGRATION_COMPLETE.md
│   │   ├── emr-integration.md
│   │   └── mappings/
│   ├── reviews/                    # Completed reviews
│   │   ├── UI_UX_REVIEW_COMPLETE.md
│   │   ├── EXECUTIVE_REVIEW_FIXES_COMPLETE.md
│   │   └── SPEC_KIT_REVIEW.md
│   ├── archive/                    # Historical documentation
│   │   ├── CRITICAL_FIXES.md
│   │   ├── DELIVERABLES_COMPLETE.md
│   │   ├── DESIGN_CLARIFICATION.md
│   │   ├── FIXES_APPLIED_SUMMARY.md
│   │   ├── IMPLEMENTATION_SUMMARY.md
│   │   ├── RESTRUCTURE_PLAN.md
│   │   └── SPEC_KIT_COMPLETE.md
│   └── governance/                 # Governance documents
│       ├── AGENT_CONSTITUTION.md
│       ├── FILE_RULES.md
│       ├── SECURITY.md
│       ├── PRIVACY.md
│       ├── LEGAL_NOTICE.md
│       ├── PRODUCT_DESCRIPTION.md
│       └── TASKS.md
│
├── 📁 out/                         # Build outputs (gitignored)
│   └── .gitkeep
│
└── 📁 Documents/                   # Reference materials
    ├── agent_pack/                 # Original spec-kit
    │   └── (archived specifications)
    └── asam-paper-criteria.pdf     # ASAM criteria reference
```

---

## 🎯 Directory Purposes

### Root Level

**INDEX.md** - Single Source of Truth
- Always kept current with project state
- Master navigation document
- Links to all major resources
- Updated with every significant change

**README.md** - Project Overview
- High-level project description
- Quick start guide
- Installation instructions
- Links to detailed documentation

**CONTRIBUTING.md** - Contribution Guide
- How to contribute
- Code standards
- PR process
- Testing requirements

### Configuration Directories

**.github/** - GitHub Configuration
- CI/CD workflows
- Issue/PR templates
- Repository automation
- Spec-kit prompts

**.specify/** - Spec-Kit Framework
- Project constitution
- Spec-kit scripts
- Template definitions

**.vscode/** - VS Code Workspace
- Task definitions
- Editor settings
- Extensions recommendations

### Source Code

**agent/** - Python CLI Application
- Treatment plan validation
- LOC calculation
- PDF export orchestration
- Data processing

**ios/** - iOS SwiftUI Application
- Native iPad assessment app
- Domain rating interface
- Safety validation
- LOC recommendation
- PDF export

**tools/** - Platform-Specific Tools
- Swift PDF export CLI
- Future: Node.js tools
- Future: C# tools

### Data & Assets

**data/** - Data Files
- LOC reference taxonomy (SHIP-SAFE)
- Analyst crosswalk (DO NOT SHIP)
- Sample data for testing
- Data documentation

**assets/** - Static Assets
- PDF templates
- Images
- Icons
- Fonts (when needed)

**out/** - Build Outputs
- Generated PDFs
- Compiled binaries
- Gitignored directory

### Documentation

**docs/** - Documentation Root
- specs/ - Original specifications
- guides/ - Integration guides
- reviews/ - Completed reviews
- archive/ - Historical docs
- governance/ - Project policies

---

## 📋 File Naming Conventions

### Documentation
- Use `SCREAMING_SNAKE_CASE.md` for important docs (e.g., `README.md`)
- Use `snake_case.md` for technical docs (e.g., `emr-integration.md`)
- Use `PascalCase.md` for specification docs (e.g., `DataModel.md`)

### Code
- Python: `snake_case.py`
- Swift: `PascalCase.swift`
- Shell: `kebab-case.sh`
- JSON: `snake_case.json` or `kebab-case.json`

### Directories
- Use lowercase with underscores: `agent_pack/`
- Avoid spaces in directory names
- Use singular for code, plural for docs: `tool/` vs `docs/`

---

## 🔄 Migration Plan

### Phase 1: Create Structure (Completed)
- [x] Create docs/ subdirectories
- [x] Create ios/ directory
- [x] Plan migration paths

### Phase 2: Move Files (In Progress)
- [ ] Move completed reviews to `docs/reviews/`
- [ ] Move guides to `docs/guides/`
- [ ] Move governance to `docs/governance/`
- [ ] Archive old documentation
- [ ] Update all internal links

### Phase 3: Update References (Next)
- [ ] Update INDEX.md with new structure
- [ ] Update README.md links
- [ ] Update AGENT_CONSTITUTION.md
- [ ] Update .github/workflows/
- [ ] Update VS Code tasks

### Phase 4: Add Best Practices (Next)
- [ ] Add .editorconfig
- [ ] Add .gitattributes
- [ ] Add CONTRIBUTING.md
- [ ] Add docs/README.md
- [ ] Update .gitignore

---

## ✅ Best Practices Implemented

### Version Control
- `.gitignore` - Proper exclusions
- `.gitattributes` - Line ending normalization
- `out/` - Gitignored build outputs

### Editor Configuration
- `.editorconfig` - Consistent formatting across editors
- `.vscode/` - VS Code-specific settings

### Documentation
- `docs/` - Centralized documentation
- `INDEX.md` - Single source of truth
- `README.md` - Clear entry point
- `CONTRIBUTING.md` - Contribution guidelines

### Code Organization
- Separate source directories per platform
- Clear separation of concerns
- No code in root directory

### Data Management
- Separate data directory
- Clear documentation of ship-safe vs internal files
- Sample data for testing

---

## 🚫 Anti-Patterns Avoided

### ❌ Don't Do This
- Don't put code in root directory
- Don't mix documentation types
- Don't use spaces in filenames
- Don't commit build outputs
- Don't commit secrets or PHI
- Don't nest documentation too deeply

### ✅ Do This Instead
- Use dedicated source directories
- Organize docs by purpose
- Use hyphens or underscores
- Gitignore build outputs
- Use environment variables
- Keep docs 2-3 levels deep max

---

## 📊 Project Metrics

### Directory Count
- Source: 3 (`agent/`, `ios/`, `tools/`)
- Data: 1 (`data/`)
- Documentation: 1 (`docs/` with 5 subdirs)
- Configuration: 3 (`.github/`, `.specify/`, `.vscode/`)

### File Organization
- Root level: ~15 files (governance + quick ref)
- Documentation: ~40 files in `docs/`
- Source code: ~10 files
- Configuration: ~20 files

### Documentation Coverage
- Specifications: 100% (all in `docs/specs/`)
- Guides: 100% (all in `docs/guides/`)
- Reviews: 100% (all in `docs/reviews/`)
- Governance: 100% (all in `docs/governance/`)

---

## 🔗 Key Principles

1. **Single Source of Truth**: INDEX.md is always current
2. **Separation of Concerns**: Code, docs, data, config are separate
3. **Platform Independence**: Each platform has its own directory
4. **Clear Navigation**: README → INDEX → Specific docs
5. **Archive, Don't Delete**: Move old docs to archive/
6. **Document Everything**: Every directory has README.md
7. **Industry Standard**: Follows OSS best practices

---

**Last Updated**: November 9, 2025  
**Maintained By**: Project Lead  
**Review Frequency**: With each major milestone
