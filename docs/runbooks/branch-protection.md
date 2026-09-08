# Runbook — Branch Protection (require gate checks before merge)

Answers QUESTIONS.pt-BR.md #10 ("quero o runbook de como fazer isso pra todos os meus projetos"). **Deliberately not auto-applied by any agent session** — this changes real GitHub repo settings (admin action, `SPEC.md` scope boundary: "Creating GitHub repo secrets, enabling branch protection... on `rastaFul/agents-harness` or any product repo" was explicitly out of scope for the Gate Hardening initiative, and a cross-repo settings change is exactly the kind of action rule 9/escalation treats as needing an explicit, deliberate run — not something to fire off as a side effect of answering a questions file).

## Why

Right now `.github/workflows/gates.yml` runs and reports pass/fail, but nothing stops a merge if it fails — the checks are visible, not enforced. Branch protection with required status checks closes that gap.

## Prerequisites

- `gh` CLI authenticated with admin rights on the target repo (`gh auth status` — this session's own token already has `repo` scope, sufficient for personal repos you own).
- The repo must have run `.github/workflows/gates.yml` at least once on the target branch, so GitHub knows the check names to offer.

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
  -f 'required_status_checks.contexts[]=policy-gate-status' \
  -f enforce_admins=true \
  -f required_pull_request_reviews.required_approving_review_count=0 \
  -f required_pull_request_reviews.require_code_owner_reviews=true \
  -f restrictions=null
```

Notes:
- `required_approving_review_count=0` — single-maintainer repos (CODEOWNERS is always `@rastaFul`, see `.github/CODEOWNERS`), so a human-approval-count requirement would just block yourself. `require_code_owner_reviews=true` still keeps the CODEOWNERS file meaningful for when/if that changes.
- `enforce_admins=true` — applies the rule to the owner too, not just external contributors. Set `false` if you want an escape hatch for emergency pushes (weigh against the "checks exist but don't block" problem this is meant to solve).
- Job names (`dev-gates`, `security-gates`, `infra-gates`, `policy-gate-status`) must match `.github/workflows/gates.yml` job `id`s exactly — some jobs (`dev-gates`, `infra-gates`) are conditional (`if: hashFiles(...)`) and won't report if the condition is false; GitHub treats a job that never ran as neither pass nor fail for a required check, which can block merges on repos that legitimately have no `package.json`/`*.tf`. Verify per-repo before enabling — remove a context from the list above if that repo will never have that job run.

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
