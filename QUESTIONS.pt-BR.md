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
