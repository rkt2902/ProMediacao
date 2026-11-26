-- =============================================================================
-- Migração 20261126120000_001_fundacao
-- Objetivo : feature 001 Fundação. Perfis, escritórios, pertença mediador-
--            escritório, concessões de consentimento, auditoria só INSERT,
--            texto de consentimento versionado, dados escritos pelo mediador,
--            RLS e funções (lista do mediador, "as minhas concessões",
--            contagens do admin, voltar a aceitar).
-- Data     : 2026-11-26
-- Estado   : NÃO APLICADA (o Henrique atualiza esta linha depois de aplicar
--            no SQL Editor e confirmar).
-- Spec     : docs/features/001-fundacao/02-spec.md (US 6 = matriz de isolamento)
--
-- Notas de desenho
--  * Idempotente: pode ser corrida mais de uma vez sem erro.
--  * Nada é público: RLS ativo em todas as tabelas, privilégios de anon
--    revogados, políticas só para o papel `authenticated`.
--  * Identidade sempre por auth.uid(); nenhum parâmetro traz o id do utilizador.
--  * Funções SECURITY DEFINER com search_path vazio e nomes qualificados.
--  * Criação de perfis: só com service role (funções de servidor da tarefa 2)
--    ou à mão para o primeiro admin (supabase/seed/001_first_admin.sql). Não há
--    trigger em auth.users de propósito: confiar em raw_user_meta_data deixaria
--    qualquer pessoa autoatribuir o papel admin.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tipos
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'app_role') then
    create type public.app_role as enum ('admin', 'mediador', 'cliente');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'grant_status') then
    create type public.grant_status as enum ('pendente', 'ativa', 'recusada', 'retirada');
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- 2. Tabelas
-- -----------------------------------------------------------------------------

-- Perfis (um por utilizador de auth.users)
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  role        public.app_role not null,
  full_name   text not null check (char_length(full_name) between 1 and 200),
  email       text not null check (char_length(email) between 3 and 320),
  created_at  timestamptz not null default now()
);
create unique index if not exists profiles_email_lower_uidx on public.profiles (lower(email));
create index if not exists profiles_role_idx on public.profiles (role);

-- Escritórios
create table if not exists public.offices (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 200),
  created_at  timestamptz not null default now()
);

-- Pertença mediador-escritório: um mediador pertence a um único escritório
create table if not exists public.office_members (
  user_id     uuid primary key references public.profiles (id) on delete cascade, -- PK = restrição única por mediador
  office_id   uuid not null references public.offices (id) on delete restrict,
  created_at  timestamptz not null default now()
);
create index if not exists office_members_office_idx on public.office_members (office_id);

-- Texto de consentimento versionado
create table if not exists public.consent_texts (
  version           text primary key check (char_length(version) between 1 and 50),
  content           text not null,
  is_draft          boolean not null default true,   -- true = placeholder ainda não validado
  needs_legal_review boolean not null default true,  -- a validar pelo jurista
  created_at        timestamptz not null default now()
);

-- Concessões cliente -> escritório (tudo ou nada, por escritório)
create table if not exists public.consent_grants (
  id               uuid primary key default gen_random_uuid(),
  client_id        uuid not null references public.profiles (id) on delete cascade,
  office_id        uuid not null references public.offices (id) on delete restrict,
  status           public.grant_status not null default 'pendente',
  consent_version  text not null references public.consent_texts (version),
  created_by       uuid references public.profiles (id) on delete set null, -- mediador que convidou, ou o próprio cliente
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  accepted_at      timestamptz,
  declined_at      timestamptz,
  withdrawn_at     timestamptz
);
-- No máximo uma concessão "aberta" (pendente ou ativa) por cliente e escritório.
-- Recusada e retirada são finais; voltar a aceitar cria um registo novo.
create unique index if not exists consent_grants_one_open_uidx
  on public.consent_grants (client_id, office_id) where status in ('pendente', 'ativa');
create index if not exists consent_grants_client_idx on public.consent_grants (client_id);
create index if not exists consent_grants_office_status_idx on public.consent_grants (office_id, status);

