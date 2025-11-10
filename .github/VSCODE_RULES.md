# VS Code Configuration Rules & Standards

**For: ASAMPlan POC**  
**Effective: 2025-11-08**  
**Authority: Project Constitution v1.0.0**

---

## Workspace Configuration

### Recommended Workspace File

**Use**: `ASAMPlan.code-workspace` for consistent team settings

**Benefits:**
- ✅ Consistent editor settings across team
- ✅ Centralized Python/Swift configuration
- ✅ Pre-configured debug launch configurations
- ✅ Extension recommendations
- ✅ Task integration

**Opening Workspace:**
```bash
code ASAMPlan.code-workspace
```

---

## Required Extensions

### Core Extensions (MUST INSTALL)

**Python Development:**
```
ms-python.python                 # Python IntelliSense & debugging
ms-python.vscode-pylance         # Fast Python language server
```

**Git & GitHub:**
```
github.copilot                   # AI pair programmer
github.copilot-chat              # AI chat interface
eamodio.gitlens                  # Advanced Git visualization
github.vscode-pull-request-github # PR management
```

**Documentation:**
```
yzhang.markdown-all-in-one       # Markdown tools
davidanson.vscode-markdownlint   # Markdown linting
```

### Recommended Extensions

**Code Quality:**
```
editorconfig.editorconfig        # Consistent coding style
streetsidesoftware.code-spell-checker # Spell checking
```

**Swift Development (for iOS app):**
```
sswg.swift-lang                  # Swift language support
```

**Utilities:**
```
spmeesseman.vscode-taskexplorer  # Task visualization
tomoki1207.pdf                   # PDF preview
```

### Installation Command

```bash
# Install all required extensions
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension github.copilot
code --install-extension github.copilot-chat
code --install-extension eamodio.gitlens
code --install-extension github.vscode-pull-request-github
code --install-extension yzhang.markdown-all-in-one
code --install-extension davidanson.vscode-markdownlint
```

---

## Editor Settings Standards

### Formatting Rules

**Python Files:**
- **Formatter**: Black
- **Line Length**: 88 characters (Black default)
- **Format on Save**: Enabled
- **Tab Size**: 4 spaces
- **Organize Imports on Save**: Enabled

**Swift Files:**
- **Tab Size**: 4 spaces
- **Format on Save**: Enabled
- **Insert Spaces**: Enabled

**JSON Files:**
- **Format on Save**: Enabled
- **Tab Size**: 2 spaces

**Markdown Files:**
- **Format on Save**: Enabled
- **Word Wrap**: On
- **Line Length**: 100 characters (recommended)

**Shell Scripts:**
- **Tab Size**: 2 spaces
- **EOL**: LF (Unix line endings)
- **Insert Spaces**: Enabled

### File Handling

**Auto-Trim:**
```json
{
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true
}
```

**File Exclusions (Hidden from Explorer):**
```json
{
  "files.exclude": {
    "**/.DS_Store": true,
    "**/__pycache__": true,
    "**/*.pyc": true,
    "**/out": true
  }
}
```

---

## Task Configuration Standards

### Task Naming Convention

**Format**: `Agent: <Action Description>`

**Examples:**
- ✅ `Agent: Scaffold` — Clear and specific
- ✅ `Agent: Export PDF` — Describes action
- ❌ `Run` — Too vague
- ❌ `Task1` — Not descriptive

### Task Structure Requirements

**All tasks MUST have:**
```json
{
  "label": "Agent: <Descriptive Name>",
  "type": "shell",
  "command": "<full command with absolute paths>",
  "problemMatcher": [],
  "presentation": {
    "echo": true,
    "reveal": "always",
    "focus": false,
    "panel": "shared"
  }
}
```

### Task Best Practices

**DO:**
- ✅ Use full parameter names (`--in` not `-i`)
- ✅ Use absolute paths where possible
- ✅ Set proper `dependsOn` for task chains
- ✅ Include helpful output messages
- ✅ Make tasks idempotent

