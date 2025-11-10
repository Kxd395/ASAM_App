# GitHub Repository Rules & Standards

**For: ASAMPlan POC**  
**Effective: 2025-11-08**  
**Authority: Project Constitution v1.0.0**

---

## Repository Configuration

### General Settings

**Required Settings:**
```yaml
Repository Type: Private (REQUIRED for healthcare applications)
Default Branch: main
License: Proprietary (see LICENSE file)
Topics: healthcare, asam, pdf-generation, hipaa-compliant, ios
Description: "ASAM Treatment Plan PDF generation POC for iPad - Private healthcare application"
```

**Visibility:**
- ⛔ **NEVER make this repository public** — Contains healthcare application code
- 🔒 Repository must remain PRIVATE
- 👥 Access by invitation only
- 📝 Maintain access audit log

### Required Files

**MUST be present in repository root:**
- ✅ `.gitignore` — Prevent PHI and secrets from being committed
- ✅ `README.md` — Project overview and quickstart
- ✅ `LICENSE` — Legal protection
- ✅ `CHANGELOG.md` — Version history
- ✅ `.specify/memory/constitution.md` — Governance
- ✅ `SECURITY.md` — Security policies
- ✅ `PRIVACY.md` — Privacy commitments

---

## Branch Protection Rules

### Main Branch Protection

**Settings for `main` branch:**

**Pull Request Requirements:**
- ✅ Require pull request before merging
- ✅ Require 1 approval (increase to 2 for production)
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require review from Code Owners (when CODEOWNERS file exists)

**Status Check Requirements:**
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging

**Additional Restrictions:**
- ✅ Require conversation resolution before merging
- ✅ Do not allow bypassing the above settings
- ✅ Restrict who can push to matching branches (maintainers only)
- ⛔ **No force pushes allowed**
- ⛔ **No branch deletion allowed**

**Signature Verification:**
- 🔐 Require signed commits (recommended for production)

### Feature Branch Naming

**Required Format:**
```
feature/<short-description>   # New features
fix/<issue-number>-<description>  # Bug fixes
security/<description>         # Security fixes
docs/<description>             # Documentation updates
refactor/<description>         # Code refactoring
test/<description>             # Test additions
```

**Examples:**
- ✅ `feature/signature-capture`
- ✅ `fix/123-validation-error`
- ✅ `security/remove-phi-from-logs`
- ✅ `docs/update-quickstart-guide`
- ❌ `dev` (too vague)
- ❌ `johns-branch` (not descriptive)

---

## Commit Standards

### Commit Message Format

**Required Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` — New feature
- `fix` — Bug fix
- `security` — Security fix or PHI protection improvement
- `docs` — Documentation only
- `style` — Code style/formatting (no logic change)
- `refactor` — Code refactoring (no feature change)
- `test` — Adding or updating tests
- `chore` — Maintenance tasks
- `perf` — Performance improvement

**Scope (optional):**
- `agent` — Python CLI
- `pdf-export` — Swift PDF export
- `validation` — Data validation
- `build` — Build scripts
- `tasks` — VS Code tasks

**Examples:**
```bash
# Good commits
feat(agent): add comprehensive plan validation
fix(pdf-export): correct signature position on page 3
security(agent): prevent PHI in error messages
docs: update README with new task workflow
refactor(validation): extract field validation to separate function
test(agent): add deterministic hash tests

# Bad commits
❌ "fixed stuff"
❌ "WIP"
❌ "update"
❌ "asdfasdf"
```

### Commit Requirements

**MUST:**
- ✅ Write clear, descriptive commit messages
- ✅ Update CHANGELOG.md for user-facing changes
- ✅ Keep commits focused on single concern
- ✅ Reference issue numbers when applicable (`Fixes #123`)

**MUST NOT:**
- ❌ Commit PHI or real patient data
- ❌ Commit secrets, API keys, or credentials
- ❌ Commit files from `out/` directory
- ❌ Commit `.env` files
- ❌ Use generic messages like "update" or "fix"

---

## .gitignore Standards

**Required .gitignore entries:**

