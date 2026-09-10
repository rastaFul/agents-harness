# Perguntas em Aberto — Iniciativa Gate Hardening (2026-09-03)

Nada aqui foi decidido por mim ou pelos 3 agentes delegados — ou é decisão de negócio/threshold, ou precisa de uma credencial/conta que não tenho, ou precisa de verificação ao vivo que nenhum de nós conseguiu fazer a partir deste sandbox. Nada abaixo foi chutado na implementação; onde um script precisava de *algum* valor para não quebrar, o default é reportar `INFO`/`SKIPPED` em vez de aplicar um número inventado — ver cada item.

## Thresholds (decisões de negócio, não técnicas)

1. **Threshold de delta de custo do Infracost.** `harness-gates/SKILL.md` sempre disse "sinalizar para revisão se aumento de custo > threshold" mas nunca definiu o número. `skills/cost-gates` reporta o delta mensal como `INFO`, não bloqueia. Necessário: um número em $ ou %.
Isso irá mudar conforme eu hospedar nas primeiras clouds, mas enquanto está local estou mantendo um custo zero de infra. E quando tiver em cloud eu quero saber sempre que for aumentar, qualquer valor.
2. **Scores mínimos do Lighthouse CI** (performance/acessibilidade/best-practices/SEO, 0-100 cada). `skills/perf-a11y-gates` reporta os scores como `INFO`, não bloqueia. Necessário: 4 números, ou decisão de que só algumas categorias devem bloquear.
Todas as categorias devem bloquear, preciso manter um bom nível de qualidade. Quais são os valores aceitos pelo mercado?
3. **Threshold de mutation-score do Stryker.** Vem com o default do próprio scaffold do Stryker (`thresholds.break: null` — não falha o build). Necessário: um número real, idealmente após medir um baseline de mutation score num projeto real primeiro (recomendação do próprio agente dev-quality).
Eu não entendi muito bem o que é o Stryker. Me explique melhor.
4. **Threshold de duplicação do jscpd.** Vem sem threshold (default da ferramenta = apenas reporta). Necessário: um teto de % de duplicação, se algum for desejado.
Vamos fixar no que é aceito como um alto padrão de qualidade no mercado.
5. **Mapeamento de severidade → bloqueio do Semgrep.** A taxonomia do Semgrep é `ERROR`/`WARNING`/`INFO`, não o estilo CVSS critical/high/medium/low usado no resto deste repo. O script atualmente bloqueia só em `ERROR` (provisório). `WARNING` também deveria bloquear?
Sim, warning deve ser incluso
6. **Findings "unscored" do osv-scanner** (sem label de severidade normalizado — alguns ecossistemas só expõem um vetor CVSS bruto). Atualmente fail-open (não bloqueia). Deveriam ser fail-closed (tratados como HIGH)?
Sim.
7. **Barra uniforme 0-critical/0-high entre as 6 ferramentas de segurança?** Apliquei a barra existente do `npm audit` (de `steering/dependency-audit.md`) uniformemente a trivy_fs/osv-scanner/trivy_config/sbom_grype. Misconfig de IaC (trivy config) deveria ter uma barra diferente de vulnerabilidades de dependência/código?
Se for possível manter a mesma barra, simplifica o entendimento e eu prefiro.

## Credenciais / contas que não tenho
Quero o run book de todas as contas que faltam eu criar para que eu possa fazer.

8. **`INFRACOST_API_KEY`.** Referenciada em `.github/workflows/gates.yml` como `${{ secrets.INFRACOST_API_KEY }}` — o secret do GitHub Actions ainda não existe. O gate de custo dá `SKIPPED` de forma limpa sem ela, não quebra o pipeline, mas fica com cobertura zero até ser provisionada.
O que eu preciso para ter essa informação?
9. **Registry de container para a imagem sandbox (ghcr.io/rastaFul/...).** Majoritariamente RESOLVIDO — evitei deliberadamente essa necessidade fazendo o CI buildar o `Dockerfile.sandbox` do zero em vez de puxar uma imagem publicada (ver comentário de cabeçalho em `.github/workflows/gates.yml`). Ainda vale decidir depois, puramente como otimização de velocidade de CI (build leva minutos, um pull cacheado seria mais rápido), mas não é mais bloqueador para a correção local==CI.
Vamos criar um repositório para a imagem. Onde eu posso hospedar sem custos?

