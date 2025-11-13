# Security Backlog (Deferred to Post-Prototype)

**Created**: November 13, 2025  
**Status**: Parked - No work until prototype milestone complete  
**Purpose**: Track security requirements to implement after demo, with acceptance criteria

---

## Scope

Security items we will implement **after the prototype milestone**. No work now, only notes with acceptance checks.

---

## A. Data at Rest

- [ ] **CryptoKit file encryption with per-install key in Keychain**
  - **Accept**: Files only readable on same install, decrypt round-trip test passes
  - **Test**: Attempt to read file on different device → should fail
  - **Files**: `SecureStore.swift`, `EncryptionTests.swift`

- [ ] **PHI schema tagging and selective encryption of fields marked `phi:true`**
  - **Accept**: Redacted JSON shows masked values for PHI keys
  - **Test**: Export with redaction → free-text fields show `***REDACTED***`
  - **Files**: `PHISchema.swift`, `Redactor.swift`

- [ ] **No-backup flag on all storage paths**
  - **Accept**: `NSURLIsExcludedFromBackupKey` verified in preflight
  - **Test**: Check `xattr` on storage folder → `com.apple.metadata:com_apple_backup_excludeItem` present
  - **Files**: `StorageManager.swift`, `PreflightChecks.swift`

---

## B. Transport and Device

- [ ] **TLS pin set when network sync exists**
  - **Accept**: MitM test fails to connect
  - **Test**: Proxy with invalid cert → connection refused
  - **Files**: `NetworkManager.swift`, `TLSPinningTests.swift`

- [ ] **Background snapshot blur**
  - **Accept**: App switcher never shows form content
  - **Test**: Background app, check screenshot → blurred overlay visible
  - **Files**: `AppDelegate.swift` or `SceneDelegate.swift`, `SnapshotBlurView.swift`

- [ ] **Device policy hooks for MDM later**
  - **Accept**: Doc lists required keys, not implemented now
  - **Test**: N/A (documentation only)
  - **Files**: `docs/MDM_INTEGRATION.md`

---

## C. Identity and Session

- [ ] **In-app PIN or Face ID gate**
  - **Accept**: App requires auth on cold start and after 2 minutes background
  - **Test**: Cold launch → PIN prompt, background 2min → PIN prompt on return
  - **Files**: `AuthenticationManager.swift`, `PINView.swift`

- [ ] **Role flags for read vs export**
  - **Accept**: Non-elevated role cannot export PDF
  - **Test**: Login as read-only user → Export button disabled
  - **Files**: `UserRole.swift`, `ExportPermissionManager.swift`

---

## D. Auditability

- [ ] **Append-only JSONL audit log with rule checksum**
  - **Accept**: Change events include who, when, old, new, ruleset version
  - **Test**: Change field → audit.log.jsonl contains entry with all metadata
  - **Files**: `AuditLog.swift`, `AuditEvent.swift`
  - **Format**:
    ```json
    {"ts":"2025-11-13T14:30:22Z","user":"kdial","action":"field_change","path":"d3.suicidal.today","old":"false","new":"true","ruleset":"v2.0.0","checksum":"abc123"}
    ```

- [ ] **Override ledger for final severity**
  - **Accept**: Cannot finish with Sev 3 or 4 override without reason code
  - **Test**: Attempt to override to Sev 4 without reason → blocked with error
  - **Files**: `SeverityOverrideManager.swift`, `OverrideLedger.swift`

---

## E. Export Controls

- [ ] **Export preflight. Abort if any requirement fails**
  - **Accept**: Unit test forces failure when key or no-backup flag missing
  - **Test**: Remove Keychain key → export fails with preflight error
  - **Files**: `ExportPreflight.swift`, `ExportPreflightTests.swift`
  - **Checks**:
    - Keychain key present
    - Storage path excluded from backup
    - NSFileProtection set to `.completeUntilFirstUserAuthentication`
    - Ruleset version present
    - No PHI validation errors

- [ ] **Minimal vs full export with PHI redaction**
  - **Accept**: Minimal export excludes free text and identifiers
  - **Test**: Export minimal → MRN, FIN, free-text fields redacted
  - **Files**: `ExportRedactor.swift`, `ExportOptions.swift`

- [ ] **Watermark and "Not for clinical use" footer on PDFs**
  - **Accept**: Visible on every page
  - **Test**: Generate PDF → footer present on all pages
  - **Files**: `PDFGenerator.swift`, `WatermarkRenderer.swift`

---

## F. Settings and Policy

- [ ] **Settings page for purge data, disable analytics, export default**
  - **Accept**: Toggles persist, e2e tests cover them
  - **Test**: Toggle setting → persists after app restart
  - **Files**: `SettingsView.swift`, `AppSettings.swift`
  - **Required Settings**:
    - Purge all PHI (2-step confirmation)
    - Require passcode on launch
    - Disable screenshots for sensitive screens
    - Export default (minimal vs full)
    - Delete all local data

- [ ] **Data retention timer and scrub job**
  - **Accept**: Test deletes artifacts older than N days
  - **Test**: Create assessment, set retention to 1 day, wait 25h → auto-deleted
  - **Files**: `RetentionManager.swift`, `DataScrubJob.swift`

---

## G. Build and Ops

- [ ] **PROTOTYPE vs PROD feature flags**
  - **Accept**: PROD blocks dev exports and enables full preflight
  - **Test**: PROD build → export requires all preflight checks
  - **Files**: `FeatureFlags.swift`, `BuildConfig.xcconfig`

- [ ] **Secrets handling doc**
  - **Accept**: No secrets in repo, CI scan passes
  - **Test**: Run `git-secrets` scan → no secrets found
  - **Files**: `docs/SECRETS_HANDLING.md`, `.git-secrets` config

---

## Implementation Priority (Post-Prototype)

### Phase 1: Critical Security (Week 1)
1. SecureStore encryption
2. No-backup flag
3. Export preflight
4. Audit log

### Phase 2: User Safety (Week 2)
5. Background snapshot blur
6. PIN/Face ID gate
7. Settings page (purge PHI, passcode)

### Phase 3: Compliance (Week 3)
8. PHI redaction
9. Watermark on PDFs
10. Role-based export permissions

### Phase 4: Operations (Week 4)
11. Data retention
12. Feature flags (PROTOTYPE vs PROD)
13. Secrets handling doc
14. TLS pinning (if network sync needed)

---

## Notes

- **DO NOT START** any of these tasks until prototype demo is complete
- All items have clear acceptance criteria for testing
- Security is critical but not blocking the MVP demo
- Track progress in separate security sprint after prototype approval

---

**Manager's Note**: This backlog ensures we don't ship insecure code to production, but we're explicitly deferring it to avoid scope creep during the prototype sprint. Every item has a clear test that can be automated.
