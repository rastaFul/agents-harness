# Code Gates

Scripts to run TypeScript/Node.js quality gates and return structured JSON results.

## Usage

### Per-step gates (fast, ~3s)
```bash
bash skills/code-gates/scripts/run-gates.sh [project-dir]
```
Runs: tsc → eslint → jest. Returns JSON.

### Checkpoint gates (every 3 tasks)
```bash
bash skills/code-gates/scripts/run-checkpoint.sh [project-dir]
```
Runs: coverage → npm audit. Returns JSON.

### Final gates (after all tasks)
```bash
bash skills/code-gates/scripts/run-final.sh [project-dir]
```
Runs: tsc → eslint → jest → coverage → npm audit → sonar-scan. Returns JSON.

## Output Format

```json
{
  "timestamp": "2026-01-01T12:00:00-03:00",
  "gates": {
    "tsc": {"status": "PASS", "errors": 0},
    "eslint": {"status": "PASS", "errors": 0, "warnings": 2},
    "jest": {"status": "PASS", "total": 27, "passed": 27, "failed": 0},
    "coverage": {"status": "PASS", "statements": 95, "branches": 88},
    "audit": {"status": "PASS", "critical": 0, "high": 0},
    "sonar": {"status": "SKIPPED"}
  },
  "overall": "PASS"
}
```
