---
name: supabase-migrations
description: Regras para migrações, RPCs e RLS em Supabase e as queries que confirmam o estado real da base de dados. Usar ao criar ou verificar qualquer mudança de schema.
---

# Migrações Supabase

## Escrever

- Um ficheiro por migração na pasta de migrações do projeto, numerado em sequência (vê o último que existe). Cabeçalho com objetivo, data e "NÃO APLICADA" (o Henrique atualiza depois de aplicar).
- Nunca aplicar: nem por MCP, nem por CLI (`supabase db push`), nem por SQL direto. Quem aplica é o Henrique, no SQL Editor.
- `CREATE OR REPLACE FUNCTION` com uma lista de parâmetros diferente cria um overload novo em vez de substituir. Se mudares a assinatura, faz `DROP FUNCTION IF EXISTS nome(tipos antigos);` antes.
- RPCs: a identidade vem sempre de `auth.uid()`, nunca de um parâmetro. `SECURITY DEFINER` só quando for preciso, e sempre com `search_path` fixo (por exemplo `set search_path = ''` com nomes qualificados `public.`).
- RLS ativo em todas as tabelas novas, com uma política para cada operação usada. `INSERT ... RETURNING` precisa de política de INSERT e também de SELECT.
- Idempotente quando possível (`IF NOT EXISTS`, `IF EXISTS`).

## Verificar no live (só leitura)

```sql
-- colunas de uma tabela
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = '<tabela>';

-- funções e overloads
select p.proname, pg_get_function_identity_arguments(p.oid) as args
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = '<funcao>';

-- RLS ativo
select relname, relrowsecurity from pg_class where oid = 'public.<tabela>'::regclass;

-- políticas
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = '<tabela>';

-- constraints
select conname, contype, pg_get_constraintdef(oid)
from pg_constraint
where conrelid = 'public.<tabela>'::regclass;
```

Um "feito" só conta depois de estas queries o confirmarem.
