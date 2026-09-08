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
- Modifying any product repo (artists-booking, microgrow, rastafinancas, vetcare) or infra-platform directly — only the reusable templates land in agents-harness; rollout to product repos is a separate future task.
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
