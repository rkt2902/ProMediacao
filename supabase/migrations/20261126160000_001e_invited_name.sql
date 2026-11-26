-- =============================================================================
-- Migração 20261126160000_001e_invited_name
-- Objetivo : bug 13 do qa da feature 001 (docs/features/001-fundacao/05-qa.md),
--            opção A decidida pelo Henrique. Enquanto a concessão está pendente
--            ou recusada, o mediador vê o NOME QUE ELE PRÓPRIO ESCREVEU ao criar
--            o cliente; o full_name do perfil só aparece com a concessão ativa.
--            Assim a lista não revela que o email já tinha conta noutro escritório.
--            (1) consent_grants.invited_name: nome dado pelo mediador no convite
--                (1 a 200 caracteres, sem '<' nem '>'), imutável depois de criado.
--            (2) Preenchida para as concessões existentes a partir do perfil.
--            (3) list_office_clients recriada com a MESMA assinatura e colunas.
--                office_client_count não muda (só conta).
-- Data     : 2026-11-26
-- Estado   : NÃO APLICADA (o Henrique atualiza esta linha depois de aplicar).
--            Aplicar DEPOIS da 001, 001b, 001c e 001d.
--
-- Notas de desenho
--  * Idempotente, numa só transação, sem apagar dados.
--  * A coluna é nullable: concessões criadas pelo próprio cliente (reaccept_grant)
--    nascem ativas e não têm convite. Uma concessão pendente ou recusada sem
--    invited_name (só possível por INSERT direto pela API, fora do create-client)
--    mostra o email como nome, nunca o full_name do perfil.
--  * Escrita só no INSERT: o grant de UPDATE de authenticated continua limitado a
--    (status, consent_version) e o trigger de UPDATE passa a recusar mudanças a
--    invited_name (também ao service role).
--  * A edge function create-client grava invited_name; a versão publicada tolera
--    a coluna ainda não existir (repete o INSERT sem ela), por isso a ordem
--    deploy/aplicação não parte a criação de clientes.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1. Coluna e preenchimento das existentes (antes de a tornar imutável)
-- -----------------------------------------------------------------------------
alter table public.consent_grants add column if not exists invited_name text;

-- Só linhas ainda sem valor. O trigger de UPDATE deixa passar (estado igual,
-- versão igual) e a auditoria só regista mudanças de estado.
update public.consent_grants g
set invited_name = nullif(btrim(translate(left(p.full_name, 200), '<>', '')), '')
from public.profiles p
where p.id = g.client_id
  and g.invited_name is null;

do $$
begin
  if not exists (select 1 from pg_constraint
                 where conrelid = 'public.consent_grants'::regclass
                   and conname = 'consent_grants_invited_name_check') then
    alter table public.consent_grants
      add constraint consent_grants_invited_name_check
      check (invited_name is null
             or (char_length(invited_name) between 1 and 200
                 and invited_name = btrim(invited_name)
                 and invited_name !~ '[<>]'));
  end if;
end;
$$;

comment on column public.consent_grants.invited_name is
  'Nome escrito pelo mediador ao convidar. Mostrado ao escritório enquanto a concessão não está ativa (bug 13). Imutável.';

-- -----------------------------------------------------------------------------
-- 2. Trigger de UPDATE: igual à 001, mais invited_name na lista de imutáveis
-- -----------------------------------------------------------------------------
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
     or new.withdrawn_at is distinct from old.withdrawn_at
     or new.invited_name is distinct from old.invited_name then
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

-- -----------------------------------------------------------------------------
-- 3. Lista do mediador: mesma assinatura e colunas (CREATE OR REPLACE, sem overload)
--    full_name = perfil só com a concessão ativa; senão o nome do convite.
-- -----------------------------------------------------------------------------
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
  select g.id, g.client_id,
         case when g.status = 'ativa' then p.full_name
              else coalesce(g.invited_name, p.email) end,
         p.email, g.status, g.created_at, g.updated_at
  from public.consent_grants g
  join public.profiles p on p.id = g.client_id
  where private.my_role() = 'mediador'
    and g.office_id = private.my_office_id()
    and g.status in ('pendente', 'ativa', 'recusada')
  order by g.updated_at desc, g.id
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke execute on function public.list_office_clients(integer, integer) from public, anon;
grant execute on function public.list_office_clients(integer, integer) to authenticated;

commit;
