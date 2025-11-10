# ASAMPlan POC Constitution

**Governing Document for ASAM Treatment Plan PDF Generation System**

This constitution establishes the non-negotiable principles and standards for developing legally compliant, secure, and maintainable ASAM Treatment Plan software.

---

## Core Principles (NON-NEGOTIABLE)

### I. PHI Protection First (CRITICAL)

**Protected Health Information (PHI) must never leak through technical artifacts.**

**MUST Requirements:**
- NO PHI in filenames — use opaque random IDs only (e.g., `ASAMPlan_a8f4k2j9.pdf`)
- NO PHI in logs, error messages, or console output
- NO PHI in git commits, commit messages, or branch names
- NO PHI in test fixtures or sample data (use dummy data only)
- Signature images are EPHEMERAL — used only for PDF stamping, never persisted beyond export
- Output directory (`out/`) MUST be gitignored
- All generated PDFs MUST be excluded from cloud sync and backups unless explicitly approved by compliance officer

**Rationale:** This is a healthcare application subject to HIPAA regulations. Any PHI leak could result in legal liability, patient harm, and regulatory sanctions.

### II. Legal Compliance (CRITICAL)

**ASAM Treatment Plans are legal documents that may be used in court proceedings.**

**MUST Requirements:**
- Use ONLY the official ASAM Treatment Plan PDF form
- Fill AcroForm fields programmatically — NEVER re-typeset or recreate the form
- Apply cryptographic seal (SHA-256 hash) to ensure document integrity
- Signature stamping must be clear, legible, and properly positioned
- PDF footer must contain the plan hash for verification
- Maintain audit trail of plan versions (via git or structured logging)

**MUST NOT:**
- Modify the official ASAM form layout or design
- Remove or obscure form branding or legal notices
- Create custom treatment plan formats
- Skip cryptographic sealing

**Rationale:** Court admissibility requires using the official form. Any deviation could invalidate the legal standing of the treatment plan.

### III. Deterministic Operations (CRITICAL)

**The same input must always produce the same cryptographic hash.**

**MUST Requirements:**
- JSON encoding MUST use canonical format (sorted keys, consistent separators)
- Hash function MUST be SHA-256
- Field ordering MUST be stable across platforms
- No randomness in hash computation
- Hash MUST be computed BEFORE signature stamping
- Plan JSON MUST be validated before hashing

**Implementation Standard:**
```python
def canonical_bytes(obj) -> bytes:
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode("utf-8")

def plan_hash(plan_obj) -> str:
    return hashlib.sha256(canonical_bytes(plan_obj)).hexdigest()
```

**Rationale:** Deterministic hashing ensures document integrity verification and prevents tampering detection failures.

### IV. Local-First Architecture (CRITICAL)

**This POC operates entirely offline. No network transmission of PHI.**

**MUST Requirements:**
- All processing happens locally on the device
- No API calls transmitting patient data
- No analytics or telemetry containing PHI
- No third-party library dependencies that "phone home"
- SQLite database must be stored locally with proper file protection
- Development and testing must not require internet connectivity

**Rationale:** Offline operation eliminates entire classes of security vulnerabilities and HIPAA compliance concerns.

### V. Zero Secrets in Repository (CRITICAL)

**No credentials, keys, tokens, or sensitive configuration in version control.**

**MUST Requirements:**
- No hardcoded passwords or API keys
- No embedded certificates or keystores
- No PHI or real patient data in test fixtures
- Use environment variables for sensitive configuration
- `.env` files must be gitignored
- Credentials must be documented in secure internal wiki, not in repo

**Rationale:** Accidental credential exposure is a common security vulnerability that can be prevented through strict repository hygiene.

### VI. Code Quality Standards

**Code must be maintainable, testable, and idiomatic.**

**MUST Requirements:**
- Python code follows PEP 8 style guidelines
- Swift code follows Swift API Design Guidelines
- Functions have single responsibility
- Complex logic includes inline comments explaining WHY, not just WHAT
- Magic numbers must be named constants
- Error messages must be actionable and user-friendly
- No commented-out code in main branch