## Ações de governança que exigem acesso admin no GitHub (não executadas — fora de escopo conforme SPEC.md)

10. **Branch protection exigindo que os novos gate checks passem antes do merge.** Sem isso, `.github/workflows/gates.yml` roda e reporta, mas não bloqueia de fato um merge — o mesmo problema de "confiança" de antes, só que uma camada acima. Precisa de alguém com admin em `rastaFul/agents-harness` (e depois, em cada repo de produto) para habilitar isso nas configurações do repo.
Quero o runbook de como fazer isso pra todos os meus projetos
11. **CODEOWNERS para revisão humana em paths sensíveis** (estava na lista original de ferramentas sugeridas, nunca implementado — nenhum arquivo criado). Precisa de decisão sobre quais paths (infra/, código security-critical) e quem são os owners.
O code owners dos meus projetos atuais são sempre eu mesmo. 

## Follow-ups de reprodutibilidade / manutenção

12. **Polaris, pluto, kubeconform, kube-linter estão fixados em `/releases/latest/download/...`** no `Dockerfile.sandbox`, não numa versão fixa — diferente de gitleaks/osv-scanner/kube-bench/opa/conftest/infracost/terraform-docs/tflint, que verifiquei e fixei em versões exatas atuais via lookups reais no GitHub. O agente infra-quality não conseguiu verificar os nomes de arquivo por versão a partir do sandbox dele (sem acesso a rede lá); usar `/latest/` evitou chutar um nome de arquivo errado, mas significa que essas 4 ferramentas vão silenciosamente derivar para o que for mais novo a cada build de imagem. Recomendo fixar a versão assim que alguém confirmar que o padrão de nome de asset é estável entre versões.
Eu quero sim fixar na versão LTS mais recente de todas elas, mas criar mecanismo para monitorar e manter atualizações periodicamente(Sempre com revisão antes)
13. **6 novas versões de ferramentas fixadas no `Dockerfile.sandbox`** (gitleaks, osv-scanner, kube-bench, opa, conftest, infracost) mais o `SONAR_SCANNER_VERSION` pré-existente — já existe alguma regra do renovate/dependabot cobrindo esse arquivo, ou deveria ser criada uma para que não fiquem desatualizadas silenciosamente? Não verificado, sinalizado pelo agente security-gates.
Segue com a mesma resposta da anterior
14. **Suporte multi-arch (arm64).** Os comandos de instalação de `gitleaks`, `osv-scanner`, `kube-bench` estão fixados em assets `linux_x64`/`linux_amd64` sem detecção de arquitetura via `uname -m`, diferente dos install scripts existentes de `tfsec`/`kube-score`/`trivy`/`syft`/`grype`, que auto-detectam. Só importa se essa imagem algum dia precisar buildar para arm64 — não sei se isso é um requisito.
Se for possível, possibilitar o build para ARM, que é mais barato em algumas clouds, como a AWS
15. **Invocação exata de `terraform-docs --output-check`** em `run-infra-quality-final.sh` — o agente que implementou não conseguiu executar um binário real para confirmar o posicionamento da flag. Verificar contra o binário real fixado v0.24.0 assim que a imagem buildar com sucesso.
Sim, executar
16. **Nomes de campo do JSON do Polaris** (`DangerResultCount`/`WarningResultCount`) no mesmo script são um parse best-effort (o schema pode ter mudado entre versões do Polaris) — PASS/FAIL é decidido pelo próprio exit code do Polaris (`--set-exit-code-on-danger`), não por esses campos, especificamente para que um chute de schema não verificado não possa silenciosamente produzir um resultado errado. Vale confirmar os campos parseados quando a ferramenta realmente rodar.
Verifique

## Inconsistência de processo que eu mesmo introduzi (não é achado de sub-agente sobre o trabalho de outra pessoa — é sobre meu próprio trabalho nesta sessão)

