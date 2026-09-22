# Context Search

Keyword retrieval ("RAG-lite") over archived audit history, skills, and
steering docs — returns matching snippets (file:line + 2 lines of context),
never a whole file. Companion skill: `archive-session` (same skill directory)
moves closed-session entries out of `STATE.md`/`DECISIONS.md` so this script
has something small to search instead of re-reading the active files.

## Why keyword search, not embeddings

Decision recorded in `.specs/features/context-retrieval/spec.md`
("Decisão de arquitetura: RAG por embeddings é overkill aqui"). This repo's
corpus is small (~3500 lines across dozens of named, self-describing files),
not thousands of undifferentiated documents. Filenames and keywords already
discriminate well enough — a full embeddings pipeline (embedding model,
vector DB, re-sync on every write) adds real cost (API calls, a new
dependency, sync complexity) for an uncertain gain on a corpus this size.
`ripgrep` gives exact, fast, zero-infra keyword search with real file:line
provenance. The upgrade path to embeddings stays open if the corpus grows
enough to need semantic (not just lexical) matching — not the starting point.

## What it searches

- `.specs/audit/archive/` — archived (closed-session) STATE.md/DECISIONS.md
  history, written by `archive-session.sh`
- `claude/skills/` — all `SKILL.md` + scripts
- `claude/steering/` — all convention files

Deliberately NOT in scope: active `.specs/project/STATE.md`/`DECISIONS.md`
(read directly per rule 1, they're kept short), `claude/.claude/agents/`
(read directly, already small), anything outside the repo.

## Usage

```bash
bash claude/skills/context-search/scripts/search.sh "<query>"
```

- Runs `rg -n -C2` (2 lines of context) against the three directories above,
  resolved from the repo root via `git rev-parse --show-toplevel` (never
  hardcoded — works regardless of cwd).
- Output: one or more `path:line:` matches with surrounding context, never a
  full file.
- No match: empty output, exit `0` — absence of a hit is not an error.
- Missing query argument: usage message on stderr, exit `2`.

## Sandbox note (ripgrep resolution)

Some Claude Code sandboxes only expose `rg` as an interactive-shell function
that shells out to Claude Code's own bundled ripgrep binary (`exec -a rg
<claude-binary>`) — that function isn't inherited by script subprocesses, so
a plain `command -v rg` can fail even though ripgrep "works" when typed
directly at the prompt. `search.sh` handles this itself: it prefers a real
`rg` on `PATH`, and falls back to invoking the bundled ripgrep through
`$CLAUDE_CODE_EXECPATH` (or `~/.local/bin/claude`) the same way, before
failing with a clear error. No caller action needed either way.

## Companion: archiving

```bash
bash claude/skills/context-search/scripts/archive-session.sh <state-file> <archive-dir>
```

Moves closed-session blocks (`Status: ... DONE|COMPLETED|PARTIAL` through the
next `Status:` block or end of file) out of an active `.specs/project/*.md`
file into `<archive-dir>/YYYY-MM.md`, leaving a 1-line index entry
(`- [YYYY-MM-DD] <summary> → ver <archive-file>`) in its place. Never
deletes content — only relocates it. See the script's own header comment for
the exact block-boundary and date-inference rules.