**SHOULD Requirements:**
- Functions should be under 50 lines
- Cyclomatic complexity should be under 10
- Use type hints in Python where beneficial
- Include docstrings for public functions

### VII. Test-First Development

**Tests provide confidence that the system works correctly.**

**MUST Requirements (when tests exist):**
- All tests must pass before merging to main
- Tests must not contain PHI
- Tests must be deterministic (no random failures)
- Test fixtures must be representative of real use cases

**SHOULD Requirements:**
- New features should include unit tests
- Critical workflows should have integration tests
- Validation logic should have comprehensive test coverage
- Hash computation should have determinism tests

**Future Goal:** Achieve 80%+ code coverage for core business logic

---

## Security Requirements

### Data Protection

**File System Security:**
- Development Macs MUST use FileVault encryption
- Repository MUST NOT be placed in cloud-sync folders (Dropbox, iCloud Drive, etc.)
- Generated PDFs in `out/` MUST be deleted after testing
- iOS app data files MUST use Complete File Protection (NSFileProtectionComplete)
- iOS app data MUST be excluded from iCloud backup

**Secure Deletion:**
- Ephemeral signature images MUST be securely deleted after use
- Test PDFs containing dummy PHI MUST be deleted, not just gitignored
- Use `srm` or equivalent secure delete on macOS for sensitive files

### Dependency Security

**MUST Requirements:**
- Python uses standard library only (no external dependencies for POC)
- Swift uses only Apple frameworks (PDFKit, PencilKit)
- No unvetted third-party libraries
- Xcode and Python versions must be documented

**Future Requirements (if adding dependencies):**
- Run `pip audit` or equivalent security scanner
- Pin exact dependency versions
- Review security advisories before updating dependencies

### Incident Response (POC Context)

**If PHI leak detected:**
1. Immediately delete the exposed file securely
2. Rotate any affected test data
3. Review git history for accidental commits
4. Document incident in secure internal wiki
5. Update preventive controls to prevent recurrence

---

## Development Workflow

### File Organization

**MUST Follow:**
```
/agent                # Python CLI for orchestration
/tools/pdf_export     # Swift CLI for PDF manipulation
/assets               # Official PDF template and resources
/data                 # Sample (non-PHI) test data only
/scripts              # Build and automation scripts
/tests                # Unit and integration tests (future)
/out                  # Generated outputs (gitignored)
/docs                 # Documentation (future)
```

**Naming Conventions:**
- JSON keys: lowerCamelCase (e.g., `patientFullName`)
- Python functions: snake_case (e.g., `plan_validate`)
- Swift functions: camelCase (e.g., `fillAcroForm`)
- File constants: UPPER_SNAKE_CASE (e.g., `FORM_FIELD_MAP`)

### Version Control

**MUST Requirements:**
- Every meaningful change updates CHANGELOG.md
- Commit messages follow format: `<type>: <description>`
  - Types: `feat`, `fix`, `docs`, `refactor`, `test`, `security`
  - Example: `security: prevent PHI in error messages`
- No force push to main branch
- Feature branches follow format: `feature/<description>` or `fix/<description>`

**MUST NOT:**
- Commit files in `out/` directory
- Commit `.env` files or credentials
- Commit real patient data or real signatures
- Commit work-in-progress without meaningful message

### Build & Deployment

**MUST Requirements:**
- Swift CLI MUST compile without warnings on latest stable Xcode
- Build script (`scripts/build-swift-cli.sh`) MUST be idempotent
- VS Code tasks MUST have clear names and descriptions
- Build failures MUST provide actionable error messages

**Build Dependencies:**
- Xcode Command Line Tools (minimum version: to be documented)
- Python 3.x (minimum 3.8, documented in README)
- No other external dependencies for POC

### Quality Gates

**Before Merging to Main:**
- [ ] All VS Code tasks execute successfully
- [ ] CHANGELOG.md updated
- [ ] No PHI in any committed files
- [ ] No credentials or secrets in code
- [ ] Code follows style guidelines
- [ ] README accurate and up-to-date

