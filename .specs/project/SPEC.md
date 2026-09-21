# SPEC — Gate Hardening (Security + Dev + Infra quality), Local == CI

## Goal
Close the gate gaps identified in the 2026-09-02/03 audit: policies as prose not code, self-reported gates with no real CI, missing secret/SAST/SCA scanning, no architecture conformance, no infra-quality gates beyond security, no mutation testing, no cost/perf/a11y gates. Implement the tool list approved by the user, organized in 5 phases, with one hard architectural constraint: **the local gate (run during agent execution) and the CI gate (run on push/PR) must execute the exact same script, inside the exact same container image — never two separate implementations that can drift.**

## Scope (closed)
IN scope:
- `agents-harness` repo only: Dockerfile.sandbox, new/updated skills (scripts + configs), `.github/workflows/gates.yml` template, OPA/Conftest policy files translating `policies.md`, `install.sh` propagation, steering/agent doc updates.
- Written artifacts + local syntax/lint verification (bash -n, yamllint, docker build attempt if time allows).

OUT of scope (explicitly NOT done without separate approval):
- Publishing any image to a real container registry (ghcr.io/rastaFul/...) — needs registry/auth decision, registered as open question.
- Creating GitHub repo secrets, enabling branch protection, or any GitHub API/admin action on `rastaFul/agents-harness` or any product repo.
- Modifying any product repo (rastafinancas e outros repositórios privados do usuário) or infra-platform directly — only the reusable templates land in agents-harness; rollout to product repos is a separate future task.
- Deciding numeric thresholds not already established (coverage %, cost delta %, Lighthouse score minimum) — use tool defaults, flag as question, do not invent a business threshold.

## Phases (from approved priority list)
1. Sandbox image versioning skeleton + OPA/Conftest + CI workflow skeleton (local==CI mechanism)
2. Security: gitleaks, Semgrep, trivy fs/config, osv-scanner, Syft+Grype, kube-bench
3. Dev quality: dependency-cruiser, eslint-plugin-sonarjs, jscpd, Stryker, husky+lint-staged+commitlint
4. Infra quality: tflint, terraform-docs, Polaris, pluto, kubeconform, terratest, helm-unittest, fix kube-linter install gap
5. Infracost, Lighthouse CI, axe-core/playwright

## Done criteria
Per phase: artifacts written, referenced in relevant skill/steering docs, syntax-verified externally (not self-declared), registered in `.specs/audit/execution.md`, any undecidable item logged in `QUESTIONS.md` instead of guessed.
Overall: all 5 phases DONE or explicitly BLOCKED with reason in QUESTIONS.md. Final `RESULT.md` and `QUESTIONS.md` produced at repo root.

## Autonomous execution parameters
- Timeout: this working session (single continuous pass). If not finished, checkpoint STATE.md as PARTIAL with exact resume point.
- Checkpoints: every 3 steps or 15 minutes (per rule 9/2), appended to STATE.md.
- Circuit breaker (reuse feedback-loop defaults, infra profile): 3 consecutive step failures on the same item → stop that item, log as BLOCKED, continue with independent items. Do not let one blocked tool stall unrelated tools.
- Delegation: task-executor for implementation bundles that are independent and parallelizable; orchestrator (this session) does the shared/central files (Dockerfile.sandbox, install.sh, CI workflow, OPA policy translation) to avoid merge conflicts between parallel writers.
- No decision-under-uncertainty: registry names, CI secrets, thresholds not already agreed, branch-protection config, and anything touching product repos → QUESTIONS.md, never assumed.
- Human approval gate: per rule 9, result does not get committed/pushed without explicit human approval after reviewing RESULT.md.

## Task 10 — Autonomous gate-clearing loop (2026-09-09T07:46:03-03:00)
User: "aplique [reusable-ci.yml fix] e entre em modo autonomo e em loop, até zerar as vulnerabilidades ou gates barrados que encontrar."

**Caveat, same as every prior "autonomous" request this initiative**: cannot self-relaunch as a separate `claude --agent harness-infra --remote-control` process from inside a running interactive session. Applying rule 9's spirit within this session instead (closed scope, checkpoints, circuit breaker) rather than claiming full compliance.

**Closed scope (infra/security gate findings only, across the 6 repos this initiative already touches: agents-harness, rastafinancas, infra-platform e outros repositórios privados do usuário):**
- IN: real findings surfaced by each repo's `Harness Gates` CI (`gates.yml`) infra/security jobs — tfsec, checkov, OPA policy-gate, trivy, and any NEW harness-template bug the loop itself surfaces (same discipline as the rollout: fix centrally, propagate).
- OUT: pre-existing application-level CI failures unrelated to security/infra (broken `npm install` in one of the user's private repos, actual product lint/test/coverage debt) — that's `harness-dev`/product-backlog territory, not this orchestrator's scope, and fixing it blind risks breaking real app behavior.
- OUT: anything requiring credentials this session doesn't have (OCI apply, `INFRACOST_API_KEY`, GitHub Pro/branch protection) — already-escalated items stay escalated, not re-attempted here.
- OUT: production `terraform apply` — code-level Terraform fixes stay in scope (validated via `terraform validate`/`tfsec`/`checkov`), applying to live state does not (no credentials, same as the OCI fix already done).

**Done criteria:** every repo's `Harness Gates` run is green, OR every remaining red job is classified as one of: FIXED (re-verified via a real subsequent run), BLOCKED (circuit breaker exhausted — 3 attempts on the same distinct finding — logged with reason), or OUT-OF-SCOPE (app-level, logged and left for `harness-dev`/product owner).

**Circuit breaker:** 3 fix attempts per distinct finding before marking BLOCKED and moving to the next repo/finding — never loop indefinitely on one item.

**Checkpoints:** STATE.md updated every 3 repos checked or 15 minutes, whichever first.