-- Auditoria de consentimento. Sem FKs de propósito: o registo sobrevive a apagamentos.
create table if not exists public.consent_audit (
  id               bigint generated always as identity primary key,
  grant_id         uuid not null,
  client_id        uuid not null,
  office_id        uuid not null,
  action           text not null check (action in ('created', 'accepted', 'declined', 'withdrawn')),
  consent_version  text not null,
  actor_id         uuid,                       -- auth.uid() de quem agiu (null = service role)
  created_at       timestamptz not null default now()
);
create index if not exists consent_audit_client_idx on public.consent_audit (client_id);
create index if not exists consent_audit_office_idx on public.consent_audit (office_id);

-- Dados que o mediador escreve no perfil do cliente (tabela mínima, decisão 2 = A)
create table if not exists public.client_office_notes (
  id          uuid primary key default gen_random_uuid(),
  client_id   uuid not null references public.profiles (id) on delete cascade,
  office_id   uuid not null references public.offices (id) on delete restrict,
  notes       text not null default '' check (char_length(notes) <= 10000),
  author_id   uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (client_id, office_id)
);
create index if not exists client_office_notes_office_idx on public.client_office_notes (office_id);

-- -----------------------------------------------------------------------------
-- 3. Texto de consentimento: seed v0-rascunho (PLACEHOLDER, a validar pelo jurista)
-- -----------------------------------------------------------------------------
insert into public.consent_texts (version, content, is_draft, needs_legal_review)
values (
  'v0-rascunho',
  'RASCUNHO, A VALIDAR PELO JURISTA. Ao aceitar, autoriza este escritório de mediação (todos os mediadores do escritório) a aceder aos dados e documentos que partilha na plataforma, para tratar os seus pedidos. Pode retirar este acesso a qualquer momento e o escritório deixa de ver os seus dados de imediato. Este texto não é final.',
  true,
  true
)
on conflict (version) do nothing;

-- -----------------------------------------------------------------------------
-- 4. Funções auxiliares (SECURITY DEFINER para evitar recursão de RLS)
-- -----------------------------------------------------------------------------

-- Papel do utilizador autenticado (null se não houver perfil)
create or replace function public.my_role()
returns public.app_role
language sql stable security definer set search_path = ''
as $$
  select p.role from public.profiles p where p.id = auth.uid();
$$;

-- Escritório do mediador autenticado (null se não for mediador com escritório)
create or replace function public.my_office_id()
returns uuid
language sql stable security definer set search_path = ''
as $$
  select m.office_id from public.office_members m where m.user_id = auth.uid();
$$;

-- O id corresponde a um perfil de cliente?
create or replace function public.is_client(p_user uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.profiles p where p.id = p_user and p.role = 'cliente');
$$;

-- Concessão ativa deste cliente com este escritório?
create or replace function public.has_active_grant(p_client uuid, p_office uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.consent_grants g
    where g.client_id = p_client and g.office_id = p_office and g.status = 'ativa'
  );
$$;

-- O cliente autenticado tem alguma concessão (qualquer estado) com o escritório?
create or replace function public.client_has_grant_with(p_office uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.consent_grants g
    where g.client_id = auth.uid() and g.office_id = p_office
  );
$$;

-- O mediador autenticado vê este cliente completo (concessão ativa no seu escritório)?
create or replace function public.mediator_sees_client(p_client uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select public.my_role() = 'mediador'
     and public.has_active_grant(p_client, public.my_office_id());
$$;

-- Versão atual do texto de consentimento (a mais recente)
create or replace function public.current_consent_version()
returns text
language sql stable security definer set search_path = ''
as $$
  select t.version from public.consent_texts t order by t.created_at desc, t.version desc limit 1;
$$;

-- -----------------------------------------------------------------------------
-- 5. Triggers
-- -----------------------------------------------------------------------------

-- 5.1 Pertença: só mediadores podem pertencer a um escritório
create or replace function public.trg_office_members_check()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.profiles p where p.id = new.user_id and p.role = 'mediador') then
    raise exception 'Só um mediador pode pertencer a um escritório' using errcode = '23514';
  end if;
  return new;
end;
$$;
drop trigger if exists office_members_check on public.office_members;
create trigger office_members_check
  before insert or update on public.office_members
  for each row execute function public.trg_office_members_check();

