# 04 Plano: 001 Fundação

Entradas comuns a todas as tarefas: `CLAUDE.md`, `docs/decisions.md`, `02-spec.md`, `03-design.md`, `docs/design/DESIGN.md`. Migrações e funções: só escritas como ficheiros, nunca aplicadas nem publicadas pelos agentes.

| # | Tarefa | Dono | Ficheiros permitidos | Depende de | Feito quando |
| --- | --- | --- | --- | --- | --- |
| 1 | Esquema, RLS e auditoria: perfis, escritórios, pertença (1 por mediador), concessões (pendente/ativa/recusada/retirada), auditoria só INSERT por trigger, texto de consentimento `v0-rascunho`, vista/função security definer do mediador (nome, email, estado de pendentes/recusados), função de contagens do admin. Seguir a skill `supabase-migrations` | supabase-dev | `supabase/migrations/*.sql` (ficheiros novos), `supabase/seed/` | nada | Ficheiro(s) `.sql` idempotentes e comentados; admin sem SELECT em nomes/emails; auditoria sem UPDATE/DELETE para os perfis da app |
| 2 | Funções de servidor com service role: convidar mediador (admin), criar cliente e concessão pendente (mediador), reenviar/pedir link (mediador e cliente, resposta igual exista ou não a conta, 60 s de limite) | supabase-dev | `supabase/functions/**` | 1 | Código escrito e comentado; nenhum segredo no repositório; lista do que o Henrique tem de publicar |
| 3 | Fundação visual: fontes (Source Serif 4, Atkinson Hyperlegible Next e Mono, OFL) em `assets/fonts`, tokens, tipografia, motion, tema, widgets partilhados do `03-design.md`; dependências novas do projeto (Supabase, rotas, etc.) | flutter-dev | `pubspec.yaml`, `assets/fonts/**`, `lib/core/design/**`, `lib/core/widgets/**`, `test/core/**` | nada | `flutter analyze` limpo; tokens e widgets testados; nenhum valor solto nos widgets |
| 3b | Ajustes de responsividade na fundação visual, vindos da auditoria do designer: tokens novos (`larguraFormulario`, `textoMinimo`, `linhaTabela`, `colunaEstado`, `colunaData`, `colunaAcao`, `alturaBaixa`), `PageFrame` centrado em desktop, `ConfirmSheet` só de leitura (640) com gestão de foco, conta no topo por tamanho, `TextAction` desativado com razão escrita | flutter-dev | `lib/core/design/**`, `lib/core/widgets/**`, `test/core/**` | 3 | `flutter analyze` e `flutter test` limpos; testes nos três tamanhos |
| 4 | Esqueleto da app: inicialização do Supabase (URL e chave anon por `--dart-define`, sem segredos no repo), sessão, rotas por papel, login/recuperação de palavra-passe do mediador e admin, entrada do cliente por link mágico, link expirado e pedido de novo link | flutter-dev | `lib/main.dart`, `lib/app/**`, `lib/core/config/**`, `lib/features/auth/**`, `test/features/auth/**` | 3 (UI), 2 (contrato das funções) | Login e rotas funcionam contra o backend; estados de erro e offline do `03-design.md` |
| 4b | **Referências visuais** (renders PNG nos três tamanhos; admin desktop e um tamanho pequeno) de todos os ecrãs da 001: entrada, login, recuperar palavra-passe, link expirado, consentimento, Com quem partilho, Clientes (+ criar cliente), Admin. O Henrique aprova antes das tarefas 5, 6 e 7 | designer | `docs/features/001-fundacao/renders/**`, `03-design.md` | 3b | Renders no repo, um por ecrã e tamanho; aprovados pelo Henrique no gate 2 reaberto |
| 4c | **Alinhar o código com o design aprovado:** `PageFrame` sem linha de marca e com a conta na linha do `FolderTab`; widgets `Wordmark` e `Colophon` e token `AppType.marca`; `AuthLayout` à esquerda da moldura com a régua à largura da moldura; entrada unificada (um só formulário, link só para clientes); ecrã Criar palavra-passe (10 + 4 classes, sem confirmação, regras em tempo real, botão nunca desativado pelas regras); `AccountActions` na conta; cross-fade `base` entre páginas; skeletons, erros e offline conforme `03-design.md` | flutter-dev | `lib/core/**`, `lib/app/**`, `lib/features/auth/**`, `test/core/**`, `test/features/auth/**` | 4b aprovada (feito) | `flutter analyze` e `flutter test` limpos; testes nos três tamanhos; igual aos renders |
| 4d | Templates de email (convite e link mágico) com o colofão e a regra "Fora da app" do `DESIGN.md`; funções devem pedir link mágico só a clientes | supabase-dev | `supabase/templates/**`, `supabase/functions/**` | 4b aprovada | Ficheiros escritos; o Henrique cola os templates no painel Auth |
| 5 | Ecrãs do cliente: convite e consentimento (aceitar/recusar, texto da versão), "Com quem partilho", retirar acesso, convite pendente dentro da app | flutter-dev | `lib/features/consent/**`, `test/features/consent/**` | 4, 4b aprovada, gate 3 | Todos os estados da matriz; nunca mostra aceite/retirado sem confirmação do servidor |
| 6 | Ecrãs do mediador: lista de clientes com estados (incl. "Recusado"), criar cliente, reenviar (bloqueio de 60 s) | flutter-dev | `lib/features/mediator/**`, `test/features/mediator/**` | 4, gate 3 | Responsivo (desktop, tablet, telemóvel); lista vazia, longa e paginada |
| 7 | Ecrãs do admin: criar escritório, convidar mediador, 3 contagens | flutter-dev | `lib/features/admin/**`, `test/features/admin/**` | 4, gate 3 | Sem nenhum dado pessoal no ecrã nem nos pedidos |
| 8 | QA: scripts SQL da matriz de isolamento (todas as linhas da US 6), verificação ao vivo do esquema e RLS, testes de auditoria, `flutter analyze` e `flutter test`, veredicto em `05-qa.md` | qa | `docs/features/001-fundacao/05-qa.md`, `supabase/tests/**`, `test/**` só para testes novos | 5, 6, 7 | Veredicto PASSA/FALHA com a matriz linha a linha; 0 divergências |
| 9 | Polimento visual e goldens | designer | `test/design_review/001_fundacao/**`, `docs/design/DESIGN.md` | 5, 6, 7 | Goldens lidos e críticos tratados; sem alterações a `lib/` (pedidos vão ao flutter-dev) |