17. **`install.sh` roda automaticamente `npm install -D axe-playwright`** num `package.json` de projeto-alvo quando existe um (minha própria adição na Fase 5), mas as devDependencies do bundle dev-quality (husky, lint-staged, commitlint, dependency-cruiser, eslint-plugin-sonarjs, jscpd, Stryker) são **apenas documentadas** — impressas como comando, não executadas automaticamente. O agente dev-quality sinalizou exatamente essa inconsistência no próprio relatório sem saber que eu tinha causado isso. Precisa de uma política consistente: auto-instalar em todo lugar onde existe um `package.json`, ou apenas documentar em todo lugar.
Sim, auto instalar, pois são dependencias que eu sempre quero usar como gates

## RESOLVIDO desde a passada original

20. ~~**`sonar-scanner` falha ao rodar**~~ — **CORRIGIDO em 2026-09-04** (`.specs/audit/execution.md` Task 6). Causa raiz: o JRE embutido dentro do `sonar-scanner-cli` é linkado a glibc; `gcompat` não é suficiente para uma JVM completa. Correção: desabilitado o JRE embutido (`use_embedded_jre=false` via sed no script launcher) e instalado o `openjdk17-jre-headless` nativo musl do próprio Alpine — escopo restrito ao sonar-scanner, sem shim glibc para a imagem inteira nem troca de base image. Verificado executando de fato `sonar-scanner --version` dentro de um build real (não apenas presença do arquivo). Todas as 23/23 gate tools em `Dockerfile.sandbox` agora verificadas funcionalmente (era 22/23). Isso também fecha de vez o gap #4 da auditoria original de 2026-09-02 ("SonarQube provavelmente nunca roda de fato na prática").

## Rollout (deliberadamente fora de escopo nesta passada, conforme SPEC.md)

18. **Quando/como fazer o rollout disso para os repos de produto** (artists-booking, microgrow, rastafinancas, vetcare) e para o próprio `infra-platform`. Esta passada só tocou `agents-harness` (o repo template-fonte). Rollout significa rodar `install.sh` novamente em cada projeto e lidar com o que já existir lá (mesmo cuidado tomado durante a sincronização anterior com `~/.claude` — diff antes, nunca sobrescrever às cegas).
Sempre que eu validar as nossas alterações, eu quero sincronizar com meu agente global do claude e dos meus projetos.
19a. **`harness-dev.md` NÃO foi atualizado com referências às novas skills de gate** — só `harness-infra.md` regra 3 recebeu a lista de bullets "Policy-as-code / Infra quality / Security scanning / Cost" adicionada nesta sessão. Os novos gates relevantes para dev (dependency-cruiser, jscpd/sonarjs, Stryker via `code-gates`, security-gates, perf-a11y-gates) existem e funcionam, mas a própria tabela de gates do `harness-dev.md` ainda não os menciona — o mesmo risco de "escrito mas órfão" sinalizado abaixo para `run-final.sh`, só que no nível do doc do orquestrador em vez do nível do script. Não feito nesta passada; sinalizando explicitamente em vez de deixar uma inconsistência silenciosa entre os dois docs de orquestrador.
quero atualizar o harness-dev para receber também.
19. **`run-final.sh` (code-gates) ainda não conectado para chamar os 3 novos scripts dev-quality** (`run-architecture-gate.sh`, `run-quality-extra.sh`, `run-mutation.sh`). Funcionam standalone; conectá-los na agregação final de gates existente é um próximo passo natural, não feito nesta passada (não estava na lista explícita de entregáveis dada ao agente dev-quality).
Sim, quero que vc faça

## RESOLVIDO — itens 1-19a (2026-09-08/09), bookkeeping corrigido 2026-09-10

Achado real 2026-09-10: TODOS os itens 1-19a abaixo já estavam implementados e verificados desde
Tasks 7-10 (`.specs/audit/execution.md`, 2026-09-08/09), mas este arquivo nunca foi atualizado pra
refletir isso — só o item 20 tinha uma seção "RESOLVIDO". Isso já causou confusão real numa sessão
de `harness-infra` que reportou ao usuário "thresholds de gate não definidos" como pendência,
quando na verdade já tinham sido definidos e implementados dias antes. Corrigindo o registro agora
pra isso não se repetir — cada item abaixo tem onde a implementação real vive e como foi verificada:

