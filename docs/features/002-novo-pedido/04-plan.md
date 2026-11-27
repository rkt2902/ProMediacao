# 04 Plano: 002 Novo pedido

Entradas comuns a todas as tarefas: `CLAUDE.md`, `docs/decisions.md` (gates 1 e 2 de 27/11), `02-spec.md`, `03-design.md`, `renders/` (aprovados), `docs/design/DESIGN.md`, `docs/reference/tipos-de-seguro.md`. Migrações e funções: só escritas como ficheiros, nunca aplicadas nem publicadas pelos agentes (aplica o lead, gate 3).

| # | Tarefa | Dono (modelo) | Ficheiros permitidos | Depende de | Feito quando |
| --- | --- | --- | --- | --- | --- |
| 1 | **Esquema 002**: catálogo (tipos, itens D/I com ordem, nota na voz do cliente do `03-design.md`) com seed dos 13 tipos; pedido (cliente, tipo, origem `mediador`/`cliente`, etapa 1 a 4, condições particulares, mensagem ≤500, cópia da lista, autor, datas); destinatário (pedido ↔ escritório); proposta (só estrutura, sem permissões); auditoria de pedido (só INSERT); notificações genéricas (tipo, destinatário, texto, lida, data, objeto). RPC atómica de criação de N pedidos (concessão ativa obrigatória, lista editada validada, auditoria, notificação só se o cliente já entrou alguma vez, ex.: `auth.users.last_sign_in_at` não nulo); verificação de pedido repetido do mesmo tipo; leituras: resumo de pedidos por cliente para a lista Clientes, pedidos do cliente na ficha (só deste escritório), "Os meus pedidos" do cliente (com flag "Acesso retirado"), detalhe; notificações (listar, contar não lidas, marcar lida); contagem de pedidos no painel do admin. RLS de todas as linhas da matriz de isolamento da spec; admin sem acesso a dados de pedidos. Seguir a skill `supabase-migrations` | supabase-dev (opus) | `supabase/migrations/*002*.sql` (novos), `supabase/tests/002*` | nada | `.sql` idempotente e comentado; nenhuma alteração destrutiva às tabelas da 001; contrato das RPC (nomes, parâmetros, retornos, erros) escrito no topo do ficheiro para o flutter-dev |
| 2 | **Email do pedido**: função de servidor que envia ao cliente titular o email curto (escritório, tipos, mensagem, link para `/pedidos`), um por criação; reenvio pelo mediador com limite de 60 s (reutilizar `send_throttle` e o mecanismo de link da 001); falha de envio não desfaz os pedidos e é devolvida à app (US 4.4). Template em `supabase/templates/` conforme o render do email (aplicado quando houver SMTP próprio; até lá diz o que sai de facto) | supabase-dev (opus) | `supabase/functions/**` (função nova + `_shared` se preciso), `supabase/templates/request-*` | 1 | Código comentado, sem segredos; lista do que o lead publica; risco do email por defeito descrito |
| 3a | **Fundação visual da 002**: tokens novos marcados "(proposto, 002)" no `DESIGN.md` e componentes novos (StageTrack, StageStrip, CheckRow, TagLabel, NotificationBell, `StampStatus.acessoRetirado`) | flutter-dev (sonnet) | `lib/core/design/**`, `lib/core/widgets/**`, `test/core/**` | gate 2 | `flutter analyze` limpo; widgets testados nos três tamanhos; nenhum valor solto |
| 3 | **Base Flutter da 002**: camada de dados e domínio dos pedidos, catálogo e notificações contra o contrato da tarefa 1; rotas novas (Novo pedido, ficha do cliente, pedido, "Os meus pedidos" como inicial do cliente, detalhe, notificações) e links do email | flutter-dev (opus) | `lib/app/**`, `lib/features/requests/**` (novo: `domain`, `data`, `application`), `lib/features/notifications/{domain,data,application}/**`, `test/app/**`, `test/features/requests/**`, `test/features/notifications/**` | 1 (contrato escrito), 3a | `flutter analyze` limpo; repositórios testados com fakes; rotas por papel testadas (cliente entra em "Os meus pedidos") |
| 4 | **Ecrãs do mediador**: Novo pedido (cliente só com concessão ativa, N tipos, lista editável, nota, condições particulares, mensagem com contador, aviso de repetido, sucesso, email falhou + reenviar), Clientes com estado dos pedidos ("Novo pedido" principal), ficha do cliente com os pedidos, pedido em só leitura; 4.ª contagem no admin | flutter-dev (sonnet) | `lib/features/mediator/**`, `lib/features/admin/**`, `test/features/mediator/**`, `test/features/admin/**` | 3 | Igual aos renders nos três tamanhos; estados vazio, a carregar, erro, offline e sucesso; widget tests |
| 5 | **Ecrãs do cliente**: "Os meus pedidos" (4 etapas, aviso sem data, "Acesso retirado"), detalhe só leitura, sino e lista de notificações (painel em desktop, ecrã no telemóvel), ligação para "Com quem partilho" | flutter-dev (sonnet) | `lib/features/client_requests/**` (novo), `lib/features/notifications/presentation/**`, `test/features/client_requests/**`, `test/features/notifications/presentation/**` | 3 | Igual aos renders nos três tamanhos; "lida" só depois da confirmação do servidor; widget tests |
| 6 | **QA**: matriz de isolamento linha a linha ao vivo (scripts em transação com ROLLBACK), criação atómica, repetido, retirada, notificações, contagem do admin, email (o que for verificável), `flutter analyze` e `flutter test`, responsividade; veredicto em `05-qa.md` | qa (opus) | `docs/features/002-novo-pedido/05-qa.md`, `supabase/tests/**` (novos), `test/**` só para testes novos | gate 3, 4, 5 | Veredicto PASSA/FALHA com a matriz; 0 divergências de isolamento |
| 7 | **Polimento e goldens** dos ecrãs da 002 | designer (opus) | `test/design_review/002_novo_pedido/**`, `docs/design/DESIGN.md` | 6 | Goldens lidos; pedidos de correção vão ao dono do ficheiro |

