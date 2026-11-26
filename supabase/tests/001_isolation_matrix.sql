-- =============================================================================
-- QA 001 Fundação: matriz de isolamento (US 6) + auditoria + transições
-- Ficheiro : supabase/tests/001_isolation_matrix.sql
-- Data     : 2026-11-26
-- Spec     : docs/features/001-fundacao/02-spec.md (US 3, 4, 5 e 6)
--
-- COMO CORRER (SQL Editor do Supabase, como postgres)
--   1. Colar o ficheiro inteiro e carregar em Run. Não é preciso selecionar nada.
--   2. O script TERMINA SEMPRE EM ERRO, de propósito: o erro final é o relatório
--      ("QA 001: N PASS, N FAIL, N RISCO ...") seguido de uma linha por teste.
--      O erro faz o ROLLBACK de tudo: utilizadores, escritórios, concessões,
--      notas e auditoria de teste desaparecem. Nada fica gravado.
--   3. Copiar o texto do erro para o lead (ou para o 05-qa.md).
--
-- PORQUE É UM ÚNICO BLOCO DO
--   Um único comando = uma única transação. O RAISE EXCEPTION no fim obriga ao
--   ROLLBACK mesmo que o editor esteja em autocommit, e não deixa a ligação
--   numa transação aberta ou abortada (o que podia acontecer com BEGIN ...
--   ROLLBACK num editor que corre vários comandos de uma vez).
--   Se algo falhar a meio (por exemplo na preparação), o erro mostrado é esse
--   e também nada fica gravado.
--
-- COMO SIMULA CADA PAPEL
--   set local role authenticated|anon + request.jwt.claims (e request.jwt.claim.sub)
--   com o "sub" do utilizador de teste, tal como o PostgREST faz. auth.uid() lê
--   esses valores. Os testes S* confirmam que a simulação funciona; se algum S*
--   der FAIL, o resto do relatório não vale.
--
-- LEGENDA
--   PASS  = resultado igual ao esperado na spec
--   FAIL  = divergência (bloqueia o fecho da feature, US 6)
--   RISCO = fora da letra da matriz, mas mostra uma fuga ou fragilidade conhecida
--           (ver 05-qa.md); não bloqueia sozinho
--
-- Dados de teste (todos novos, com emails @example.invalid e nomes "qa001-..."):
--   escritórios A e B; mediadores MA (A) e MB (B); clientes C1 (ativa A),
--   C2 (ativa A e B), C3 (pendente A), C4 (retirada A), C5 (recusada A);
--   admin ADM; anónimo. Notas do mediador: C1/A, C4/A, C2/B.
-- =============================================================================

do $qa$
declare
  v_tag  text := 'qa001-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
  v_ver  text;
  -- pessoas e escritórios
  v_a    uuid := gen_random_uuid();
  v_b    uuid := gen_random_uuid();
  v_ma   uuid := gen_random_uuid();
  v_mb   uuid := gen_random_uuid();
  v_c1   uuid := gen_random_uuid();
  v_c2   uuid := gen_random_uuid();
  v_c3   uuid := gen_random_uuid();
  v_c4   uuid := gen_random_uuid();
  v_c5   uuid := gen_random_uuid();
  v_adm  uuid := gen_random_uuid();
  v_lbl  jsonb;
  -- concessões
  g_c1a  uuid;  g_c2a uuid;  g_c2b uuid;  g_c3a uuid;  g_c4a uuid;  g_c5a uuid;
  g_c1a2 uuid;  g_c4a2 uuid;
  -- trabalho
  v_out  text[] := '{}';
  v_ok   boolean;
  v_t    text;
  v_n    bigint;
  v_n2   bigint;
  v_aud  bigint;
  v_pass int; v_fail int; v_risk int;
