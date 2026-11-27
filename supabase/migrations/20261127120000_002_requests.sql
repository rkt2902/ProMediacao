-- =============================================================================
-- Migração 20261127120000_002_requests
-- Objetivo : feature 002 Novo pedido. Catálogo de tipos de seguro (13 tipos,
--            itens D/I, notas na voz do cliente), pedidos, itens do pedido
--            (cópia da lista), destinatários, propostas (só estrutura),
--            auditoria de pedido (só INSERT), notificações genéricas, RLS de
--            todas as linhas da matriz de isolamento e RPCs.
-- Data     : 2026-11-27
-- Estado   : NÃO APLICADA (o Henrique/lead atualiza esta linha depois de
--            aplicar pela API de gestão e verificar ao vivo).
--            Aplicar DEPOIS da 001, 001b, 001c, 001d e 001e.
-- Spec     : docs/features/002-novo-pedido/02-spec.md (US 1 a 7; US 6 = matriz)
-- Design   : docs/features/002-novo-pedido/03-design.md ("Catálogo: notas na
--            voz do cliente" = texto do seed das notas)
-- Testes   : supabase/tests/002_isolation_matrix.sql (DO único, termina em
--            erro propositado = ROLLBACK)
--
-- =============================================================================
-- CONTRATO DAS RPC (para o flutter-dev)
-- =============================================================================
-- Regras gerais
--  * Todas pedem sessão (papel `authenticated`); `anon` não tem EXECUTE.
--  * Identidade e escritório vêm SEMPRE de auth.uid() no servidor. Nenhuma RPC
--    recebe o id do utilizador nem o escritório do mediador.
--  * Erros: a app decide pelo campo `message` do PostgrestException, que é um
--    código estável em inglês (lista abaixo). `code` traz o SQLSTATE; `details`
--    traz contexto quando indicado. Nunca mostrar `message` ao utilizador.
--  * "Sem acesso" nas leituras = 0 linhas (nunca erro), para não revelar se o
--    cliente ou o pedido existe.
--  * Etapas (stage): 1 Pedido criado, 2 Documentos enviados, 3 Em análise pelo
--    mediador, 4 Enviado às seguradoras. "Em curso" = etapa 1 a 3.
--  * Natureza dos itens (kind): 'D' = Documento, 'I' = Dado a preencher.
--  * Origem (origin): 'mediador' (002) | 'cliente' (preparado, 005).
--
-- ---- Catálogo ---------------------------------------------------------------
-- get_insurance_catalog()
--   -> setof (code text, name text, note text|null, sort_order int,
--             items jsonb)  -- items = [{id uuid, position int, kind 'D'|'I', label text}]
--   Só tipos e itens ativos, por sort_order e position. Qualquer autenticado.
--   (Também legível por SELECT direto em insurance_types / insurance_type_items.)
--
-- ---- Mediador ---------------------------------------------------------------
-- create_requests(p_client_id uuid, p_requests jsonb,
--                 p_allow_policy_conditions boolean default false,
--                 p_message text default null)
--   p_requests = array de 1 a 13 objetos, um por tipo (tipos sem repetir):
--     { "type_code": "automovel",
--       "confirm_repeat": false,          -- opcional; true = "Criar outro na mesma"
--       "items": [ {"catalog_item_id": "<uuid>"},             -- item do catálogo (o servidor copia kind e label)
--                  {"kind": "D", "label": "Fotografias do veículo"} ] }  -- item livre
--     A ordem de "items" é a ordem guardada. Itens tirados = não enviados.
--   p_message: opcional; aparada (trim); vazia = null; máx. 500 caracteres.
--   Atómica: cria N pedidos (etapa 1, origem 'mediador', destino = escritório
--   do mediador) ou nenhum. Por pedido: auditoria 'created' e, se o cliente já
--   entrou alguma vez (auth.users.last_sign_in_at não nulo), 1 notificação.
--   -> setof (request_id uuid, batch_id uuid, type_code text, type_name text,
--             created_at timestamptz)
--      batch_id é igual para os N pedidos: é o que a função de email (tarefa 2)
--      recebe para enviar UM email por criação.
--   Erros (message / SQLSTATE / details):
--     not_authorized        42501  quem chama não é mediador com escritório
--     client_not_available  42501  sem concessão ATIVA entre o cliente e o
--                                  escritório (inclui: não existe, outro
--                                  escritório, pendente, recusada, retirada).
--                                  Copy: "Este cliente já não partilha dados consigo."
--     invalid_input         22023  p_requests mal formado, 0 ou >13 tipos, tipo
--                                  repetido, tipo desconhecido/inativo,
--                                  confirm_repeat não booleano. details = type_code (se houver)
--     empty_list            22023  lista de um tipo vazia. details = type_code
--     invalid_item          22023  item inválido (kind não D/I; label vazio,
--                                  >200, com '<' ou '>' ou caracteres de
--                                  controlo; catalog_item_id que não é deste tipo
--                                  ou repetido; >60 itens). details = type_code
--     message_too_long      22001  mensagem > 500 caracteres (contagem em
--                                  code points, como char_length)
--     repeated_request      P0001  há pedido em curso (etapa 1 a 3) do mesmo
--                                  tipo com ESTE escritório e não veio
--                                  confirm_repeat=true. details = type_codes
--                                  separados por vírgula. Nada foi criado.
--
-- client_open_types(p_client_id uuid)
--   Para o aviso de repetido e "Em curso desde {data}" no Novo pedido.
--   -> setof (type_code text, type_name text, open_count bigint,
--             first_created_at timestamptz, last_created_at timestamptz,
--             max_stage smallint)
--   Só pedidos em curso deste escritório; 0 linhas sem concessão ativa.
--
-- office_requests_summary(p_client_ids uuid[] default null)
--   Coluna "Pedidos" da lista Clientes. Passar os client_id da página
--   (máx. 200; null = todos os clientes ativos do escritório).
--   -> setof (client_id uuid, open_count bigint, max_open_stage smallint|null,
--             last_created_at timestamptz, total_count bigint)
--   Só clientes com concessão ATIVA e com pelo menos 1 pedido deste escritório.
--   Cliente ativo sem linha = "Sem pedidos". Pendentes/recusados: nunca aparecem.
--
-- office_open_request_count() -> bigint
--   "{n} pedidos em curso" no cabeçalho de Clientes (etapa 1 a 3, deste
--   escritório, só clientes com concessão ativa). Outros papéis: 0.
--
-- list_client_requests(p_client_id uuid, p_limit int default 25, p_offset int default 0)
--   Ficha do cliente: pedidos DESTE escritório, mais recentes primeiro.
--   -> setof (request_id uuid, type_code text, type_name text, stage smallint,
--             origin text, allow_policy_conditions boolean, created_at timestamptz,
--             author_name text|null, document_count bigint, data_count bigint,
--             total_count bigint, open_count bigint)
--   total_count/open_count = totais (todas as páginas). 0 linhas sem concessão
--   ativa (retirada oculta de imediato; volta com nova concessão ativa).
--   Cabeçalho da ficha (nome, email, estado e data da concessão): SELECT
--   direto em profiles e consent_grants (RLS da 001), como hoje.
--
-- ---- Mediador e cliente -----------------------------------------------------
-- get_request(p_request_id uuid)
--   Detalhe (ecrã 3b do mediador e ecrã 5 do cliente). 0 linhas = "Pedido não
--   encontrado" / "Sem acesso".
--   -> setof (request_id uuid, client_id uuid, client_name text,
--             office_id uuid, office_name text, type_code text, type_name text,
--             type_note text|null, origin text, stage smallint,
--             allow_policy_conditions boolean, message text|null,
--             author_name text|null, created_at timestamptz,
--             documents_sent_at timestamptz|null, review_started_at timestamptz|null,
--             sent_to_insurers_at timestamptz|null,
--             access_withdrawn boolean, access_withdrawn_at timestamptz|null,
--             items jsonb)   -- [{id, position, kind, label, source 'catalogo'|'livre'}]
--   Mediador: só com concessão ativa (logo access_withdrawn = false).
--   Cliente: sempre os seus; access_withdrawn = true quando o escritório já não
--   tem concessão ativa (carimbo "Acesso retirado", sem ações).
--
-- ---- Cliente ----------------------------------------------------------------
-- list_my_requests(p_limit int default 25, p_offset int default 0)
--   "Os meus pedidos": todos os pedidos do cliente, mais recentes primeiro.
--   -> setof (request_id uuid, type_code text, type_name text, office_id uuid,
--             office_name text, stage smallint, origin text,
--             allow_policy_conditions boolean, created_at timestamptz,
--             document_count bigint, data_count bigint,
--             access_withdrawn boolean, access_withdrawn_at timestamptz|null,
--             total_count bigint, open_count bigint)
--   open_count = "Tem {n} pedidos em curso" (etapa 1 a 3 E acesso não retirado).
--   Grupos "Em curso" / "Com o acesso retirado": pela coluna access_withdrawn.
--
-- list_my_notifications(p_limit int default 25, p_offset int default 0)
--   -> setof (notification_id uuid, kind text, title text, body text|null,
--             object_type text|null, object_id uuid|null, is_read boolean,
--             read_at timestamptz|null, created_at timestamptz,
--             total_count bigint, unread_count bigint)
--   Só as do próprio, por data decrescente. Na 002: kind 'pedido_criado',
--   title "Novo pedido: {tipo}", body = nome do escritório,
--   object_type 'request', object_id = id do pedido (abrir com get_request).
--
-- my_unread_notification_count() -> bigint   (contador do sino)
--
-- set_notification_read(p_notification_id uuid, p_read boolean default true)
--   -> setof (notification_id uuid, is_read boolean, read_at timestamptz)  (1 linha)
--   Só muda lida/não lida numa notificação do próprio. A app só dá como lida
--   depois desta resposta (sem update otimista, US 7.6).
--   Erros: not_found P0002 (não existe ou não é sua; não distingue).
--
-- ---- Admin ------------------------------------------------------------------
-- admin_counts()  (MESMO NOME, SEM PARÂMETROS, como na 001)
--   -> setof (offices bigint, mediators bigint, clients bigint, requests bigint)
--   Acrescenta a 4.ª coluna `requests` (total de pedidos). As 3 colunas da 001
--   mantêm nome e tipo: a app atual (lê por nome) continua a funcionar.
--   Outros papéis: 0 linhas. O admin não lê nenhuma tabela de pedidos.
--
-- =============================================================================
-- Notas de desenho
-- =============================================================================
--  * Validada a 27/11 num Postgres 16 local descartável (stub de auth, ACL por
--    defeito igual ao do projeto): 001 a 001e + esta aplicadas, esta duas vezes
--    sem erro; supabase/tests/002_isolation_matrix.sql 35 PASS / 0 FAIL;
--    001_isolation_matrix 66 PASS / 1 RISCO (o mesmo de antes) e 001de 15 PASS.
--    NÃO foi aplicada nem testada no projeto Supabase.
--  * Idempotente e numa só transação (BEGIN/COMMIT): se algo falhar, nada muda.
--    Seed com ON CONFLICT DO NOTHING: voltar a correr não apaga edições feitas
--    ao catálogo nos dados.
--  * Nada destrutivo nas tabelas da 001. A única função da 001 recriada é
--    admin_counts (DROP + CREATE, porque o tipo de retorno muda; não há dados).
--  * Escrita na app SÓ por RPC SECURITY DEFINER: nenhuma tabela nova dá
--    INSERT/UPDATE/DELETE ao papel authenticated. Por isso "alterar etapa,
--    lista, apagar pedido, acrescentar destinatário ou proposta, criar
--    notificação" falham com permission denied (42501) mesmo antes da RLS.
--  * O ACL por defeito do esquema public (verificado ao vivo a 27/11) dá ALL a
--    anon e authenticated em tabelas e EXECUTE em funções novas: tudo é
--    revogado explicitamente aqui.
--  * Lista do pedido = TABELA request_items (não jsonb). Porquê: na 003 o
--    cliente envia um documento/dado POR ITEM e a 004 revê item a item; uma
--    linha com id permite FK e estado por item sem reescrever a lista. A cópia
--    é feita no servidor: para itens do catálogo a app manda só o id e o
--    servidor copia kind e label (a app não consegue alterar o texto do
--    catálogo); itens livres são validados (≤200, sem '<' '>', como os nomes
--    da 001). catalog_item_id fica sem FK de propósito: o catálogo pode ser
--    editado ou desativado sem tocar em pedidos existentes.
--  * requests guarda também cópia do nome e da nota do tipo (type_name,
--    type_note): mudar o catálogo depois não muda pedidos existentes.
--  * Visibilidade do mediador = destinatário é o seu escritório E concessão
--    ATIVA do cliente com esse escritório, avaliada em cada consulta (sem
--    cache). Retirada: 0 linhas de imediato, nada apagado. Nova concessão
--    ativa (reaccept_grant): os pedidos reaparecem com a etapa que tinham.
--  * Auxiliares das políticas no esquema `private` (não exposto pela API,
--    como na 001d). Nunca acrescentar `private` aos Exposed schemas.
--  * Auditoria: trigger AFTER INSERT em request_recipients (100% das criações,
--    também por service role). UPDATE/DELETE/TRUNCATE bloqueados para todos.
--  * Pedidos, itens e destinatários não se apagam (trigger), como as concessões.
--    Apagamento RGPD: processo à parte (mesma ressalva da 001).
--  * Notificações: só criadas por private.notify (chamada por RPCs SECURITY
--    DEFINER). O cliente só muda read_at por set_notification_read; um trigger
--    impede mudar qualquer outra coluna (também ao service role).
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. Catálogo
-- -----------------------------------------------------------------------------
create table if not exists public.insurance_types (
  code        text primary key check (code ~ '^[a-z][a-z0-9_]{1,49}$'),
  name        text not null check (char_length(name) between 1 and 100 and name = btrim(name) and name !~ '[<>]'),
  note        text check (note is null or (char_length(note) between 1 and 500 and note !~ '[<>]')),
  sort_order  smallint not null unique check (sort_order > 0),
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
comment on table public.insurance_types is
  'Catálogo de tipos de seguro (002). Editável em dados (SQL/service role), sem nova versão da app. Desativar com active=false; não apagar.';

create table if not exists public.insurance_type_items (
  id          uuid primary key default gen_random_uuid(),
  type_code   text not null references public.insurance_types (code) on delete restrict,
  position    smallint not null check (position between 1 and 100),
  kind        text not null check (kind in ('D', 'I')),
  label       text not null check (char_length(label) between 1 and 200 and label = btrim(label) and label !~ '[<>]'),
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (type_code, position)
);
comment on column public.insurance_type_items.kind is 'D = documento a carregar; I = dado a preencher.';

-- -----------------------------------------------------------------------------
-- 2. Pedidos, itens, destinatários, propostas, auditoria, notificações
-- -----------------------------------------------------------------------------
create table if not exists public.requests (
  id                       uuid primary key default gen_random_uuid(),
  batch_id                 uuid not null,  -- N pedidos criados juntos (um email por criação)
  client_id                uuid not null references public.profiles (id) on delete restrict,
  insurance_type_code      text not null references public.insurance_types (code) on delete restrict,
  type_name                text not null check (char_length(type_name) between 1 and 100),  -- cópia
  type_note                text check (type_note is null or char_length(type_note) <= 500),  -- cópia
  origin                   text not null default 'mediador' check (origin in ('mediador', 'cliente')),
  stage                    smallint not null default 1 check (stage between 1 and 4),
  allow_policy_conditions  boolean not null default false,
  message                  text check (message is null or char_length(message) between 1 and 500),
  list_edited              boolean not null default false,  -- métrica: lista diferente do catálogo
  author_id                uuid references public.profiles (id) on delete set null,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),
  documents_sent_at        timestamptz,  -- etapa 2 (003)
  review_started_at        timestamptz,  -- etapa 3 (004)
  sent_to_insurers_at      timestamptz   -- etapa 4 (004)
);
create index if not exists requests_client_created_idx on public.requests (client_id, created_at desc);
create index if not exists requests_batch_idx on public.requests (batch_id);
create index if not exists requests_type_idx on public.requests (insurance_type_code);

create table if not exists public.request_items (
  id               uuid primary key default gen_random_uuid(),
  request_id       uuid not null references public.requests (id) on delete restrict,
  position         smallint not null check (position between 1 and 100),
  kind             text not null check (kind in ('D', 'I')),
  label            text not null check (char_length(label) between 1 and 200 and label = btrim(label) and label !~ '[<>]'),
  source           text not null check (source in ('catalogo', 'livre')),
  catalog_item_id  uuid,  -- sem FK de propósito (ver notas)
  created_at       timestamptz not null default now(),
  unique (request_id, position)
);

create table if not exists public.request_recipients (
  id          uuid primary key default gen_random_uuid(),
  request_id  uuid not null references public.requests (id) on delete restrict,
  office_id   uuid not null references public.offices (id) on delete restrict,
  created_at  timestamptz not null default now(),
  unique (request_id, office_id)
);
create index if not exists request_recipients_office_idx on public.request_recipients (office_id, request_id);

-- Propostas: só estrutura (006). RLS ativo, sem políticas, sem privilégios.
create table if not exists public.proposals (
  id          uuid primary key default gen_random_uuid(),
  request_id  uuid not null references public.requests (id) on delete restrict,
  office_id   uuid not null references public.offices (id) on delete restrict,
  created_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now()
);
create index if not exists proposals_request_idx on public.proposals (request_id);

-- Auditoria de pedido. Sem FKs de propósito: o registo sobrevive a apagamentos.
create table if not exists public.request_audit (
  id                   bigint generated always as identity primary key,
  request_id           uuid not null,
  client_id            uuid not null,
  office_id            uuid not null,
  insurance_type_code  text not null,
  action               text not null check (action in ('created')),
  actor_id             uuid,  -- auth.uid() de quem criou (null = service role)
  created_at           timestamptz not null default now()
);
create index if not exists request_audit_request_idx on public.request_audit (request_id);
create index if not exists request_audit_client_idx on public.request_audit (client_id);
create index if not exists request_audit_office_idx on public.request_audit (office_id);

-- Notificações genéricas (reutilizáveis por outras features)
create table if not exists public.notifications (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references public.profiles (id) on delete cascade,
  kind          text not null check (kind ~ '^[a-z][a-z0-9_]{1,49}$'),
  title         text not null check (char_length(title) between 1 and 200 and title !~ '[<>]'),
  body          text check (body is null or (char_length(body) <= 300 and body !~ '[<>]')),
  object_type   text check (object_type is null or object_type ~ '^[a-z][a-z0-9_]{1,49}$'),
  object_id     uuid,
  read_at       timestamptz,
  created_at    timestamptz not null default now()
);
create index if not exists notifications_recipient_created_idx on public.notifications (recipient_id, created_at desc);
create index if not exists notifications_recipient_unread_idx on public.notifications (recipient_id) where read_at is null;

-- -----------------------------------------------------------------------------
-- 3. Seed do catálogo (13 tipos). Fonte: docs/reference/tipos-de-seguro.md;
--    notas com o texto final de 03-design.md "Catálogo: notas na voz do cliente".
--    ON CONFLICT DO NOTHING: não sobrescreve edições feitas depois nos dados.
-- -----------------------------------------------------------------------------
insert into public.insurance_types (code, name, note, sort_order) values
  ('vida',                        'Vida',                                    'Se tiver problemas de saúde: todos os exames e relatórios recentes da patologia.', 1),
  ('vida_habitacao',              'Vida Habitação',                          'Se tiver problemas de saúde: todos os exames e relatórios recentes da patologia.', 2),
  ('doencas_graves',              'Doenças Graves',                          'Pode ser incluído no Seguro de Vida ou contratado em separado.', 3),
  ('multirriscos_habitacao',      'Multirriscos Habitação',                  null, 4),
  ('multirriscos_negocio',        'Multirriscos Negócio',                    'Capital do recheio enquadrado na atividade exercida no espaço e no seu conteúdo.', 5),
  ('saude',                       'Saúde',                                   'Para menores, o tomador é a mãe ou o pai. Com seguro de saúde há mais de 2 anos é possível transferir os períodos de carência.', 6),
  ('acidentes_pessoais',          'Acidentes Pessoais',                      'Individual ou de grupo.', 7),
  ('automovel',                   'Automóvel',                               'Se o condutor habitual não for o tomador, envie também o Cartão de Cidadão, a carta de condução e a morada do condutor.', 8),
  ('acidentes_trabalho_fixo',     'Acidentes de Trabalho (prémio fixo)',     'Se a empresa já tem seguro, envie a apólice em vigor.', 9),
  ('acidentes_trabalho_variavel', 'Acidentes de Trabalho (prémio variável)', 'Se a empresa já tem seguro, envie a apólice em vigor.', 10),
  ('pets',                        'Pets',                                    null, 11),
  ('responsabilidade_civil',      'Responsabilidade Civil',                  null, 12),
  ('obras',                       'Obras',                                   'Os documentos pedidos variam de seguradora para seguradora.', 13)
on conflict (code) do nothing;

-- Blocos reutilizados (CC, CC tomador, Morada, Imóvel) expandidos item a item.
insert into public.insurance_type_items (type_code, position, kind, label)
select v.type_code, v.position, v.kind, v.label
from (values
  -- 1 Vida: CC · Morada · Capital · Profissão · Prazo
  ('vida', 1, 'D', 'Cartão de Cidadão (NIF, nome completo, data de nascimento)'),
  ('vida', 2, 'I', 'Morada'),
  ('vida', 3, 'I', 'Capital seguro ou em dívida'),
  ('vida', 4, 'I', 'Profissão'),
  ('vida', 5, 'I', 'Prazo'),
  -- 2 Vida Habitação
  ('vida_habitacao', 1, 'D', 'Cartão de Cidadão (NIF, nome completo, data de nascimento)'),
  ('vida_habitacao', 2, 'I', 'Morada'),
  ('vida_habitacao', 3, 'I', 'Capital seguro ou em dívida'),
  ('vida_habitacao', 4, 'I', 'Taxas do empréstimo'),
  ('vida_habitacao', 5, 'I', 'Prazo'),
  ('vida_habitacao', 6, 'I', 'Profissão'),
  ('vida_habitacao', 7, 'D', 'Exames e relatórios médicos (se aplicável)'),
  -- 3 Doenças Graves
  ('doencas_graves', 1, 'D', 'Cartão de Cidadão (NIF, nome completo, data de nascimento)'),
  ('doencas_graves', 2, 'I', 'Morada'),
  ('doencas_graves', 3, 'I', 'Capital seguro'),
  ('doencas_graves', 4, 'I', 'Profissão'),
  ('doencas_graves', 5, 'I', 'Prazo'),
  -- 4 Multirriscos Habitação: CC · Imóvel
  ('multirriscos_habitacao', 1, 'D', 'Cartão de Cidadão (NIF, nome completo, data de nascimento)'),
  ('multirriscos_habitacao', 2, 'I', 'Morada do risco, se diferente da do tomador'),
  ('multirriscos_habitacao', 3, 'I', 'Área em m², n.º de WC e assoalhadas'),
  ('multirriscos_habitacao', 4, 'I', 'Capital do edifício'),
  ('multirriscos_habitacao', 5, 'I', 'Capital do recheio'),
  ('multirriscos_habitacao', 6, 'D', 'Caderneta predial do imóvel'),
  ('multirriscos_habitacao', 7, 'I', 'Ano de construção'),
  ('multirriscos_habitacao', 8, 'I', 'Ano das obras (canalização, eletricidade, etc.)'),
  -- 5 Multirriscos Negócio: CC tomador · CAE · Imóvel
  ('multirriscos_negocio', 1, 'D', 'Dados do tomador (Cartão de Cidadão)'),
  ('multirriscos_negocio', 2, 'I', 'CAE'),
  ('multirriscos_negocio', 3, 'I', 'Morada do risco, se diferente da do tomador'),
  ('multirriscos_negocio', 4, 'I', 'Área em m², n.º de WC e assoalhadas'),
  ('multirriscos_negocio', 5, 'I', 'Capital do edifício'),
  ('multirriscos_negocio', 6, 'I', 'Capital do recheio'),
  ('multirriscos_negocio', 7, 'D', 'Caderneta predial do imóvel'),
  ('multirriscos_negocio', 8, 'I', 'Ano de construção'),
  ('multirriscos_negocio', 9, 'I', 'Ano das obras (canalização, eletricidade, etc.)'),
  -- 6 Saúde
  ('saude', 1, 'D', 'Dados do tomador (Cartão de Cidadão)'),
  ('saude', 2, 'I', 'Morada'),
  ('saude', 3, 'I', 'Data de nascimento de todas as pessoas a incluir'),
  ('saude', 4, 'I', 'Coberturas e capitais pretendidos'),
  -- 7 Acidentes Pessoais
  ('acidentes_pessoais', 1, 'D', 'Dados do tomador (Cartão de Cidadão)'),
  ('acidentes_pessoais', 2, 'I', 'Morada'),
  ('acidentes_pessoais', 3, 'I', 'Coberturas pretendidas'),
  ('acidentes_pessoais', 4, 'I', 'Profissão'),
  -- 8 Automóvel
  ('automovel', 1, 'D', 'Dados do tomador (Cartão de Cidadão)'),
  ('automovel', 2, 'I', 'Morada'),
  ('automovel', 3, 'D', 'Carta de condução'),
  ('automovel', 4, 'D', 'Documento Único Automóvel (DUA / livrete)'),
  ('automovel', 5, 'I', 'Coberturas pretendidas'),
  ('automovel', 6, 'I', 'Franquias (danos próprios)'),
  -- 9 Acidentes de Trabalho (prémio fixo)
  ('acidentes_trabalho_fixo', 1, 'D', 'Dados do tomador (empresa)'),
  ('acidentes_trabalho_fixo', 2, 'I', 'Morada'),
  ('acidentes_trabalho_fixo', 3, 'I', 'CAE'),
  ('acidentes_trabalho_fixo', 4, 'I', 'Nome e data de nascimento dos trabalhadores'),
  ('acidentes_trabalho_fixo', 5, 'D', 'Recibos de vencimento (horas, salário base, subsídios)'),
  ('acidentes_trabalho_fixo', 6, 'D', 'Apólice em vigor'),
  -- 10 Acidentes de Trabalho (prémio variável)
  ('acidentes_trabalho_variavel', 1, 'D', 'Dados do tomador (empresa)'),
  ('acidentes_trabalho_variavel', 2, 'I', 'Morada'),
  ('acidentes_trabalho_variavel', 3, 'I', 'CAE'),
  ('acidentes_trabalho_variavel', 4, 'I', 'Massa salarial'),
  ('acidentes_trabalho_variavel', 5, 'D', 'Apólice em vigor'),
  -- 11 Pets
  ('pets', 1, 'D', 'Dados do tomador (Cartão de Cidadão)'),
  ('pets', 2, 'D', 'Livro do animal e micro-chip'),
  ('pets', 3, 'I', 'Tipo de atividade do animal (companhia, provas desportivas, etc.)'),
  -- 12 Responsabilidade Civil
  ('responsabilidade_civil', 1, 'D', 'Dados do tomador (CC para trabalhadores independentes)'),
  ('responsabilidade_civil', 2, 'I', 'Morada'),
  ('responsabilidade_civil', 3, 'I', 'CAE'),
  -- 13 Obras
  ('obras', 1, 'D', 'Dados do tomador (CC para particulares)'),
  ('obras', 2, 'I', 'Morada da obra'),
  ('obras', 3, 'D', 'Plantas'),
  ('obras', 4, 'D', 'Orçamentos'),
  ('obras', 5, 'D', 'Caderno de encargos'),
  ('obras', 6, 'D', 'Memória descritiva da obra'),
  ('obras', 7, 'I', 'Percentagem de obra realizada')
) as v(type_code, position, kind, label)
on conflict (type_code, position) do nothing;

-- -----------------------------------------------------------------------------
-- 4. Auxiliares em private (não expostas pela API; SECURITY DEFINER para as
--    políticas não entrarem em recursão de RLS)
-- -----------------------------------------------------------------------------

-- O mediador autenticado vê este pedido? (destino = o seu escritório E
-- concessão ATIVA do cliente com esse escritório, avaliada agora)
create or replace function private.mediator_sees_request(p_request uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select private.my_role() = 'mediador'
     and exists (
       select 1
       from public.request_recipients r
       join public.requests q on q.id = r.request_id
       where r.request_id = p_request
         and r.office_id = private.my_office_id()
         and private.has_active_grant(q.client_id, r.office_id)
     );
$$;

-- O pedido é do cliente autenticado?
create or replace function private.client_owns_request(p_request uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.requests q where q.id = p_request and q.client_id = auth.uid());
$$;

-- Criar uma notificação. Só chamada dentro de funções SECURITY DEFINER (corre
-- como dono); ninguém da app a pode executar.
create or replace function private.notify(
  p_recipient uuid, p_kind text, p_title text, p_body text, p_object_type text, p_object_id uuid)
returns uuid
language sql volatile security definer set search_path = ''
as $$
  insert into public.notifications (recipient_id, kind, title, body, object_type, object_id)
  values (p_recipient, p_kind, left(translate(p_title, '<>', ''), 200),
          nullif(left(translate(coalesce(p_body, ''), '<>', ''), 300), ''), p_object_type, p_object_id)
  returning id;
$$;

revoke execute on all functions in schema private from public, anon;
grant execute on function private.mediator_sees_request(uuid), private.client_owns_request(uuid) to authenticated;
revoke execute on function private.notify(uuid, text, text, text, text, uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 5. Triggers
-- -----------------------------------------------------------------------------

-- 5.1 Pedidos: valores impostos à entrada (nasce na etapa 1, datas do servidor)
create or replace function public.trg_requests_before_insert()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.stage := 1;
  new.created_at := now();
  new.updated_at := now();
  new.documents_sent_at := null;
  new.review_started_at := null;
  new.sent_to_insurers_at := null;
  return new;
end;
$$;
drop trigger if exists requests_before_insert on public.requests;
create trigger requests_before_insert
  before insert on public.requests
  for each row execute function public.trg_requests_before_insert();

-- 5.2 Pedidos: campos imutáveis; a etapa muda (003/004) e carimba a data.
--     author_id só pode passar a null (FK on delete set null).
create or replace function public.trg_requests_before_update()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.id <> old.id or new.batch_id <> old.batch_id or new.client_id <> old.client_id
     or new.insurance_type_code <> old.insurance_type_code or new.type_name <> old.type_name
     or new.type_note is distinct from old.type_note or new.origin <> old.origin
     or new.allow_policy_conditions <> old.allow_policy_conditions
     or new.message is distinct from old.message or new.list_edited <> old.list_edited
     or new.created_at <> old.created_at
     or (new.author_id is distinct from old.author_id and new.author_id is not null) then
    raise exception 'Campos do pedido não alteráveis' using errcode = '42501';
  end if;
  if new.stage <> old.stage then
    if new.stage >= 2 and new.documents_sent_at is null then new.documents_sent_at := now(); end if;
    if new.stage >= 3 and new.review_started_at is null then new.review_started_at := now(); end if;
    if new.stage >= 4 and new.sent_to_insurers_at is null then new.sent_to_insurers_at := now(); end if;
  end if;
  new.updated_at := now();
  return new;
end;
$$;
drop trigger if exists requests_before_update on public.requests;
create trigger requests_before_update
  before update on public.requests
  for each row execute function public.trg_requests_before_update();

-- 5.3 Pedidos, itens e destinatários não se apagam (histórico)
create or replace function public.trg_requests_no_delete()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  raise exception 'Os pedidos não se apagam' using errcode = '42501';
end;
$$;
drop trigger if exists requests_no_delete on public.requests;
create trigger requests_no_delete
  before delete on public.requests
  for each row execute function public.trg_requests_no_delete();
drop trigger if exists request_items_no_delete on public.request_items;
create trigger request_items_no_delete
  before delete on public.request_items
  for each row execute function public.trg_requests_no_delete();
drop trigger if exists request_recipients_no_delete on public.request_recipients;
create trigger request_recipients_no_delete
  before delete on public.request_recipients
  for each row execute function public.trg_requests_no_delete();

-- 5.4 Itens e destinatários: a lista copiada e o destino não mudam
create or replace function public.trg_request_children_immutable()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  raise exception 'A lista e os destinatários de um pedido não se alteram' using errcode = '42501';
end;
$$;
drop trigger if exists request_items_immutable on public.request_items;
create trigger request_items_immutable
  before update of request_id, position, kind, label, source, catalog_item_id, created_at on public.request_items
  for each row execute function public.trg_request_children_immutable();
drop trigger if exists request_recipients_immutable on public.request_recipients;
create trigger request_recipients_immutable
  before update on public.request_recipients
  for each row execute function public.trg_request_children_immutable();

-- 5.5 Auditoria automática: 1 registo 'created' por pedido e escritório de destino
create or replace function public.trg_request_recipients_audit()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.request_audit (request_id, client_id, office_id, insurance_type_code, action, actor_id)
  select q.id, q.client_id, new.office_id, q.insurance_type_code, 'created', auth.uid()
  from public.requests q where q.id = new.request_id;
  return null;
end;
$$;
drop trigger if exists request_recipients_audit on public.request_recipients;
create trigger request_recipients_audit
  after insert on public.request_recipients
  for each row execute function public.trg_request_recipients_audit();

-- 5.6 Auditoria imutável (reutiliza a função da 001: "A auditoria só aceita INSERT")
drop trigger if exists request_audit_no_update_delete on public.request_audit;
create trigger request_audit_no_update_delete
  before update or delete on public.request_audit
  for each row execute function public.trg_consent_audit_immutable();
drop trigger if exists request_audit_no_truncate on public.request_audit;
create trigger request_audit_no_truncate
  before truncate on public.request_audit
  for each statement execute function public.trg_consent_audit_immutable();

-- 5.7 Notificações: só read_at pode mudar (para todos, incluindo service role)
create or replace function public.trg_notifications_before_update()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if new.id <> old.id or new.recipient_id <> old.recipient_id or new.kind <> old.kind
     or new.title <> old.title or new.body is distinct from old.body
     or new.object_type is distinct from old.object_type
     or new.object_id is distinct from old.object_id or new.created_at <> old.created_at then
    raise exception 'Só o estado lida/não lida da notificação pode mudar' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists notifications_before_update on public.notifications;
create trigger notifications_before_update
  before update on public.notifications
  for each row execute function public.trg_notifications_before_update();

-- 5.8 Catálogo: carimbo de updated_at
create or replace function public.trg_insurance_types_stamp()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
drop trigger if exists insurance_types_stamp on public.insurance_types;
create trigger insurance_types_stamp
  before update on public.insurance_types
  for each row execute function public.trg_insurance_types_stamp();

-- -----------------------------------------------------------------------------
-- 6. RLS e privilégios (menos privilégio; o ACL por defeito dá ALL a anon)
-- -----------------------------------------------------------------------------
alter table public.insurance_types      enable row level security;
alter table public.insurance_type_items enable row level security;
alter table public.requests             enable row level security;
alter table public.request_items        enable row level security;
alter table public.request_recipients   enable row level security;
alter table public.proposals            enable row level security;
alter table public.request_audit        enable row level security;
alter table public.notifications        enable row level security;

revoke all on public.insurance_types, public.insurance_type_items, public.requests,
              public.request_items, public.request_recipients, public.proposals,
              public.request_audit, public.notifications
  from public, anon, authenticated;

-- Só leitura para a app; toda a escrita passa por RPC SECURITY DEFINER.
grant select on public.insurance_types      to authenticated;
grant select on public.insurance_type_items to authenticated;
grant select on public.requests             to authenticated;
grant select on public.request_items        to authenticated;
grant select on public.request_recipients   to authenticated;
grant select on public.request_audit        to authenticated;
grant select on public.notifications        to authenticated;
-- proposals: nada (só estrutura)

-- Sequência da identidade da auditoria: nada para a app
do $$
declare
  v_seq text := pg_get_serial_sequence('public.request_audit', 'id');
begin
  if v_seq is not null then
    execute format('revoke all on sequence %s from public, anon, authenticated', v_seq);
  end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- 7. Políticas RLS (só SELECT: não há outras operações para authenticated)
-- -----------------------------------------------------------------------------

-- Catálogo: qualquer autenticado lê (matriz: "MA ler o catálogo: permitido").
-- Escrita: sem política e sem privilégio (só migração/service role).
drop policy if exists insurance_types_select on public.insurance_types;
create policy insurance_types_select on public.insurance_types
  for select to authenticated using (true);

drop policy if exists insurance_type_items_select on public.insurance_type_items;
create policy insurance_type_items_select on public.insurance_type_items
  for select to authenticated using (true);

-- Pedidos
drop policy if exists requests_select_client on public.requests;
create policy requests_select_client on public.requests
  for select to authenticated using (client_id = auth.uid());

drop policy if exists requests_select_mediator on public.requests;
create policy requests_select_mediator on public.requests
  for select to authenticated using (private.mediator_sees_request(id));

-- Itens (iguais ao pedido)
drop policy if exists request_items_select_client on public.request_items;
create policy request_items_select_client on public.request_items
  for select to authenticated using (private.client_owns_request(request_id));

drop policy if exists request_items_select_mediator on public.request_items;
create policy request_items_select_mediator on public.request_items
  for select to authenticated using (private.mediator_sees_request(request_id));

-- Destinatários: o cliente vê os dos seus pedidos; o mediador só a linha do
-- seu escritório (e só com concessão ativa)
drop policy if exists request_recipients_select_client on public.request_recipients;
create policy request_recipients_select_client on public.request_recipients
  for select to authenticated using (private.client_owns_request(request_id));

drop policy if exists request_recipients_select_mediator on public.request_recipients;
create policy request_recipients_select_mediator on public.request_recipients
  for select to authenticated using (
    office_id = private.my_office_id() and private.mediator_sees_request(request_id)
  );

-- Auditoria: cliente a sua; mediador a do seu escritório só com concessão ativa
-- (a retirada oculta também a existência dos pedidos)
drop policy if exists request_audit_select_client on public.request_audit;
create policy request_audit_select_client on public.request_audit
  for select to authenticated using (client_id = auth.uid());

drop policy if exists request_audit_select_mediator on public.request_audit;
create policy request_audit_select_mediator on public.request_audit
  for select to authenticated using (
    private.my_role() = 'mediador'
    and office_id = private.my_office_id()
    and private.has_active_grant(client_id, office_id)
  );

-- Notificações: só o destinatário lê. Escrita só por RPC.
drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
  for select to authenticated using (recipient_id = auth.uid());

-- proposals: RLS ativo e nenhuma política (0 linhas / recusado para todos).

-- -----------------------------------------------------------------------------
-- 8. RPCs (identidade sempre por auth.uid())
-- -----------------------------------------------------------------------------

-- 8.1 Catálogo (tipos e itens ativos)
create or replace function public.get_insurance_catalog()
returns table (code text, name text, note text, sort_order integer, items jsonb)
language sql stable security definer set search_path = ''
as $$
  select t.code, t.name, t.note, t.sort_order::integer,
         coalesce((select jsonb_agg(jsonb_build_object('id', i.id, 'position', i.position,
                                                       'kind', i.kind, 'label', i.label)
                                    order by i.position)
                   from public.insurance_type_items i
                   where i.type_code = t.code and i.active), '[]'::jsonb)
  from public.insurance_types t
  where t.active and auth.uid() is not null
  order by t.sort_order;
$$;

-- 8.2 Criação atómica de N pedidos (mediador)
create or replace function public.create_requests(
  p_client_id uuid,
  p_requests jsonb,
  p_allow_policy_conditions boolean default false,
  p_message text default null
)
returns table (request_id uuid, batch_id uuid, type_code text, type_name text, created_at timestamptz)
language plpgsql volatile security definer set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid         uuid := auth.uid();
  v_office      uuid;
  v_office_name text;
  v_message     text;
  v_cond        boolean := coalesce(p_allow_policy_conditions, false);
  v_batch       uuid := gen_random_uuid();
  v_signed_in   boolean;
  v_elem        jsonb;
  v_item        jsonb;
  v_code        text;
  v_codes       text[] := '{}';
  v_repeat      text[] := '{}';
  v_type        public.insurance_types%rowtype;
  v_kinds       text[];
  v_labels      text[];
  v_sources     text[];
  v_cat_ids     uuid[];
  v_cat_id      uuid;
  v_cat_kind    text;
  v_cat_label   text;
  v_label       text;
  v_kind        text;
  v_n_custom    integer;
  v_n_active    integer;
  v_edited      boolean;
  v_req_id      uuid;
  v_now         timestamptz;
  i             integer;
begin
  -- Quem chama: mediador com escritório
  if v_uid is null or private.my_role() is distinct from 'mediador' then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  v_office := private.my_office_id();
  if v_office is null then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  -- Serializa criações para o mesmo cliente e escritório (verificação de
  -- repetido consistente; um duplo clique não cria duplicados sem aviso)
  perform pg_advisory_xact_lock(hashtextextended('requests:' || coalesce(p_client_id::text, '') || ':' || v_office::text, 0));

  -- Concessão ATIVA obrigatória. FOR SHARE: uma retirada em simultâneo espera
  -- pelo fim desta transação. Mesma resposta para todos os outros casos
  -- (não existe, outro escritório, pendente, recusada, retirada).
  perform 1 from public.consent_grants g
  where g.client_id = p_client_id and g.office_id = v_office and g.status = 'ativa'
  for share;
  if p_client_id is null or not found then
    raise exception 'client_not_available' using errcode = '42501';
  end if;

  -- Mensagem
  v_message := nullif(btrim(coalesce(p_message, '')), '');
  if v_message is not null and char_length(v_message) > 500 then
    raise exception 'message_too_long' using errcode = '22001';
  end if;

  -- Forma geral
  if p_requests is null or jsonb_typeof(p_requests) <> 'array'
     or jsonb_array_length(p_requests) < 1 or jsonb_array_length(p_requests) > 13 then
    raise exception 'invalid_input' using errcode = '22023';
  end if;

  -- Passo 1: tipos válidos, sem repetir; recolhe os repetidos por confirmar
  for v_elem in select e from jsonb_array_elements(p_requests) as e loop
    if jsonb_typeof(v_elem) <> 'object' or jsonb_typeof(v_elem -> 'type_code') is distinct from 'string' then
      raise exception 'invalid_input' using errcode = '22023';
    end if;
    v_code := v_elem ->> 'type_code';
    if v_code = any (v_codes) then
      raise exception 'invalid_input' using errcode = '22023', detail = v_code;
    end if;
    if not exists (select 1 from public.insurance_types t where t.code = v_code and t.active) then
      raise exception 'invalid_input' using errcode = '22023', detail = left(v_code, 50);
    end if;
    if v_elem ? 'confirm_repeat' and jsonb_typeof(v_elem -> 'confirm_repeat') not in ('boolean', 'null') then
      raise exception 'invalid_input' using errcode = '22023', detail = v_code;
    end if;
    v_codes := v_codes || v_code;
    if coalesce((v_elem ->> 'confirm_repeat')::boolean, false) = false
       and exists (select 1
                   from public.requests q
                   join public.request_recipients r on r.request_id = q.id and r.office_id = v_office
                   where q.client_id = p_client_id
                     and q.insurance_type_code = v_code
                     and q.stage between 1 and 3) then
      v_repeat := v_repeat || v_code;
    end if;
  end loop;

  if cardinality(v_repeat) > 0 then
    raise exception 'repeated_request' using errcode = 'P0001', detail = array_to_string(v_repeat, ',');
  end if;

  select o.name into v_office_name from public.offices o where o.id = v_office;
  select exists (select 1 from auth.users u where u.id = p_client_id and u.last_sign_in_at is not null)
    into v_signed_in;

  -- Passo 2: valida e copia a lista de cada tipo e cria tudo. Qualquer erro
  -- desfaz a transação inteira (nada fica criado).
  for v_elem in select e from jsonb_array_elements(p_requests) as e loop
    v_code := v_elem ->> 'type_code';
    select * into v_type from public.insurance_types t where t.code = v_code;

    if jsonb_typeof(v_elem -> 'items') is distinct from 'array' or jsonb_array_length(v_elem -> 'items') = 0 then
      raise exception 'empty_list' using errcode = '22023', detail = v_code;
    end if;
    if jsonb_array_length(v_elem -> 'items') > 60 then
      raise exception 'invalid_item' using errcode = '22023', detail = v_code;
    end if;

    v_kinds := '{}'; v_labels := '{}'; v_sources := '{}'; v_cat_ids := '{}'; v_n_custom := 0;
    for v_item in select x from jsonb_array_elements(v_elem -> 'items') as x loop
      if jsonb_typeof(v_item) <> 'object' then
        raise exception 'invalid_item' using errcode = '22023', detail = v_code;
      end if;
      if v_item ? 'catalog_item_id' then
        -- Item do catálogo: o servidor copia kind e label
        if jsonb_typeof(v_item -> 'catalog_item_id') <> 'string'
           or (v_item ->> 'catalog_item_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
          raise exception 'invalid_item' using errcode = '22023', detail = v_code;
        end if;
        v_cat_id := (v_item ->> 'catalog_item_id')::uuid;
        if v_cat_id = any (v_cat_ids) then
          raise exception 'invalid_item' using errcode = '22023', detail = v_code;
        end if;
        select ci.kind, ci.label into v_cat_kind, v_cat_label
        from public.insurance_type_items ci
        where ci.id = v_cat_id and ci.type_code = v_code and ci.active;
        if not found then
          raise exception 'invalid_item' using errcode = '22023', detail = v_code;
        end if;
        v_kinds := v_kinds || v_cat_kind;
        v_labels := v_labels || v_cat_label;
        v_sources := v_sources || 'catalogo'::text;
        v_cat_ids := v_cat_ids || v_cat_id;
      else
        -- Item livre
        if jsonb_typeof(v_item -> 'kind') is distinct from 'string'
           or jsonb_typeof(v_item -> 'label') is distinct from 'string' then
          raise exception 'invalid_item' using errcode = '22023', detail = v_code;
        end if;
        v_kind := v_item ->> 'kind';
        v_label := btrim(v_item ->> 'label');
        if v_kind not in ('D', 'I')
           or char_length(v_label) not between 1 and 200
           or v_label ~ '[<>]'
           or v_label ~ '[[:cntrl:]]' then
          raise exception 'invalid_item' using errcode = '22023', detail = v_code;
        end if;
        v_kinds := v_kinds || v_kind;
        v_labels := v_labels || v_label;
        v_sources := v_sources || 'livre'::text;
        v_cat_ids := v_cat_ids || null::uuid;
        v_n_custom := v_n_custom + 1;
      end if;
    end loop;

    -- Lista alterada = tem itens livres ou não tem exatamente os itens ativos do catálogo
    select count(*) into v_n_active from public.insurance_type_items ci where ci.type_code = v_code and ci.active;
    v_edited := v_n_custom > 0 or (cardinality(v_kinds) - v_n_custom) <> v_n_active;

    insert into public.requests (batch_id, client_id, insurance_type_code, type_name, type_note, origin,
                                 allow_policy_conditions, message, list_edited, author_id)
    values (v_batch, p_client_id, v_code, v_type.name, v_type.note, 'mediador',
            v_cond, v_message, v_edited, v_uid)
    returning id, created_at into v_req_id, v_now;

    for i in 1 .. cardinality(v_kinds) loop
      insert into public.request_items (request_id, position, kind, label, source, catalog_item_id)
      values (v_req_id, i, v_kinds[i], v_labels[i], v_sources[i], v_cat_ids[i]);
    end loop;

    -- Destino = escritório do mediador (o trigger escreve a auditoria)
    insert into public.request_recipients (request_id, office_id) values (v_req_id, v_office);

    -- Notificação só se o cliente já entrou alguma vez (decisão do lead)
    if v_signed_in then
      perform private.notify(p_client_id, 'pedido_criado', 'Novo pedido: ' || v_type.name,
                             v_office_name, 'request', v_req_id);
    end if;

    request_id := v_req_id;
    batch_id := v_batch;
    type_code := v_code;
    type_name := v_type.name;
    created_at := v_now;
    return next;
  end loop;
end;
$$;

-- 8.3 Tipos em curso de um cliente com este escritório (aviso de repetido)
create or replace function public.client_open_types(p_client_id uuid)
returns table (type_code text, type_name text, open_count bigint,
               first_created_at timestamptz, last_created_at timestamptz, max_stage smallint)
language sql stable security definer set search_path = ''
as $$
  select q.insurance_type_code, max(q.type_name), count(*), min(q.created_at), max(q.created_at), max(q.stage)
  from public.requests q
  join public.request_recipients r on r.request_id = q.id and r.office_id = private.my_office_id()
  where private.my_role() = 'mediador'
    and q.client_id = p_client_id
    and q.stage between 1 and 3
    and private.has_active_grant(p_client_id, r.office_id)
  group by q.insurance_type_code
  order by q.insurance_type_code;
$$;

-- 8.4 Resumo por cliente para a lista Clientes
create or replace function public.office_requests_summary(p_client_ids uuid[] default null)
returns table (client_id uuid, open_count bigint, max_open_stage smallint,
               last_created_at timestamptz, total_count bigint)
language sql stable security definer set search_path = ''
as $$
  select q.client_id,
         count(*) filter (where q.stage between 1 and 3),
         max(q.stage) filter (where q.stage between 1 and 3),
         max(q.created_at),
         count(*)
  from public.requests q
  join public.request_recipients r on r.request_id = q.id and r.office_id = private.my_office_id()
  where private.my_role() = 'mediador'
    and (p_client_ids is null or (cardinality(p_client_ids) <= 200 and q.client_id = any (p_client_ids)))
    and private.has_active_grant(q.client_id, r.office_id)
  group by q.client_id;
$$;

-- 8.5 Total de pedidos em curso do escritório (cabeçalho de Clientes)
create or replace function public.office_open_request_count()
returns bigint
language sql stable security definer set search_path = ''
as $$
  select count(*)
  from public.requests q
  join public.request_recipients r on r.request_id = q.id and r.office_id = private.my_office_id()
  where private.my_role() = 'mediador'
    and q.stage between 1 and 3
    and private.has_active_grant(q.client_id, r.office_id);
$$;

-- 8.6 Ficha do cliente: pedidos deste escritório
create or replace function public.list_client_requests(p_client_id uuid, p_limit integer default 25, p_offset integer default 0)
returns table (request_id uuid, type_code text, type_name text, stage smallint, origin text,
               allow_policy_conditions boolean, created_at timestamptz, author_name text,
               document_count bigint, data_count bigint, total_count bigint, open_count bigint)
language sql stable security definer set search_path = ''
as $$
  select q.id, q.insurance_type_code, q.type_name, q.stage, q.origin, q.allow_policy_conditions,
         q.created_at, a.full_name, ic.documents, ic.data,
         count(*) over (), count(*) filter (where q.stage between 1 and 3) over ()
  from public.requests q
  join public.request_recipients r on r.request_id = q.id and r.office_id = private.my_office_id()
  join public.insurance_types t on t.code = q.insurance_type_code
  left join public.profiles a on a.id = q.author_id
  cross join lateral (
    select count(*) filter (where i.kind = 'D') as documents, count(*) filter (where i.kind = 'I') as data
    from public.request_items i where i.request_id = q.id
  ) ic
  where private.my_role() = 'mediador'
    and q.client_id = p_client_id
    and private.has_active_grant(p_client_id, r.office_id)
  order by q.created_at desc, t.sort_order, q.id
  limit least(greatest(coalesce(p_limit, 25), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- 8.7 Detalhe de um pedido (mediador com concessão ativa, ou cliente titular)
create or replace function public.get_request(p_request_id uuid)
returns table (request_id uuid, client_id uuid, client_name text, office_id uuid, office_name text,
               type_code text, type_name text, type_note text, origin text, stage smallint,
               allow_policy_conditions boolean, message text, author_name text, created_at timestamptz,
               documents_sent_at timestamptz, review_started_at timestamptz, sent_to_insurers_at timestamptz,
               access_withdrawn boolean, access_withdrawn_at timestamptz, items jsonb)
language sql stable security definer set search_path = ''
as $$
  select q.id, q.client_id, c.full_name, r.office_id, o.name,
         q.insurance_type_code, q.type_name, q.type_note, q.origin, q.stage,
         q.allow_policy_conditions, q.message, a.full_name, q.created_at,
         q.documents_sent_at, q.review_started_at, q.sent_to_insurers_at,
         not private.has_active_grant(q.client_id, r.office_id),
         case when not private.has_active_grant(q.client_id, r.office_id) then
           (select max(g.withdrawn_at) from public.consent_grants g
            where g.client_id = q.client_id and g.office_id = r.office_id)
         end,
         coalesce((select jsonb_agg(jsonb_build_object('id', i.id, 'position', i.position, 'kind', i.kind,
                                                       'label', i.label, 'source', i.source)
                                    order by i.position)
                   from public.request_items i where i.request_id = q.id), '[]'::jsonb)
  from public.requests q
  cross join lateral (
    select rr.office_id from public.request_recipients rr
    where rr.request_id = q.id
      and (q.client_id = auth.uid() or rr.office_id = private.my_office_id())
    order by rr.created_at, rr.office_id
    limit 1
  ) r
  join public.offices o on o.id = r.office_id
  join public.profiles c on c.id = q.client_id
  left join public.profiles a on a.id = q.author_id
  where q.id = p_request_id
    and (q.client_id = auth.uid() or private.mediator_sees_request(q.id));
$$;

-- 8.8 Cliente: "Os meus pedidos" (sempre todos os seus, com flag de acesso retirado)
create or replace function public.list_my_requests(p_limit integer default 25, p_offset integer default 0)
returns table (request_id uuid, type_code text, type_name text, office_id uuid, office_name text,
               stage smallint, origin text, allow_policy_conditions boolean, created_at timestamptz,
               document_count bigint, data_count bigint, access_withdrawn boolean,
               access_withdrawn_at timestamptz, total_count bigint, open_count bigint)
language sql stable security definer set search_path = ''
as $$
  select x.id, x.insurance_type_code, x.type_name, x.office_id, x.office_name, x.stage, x.origin,
         x.allow_policy_conditions, x.created_at, x.documents, x.data, x.withdrawn,
         case when x.withdrawn then
           (select max(g.withdrawn_at) from public.consent_grants g
            where g.client_id = x.client_id and g.office_id = x.office_id)
         end,
         count(*) over (),
         count(*) filter (where x.stage between 1 and 3 and not x.withdrawn) over ()
  from (
    select q.id, q.client_id, q.insurance_type_code, q.type_name, r.office_id, o.name as office_name,
           q.stage, q.origin, q.allow_policy_conditions, q.created_at, t.sort_order,
           ic.documents, ic.data,
           not private.has_active_grant(q.client_id, r.office_id) as withdrawn
    from public.requests q
    cross join lateral (
      select rr.office_id from public.request_recipients rr
      where rr.request_id = q.id order by rr.created_at, rr.office_id limit 1
    ) r
    join public.offices o on o.id = r.office_id
    join public.insurance_types t on t.code = q.insurance_type_code
    cross join lateral (
      select count(*) filter (where i.kind = 'D') as documents, count(*) filter (where i.kind = 'I') as data
      from public.request_items i where i.request_id = q.id
    ) ic
    where q.client_id = auth.uid()
  ) x
  order by x.created_at desc, x.sort_order, x.id
  limit least(greatest(coalesce(p_limit, 25), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- 8.9 Notificações do próprio
create or replace function public.list_my_notifications(p_limit integer default 25, p_offset integer default 0)
returns table (notification_id uuid, kind text, title text, body text, object_type text, object_id uuid,
               is_read boolean, read_at timestamptz, created_at timestamptz,
               total_count bigint, unread_count bigint)
language sql stable security definer set search_path = ''
as $$
  select n.id, n.kind, n.title, n.body, n.object_type, n.object_id,
         n.read_at is not null, n.read_at, n.created_at,
         count(*) over (), count(*) filter (where n.read_at is null) over ()
  from public.notifications n
  where n.recipient_id = auth.uid()
  order by n.created_at desc, n.id
  limit least(greatest(coalesce(p_limit, 25), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

create or replace function public.my_unread_notification_count()
returns bigint
language sql stable security definer set search_path = ''
as $$
  select count(*) from public.notifications n
  where n.recipient_id = auth.uid() and n.read_at is null;
$$;

-- 8.10 Marcar como lida / não lida (só as suas)
create or replace function public.set_notification_read(p_notification_id uuid, p_read boolean default true)
returns table (notification_id uuid, is_read boolean, read_at timestamptz)
language plpgsql volatile security definer set search_path = ''
as $$
#variable_conflict use_column
declare
  v_id   uuid;
  v_read timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  update public.notifications n
     set read_at = case when coalesce(p_read, true) then coalesce(n.read_at, now()) else null end
   where n.id = p_notification_id and n.recipient_id = auth.uid()
  returning n.id, n.read_at into v_id, v_read;
  if v_id is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  notification_id := v_id;
  is_read := v_read is not null;
  read_at := v_read;
  return next;
end;
$$;

-- 8.11 Admin: 4 contagens (o tipo de retorno muda, por isso DROP + CREATE).
--      Mesmo nome e sem parâmetros; as 3 colunas da 001 mantêm-se.
drop function if exists public.admin_counts();
create function public.admin_counts()
returns table (offices bigint, mediators bigint, clients bigint, requests bigint)
language sql stable security definer set search_path = ''
as $$
  select
    (select count(*) from public.offices),
    (select count(*) from public.profiles where role = 'mediador'),
    (select count(*) from public.profiles where role = 'cliente'),
    (select count(*) from public.requests)
  where private.my_role() = 'admin';
$$;

-- -----------------------------------------------------------------------------
-- 9. Execução das funções: nada para public/anon; authenticated nas RPCs
-- -----------------------------------------------------------------------------
revoke execute on function
  public.get_insurance_catalog(),
  public.create_requests(uuid, jsonb, boolean, text),
  public.client_open_types(uuid),
  public.office_requests_summary(uuid[]),
  public.office_open_request_count(),
  public.list_client_requests(uuid, integer, integer),
  public.get_request(uuid),
  public.list_my_requests(integer, integer),
  public.list_my_notifications(integer, integer),
  public.my_unread_notification_count(),
  public.set_notification_read(uuid, boolean),
  public.admin_counts()
  from public, anon;

grant execute on function
  public.get_insurance_catalog(),
  public.create_requests(uuid, jsonb, boolean, text),
  public.client_open_types(uuid),
  public.office_requests_summary(uuid[]),
  public.office_open_request_count(),
  public.list_client_requests(uuid, integer, integer),
  public.get_request(uuid),
  public.list_my_requests(integer, integer),
  public.list_my_notifications(integer, integer),
  public.my_unread_notification_count(),
  public.set_notification_read(uuid, boolean),
  public.admin_counts()
  to authenticated;

-- Funções de trigger: ninguém as chama diretamente
revoke execute on function
  public.trg_requests_before_insert(), public.trg_requests_before_update(),
  public.trg_requests_no_delete(), public.trg_request_children_immutable(),
  public.trg_request_recipients_audit(), public.trg_notifications_before_update(),
  public.trg_insurance_types_stamp()
  from public, anon, authenticated;

commit;
