# STATE

Status: COMPLETED
Last task: auto-retry skill (rate-limit resume + remote-control for autonomous mode)
Mode: quick mode (retrospec, no upfront spec doc)

## Done
- claude-auto-retry integrated into `claude/install.sh` (installs binary + shell wrapper + `~/.claude-auto-retry.json` w/ STATE.md-forcing retryMessage)
- New skill `claude/skills/auto-retry/SKILL.md`
- `claude/CLAUDE.md` — Skills Ativos entry added
- `claude/.claude/agents/harness-infra.md` and `harness-dev.md` — rule 9 (Autonomous execution) updated: mandatory `--remote-control` at launch and on any hard relaunch; mandatory STATE.md re-read after any rate-limit resume

## Done (continued)
- Synced to `~/.claude/` (global): CLAUDE.md, agents/harness-infra.md, agents/harness-dev.md, skills/auto-retry/SKILL.md — diffed first, confirmed zero local-only content anywhere (agents/skills/steering), no overwrite risk
- `claude-auto-retry` installed globally (npm) + shell wrapper registered in `.bashrc`/`.zshrc` + `~/.claude-auto-retry.json` written
- Discovered during real install: nvm-managed Node breaks the wrapper silently on version switch — documented in SKILL.md, needs `claude-auto-retry install` re-run after any `nvm use`

## Pending / not done in this session
- Empirical test against a real rate-limit hit — user will trigger this naturally during normal autonomous use, not simulated here
- User must `source ~/.bashrc`/`~/.zshrc` (or open new shell) for the wrapper to take effect

## Done (task 3 — mid-task checkpoint frequency)
- Same 3-steps/15min cadence already used in rule 9 (autonomous) now applies to EVERY task, not just autonomous mode — reused existing constant, no new one invented
- `harness-infra.md` + `harness-dev.md`: rule 2 "DURING each task" gained checkpoint bullet; rule 5 transition list gained "Mid-task progress" entry
- `task-executor.md`: new rule 5b "Mid-task checkpoint" — progress note to STATE.md after each TDD cycle / ~15min for long single tasks, not just final Task Result
- Format/content of what's recorded unchanged per user request — only frequency changed
- Synced to `~/.claude/agents/` (all 3 files, diff-verified)
