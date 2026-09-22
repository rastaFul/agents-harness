# SPEC: README.md skills list sync

Status: APROVADO ("Quero que corrija sim")
Criado/Aprovado: 2026-09-22

## Motivo
README "### Skills" list missing 8 skills present in `claude/skills/`: auto-retry, caveman, context-search, cost-gates, infra-quality-gates, perf-a11y-gates, policy-gates, security-gates.

## Escopo
Add one bullet per missing skill to README.md `### Skills (reusable behaviors)`, one-line description each, consistent style with existing bullets. No other README changes.

## Critério de pronto
`ls claude/skills` and README bullets match 1:1.
