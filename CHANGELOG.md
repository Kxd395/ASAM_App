# CHANGELOG.md

## 1.3.0 — 2025-11-13 (Root Cleanup & Development Branch)

### Added — Development Infrastructure
- **Created dev branch** - Safe experimentation branch while preserving stable master for demos
- **Added docs/dev-notes/** - Archive directory for 47 development status files
- **Created dev-notes index** - Comprehensive README.md organizing historical documentation

### Changed — Repository Organization
- **Cleaned root directory** - Moved 47 status/implementation documents to `docs/dev-notes/`
  - All dimension implementation notes (D1-D6)
  - UI/UX fixes (sidebar, navigation, layout)
  - Build and compilation documentation
  - Critical fixes and issue resolution docs
- **Moved scripts** - Relocated `add_files_to_xcode.rb` to `scripts/` directory
- **Updated INDEX.md** - Reflected latest project status with all 6 dimensions working
- **Root hygiene check** - Now passing with only essential files in root

### Fixed — All Dimensions Working
- **D2 and D6 severity ratings** - Added required `text` field to fix decoder errors
- **D3 dual-checkbox pattern** - Implemented AOD-only column with complete ASAM paper form compliance
  - Added `aodOnly` field to HealthIssueSelection model
  - Created dual-checkbox UI with column headers
  - Implemented Rules 1 & 2 (AOD-only => present, unchecking present clears AOD-only)
  - Added category counts showing AOD-only numbers
  - Orange pill indicators and accessibility labels

### Repository Status
- ✅ **Root hygiene passing** - Agent ops check successful
- ✅ **All 6 dimensions working** - D1-D6 with colored severity cards
- ✅ **Development branch ready** - Safe experimentation environment
- ✅ **Documentation archived** - Historical context preserved in dev-notes
- ✅ **Project organized** - Clean structure for ongoing development

### Git Branches
- **master** - Stable demo version (all features working, pushed to origin)
- **dev** - Development branch for experimentation (just created, pushed to origin)

## 1.2.1 — 2025-11-11 (Repository Cleanup & Organization)

### Changed — Repository Structure
- **Cleaned root directory** - Archived 22 temporary build fix documents to `docs/archive/2025-11-build-fixes/`
- **Removed build artifacts** - Deleted RESTORE_POINT directories, backup folders, and temporary scripts
- **Updated .gitignore** - Enhanced to exclude build artifacts, restore points, temporary scripts, and logs
- **Consolidated documentation** - Removed duplicate/corrupted README and CHANGELOG files

### Fixed — Documentation SSOT
- **Updated INDEX.md** - Corrected date to November 11, 2025 and build status to "Build Succeeded"
- **Rewrote README.md** - Clean, comprehensive documentation replacing corrupted version
- **Improved navigation** - All documents now point to INDEX.md as single source of truth

### Removed — Temporary Files
- Build artifacts: `xcodebuild_build.log`, `.xcresult` files
- Restore points: `RESTORE_POINT_20251111_143613/`, `BACKUP_DUPLICATES/`
- Temporary scripts: `fix_*.py`, `clean_*.py`, `add_*.py`, `*.sh` helper scripts
- Duplicate docs: 22 status/fix documents moved to archive
- Test exports: `ASAM_Traceability_Matrix_Export.csv`

### Repository Status
- ✅ **Root directory clean** - Only essential files remain
- ✅ **All documents updated** - Current as of November 11, 2025
- ✅ **SSOT established** - INDEX.md is authoritative reference
- ✅ **Build artifacts excluded** - Comprehensive .gitignore rules
- ✅ **History preserved** - All temporary docs archived, not deleted

## 1.2.0 — 2025-11-11 (Critical Compile Fixes)

### Fixed — iOS Build Critical Errors
- **RulesProvenance.swift** - Fixed all compile-time signature mismatches and platform compatibility issues
  - Added comprehensive `RulesChecksum` struct with SHA256 hash computation and manifest generation  
  - Fixed platform-specific font handling for iOS vs macOS compatibility
  - Corrected `pdfFooterText` method signatures across all call sites
  - Added proper CryptoKit imports for hash computation functionality
- **ExportPreflight.swift** - Updated all test method call signatures for consistency
  - Fixed 6 test methods in `ExportPreflightTests.swift` to match corrected API
  - Added required `provenance`, `complianceMode`, and `templatePath` parameters
  - Ensured all test cases properly exercise the full method signature
- **ObservableObject Imports** - Fixed missing Combine framework imports
  - Added `import Combine` to `QuestionsService.swift`
  - Added `import Combine` to `SeverityScoring.swift`
  - Resolved protocol conformance issues for `ObservableObject`
- **RulesServiceWrapper** - Verified state management implementation
  - Confirmed `RulesState` enum and `rulesState` property implementation
  - Validated state transitions for `.healthy` and `.degraded` modes

### Build Status  
- ✅ **iOS app now compiles successfully** with zero critical errors
- ✅ All signature mismatches resolved
- ✅ Platform compatibility issues addressed  
- ✅ Protocol conformance requirements satisfied
- ⚠️ Minor deprecation warnings remain (non-blocking)

### Technical Impact
- **Resolved show-stopper build failures** preventing iOS app compilation
- **Fixed critical type system issues** that blocked code execution
- **Ensured production build compatibility** across all target platforms
- **Maintained backward compatibility** while fixing forward compatibility issues

## 1.1.0 — 2025-11-08 (Spec-Kit Integration)

### Added — Spec-Kit Framework
- **Spec-Kit v0.0.79** installed and configured
- Added `.github/prompts/` with 8 spec-kit command definitions
- Added `.specify/` directory with templates, scripts, and memory
- Configured for GitHub Copilot integration

### Added — Comprehensive Governance
- **Constitution** (`.specify/memory/constitution.md`) — 650+ lines
  - 7 core principles including PHI protection, legal compliance, deterministic operations
  - Security requirements and data protection standards
  - Development workflow and quality gates
  - Schema and documentation standards
  - VS Code and GitHub integration rules
  - Governance and amendment process
- **GitHub Rules** (`.github/GITHUB_RULES.md`) — 800+ lines
  - Repository configuration and branch protection
  - Commit message and PR standards
  - Issue templates (bug, feature, security)
  - Code owners configuration
  - Release management procedures
  - Compliance and emergency procedures
- **VS Code Rules** (`.github/VSCODE_RULES.md`) — 700+ lines
  - Workspace configuration standards
  - Required and recommended extensions
  - Editor settings by file type
  - Task and debug configuration standards
  - Linting and code quality setup
  - Security and privacy settings

### Added — VS Code Workspace
- **ASAMPlan.code-workspace** — Complete workspace configuration
  - Python formatting (Black, 88 chars)
  - Swift and JSON settings
  - File and search exclusions
  - Extension recommendations
  - Debug launch configurations

### Added — Documentation
- **SPEC_KIT_REVIEW.md** — Comprehensive project analysis (650+ lines)
  - Architecture and security review
  - Code quality assessment
  - Detailed recommendations by priority
- **SPEC_KIT_SUMMARY.md** — Installation and action plan (350+ lines)
  - Phase-by-phase workflow
  - Command reference
  - Configuration guides
- **QUICK_START.md** — Quick reference guide (100+ lines)
  - 5-step quick start
  - Essential commands
  - Known issues
- **SPEC_KIT_COMPLETE.md** — Completion summary
  - What was accomplished
  - Success metrics
  - Next steps

### Changed
- Enhanced project structure with spec-driven development framework
- Improved governance documentation organization
- Added comprehensive security and compliance guidelines

### Security
- Documented PHI protection requirements in Constitution
- Established repository security standards
- Added security issue template and procedures
- Documented emergency response procedures

### Notes
- Total governance documentation: 2,340+ lines
- Ready for spec-driven development workflow
- All existing functionality preserved

---

## 1.0.0 — 2025-11-09 01:42:30 (Initial Release)

### Added
- Initial drop‑in package with Python agent, Swift PDF exporter, VS Code tasks
- Governance docs (constitution, file rules, security, privacy)
- Sample plan JSON and sample signature
