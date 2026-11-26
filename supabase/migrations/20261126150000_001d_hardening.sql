-- =============================================================================
-- Migração 20261126150000_001d_hardening
-- Objetivo : correções do qa da feature 001 (docs/features/001-fundacao/05-qa.md)
--            (1) Bug 7: as funções auxiliares SECURITY DEFINER com parâmetros
--                (is_client, has_active_grant, has_declined_grant,
--                mediator_sees_client, client_has_grant_with) deixam de estar
--                no esquema exposto `public`. Passam para o esquema `private`,
--                que a API (PostgREST) não expõe, e as políticas RLS e as RPCs
--                passam a usá-las de lá. Deixam de ser um oráculo por RPC.
--            (2) Bug 9: nome de escritório único sem distinguir maiúsculas.
--            (3) Bug 12: RPC office_client_count() com o total de clientes do
--                escritório do mediador (a lista continua paginada).
-- Data     : 2026-11-26
-- Estado   : NÃO APLICADA (o Henrique atualiza esta linha depois de aplicar
--            no SQL Editor e confirmar). Aplicar DEPOIS da 001, 001b e 001c.
--
-- Notas de desenho
--  * Idempotente e numa só transação: se algo falhar, nada muda.
--  * Validada num Postgres 16 local descartável (stub de auth): 001 a 001d
--    aplicadas duas vezes sem erro; supabase/tests/001_isolation_matrix.sql
--    passa de 65 PASS / 2 RISCO para 66 PASS / 0 FAIL / 1 RISCO (X02 resolvido).
--  * Não altera as migrações anteriores. As RPCs recriadas mantêm a mesma
--    assinatura e o mesmo tipo de retorno (CREATE OR REPLACE, sem overloads).
--  * Políticas avaliam-se com o papel de quem pergunta: `authenticated` precisa
--    de USAGE no esquema `private` e EXECUTE nas funções. Isso NÃO as torna
--    chamáveis pela API, porque a API só serve os esquemas expostos
--    (Settings > API > Exposed schemas: public e graphql_public). Nunca
--    acrescentar `private` a essa lista.
--  * public.my_role() e public.my_office_id() ficam (o script da matriz e
--    possíveis chamadas antigas usam-nas), mas passam a SECURITY INVOKER: só
--    respondem sobre o próprio utilizador, através da RLS de profiles e
--    office_members (políticas *_own). Já não contornam a RLS.
--  * public.current_consent_version() fica igual: é uma RPC usada pela app e o
--    texto de consentimento é legível por qualquer autenticado.
--  * Os DROP FUNCTION no fim não usam CASCADE: se alguma política ou função
--    ainda depender das versões antigas, a migração falha e nada é aplicado.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. Esquema privado (não exposto pela API)
-- -----------------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Auxiliares em private (mesmo corpo das versões de public; SECURITY DEFINER
--    para as políticas não entrarem em recursão de RLS)
-- -----------------------------------------------------------------------------
create or replace function private.my_role()
returns public.app_role
language sql stable security definer set search_path = ''
as $$
  select p.role from public.profiles p where p.id = auth.uid();
$$;

create or replace function private.my_office_id()
returns uuid
language sql stable security definer set search_path = ''
as $$
  select m.office_id from public.office_members m where m.user_id = auth.uid();
$$;

create or replace function private.is_client(p_user uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.profiles p where p.id = p_user and p.role = 'cliente');
$$;

create or replace function private.has_active_grant(p_client uuid, p_office uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.consent_grants g
    where g.client_id = p_client and g.office_id = p_office and g.status = 'ativa'
  );
$$;

create or replace function private.has_declined_grant(p_client uuid, p_office uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.consent_grants g
    where g.client_id = p_client and g.office_id = p_office and g.status = 'recusada'
  );
$$;

create or replace function private.client_has_grant_with(p_office uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.consent_grants g
    where g.client_id = auth.uid() and g.office_id = p_office
  );
$$;