```gitignore
# Generated outputs (MAY CONTAIN PHI)
out/
*.pdf

# Environment and secrets
.env
.env.local
.env.*.local
secrets/
credentials/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
venv/
ENV/
env/

# Swift / Xcode
.DS_Store
xcuserdata/
*.xcworkspace/xcuserdata/
*.mode1v3
*.mode2v3
*.perspectivev3
*.pbxuser
!default.pbxuser
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM
.build/

# VS Code
.vscode/settings.json
.vscode/tasks.json
.vscode/launch.json
.vscode/extensions.json
*.code-workspace
.history/

# macOS
.DS_Store
.AppleDouble
.LSOverride
Icon
._*
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.nox/

# IDE
.idea/
*.swp
*.swo
*~
.project
.classpath
.settings/
.vscode/
```

---

## Pull Request Standards

### PR Title Format

**Format:**
```
<type>: <description>
```

**Examples:**
- ✅ `feat: Add signature validation to PDF export`
- ✅ `fix: Resolve hash computation inconsistency`
- ✅ `security: Remove PHI from debug output`
- ❌ `Update code`
- ❌ `PR #123`

### PR Description Template

**Create `.github/PULL_REQUEST_TEMPLATE.md`:**

```markdown
## Description
<!-- Provide a clear description of what this PR does and why -->

## Type of Change
<!-- Check all that apply -->
- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 🔒 Security fix (addresses security vulnerability or PHI risk)
- [ ] 📝 Documentation update
- [ ] ♻️ Refactoring (no functional changes)
- [ ] ⚡ Performance improvement
- [ ] 🧪 Test addition/update
- [ ] 🔨 Build/tooling change

## Related Issues
<!-- Link to related issues: Fixes #123, Closes #456 -->

## Changes Made
<!-- Bullet list of specific changes -->
- 
- 

## Testing Performed
<!-- Describe how you tested these changes -->
- [ ] All VS Code tasks execute successfully
- [ ] Manual testing completed
- [ ] Unit tests added/updated (if applicable)
- [ ] Integration test completed

## Security Checklist
<!-- REQUIRED for all PRs -->
- [ ] No PHI in filenames
- [ ] No PHI in logs or error messages
- [ ] No PHI in test data or fixtures
- [ ] No secrets or credentials committed
- [ ] No real patient data used
- [ ] Output files properly gitignored

## Quality Gates
<!-- REQUIRED before approval -->
- [ ] CHANGELOG.md updated (if user-facing change)
- [ ] Code follows style guidelines
- [ ] Documentation updated (if needed)
- [ ] No new linter warnings
- [ ] Commit messages follow standards

## Screenshots / Videos
<!-- If applicable, add screenshots or demo videos -->

## Additional Notes
<!-- Any deployment notes, rollback plans, or follow-up work -->

## Reviewer Checklist
<!-- For reviewer use -->
- [ ] Code review completed
- [ ] Security review completed (if applicable)
- [ ] No PHI detected in changes
- [ ] Changes align with Constitution
- [ ] CHANGELOG.md entry is clear
```

### PR Review Process

**Review Requirements:**

**All PRs Must Have:**
1. ✅ Clear description of changes
2. ✅ All quality gates passed
3. ✅ At least 1 approval from maintainer
4. ✅ Conversation threads resolved
5. ✅ CI checks passing (when implemented)

**Security-Sensitive PRs (require extra review):**
- Changes to PHI handling
- Modifications to cryptographic functions
- Changes to file I/O operations
- Addition of external dependencies
- Changes to `.gitignore` or security policies

**Reviewer Responsibilities:**
- 🔍 Check for PHI in code or comments
- 🔍 Verify no secrets committed
- 🔍 Ensure CHANGELOG.md updated
- 🔍 Verify code follows Constitution
- 🔍 Check for security implications
- 🔍 Validate commit message format

---

## Issue Templates

### Bug Report Template

**Create `.github/ISSUE_TEMPLATE/bug_report.md`:**

