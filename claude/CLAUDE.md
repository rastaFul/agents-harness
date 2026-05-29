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
- `frontend-design.md` — UI stack, design tokens, component scope
- `visual-automation.md` — Playwright MCP thresholds and E2E scope
- `session-memory.md` — Napkin protocol and entry boundaries
- `research-extraction.md` — Firecrawl limits, allowed/blocked domains
- Others: error-handling, api-rest, resilience, security, observability

## Gate E2E — Playwright MCP (OBRIGATÓRIO)

**Ativado automaticamente** quando o projeto envolve:
- Interface (componente, página, formulário, modal, dashboard, layout)
- Integração com sistemas externos testável via browser
- Fluxo de usuário com múltiplos passos
- Qualquer aceitação visual descrita na spec

**O que o gate faz:**
Sobe um browser real (Chromium headless) via Playwright MCP e navega pelas funcionalidades como um usuário real: clica, preenche formulários, verifica textos, faz assertions visuais.

**Protocolo obrigatório:**
```
1. Verificar server rodando: curl -sf http://localhost:PORT || erro
2. Escrever teste E2E ANTES da implementação (TDD Red — deve falhar)
3. Confirmar falha do teste
4. Implementar feature
5. Rodar gate Playwright: deve PASSAR antes de marcar task DONE
6. Salvar screenshots em .specs/features/[feature]/screenshots/
7. Registrar em execution.md: playwright: PASS|FAIL (X tests, Y passed)
```

**Fluxo do browser (o que executar):**
- Navegar para a URL da feature (`playwright_navigate`)
- Interagir como usuário real: clicar, digitar, submeter (`playwright_click`, `playwright_fill`)
- Assertions: verificar textos, elementos visíveis, estados (`playwright_get_visible_text`, `playwright_get_visible_html`)
- Capturar screenshot como evidência (`playwright_screenshot`)
- Testar happy path + pelo menos 1 error path por fluxo crítico

**NÃO usar Playwright para:**
- Testes unitários de lógica → Jest
- Testes de API pura → Supertest / curl
- Tarefas de backend sem UI
- Fase TDD Red (falha esperada não é gate failure)

**Referência:** `steering/visual-automation.md`

## Frontend Skills

When working on UI tasks, these additional skills activate automatically:

- **interface-design** — Reads/writes `.interface-design/system.md` to maintain design token consistency across sessions. Read before any component generation.
- **playwright-mcp** — E2E and visual regression gate via Playwright MCP server. Mandatory gate for all tasks with visual output. Protocol above applies.
- **napkin** — Tactical session memory in `.claude/napkin.md`. Read at session start; write on corrections and pattern discoveries.
- **firecrawl** — Web scraping for external design references and research. Use when WebSearch/WebFetch is insufficient.

## Skills Ativos

- `snip` — CLI proxy ativo via PreToolUse hook. Filtra saída de npm/npx/git/jest/tsc antes de chegar ao modelo. Ver `skills/snip/SKILL.md`. Checar ganhos: `snip gain`.
- `caveman` — Estilo de comunicação token-eficiente (`skills/caveman/SKILL.md`)
- `playwright-mcp` — Gate E2E via browser real (`skills/playwright-mcp/SKILL.md`)

## Token Efficiency (Caveman Mode)

Maximize Claude Pro session duration. Always apply:

**Output:**
- Respostas curtas, diretas, técnicas
- Sem saudações, rodeios, resumos duplicados, encerramentos decorativos
- Código mínimo funcional; sem boilerplate desnecessário
- Não explique o óbvio; não repita a pergunta

**Input:**
- Usar só contexto necessário; ignorar histórico irrelevante
- Compactar contexto longo; trabalhar só com trecho útil

**Model routing:**
- Modelo leve: resumos, formatação, extração, perguntas diretas
- Modelo forte: depuração difícil, arquitetura, decisões complexas
- Nunca escalar por padrão

**Execução:**
- Agrupar tarefas relacionadas em uma resposta
- Não quebrar tarefa simples em múltiplas mensagens
- Encerrar objetivamente quando resolvido

**Regra final:** conflito verbosidade × economia → priorize economia.

## Tool Output Compression

Minimizar tokens consumidos por saídas de ferramentas (npm test, tsc, eslint, build, lint, etc).

**SUCESSO:** `[comando] | OK | resumo curto`
**FALHA:** `[comando] | FAIL | N erros | arquivo:linha mensagem`

Regras:
- Nunca enviar saída completa ao modelo salvo necessidade estrita
- Passar: nome + OK + contagem + duração
- Falhar: nome + FAIL + N erros + arquivos + linhas relevantes + bloco mínimo de erro
- Logs longos: usar tail/head/grep/sed/awk — descartar progresso, barras, downloads, stack traces redundantes
- Testes OK: só resumo final. Testes FAIL: só suites falhas + trecho mínimo
- TypeScript: arquivo:linha:col código mensagem — agrupar erros repetidos
- Lint: agrupar por arquivo, remover repetições, manter regra+linha+mensagem
- Não reenviar logs já vistos — preservar só resumo estruturado do último resultado
- Output bruto só quando resumo não basta para tomar decisão
