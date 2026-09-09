# Runbook — Branch Protection (require gate checks before merge)

Answers QUESTIONS.pt-BR.md #10 ("quero o runbook de como fazer isso pra todos os meus projetos"). **Deliberately not auto-applied by any agent session** — this changes real GitHub repo settings (admin action, `SPEC.md` scope boundary: "Creating GitHub repo secrets, enabling branch protection... on `rastaFul/agents-harness` or any product repo" was explicitly out of scope for the Gate Hardening initiative, and a cross-repo settings change is exactly the kind of action rule 9/escalation treats as needing an explicit, deliberate run — not something to fire off as a side effect of answering a questions file).

## Why

Right now `.github/workflows/gates.yml` runs and reports pass/fail, but nothing stops a merge if it fails — the checks are visible, not enforced. Branch protection with required status checks closes that gap.

## Prerequisites

- `gh` CLI authenticated with admin rights on the target repo (`gh auth status` — this session's own token already has `repo` scope, sufficient for personal repos you own).
- The repo must have run `.github/workflows/gates.yml` at least once on the target branch, so GitHub knows the check names to offer.
- **Plan limitation confirmed live, 2026-09-08 (not assumed):** both the classic branch-protection API (`PUT .../branches/{branch}/protection`) and the newer rulesets API (`POST .../rulesets`) returned the same `403`: `"Upgrade to GitHub Pro or make this repository public to enable this feature."` — **private repos on a free personal GitHub plan cannot use branch protection or rulesets at all**, regardless of endpoint. This blocks `agents-harness` and every other private repo (artists-booking, microgrow, rastafinancas, vetcare, infra-platform) unless one of:
  1. Upgrade the account to GitHub Pro (paid, unlocks this for all owned private repos), or
  2. Make the specific repo public (free, but changes real visibility — a deliberate per-repo decision, not something to default into).

  Neither was decided here — this runbook stops at "how to apply it once available," not "which of these two to choose." If/when one is chosen, the commands below work as documented.

## Steps (per repo)

```bash
REPO="rastaFul/agents-harness"   # change per repo: artists-booking, microgrow, rastafinancas, vetcare, infra-platform
BRANCH="main"

gh api -X PUT "repos/$REPO/branches/$BRANCH/protection" \
  -H "Accept: application/vnd.github+json" \
  -f required_status_checks.strict=true \
  -f 'required_status_checks.contexts[]=dev-gates' \
  -f 'required_status_checks.contexts[]=security-gates' \
  -f 'required_status_checks.contexts[]=infra-gates' \
  -f 'required_status_checks.contexts[]=perf-a11y-gates' \
  -f 'required_status_checks.contexts[]=policy-gate-status' \
  -f enforce_admins=true \
  -f required_pull_request_reviews.required_approving_review_count=0 \
  -f required_pull_request_reviews.require_code_owner_reviews=true \
  -f restrictions=null
```

Notes:
- `required_approving_review_count=0` — single-maintainer repos (CODEOWNERS is always `@rastaFul`, see `.github/CODEOWNERS`), so a human-approval-count requirement would just block yourself. `require_code_owner_reviews=true` still keeps the CODEOWNERS file meaningful for when/if that changes.
- `enforce_admins=true` — applies the rule to the owner too, not just external contributors. Set `false` if you want an escape hatch for emergency pushes (weigh against the "checks exist but don't block" problem this is meant to solve).
- Job names above are confirmed live against `agents-harness`'s first fully-green real run (`gh api repos/rastaFul/agents-harness/actions/runs/34292146125/jobs`, 2026-09-08) — not guessed. `build-sandbox` and `publish-image` deliberately excluded: `build-sandbox` is an implementation-detail dependency every other job already needs, and `publish-image` is a speed/reuse optimization (GHCR cache), not a required quality/security gate. `dev-gates`/`infra-gates`/`perf-a11y-gates` used to be JOB-level-conditional (`if: hashFiles(...)`) and could have stayed pending forever on repos missing the matching files — fixed (see git log, "hashFiles() not allowed in job-level if:") to use step-level guards instead, so these jobs now always report a real conclusion regardless of repo content. Still worth a quick check per-repo before enabling that all 5 job `id`s actually exist in whatever `gates.yml` version that repo has installed.

## Verify

```bash
gh api "repos/$REPO/branches/$BRANCH/protection" | python3 -m json.tool
```

## Rollback

```bash
gh api -X DELETE "repos/$REPO/branches/$BRANCH/protection"
```

## Rollout order (suggested, not automated)

1. `agents-harness` itself (lowest risk — template repo, no prod traffic).
2. `infra-platform` (once gates.yml is actually installed there).
3. Product repos one at a time (artists-booking, microgrow, rastafinancas, vetcare) — after confirming `gates.yml` has run green at least once on each.
