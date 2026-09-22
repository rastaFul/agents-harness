# SPEC: output-style `caveman` nativo — port global → repo

Status: APROVADO (aprovado em duas fases: plano original "3 itens" + "crie
primeiro no claude global... depois passamos aqui pro repositório git";
fase 2 confirmada agora com "Quero colocar isso no repositório tbm")
Criado em: 2026-09-22
Aprovado em: 2026-09-22

## Motivo

Item 1 do plano original de economia de tokens (sessão anterior): versão
nativa do skill `caveman` como Claude Code **output style**
(`~/.claude/output-styles/caveman.md` + `outputStyle: "Caveman"` em
`settings.json`) — precedência mais forte que CLAUDE.md (substitui o
system-prompt do estilo Default em vez de competir como prosa anexada).
Validado no `~/.claude` global; porte pro repositório ficou pendente porque
a sessão pivotou pra Feature 2 (context-retrieval) antes de fechar essa
etapa. Sem esta task, quem clonar o repo do zero fica só com o skill antigo
(`claude/skills/caveman/`), sem o mecanismo nativo mais forte.

## Escopo

1. Criar `claude/output-styles/caveman.md` — cópia do arquivo global
   validado (conteúdo é genérico, sem caminho/máquina específica).
2. `claude/skills/caveman/SKILL.md` — não remover (zero perda de
   informação). Adicionar nota no topo marcando como superseded pelo
   output-style nativo, com ponteiro.
3. `claude/CLAUDE.md` — documentar o output-style em "Skills Ativos" (ou
   seção própria) com instrução de ativação (`outputStyle` em
   `~/.claude/settings.json`, é config de usuário, não vai commitado).
4. `README.md` — nenhuma mudança de escopo (lista de skills já está
   desatualizada em relação a `CLAUDE.md`; fora de escopo, não é este pedido).

## Fora de escopo

- Remover/depreciar de fato o skill `claude/skills/caveman/` (mantém, é
  fallback pra formato codex ou fluxo sem output-style).
- Mudar `codex/` (output styles é mecanismo exclusivo do Claude Code).
- Atualizar a lista de skills desatualizada do `README.md` (gap
  pré-existente, não relacionado a este pedido).

## Critério de pronto

- `claude/output-styles/caveman.md` existe, frontmatter válido (`name`,
  `description`, `keep-coding-instructions`), conteúdo idêntico ao global
  validado.
- `claude/CLAUDE.md` referencia o output-style e como ativá-lo.
- `claude/skills/caveman/SKILL.md` tem nota de superseded, conteúdo restante
  intacto (nada removido).
- Nenhuma referência quebrada (grep por caminho antigo/novo consistente).

## Tarefas

1. Copiar `claude/output-styles/caveman.md` do global, validar frontmatter.
2. Adicionar nota de superseded no topo de `claude/skills/caveman/SKILL.md`.
3. Documentar ativação em `claude/CLAUDE.md`.
4. Registrar em `DECISIONS.md` + `execution.md`.
