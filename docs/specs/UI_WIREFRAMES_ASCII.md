# UI Wireframes - ASCII

Global rules
- Persistent safety banner warns but does not lock form entry. Export is hard blocked until a safety action is recorded.
- Assessment Mode and Planning Mode are separate modules.
- Problems module is the only CRUD owner. Domains capture scratchpad only with Send to Problems action.
- EMR Context drawer is read only and visually distinct.

=====================================================
1) Launch and Auth
=====================================================
+--------------------------------------------------------------+
|  ASSESS - Launch                                             |
+--------------------------------------------------------------+
|  [ Launch with EMR ]  [ Demo with Mock Data ]                |
|                                                              |
|  Last sign in: <user>                                        |
|  Tenant: <profile>                                           |
|                                                              |
|  Status                                                      |
|  - EMR base: https://.../fhir        [ Check ] [ OK ]        |
|  - OAuth token: not present           [ Sign In ]            |
|  - Local DB: encrypted and healthy    [ Details ]            |
|  - Device health: storage ok, backup excluded                |
+--------------------------------------------------------------+
|  Footer: Non PHI logs only                                   |
+--------------------------------------------------------------+

=====================================================
2) Patient Lookup
=====================================================
+--------------------------------------------------------------+
|  Patient Lookup                                              |
+--------------------------------------------------------------+
|  Search MRN, FIN, or name: [____________________] [ Scan ]   |
|                                                              |
|  Recent                                                      |
|  - MRN 112233  Demo Patient A  2 open encounters             |
|  - MRN 445566  Demo Patient B  1 open encounter              |
|                                                              |
|  [ Continue ]   [ Cancel ]                                   |
+--------------------------------------------------------------+

=====================================================
3) Patient Summary and Encounters
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Patient Summary                                 |  Encounters                                   |
+--------------------------------------------------------------------------------------------------+
|  Demo Patient A      MRN 112233                  |  FIN 900001  Outpatient  Today  [ Select ]    |
|  DOB 01 01 1980      Allergies: NKDA             |  FIN 900000  ED        Last week [ View ]     |
|  EMR Context (read only): alerts, allergies, meds|                                                 |
+--------------------------------------------------------------------------------------------------+
|  [ New Assessment Draft ]  [ Open Existing Draft ]   [ Back ]                                    |
+--------------------------------------------------------------------------------------------------+

=====================================================
4) Assessment Overview
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Assessment - Overview - FIN 900001                                                              |
+--------------------------------------------------------------------------------------------------+
|  Severity chips                                                                                  |
|  A 0  B 1  C 0  D 0  E 1  F 0                 [ Tap to open domain ]                             |
|                                                                                                  |
|  Candidate WM: undecided      Indicated Level: pending                                           |
|                                                                                                  |
|  Progress                                   Validation                                           |
|  A Intake and withdrawal  2 of 5            4 issues  [ Expand ]                                 |
|  B Biomedical            1 of 4                                                                   |
|  C Psychiatric           0 of 5                                                                   |
|  D Use related           0 of 4                                                                   |
|  E Environment           1 of 4                                                                   |
|  F Person centered       0 of 3                                                                   |
|                                                                                                  |
|  [ Save Draft ]  [ Review ]  [ Proceed to Planning Mode ]                                        |
+--------------------------------------------------------------------------------------------------+

=====================================================
5) Safety Banner - persistent on all Assessment pages
=====================================================
+--------------------------------------------------------------------------------------------------+
|  SAFETY: Immediate evaluation required. Export is blocked until action recorded.  [ Record ]     |
+--------------------------------------------------------------------------------------------------+

=====================================================
6) Domain template - Required for Level of Care then Required for Treatment Plan
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Domain A - Intake and withdrawal - FIN 900001                                                   |
+--------------------------------------------------------------------------------------------------+
|  [ Severity 0 1 2 3 4 ]   [ Anchors ]                                                            |
|                                                                                                  |
|  Required for Level of Care                                                                      |
|  - Last substance use:  [ date picker ]                                                          |
|  - Withdrawal signs:    [ none | mild | moderate | severe ]                                      |
|  - Overdose history:    [ yes | no ]   [ details ]                                               |
|                                                                                                  |
|  Required for Treatment Plan                                                                     |
|  - Notes: [ multiline text ]                                                                     |
|  - Scratchpad: Problem(s)  [ text ]    Goal(s)  [ text ]  [ Send to Problems ]                   |
|                                                                                                  |
|  EMR Context (read only)  [ show ]                                                               |
|                                                                                                  |
|  Actions                                                                                         |
|  [ Save and Next ]  [ Back ]  [ Jump to overview ]                                               |
+--------------------------------------------------------------------------------------------------+

=====================================================
7) Problems - single source of truth
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Problems - FIN 900001                                                                           |
+--------------------------------------------------------------------------------------------------+
|  [ + Add Problem ]                                                                               |
|                                                                                                  |
|  [ ] Problem 1  concise statement                        Goal: short goal         Tags: D1 D2    |
|  [ ] Problem 2  concise statement                        Goal: short goal         Tags: D3       |
|                                                                                                  |
|  Hint: problems are created here. Domains only send scratchpad text to this queue.               |
+--------------------------------------------------------------------------------------------------+

