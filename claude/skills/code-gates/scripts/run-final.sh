#!/bin/bash
# Run ALL gates: tsc, eslint, jest, coverage, audit, sonar. Returns JSON.
set -euo pipefail
DIR="${1:-.}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Run step gates + checkpoint gates
STEP=$(bash "$SKILL_DIR/scripts/run-gates.sh" "$DIR" 2>/dev/null)
CHECKPOINT=$(bash "$SKILL_DIR/scripts/run-checkpoint.sh" "$DIR" 2>/dev/null)

# Merge results
RESULT=$(python3 -c "
import json, sys
step = json.loads('''$STEP''')
checkpoint = json.loads('''$CHECKPOINT''')
merged = step
merged['gates'].update(checkpoint['gates'])

# Sonar
sonar = {'status': 'SKIPPED', 'bugs': 0, 'vulnerabilities': 0, 'smells': 0, 'coverage': 0, 'duplications': 0}
merged['gates']['sonar'] = sonar
merged['overall'] = 'PASS'
for g in merged['gates'].values():
    if g['status'] == 'FAIL':
        merged['overall'] = 'FAIL'
        break
print(json.dumps(merged, indent=2))
")

# Try sonar if available
if command -v sonar-scan &>/dev/null && [ -n "${SONAR_HOST_URL:-}" ]; then
  SONAR_OUT=$(sonar-scan "$DIR" 2>&1) || true
  SONAR_GATE=$(echo "$SONAR_OUT" | grep "SONAR_GATE=" | cut -d= -f2)
  SONAR_BUGS=$(echo "$SONAR_OUT" | grep "bugs:" | awk '{print $2}' || echo 0)
  SONAR_VULNS=$(echo "$SONAR_OUT" | grep "vulnerabilities:" | awk '{print $2}' || echo 0)
  SONAR_SMELLS=$(echo "$SONAR_OUT" | grep "code_smells:" | awk '{print $2}' || echo 0)
  SONAR_COV=$(echo "$SONAR_OUT" | grep "coverage:" | awk '{print $2}' || echo 0)
  SONAR_DUP=$(echo "$SONAR_OUT" | grep "duplicated_lines_density:" | awk '{print $2}' || echo 0)
  [ -z "$SONAR_BUGS" ] && SONAR_BUGS=0
  [ -z "$SONAR_VULNS" ] && SONAR_VULNS=0
  [ -z "$SONAR_SMELLS" ] && SONAR_SMELLS=0
  [ -z "$SONAR_COV" ] && SONAR_COV=0
  [ -z "$SONAR_DUP" ] && SONAR_DUP=0
  RESULT=$(echo "$RESULT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
d['gates']['sonar']={'status':'${SONAR_GATE:-SKIPPED}','bugs':${SONAR_BUGS:-0},'vulnerabilities':${SONAR_VULNS:-0},'smells':${SONAR_SMELLS:-0},'coverage':${SONAR_COV:-0},'duplications':${SONAR_DUP:-0}}
if d['gates']['sonar']['status']=='FAIL': d['overall']='FAIL'
print(json.dumps(d,indent=2))
")
fi

echo "$RESULT"
