-- =============================================================================
-- Migração 20261126130000_001b_send_throttle
-- Objetivo : limite de 60 s por destinatário nos envios de email das funções de
--            servidor (convite/reenvio de pedido e pedido de link). Complementa
--            a migração 20261126120000_001_fundacao (não a altera).
-- Data     : 2026-11-26
-- Estado   : NÃO APLICADA (o Henrique atualiza esta linha depois de aplicar
--            no SQL Editor e confirmar). Aplicar DEPOIS da 20261126120000.
--
-- Notas de desenho
--  * Guarda só o hash SHA-256 do email em minúsculas (sem dados pessoais) e a
--    hora do último envio. Serve também emails que não existem como conta, para
--    a resposta ser igual exista ou não a conta.
--  * Só a service role (funções de servidor) usa a tabela e a função: RLS ativo
--    sem políticas, privilégios revogados a anon e authenticated.
--  * claim_send_slot é atómica (um único INSERT ... ON CONFLICT): dois pedidos
--    simultâneos não passam ambos.
--  * Idempotente.
-- =============================================================================

create table if not exists public.send_throttle (
  recipient_hash  text primary key check (char_length(recipient_hash) = 64),
  last_sent_at    timestamptz not null default now()
);
create index if not exists send_throttle_last_sent_idx on public.send_throttle (last_sent_at);

alter table public.send_throttle enable row level security;
revoke all on public.send_throttle from public, anon, authenticated;
-- Sem políticas de propósito: nenhum perfil da app lê ou escreve aqui.

-- Devolve 0 se o envio pode avançar (e regista-o) ou, caso contrário, os
-- segundos que faltam até o destinatário poder receber outro.
create or replace function public.claim_send_slot(p_recipient_hash text, p_window_seconds integer default 60)
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_window integer := least(greatest(coalesce(p_window_seconds, 60), 1), 3600);
  v_claimed integer;
  v_wait integer;
begin
  -- limpeza oportunista: registos com mais de 1 dia já não limitam nada
  delete from public.send_throttle where last_sent_at < now() - interval '1 day';

  insert into public.send_throttle as t (recipient_hash, last_sent_at)
  values (p_recipient_hash, now())
  on conflict (recipient_hash) do update
    set last_sent_at = now()
    where t.last_sent_at <= now() - make_interval(secs => v_window)
  returning 1 into v_claimed;

  if v_claimed is not null then
    return 0;
  end if;

  select ceil(extract(epoch from (t.last_sent_at + make_interval(secs => v_window) - now())))::integer
    into v_wait
  from public.send_throttle t
  where t.recipient_hash = p_recipient_hash;

  return greatest(coalesce(v_wait, 1), 1);
end;
$$;

revoke execute on function public.claim_send_slot(text, integer) from public, anon, authenticated;
grant execute on function public.claim_send_slot(text, integer) to service_role;
