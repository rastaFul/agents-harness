# Spec: Preparar agents-harness para open source

Status: APROVADO
Criado em: 2026-09-21T15:08:29-03:00
Contexto cross-project: infra-platform/.specs/features/portfolio-launch-2026/spec.md

## Motivo
Framework próprio de orquestração de agentes de IA spec-driven — diferencial
de currículo pra Platform Engineering/DevOps sênior com IA aplicada.
Aprovado pelo usuário como candidato a open source e a entrar no site.

## Achados (varredura já feita)
- `LICENSE` já existe.
- `README.md` já existe e é bom (explica o funcionamento, quickstart).
- Nenhum segredo trackeado (`.env` não versionado).
- `.specs/` do próprio repo (dogfooding do harness) não expõe dado sensível
  de terceiros.

## Tarefas
1. Rodar `gitleaks detect --source . -v` no histórico completo — confirmação
   final antes de publicar.
2. Revisar `.harness-sandbox/` e `.specs/` rapidamente por qualquer caminho
   absoluto/nome de projeto real do usuário que não devesse vazar (ex.:
   nomes de repos privados citados como exemplo).
3. Após 1-2 limpos: `gh repo edit rastaFul/agents-harness --visibility
   public --accept-visibility-change-consequences`
4. Pin no perfil GitHub.

## Critério de pronto
- `gitleaks detect` limpo
- Sem referência a repos/produtos privados do usuário nos exemplos
- Repo público, pinado