**DON'T:**
- ❌ Use relative paths that might break
- ❌ Assume environment variables
- ❌ Chain commands with `&&` (use dependencies)
- ❌ Hide error output

### Standard Task Categories

**1. Setup & Scaffold:**
```json
{
  "label": "Agent: Scaffold",
  "type": "shell",
  "command": "python3 agent/asm.py scaffold"
}
```

**2. Validation:**
```json
{
  "label": "Agent: Validate",
  "type": "shell",
  "command": "python3 agent/asm.py plan.validate --in data/plan.sample.json"
}
```

**3. Build:**
```json
{
  "label": "Agent: Build pdf_export",
  "type": "shell",
  "command": "bash scripts/build-swift-cli.sh"
}
```

**4. Export/Generate:**
```json
{
  "label": "Agent: Export PDF",
  "type": "shell",
  "dependsOn": ["Agent: Build pdf_export"],
  "command": "python3 agent/asm.py pdf.export ..."
}
```

**5. Testing (Future):**
```json
{
  "label": "Agent: Run Tests",
  "type": "shell",
  "command": "python3 -m pytest tests/ -v",
  "group": {
    "kind": "test",
    "isDefault": true
  }
}
```

---

## Debug Configuration

### Python Debug Configurations

**1. Validate Plan (Most Common):**
```json
{
  "name": "Python: Validate Plan",
  "type": "debugpy",
  "request": "launch",
  "program": "${workspaceFolder}/agent/asm.py",
  "args": ["plan.validate", "--in", "data/plan.sample.json"],
  "console": "integratedTerminal",
  "justMyCode": true
}
```

**2. Compute Hash:**
```json
{
  "name": "Python: Plan Hash",
  "type": "debugpy",
  "request": "launch",
  "program": "${workspaceFolder}/agent/asm.py",
  "args": ["plan.hash", "--in", "data/plan.sample.json"],
  "console": "integratedTerminal"
}
```

**3. Current File:**
```json
{
  "name": "Python: Current File",
  "type": "debugpy",
  "request": "launch",
  "program": "${file}",
  "console": "integratedTerminal"
}
```

### Debug Best Practices

**Breakpoint Usage:**
- Set breakpoints in validation logic to inspect plan structure
- Use conditional breakpoints for specific field values
- Add logpoints for non-intrusive debugging

**Console Output:**
- Use `integratedTerminal` for better output formatting
- Enable `justMyCode` to avoid stepping into standard library

---

## Keyboard Shortcuts & Workflow

### Essential Shortcuts (macOS)

**Task Execution:**
- `Cmd+Shift+P` → "Tasks: Run Task" → Select task

**Quick Actions:**
- `Cmd+Shift+B` — Run default build task
- `Cmd+Shift+T` — Run default test task (when configured)

**File Navigation:**
- `Cmd+P` — Quick file open
- `Cmd+Shift+F` — Search across files
- `Cmd+T` — Show symbols in workspace

**Git Operations:**
- `Cmd+Shift+G` — Open source control
- `Ctrl+Shift+G` then `C` — Commit
- `Ctrl+Shift+G` then `P` — Push

**Copilot:**
- `Cmd+I` — Open inline Copilot chat
- `Cmd+Shift+I` — Open Copilot chat panel

---

## Linting & Code Quality

### Python Linting Configuration

**Pylint Settings:**
```json
{
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.linting.pylintArgs": [
    "--max-line-length=120",
    "--disable=C0111,C0103"
  ]
}
```

**Disabled Warnings Explanation:**
- `C0111` — Missing docstrings (optional for POC)
- `C0103` — Variable naming (can be restrictive)

### Black Formatting

**Configuration:**
```json
{
  "python.formatting.provider": "black",
  "python.formatting.blackArgs": [
    "--line-length=88"
  ]
}
```