```markdown
---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description
<!-- Clear and concise description of the bug -->

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior
<!-- What should happen -->

## Actual Behavior
<!-- What actually happens -->

## Environment
- OS: [e.g., macOS 14.0]
- Python Version: [e.g., 3.11.0]
- Xcode Version: [e.g., 15.0]
- VS Code Version: [e.g., 1.85.0]

## Screenshots / Logs
<!-- Add screenshots or sanitized logs (NO PHI!) -->

## Severity
- [ ] Critical (system unusable, data loss risk, PHI leak)
- [ ] High (major feature broken)
- [ ] Medium (feature partially broken)
- [ ] Low (minor inconvenience)

## Security Impact
- [ ] This bug could expose PHI
- [ ] This bug affects data integrity
- [ ] No security impact

## Additional Context
<!-- Any other relevant information -->
```

### Feature Request Template

**Create `.github/ISSUE_TEMPLATE/feature_request.md`:**

```markdown
---
name: Feature Request
about: Suggest a new feature or enhancement
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Feature Description
<!-- Clear description of the proposed feature -->

## Problem It Solves
<!-- What problem does this address? -->

## Proposed Solution
<!-- How should this work? -->

## Alternative Solutions
<!-- Other approaches considered -->

## Impact Assessment
- [ ] Requires changes to Constitution
- [ ] Affects PHI handling
- [ ] Requires legal/compliance review
- [ ] Changes security model
- [ ] Affects ASAM form handling

## User Stories
<!-- Who benefits and how? -->
As a [role], I want [feature] so that [benefit]

## Acceptance Criteria
- [ ] 
- [ ] 
- [ ] 

## Additional Context
<!-- Mockups, references, examples -->
```

### Security Issue Template

**Create `.github/ISSUE_TEMPLATE/security_report.md`:**

```markdown
---
name: Security Report
about: Report a security vulnerability or PHI risk (PRIVATE ONLY)
title: '[SECURITY] '
labels: security
assignees: ''
---

⚠️ **IMPORTANT: If this is a critical security issue with PHI at risk, contact the project maintainer directly instead of filing a public issue.**

## Security Concern
<!-- Describe the security issue -->

## Risk Assessment
- [ ] PHI could be exposed
- [ ] Credentials could be compromised
- [ ] Data integrity at risk
- [ ] Legal/compliance violation possible

## Steps to Reproduce
<!-- How to reproduce the issue -->

## Proposed Fix
<!-- If known -->

## Affected Components
- [ ] Python agent
- [ ] Swift PDF export
- [ ] VS Code tasks
- [ ] Build scripts
- [ ] Documentation

## Urgency
- [ ] Critical (immediate action required)
- [ ] High (fix within 48 hours)
- [ ] Medium (fix within 1 week)
- [ ] Low (fix in next sprint)
```

---

## Labels & Project Management

### Required Labels

**Type Labels:**
- `bug` — Something isn't working
- `enhancement` — New feature or request
- `security` — Security vulnerability or PHI risk
- `documentation` — Documentation improvements
- `question` — Further information requested
- `technical-debt` — Code quality improvements

**Priority Labels:**
- `priority: critical` — Immediate attention required
- `priority: high` — Important, address soon
- `priority: medium` — Normal priority
- `priority: low` — Nice to have

**Status Labels:**
- `status: needs-review` — Awaiting review
- `status: in-progress` — Currently being worked on
- `status: blocked` — Cannot proceed
- `status: ready` — Ready for implementation

**Component Labels:**
- `component: agent` — Python CLI
- `component: pdf-export` — Swift PDF tool
- `component: tasks` — VS Code tasks
- `component: docs` — Documentation
- `component: build` — Build system

---

## Code Owners

**Create `.github/CODEOWNERS`:**

```
# ASAMPlan POC Code Owners
# These users will be automatically requested for review

# Default owners for everything
* @project-lead

# Constitution and governance
/.specify/memory/constitution.md @project-lead @compliance-officer
/SECURITY.md @project-lead @security-team
/PRIVACY.md @project-lead @compliance-officer
/AGENT_CONSTITUTION.md @project-lead

# Python agent
/agent/ @python-lead @project-lead

# Swift PDF export
/tools/pdf_export/ @swift-lead @project-lead

# Build and deployment
/scripts/ @devops-lead @project-lead
/.vscode/tasks.json @project-lead

# Security-sensitive files
/.gitignore @security-team @project-lead
.env.example @security-team
```

---

## GitHub Actions / CI (Future)