-- 5.2 Concessões: validação e datas à entrada
create or replace function public.trg_consent_grants_before_insert()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.profiles p where p.id = new.client_id and p.role = 'cliente') then
    raise exception 'A concessão tem de ser de um cliente' using errcode = '23514';
  end if;
  new.created_by := coalesce(new.created_by, auth.uid());
  new.created_at := now();
  new.updated_at := now();
  new.accepted_at := case when new.status = 'ativa' then now() else null end;
  new.declined_at := null;
  new.withdrawn_at := null;
  if new.status not in ('pendente', 'ativa') then
    raise exception 'Uma concessão nasce pendente (mediador) ou ativa (cliente a voltar a aceitar)' using errcode = '23514';
  end if;
  return new;
end;
$$;
drop trigger if exists consent_grants_before_insert on public.consent_grants;
create trigger consent_grants_before_insert
  before insert on public.consent_grants
  for each row execute function public.trg_consent_grants_before_insert();

-- 5.3 Concessões: transições permitidas e campos imutáveis
--     pendente -> ativa | recusada ; ativa -> retirada ; recusada e retirada são finais.
create or replace function public.trg_consent_grants_before_update()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  -- só o cliente titular (service role, com auth.uid() nulo, não precisa de mudar estados)
  if auth.uid() is not null and auth.uid() <> old.client_id then
    raise exception 'Só o cliente titular pode alterar a concessão' using errcode = '42501';
  end if;
  if new.client_id <> old.client_id or new.office_id <> old.office_id
     or new.created_by is distinct from old.created_by or new.created_at <> old.created_at
     or new.accepted_at is distinct from old.accepted_at
     or new.declined_at is distinct from old.declined_at
     or new.withdrawn_at is distinct from old.withdrawn_at then
    raise exception 'Campos da concessão não alteráveis' using errcode = '42501';
  end if;
  if new.status = old.status then
    -- sem mudança de estado nada muda (nem a versão do texto)
    if new.consent_version <> old.consent_version then
      raise exception 'A versão só muda ao aceitar' using errcode = '42501';
    end if;
    return new;
  end if;
  if not ((old.status = 'pendente' and new.status in ('ativa', 'recusada'))
       or (old.status = 'ativa' and new.status = 'retirada')) then
    raise exception 'Transição de estado não permitida: % -> %', old.status, new.status using errcode = '23514';
  end if;
  if new.status <> 'ativa' and new.consent_version <> old.consent_version then
    raise exception 'A versão só muda ao aceitar' using errcode = '42501';
  end if;
  new.updated_at := now();
  if new.status = 'ativa'    then new.accepted_at  := now(); end if;
  if new.status = 'recusada' then new.declined_at  := now(); end if;
  if new.status = 'retirada' then new.withdrawn_at := now(); end if;
  return new;
end;
$$;
drop trigger if exists consent_grants_before_update on public.consent_grants;
create trigger consent_grants_before_update
  before update on public.consent_grants
  for each row execute function public.trg_consent_grants_before_update();

-- 5.4 Concessões sem DELETE nem TRUNCATE (são histórico; o estado "retirada" é o fim)
create or replace function public.trg_consent_grants_no_delete()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  raise exception 'As concessões não se apagam' using errcode = '42501';
end;
$$;
drop trigger if exists consent_grants_no_delete on public.consent_grants;
create trigger consent_grants_no_delete
  before delete on public.consent_grants
  for each row execute function public.trg_consent_grants_no_delete();
-- (apagar um cliente em cascata também é bloqueado: o apagamento RGPD é um processo à parte, ver riscos)

-- 5.5 Auditoria automática ao criar ou mudar uma concessão (100% dos casos)
create or replace function public.trg_consent_grants_audit()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.consent_audit (grant_id, client_id, office_id, action, consent_version, actor_id)
    values (new.id, new.client_id, new.office_id, 'created', new.consent_version, auth.uid());
    if new.status = 'ativa' then
      insert into public.consent_audit (grant_id, client_id, office_id, action, consent_version, actor_id)
      values (new.id, new.client_id, new.office_id, 'accepted', new.consent_version, auth.uid());
    end if;
  elsif new.status is distinct from old.status then
    insert into public.consent_audit (grant_id, client_id, office_id, action, consent_version, actor_id)
    values (
      new.id, new.client_id, new.office_id,
      case new.status
        when 'ativa'    then 'accepted'
        when 'recusada' then 'declined'
        when 'retirada' then 'withdrawn'
      end,
      new.consent_version, auth.uid()
    );
  end if;
  return null;
end;
$$;
drop trigger if exists consent_grants_audit on public.consent_grants;
create trigger consent_grants_audit
  after insert or update on public.consent_grants
  for each row execute function public.trg_consent_grants_audit();

