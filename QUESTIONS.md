# Open Questions — Gate Hardening Initiative (2026-09-03)

**STATUS 2026-09-08: all items below RESOLVED.** The user answered every item in `QUESTIONS.pt-BR.md` (Portuguese) and every decision was executed the same session — see `.specs/project/DECISIONS.md` ("2026-09-08 — QUESTIONS.pt-BR.md rollout") for the full rationale per item and `.specs/audit/execution.md` Task 7 for gate results. This file is kept as-is below for historical record of what was originally open and why; item 20 already had its own inline resolution from the previous pass.

Everything here was deliberately **not decided** by me or by the 3 delegated agents — either because it's a business/threshold call, needs a credential/account I don't have, or needs live verification none of us could do from this sandbox. Nothing below was guessed into the implementation; where a script needed *something* to not crash, it defaults to reporting `INFO`/`SKIPPED` instead of enforcing an invented number — see each item.

## Thresholds (business decisions, not technical ones)

1. **Infracost cost-delta threshold.** `harness-gates/SKILL.md` always said "flag for review if cost increase > threshold" but never defined the number. `skills/cost-gates` reports the monthly delta as `INFO`, does not block. Needs: a $ or % number.
2. **Lighthouse CI minimum scores** (performance/accessibility/best-practices/SEO, 0-100 each). `skills/perf-a11y-gates` reports scores as `INFO`, does not block. Needs: 4 numbers, or a decision that only some categories should block.
3. **Stryker mutation-score threshold.** Ships with Stryker's own scaffold default (`thresholds.break: null` — doesn't fail a build). Needs: a real number, ideally after measuring a baseline mutation score on an actual project first (per the dev-quality agent's own recommendation).
4. **jscpd duplication threshold.** Ships with no threshold (tool default = report-only). Needs: a % duplication ceiling, if one is wanted at all.
5. **Semgrep severity → block mapping.** Semgrep's taxonomy is `ERROR`/`WARNING`/`INFO`, not the CVSS-style critical/high/medium/low used everywhere else in this repo. Script currently blocks only on `ERROR` (provisional). Should `WARNING` also block?
6. **osv-scanner "unscored" findings** (no normalized severity label — some ecosystems only expose a raw CVSS vector). Currently fail-open (don't block). Should these fail-closed (treated as HIGH) instead?
7. **Uniform 0-critical/0-high bar across all 6 security tools?** Applied the existing `npm audit` bar (from `steering/dependency-audit.md`) uniformly to trivy_fs/osv-scanner/trivy_config/sbom_grype. Should IaC misconfig severity (trivy config) have a different bar than dependency/code vulnerabilities?

## Credentials / accounts I don't have

8. **`INFRACOST_API_KEY`.** Referenced in `.github/workflows/gates.yml` as `${{ secrets.INFRACOST_API_KEY }}` — the GitHub Actions secret does not exist yet. Cost gate `SKIPPED`s cleanly without it, doesn't break the pipeline, but has zero coverage until provisioned.
9. **Container registry for the sandbox image (ghcr.io/rastaFul/...).** Mostly RESOLVED — I deliberately avoided needing this by having CI build `Dockerfile.sandbox` fresh instead of pulling a published image (see `.github/workflows/gates.yml` header comment). Still worth deciding later purely as a CI-speed optimization (build takes minutes, a cached pull would be faster), but it's no longer a blocker for local==CI correctness.

## Governance actions requiring GitHub admin access (not taken — out of scope per SPEC.md)

10. **Branch protection requiring the new gate checks to pass before merge.** Without this, `.github/workflows/gates.yml` runs and reports, but doesn't actually block a merge — same "trust" problem as before, just moved one layer. Needs someone with admin on `rastaFul/agents-harness` (and later, each product repo) to enable it in repo settings.
11. **CODEOWNERS for human review on sensitive paths** (was on the original suggested-tools list, never implemented — no file created). Needs a decision on which paths (infra/, security-critical code) and who the owners are.

## Reproducibility / maintenance follow-ups

12. **Polaris, pluto, kubeconform, kube-linter are pinned to `/releases/latest/download/...`** in `Dockerfile.sandbox`, not a fixed version — unlike gitleaks/osv-scanner/kube-bench/opa/conftest/infracost/terraform-docs/tflint, which I verified and pinned to exact current versions via live GitHub lookups. The infra-quality agent couldn't verify per-version asset filenames from its sandbox (no network access there); using `/latest/` avoided guessing a wrong filename, but means those 4 tools will silently drift to whatever is newest at each image build. Recommend pinning once someone confirms the asset-name pattern is stable across versions.
13. **6 new pinned tool versions in `Dockerfile.sandbox`** (gitleaks, osv-scanner, kube-bench, opa, conftest, infracost) plus the pre-existing `SONAR_SCANNER_VERSION` — is there a renovate/dependabot rule covering this file already, or should one be set up so these don't go stale silently? Not checked, flagged by the security-gates agent.
14. **Multi-arch (arm64) support.** `gitleaks`, `osv-scanner`, `kube-bench` install commands are pinned to `linux_x64`/`linux_amd64` assets with no `uname -m` arch-detection, unlike `tfsec`/`kube-score`/`trivy`/`syft`/`grype`'s existing install scripts, which auto-detect. Only matters if this image ever needs to build for arm64 — don't know if that's a requirement.
15. **`terraform-docs --output-check` exact invocation** in `run-infra-quality-final.sh` — the implementing agent couldn't execute a live binary to confirm flag placement. Verify against the actual pinned v0.24.0 binary once the image builds successfully.
16. **Polaris JSON field names** (`DangerResultCount`/`WarningResultCount`) in the same script are a best-effort parse (schema may have shifted across Polaris versions) — PASS/FAIL is driven by Polaris's own `--set-exit-code-on-danger` exit code, not by these fields, specifically so an unverified schema guess can't silently produce a wrong result. Worth confirming the parsed fields once the tool actually runs.

## Process inconsistency I introduced myself (not a sub-agent finding about someone else — about my own work this session)

17. **`install.sh` auto-runs `npm install -D axe-playwright`** into a target project's `package.json` when one exists (my own Phase 5 addition), but the dev-quality bundle's devDependencies (husky, lint-staged, commitlint, dependency-cruiser, eslint-plugin-sonarjs, jscpd, Stryker) are **document-only** — printed as a command, not auto-run. The dev-quality agent flagged this exact inconsistency in its own report without knowing I'd caused it. Needs one consistent policy: auto-install everywhere a `package.json` exists, or document-only everywhere.

## RESOLVED since original pass

20. ~~**`sonar-scanner` fails to run**~~ — **FIXED 2026-09-04** (`.specs/audit/execution.md` Task 6). Root cause: bundled JRE inside `sonar-scanner-cli` is glibc-linked; `gcompat` isn't enough for a full JVM. Fix: disabled the embedded JRE (`use_embedded_jre=false` via sed on the launcher script) and installed Alpine's own musl-native `openjdk17-jre-headless` instead — scoped to sonar-scanner only, no image-wide glibc shim or base-image swap. Verified by actually running `sonar-scanner --version` inside a real build (not just file presence). All 23/23 gate tools in `Dockerfile.sandbox` now functionally verified (was 22/23). This also closes gap #4 from the original 2026-09-02 audit ("SonarQube probably never actually runs in practice") for real.

## Rollout (deliberately out of scope this pass, per SPEC.md)

18. **When/how to roll this out to product repos** (artists-booking, microgrow, rastafinancas, vetcare) and to `infra-platform` itself. This pass only touched `agents-harness` (the template source). Rollout means re-running `install.sh` per project and dealing with whatever's already there (same care taken during the earlier `~/.claude` sync — diff first, never blind-overwrite).
19a. **`harness-dev.md` was NOT updated with references to the new gate skills** — only `harness-infra.md` rule 3 got the "Policy-as-code / Infra quality / Security scanning / Cost" bullet list added this session. The dev-relevant new gates (dependency-cruiser, jscpd/sonarjs, Stryker via `code-gates`, security-gates, perf-a11y-gates) exist and work but `harness-dev.md`'s own gate table doesn't mention them yet — same "written but orphaned" risk flagged for `run-final.sh` below, at the orchestrator-doc level instead of the script level. Not done this pass; noting explicitly rather than leaving a silent inconsistency between the two orchestrator docs.
19. **`run-final.sh` (code-gates) not yet wired to call the 3 new dev-quality scripts** (`run-architecture-gate.sh`, `run-quality-extra.sh`, `run-mutation.sh`). They work standalone; wiring them into the existing final-gate aggregation is a natural next step, not done this pass (wasn't in the explicit deliverable list given to the dev-quality agent).
