-- =============================================================================
-- QA 001 Fundação: regressão das migrações 001d (endurecimento) e 001e (invited_name)
-- Ficheiro : supabase/tests/001de_regression.sql
-- Data     : 2026-11-27
-- Complementa supabase/tests/001_isolation_matrix.sql, que não cobre:
--   invited_name (bug 13), office_client_count (bug 12), nome de escritório único
--   (bug 9) e o esquema private sem acesso anónimo (bug 7).
--
-- COMO CORRER: igual à matriz. Um único bloco DO, como postgres. TERMINA SEMPRE EM
-- ERRO de propósito: o texto do erro é o relatório ("QA 001de: N PASS, N FAIL ...")
-- e o erro obriga ao ROLLBACK de tudo. Nada fica gravado.
-- Esperado: 0 FAIL. Se R00 falhar, a simulação de sessão não funcionou.
-- =============================================================================

do $qa$
declare
  v_tag  text := 'qa001de-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  v_ver  text;
  v_a    uuid := gen_random_uuid();
  v_b    uuid := gen_random_uuid();
  v_ma   uuid := gen_random_uuid();
  v_mb   uuid := gen_random_uuid();
  v_c1   uuid := gen_random_uuid();   -- ativa em A, perfil "Perfil C1", convidado "Convite C1"
  v_c3   uuid := gen_random_uuid();   -- pendente em A, perfil "Perfil C3", convidado "Convite C3"
  v_c6   uuid := gen_random_uuid();   -- pendente em A, sem invited_name (concessão anterior à 001e)
  v_c7   uuid := gen_random_uuid();   -- pendente em B (só para MB)
  v_adm  uuid := gen_random_uuid();
  g_c3a  uuid;
  v_out  text[] := '{}';
  v_ok   boolean;
  v_t    text;
  v_n    bigint;
  v_pass int; v_fail int;