**Before Production Release (Future):**
- [ ] All tests passing
- [ ] Security review completed
- [ ] Documentation updated
- [ ] Official ASAM PDF template verified
- [ ] Compliance officer approval

---

## Schema & Data Standards

### Plan JSON Schema

**MUST Requirements:**
- All required fields defined in `FORM_FIELD_MAP.json`
- Field types strictly enforced (string, array, object, etc.)
- Enum values (like `levelOfCare`) must match ASAM standards
- Dates in ISO 8601 format (YYYY-MM-DD)
- No nullable required fields

**Validation Rules:**
- `patientFullName`: required, non-empty string
- `levelOfCare`: required, must be valid ASAM level (0.5, 1, 2.1, 2.5, 3.1, 3.3, 3.5, 3.7, 4)
- `problems`: required, must be array of problem objects
- Additional validations defined in validator module

### Field Mapping

**MUST Maintain:**
- Single source of truth: `FORM_FIELD_MAP.json`
- Bidirectional mapping: JSON field ↔ PDF AcroForm field
- Version tracking when ASAM form updates
- Documentation of any field transformation logic

---

## Documentation Standards

### Code Documentation

**MUST Include:**
- README.md with quickstart instructions
- Inline comments for non-obvious logic
- Error messages that guide user to resolution
- Security warnings where PHI could be exposed

**SHOULD Include:**
- Architecture decision records (ADRs) for major choices
- API documentation for public functions
- Troubleshooting guide for common issues
- Video walkthrough or screenshots

### Governance Documentation

**MUST Maintain:**
- This Constitution (`.specify/memory/constitution.md`)
- `AGENT_CONSTITUTION.md` (legacy, to be consolidated)
- `FILE_RULES.md` (file organization standards)
- `SECURITY.md` (security policies)
- `PRIVACY.md` (privacy commitments)
- `CHANGELOG.md` (version history)
- `TASKS.md` (current work items)

---

## VS Code Integration Standards

### Task Configuration

**MUST Requirements:**
- All tasks have clear, descriptive labels
- Tasks use full parameter names (no abbreviations)
- Task dependencies properly declared (e.g., Export depends on Build)
- Error output goes to stderr for VS Code problem matcher
- Tasks are idempotent where possible

**Standard Tasks:**
1. **Agent: Scaffold** — Setup directories and structure
2. **Agent: Plan Hash** — Verify deterministic hashing
3. **Agent: Validate** — Quality gate before PDF export
4. **Agent: Build pdf_export** — Compile Swift CLI
5. **Agent: Export PDF** — Full pipeline execution
6. **Agent: Run Tests** (future) — Execute test suite
7. **Agent: Clean** (future) — Remove generated artifacts

### Editor Configuration

**Recommended Extensions:**
- Python extension (for linting and formatting)
- Swift extension (for syntax highlighting)
- Markdown linting (for documentation quality)
- GitLens (for commit history)

**Workspace Settings:**
```json
{
  "files.exclude": {
    "out/": true,
    "**/.DS_Store": true
  },
  "python.linting.enabled": true,
  "editor.formatOnSave": true
}
```

---

## GitHub Repository Standards

### Repository Settings

**MUST Configure:**
- Repository is PRIVATE (never public due to healthcare context)
- Branch protection on `main`:
  - Require pull request reviews
  - Require status checks to pass
  - No force push
  - No deletion
- `.gitignore` includes:
  - `out/`
  - `.env`
  - `.DS_Store`
  - `*.pyc`, `__pycache__/`
  - Xcode build artifacts

### Pull Request Standards

**MUST Include:**
- Clear description of changes
- Reference to related issue or task
- Checklist of quality gates passed
- Screenshots for UI changes (future iOS app)
- Security review for authentication/authorization changes

