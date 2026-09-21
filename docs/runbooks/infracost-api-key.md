# Runbook — Provisioning `INFRACOST_API_KEY`

Answers QUESTIONS.pt-BR.md #8 ("o que eu preciso para ter essa informação?"). This is a real external-account step — the agent cannot create it on your behalf (needs your email/interaction), so it's documented here instead of auto-run.

## Why it's needed

`skills/cost-gates/scripts/run-cost-gate.sh` calls `infracost breakdown`, which needs an API key to price resources against cloud provider catalogs. Without it, the gate reports `SKIPPED` — zero coverage, doesn't break the pipeline.

## Steps

1. **Sign up (free, no credit card)**: https://www.infracost.io/ → "Get Free API Key" (or `infracost auth login` from a machine with the CLI installed — same result, opens a browser flow).
2. **Get the key**: after signup, the key is shown in the dashboard (https://dashboard.infracost.io/org/settings) or printed by `infracost configure get api_key` if you signed up via the CLI.
3. **Add as a GitHub Actions secret**, per repo that runs `.github/workflows/gates.yml`:
   ```bash
   gh secret set INFRACOST_API_KEY --repo rastaFul/agents-harness
   # paste the key when prompted, or:
   echo "<your-key>" | gh secret set INFRACOST_API_KEY --repo rastaFul/agents-harness
   ```
   Repeat per product repo once this template is rolled out there (rastafinancas e outros repositórios privados do usuário) — each repo's Actions secrets are independent, this is not inherited automatically.
4. **Local use** (agent running gates outside CI): export the same key as an env var before invoking the sandbox —
   ```bash
   export INFRACOST_API_KEY="<your-key>"
   ```

## Threshold reminder

Once the key is set, the gate blocks (`FAIL`) on **any monthly cost above $0** — the agreed baseline while infra stays local-only (QUESTIONS.pt-BR.md #1). This is intentional: it should almost never fire until you deliberately provision a first paid cloud resource, at which point revisit the threshold (see the note in `run-cost-gate.sh`) to switch to a true diff-based gate instead of an absolute-zero one.

## Free tier limits

Infracost's free tier covers unlimited `breakdown`/`diff` runs for personal/small projects — no cost to provisioning this. If usage ever needs the paid tier, that's a separate decision, not implied by this runbook.
