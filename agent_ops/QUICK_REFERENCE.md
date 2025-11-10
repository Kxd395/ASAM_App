# 🤖 Agent Operations Quick Reference

**Last Updated**: November 9, 2025  
**Status**: Production Ready ✅

---

## 📋 Essential Commands

### Check Root Hygiene
```bash
cd agent_ops
python3 tools/check_root_files.py
```
**Expected**: `Root hygiene OK.`

### Post-Run Update
```bash
cd agent_ops
python3 tools/agent_postrun.py \
  --run-id "$(date +%Y%m%d%H%M%S)" \
  --actor "agent" \
  --summary "Brief description (no PHI)" \
  --completed T-0001 T-0002 \
  --artifacts artifacts/output.pdf
```

### View Current Tasks
```bash
cat agent_ops/docs/MASTER_TODO.md
```

### View Run History
```bash
cat agent_ops/docs/RUN_LOG.md
```

---

## ⚠️ Critical Rules

### ❌ Never Do
- Log PHI (MRN, FIN, patient names)
- Use patient names in filenames
- Create files in repository root
- Edit MASTER_TODO.md manually
- Skip post-run updates

### ✅ Always Do
- Use neutral filenames (`ASAMPlan_20251109120000.pdf`)
- Write to `artifacts/`, `out/`, or `docs/`
- Call `agent_postrun.py` after work
- Update `TODO_INDEX.json` for tasks
- Check root hygiene before commit

---

## 🎯 VS Code Integration

1. Press `Cmd+Shift+P`
2. Type "Tasks: Run Task"
3. Select:
   - **Agent: Postrun** - Update after work
   - **Agent: Check Root Hygiene** - Validate cleanliness

---

## 📁 Key Files

| File | Edit? | Purpose |
|------|-------|---------|
| `TODO_INDEX.json` | ✅ Yes | Task source of truth |
| `MASTER_TODO.md` | ❌ No | Auto-generated view |
| `RUN_LOG.md` | ❌ No | Auto-appended audit trail |
| `ALLOWED_ROOT.json` | ⚠️ Carefully | Root file whitelist |

---

## 📚 Documentation

- **[INTEGRATION_GUIDE.md](agent_ops/docs/INTEGRATION_GUIDE.md)** - Complete setup
- **[AGENT_CONSTITUTION.md](agent_ops/docs/AGENT_CONSTITUTION.md)** - Safety rules
- **[AGENT_OPERATIONS.md](agent_ops/docs/AGENT_OPERATIONS.md)** - Operations playbook

---

## 🔗 Quick Links

- **Main Index**: [INDEX.md](../INDEX.md)
- **Project Constitution**: [../docs/governance/AGENT_CONSTITUTION.md](../docs/governance/AGENT_CONSTITUTION.md)
- **Integration Complete**: [../docs/AGENT_OPS_INTEGRATION_COMPLETE.md](../docs/AGENT_OPS_INTEGRATION_COMPLETE.md)

---

**Status**: ✅ All systems operational
