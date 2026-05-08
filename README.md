# Harness Agents

Spec-driven AI orchestrators for infrastructure and development. They enforce mandatory gates, external verification, feedback loops, and persistent state tracking on every action that modifies state.

## How It Works

Two orchestrator agents (harness-infra, harness-dev) coordinate sub-agents (task-executor, infra-analyzer, code-analyzer) to execute tasks. Every modification follows:

```
SPEC → APPROVE → EXECUTE (with gates) → VERIFY (external tools) → REGISTER (audit + metrics)
```

Nothing executes without a spec. Nothing passes without external verification. Nothing is forgotten — audit trail and metrics are mandatory.

## Choose Your Format

| Format | Tool | Directory |
|--------|------|-----------|
| Claude Code | `claude --agent harness-infra` | `claude/` |
| OpenAI Codex | `codex` with AGENTS.md | `codex/` |

Both formats deliver identical behavior — spec-driven execution, TDD, gates, sub-agent delegation, autonomous mode with circuit breakers.

## Quick Start

### Claude Code

```bash
git clone <this-repo> agents-harness
cd agents-harness/claude
./install.sh ~/my-project
cd ~/my-project
claude --agent harness-dev
```

### OpenAI Codex

```bash
git clone <this-repo> agents-harness
cd agents-harness/codex
./install.sh ~/my-project
cd ~/my-project
codex
```

## Sandbox (Optional but Recommended)

The sandbox provides SonarQube for quality gates and an isolated execution environment for autonomous mode.

```bash
cd agents-harness/docker
./sandbox-run.sh ~/my-project
```

SonarQube will be available at `http://localhost:9000` (default credentials: admin/admin).

## Architecture Customization

By default, the agents enforce **Clean Architecture** (domain → application → infrastructure → interface) with a **Handler → Service → Repository** layering pattern.

To use a different architecture:
1. Edit `steering/architecture.md` in your chosen format directory
2. Edit `steering/service-layers.md` to match your layering
3. The agents will follow whatever pattern you define there

You can also remove these files entirely — the agents will then ask you about architecture decisions as they arise.

## Observability

The agents use generic placeholders for observability tools. Configure your own:
- **Logs**: Any OpenTelemetry-compatible log backend
- **Metrics**: Any Prometheus-compatible metrics backend
- **Traces**: Any OpenTelemetry-compatible tracing backend

Edit `steering/observability-logs.md` and `steering/observability-tracing.md` to match your stack.

## Cloud Provider

The agents support any cloud provider. AWS examples are included in the infra agent but are not hardcoded. When the agent needs cloud context (account, region, profile), it will ask you.

## What's Included

### Skills (reusable behaviors)
- **snip** — CLI proxy that filters shell output (npm, jest, tsc, git) before it reaches the model. Installed automatically; avg 97% token reduction.
- **harness-gates** — Mandatory checkpoints before/during/after actions
- **feedback-loop** — Autonomous execute→verify→correct cycle
- **audit-trail** — Complete action logging
- **metrics-collector** — Performance metrics per execution
- **harness-judge** — LLM-as-Judge post-execution evaluation
- **spec-manager** — Scripts to create/manage `.specs/` structure
- **audit-writer** — Scripts to write audit entries and metrics
- **code-gates** — Scripts to run TypeScript/Node.js quality gates
- **interface-design** — Persistent design system guardian via `.interface-design/system.md`
- **playwright-mcp** — E2E and visual regression gate using Playwright MCP server
- **napkin** — Tactical session memory per repository via `.claude/napkin.md`
- **firecrawl** — Web scraping and structured extraction for research inputs

### Agents
- **harness-infra** — Orchestrator for infrastructure (Terraform, K8s, AWS, Helm, Docker)
- **harness-dev** — Orchestrator for development (TypeScript/Node.js, TDD, Clean Architecture)
- **task-executor** — Sub-agent that implements individual tasks
- **infra-analyzer** — Sub-agent for read-only infrastructure analysis
- **code-analyzer** — Sub-agent for read-only code analysis

### Steering (configurable conventions)
- Architecture patterns (Clean Architecture, service layers)
- Error handling patterns
- REST API conventions
- Testing standards (TDD, Jest, coverage)
- Resilience patterns (timeout, retry, circuit breaker)
- Security audit rules
- Dependency audit rules
- OpenTelemetry observability patterns
- Frontend design conventions (stack, tokens, component scope)
- Visual automation rules (Playwright thresholds, E2E coverage targets)
- Session memory protocol (Napkin write/read boundaries)
- Research extraction rules (Firecrawl limits, domain allow/block lists)

## License

Apache 2.0 — use freely in commercial and personal projects.
