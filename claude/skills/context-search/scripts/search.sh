#!/bin/bash
# Keyword search ("RAG-lite") over archived audit history + skills + steering.
# Usage: search.sh <query>
# Returns matching lines with 2 lines of context and file:line prefix.
# No match => empty output, exit 0 (not an error).
set -uo pipefail

QUERY="${1:-}"
if [[ -z "$QUERY" ]]; then
  echo "Usage: search.sh <query>" >&2
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "search.sh: not inside a git repository" >&2
  exit 2
fi

TARGETS=()
for d in ".specs/audit/archive" "claude/skills" "claude/steering"; do
  if [[ -d "$REPO_ROOT/$d" ]]; then
    TARGETS+=("$REPO_ROOT/$d")
  fi
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  exit 0
fi

# Resolve a real ripgrep binary. On some Claude Code sandboxes `rg` is only
# exposed as an interactive-shell function (not inherited by script
# subprocesses) that shells out to Claude Code's own bundled ripgrep via
# `exec -a rg <claude-binary>`. Prefer a real `rg` on PATH; fall back to the
# same trick if available; fail clearly otherwise.
run_rg() {
  if command -v rg >/dev/null 2>&1; then
    command rg "$@"
    return $?
  fi
  local cc_bin="${CLAUDE_CODE_EXECPATH:-}"
  if [[ -z "$cc_bin" || ! -x "$cc_bin" ]]; then
    cc_bin="$HOME/.local/bin/claude"
  fi
  if [[ -x "$cc_bin" ]]; then
    ( exec -a rg "$cc_bin" "$@" )
    return $?
  fi
  echo "search.sh: 'rg' (ripgrep) not found on PATH and no Claude Code bundled ripgrep available" >&2
  return 127
}

run_rg -n -C2 --no-heading -- "$QUERY" "${TARGETS[@]}"
RC=$?

# rg exit codes: 0 = match found, 1 = no match (not an error here), 2 = real error
if [[ $RC -eq 0 || $RC -eq 1 ]]; then
  exit 0
fi
exit "$RC"