-- 5.6 Auditoria imutável: UPDATE, DELETE e TRUNCATE falham para toda a gente
create or replace function public.trg_consent_audit_immutable()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  raise exception 'A auditoria só aceita INSERT' using errcode = '42501';
end;
$$;
drop trigger if exists consent_audit_no_update_delete on public.consent_audit;
create trigger consent_audit_no_update_delete
  before update or delete on public.consent_audit
  for each row execute function public.trg_consent_audit_immutable();
drop trigger if exists consent_audit_no_truncate on public.consent_audit;
create trigger consent_audit_no_truncate
  before truncate on public.consent_audit
  for each statement execute function public.trg_consent_audit_immutable();

-- 5.7 Notas do mediador: autor e datas
create or replace function public.trg_notes_stamp()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.author_id := auth.uid();
    new.created_at := now();
  else
    if new.client_id <> old.client_id or new.office_id <> old.office_id then
      raise exception 'Cliente e escritório não são alteráveis' using errcode = '42501';
    end if;
    new.created_at := old.created_at;
    new.author_id := auth.uid();
  end if;
  new.updated_at := now();
  return new;
end;
$$;
drop trigger if exists client_office_notes_stamp on public.client_office_notes;
create trigger client_office_notes_stamp
  before insert or update on public.client_office_notes
  for each row execute function public.trg_notes_stamp();

-- -----------------------------------------------------------------------------
-- 6. RLS: ativar em todas as tabelas
-- -----------------------------------------------------------------------------
alter table public.profiles            enable row level security;
alter table public.offices             enable row level security;
alter table public.office_members      enable row level security;
alter table public.consent_texts       enable row level security;
alter table public.consent_grants      enable row level security;
alter table public.consent_audit       enable row level security;
alter table public.client_office_notes enable row level security;

-- -----------------------------------------------------------------------------
-- 7. Privilégios (menos privilégio: nada para anon, mínimo para authenticated)
-- -----------------------------------------------------------------------------
revoke all on public.profiles, public.offices, public.office_members, public.consent_texts,
              public.consent_grants, public.consent_audit, public.client_office_notes
  from public, anon, authenticated;

grant select                        on public.profiles            to authenticated;
grant update (full_name)            on public.profiles            to authenticated;
grant select, insert, update        on public.offices             to authenticated;
grant select, insert, delete        on public.office_members      to authenticated;
grant select                        on public.consent_texts       to authenticated;
grant select, insert                on public.consent_grants      to authenticated;
grant update (status, consent_version) on public.consent_grants   to authenticated;
grant select                        on public.consent_audit       to authenticated; -- sem INSERT/UPDATE/DELETE: só o trigger escreve
grant select, insert, update (notes) on public.client_office_notes to authenticated;

-- -----------------------------------------------------------------------------
-- 8. Políticas RLS
-- -----------------------------------------------------------------------------

-- profiles --------------------------------------------------------------------
-- O admin só lê o PRÓPRIO perfil (precisa do papel para as rotas). Nunca os dos outros.
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid());

-- Mediador: clientes com concessão ativa no seu escritório (completo).
-- Pendente/recusada só via public.list_office_clients().
drop policy if exists profiles_select_mediator_active on public.profiles;
create policy profiles_select_mediator_active on public.profiles
  for select to authenticated using (public.mediator_sees_client(id));

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
-- (grant de coluna: só full_name; o papel e o email não mudam por aqui)
-- INSERT/DELETE: sem política = recusado. Perfis criam-se com service role.

-- offices ---------------------------------------------------------------------
drop policy if exists offices_select on public.offices;
create policy offices_select on public.offices
  for select to authenticated using (
    public.my_role() = 'admin'
    or id = public.my_office_id()
    or public.client_has_grant_with(id)
  );

drop policy if exists offices_insert_admin on public.offices;
create policy offices_insert_admin on public.offices
  for insert to authenticated with check (public.my_role() = 'admin');

drop policy if exists offices_update_admin on public.offices;
create policy offices_update_admin on public.offices
  for update to authenticated using (public.my_role() = 'admin') with check (public.my_role() = 'admin');