**Manual Formatting:**
```bash
black agent/
black tests/
```

### Markdown Linting

**Configuration:**
```json
{
  "markdownlint.config": {
    "MD013": false,  // Line length (can be long in docs)
    "MD033": false,  // Inline HTML (needed for badges)
    "MD041": false   // First line need not be heading
  }
}
```

---

## Git Integration

### Source Control Settings

**Recommended:**
```json
{
  "git.autofetch": true,
  "git.confirmSync": false,
  "git.enableSmartCommit": false,
  "git.postCommitCommand": "none"
}
```

### GitLens Configuration

**Useful Features:**
- Current Line Blame — See who last edited line
- File History — Track file changes over time
- Branch Comparison — Compare branches visually
- Commit Search — Find commits by message or author

**Privacy Note:** Be careful with GitLens features when working with PHI. Disable sharing features.

### Pre-Commit Checks (via GitLens)

**Recommended Checks:**
- [ ] No PHI in staged files
- [ ] No secrets in staged files
- [ ] CHANGELOG.md updated
- [ ] Linting passes

---

## Terminal Configuration

### Integrated Terminal Settings

```json
{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.scrollback": 10000,
  "terminal.integrated.copyOnSelection": true
}
```

### Useful Terminal Commands

**Quick Open:**
- `` Ctrl+` `` — Toggle integrated terminal
- `Cmd+Shift+C` — Open external terminal

**Multiple Terminals:**
- Create split terminal for parallel tasks
- Name terminals for clarity (right-click → Rename)

---

## Snippets & Productivity

### Custom Python Snippets

**Create `.vscode/python.json`:**

```json
{
  "SHA256 Hash": {
    "prefix": "hash-canonical",
    "body": [
      "def canonical_bytes(obj) -> bytes:",
      "    return json.dumps(obj, sort_keys=True, separators=(',', ':')).encode('utf-8')",
      "",
      "def compute_hash(obj) -> str:",
      "    return hashlib.sha256(canonical_bytes(obj)).hexdigest()"
    ],
    "description": "Canonical JSON hash functions"
  },
  
  "CLI Command": {
    "prefix": "cmd-handler",
    "body": [
      "def cmd_${1:name}(args):",
      "    \"\"\"${2:Description}\"\"\"",
      "    ${3:pass}"
    ],
    "description": "CLI command handler"
  }
}
```

---

## Problem Matchers

### Custom Problem Matchers

**For Python Errors:**
```json
{
  "problemMatcher": {
    "owner": "python",
    "fileLocation": ["relative", "${workspaceFolder}"],
    "pattern": {
      "regexp": "^(.+):(\\d+):(\\d+):\\s+(error|warning):\\s+(.+)$",
      "file": 1,
      "line": 2,
      "column": 3,
      "severity": 4,
      "message": 5
    }
  }
}
```

**For Swift Build Errors:**
```json
{
  "problemMatcher": {
    "owner": "swift",
    "fileLocation": ["relative", "${workspaceFolder}"],
    "pattern": {
      "regexp": "^(.+):(\\d+):(\\d+):\\s+(error|warning):\\s+(.+)$",
      "file": 1,
      "line": 2,
      "column": 3,
      "severity": 4,
      "message": 5
    }
  }
}
```

---

## Workspace Organization

### Recommended File Tree View

```
ASAM_App/
├── 📁 .github/             # GitHub configuration
│   ├── GITHUB_RULES.md
│   └── prompts/
├── 📁 .specify/            # Spec-kit configuration
│   ├── memory/
│   │   └── constitution.md
│   └── scripts/
├── 📁 .vscode/             # VS Code configuration
│   └── tasks.json
├── 📁 agent/               # Python CLI
│   └── asm.py
├── 📁 assets/              # Static resources
│   ├── ⚠️ ASAM_TreatmentPlan_Template.pdf
│   └── sample_signature.png
├── 📁 data/                # Sample data
│   └── plan.sample.json
├── 📁 Documents/           # Reference documents
│   └── asam-paper-criteria...pdf
├── 📁 scripts/             # Build scripts
│   └── build-swift-cli.sh
├── 📁 tools/               # Platform-specific tools
│   └── pdf_export/
│       └── PDFExport.swift
├── 📄 ASAMPlan.code-workspace  # Workspace file
├── 📄 README.md
├── 📄 CHANGELOG.md
└── 📄 QUICK_START.md
```

### File Associations

**Custom Associations:**
```json
{
  "files.associations": {
    "*.json": "jsonc",
    "CHANGELOG": "markdown",
    "TASKS": "markdown",
    "*.template": "plaintext"
  }
}
```

---

## Security & Privacy Settings

### Preventing PHI Exposure

**Search Exclusions:**
```json
{
  "search.exclude": {
    "**/out/**": true,
    "**/*.pdf": true
  }
}
```

**File Watcher Exclusions:**
```json
{
  "files.watcherExclude": {
    "**/out/**": true
  }
}
```

### Disabling Telemetry

**Privacy Settings:**
```json
{
  "telemetry.telemetryLevel": "off",
  "redhat.telemetry.enabled": false
}
```

### GitHub Copilot Privacy

**Settings:**
```json
{
  "github.copilot.advanced": {
    "debug.overrideProxyUrl": "",
    "debug.testOverrideProxyUrl": ""
  }
}
```

**IMPORTANT:** Copilot sends code to OpenAI. NEVER use Copilot on files containing real PHI.

---

## Troubleshooting

### Common Issues

**1. Python Not Found**
```bash
# Check Python path
which python3

