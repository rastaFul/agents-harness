# Project Instructions

This project uses spec-driven AI agents (Harness) for infrastructure and development tasks.

## Core Principle

**Spec-driven. Everything starts with a spec.** No spec, no execution. No gate, no progress. No external verification, no trust.

## Agents Available

- `harness-infra` — Infrastructure orchestrator (Terraform, K8s, AWS, Helm, Docker)
- `harness-dev` — Development orchestrator (TypeScript/Node.js, TDD, Clean Architecture)

Launch with: `claude --agent harness-infra` or `claude --agent harness-dev`

## Sub-Agents (delegated automatically)

- `task-executor` — Implements individual tasks with TDD and gates
- `infra-analyzer` — Read-only infrastructure analysis
- `code-analyzer` — Read-only code analysis

## Key Behaviors

1. Every session starts by reading `.specs/project/STATE.md`
2. Every modification requires a spec (unless quick mode is explicitly requested)
3. Every action is verified by external tools (never self-validated)
4. Every result is logged to `.specs/audit/` and `.specs/metrics/`
5. Sub-agents handle implementation; orchestrators plan and coordinate

## Quick Mode

Say "quick mode", "no spec", or "just do it" to skip spec creation. Gates and audit still apply. A retrospec is generated after completion.

## Read-Only (No Spec Needed)

Queries, analysis, and read operations never need a spec or gates:
- "What does this module do?"
- "List the pods"
- "Show me the logs"

## Observability

- **Logs**: OpenTelemetry-compatible backend (configure in steering/observability-logs.md)
- **Metrics**: Prometheus-compatible backend (configure in steering/observability-tracing.md)
- Never mix: logs tool for app logs, metrics tool for infra metrics

## Steering Files

Configurable conventions in `steering/`. Edit to match your project:
- `architecture.md` — Architecture pattern (default: Clean Architecture)
- `service-layers.md` — Layering (default: Handler → Service → Repository)
- `testing.md` — Test standards (default: TDD with Jest)
- Others: error-handling, api-rest, resilience, security, observability