1. **Custo (Infracost)**: `claude/skills/cost-gates/scripts/run-cost-gate.sh` — baseline $0, qualquer
   custo mensal > 0 bloqueia. Verificado: PASS sintático (Task 7); sem `INFRACOST_API_KEY` real
   ainda configurado em nenhum repo (item 8, ver abaixo) — o gate funciona, só roda `SKIPPED` até a
   credencial existir.
2. **Lighthouse CI**: `claude/skills/perf-a11y-gates/scripts/run-lighthouse.sh` — 90/100 nas 4
   categorias. Verificado sintaticamente (Task 7); execução real depende de UI rodando localmente
   (não testado contra uma UI real ainda, nenhum rollout com Playwright ativo até agora).
3. **Stryker (mutation testing)**: `claude/templates/dev-quality/stryker.conf.json` —
   `thresholds.break: 50` (ponto de partida, não uma medição de baseline real ainda — nenhum
   projeto rodou Stryker de verdade até agora pra calibrar esse número contra dado real).
4. **jscpd (duplicação)**: `claude/templates/dev-quality/.jscpd.json` — `threshold: 3` (%,
   padrão de mercado pra "alto padrão de qualidade").
5. **Semgrep**: `run-security-final.sh` — `ERROR` e `WARNING` bloqueiam.
6. **osv-scanner unscored**: `run-security-gates.sh` — fail-closed, tratado como `HIGH`.
7. **Barra uniforme 0-critical/0-high**: `trivy config`/`trivy fs`/`osv-scanner`/`sbom_grype` todos
   `CRITICAL,HIGH`.
8. **INFRACOST_API_KEY**: runbook em `docs/runbooks/infracost-api-key.md`. Credencial em si ainda
   NÃO provisionada em nenhum repo — ação do usuário pendente (obter a key + `gh secret set` em
   cada repo), não é código faltando.
9. **Registry de container**: GHCR (`ghcr.io`), decidido e implementado — `publish-image` job em
   `.github/workflows/gates.yml`, multi-arch (amd64+arm64), nome de imagem derivado por repo (não
   hardcoded). Verificado com push real confirmado via log do `build-push-action` (Task 8) e rodando
   nos 6 repos (Task 9/10).
10. **Branch protection**: runbook em `docs/runbooks/branch-protection.md`. Tentado de verdade contra
    `agents-harness` (API clássica + rulesets) — **bloqueado por limitação real do plano GitHub**
    (403 "Upgrade to GitHub Pro or make this repository public" em repo privado, confirmado por 2
    endpoints diferentes, Task 8). Documentado com os nomes de job reais pra quando o plano permitir.
11. **CODEOWNERS**: `.github/CODEOWNERS` — `* @rastaFul`, copiado pro 5 repos de produto + este.
12/13. **Pin de versão + Renovate**: todos os `ARG *_VERSION` em `docker/Dockerfile.sandbox`
    pinados em versão exata (não mais `/latest/`); `renovate.json` na raiz com um customManager por
    ferramenta (regex sobre cada ARG, datasource `github-releases`), `automerge: false` — todo bump
    vira PR revisado, nunca automático, por pedido explícito do usuário ("sempre com revisão antes").
14. **ARM64**: `docker/Dockerfile.sandbox` usa `${TARGETARCH}` em todos os installs, com
    mapeamento especial pro asset do kube-linter (nome de arquivo diferente em arm64 vs amd64).
    Verificado com `docker build --no-cache` real (Task 7).
15. **terraform-docs --output-check**: verificado com fixture real, comportamento correto nas 2
    direções (PASS quando atual, FAIL quando desatualizado) — Task 7.
16. **Polaris JSON fields**: schema real verificado (o palpite original estava errado — não existe
    `DangerResultCount`/`WarningResultCount` no nível raiz), parser reescrito e reverificado contra
    fixture real (danger=3, warning=14) — Task 7.
