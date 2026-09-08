# Metrics — QUESTIONS.pt-BR.md rollout (Task 7)

- Date: 2026-09-08
- Scope: all 20 answered items in `QUESTIONS.pt-BR.md`
- Files changed: 20 (17 modified, 3 new: `.github/CODEOWNERS`, `renovate.json`, `docs/runbooks/*.md` x2)
- Docker rebuilds: 1 full (`--no-cache`, sandbox image) + ~11 throwaway verification builds (batched functional checks, fixture tests, bug repro/fix cycles)
- Real bugs found and fixed during verification (beyond the planned changes): 2
  - `xargs` empty-stdin crash (exit 123) — crashed the entire final infra-quality gate script on any repo with zero `.tf` files
  - Polaris + kube-linter stderr merged into stdout via `2>&1`, silently corrupting JSON parsing (danger/warning/reports counts always reported as 0 regardless of real findings)
- Tools functionally re-verified (real execution, not file presence) after Dockerfile changes: 14 (arch-mapped) + 2 (Polaris/kube-linter fixture-based)
- Gates run: bash -n (8 scripts), JSON validity (3 files), yamllint (1), hadolint (0 findings), docker build (REAL_EXIT=0, marker-verified), functional --version checks, 2 fixture-based end-to-end script runs
- Escalations: 0 (no gate failed 3x consecutively; the 2 found bugs were fixed on first attempt each after real repro)
- Deliberately NOT auto-applied (documented as runbooks instead, per explicit user request or original SPEC.md scope boundary): INFRACOST_API_KEY provisioning (needs human account creation), branch protection (cross-repo admin action)