=====================================================
8) Review - blockers first
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Review - Validation                                                                             |
+--------------------------------------------------------------------------------------------------+
|  Blockers                                                                                        |
|  - Safety flag present. Action not recorded.                     [ Record action ]               |
|  - Domain C required item not answered.                         [ Fix ]                          |
|                                                                                                  |
|  Gaps                                                                                             |
|  - Problem 2 goal missing.                                   [ Fix ]                             |
|                                                                                                  |
|  Advisory                                                                                         |
|  - Consider medical management based on D2.                 [ Details ]                           |
|                                                                                                  |
|  [ Continue to Sign ]   [ Save Draft ]   Export is disabled until blockers cleared.              |
+--------------------------------------------------------------------------------------------------+

=====================================================
9) Summary and Level of Care - bridge to Planning Mode
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Summary and LOC                                                                                 |
+--------------------------------------------------------------------------------------------------+
|  Severity grid: A 2  B 1  C 0  D 1  E 2  F 0                                                     |
|  WM Indicated: Alcohol  Opioid  Stimulant   Candidate level: 2.7                                 |
|                                                                                                  |
|  Indicated LOC: 3.5   Actual LOC: [ picker ]                                                     |
|  Discrepancy Reasons: [ multi select - required if levels differ ]                                |
|                                                                                                  |
|  [ Proceed to Planning Mode ]                                                                     |
+--------------------------------------------------------------------------------------------------+

=====================================================
10) Sign and Seal
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Sign and Seal                                                                                   |
+--------------------------------------------------------------------------------------------------+
|  Attestation: I attest this assessment is accurate to my best clinical judgment.                 |
|  Clinician: <auto>   Date: <now>                                                                 |
|                                                                                                  |
|  Signature                                                                                        |
|  +------------------------------------------------------+                                        |
|  |  PencilKit canvas                                    |                                        |
|  +------------------------------------------------------+                                        |
|                                                                                                  |
|  Seal preview                                                                                   |
|  [ Plan ID: 7f9c...   Hash: 12ab34cd56ef   Status: pending ]                                     |
|                                                                                                  |
|  [ Sign and Seal ]   [ Clear signature ]   [ Back ]                                              |
+--------------------------------------------------------------------------------------------------+

=====================================================
11) Export with Preflight
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Export                                                                                          |
+--------------------------------------------------------------------------------------------------+
|  Preflight                                                                                       |
|  - 6 domain ratings present                     [ OK ]                                           |
|  - WM set or rationale documented               [ OK ]                                           |
|  - Discrepancy reasons captured if needed       [ OK ]                                           |
|                                                                                                  |
|  Template: Neutral Treatment Plan                                                                |
|  File name: TreatmentPlan_8xY7zQ.pdf                                                             |
|  Destination                                                                                     |
|  - [x] Save local sandbox                                                                        |
|  - [x] Upload to EMR as DocumentReference                                                        |
|                                                                                                  |
|  [ Export now ]                                                                                  |
|                                                                                                  |
|  Result                                                                                          |
|  - Local: saved                                                                                  |
|  - EMR: queued for upload                                                                        |
|                                                                                                  |
|  [ Share ]  [ View PDF ]  [ Done ]                                                               |
+--------------------------------------------------------------------------------------------------+

=====================================================
12) Sync diagnostics
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Sync Diagnostics                                                                                |
+--------------------------------------------------------------------------------------------------+
|  Queue                                                                                           |
|  - Job 1001  Upload PDF  FIN 900001   status: queued   retry in: 02:00                           |
|  - Job 1002  Observations FIN 900001  status: failed   last code: 413  [ Use Binary + DocRef ]  |
|                                                                                                  |
|  Network                                                                                         |
|  - Reachable: yes       Last check: 10:22                                                        |
|  - Auth token: valid    Expires: 11:45                                                           |
|                                                                                                  |
|  Actions                                                                                         |
|  [ Retry failed ]  [ Flush cache ]  [ Export logs ]                                              |
+--------------------------------------------------------------------------------------------------+

=====================================================
13) Audit
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Audit                                                                                           |
+--------------------------------------------------------------------------------------------------+
|  Time         User         Action                Target                MAC prefix                |
|  10:15        kjd          read Patient          MRN 112233            4a1c...                   |
|  10:16        kjd          write Assessment      Draft 7f9c            9b0e...                   |
|  10:17        kjd          sign                  Draft 7f9c            22aa...                   |
|  10:17        system       export                PDF 8xY7zQ            f0de...                   |
|                                                                                                  |
|  [ Filter ] [ Export CSV ]                                                                       |
+--------------------------------------------------------------------------------------------------+

=====================================================
14) Settings
=====================================================
+--------------------------------------------------------------------------------------------------+
|  Settings                                                                                        |
+--------------------------------------------------------------------------------------------------+
|  Security                                                                                        |
|  - Face ID on open: [ On ]   Idle lock: [ 2 minutes ]                                            |
|  - Clear sandbox on logout: [ On ]                                                               |
|                                                                                                  |
|  Data                                                                                            |
|  - Cache TTLs:  vitals 12h  meds 24h  demos 7d  encounters 72h                                  |
|  - Exclude from iCloud backup: [ On ]                                                            |
|                                                                                                  |
|  Integration                                                                                     |
|  - Tenant profile: <profile>                                                                     |
|  - Max PDF size: 8 MB    Upload strategy: Binary then DocumentReference                          |
|                                                                                                  |
|  Legal                                                                                           |
|  - Internal taxonomy only. No external names in UI.                                              |
+--------------------------------------------------------------------------------------------------+