## Ordem e paralelismo

- Em paralelo já: **1** (supabase-dev) e **3** (flutter-dev).
- **2** começa quando o **1** estiver escrito.
- **GATE 3** depois do **1** e do **2**: o Henrique aplica a(s) migração(ões) no SQL Editor e publica as funções, e confirma "aplicada".
- **4** começa depois de **3**; **5, 6 e 7** depois do gate 3 e do **4**.
- **8** e **9** no fim; correções devolvidas ao dono do ficheiro (máx. 2 ciclos).

## Critério transversal: responsividade (decisão de 2026-11-26)

A app é usada no navegador, sem instalação. Cada ecrã de **cliente e mediador** tem de estar desenhado e testado em telemóvel (≤640), tablet (≤1100) e desktop; o admin é desktop-first mas utilizável nos outros. Aplica-se às tarefas 4 a 9: widget tests e goldens nos três tamanhos; o `qa` verifica-o ecrã a ecrã. A publicação web e o alojamento (UE) ficam como decisão a abrir antes do gate 4.

## Riscos do plano

- O QA precisa de executar a matriz com papéis de teste. O MCP do Supabase é só leitura e falhou nesta sessão: se não ligar, o `qa` escreve os scripts em `supabase/tests/` e o Henrique corre-os no SQL Editor e devolve o resultado.
- O email por defeito do Supabase tem limites de envio: pode afetar a métrica dos 10 minutos (decisão já tomada).
- Texto de consentimento `v0-rascunho`: não é final; sem clientes reais até haver parecer jurídico.

## Gates

- [x] Gate 1: âmbito aprovado (2026-11-26)
- [x] Gate 2: design aprovado em texto (2026-11-26)
- [x] Gate 2 reaberto: renders de cada ecrã aprovados pelo Henrique (tarefa 4b), incluindo estados, fluxos, transições, cabeçalho sem marca com Sair na linha do separador e marca por colofão (26/11)
- [x] Gate 3: migrações 001, 001b e 001c aplicadas e confirmadas ao vivo (26/11); funções publicadas
- [ ] Gate 4: release aprovada
