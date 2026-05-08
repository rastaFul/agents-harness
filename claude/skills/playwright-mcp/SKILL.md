# Playwright MCP

Visual automation gate using Playwright as an MCP server. E2E testing, visual regression, and UI flow validation in a real browser. Source: https://github.com/microsoft/playwright-mcp

## Setup

```bash
npx @playwright/mcp@latest
```

Add to MCP config (`.claude/settings.json` or `~/.claude/settings.json`):
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

## Gate Protocol

```
WRITE TEST (Red — must fail) → IMPLEMENT → RUN GATE → PASS? → register result
                                                       ↓ FAIL
                                              analyze → fix → re-run (max 5)
```

1. Write E2E test BEFORE implementation (TDD Red)
2. Confirm test fails
3. Implement feature
4. Run Playwright gate — must PASS before task is DONE
5. Save screenshots to `.specs/features/[feature]/screenshots/`
6. Register in `execution.md`: `playwright: PASS|FAIL (X tests, Y passed)`

## Trigger

Activate for: any task with visual output (component, page, flow), visual acceptance criteria in spec, checkpoint on UI features (every 3 tasks).

Trigger keywords: E2E, visual, regression, flow, browser, screenshot, automation.

Do NOT activate for: unit tests (Jest), backend tasks, TDD Red phase, static analysis.

## Files

| File | Access | Purpose |
|------|--------|---------|
| `e2e/**/*.spec.ts` | Read + Write | E2E test files |
| `playwright.config.ts` | Read | Runner configuration |
| `.specs/audit/execution.md` | Write | Gate result with timestamp |
| `.specs/features/[feature]/screenshots/` | Write | Visual evidence |
| `steering/visual-automation.md` | Read | Thresholds and scope rules |

## Visual Regression

- First run → creates baseline (no diff)
- Subsequent runs → compare vs baseline
- Diff > 5% → FAIL → require human approval to update baseline

## Rules

1. Never replace Jest — Playwright tests flows and UI; Jest tests logic
2. App server must be running before invoking Playwright gate
3. Register every gate result in `execution.md` with timestamp
4. Critical user flows must have 100% E2E coverage (as defined in spec)
