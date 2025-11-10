# ASSESS App - Agent Package
Version: 0.2.0
Generated: 2025-11-09T12:00:00

Scope
- Assessment Mode and Planning Mode are separate.
- Hybrid PDF: static AcroForm pages plus dynamic Appendix pages.
- EMR Context is read only. Assessment content is interviewer owned.
- Problems module is the only CRUD owner for problems and goals.

What is included
- UI_WIREFRAMES_ASCII.md - updated ASCII for all screens.
- SPEC_PDF_COMPOSER.md - hybrid PDF spec with overflow rules and API.
- DESCRIPTOR_D1.json - starter descriptor for Domain 1.
- VALIDATION_GATES.json - global export blockers and advisory gates.
- DATA_MODEL.md - tables and ownership.
- EMR_CONTEXT_POLICY.md - read only policy and TTLs.
- SETTINGS_DEFAULTS.md - security and caching defaults.
- TASKS_TODO.md - implementation tasks.
- ACCEPTANCE_TESTS.md - tests to pass before pilot.
- NOTICE.txt - licensing and naming guidance.

Shipping note
- UI labels use neutral language. External taxonomy names must not ship without written license.
