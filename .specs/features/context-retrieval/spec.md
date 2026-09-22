# Spec: Retrieval layer para reduzir consumo de contexto

Status: APROVADO
Criado em: 2026-09-22
Aprovado em: 2026-09-22

## Motivo
Usuário reporta consumo alto de contexto por agentes/skills, pede RAG pra
carregar só o necessário.

## Diagnóstico (dados reais deste repo, não estimativa)
| Fonte | Linhas | Carregamento hoje |
|---|---|---|
| `claude/.claude/agents/*.md` | 673 | 1x por sessão, por persona — já enxuto |
| `claude/skills/*/SKILL.md` | 1390 | Sob demanda (Claude Code progressive disclosure + índice em CLAUDE.md) — já lazy |
| `claude/steering/*.md` | 843 | Sob demanda (Read explícito quando a regra manda) — já lazy |
| `.specs/project/STATE.md` + `DECISIONS.md` + `audit/execution.md` | 455 | **Lido por INTEIRO toda sessão** (rule 1), sem arquivamento, cresce sem teto desde 2026-05 |

Conclusão: skills/steering/agentes já não são o gargalo (mecanismo lazy nativo
existe e funciona). O gargalo real e mensurável é o histórico de
STATE.md/DECISIONS.md/execution.md — único que não tem nenhum "carregar só o
necessário" e só cresce.

## Decisão de arquitetura: RAG por embeddings é overkill aqui
Corpus total é pequeno (~3500 linhas, dezenas de arquivos nomeados e
descritos, não milhares de documentos). A dor real (histórico) se resolve com
arquivamento + busca por keyword — não precisa de embedding model, vector DB,
nem sync a cada write. Proposta: retrieval "RAG-lite" via ripgrep, não vetores.
Semântica não é necessária: nomes de arquivo/keywords já discriminam bem.
Caminho de upgrade pra embeddings fica aberto, mas não é o ponto de partida
(evita adicionar custo de API de embedding e dependência nova pra ganho
incerto num corpus deste tamanho).

## Ganho estimado (números reais deste repo)
- STATE.md+DECISIONS.md hoje: ~14k tokens (7196+6783, medido via `wc`).
  Lidos por inteiro na abertura da sessão (rule 1) e — por ficarem no
  histórico da conversa — recacheados a CADA turno subsequente pelo resto da
  sessão. Numa sessão longa (centenas de turnos, ex. a de 3d16h já registrada
  em STATE.md) isso multiplica: ~14k × N turnos.
- Meta pós-arquivamento: ≤50 linhas cada (~3-4k tokens combinados) → corta
  ~10k tokens da baseline fixa de CADA turno, dali em diante.
- Limite honesto: isso não é a causa dominante do total de cache-read da
  conta (6.6B/30 dias) — essa causa é duração de sessão/acúmulo de histórico
  de tool output ao longo da conversa, não arquivos estáticos lidos 1x. Esse
  item é complementar ao `/compact` (item 5 abaixo), não substituto.

## Escopo
1. **Arquivamento de STATE.md/DECISIONS.md**: entradas de sessões fechadas
   (`Status: COMPLETED`/`PARTIAL`) movidas pra
   `.specs/audit/archive/YYYY-MM.md`. STATE.md/DECISIONS.md ativos passam a
   ter só a sessão atual + índice de 1 linha por entrada arquivada (data +
   resumo de 1 frase + path).
2. **Skill nova `context-search`**: `scripts/search.sh <query>` — ripgrep
   sobre `.specs/audit/archive/`, `claude/skills/`, `claude/steering/`,
   retorna trecho com contexto (`grep -n -C2`), não o arquivo inteiro.
3. **Rule 1 atualizada** (`harness-dev.md`, `harness-infra.md`): ler
   STATE.md/DECISIONS.md ativos (curtos); contexto histórico específico via
   `context-search`, não abrindo o arquivo completo.
4. **Corte inicial**: arquivar Tasks 1-10 (2026-05 a 2026-09-10) já
   existentes em STATE.md/DECISIONS.md, deixando os ativos mínimos a partir
   de agora.
5. **Protocolo de `/compact` em sessões longas** (novo, ataca a causa
   dominante do cache-read, não só STATE/DECISIONS): regra nova (9b) em
   `harness-dev.md`/`harness-infra.md` — rodar `/compact` periodicamente em
   sessões longas/autônomas, na mesma cadência dos checkpoints (a cada 3
   passos/15min), sempre DEPOIS de checkpointar STATE.md/execution.md (nunca
   antes — compact reseta a conversa, não os arquivos, que continuam sendo a
   fonte de verdade). Obrigatório em modo autônomo (rule 9); recomendado em
   sessão interativa que se estender por várias horas. Após qualquer compact
   (ou resume pós rate-limit), reler STATE.md/execution.md — mesma disciplina
   já exigida pelo `auto-retry`.

## Fora de escopo
- Embeddings/vector DB.
- Sumarização automática via LLM do conteúdo arquivado (gasta tokens pra
  economizar tokens — ganho líquido não comprovado). Arquivamento é bruto
  (move, não resume) nesta rodada.
- Mudar lazy-load de skills/steering — já adequado.

## Critério de pronto
- STATE.md/DECISIONS.md ativos ≤50 linhas cada após arquivamento inicial
- `context-search` funcional — testado com ≥5 queries reais contra decisões
  já arquivadas, retorno correto
- Rule 1 atualizada em harness-dev.md e harness-infra.md (repo + `~/.claude`)
- Regra 9b (`/compact`) presente em harness-dev.md e harness-infra.md (repo +
  `~/.claude`), amarrada à cadência de checkpoint existente (rule 2/9)
- Zero perda de informação — conteúdo só realocado, nunca deletado

## Riscos
- Decisão antiga relevante não lembrada pelo orquestrador → não buscada.
  Mitigado pelo índice de 1 linha nos arquivos ativos apontando pro arquivo
  de arquivo certo.
- `/compact` rodado antes de checkpoint → perda de progresso não registrado.
  Mitigado pela ordem explícita na regra (checkpoint sempre antes de compact).
- Compactar com frequência maior que o checkpoint gasta tokens de sumarização
  e anula o ganho — mitigado por travar a mesma cadência (3 passos/15min).

## Tarefas (TDD onde aplicável)
1. `scripts/search.sh` (skill `context-search`) — teste: query conhecida
   contra fixture retorna trecho esperado; query sem match retorna vazio sem
   erro.
2. Script de arquivamento (`scripts/archive-session.sh`) — teste: sessão
   COMPLETED é movida, índice atualizado, arquivo ativo encolhe.
3. Rodar arquivamento inicial neste repo (Tasks 1-10).
4. Atualizar rule 1 em `harness-dev.md`/`harness-infra.md` (repo): ler ativos
   curtos + usar `context-search` pra histórico específico.
5. Adicionar regra 9b (`/compact` em sessões longas) em `harness-dev.md`/
   `harness-infra.md` (repo).
6. Validar tudo neste repo; sync pra `~/.claude` só depois de validado
   (mesmo protocolo já usado nas sessões anteriores — diff antes de
   sobrescrever).