-- office_members --------------------------------------------------------------
-- Só ids (sem dados pessoais). Admin vê todas; mediador vê a sua.
drop policy if exists office_members_select on public.office_members;
create policy office_members_select on public.office_members
  for select to authenticated using (user_id = auth.uid() or public.my_role() = 'admin');

drop policy if exists office_members_insert_admin on public.office_members;
create policy office_members_insert_admin on public.office_members
  for insert to authenticated with check (public.my_role() = 'admin');

drop policy if exists office_members_delete_admin on public.office_members;
create policy office_members_delete_admin on public.office_members
  for delete to authenticated using (public.my_role() = 'admin');

-- consent_texts ---------------------------------------------------------------
drop policy if exists consent_texts_select on public.consent_texts;
create policy consent_texts_select on public.consent_texts
  for select to authenticated using (true);
-- escrita: só por migração (sem política)

-- consent_grants --------------------------------------------------------------
drop policy if exists grants_select_client on public.consent_grants;
create policy grants_select_client on public.consent_grants
  for select to authenticated using (client_id = auth.uid());

-- Mediador: as do seu escritório, nunca as retiradas ("retirada: nada")
drop policy if exists grants_select_mediator on public.consent_grants;
create policy grants_select_mediator on public.consent_grants
  for select to authenticated using (
    public.my_role() = 'mediador'
    and office_id = public.my_office_id()
    and status <> 'retirada'
  );

-- Mediador só cria concessões pendentes, para o seu escritório, para um cliente
drop policy if exists grants_insert_mediator on public.consent_grants;
create policy grants_insert_mediator on public.consent_grants
  for insert to authenticated with check (
    public.my_role() = 'mediador'
    and office_id = public.my_office_id()
    and status = 'pendente'
    and created_by = auth.uid()
    and consent_version = public.current_consent_version()
    and public.is_client(client_id)
  );

-- Só o cliente titular muda o estado (o trigger valida as transições)
drop policy if exists grants_update_client on public.consent_grants;
create policy grants_update_client on public.consent_grants
  for update to authenticated
  using (client_id = auth.uid())
  with check (client_id = auth.uid());
-- DELETE: sem política e trigger a bloquear. Mediador e admin: sem UPDATE.

-- consent_audit ---------------------------------------------------------------
drop policy if exists audit_select_client on public.consent_audit;
create policy audit_select_client on public.consent_audit
  for select to authenticated using (client_id = auth.uid());

drop policy if exists audit_select_mediator on public.consent_audit;
create policy audit_select_mediator on public.consent_audit
  for select to authenticated using (
    public.my_role() = 'mediador' and office_id = public.my_office_id()
  );
-- INSERT/UPDATE/DELETE: sem política, sem privilégio e com trigger. Admin: nada.

-- client_office_notes ---------------------------------------------------------
drop policy if exists notes_select_client on public.client_office_notes;
create policy notes_select_client on public.client_office_notes
  for select to authenticated using (client_id = auth.uid());

-- Mediador só com concessão ativa: a retirada oculta de imediato; uma nova concessão ativa repõe.
drop policy if exists notes_select_mediator on public.client_office_notes;
create policy notes_select_mediator on public.client_office_notes
  for select to authenticated using (
    public.my_role() = 'mediador'
    and office_id = public.my_office_id()
    and public.has_active_grant(client_id, office_id)
  );

drop policy if exists notes_insert_mediator on public.client_office_notes;
create policy notes_insert_mediator on public.client_office_notes
  for insert to authenticated with check (
    public.my_role() = 'mediador'
    and office_id = public.my_office_id()
    and public.has_active_grant(client_id, office_id)
  );

drop policy if exists notes_update_mediator on public.client_office_notes;
create policy notes_update_mediator on public.client_office_notes
  for update to authenticated
  using (
    public.my_role() = 'mediador'
    and office_id = public.my_office_id()
    and public.has_active_grant(client_id, office_id)
  )
  with check (
    public.my_role() = 'mediador'
    and office_id = public.my_office_id()
    and public.has_active_grant(client_id, office_id)
  );

-- -----------------------------------------------------------------------------
-- 9. RPCs (identidade sempre por auth.uid())
-- -----------------------------------------------------------------------------