## Ordem e paralelismo

- **1** e **3a** em paralelo. **2** e **3** começam quando o **1** estiver escrito (em paralelo).
- **GATE 3** depois do **1** e do **2**: o lead mostra o resumo ao Henrique, aplica pela API de gestão, verifica ao vivo, publica a função e regista em `docs/decisions.md`.
- **4** e **5** em paralelo depois do **3** (ficheiros disjuntos).
- **6** depois do gate 3 e de **4** e **5**; **7** no fim. Correções voltam ao dono do ficheiro (máx. 2 ciclos).

## Decisões do lead (fora dos gates)

- "Já entrou alguma vez" = `auth.users.last_sign_in_at` não nulo, lido no servidor (a app não decide).
- A lista do pedido é uma cópia (jsonb ou tabela de itens, à escolha do supabase-dev, justificada); itens livres têm texto ≤200 sem `<`/`>`, como os nomes da 001.
- Depois de responder ao consentimento, o cliente vai para "Com quem partilho" (`/cliente/partilhas`), e esse ecrã ganha regresso a "Os meus pedidos" e o sino; `lib/features/consent/**` passa a ser da tarefa 5. A troca dos marcadores em `lib/app/route_builders.dart` pelos ecrãs reais é do lead, depois das tarefas 4 e 5.
- Só a 3a toca em `lib/core/**` e só a 3 em `lib/app/**`; se 4 ou 5 precisarem de um widget novo, pedem-no ao lead.

## Riscos do plano

- O email por defeito do Supabase (sem SMTP próprio) só envia emails de autenticação, com template fixo e 2 por hora: o email do pedido pode sair como link mágico genérico até haver SMTP (Brevo). A tarefa 2 diz exatamente o que sai.
- Sem a app publicada (Cloudflare adiado), o link do email aponta para `localhost`: o teste ponta a ponta com email real fica para depois do passo 2 do `STATUS.md`.
- Texto de consentimento `v0-rascunho` e sem clientes reais até haver parecer jurídico.

## Gates

- [x] Gate 1: âmbito aprovado (2026-11-27)
- [x] Gate 2: renders aprovados (2026-11-27)
- [x] Gate 3: migração 002 aplicada e verificada ao vivo (27/11: 35 PASS / 0 FAIL)
- [x] Função do email publicada (27/11; ACTIVE, JWT obrigatório, sem sessão dá 401; sem fornecedor responde 503 `email_unavailable`)
- [ ] Gate 4: release aprovada
