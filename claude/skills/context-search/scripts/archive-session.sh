#!/bin/bash
# Move closed-session entries out of a STATE.md/DECISIONS.md-style file into
# .specs/audit/archive/YYYY-MM.md, leaving a 1-line index in their place.
# Usage: archive-session.sh <active-file> <archive-dir>
#
# Detection rules:
#   - If the file has lines starting with "Status" (STATE.md style): a block
#     runs from one such line up to (not including) the next one, or EOF.
#     A block is CLOSED (archived) only if its Status line contains DONE,
#     COMPLETED, or PARTIAL as a whole word — e.g. "Status: EXECUTING..." is
#     left alone (open session), "Status: COMPLETED (Task 7)..." is archived.
#   - Otherwise, if the file has "## " top-level headings (DECISIONS.md
#     style, no Status markers at all): every entry is treated as closed and
#     archived — this file's own convention is "every entry is a past
#     decision", there is no "open" entry concept for it.
#   - Archive month (YYYY-MM.md) is inferred from the first YYYY-MM-DD date
#     found in the block (heading line first, then full block text). No date
#     found anywhere in the block => falls back to today's date. This is a
#     best-effort heuristic, not a guarantee — documented limitation.
# Never deletes: closed blocks are written verbatim to the archive file
# before being removed from the active file.
set -uo pipefail

ACTIVE_FILE="${1:-}"
ARCHIVE_DIR="${2:-}"

if [[ -z "$ACTIVE_FILE" || -z "$ARCHIVE_DIR" ]]; then
  echo "Usage: archive-session.sh <active-file> <archive-dir>" >&2
  exit 2
fi

if [[ ! -f "$ACTIVE_FILE" ]]; then
  echo "archive-session.sh: active file not found: $ACTIVE_FILE" >&2
  exit 2
fi

mkdir -p "$ARCHIVE_DIR"

python3 - "$ACTIVE_FILE" "$ARCHIVE_DIR" <<'PYEOF'
import sys
import re
import os
import datetime

active_path, archive_dir = sys.argv[1], sys.argv[2]

with open(active_path, encoding='utf-8') as f:
    lines = f.readlines()

STATUS_RE = re.compile(r'^Status\b')
HEADING_RE = re.compile(r'^##\s')
CLOSED_WORDS_RE = re.compile(r'\b(DONE|COMPLETED|PARTIAL)\b')
DATE_RE = re.compile(r'\d{4}-\d{2}-\d{2}')
STATUS_PREFIX_RE = re.compile(r'^Status(\s*\([^)]*\))?\s*:\s*')

today = datetime.date.today().isoformat()

status_idx = [i for i, l in enumerate(lines) if STATUS_RE.match(l)]

if status_idx:
    mode = 'state'
    preamble_end = status_idx[0]
    boundaries = status_idx + [len(lines)]
    blocks = [(status_idx[k], lines[status_idx[k]:boundaries[k + 1]])
              for k in range(len(status_idx))]
else:
    heading_idx = [i for i, l in enumerate(lines) if HEADING_RE.match(l)]
    if heading_idx:
        mode = 'all'
        preamble_end = heading_idx[0]
        boundaries = heading_idx + [len(lines)]
        blocks = [(heading_idx[k], lines[heading_idx[k]:boundaries[k + 1]])
                  for k in range(len(heading_idx))]
    else:
        mode = 'none'
        preamble_end = len(lines)
        blocks = []

preamble = lines[:preamble_end]


def is_closed(block_lines):
    if mode == 'state':
        return bool(CLOSED_WORDS_RE.search(block_lines[0]))
    if mode == 'all':
        return True
    return False


def extract_date(block_lines):
    if mode == 'all':
        m = DATE_RE.search(block_lines[0])
        if m:
            return m.group(0)
    text = ''.join(block_lines)
    m = DATE_RE.search(text)
    if m:
        return m.group(0)
    return today


def first_sentence(text, max_len=200):
    text = ' '.join(text.split())
    m = re.search(r'.{1,%d}?[.!?](?=\s|$)' % max_len, text)
    if m:
        return m.group(0).strip()
    candidate = text[:max_len].strip()
    if len(text) > max_len:
        candidate += '...'
    return candidate


def extract_summary(block_lines):
    if mode == 'state':
        first_line = block_lines[0].rstrip('\n')
        stripped = STATUS_PREFIX_RE.sub('', first_line).strip()
        if not stripped and len(block_lines) > 1:
            stripped = ' '.join(l.strip() for l in block_lines[1:3])
        return first_sentence(stripped)
    if mode == 'all':
        heading = block_lines[0].strip().lstrip('#').strip()
        parts = heading.split('—', 1)  # em dash, this repo's convention
        title = parts[1].strip() if len(parts) == 2 else heading
        return first_sentence(title)
    return ''


kept_lines = list(preamble)
index_lines = []
archived_count = 0

for _, block_lines in blocks:
    if is_closed(block_lines):
        date = extract_date(block_lines)
        month = date[:7]
        summary = extract_summary(block_lines)
        archive_file = os.path.join(archive_dir, f'{month}.md')
        is_new_file = not os.path.exists(archive_file)
        with open(archive_file, 'a', encoding='utf-8') as af:
            if is_new_file:
                af.write(f'# Archive {month}\n\n')
            af.writelines(block_lines)
            if block_lines and not block_lines[-1].endswith('\n'):
                af.write('\n')
            af.write('\n')
        index_lines.append(f'- [{date}] {summary} → ver {archive_file}\n')
        archived_count += 1
    else:
        kept_lines.extend(block_lines)

if index_lines:
    if kept_lines and not kept_lines[-1].strip() == '':
        kept_lines.append('\n')
    kept_lines.append('### Índice arquivado\n')
    kept_lines.extend(index_lines)

with open(active_path, 'w', encoding='utf-8') as f:
    f.writelines(kept_lines)

print(f'archived {archived_count} block(s); mode={mode}')
PYEOF