**PR Template:**
```markdown
## Description
[What changed and why]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Security fix
- [ ] Documentation update
- [ ] Refactoring

## Quality Gates
- [ ] No PHI in changes
- [ ] No secrets committed
- [ ] CHANGELOG.md updated
- [ ] Tests passing (when tests exist)
- [ ] VS Code tasks execute successfully

## Additional Notes
[Any deployment notes, rollback plans, or follow-up tasks]
```

### Issue Tracking

**Labels to Use:**
- `security` — Security vulnerability or PHI risk
- `compliance` — HIPAA or legal compliance issue
- `bug` — Something broken
- `enhancement` — New feature request
- `documentation` — Docs improvement
- `technical-debt` — Code quality improvement

### GitHub Actions (Future)

**Planned CI/CD Pipeline:**
1. **On Push to PR:**
   - Run linters (pylint, swiftlint)
   - Run test suite
   - Check for secrets in code
   - Validate CHANGELOG.md updated

2. **On Merge to Main:**
   - Build Swift CLI
   - Run full integration test
   - Tag release version
   - Generate documentation

---

## Governance & Amendment Process

### Constitution Authority

**This Constitution supersedes:**
- Individual developer preferences
- Informal team agreements
- Undocumented "best practices"
- External coding standards (unless explicitly adopted)

**This Constitution defers to:**
- HIPAA regulations and legal counsel
- ASAM official guidelines
- Apple security best practices (for iOS app)

### Amendment Process

**To amend this Constitution:**
1. Propose change via GitHub issue with `constitution-amendment` label
2. Document rationale and impact analysis
3. Gain consensus from project maintainers
4. Update this document with new version number
5. Update `CHANGELOG.md` with amendment details
6. Communicate changes to all contributors

**Emergency Amendments:**
- Security vulnerabilities may require immediate amendment
- Compliance officer can override for legal/regulatory reasons
- Emergency amendments must be retroactively documented

### Conflict Resolution

**If conflicts arise between documents:**
1. This Constitution has highest authority
2. Legal/regulatory requirements override Constitution
3. Security requirements override feature requirements
4. PHI protection overrides convenience

**If principles conflict:**
1. PHI Protection > Legal Compliance > All Others
2. Security > Performance
3. Correctness > Speed of delivery
4. Simplicity > Cleverness

---

## Compliance Tracking

### Required Reviews

**Security Review Required For:**
- Any change touching PHI handling
- New file I/O operations
- Changes to cryptographic functions
- Addition of external dependencies
- Changes to backup/sync exclusion logic

**Legal Review Required For:**
- Changes to official ASAM form usage
- Modifications to signature workflow
- Changes to audit trail or versioning
- Addition of new data fields to plan

### Audit Trail

**MUST Log:**
- Plan creation and modification events
- PDF export operations
- Validation failures
- Security-relevant errors

**MUST NOT Log:**
- PHI values
- Full plan JSON content
- Signature images
- Patient identifiers

---

## Version History

**Version**: 1.0.0  
**Ratified**: 2025-11-08  
**Last Amended**: 2025-11-08  
**Next Review**: 2025-12-08 (monthly review recommended during POC phase)

**Change History:**
- 1.0.0 (2025-11-08) — Initial constitution merging AGENT_CONSTITUTION.md, FILE_RULES.md, SECURITY.md, PRIVACY.md, and spec-kit best practices

---

## Quick Reference Card

### ✅ MUST DO
- Use opaque IDs for filenames
- Use official ASAM PDF form only
- Compute SHA-256 hash with canonical JSON
- Keep all processing local/offline
- Update CHANGELOG.md for changes
- Use FileVault encryption
- Exclude `out/` from git

### ❌ MUST NOT DO
- Put PHI in filenames, logs, or errors
- Modify official ASAM form layout
- Commit secrets or credentials
- Transmit PHI over network
- Skip cryptographic sealing
- Use non-deterministic hashing
- Commit files to `out/` directory

### 🎯 WHEN IN DOUBT
1. Prioritize PHI protection
2. Consult this Constitution
3. Ask for security review
4. Document your decision
5. Favor simplicity and clarity

---

**This Constitution is a living document. All contributors must read and acknowledge understanding before committing code.**
