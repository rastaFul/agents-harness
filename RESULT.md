# Gate Hardening — Result (autonomous run, 2026-09-03)

## Latest — Product-repo rollout complete (2026-09-09)
Rolled out the full agent + gate bundle to all 5 remaining repos (artists-booking, microgrow, rastafinancas, vetcare, infra-platform) — a scoped `.specs/features/harness-gates-rollout/spec.md` per repo, `install.sh` run against each, only harness-installation files staged/committed (never pre-existing WIP in any repo).

Doing this for real, against real repos and real CI, surfaced **11 more real bugs** no local check could have caught (Zone.Identifier junk files polluting installs, `lint-staged` git-version floor, a `grep -c || echo 0` duplication bug hit 3 separate times across different scripts, missing workflow `permissions:`, a hardcoded GHCR image name). All fixed centrally and propagated everywhere + synced to `~/.claude` — full list in `.specs/project/DECISIONS.md` ("2026-09-09") and `.specs/audit/execution.md` Task 9.

**Verified final state (`gh api` on completed runs, never a trusted notification): 4/5 repos fully green** end to end. **infra-platform is red for a real reason, not a bug**: `infra-gates` found 2 genuine, previously-unknown checkov findings against the live production OCI compute instance Terraform (boot-volume encryption, legacy metadata endpoint) — deliberately not auto-fixed, since that's a running instance and the fix may require replacement (real blast radius) — escalated to the user, not guessed at.

Spec: `.specs/project/SPEC.md`. Open questions (not decided, no guesses made): `QUESTIONS.md`. Full checkpoint trail: `.specs/project/STATE.md`. Per-task gate log: `.specs/audit/execution.md`.

## Caveat on "autonomous mode" — read this first

Rule 9 (autonomous execution) calls for launching a *separate* `claude --agent harness-infra --remote-control` process. This work instead ran inside the **existing interactive session** — I can't self-relaunch with CLI flags from inside a running conversation. I applied the spirit of rule 9 within this session (delegation to sub-agents, parallel work, checkpoints every 3 steps/15min, circuit-breaker discipline) but **`--remote-control` was not active for this run** — if you weren't watching, you wouldn't have gotten mobile visibility into it the way rule 9 promises for a real autonomous launch. Flagging this rather than silently claiming full rule-9 compliance.

## What was done

### Phase 1 — Local == CI mechanism, policy-as-code
- `.github/workflows/gates.yml` — builds `docker/Dockerfile.sandbox` fresh in CI and runs the exact same skill scripts used locally, in the exact same container. No published registry image needed for this guarantee (deliberate simplification — see file header comment).
- `skills/policy-gates/` — OPA/Conftest. `policies/terraform.rego` + `policies/kubernetes.rego` translate the **structurally-checkable** subset of `skills/harness-gates/references/policies.md` hard rules into code that blocks mechanically (SG 0.0.0.0/0, mandatory tags, static IAM keys, public buckets, encryption-at-rest, `:latest` tags, missing resource limits/health checks, Ingress without TLS). Process-sequencing rules (destroy approval, plan-before-apply, no state commit) documented as deliberately out of scope for static analysis.
- Rego syntax bug caught by external verification (`opa check` via docker, opa not installed locally) — old syntax missing `if`/`contains` keywords, fixed, re-verified PASS.

### Phase 2 — Security (delegated to task-executor, parallel)
- `skills/security-gates/` — gitleaks, trivy fs/config (extends the trivy already in the image), osv-scanner, semgrep, syft+grype (SBOM), kube-bench (documented as cluster-only, deliberately not scripted). Verified with a functional smoke test using mocked tool binaries, not just `bash -n`. 5 open questions logged, not decided (severity-mapping calls — see QUESTIONS.md).

