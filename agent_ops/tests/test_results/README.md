# Test Results Tracking

This directory contains all test execution results for the ASAM Assessment application.

## Structure

```
test_results/
├── smoke/              # Smoke test runs
├── unit/               # Unit test runs
├── integration/        # Integration test runs
├── TEST_HISTORY.md     # Chronological log of all test runs
└── latest.json         # Most recent test result (symlink or copy)
```

## Test Result Format

Each test run creates a JSON file with this structure:

```json
{
  "run_id": "20251110_143022",
  "timestamp": "2025-11-10T14:30:22Z",
  "type": "smoke|unit|integration|full",
  "status": "pass|fail|blocked",
  "summary": {
    "total": 45,
    "passed": 42,
    "failed": 3,
    "skipped": 0
  },
  "duration_seconds": 123.45,
  "environment": {
    "xcode_version": "15.0",
    "simulator": "iPhone 15",
    "ios_version": "17.0"
  },
  "blockers": [],
  "failures": [],
  "raw_output": "..."
}
```

## Usage

### View Latest Results
```bash
cat agent_ops/tests/test_results/latest.json | jq
```

### View Test History
```bash
cat agent_ops/tests/test_results/TEST_HISTORY.md
```

### Run Smoke Test
```bash
./scripts/run-smoke-tests.sh
```