create or replace function private.mediator_sees_client(p_client uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select private.my_role() = 'mediador'
     and private.has_active_grant(p_client, private.my_office_id());
$$;

revoke execute on all functions in schema private from public, anon;
grant execute on function
  private.my_role(), private.my_office_id(), private.is_client(uuid),
  private.has_active_grant(uuid, uuid), private.has_declined_grant(uuid, uuid),
  private.client_has_grant_with(uuid), private.mediator_sees_client(uuid)
  to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Políticas RLS: as mesmas regras, agora com as auxiliares de private
-- -----------------------------------------------------------------------------

-- profiles
drop policy if exists profiles_select_mediator_active on public.profiles;
create policy profiles_select_mediator_active on public.profiles
  for select to authenticated using (private.mediator_sees_client(id));

-- offices
drop policy if exists offices_select on public.offices;
create policy offices_select on public.offices
  for select to authenticated using (
    private.my_role() = 'admin'
    or id = private.my_office_id()
    or private.client_has_grant_with(id)
  );

drop policy if exists offices_insert_admin on public.offices;
create policy offices_insert_admin on public.offices
  for insert to authenticated with check (private.my_role() = 'admin');

drop policy if exists offices_update_admin on public.offices;
create policy offices_update_admin on public.offices
  for update to authenticated using (private.my_role() = 'admin') with check (private.my_role() = 'admin');

-- office_members
drop policy if exists office_members_select on public.office_members;
create policy office_members_select on public.office_members
  for select to authenticated using (user_id = auth.uid() or private.my_role() = 'admin');

drop policy if exists office_members_insert_admin on public.office_members;
create policy office_members_insert_admin on public.office_members
  for insert to authenticated with check (private.my_role() = 'admin');

drop policy if exists office_members_delete_admin on public.office_members;
create policy office_members_delete_admin on public.office_members
  for delete to authenticated using (private.my_role() = 'admin');

-- consent_grants
drop policy if exists grants_select_mediator on public.consent_grants;
create policy grants_select_mediator on public.consent_grants
  for select to authenticated using (
    private.my_role() = 'mediador'
    and office_id = private.my_office_id()
    and status <> 'retirada'
  );

drop policy if exists grants_insert_mediator on public.consent_grants;
create policy grants_insert_mediator on public.consent_grants
  for insert to authenticated with check (
    private.my_role() = 'mediador'
    and office_id = private.my_office_id()
    and status = 'pendente'
    and created_by = auth.uid()
    and consent_version = public.current_consent_version()
    and private.is_client(client_id)
    and not private.has_declined_grant(client_id, office_id)
  );

-- consent_audit
drop policy if exists audit_select_mediator on public.consent_audit;
create policy audit_select_mediator on public.consent_audit
  for select to authenticated using (
    private.my_role() = 'mediador' and office_id = private.my_office_id()
  );

-- client_office_notes
drop policy if exists notes_select_mediator on public.client_office_notes;
create policy notes_select_mediator on public.client_office_notes
  for select to authenticated using (
    private.my_role() = 'mediador'
    and office_id = private.my_office_id()
    and private.has_active_grant(client_id, office_id)
  );

drop policy if exists notes_insert_mediator on public.client_office_notes;
create policy notes_insert_mediator on public.client_office_notes
  for insert to authenticated with check (
    private.my_role() = 'mediador'
    and office_id = private.my_office_id()
    and private.has_active_grant(client_id, office_id)
  );

drop policy if exists notes_update_mediator on public.client_office_notes;
create policy notes_update_mediator on public.client_office_notes
  for update to authenticated
  using (
    private.my_role() = 'mediador'
    and office_id = private.my_office_id()
    and private.has_active_grant(client_id, office_id)
  )
  with check (
    private.my_role() = 'mediador'
    and office_id = private.my_office_id()
    and private.has_active_grant(client_id, office_id)
  );

-- (profiles_select_own, profiles_update_own, consent_texts_select,
--  grants_select_client, grants_update_client, audit_select_client e
--  notes_select_client não usam auxiliares: ficam como estão.)

-- -----------------------------------------------------------------------------
-- 4. RPCs públicas: mesma assinatura e mesmo retorno, agora com private.*
-- -----------------------------------------------------------------------------

-- 4.1 Lista do mediador (igual à 001c)
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
  where private.my_role() = 'mediador'
    and g.office_id = private.my_office_id()
    and g.status in ('pendente', 'ativa', 'recusada')
  order by g.updated_at desc, g.id
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- 4.2 Contagens do admin (igual à 001)
create or replace function public.admin_counts()
returns table (offices bigint, mediators bigint, clients bigint)
language sql stable security definer set search_path = ''
as $$
  select
    (select count(*) from public.offices),
    (select count(*) from public.profiles where role = 'mediador'),
    (select count(*) from public.profiles where role = 'cliente')
  where private.my_role() = 'admin';
$$;

-- 4.3 Voltar a aceitar (igual à 001)
create or replace function public.reaccept_grant(p_office_id uuid, p_version text)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null or private.my_role() is distinct from 'cliente' then
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

-- 4.4 NOVA: total de clientes do escritório do mediador (bug 12).
--     Conta exatamente o que list_office_clients lista (pendente, ativa, recusada;
--     retiradas nunca). Outros papéis: 0. Sem parâmetros: identidade por auth.uid().
create or replace function public.office_client_count()
returns bigint
language sql stable security definer set search_path = ''
as $$
  select count(*)
  from public.consent_grants g
  where private.my_role() = 'mediador'
    and g.office_id = private.my_office_id()
    and g.status in ('pendente', 'ativa', 'recusada');
$$;

revoke execute on function
  public.list_office_clients(integer, integer), public.admin_counts(),
  public.reaccept_grant(uuid, text), public.office_client_count()
  from public, anon;
grant execute on function
  public.list_office_clients(integer, integer), public.admin_counts(),
  public.reaccept_grant(uuid, text), public.office_client_count()
  to authenticated;

-- -----------------------------------------------------------------------------
-- 5. public.my_role() e public.my_office_id(): ficam, mas sem SECURITY DEFINER
--    (respondem só sobre o próprio utilizador, pela RLS das políticas *_own)
-- -----------------------------------------------------------------------------
create or replace function public.my_role()
returns public.app_role
language sql stable security invoker set search_path = ''
as $$
  select p.role from public.profiles p where p.id = auth.uid();
$$;

create or replace function public.my_office_id()
returns uuid
language sql stable security invoker set search_path = ''
as $$
  select m.office_id from public.office_members m where m.user_id = auth.uid();
$$;

revoke execute on function public.my_role(), public.my_office_id() from public, anon;
grant execute on function public.my_role(), public.my_office_id() to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Remover os oráculos de public (sem CASCADE: falha se algo ainda depender)
-- -----------------------------------------------------------------------------
drop function if exists public.mediator_sees_client(uuid);
drop function if exists public.client_has_grant_with(uuid);
drop function if exists public.has_active_grant(uuid, uuid);
drop function if exists public.has_declined_grant(uuid, uuid);
drop function if exists public.is_client(uuid);

-- -----------------------------------------------------------------------------
-- 7. Nome de escritório único sem distinguir maiúsculas (bug 9).
--    Ao vivo a 26/11: 0 escritórios, sem duplicados. A app já trata 23505.
-- -----------------------------------------------------------------------------
create unique index if not exists offices_name_lower_uidx on public.offices (lower(name));

commit;
