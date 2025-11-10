# File Rules and Naming

## Naming
- **Outputs**: `ASAMPlan_<random>.pdf` — never include names, MRNs, or dates of birth.
- **Assets**: Put the official ASAM PDF at `assets/ASAM_TreatmentPlan_Template.pdf`.
- **Temp files**: Use the `out/` folder only; it is git‑ignored.

## Structure
```
/agent                Python CLI
/tools/pdf_export     Swift CLI for PDF export
/assets               Official PDF (not included) and sample signature
/data                 Sample input JSON
/scripts              Build scripts
/.vscode              Task runner and editor settings
/out                  Outputs (git‑ignored)
```

## Conventions
- JSON keys are lowerCamelCase.
- Keep field maps in one place (`FORM_FIELD_MAP.json`).
- Keep policy docs at repo root for easy review.