### Phase 3 — Dev quality (delegated, parallel)
- `skills/code-gates/` extended with `run-architecture-gate.sh` (dependency-cruiser), `run-quality-extra.sh` (jscpd + sonarjs complexity), `run-mutation.sh` (Stryker).
- `templates/dev-quality/` — real, ready-to-use config templates: `.dependency-cruiser.cjs` (translates `steering/architecture.md`'s Clean Architecture layering into enforced rules, with inline comments quoting the source prose line), `.jscpd.json`, `stryker.conf.json`, `commitlint.config.cjs`, `lint-staged.config.cjs`, `.husky/pre-commit` + `commit-msg` + `setup-husky.sh`.
- 4 open questions logged (mutation/duplication thresholds, install.sh auto-run policy, `run-final.sh` wiring).

### Phase 4 — Infra quality (delegated, parallel)
- `skills/infra-quality-gates/` — tflint, terraform-docs (check mode), Polaris, pluto, kubeconform, kube-linter (fixes a gap that existed BEFORE this session: `harness-infra.md` cited kube-linter as a gate tool, it was never installed). terratest/helm-unittest documented as per-project test-authoring patterns, not fake generic scripts (the agent's own judgment call, and the right one — a static script can't fabricate a real behavioral test).
- Found: **Helm and Go were completely absent from the sandbox image** — a pre-existing gap (helm lint/helm template were already cited as gates in `harness-infra.md` with no working binary). Both now installed.

### Phase 5 — Cost + perf/a11y
- `skills/cost-gates/` (Infracost) and `skills/perf-a11y-gates/` (Lighthouse CI + axe-core/playwright, injected into the *existing* Playwright MCP session rather than a second browser instance). Both report `INFO`, deliberately don't block — no threshold was ever agreed for either (see QUESTIONS.md).

### The sandbox image had never actually built — 10 real bugs found via genuine `docker build` + functional verification, not inspection

`docker/Dockerfile.sandbox` was never test-built before this session (best evidence: bug #1 below was in the very first `apk add` line). Found and fixed across 10 build attempts, each converging on the next real failure:

1. **`terraform` was never a valid apk package** in Alpine (BUSL-licensed, not apk-distributed — only the `opentofu` fork is; confirmed via `apk search -x terraform` = empty). Pre-existing. Fixed: real Terraform installed via HashiCorp's official binary release, pinned **v1.16.1** (my first guess, v1.17.0, was itself wrong — scraped from HTML text that wasn't an actual release; corrected against the authoritative `releases.hashicorp.com/terraform/index.json`, verified by downloading the real file before touching the Dockerfile again).
2. **`npm install -g npm@latest`** on `node:20-alpine` pulls npm 12.x, which requires Node ≥22 — always failed (EBADENGINE). Pre-existing. Fixed: removed (Node 20 already bundles a sufficient npm 10.8.2).
3. **tfsec's official install script** has two independent problems on this image: calls the (rate-limited, and rate-limited-by-me-this-session) GitHub API to resolve "latest", and its checksum step uses `sha256sum --quiet`, a GNU-only flag Alpine's busybox `sha256sum` doesn't support. Pre-existing. Fixed: switched to a direct pinned binary download (v1.28.14), bypassing the script entirely.
4. **kube-score's `install.sh` no longer exists upstream** (both `master` and `main` 404 on raw.githubusercontent.com — the script was removed at some point). Pre-existing, dead since whenever that happened. Fixed: direct binary download (v1.20.0).
5. **infracost's install line pointed at the wrong, deprecated repo** (`infracost/infracost`, whose own script says "only <1.0.0, see infracost/cli for >=2.0.0"). Fixed: switched to the real current repo (`infracost/cli`, v2.16.2) — confirmed working: `infracost version 2.16.2`.
6. **Polaris/pluto's guessed `/latest/download/` filenames were wrong** (their real release assets embed the version number in the filename). Fixed: pinned versions (10.2.2 / 5.24.3) with correct filenames, verified before editing. kubeconform/kube-linter's guessed filenames turned out correct, left as-is (still unpinned, see QUESTIONS.md #12).
7. **helm's official install script needs `openssl`** for checksum verification, absent from the base image. Fixed: added to `apk add`.
8. **`unzip`** was used by the SonarQube scanner step with no `apk add unzip` ever declared — latent, worked by accident. Fixed: added explicitly, along with `tar`.
9. **6 raw `curl -o` downloads had no `-f` (fail-on-HTTP-error)** — the exact mechanism that turned bug #1's wrong version guess into a confusing `unzip` parse error instead of a clear 404. Fixed across all of them (terraform, terraform-docs, polaris, pluto, kubeconform, kube-linter, and the pre-existing sonar-scanner line) — systemic fix, not a one-off.
10. **The `infracost` binary is glibc-linked**; Alpine is musl-based and has no glibc at all. Passed every earlier check (right ELF, right architecture) and still failed to execute with a misleading "not found" — traced with `readelf -l` to a missing `/lib64/ld-linux-x86-64.so.2`. Fixed: added `gcompat` (Alpine's glibc-compat shim).

**Found, then fixed 2026-09-04 (follow-up task, see STATE.md Task 6 / execution.md):** `sonar-scanner` failed to run (`Unable to load jimage library: libjimage.so`) — its bundled JVM is also glibc-linked, and `gcompat` isn't enough for a full JVM. Fixed by disabling the embedded JRE (`use_embedded_jre=false`) and installing Alpine's own musl-native `openjdk17-jre-headless` instead, scoped to sonar-scanner only. Verified by actually executing `sonar-scanner --version` in a real build. **23/23 tools now functionally verified** (was 22/23). See QUESTIONS.md #20 (now resolved).

**How bug #1 was caught in the first place**: not by inspection — by actually running `docker build` and reading the real log instead of trusting the reported exit code. The very first build attempt's background-task notification said "exit code 0" and that was **wrong** — piping through `tee` without `pipefail` masked `docker build`'s real failure behind `tee`'s own success. This exact failure mode — trusting a self-reported status instead of verifying — is precisely what this whole initiative exists to eliminate, and it nearly got me too. Every subsequent build attempt's exit code was captured via an explicit `REAL_EXIT=$?` marker written to the log file and grepped for directly, specifically because of this.

## Docker build — final verification status

**PASS, for real — now 23/23.** `docker build` exit 0 (10th attempt, marker-verified). Then went further: built a second throwaway image running every one of the 23 installed tools' actual `--version`/equivalent command as a real `RUN` step (not `docker run`, which doesn't return stdout in this sandboxed environment — worked around via `docker build`'s streaming output instead). All 23 tools confirmed actually executing successfully — terraform, opentofu, tfsec, checkov, kube-score, trivy, gitleaks, semgrep, osv-scanner, syft, grype, kube-bench, tflint, terraform-docs, polaris, pluto, kubeconform, kube-linter, helm, opa, conftest, infracost, go, **and sonar-scanner (fixed 2026-09-04, was the 1 exception at the time this session originally ran — see follow-up above)**. Test images and temp files cleaned up after verification.

## Rewired into the orchestrators
`harness-infra.md` rule 3 (external verification) now lists all 5 new skill categories, not just the original 4 tools — otherwise these gates would exist but never get called. `harness-dev.md` was **not** updated the same way this pass (QUESTIONS.md #19a) — the dev-relevant gates exist and work standalone but aren't referenced in that orchestrator's own doc yet. Also not wired: `code-gates/run-final.sh` doesn't yet call the 3 new dev-quality scripts automatically (QUESTIONS.md #19).

## What was explicitly NOT done (see QUESTIONS.md for why)
- No registry publishing, no GitHub secrets created, no branch protection enabled, no CODEOWNERS added, no thresholds invented, no rollout to product repos. All flagged, none guessed.

## Files changed (full list)
See `.specs/audit/execution.md` for the per-task breakdown with gate results. Summary: `docker/Dockerfile.sandbox`, `.github/workflows/gates.yml` (new), `claude/install.sh`, `claude/.claude/agents/harness-infra.md`, 8 new/extended skills under `claude/skills/`, `claude/templates/dev-quality/` (new), `.specs/project/SPEC.md` + `STATE.md` + `DECISIONS.md`, `QUESTIONS.md` (new), this file.

## Sync status
Synced to `~/.claude` (global) — diffed first (same discipline as previous sessions), zero local-only content found, all new/extended files copied and diff-verified identical after copy: `harness-infra.md`, `policy-gates`, `security-gates`, `cost-gates`, `perf-a11y-gates`, `infra-quality-gates`, `code-gates` (extended), `templates/dev-quality`.

## Follow-up (2026-09-08) — QUESTIONS.pt-BR.md rollout, everything below is now resolved
Every "not yet done" / "explicitly NOT done" item above from the 2026-09-03 pass was answered by the user (in Portuguese, `QUESTIONS.pt-BR.md`) and executed the same session. Full rationale: `.specs/project/DECISIONS.md` ("2026-09-08"). Gate results: `.specs/audit/execution.md` Task 7. Highlights:
- Thresholds decided (no longer tool-default placeholders): Infracost (\$0 baseline, any increase blocks), Lighthouse (90/100 all categories), Stryker (`break=50` starting point), jscpd (3%), semgrep (ERROR+WARNING block), osv-scanner unscored (fail-closed as HIGH).
- Registry: GHCR — not a new decision, `infra-platform` ADR 006 already established it platform-wide. `publish-image` CI job added (multi-arch, on merge to `main`).
- CODEOWNERS added (`* @rastaFul`). Branch protection and `INFRACOST_API_KEY` provisioning delivered as runbooks (`docs/runbooks/`), not auto-applied — both are real external/admin actions out of this session's scope.
- `kubeconform`/`kube-linter` (the last 2 tools still on `/latest/`) now pinned. `renovate.json` added for review-gated version bumps of every pinned tool.
- **ARM64 support added** — `ARG TARGETARCH` + per-tool arch mapping across 14 tools (including a required `sonar-scanner` version bump, 5.0.1.3006→8.1.0.6389, since the old pin predates arm64 releases entirely). Every arm64 URL verified live before use. Multi-arch build+push wired into CI via buildx/qemu.
- Items #15/#16 (terraform-docs `--output-check`, Polaris JSON fields) verified for real against fixtures, not left as assumptions — and that verification pass caught **2 more real bugs** (an `xargs` empty-input crash that took down the entire final infra-quality script on any repo with zero `.tf` files, and a Polaris+kube-linter stderr/stdout JSON-corruption bug that silently zeroed out their informational counts). Both fixed and re-verified.
- `harness-dev.md` gate references and `run-final.sh` wiring (#19/#19a) — done.
- Dev-quality bundle now auto-installs via `install.sh` wherever a `package.json` exists (#17), same policy as `axe-playwright`.

**23/23 gate tools remain functionally verified**, now additionally arm64-capable and re-verified post-rebuild on amd64. Docker rebuild: REAL_EXIT=0 (marker-checked).

## Follow-up (2026-09-08, later same day) — first real GitHub Actions run: 5 more bugs, GHCR live, branch protection hits a real wall
Pushed to `origin/main` for the first time ever, which meant `.github/workflows/gates.yml` executed on real GitHub Actions for the first time in this initiative's entire history. It took 5 more real, previously-invisible bugs (each found by reading actual failed-run logs, never guessed) before it went fully green:
1. `hashFiles()` in a job-level `if:` (only legal at step level — actionlint-confirmed, yamllint can't check this)
2. `.harness-sandbox/docker` missing in the template source repo itself (fixed with a symlink to `docker/`, not a copy)
3. `ENTRYPOINT ["/bin/bash"]` + every `docker run ... bash <script>` call doubled up, so bash tried to execute itself as a script and failed with "cannot execute binary file" — reproduced and confirmed the fix with plain bash, no Docker needed
4. `skills/` missing at repo root in the template source repo (same cause as #2, fixed with a second symlink to `claude/skills/`)
5. GHCR rejecting the image tag because `github.repository_owner` preserves account casing and GHCR requires lowercase

Final run (`34292146125`): **all 7 jobs green** — including `publish-image`, which genuinely pushed a multi-arch (amd64+arm64) image to GHCR, verified via the real manifest-list digest in the build log, not just a checkmark.

**Branch protection hit a real, non-technical wall**: both the classic branch-protection API and the newer rulesets API return `403 Upgrade to GitHub Pro or make this repository public` for private repos on a free personal GitHub plan — confirmed live against `agents-harness`, not assumed. This blocks branch protection on every repo in scope until the user picks one of the two real options (paid upgrade, or making a repo public) — a business decision, not something this session decided unilaterally. `docs/runbooks/branch-protection.md` updated with this finding and the real, confirmed job-context names from the actual green run.

Rollout to product repos and `INFRACOST_API_KEY` provisioning remain not started — the former needs explicit scoping (5 repos, each possibly in a different state), the latter needs the user's own account signup.

## Not yet done
- Rollout to product repos (artists-booking, microgrow, rastafinancas, vetcare) and `infra-platform` itself — still deliberately out of scope pending user scoping (QUESTIONS.md #18).
- `INFRACOST_API_KEY` — needs the user to sign up; runbook ready (`docs/runbooks/infracost-api-key.md`).
- Branch protection — blocked on a GitHub Pro / public-repo decision (see above); runbook ready and updated (`docs/runbooks/branch-protection.md`).