### Planned Workflows

**1. Pull Request Validation** (`.github/workflows/pr-check.yml`)
```yaml
name: PR Validation
on: [pull_request]

jobs:
  security-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check for secrets
        run: |
          # Use truffleHog or similar
      - name: Check for PHI patterns
        run: |
          # Grep for common PHI patterns (names, SSN, MRN)
      - name: Validate CHANGELOG updated
        run: |
          # Check if CHANGELOG.md was modified

  python-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
      - name: Lint Python
        run: |
          pip install pylint black
          black --check agent/
          pylint agent/

  swift-build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Swift CLI
        run: bash scripts/build-swift-cli.sh
```

**2. Security Scan** (`.github/workflows/security-scan.yml`)
```yaml
name: Security Scan
on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday 2am
  workflow_dispatch:

jobs:
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run dependency audit
        run: |
          # pip-audit or similar
```

---

## Release Management

### Version Numbering

**Format: MAJOR.MINOR.PATCH**

- **MAJOR**: Breaking changes, major features
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, minor improvements

**Examples:**
- `1.0.0` — Initial POC release
- `1.1.0` — Added signature validation
- `1.1.1` — Fixed hash computation bug
- `2.0.0` — Changed API structure (breaking)

### Release Process

**Steps:**
1. ✅ Update CHANGELOG.md with release notes
2. ✅ Update version in relevant files
3. ✅ Create release branch: `release/v1.0.0`
4. ✅ Final testing and validation
5. ✅ Merge to main with approval
6. ✅ Tag release: `git tag -a v1.0.0 -m "Release 1.0.0"`
7. ✅ Create GitHub Release with notes
8. ✅ Archive release artifacts

**Release Notes Template:**
```markdown
## ASAMPlan POC v1.0.0

### New Features
- 

### Bug Fixes
- 

### Security Updates
- 

### Breaking Changes
- 

### Known Issues
- 

### Upgrade Notes
- 
```

---

## Compliance & Auditing

### Access Audit Log

**Maintain record of:**
- Who has repository access
- When access was granted
- What permission level (read, write, admin)
- When access was revoked
- Reason for access grant/revoke

### Periodic Reviews

**Monthly:**
- [ ] Review active contributors
- [ ] Audit recent commits for PHI/secrets
- [ ] Check `.gitignore` effectiveness
- [ ] Review open issues for security concerns

**Quarterly:**
- [ ] Comprehensive security audit
- [ ] Review and update this document
- [ ] Update Constitution if needed
- [ ] Review dependency security

---

## Emergency Procedures

### PHI Leak Response

**If PHI is committed to repository:**

1. **IMMEDIATE:**
   - Rotate affected repository credentials
   - Contact project lead and compliance officer
   - Do NOT force-push or rewrite history (evidence)

2. **WITHIN 24 HOURS:**
   - Document incident in secure internal wiki
   - Assess scope of exposure
   - Determine if breach notification required
   - Create remediation plan

3. **FOLLOW-UP:**
   - Implement preventive controls
   - Update this document with lessons learned
   - Train team on prevention

### Secret Exposure Response

**If credentials are committed:**

1. **IMMEDIATE:**
   - Revoke/rotate exposed credentials
   - Check access logs for unauthorized use
   - Notify security team

2. **FOLLOW-UP:**
   - Review `.gitignore` and pre-commit hooks
   - Implement secret scanning
   - Update team training

---

## Quick Reference

### ✅ MUST DO
- Keep repository PRIVATE
- Protect main branch
- Require PR reviews
- Use descriptive commit messages
- Update CHANGELOG.md
- Follow PR template
- Check for PHI before committing

### ❌ MUST NOT DO
- Make repository public
- Force push to main
- Commit PHI or secrets
- Skip PR process
- Use vague commit messages
- Bypass branch protection
- Ignore security labels

### 🚨 ALWAYS REVIEW FOR
- PHI in code, comments, or commit messages
- Secrets or credentials
- Changes to .gitignore
- Security implications
- CHANGELOG updates
- Constitution compliance

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-11-08  
**Authority**: Project Constitution v1.0.0  
**Review Schedule**: Monthly during POC, quarterly after production
