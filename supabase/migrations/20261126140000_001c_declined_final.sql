-- =============================================================================
-- Migração 20261126140000_001c_declined_final
-- Objetivo : (1) "recusada é final" imposto na base de dados: o mediador não
--            consegue criar novo pedido pendente para um cliente que já
--            recusou este escritório. (2) Listas ordenadas por updated_at
--            (um pedido reenviado fica no topo).
-- Data     : 2026-11-26
-- Estado   : NÃO APLICADA (o Henrique atualiza esta linha depois de aplicar
--            no SQL Editor e confirmar). Aplicar DEPOIS da 20261126120000
--            (e da 20261126130000).
--
-- Notas
--  * Idempotente. Não altera as migrações anteriores: substitui a política
--    grants_insert_mediator e recria as duas funções com a mesma assinatura
--    (CREATE OR REPLACE, sem overloads novos).
--  * O cliente continua a poder voltar a aceitar só depois de RETIRAR (reaccept_grant);
--    recusada não tem caminho de volta pelo mediador.
-- =============================================================================

-- 1. Auxiliar: existe concessão recusada deste cliente neste escritório?
--    SECURITY DEFINER para não depender da RLS de quem pergunta.
create or replace function public.has_declined_grant(p_client uuid, p_office uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.consent_grants g
    where g.client_id = p_client and g.office_id = p_office and g.status = 'recusada'
  );
$$;
revoke execute on function public.has_declined_grant(uuid, uuid) from public, anon;
grant execute on function public.has_declined_grant(uuid, uuid) to authenticated;

-- 2. Política de INSERT do mediador: igual à anterior + sem recusada prévia
drop policy if exists grants_insert_mediator on public.consent_grants;
create policy grants_insert_mediator on public.consent_grants
  for insert to authenticated with check (
    public.my_role() = 'mediador'
    and office_id = public.my_office_id()
    and status = 'pendente'
    and created_by = auth.uid()
    and consent_version = public.current_consent_version()
    and public.is_client(client_id)
    and not public.has_declined_grant(client_id, office_id)
  );

-- 3. Lista do mediador: mais recentemente atualizados primeiro
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
  order by g.updated_at desc, g.id
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- 4. "Com quem partilho" do cliente: idem
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
  order by g.updated_at desc, g.id;
$$;

-- Privilégios das funções recriadas (mantêm-se, repetidos por segurança)
revoke execute on function public.list_office_clients(integer, integer), public.my_consents() from public, anon;
grant execute on function public.list_office_clients(integer, integer), public.my_consents() to authenticated;
