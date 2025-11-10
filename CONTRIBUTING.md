# Contributing to ASAM Assessment Application

Thank you for your interest in contributing! This document provides guidelines and workflows for contributing to this project.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Security](#security)

---

## 🤝 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors.

### Our Standards

**Expected Behavior:**
- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what's best for the project
- Show empathy towards other contributors

**Unacceptable Behavior:**
- Harassment, discrimination, or derogatory comments
- Personal attacks or trolling
- Publishing others' private information
- Other conduct inappropriate in a professional setting

---

## 🚀 Getting Started

### Prerequisites

**Required:**
- Python 3.9+
- Xcode 15+ (for iOS development)
- VS Code (recommended) or your preferred editor
- Git 2.30+

**Recommended:**
- Black formatter for Python
- SwiftLint for Swift code
- EditorConfig plugin

### Initial Setup

1. **Fork the repository**
   ```bash
   # Visit https://github.com/your-org/ASAM_App
   # Click "Fork" button
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ASAM_App.git
   cd ASAM_App
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/original-org/ASAM_App.git
   ```

4. **Install dependencies**
   ```bash
   # Python dependencies
   pip install -r requirements.txt
   
   # Install pre-commit hooks
   pip install pre-commit
   pre-commit install
   ```

5. **Read key documents**
   - `INDEX.md` - Project navigation
   - `docs/governance/AGENT_CONSTITUTION.md` - Core principles
   - `docs/governance/SECURITY.md` - Security requirements
   - `.github/GITHUB_RULES.md` - Repository standards

---

## 🔄 Development Workflow

### 1. Create a Branch

```bash
# Update your fork
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

**Branch Naming Conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions/updates
- `chore/` - Maintenance tasks

### 2. Make Changes

**Before coding:**
- [ ] Understand the feature/fix requirements
- [ ] Check for existing issues/PRs
- [ ] Review relevant documentation
- [ ] Plan your approach

**While coding:**
- [ ] Follow coding standards (see below)
- [ ] Write clear, self-documenting code
- [ ] Add comments for complex logic
- [ ] Keep commits small and focused
- [ ] Test your changes locally

### 3. Commit Your Changes

```bash
# Stage files
git add path/to/changed/files

# Commit with descriptive message
git commit -m "type(scope): description"
```

See [Commit Guidelines](#commit-guidelines) below for details.

### 4. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create PR on GitHub
# - Fill out the PR template completely
# - Link related issues
# - Request reviews
```

---

## 💻 Coding Standards

### Python

**Style Guide:** PEP 8 with Black formatting

```python
# Good: Clear function names, type hints, docstrings
def calculate_loc_recommendation(
    assessment: Assessment,
    criteria: LOCCriteria
) -> LOCRecommendation:
    """
    Calculate LOC recommendation based on assessment data.
    
    Args:
        assessment: Patient assessment data
        criteria: LOC decision criteria
        
    Returns:
        LOCRecommendation with code and rationale
    """
    # Implementation
    pass

# Bad: Unclear names, no types, no docstring
def calc(a, c):
    pass
```

**Key Principles:**
- Use type hints for function signatures
- Write docstrings for public functions
- Keep functions short (< 50 lines)
- Avoid global state
- Use descriptive variable names

**Formatting:**
```bash
# Format with Black
black agent/

# Check with flake8
flake8 agent/
```

### Swift

**Style Guide:** Swift API Design Guidelines

```swift
// Good: Clear, Swifty code
func recommendLevelOfCare(
    for assessment: Assessment
) -> LOCRecommendation {
    // Implementation
}

// Bad: Objective-C style
func getLOCRecommendationWithAssessment(assessment: Assessment) -> LOCRecommendation {
    // Implementation
}
```

**Key Principles:**
- Use Swift naming conventions
- Prefer value types (struct) over reference types (class)
- Use protocols for abstraction
- Leverage Swift's type system
- Write self-documenting code

**Formatting:**
```bash
# Format with SwiftFormat
swiftformat tools/pdf_export/
```

### Markdown

**Style:** Use consistent formatting

```markdown
# Good: Clear hierarchy, proper spacing

## Section Title

Content paragraph with proper spacing.

### Subsection

- Bulleted list item
- Another item

### Code Examples

```python
# Properly formatted code block
def example():
    pass
```

# Bad: Inconsistent formatting

##Section Title
Content with no spacing...
```

**Key Principles:**
- Use ATX-style headers (`#` not `===`)
- One blank line between sections
- Use fenced code blocks with language
- Keep lines under 120 characters

---

## 📝 Commit Guidelines

### Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test additions/updates
- `chore`: Maintenance tasks
- `security`: Security fixes
- `perf`: Performance improvements

### Scope

Optional, indicates component affected:
- `agent`: Python CLI
- `ios`: iOS app
- `pdf`: PDF export
- `loc`: LOC calculation
- `data`: Data files
- `docs`: Documentation
- `ci`: CI/CD

### Examples

```bash
# Good commits
git commit -m "feat(ios): add accessibility labels to domain view"
git commit -m "fix(loc): correct withdrawal management calculation"
git commit -m "docs(readme): update installation instructions"
git commit -m "security(agent): sanitize user input in CLI"

# Bad commits
git commit -m "fixed stuff"
git commit -m "WIP"
git commit -m "Update file.py"
```

### Commit Body

Add details when subject isn't enough:

```
feat(ios): add safety banner modal with audit logging

- Replace dismissible banner with modal sheet
- Require action type selection and notes
- Implement AuditService with HMAC verification
- Add unit tests for action recording

Closes #42
```

---

## 🔍 Pull Request Process

### Before Submitting

**Checklist:**
- [ ] Code follows style guidelines
- [ ] All tests pass locally
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] No PHI or secrets in code
- [ ] CHANGELOG.md updated (if applicable)
- [ ] Commits are clean and descriptive