begin
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
  v_ver := public.current_consent_version();

  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous)
  select u.id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
         v_tag || '-' || u.k || '@example.invalid', '', now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, false
  from (values (v_ma, 'ma'), (v_mb, 'mb'), (v_c1, 'c1'), (v_c3, 'c3'), (v_c6, 'c6'), (v_c7, 'c7'),
               (v_adm, 'adm')) as u(id, k);

  insert into public.profiles (id, role, full_name, email)
  select u.id, u.r::public.app_role, 'Perfil ' || upper(u.k), v_tag || '-' || u.k || '@example.invalid'
  from (values (v_ma, 'ma', 'mediador'), (v_mb, 'mb', 'mediador'), (v_c1, 'c1', 'cliente'),
               (v_c3, 'c3', 'cliente'), (v_c6, 'c6', 'cliente'), (v_c7, 'c7', 'cliente'),
               (v_adm, 'adm', 'admin')) as u(id, k, r);

  insert into public.offices (id, name) values (v_a, v_tag || ' Escritório A'), (v_b, v_tag || ' Escritório B');
  insert into public.office_members (user_id, office_id) values (v_ma, v_a), (v_mb, v_b);

  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by, invited_name)
    values (v_c1, v_a, 'ativa', v_ver, v_ma, 'Convite C1');
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by, invited_name)
    values (v_c3, v_a, 'pendente', v_ver, v_ma, 'Convite C3') returning id into g_c3a;
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c6, v_a, 'pendente', v_ver, v_ma);
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by, invited_name)
    values (v_c7, v_b, 'pendente', v_ver, v_mb, 'Convite C7');

  -- ===================== MA =====================
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;

  v_ok := auth.uid() = v_ma and current_user = 'authenticated';
  v_out := v_out || format('%s | R00 | MA | simulação de sessão | obtido: uid ok=%s user=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, auth.uid() = v_ma, current_user);

  -- R01 bug 13: pendente mostra o nome que o mediador escreveu, não o do perfil
  select l.full_name into v_t from public.list_office_clients(200, 0) l where l.client_id = v_c3;
  v_ok := v_t = 'Convite C3';
  v_out := v_out || format('%s | R01 | MA | pendente: nome = invited_name | esperado: Convite C3 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, coalesce(v_t, '(null)'));

  -- R02 ativa mostra o nome do perfil
  select l.full_name into v_t from public.list_office_clients(200, 0) l where l.client_id = v_c1;
  v_ok := v_t = 'Perfil C1';
  v_out := v_out || format('%s | R02 | MA | ativa: nome = perfil | esperado: Perfil C1 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, coalesce(v_t, '(null)'));

  -- R03 pendente sem invited_name (anterior à 001e) mostra o email, nunca o nome do perfil
  select l.full_name into v_t from public.list_office_clients(200, 0) l where l.client_id = v_c6;
  v_ok := v_t = v_tag || '-c6@example.invalid';
  v_out := v_out || format('%s | R03 | MA | pendente sem invited_name: email | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, coalesce(v_t, '(null)'));

  -- R04 office_client_count do MA = 3 (C1, C3, C6), igual ao tamanho da lista
  v_n := public.office_client_count();
  select count(*) = v_n into v_ok from public.list_office_clients(200, 0);
  v_ok := v_ok and v_n = 3;
  v_out := v_out || format('%s | R04 | MA | office_client_count = lista | esperado: 3 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);

  -- R05 invited_name é imutável (sem UPDATE de coluna para authenticated)
  begin
    update public.consent_grants set invited_name = 'Outro' where id = g_c3a;
    get diagnostics v_n = row_count;
    v_out := v_out || format('%s | R05 | MA | alterar invited_name | esperado: recusado | obtido: %s linhas',
                             case when v_n = 0 then 'PASS' else 'FAIL' end, v_n);
  exception when others then
    v_out := v_out || format('PASS | R05 | MA | alterar invited_name | recusado: %s', sqlstate);
  end;

  -- R06 invited_name com < ou > é recusado (CHECK)
  begin
    insert into public.consent_grants (client_id, office_id, status, consent_version, created_by, invited_name)
      values (v_c7, v_a, 'pendente', v_ver, v_ma, '<script>');
    v_out := v_out || 'FAIL | R06 | MA | invited_name com <> | esperado: recusado | obtido: aceite';
  exception when others then
    v_out := v_out || format('%s | R06 | MA | invited_name com <> | obtido: %s',
                             case when sqlstate = '23514' then 'PASS' else 'FAIL' end, sqlstate);
  end;

  -- R07 auxiliares de private continuam a responder dentro da RLS (sem elas a lista partia)
  v_ok := private.my_office_id() = v_a;
  v_out := v_out || format('%s | R07 | MA | private.my_office_id() | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_ok);

  -- ===================== MB =====================
  perform set_config('request.jwt.claims', json_build_object('sub', v_mb, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_mb::text, true);
  v_n := public.office_client_count();
  v_out := v_out || format('%s | R08 | MB | office_client_count só conta B | esperado: 1 | obtido: %s',
                           case when v_n = 1 then 'PASS' else 'FAIL' end, v_n);

  -- ===================== C3 (cliente) =====================
  perform set_config('request.jwt.claims', json_build_object('sub', v_c3, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c3::text, true);
  v_n := public.office_client_count();
  v_out := v_out || format('%s | R09 | C3 | office_client_count de cliente | esperado: 0 | obtido: %s',
                           case when v_n = 0 then 'PASS' else 'FAIL' end, v_n);
  begin
    update public.consent_grants set invited_name = 'Eu' where id = g_c3a;
    get diagnostics v_n = row_count;
    v_out := v_out || format('%s | R10 | C3 | titular altera invited_name | esperado: recusado | obtido: %s linhas',
                             case when v_n = 0 then 'PASS' else 'FAIL' end, v_n);
  exception when others then
    v_out := v_out || format('PASS | R10 | C3 | titular altera invited_name | recusado: %s', sqlstate);
  end;

  -- ===================== ADM =====================
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_adm::text, true);
  v_n := public.office_client_count();
  v_out := v_out || format('%s | R11 | ADM | office_client_count de admin | esperado: 0 | obtido: %s',
                           case when v_n = 0 then 'PASS' else 'FAIL' end, v_n);
  begin
    insert into public.offices (name) values (upper(v_tag || ' escritório a'));
    v_out := v_out || 'FAIL | R12 | ADM | nome de escritório repetido (maiúsculas) | esperado: 23505 | obtido: aceite';
  exception when others then
    v_out := v_out || format('%s | R12 | ADM | nome de escritório repetido (maiúsculas) | obtido: %s',
                             case when sqlstate = '23505' then 'PASS' else 'FAIL' end, sqlstate);
  end;

  -- ===================== anónimo =====================
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
  perform set_config('request.jwt.claim.sub', '', true);
  set local role anon;
  begin
    v_ok := private.has_active_grant(v_c1, v_a);
    v_out := v_out || format('FAIL | R13 | anon | private.has_active_grant | esperado: sem permissão | obtido: %s', v_ok);
  exception when others then
    v_out := v_out || format('%s | R13 | anon | private.has_active_grant | obtido: %s',
                             case when sqlstate = '42501' then 'PASS' else 'FAIL' end, sqlstate);
  end;
  begin
    v_n := public.office_client_count();
    v_out := v_out || format('FAIL | R14 | anon | office_client_count | esperado: sem permissão | obtido: %s', v_n);
  exception when others then
    v_out := v_out || format('%s | R14 | anon | office_client_count | obtido: %s',
                             case when sqlstate = '42501' then 'PASS' else 'FAIL' end, sqlstate);
  end;

  reset role;
  select count(*) filter (where x like 'PASS%'), count(*) filter (where x like 'FAIL%')
    into v_pass, v_fail from unnest(v_out) x;
  raise exception E'QA 001de: % PASS, % FAIL (ROLLBACK propositado, nada gravado)\n%',
    v_pass, v_fail, array_to_string(v_out, E'\n');
end
$qa$;