-- 9.1 Mediador: lista paginada de clientes do seu escritório.
--     Devolve só id, nome, email e estado (pendente, ativa, recusada). Retiradas: nunca.
create or replace function public.list_office_clients(p_limit integer default 50, p_offset integer default 0)
returns table (
  grant_id    uuid,
  client_id   uuid,
  full_name   text,
  email       text,
  status      public.grant_status,
  created_at  timestamptz,
  updated_at  timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select g.id, g.client_id, p.full_name, p.email, g.status, g.created_at, g.updated_at
  from public.consent_grants g
  join public.profiles p on p.id = g.client_id
  where public.my_role() = 'mediador'
    and g.office_id = public.my_office_id()
    and g.status in ('pendente', 'ativa', 'recusada')
  order by g.created_at desc, g.id
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- 9.2 Cliente: "Com quem partilho". Concessões próprias com nome do escritório e do mediador.
create or replace function public.my_consents()
returns table (
  grant_id         uuid,
  office_id        uuid,
  office_name      text,
  mediator_name    text,
  status           public.grant_status,
  consent_version  text,
  created_at       timestamptz,
  accepted_at      timestamptz,
  declined_at      timestamptz,
  withdrawn_at     timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select g.id, g.office_id, o.name, m.full_name, g.status, g.consent_version,
         g.created_at, g.accepted_at, g.declined_at, g.withdrawn_at
  from public.consent_grants g
  join public.offices o on o.id = g.office_id
  left join public.profiles m on m.id = g.created_by and m.role = 'mediador'
  where g.client_id = auth.uid()
  order by g.created_at desc, g.id;
$$;

-- 9.3 Admin: 3 contagens, sem dados pessoais. Outros papéis: 0 linhas.
create or replace function public.admin_counts()
returns table (offices bigint, mediators bigint, clients bigint)
language sql stable security definer set search_path = ''
as $$
  select
    (select count(*) from public.offices),
    (select count(*) from public.profiles where role = 'mediador'),
    (select count(*) from public.profiles where role = 'cliente')
  where public.my_role() = 'admin';
$$;

-- 9.4 Cliente volta a aceitar depois de retirar: nasce um registo novo, ativo, com a versão aceite.
--     Só se já existiu uma concessão retirada com esse escritório (sem diretório público: decisão 1)
--     e não há outra aberta. O trigger cria o registo de auditoria.
create or replace function public.reaccept_grant(p_office_id uuid, p_version text)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null or public.my_role() is distinct from 'cliente' then
    raise exception 'Sem permissão' using errcode = '42501';
  end if;
  if p_version is distinct from public.current_consent_version() then
    raise exception 'Versão do texto desatualizada' using errcode = '23514';
  end if;
  if not exists (select 1 from public.consent_grants g
                 where g.client_id = auth.uid() and g.office_id = p_office_id and g.status = 'retirada') then
    raise exception 'Sem concessão anterior retirada com este escritório' using errcode = '42501';
  end if;
  if exists (select 1 from public.consent_grants g
             where g.client_id = auth.uid() and g.office_id = p_office_id and g.status in ('pendente', 'ativa')) then
    raise exception 'Já existe uma concessão aberta' using errcode = '23505';
  end if;
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
  values (auth.uid(), p_office_id, 'ativa', p_version, auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

-- -----------------------------------------------------------------------------
-- 10. Execução das funções: nada para anon/public; authenticated onde faz sentido
-- -----------------------------------------------------------------------------
revoke execute on function
  public.my_role(), public.my_office_id(), public.is_client(uuid), public.has_active_grant(uuid, uuid),
  public.client_has_grant_with(uuid), public.mediator_sees_client(uuid), public.current_consent_version(),
  public.list_office_clients(integer, integer), public.my_consents(), public.admin_counts(),
  public.reaccept_grant(uuid, text)
  from public, anon;

grant execute on function
  public.my_role(), public.my_office_id(), public.is_client(uuid), public.has_active_grant(uuid, uuid),
  public.client_has_grant_with(uuid), public.mediator_sees_client(uuid), public.current_consent_version(),
  public.list_office_clients(integer, integer), public.my_consents(), public.admin_counts(),
  public.reaccept_grant(uuid, text)
  to authenticated;

-- Funções de trigger: ninguém as chama diretamente
revoke execute on function
  public.trg_office_members_check(), public.trg_consent_grants_before_insert(),
  public.trg_consent_grants_before_update(), public.trg_consent_grants_no_delete(),
  public.trg_consent_grants_audit(), public.trg_consent_audit_immutable(), public.trg_notes_stamp()
  from public, anon, authenticated;
