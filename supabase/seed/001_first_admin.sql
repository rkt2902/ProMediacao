-- =============================================================================
-- Seed 001: primeiro admin. NÃO APLICADO. Só depois da migração 20261126120000_001_fundacao.
-- Passos (o Henrique, no painel do Supabase):
--  1. Authentication > Users > "Add user" com o email e palavra-passe do admin
--     (marcar "Auto confirm user"). Copiar o UUID criado.
--  2. Substituir os três valores abaixo e correr no SQL Editor.
-- Os perfis de mediador e cliente criam-se pelas funções de servidor (tarefa 2),
-- nunca por este ficheiro.
-- =============================================================================
insert into public.profiles (id, role, full_name, email)
values (
  '00000000-0000-0000-0000-000000000000',   -- UUID do utilizador criado em auth.users
  'admin',
  'Nome do admin',
  'admin@exemplo.pt'
)
on conflict (id) do nothing;