17. **install.sh auto-instala TODAS as devDependencies do bundle** (husky, lint-staged@16,
    commitlint, dependency-cruiser, eslint-plugin-sonarjs, jscpd, Stryker) — não documenta mais só,
    roda `npm install -D ...` de verdade. Mesmo padrão já usado pro `axe-playwright`.
18. **Sincronização após validar**: processo seguido nas Tasks 7-10 — mudanças validadas em
    `agents-harness` sincronizadas pra `~/.claude/` (global) e pros 5 repos de produto via rollout
    (Task 9). Isso é uma prática operacional contínua, não um item que "termina" — todo `harness-infra`
    deve continuar seguindo esse fluxo daqui pra frente (validar aqui → sincronizar → rollout).
19. **`run-final.sh` conectado**: chama `run-architecture-gate.sh`/`run-quality-extra.sh`/
    `run-mutation.sh` de verdade (não só standalone).
19a. **`harness-dev.md` atualizado**: tabela de gates agora referencia dependency-cruiser,
    jscpd/sonarjs, Stryker, security-gates, perf-a11y-gates com os thresholds decididos.

Ver `.specs/audit/execution.md` Tasks 7 (implementação + verificação local), 8 (1º run real de CI
no GitHub Actions, 5 bugs achados/corrigidos), 9 (rollout pros 5 repos de produto, 11 bugs
achados/corrigidos, 4/5 verdes + 1 achado real de produção em infra-platura escalado), 10 (loop
autônomo até 6/6 repos verdes, mais 2 bugs achados/corrigidos) pro detalhe completo de cada
verificação real.

## Achado novo 2026-09-10 — cota de storage do GitHub Actions estourada (não é bug de código)

`build-sandbox` começou a falhar em TODOS os repos (`agents-harness`, `artists-booking`,
`microgrow`, `vetcare`, `infra-platform`) entre 2026-09-09 ~20h e 2026-09-10 — não por regressão de
código, confirmado via log real de cada job: `##[error]Failed to CreateArtifact: Artifact storage
quota has been hit.` Causa: `retention-days: 1` já estava configurado desde o início (correto), mas
o volume de runs das Tasks 7-10 (múltiplas iterações de `docker build`/`publish-image` em 6 repos
num único dia, cada `harness-sandbox-image` artifact ~1GB) acumulou ~39GB reais antes do ciclo de
recálculo de 6-12h do GitHub zerar a contagem — plano gratuito de conta pessoal.
Ação tomada: todos os artifacts existentes deletados manualmente via API (`DELETE
/repos/{owner}/{repo}/actions/artifacts/{id}`) nos 5 repos com Actions habilitado — ~39GB liberados
(24 artifacts em `agents-harness` sozinho, confirmado via `GET .../actions/artifacts` mostrando 0
bytes depois). **Testado de verdade com `gh run rerun` em `infra-platform` — ainda falha com o
MESMO erro de cota**, mesmo com os artifacts já deletados. Ou seja: a frase "recalculated every
6-12 hours" do próprio erro é literal — o GATE que bloqueia novos uploads usa uma foto periódica de
uso, não checa em tempo real quantos artifacts existem agora. Deletar ajuda a não piorar, mas NÃO
desbloqueia na hora. Isso é uma limitação de timing do lado do GitHub, não algo que dê pra forçar —
mesma categoria do 403 de branch protection (Task 8): não é caso de "retry 3x e escalar", é uma
janela de tempo definida pelo próprio GitHub. Vai se resolver sozinho dentro de até 6-12h da
exaustão original (~2026-09-09 noite) sem mais nenhuma ação — não fica re-tentando.
Não é uma ação recorrente automatizada ainda — se o padrão de múltiplos runs/dia em 6 repos
continuar, isso pode voltar a acontecer. Considerar: reduzir `retention-days` pra 0 (não guardar
nada, já que o artifact só serve de repasse entre jobs do MESMO run) ou usar cache do Docker layer
em vez de artifact pra evitar o problema de raiz — não decidido/implementado, registrado como
follow-up.
