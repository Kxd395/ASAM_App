# EMR Context policy

- EMR data is a read only drawer. Never pre fill assessment controls.
- Provenance: if user copies from EMR, record a small note "copied from EMR" in field metadata.
- TTLs: allergies 24h, meds 24h, demographics 7d, encounters 72h.
- Failure mode: if EMR fetch fails, show drawer with an error. Do not block assessment.