# Update workspace settings
"python.defaultInterpreterPath": "/usr/local/bin/python3"
```

**2. Tasks Not Running**
```bash
# Check task configuration
Cmd+Shift+P → "Tasks: Configure Task"

# Verify cwd is set correctly
"options": {
  "cwd": "${workspaceFolder}"
}
```

**3. Swift Build Fails**
```bash
# Check Xcode tools
xcode-select --version

# Reinstall if needed
xcode-select --install
```

**4. Linting Not Working**
```bash
# Install pylint
pip3 install pylint black

# Reload window
Cmd+Shift+P → "Developer: Reload Window"
```

---

## Best Practices Summary

### ✅ DO

- Use the workspace file (`ASAMPlan.code-workspace`)
- Install all required extensions
- Enable format on save
- Use task runner for common operations
- Name tasks descriptively
- Keep terminal scrollback high for debugging
- Use problem matchers for error detection
- Exclude `out/` from searches and watchers

### ❌ DON'T

- Commit `.vscode/settings.json` with personal settings
- Use Copilot on files with real PHI
- Enable telemetry if handling PHI
- Share workspace with untrusted extensions
- Hard-code file paths in tasks
- Skip linting setup
- Leave debug configurations without descriptions

### 🎯 PRODUCTIVITY TIPS

1. **Use Command Palette** (`Cmd+Shift+P`) for everything
2. **Learn task shortcuts** for frequent operations
3. **Set up debug configurations** before debugging
4. **Use multi-cursor editing** for repetitive changes
5. **Master Git integration** for efficient version control
6. **Configure snippets** for common code patterns
7. **Use peek definition** (`Cmd+Click`) to navigate code
8. **Enable breadcrumbs** for file context

---

## Maintenance Schedule

**Weekly:**
- [ ] Update extensions
- [ ] Check for new VS Code version
- [ ] Review task configurations

**Monthly:**
- [ ] Review and optimize settings
- [ ] Update this document with new learnings
- [ ] Check extension recommendations for updates

**As Needed:**
- [ ] Add new tasks for new workflows
- [ ] Update debug configurations
- [ ] Adjust linting rules based on team feedback

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-11-08  
**Authority**: Project Constitution v1.0.0  
**Next Review**: 2025-12-08