### PR Title

Use same format as commit messages:

```
feat(ios): add accessibility support
fix(agent): resolve PDF export crash
docs(guides): add LOC integration guide
```

### PR Description

**Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Security fix

## Related Issues
Closes #123

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing performed
- [ ] Accessibility tested (for iOS)

## Screenshots (if applicable)
[Add screenshots]

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests pass
- [ ] No PHI or secrets
```

### Review Process

1. **Automated Checks**
   - CI pipeline must pass
   - Legal compliance check must pass
   - All tests must pass

2. **Code Review**
   - At least one approval required
   - Address all reviewer comments
   - Keep discussion professional

3. **Merging**
   - Squash commits for clean history
   - Use descriptive merge commit message
   - Delete branch after merge

---

## 🧪 Testing

### Python Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=agent

# Run specific test
pytest tests/test_loc_service.py
```

**Test Standards:**
- Unit tests for all business logic
- Integration tests for workflows
- Mock external dependencies
- Aim for 80%+ coverage

### iOS Tests

```bash
# Run tests in Xcode
# Product → Test (⌘U)

# Or from command line
xcodebuild test -scheme ASSESS -destination 'platform=iOS Simulator,name=iPad Pro'
```

**Test Standards:**
- Unit tests for services and models
- UI tests for critical flows
- Accessibility tests for all views
- Test on multiple device sizes

### Manual Testing

**Before PR:**
- [ ] Test happy path
- [ ] Test error cases
- [ ] Test edge cases
- [ ] Test on target platforms
- [ ] Test accessibility (iOS)

---

## 🔐 Security

### Security Requirements

**CRITICAL: Never commit:**
- PHI (Protected Health Information)
- API keys or credentials
- Personal identifiable information
- Real patient data

**Use instead:**
- Environment variables for secrets
- Sample/synthetic data for testing
- Placeholder values in examples

### Reporting Security Issues

**DO NOT create public issues for security vulnerabilities**

Instead:
1. Email security team at [security@example.com]
2. Include detailed description
3. Include steps to reproduce
4. Wait for response before disclosure

### Security Checklist

- [ ] No hardcoded credentials
- [ ] Input validation implemented
- [ ] Output sanitized
- [ ] Dependencies up to date
- [ ] Security scan passed

---

## 📚 Additional Resources

### Documentation
- [INDEX.md](INDEX.md) - Project navigation
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Repository layout
- [docs/governance/AGENT_CONSTITUTION.md](docs/governance/AGENT_CONSTITUTION.md) - Core principles

### Tools
- [Black](https://black.readthedocs.io/) - Python formatter
- [SwiftLint](https://github.com/realm/SwiftLint) - Swift linter
- [pre-commit](https://pre-commit.com/) - Git hooks

### Communication
- GitHub Issues - Bug reports, feature requests
- GitHub Discussions - Questions, ideas
- Pull Requests - Code contributions

---

## ❓ Questions?

**Need help?**
- Check [INDEX.md](INDEX.md) for navigation
- Search existing issues
- Ask in GitHub Discussions
- Reach out to maintainers

**Thank you for contributing!** 🎉

---

**Last Updated**: November 9, 2025  
**Maintained By**: Project Contributors  
**License**: See [LICENSE](LICENSE)
