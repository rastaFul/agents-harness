# DECISIONS

## 2026-09-02 — claude-auto-retry lives in agents-harness, not infra-platform
Rationale: it's meta-tooling for how Claude Code agents run (session/rate-limit management), not cloud infra. agents-harness already owns autonomous-mode rules (rule 9) and has the install.sh pattern (mirrors `install_snip`). Ansible project was considered and rejected — it would configure a remote server to manage a local CLI session, wrong layer.

## 2026-09-02 — retryMessage forces STATE.md re-read instead of blind "continue"
Rationale: claude-auto-retry's tmux send-keys injection cannot detect special confirmation prompts (upstream limitation) — treating its resume as guaranteed context-perfect is unsafe. Pairing it with the harness's own checkpoint protocol (every 3 steps/15min) makes the imperfect injection safe: worst case the agent re-grounds like a fresh session.

## 2026-09-02 — mid-task checkpoint frequency generalized to every task
Rationale: rule 9's 3-steps/15min checkpoint only applied to autonomous mode — a normal task interrupted mid-flight (rate limit, crash) had no intermediate record, only IN_PROGRESS at start and DONE/FAILED at end. Reused the existing cadence constant instead of introducing a second one. Format/content unchanged (user explicit constraint) — only write frequency increased. Applied to harness-infra.md, harness-dev.md (rules 2 and 5) and task-executor.md (new rule 5b), synced to ~/.claude.

## 2026-09-02 — --remote-control mandatory for all autonomous launches and hard relaunches
Rationale: user follows autonomous runs from mobile. Native Claude Code `--remote-control` flag covers this with no inbound ports / no infra change. claude-auto-retry resumes the *same* process (remote-control persists automatically), but a hard relaunch after a crash creates a genuinely new session — that must explicitly re-add the flag, since crash time is exactly when nobody's at the terminal.
