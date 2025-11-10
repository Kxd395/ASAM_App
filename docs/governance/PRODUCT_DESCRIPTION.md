# Product Description — ASAMPlan POC

**Goal**: Produce a legally sound, signed ASAM Treatment Plan PDF from a native iPad app, offline, with secure defaults.

**Primary users**: Counselors, peers, and clinicians completing ASAM-aligned treatment plans during intake and updates.

**MVP capabilities**
- Patient info, diagnoses, dynamic problems list
- PencilKit signature capture
- Cryptographic plan seal (SHA‑256 of canonical JSON)
- PDF export that fills official AcroForms and adds a footer seal
- Face ID gate and idle lock in the app (implementation in iOS project; CLI here supports PDF workflow)

**Out of scope for the POC**
- Multi-device sync and conflict resolution
- Remote wipe and MDM
- Full event sourcing and server reconciliation

**Why this matters**
- Exports are court‑admissible by using the **official ASAM form** and AcroForm fields
- No PHI leaks via filenames
- Signature images are ephemeral; only the hash survives in data