begin
  -- ---------------------------------------------------------------------------
  -- 0. Preparação (como postgres, sem sessão simulada)
  -- ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);

  v_ver := public.current_consent_version();
  if v_ver is null then
    raise exception 'Preparação: não há texto de consentimento (consent_texts vazio)';
  end if;

  v_lbl := jsonb_build_object(
    v_ma::text, 'MA', v_mb::text, 'MB', v_c1::text, 'C1', v_c2::text, 'C2', v_c3::text, 'C3',
    v_c4::text, 'C4', v_c5::text, 'C5', v_adm::text, 'ADM', v_a::text, 'A', v_b::text, 'B');

  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous)
  select u.id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
         v_tag || '-' || u.k || '@example.invalid', '', now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, false
  from (values (v_ma, 'ma'), (v_mb, 'mb'), (v_c1, 'c1'), (v_c2, 'c2'), (v_c3, 'c3'),
               (v_c4, 'c4'), (v_c5, 'c5'), (v_adm, 'adm')) as u(id, k);

  insert into public.profiles (id, role, full_name, email)
  select u.id, u.r::public.app_role, v_tag || ' ' || upper(u.k), v_tag || '-' || u.k || '@example.invalid'
  from (values (v_ma, 'ma', 'mediador'), (v_mb, 'mb', 'mediador'), (v_c1, 'c1', 'cliente'),
               (v_c2, 'c2', 'cliente'), (v_c3, 'c3', 'cliente'), (v_c4, 'c4', 'cliente'),
               (v_c5, 'c5', 'cliente'), (v_adm, 'adm', 'admin')) as u(id, k, r);

  insert into public.offices (id, name) values (v_a, v_tag || ' Escritório A'), (v_b, v_tag || ' Escritório B');
  insert into public.office_members (user_id, office_id) values (v_ma, v_a), (v_mb, v_b);

  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c1, v_a, 'ativa', v_ver, v_ma) returning id into g_c1a;
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c2, v_a, 'ativa', v_ver, v_ma) returning id into g_c2a;
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c2, v_b, 'ativa', v_ver, v_mb) returning id into g_c2b;
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c3, v_a, 'pendente', v_ver, v_ma) returning id into g_c3a;
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c4, v_a, 'ativa', v_ver, v_ma) returning id into g_c4a;
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c5, v_a, 'pendente', v_ver, v_ma) returning id into g_c5a;

  -- notas escritas enquanto a concessão estava ativa (C4 retira a seguir)
  insert into public.client_office_notes (client_id, office_id, notes)
    values (v_c1, v_a, 'nota C1/A'), (v_c4, v_a, 'nota C4/A'), (v_c2, v_b, 'nota C2/B');

  update public.consent_grants set status = 'retirada' where id = g_c4a;
  update public.consent_grants set status = 'recusada' where id = g_c5a;

  -- ===========================================================================
  -- MA (mediador do escritório A)
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;

  v_t := format('uid=%s role=%s my_role=%s', v_lbl ->> auth.uid()::text, current_user, public.my_role());
  v_ok := auth.uid() = v_ma and current_user = 'authenticated' and public.my_role() = 'mediador'
          and public.my_office_id() = v_a;
  v_out := v_out || format('%s | S1 | MA | simulação de sessão | esperado: uid=MA role=authenticated my_role=mediador | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- M01 listar clientes
  select coalesce(string_agg(x.lbl, ',' order by x.lbl), '(vazio)') into v_t
  from (select coalesce(v_lbl ->> l.client_id::text, 'OUTRO') || ':' || l.status::text as lbl
        from public.list_office_clients(200, 0) l) x;
  v_ok := v_t = 'C1:ativa,C2:ativa,C3:pendente,C5:recusada';
  v_out := v_out || format('%s | M01a | MA | listar clientes (lista) | esperado: C1:ativa,C2:ativa,C3:pendente,C5:recusada (C4 nada) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select coalesce(string_agg(x.lbl, ',' order by x.lbl), '(vazio)') into v_t
  from (select coalesce(v_lbl ->> p.id::text, 'OUTRO') as lbl
        from public.profiles p where p.id in (v_c1, v_c2, v_c3, v_c4, v_c5)) x;
  v_ok := v_t = 'C1,C2';
  v_out := v_out || format('%s | M01b | MA | perfis completos (tabela profiles) | esperado: C1,C2 (C3, C4, C5 não) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select count(*) into v_n from public.list_office_clients(200, 0) l
  where l.client_id in (v_c3, v_c5) and l.full_name is not null and l.email is not null;
  v_ok := v_n = 2;
  v_out := v_out || format('%s | M01c | MA | C3 e C5 só nome, email e estado (pela função) | esperado: 2 linhas com nome e email | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);

  select (select count(*) from public.consent_grants where client_id = v_c4)
       + (select count(*) from public.client_office_notes where client_id = v_c4)
       + (select count(*) from public.profiles where id = v_c4)
    into v_n;
  v_ok := v_n = 0;
  v_out := v_out || format('%s | M01d | MA | C4 (retirada): concessão, notas, perfil | esperado: 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);

  select count(*) into v_n from public.client_office_notes where client_id in (v_c1, v_c2);
  v_ok := v_n = 1;
  v_out := v_out || format('%s | M01e | MA | notas do escritório A (C1 ativa) | esperado: 1 (só a nota C1/A; a de C2/B é de B) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);

  -- M02 ler clientes, concessões, auditoria de B
  select format('offices=%s grants=%s audit=%s notes=%s members=%s perfilMB=%s',
           (select count(*) from public.offices where id = v_b),
           (select count(*) from public.consent_grants where office_id = v_b),
           (select count(*) from public.consent_audit where office_id = v_b),
           (select count(*) from public.client_office_notes where office_id = v_b),
           (select count(*) from public.office_members where office_id = v_b),
           (select count(*) from public.profiles where id = v_mb))
    into v_t;
  v_ok := v_t = 'offices=0 grants=0 audit=0 notes=0 members=0 perfilMB=0';
  v_out := v_out || format('%s | M02 | MA | ler escritório, clientes, concessões, auditoria e notas de B | esperado: tudo 0 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- M03 ler concessões de C2 com B
  select (select count(*) from public.consent_grants where client_id = v_c2 and office_id = v_b)
       + (select count(*) from public.consent_audit where grant_id = g_c2b)
    into v_n;
  v_ok := v_n = 0;
  v_out := v_out || format('%s | M03 | MA | ler concessão (e auditoria) de C2 com B | esperado: 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);

  -- M04 alterar estado de uma concessão (aceitar por C3, retirar C1, reabrir C5, apagar)
  begin
    update public.consent_grants set status = 'ativa' where id = g_c3a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%' or v_t = 'sem erro, 0 linha(s)';
  v_out := v_out || format('%s | M04a | MA | aceitar pela C3 (pendente -> ativa) | esperado: recusado / 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    update public.consent_grants set status = 'retirada' where id = g_c1a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%' or v_t = 'sem erro, 0 linha(s)';
  v_out := v_out || format('%s | M04b | MA | retirar a concessão de C1 | esperado: recusado / 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    update public.consent_grants set status = 'pendente' where id = g_c5a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%' or v_t = 'sem erro, 0 linha(s)';
  v_out := v_out || format('%s | M04c | MA | C5 recusada -> pendente (UPDATE) | esperado: recusado / 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
      values (v_c5, v_a, 'pendente', v_ver, v_ma);
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M04d | MA | C5 recusada: novo pedido pendente (INSERT) | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
      values (v_c4, v_a, 'ativa', v_ver, v_ma);
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M04e | MA | criar concessão já ATIVA (C4) | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
      values (v_c1, v_b, 'pendente', v_ver, v_ma);
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M04f | MA | criar pedido para o escritório B | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    delete from public.consent_grants where id = g_c1a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%' or v_t = 'sem erro, 0 linha(s)';
  v_out := v_out || format('%s | M04g | MA | apagar concessão de C1 | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    insert into public.client_office_notes (client_id, office_id, notes) values (v_c3, v_a, 'x');
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M04h | MA | escrever notas de C3 (pendente) | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    update public.profiles set full_name = 'x' where id = v_c1;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%' or v_t = 'sem erro, 0 linha(s)';
  v_out := v_out || format('%s | M04i | MA | alterar o nome de C1 | esperado: recusado / 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    insert into public.office_members (user_id, office_id) values (v_ma, v_b);
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M04j | MA | juntar-se ao escritório B | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- M05 alterar ou apagar auditoria
  begin
    update public.consent_audit set action = 'declined' where office_id = v_a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M05a | MA | UPDATE na auditoria | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    delete from public.consent_audit where office_id = v_a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M05b | MA | DELETE na auditoria | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    insert into public.consent_audit (grant_id, client_id, office_id, action, consent_version)
      values (g_c3a, v_c3, v_a, 'accepted', v_ver);
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M05c | MA | INSERT direto na auditoria (forjar aceitação) | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    truncate public.consent_audit;
    v_t := 'sem erro, truncada';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | M05d | MA | TRUNCATE na auditoria | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- RISCO: a auditoria do escritório mostra o id de C4 (retirada) ao mediador
  select count(*) into v_n from public.consent_audit where client_id = v_c4;
  v_out := v_out || format('%s | X01 | MA | auditoria de C4 (retirada) visível ao escritório | esperado (ideal): 0 | obtido: %s linha(s) com o id de C4',
                           case when v_n = 0 then 'PASS' else 'RISCO' end, v_n);

  reset role;

  -- ===========================================================================
  -- MB (mediador do escritório B)
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_mb, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_mb::text, true);
  set local role authenticated;

  v_ok := auth.uid() = v_mb and public.my_role() = 'mediador' and public.my_office_id() = v_b;
  v_out := v_out || format('%s | S2 | MB | simulação de sessão | esperado: uid=MB my_role=mediador | obtido: uid=%s my_role=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_lbl ->> auth.uid()::text, public.my_role());

  select format('perfis=%s grants=%s audit=%s notes=%s lista=%s',
           (select count(*) from public.profiles where id in (v_c1, v_c3, v_c4, v_c5)),
           (select count(*) from public.consent_grants where client_id in (v_c1, v_c3, v_c4, v_c5)),
           (select count(*) from public.consent_audit where client_id in (v_c1, v_c3, v_c4, v_c5)),
           (select count(*) from public.client_office_notes where client_id in (v_c1, v_c3, v_c4, v_c5)),
           (select count(*) from public.list_office_clients(200, 0) l where l.client_id in (v_c1, v_c3, v_c4, v_c5)))
    into v_t;
  v_ok := v_t = 'perfis=0 grants=0 audit=0 notes=0 lista=0';
  v_out := v_out || format('%s | B01 | MB | ler C1, C3, C4, C5 | esperado: tudo 0 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select coalesce(string_agg(x.lbl, ',' order by x.lbl), '(vazio)') into v_t
  from (select coalesce(v_lbl ->> l.client_id::text, 'OUTRO') || ':' || l.status::text as lbl
        from public.list_office_clients(200, 0) l) x;
  v_ok := v_t = 'C2:ativa';
  v_out := v_out || format('%s | B02 | MB | listar clientes de B | esperado: C2:ativa | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select format('grants_A=%s notes_C2_A=%s office_A=%s',
           (select count(*) from public.consent_grants where office_id = v_a),
           (select count(*) from public.client_office_notes where office_id = v_a),
           (select count(*) from public.offices where id = v_a))
    into v_t;
  v_ok := v_t = 'grants_A=0 notes_C2_A=0 office_A=0';
  v_out := v_out || format('%s | B03 | MB | ler concessões, notas e escritório de A (incl. C2 com A) | esperado: tudo 0 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- RISCO: as funções auxiliares SECURITY DEFINER respondem a qualquer autenticado
  begin
    v_t := format('has_active_grant(C1,A)=%s is_client(C1)=%s has_declined_grant(C5,A)=%s',
                  public.has_active_grant(v_c1, v_a), public.is_client(v_c1), public.has_declined_grant(v_c5, v_a));
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_out := v_out || format('%s | X02 | MB | perguntar por RPC se C1 tem concessão ativa com A | esperado (ideal): recusado | obtido: %s',
                           case when v_t like 'recusado%' then 'PASS' else 'RISCO' end, v_t);

  reset role;

  -- ===========================================================================
  -- Clientes
  -- ===========================================================================
  -- C2
  perform set_config('request.jwt.claims', json_build_object('sub', v_c2, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c2::text, true);
  set local role authenticated;

  v_ok := auth.uid() = v_c2 and public.my_role() = 'cliente';
  v_out := v_out || format('%s | S3 | C2 | simulação de sessão | esperado: uid=C2 my_role=cliente | obtido: uid=%s my_role=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_lbl ->> auth.uid()::text, public.my_role());

  select coalesce(string_agg(x.lbl, ',' order by x.lbl), '(vazio)') into v_t
  from (select coalesce(v_lbl ->> g.client_id::text, 'OUTRO') || '/' || coalesce(v_lbl ->> g.office_id::text, 'OUTRO') as lbl
        from public.consent_grants g) x;
  select count(*) into v_n from public.consent_grants g where g.client_id <> v_c2;
  v_ok := v_t = 'C2/A,C2/B' and v_n = 0;
  v_out := v_out || format('%s | K01 | C2 | ler concessões | esperado: C2/A,C2/B e nenhuma de outro cliente | obtido: %s (de outros: %s)',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t, v_n);

  select count(*) into v_n from public.my_consents();
  select count(*) into v_n2 from public.consent_audit where client_id <> v_c2;
  v_ok := v_n = 2 and v_n2 = 0;
  v_out := v_out || format('%s | K02 | C2 | my_consents() e auditoria de outros | esperado: 2 e 0 | obtido: %s e %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);

  select coalesce(string_agg(x.lbl, ',' order by x.lbl), '(vazio)') into v_t
  from (select coalesce(v_lbl ->> p.id::text, 'OUTRO') as lbl
        from public.profiles p where p.id in (v_ma, v_mb, v_c1, v_c2, v_c3, v_c4, v_c5, v_adm)) x;
  v_ok := v_t = 'C2';
  v_out := v_out || format('%s | K03 | C2 | ler perfis (mediadores, outros clientes, admin) | esperado: só C2 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select count(*) into v_n from public.offices where id = v_b;
  v_ok := v_n = 1;
  v_out := v_out || format('%s | K04 | C2 | ler escritório B (tem concessão) | esperado: 1 (só nome) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);
  reset role;

  -- C1
  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c1::text, true);
  set local role authenticated;

  v_ok := auth.uid() = v_c1 and public.my_role() = 'cliente';
  v_out := v_out || format('%s | S4 | C1 | simulação de sessão | esperado: uid=C1 my_role=cliente | obtido: uid=%s my_role=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_lbl ->> auth.uid()::text, public.my_role());

  select count(*) into v_n from public.offices where id = v_b;
  select count(*) into v_n2 from public.offices where id = v_a;
  v_ok := v_n = 0 and v_n2 = 1;
  v_out := v_out || format('%s | K05 | C1 | ler escritório B (sem concessão) / A (com) | esperado: 0 / 1 | obtido: %s / %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);

  begin
    update public.consent_grants set status = 'retirada' where id = g_c2a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%' or v_t = 'sem erro, 0 linha(s)';
  v_out := v_out || format('%s | K06 | C1 | retirar a concessão de C2 com A | esperado: recusado / 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    update public.consent_audit set action = 'declined' where client_id = v_c1;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | K07a | C1 | UPDATE na sua auditoria | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    delete from public.consent_audit where client_id = v_c1;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | K07b | C1 | DELETE na sua auditoria | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    insert into public.consent_audit (grant_id, client_id, office_id, action, consent_version)
      values (g_c1a, v_c1, v_a, 'withdrawn', v_ver);
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | K07c | C1 | INSERT direto na auditoria | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
      values (v_c1, v_b, 'ativa', v_ver, v_c1);
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | K08 | C1 | criar concessão ativa com B por conta própria | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    perform public.reaccept_grant(v_b, v_ver);
    v_t := 'sem erro, criada';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | K09 | C1 | reaccept_grant com B (nunca teve concessão) | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    update public.profiles set role = 'admin' where id = v_c1;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%' or v_t = 'sem erro, 0 linha(s)';
  v_out := v_out || format('%s | K10 | C1 | promover-se a admin (UPDATE profiles.role) | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    update public.consent_grants set office_id = v_b where id = g_c1a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | K11 | C1 | mudar o escritório da sua concessão | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- C5 (recusada é final, também para o próprio cliente)
  perform set_config('request.jwt.claims', json_build_object('sub', v_c5, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c5::text, true);
  set local role authenticated;
  begin
    update public.consent_grants set status = 'ativa' where id = g_c5a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | K12 | C5 | recusada -> ativa pelo próprio cliente | esperado: recusado (transição) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- ===========================================================================
  -- Admin
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_adm::text, true);
  set local role authenticated;

  v_ok := auth.uid() = v_adm and public.my_role() = 'admin';
  v_out := v_out || format('%s | S5 | ADM | simulação de sessão | esperado: uid=ADM my_role=admin | obtido: uid=%s my_role=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_lbl ->> auth.uid()::text, public.my_role());

  select format('perfis_outros=%s grants=%s audit=%s notes=%s lista=%s my_consents=%s',
           (select count(*) from public.profiles where id <> v_adm),
           (select count(*) from public.consent_grants),
           (select count(*) from public.consent_audit),
           (select count(*) from public.client_office_notes),
           (select count(*) from public.list_office_clients(200, 0)),
           (select count(*) from public.my_consents()))
    into v_t;
  v_ok := v_t = 'perfis_outros=0 grants=0 audit=0 notes=0 lista=0 my_consents=0';
  v_out := v_out || format('%s | D01 | ADM | ler nomes/emails, concessões, auditoria, notas | esperado: tudo 0 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- (contagens globais: incluem os dados reais, por isso só se exige o mínimo de teste)
  select count(*), coalesce(bool_and(c.offices >= 2 and c.mediators >= 2 and c.clients >= 5), false)
    into v_n, v_ok
  from public.admin_counts() c;
  v_ok := v_ok and v_n = 1;
  v_t := format('linhas=%s, contagens >= 2/2/5: %s', v_n, case when v_ok then 'sim' else 'não' end);
  v_out := v_out || format('%s | D02 | ADM | 3 contagens | esperado: 1 linha com as 3 contagens | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    update public.consent_grants set status = 'retirada' where id = g_c1a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%' or v_t = 'sem erro, 0 linha(s)';
  v_out := v_out || format('%s | D03 | ADM | alterar uma concessão | esperado: recusado / 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    update public.consent_audit set action = 'declined' where office_id = v_a;
    get diagnostics v_n = row_count;
    v_t := format('sem erro, %s linha(s)', v_n);
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | D04 | ADM | alterar a auditoria | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- US 2: um mediador não pertence a 2 escritórios
  begin
    insert into public.office_members (user_id, office_id) values (v_ma, v_b);
    v_t := 'sem erro, inserida';
  exception when others then v_t := 'recusado (' || sqlstate || ')';
  end;
  v_ok := v_t like 'recusado%';
  v_out := v_out || format('%s | D05 | ADM | pôr MA também no escritório B | esperado: recusado (23505) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- ===========================================================================
  -- Anónimo
  -- ===========================================================================
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
  set local role anon;

  v_t := '';
  begin perform count(*) from public.profiles;            v_t := v_t || 'profiles:leu ';  exception when others then v_t := v_t || 'profiles:' || sqlstate || ' '; end;
  begin perform count(*) from public.offices;             v_t := v_t || 'offices:leu ';   exception when others then v_t := v_t || 'offices:' || sqlstate || ' '; end;
  begin perform count(*) from public.office_members;      v_t := v_t || 'members:leu ';   exception when others then v_t := v_t || 'members:' || sqlstate || ' '; end;
  begin perform count(*) from public.consent_grants;      v_t := v_t || 'grants:leu ';    exception when others then v_t := v_t || 'grants:' || sqlstate || ' '; end;
  begin perform count(*) from public.consent_audit;       v_t := v_t || 'audit:leu ';     exception when others then v_t := v_t || 'audit:' || sqlstate || ' '; end;
  begin perform count(*) from public.consent_texts;       v_t := v_t || 'texts:leu ';     exception when others then v_t := v_t || 'texts:' || sqlstate || ' '; end;
  begin perform count(*) from public.client_office_notes; v_t := v_t || 'notes:leu ';     exception when others then v_t := v_t || 'notes:' || sqlstate || ' '; end;
  begin perform count(*) from public.send_throttle;       v_t := v_t || 'throttle:leu ';  exception when others then v_t := v_t || 'throttle:' || sqlstate || ' '; end;
  v_ok := v_t not like '%:leu%';
  v_out := v_out || format('%s | N01 | anónimo | ler as 8 tabelas | esperado: recusado em todas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, trim(v_t));

  v_t := '';
  begin perform * from public.list_office_clients(10, 0); v_t := v_t || 'list:correu ';    exception when others then v_t := v_t || 'list:' || sqlstate || ' '; end;
  begin perform * from public.my_consents();              v_t := v_t || 'consents:correu '; exception when others then v_t := v_t || 'consents:' || sqlstate || ' '; end;
  begin perform * from public.admin_counts();             v_t := v_t || 'counts:correu ';  exception when others then v_t := v_t || 'counts:' || sqlstate || ' '; end;
  begin perform public.has_active_grant(v_c1, v_a);       v_t := v_t || 'has_active:correu '; exception when others then v_t := v_t || 'has_active:' || sqlstate || ' '; end;
  begin perform public.reaccept_grant(v_a, v_ver);        v_t := v_t || 'reaccept:correu '; exception when others then v_t := v_t || 'reaccept:' || sqlstate || ' '; end;
  begin perform public.claim_send_slot(repeat('a', 64), 60); v_t := v_t || 'claim:correu '; exception when others then v_t := v_t || 'claim:' || sqlstate || ' '; end;
  v_ok := v_t not like '%:correu%';
  v_out := v_out || format('%s | N02 | anónimo | chamar as funções (RPC) | esperado: recusado em todas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, trim(v_t));

  v_t := '';
  begin insert into public.offices (name) values ('x');   v_t := v_t || 'offices:escreveu '; exception when others then v_t := v_t || 'offices:' || sqlstate || ' '; end;
  begin update public.consent_grants set status = 'retirada' where id = g_c1a; v_t := v_t || 'grants:correu '; exception when others then v_t := v_t || 'grants:' || sqlstate || ' '; end;
  begin delete from public.consent_audit;                  v_t := v_t || 'audit:correu '; exception when others then v_t := v_t || 'audit:' || sqlstate || ' '; end;
  v_ok := v_t not like '%:escreveu%' and v_t not like '%:correu%';
  v_out := v_out || format('%s | N03 | anónimo | escrever (escritório, concessão, auditoria) | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, trim(v_t));
  reset role;

  -- authenticated também não chega ao limite de envios (só service_role)
  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c1::text, true);
  set local role authenticated;
  v_t := '';
  begin perform count(*) from public.send_throttle;          v_t := v_t || 'ler:correu ';  exception when others then v_t := v_t || 'ler:' || sqlstate || ' '; end;
  begin perform public.claim_send_slot(repeat('b', 64), 60); v_t := v_t || 'claim:correu '; exception when others then v_t := v_t || 'claim:' || sqlstate || ' '; end;
  v_ok := v_t not like '%:correu%';
  v_out := v_out || format('%s | N04 | C1 | send_throttle e claim_send_slot | esperado: recusado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, trim(v_t));
  reset role;

  -- ===========================================================================
  -- Fluxos: aceitar, retirar, voltar a aceitar (US 4, US 5)
  -- ===========================================================================
  -- F01 C3 aceita
  perform set_config('request.jwt.claims', json_build_object('sub', v_c3, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c3::text, true);
  set local role authenticated;
  begin
    update public.consent_grants set status = 'ativa', consent_version = v_ver
      where id = g_c3a and status = 'pendente';
    get diagnostics v_n = row_count;
    v_t := format('%s linha(s)', v_n);
  exception when others then v_t := 'erro (' || sqlstate || ')';
  end;
  v_ok := v_t = '1 linha(s)';
  v_out := v_out || format('%s | F01 | C3 | aceitar o seu pedido | esperado: 1 linha | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- F02 C1 retira
  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c1::text, true);
  set local role authenticated;
  begin
    update public.consent_grants set status = 'retirada' where id = g_c1a and status = 'ativa';
    get diagnostics v_n = row_count;
    v_t := format('%s linha(s)', v_n);
  exception when others then v_t := 'erro (' || sqlstate || ')';
  end;
  v_ok := v_t = '1 linha(s)';
  v_out := v_out || format('%s | F02 | C1 | retirar acesso a A | esperado: 1 linha | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- F03 MA logo a seguir: C1 desaparece (perfil, notas, lista, concessão); C3 aparece completo
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;
  select format('perfil=%s notas=%s lista=%s grants=%s',
           (select count(*) from public.profiles where id = v_c1),
           (select count(*) from public.client_office_notes where client_id = v_c1),
           (select count(*) from public.list_office_clients(200, 0) l where l.client_id = v_c1),
           (select count(*) from public.consent_grants where client_id = v_c1))
    into v_t;
  v_ok := v_t = 'perfil=0 notas=0 lista=0 grants=0';
  v_out := v_out || format('%s | F03 | MA | C1 depois de retirar (pedido seguinte) | esperado: tudo 0, incluindo as notas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select count(*) into v_n from public.profiles where id = v_c3;
  v_ok := v_n = 1;
  v_out := v_out || format('%s | F04 | MA | C3 depois de aceitar | esperado: perfil completo (1) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);

  -- F05 novo pedido para C4 (retirada): o caminho de "voltar a dar acesso" do design
  begin
    insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
      values (v_c4, v_a, 'pendente', v_ver, v_ma) returning id into g_c4a2;
    v_t := 'criado';
  exception when others then v_t := 'erro (' || sqlstate || ')';
  end;
  v_ok := v_t = 'criado';
  v_out := v_out || format('%s | F05 | MA | novo pedido pendente para C4 (retirou antes) | esperado: criado | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select count(*) into v_n from public.client_office_notes where client_id = v_c4;
  v_ok := v_n = 0;
  v_out := v_out || format('%s | F06 | MA | notas de C4 com pedido só pendente | esperado: 0 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);
  reset role;

  -- F07 C1 volta a aceitar (reaccept_grant) e C4 aceita o novo pedido
  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c1::text, true);
  set local role authenticated;
  begin
    g_c1a2 := public.reaccept_grant(v_a, v_ver);
    v_t := case when g_c1a2 is not null and g_c1a2 <> g_c1a then 'nova concessão' else 'mesma ou nula' end;
  exception when others then v_t := 'erro (' || sqlstate || ')';
  end;
  v_ok := v_t = 'nova concessão';
  v_out := v_out || format('%s | F07 | C1 | voltar a aceitar A (reaccept_grant) | esperado: nova concessão | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  if g_c4a2 is not null then
    perform set_config('request.jwt.claims', json_build_object('sub', v_c4, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', v_c4::text, true);
    set local role authenticated;
    begin
      update public.consent_grants set status = 'ativa', consent_version = v_ver
        where id = g_c4a2 and status = 'pendente';
      get diagnostics v_n = row_count;
      v_t := format('%s linha(s)', v_n);
    exception when others then v_t := 'erro (' || sqlstate || ')';
    end;
    reset role;
  else
    v_t := 'sem pedido (F05 falhou)';
  end if;
  v_ok := v_t = '1 linha(s)';
  v_out := v_out || format('%s | F08 | C4 | aceitar o novo pedido | esperado: 1 linha | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;
  select format('C1 perfil=%s notas=%s | C4 perfil=%s notas=%s',
           (select count(*) from public.profiles where id = v_c1),
           (select count(*) from public.client_office_notes where client_id = v_c1),
           (select count(*) from public.profiles where id = v_c4),
           (select count(*) from public.client_office_notes where client_id = v_c4))
    into v_t;
  v_ok := v_t = 'C1 perfil=1 notas=1 | C4 perfil=1 notas=1';
  v_out := v_out || format('%s | F09 | MA | os dados reaparecem com a nova concessão ativa | esperado: C1 e C4 com perfil e notas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- ===========================================================================
  -- Estado final e auditoria (como postgres)
  -- ===========================================================================
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);

  select format('C2/A=%s C3/A=%s C5/A=%s C1/A antiga=%s',
           (select status from public.consent_grants where id = g_c2a),
           (select status from public.consent_grants where id = g_c3a),
           (select status from public.consent_grants where id = g_c5a),
           (select status from public.consent_grants where id = g_c1a))
    into v_t;
  v_ok := v_t = 'C2/A=ativa C3/A=ativa C5/A=recusada C1/A antiga=retirada';
  v_out := v_out || format('%s | E01 | postgres | estados finais (nada mudou por quem não podia) | esperado: C2/A=ativa C3/A=ativa C5/A=recusada C1/A antiga=retirada | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select count(*) into v_n from public.consent_grants g
  where g.office_id in (v_a, v_b)
    and not exists (select 1 from public.consent_audit a where a.grant_id = g.id and a.action = 'created');
  select count(*) into v_n2 from public.consent_grants where office_id in (v_a, v_b);
  v_ok := v_n = 0 and v_n2 = 8;
  v_out := v_out || format('%s | E02 | postgres | 100%% das concessões criadas têm registo "created" | esperado: 0 sem registo, 8 concessões (6 + reaceitação de C1 + novo pedido de C4) | obtido: %s sem registo, %s concessões',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);

  select format('C1 withdrawn=%s C3 accepted=%s C5 declined=%s C1 nova accepted=%s C4 nova accepted=%s',
           (select count(*) from public.consent_audit where grant_id = g_c1a and action = 'withdrawn' and actor_id = v_c1),
           (select count(*) from public.consent_audit where grant_id = g_c3a and action = 'accepted' and actor_id = v_c3 and consent_version = v_ver),
           (select count(*) from public.consent_audit where grant_id = g_c5a and action = 'declined'),
           (select count(*) from public.consent_audit where grant_id = g_c1a2 and action = 'accepted' and actor_id = v_c1),
           (select count(*) from public.consent_audit where grant_id = g_c4a2 and action = 'accepted' and actor_id = v_c4))
    into v_t;
  v_ok := v_t = 'C1 withdrawn=1 C3 accepted=1 C5 declined=1 C1 nova accepted=1 C4 nova accepted=1';
  v_out := v_out || format('%s | E03 | postgres | auditoria de aceitar/recusar/retirar com autor e versão | esperado: todos 1 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select count(*) into v_aud from public.consent_audit where office_id in (v_a, v_b);
  select count(*) into v_n from public.consent_audit where office_id in (v_a, v_b) and action = 'created' and actor_id = v_ma and grant_id = g_c4a2;
  v_ok := v_n = 1;
  v_out := v_out || format('%s | E04 | postgres | pedido criado pelo mediador fica com o mediador como autor | esperado: 1 | obtido: %s (total de registos de teste: %s)',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_aud);

  -- ---------------------------------------------------------------------------
  -- Relatório. O erro é propositado: obriga ao ROLLBACK de tudo o que se criou.
  -- ---------------------------------------------------------------------------
  select count(*) filter (where x like 'PASS%'), count(*) filter (where x like 'FAIL%'), count(*) filter (where x like 'RISCO%')
    into v_pass, v_fail, v_risk
  from unnest(v_out) as x;

  raise exception using
    errcode = 'P0001',
    message = format(E'QA 001: %s PASS, %s FAIL, %s RISCO (de %s linhas). Erro propositado: ROLLBACK feito, nada ficou gravado.\n%s',
                     v_pass, v_fail, v_risk, cardinality(v_out), array_to_string(v_out, E'\n'));
end
$qa$;
