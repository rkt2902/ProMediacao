-- =============================================================================
-- QA 002 Novo pedido: matriz de isolamento (US 6) + criação atómica, repetido,
-- retirada, notificações, auditoria e contagem do admin
-- Ficheiro : supabase/tests/002_isolation_matrix.sql
-- Data     : 2026-11-27
-- Spec     : docs/features/002-novo-pedido/02-spec.md (US 1, 2, 3, 4, 5, 6, 7)
-- Requer   : migrações 001 a 001e e 20261127120000_002_requests aplicadas.
--
-- COMO CORRER (SQL Editor do Supabase, ou API de gestão, como postgres)
--   1. Colar o ficheiro inteiro e correr. Não é preciso selecionar nada.
--   2. O script TERMINA SEMPRE EM ERRO, de propósito: o erro final é o relatório
--      ("QA 002: N PASS, N FAIL ...") seguido de uma linha por teste.
--      O erro faz o ROLLBACK de tudo: utilizadores, escritórios, concessões,
--      pedidos, notificações e auditoria de teste desaparecem.
--   3. Copiar o texto do erro para o 05-qa.md.
--
-- COMO SIMULA CADA PAPEL
--   Igual à 001: set local role authenticated|anon + request.jwt.claims (e
--   request.jwt.claim.sub) com o "sub" do utilizador de teste. Os testes S* confirmam
--   que a simulação funciona; se algum S* der FAIL, o resto não vale.
--
-- Dados de teste (novos, emails @example.invalid, nomes "qa002-..."):
--   escritórios A e B; MA (A), MB (B); C1 (ativa A), C2 (ativa A e B),
--   C3 (pendente A), C4 (ativa A, retira depois de ter um pedido), C5 (recusada A);
--   ADM; anónimo. "Já entrou" (last_sign_in_at): C1, C3, C4 sim; C2 nunca.
-- =============================================================================

do $qa$
declare
  v_tag  text := 'qa002-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
  v_ver  text;
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
  g_c1a  uuid;  g_c4a uuid;  g_c5a uuid;
  -- listas do catálogo (como a app as envia)
  j_auto   jsonb;  j_auto_ed jsonb;  j_vida jsonb;  j_saude jsonb;  j_pets jsonb;  j_vh jsonb;
  v_vida_item uuid;
  -- pedidos criados
  r_auto  uuid;  r_vida uuid;  r_auto2 uuid;  r_c2a uuid;  r_c2b uuid;  r_c4 uuid;
  v_batch1 uuid; v_batch2 uuid;
  n_c1 uuid;  n_c4 uuid;
  -- trabalho
  v_out  text[] := '{}';
  v_ok   boolean;
  v_t    text;
  v_det  text;
  v_n    bigint;
  v_n2   bigint;
  v_pass int; v_fail int;
begin
  -- ---------------------------------------------------------------------------
  -- 0. Preparação (como postgres)
  -- ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
  v_ver := public.current_consent_version();
  if v_ver is null then raise exception 'Preparação: consent_texts vazio'; end if;
  if (select count(*) from public.insurance_types where active) <> 13 then
    raise exception 'Preparação: o catálogo não tem 13 tipos ativos';
  end if;

  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_sso_user, is_anonymous,
                          last_sign_in_at)
  select u.id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
         v_tag || '-' || u.k || '@example.invalid', '', now(),
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, false,
         case when u.k in ('c1', 'c3', 'c4', 'ma', 'mb', 'adm') then now() end
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
    values (v_c2, v_a, 'ativa', v_ver, v_ma), (v_c2, v_b, 'ativa', v_ver, v_mb),
           (v_c3, v_a, 'pendente', v_ver, v_ma);
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c4, v_a, 'ativa', v_ver, v_ma) returning id into g_c4a;
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c5, v_a, 'pendente', v_ver, v_ma) returning id into g_c5a;
  update public.consent_grants set status = 'recusada' where id = g_c5a;

  select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position) into j_auto
    from public.insurance_type_items i where i.type_code = 'automovel' and i.active;
  -- Automóvel editado como no render: sem "Franquias (danos próprios)" + 1 item livre
  select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position)
         || jsonb_build_array(jsonb_build_object('kind', 'D', 'label', 'Fotografias do veículo (frente, traseira e lados)'))
    into j_auto_ed
    from public.insurance_type_items i where i.type_code = 'automovel' and i.active and i.label <> 'Franquias (danos próprios)';
  select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position) into j_vida
    from public.insurance_type_items i where i.type_code = 'vida' and i.active;
  select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position) into j_saude
    from public.insurance_type_items i where i.type_code = 'saude' and i.active;
  select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position) into j_pets
    from public.insurance_type_items i where i.type_code = 'pets' and i.active;
  select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position) into j_vh
    from public.insurance_type_items i where i.type_code = 'vida_habitacao' and i.active;
  select i.id into v_vida_item from public.insurance_type_items i where i.type_code = 'vida' and i.position = 1;

  -- ===========================================================================
  -- MA (escritório A): criação
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;

  v_ok := auth.uid() = v_ma and current_user = 'authenticated' and private.my_role() = 'mediador';
  v_out := v_out || format('%s | S1 | MA | simulação de sessão | esperado: uid=MA authenticated mediador | obtido: %s %s',
                           case when v_ok then 'PASS' else 'FAIL' end, current_user, private.my_role());

  -- R01 criar 2 pedidos para C1 (Automóvel editado + Vida), condições ativas, mensagem
  select count(*), count(distinct x.batch_id), min(x.batch_id::text)::uuid into v_n, v_n2, v_batch1
  from public.create_requests(v_c1,
         jsonb_build_array(jsonb_build_object('type_code', 'automovel', 'items', j_auto_ed),
                           jsonb_build_object('type_code', 'vida', 'items', j_vida)),
         true, '  Bom dia. Preciso destes elementos.  ') x;
  select q.id into r_auto from public.requests q where q.client_id = v_c1 and q.insurance_type_code = 'automovel';
  select q.id into r_vida from public.requests q where q.client_id = v_c1 and q.insurance_type_code = 'vida';
  v_ok := v_n = 2 and v_n2 = 1 and r_auto is not null and r_vida is not null;
  v_out := v_out || format('%s | R01 | MA | criar 2 pedidos para C1 (A, concessão ativa) | esperado: 2 linhas, 1 batch | obtido: %s linhas, %s batch',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);

  -- R02 estado dos pedidos criados
  select format('etapa=%s origem=%s cond=%s msg=%s editada=%s/%s itens=%s livre=%s copia=%s',
           (select string_agg(distinct q.stage::text, ',') from public.requests q where q.id in (r_auto, r_vida)),
           (select string_agg(distinct q.origin, ',') from public.requests q where q.id in (r_auto, r_vida)),
           (select bool_and(q.allow_policy_conditions) from public.requests q where q.id in (r_auto, r_vida)),
           (select q.message from public.requests q where q.id = r_auto),
           (select q.list_edited from public.requests q where q.id = r_auto),
           (select q.list_edited from public.requests q where q.id = r_vida),
           (select count(*) from public.request_items i where i.request_id = r_auto),
           (select count(*) from public.request_items i where i.request_id = r_auto and i.source = 'livre' and i.position = 6),
           (select count(*) from public.request_items i where i.request_id = r_vida and i.source = 'catalogo'))
    into v_t;
  v_ok := v_t = 'etapa=1 origem=mediador cond=t msg=Bom dia. Preciso destes elementos. editada=t/f itens=6 livre=1 copia=5';
  v_out := v_out || format('%s | R02 | MA | pedidos: etapa 1, origem mediador, cópia da lista editada | esperado: etapa=1 origem=mediador cond=true msg aparada editada=true/false itens=6 livre=1 copia=5 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- R03 C2 (ativa com A) e C4 (ainda ativa)
  select x.request_id into r_c2a from public.create_requests(v_c2,
    jsonb_build_array(jsonb_build_object('type_code', 'saude', 'items', j_saude)), false, null) x;
  select x.request_id into r_c4 from public.create_requests(v_c4,
    jsonb_build_array(jsonb_build_object('type_code', 'pets', 'items', j_pets)), false, '') x;
  v_ok := r_c2a is not null and r_c4 is not null;
  v_out := v_out || format('%s | R03 | MA | criar pedido para C2 (A) e C4 (antes de retirar) | esperado: permitido | obtido: C2=%s C4=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, r_c2a is not null, r_c4 is not null);

  -- R04 recusado para C3 (pendente), C5 (recusada), inexistente: mesma resposta
  v_t := '';
  declare v_c uuid; begin
    foreach v_c in array array[v_c3, v_c5, gen_random_uuid()] loop
      begin
        perform public.create_requests(v_c, jsonb_build_array(jsonb_build_object('type_code', 'vida', 'items', j_vida)), false, null);
        v_t := v_t || 'criado;';
      exception when others then v_t := v_t || sqlerrm || '/' || sqlstate || ';';
      end;
    end loop;
  end;
  v_ok := v_t = repeat('client_not_available/42501;', 3);
  v_out := v_out || format('%s | R04 | MA | criar para C3 (pendente), C5 (recusada), id inexistente | esperado: client_not_available x3 (não revela) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- R05 repetido sem confirmação: recusado, nada criado; com confirmação: criado
  select count(*) into v_n from public.requests q where q.client_id = v_c1;
  begin
    perform public.create_requests(v_c1, jsonb_build_array(
      jsonb_build_object('type_code', 'vida_habitacao', 'items', j_vh),
      jsonb_build_object('type_code', 'automovel', 'items', j_auto)), false, null);
    v_t := 'sem erro';
  exception when others then
    get stacked diagnostics v_det = pg_exception_detail;
    v_t := sqlerrm || '/' || sqlstate || ' detail=' || coalesce(v_det, '');
  end;
  select count(*) into v_n2 from public.requests q where q.client_id = v_c1;
  v_ok := v_t = 'repeated_request/P0001 detail=automovel' and v_n2 = v_n;
  v_out := v_out || format('%s | R05a | MA | repetido (Automóvel em curso) sem confirmar, com outro tipo novo | esperado: repeated_request detail=automovel e nada criado | obtido: %s; pedidos C1 %s -> %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t, v_n, v_n2);

  select x.request_id into r_auto2 from public.create_requests(v_c1, jsonb_build_array(
    jsonb_build_object('type_code', 'automovel', 'confirm_repeat', true, 'items', j_auto)), false, null) x;
  select count(*) into v_n2 from public.requests q where q.client_id = v_c1;
  v_ok := r_auto2 is not null and v_n2 = v_n + 1;
  v_out := v_out || format('%s | R05b | MA | repetido com confirm_repeat=true | esperado: criado (C1 passa a 3) | obtido: C1 %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n2);

  -- R06 atomicidade: 1 tipo válido + 1 com lista vazia => nada criado
  select count(*) into v_n from public.requests q where q.client_id = v_c1;
  begin
    perform public.create_requests(v_c1, jsonb_build_array(
      jsonb_build_object('type_code', 'vida_habitacao', 'items', j_vh),
      jsonb_build_object('type_code', 'doencas_graves', 'items', '[]'::jsonb)), false, null);
    v_t := 'sem erro';
  exception when others then
    get stacked diagnostics v_det = pg_exception_detail;
    v_t := sqlerrm || '/' || sqlstate || ' detail=' || coalesce(v_det, '');
  end;
  select count(*) into v_n2 from public.requests q where q.client_id = v_c1;
  v_ok := v_t = 'empty_list/22023 detail=doencas_graves' and v_n2 = v_n;
  v_out := v_out || format('%s | R06 | MA | criação atómica: 2.º tipo com lista vazia | esperado: empty_list e 0 criados | obtido: %s; C1 %s -> %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t, v_n, v_n2);

  -- R07 validações de entrada
  v_t := '';
  declare v_case jsonb; v_msg text; begin
    foreach v_case in array array[
      jsonb_build_array(jsonb_build_object('type_code', 'doencas_graves', 'items', jsonb_build_array(jsonb_build_object('kind', 'D', 'label', 'a <b>')))),
      jsonb_build_array(jsonb_build_object('type_code', 'doencas_graves', 'items', jsonb_build_array(jsonb_build_object('kind', 'X', 'label', 'ok')))),
      jsonb_build_array(jsonb_build_object('type_code', 'doencas_graves', 'items', jsonb_build_array(jsonb_build_object('kind', 'I', 'label', repeat('x', 201))))),
      jsonb_build_array(jsonb_build_object('type_code', 'doencas_graves', 'items', jsonb_build_array(jsonb_build_object('catalog_item_id', v_vida_item)))),
      jsonb_build_array(jsonb_build_object('type_code', 'vida', 'items', jsonb_build_array(jsonb_build_object('catalog_item_id', v_vida_item), jsonb_build_object('catalog_item_id', v_vida_item)))),
      jsonb_build_array(jsonb_build_object('type_code', 'nao_existe', 'items', j_vida)),
      jsonb_build_array(jsonb_build_object('type_code', 'pets', 'items', j_pets), jsonb_build_object('type_code', 'pets', 'items', j_pets)),
      jsonb_build_array(jsonb_build_object('type_code', 'pets', 'confirm_repeat', 'sim', 'items', j_pets)),
      '[]'::jsonb
    ] loop
      begin
        perform public.create_requests(v_c2, v_case, false, null);
        v_t := v_t || 'criado;';
      exception when others then v_t := v_t || sqlerrm || ';';
      end;
    end loop;
    begin
      perform public.create_requests(v_c2, jsonb_build_array(jsonb_build_object('type_code', 'pets', 'items', j_pets)), false, repeat('m', 501));
      v_t := v_t || 'criado;';
    exception when others then v_t := v_t || sqlerrm || ';';
    end;
  end;
  v_ok := v_t = 'invalid_item;invalid_item;invalid_item;invalid_item;invalid_item;invalid_input;invalid_input;invalid_input;invalid_input;message_too_long;';
  v_out := v_out || format('%s | R07 | MA | itens com < >, kind X, >200, item de outro tipo, item repetido, tipo inexistente, tipo repetido, confirm não booleano, 0 tipos, mensagem 501 | esperado: 5x invalid_item, 4x invalid_input, message_too_long | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- R08 escrita direta nas tabelas (alterar etapa, lista, apagar, destino B, proposta, catálogo, notificação)
  v_t := '';
  declare v_sql text; begin
    foreach v_sql in array array[
      format('update public.requests set stage = 2 where id = %L', r_auto),
      format('update public.request_items set label = %L where request_id = %L', 'x', r_auto),
      format('delete from public.requests where id = %L', r_auto),
      format('insert into public.request_items (request_id, position, kind, label, source) values (%L, 50, %L, %L, %L)', r_auto, 'D', 'x', 'livre'),
      format('insert into public.request_recipients (request_id, office_id) values (%L, %L)', r_auto, v_b),
      format('insert into public.requests (batch_id, client_id, insurance_type_code, type_name, author_id) values (gen_random_uuid(), %L, %L, %L, %L)', v_c1, 'vida', 'Vida', v_ma),
      format('insert into public.proposals (request_id, office_id) values (%L, %L)', r_auto, v_a),
      'update public.insurance_types set name = ''X'' where code = ''vida''',
      'insert into public.insurance_type_items (type_code, position, kind, label) values (''vida'', 99, ''D'', ''x'')',
      format('insert into public.notifications (recipient_id, kind, title) values (%L, %L, %L)', v_c1, 'pedido_criado', 'x'),
      format('insert into public.request_audit (request_id, client_id, office_id, insurance_type_code, action) values (%L, %L, %L, %L, %L)', r_auto, v_c1, v_a, 'vida', 'created')
    ] loop
      begin
        execute v_sql;
        get diagnostics v_n = row_count;
        v_t := v_t || format('ok(%s);', v_n);
      exception when others then v_t := v_t || sqlstate || ';';
      end;
    end loop;
  end;
  v_ok := v_t = repeat('42501;', 11);
  v_out := v_out || format('%s | R08 | MA | alterar etapa/lista, apagar, item, destino B, pedido direto, proposta, catálogo, notificação, auditoria | esperado: 11x recusado (42501) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- R09 catálogo legível
  select count(*) into v_n from public.get_insurance_catalog();
  select count(*) into v_n2 from public.insurance_type_items;
  v_ok := v_n = 13 and v_n2 >= 72;
  v_out := v_out || format('%s | R09 | MA | ler o catálogo | esperado: 13 tipos, >=72 itens | obtido: %s tipos, %s itens',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);

  reset role;

  -- ===========================================================================
  -- MB (escritório B)
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_mb, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_mb::text, true);
  set local role authenticated;

  select x.request_id into r_c2b from public.create_requests(v_c2,
    jsonb_build_array(jsonb_build_object('type_code', 'automovel', 'items', j_auto)), false, null) x;
  begin
    perform public.create_requests(v_c1, jsonb_build_array(jsonb_build_object('type_code', 'vida', 'items', j_vida)), false, null);
    v_t := 'criado';
  exception when others then v_t := sqlerrm;
  end;
  v_ok := r_c2b is not null and v_t = 'client_not_available';
  v_out := v_out || format('%s | B01 | MB | criar para C2 (ativa com B) / para C1 (só com A) | esperado: permitido / client_not_available | obtido: %s / %s',
                           case when v_ok then 'PASS' else 'FAIL' end, r_c2b is not null, v_t);

  select format('requests=%s items=%s recip=%s audit=%s get=%s ficha_c1=%s ficha_c2=%s resumo=%s',
           (select count(*) from public.requests where id in (r_auto, r_vida, r_c2a, r_c4)),
           (select count(*) from public.request_items where request_id in (r_auto, r_vida, r_c2a, r_c4)),
           (select count(*) from public.request_recipients where office_id = v_a),
           (select count(*) from public.request_audit where office_id = v_a),
           (select count(*) from public.get_request(r_c2a)),
           (select count(*) from public.list_client_requests(v_c1, 200, 0)),
           (select string_agg(l.type_code, ',') from public.list_client_requests(v_c2, 200, 0) l),
           (select string_agg(s.client_id::text, ',') from public.office_requests_summary(null) s))
    into v_t;
  v_ok := v_t = format('requests=0 items=0 recip=0 audit=0 get=0 ficha_c1=0 ficha_c2=automovel resumo=%s', v_c2);
  v_out := v_out || format('%s | B02 | MB | ler pedidos destinados a A (tabelas e RPCs) | esperado: 0 em tudo; ficha de C2 só o pedido de B | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, replace(v_t, v_c2::text, 'C2'));

  reset role;

  -- C4 retira a concessão com o escritório A (como o próprio cliente)
  perform set_config('request.jwt.claims', json_build_object('sub', v_c4, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c4::text, true);
  set local role authenticated;
  update public.consent_grants set status = 'retirada' where id = g_c4a;
  reset role;

  -- ===========================================================================
  -- MA: leituras
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;

  select count(*) into v_n from public.requests q where q.client_id in (v_c1, v_c2, v_c3, v_c4, v_c5);
  select count(*) into v_n2 from public.requests q where q.id in (r_auto, r_vida, r_auto2, r_c2a);
  v_ok := v_n = 4 and v_n2 = 4;
  v_out := v_out || format('%s | M01 | MA | ler pedidos de C1, C2 (destino A) | esperado: 4 (3 de C1 + 1 de C2), só de A | obtido: %s visíveis, %s dos de A',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);

  select format('c2b=%s c4=%s items_c4=%s audit_c4=%s get_c4=%s get_c2b=%s recipB=%s ficha_c2=%s ficha_c3=%s ficha_c4=%s ficha_c5=%s',
           (select count(*) from public.requests where id = r_c2b),
           (select count(*) from public.requests where client_id in (v_c3, v_c4, v_c5)),
           (select count(*) from public.request_items where request_id = r_c4),
           (select count(*) from public.request_audit where client_id = v_c4),
           (select count(*) from public.get_request(r_c4)),
           (select count(*) from public.get_request(r_c2b)),
           (select count(*) from public.request_recipients where office_id = v_b),
           (select count(*) from public.list_client_requests(v_c2, 200, 0)),
           (select count(*) from public.list_client_requests(v_c3, 200, 0)),
           (select count(*) from public.list_client_requests(v_c4, 200, 0)),
           (select count(*) from public.list_client_requests(v_c5, 200, 0)))
    into v_t;
  v_ok := v_t = 'c2b=0 c4=0 items_c4=0 audit_c4=0 get_c4=0 get_c2b=0 recipB=0 ficha_c2=1 ficha_c3=0 ficha_c4=0 ficha_c5=0';
  v_out := v_out || format('%s | M02 | MA | ler pedidos de C2 para B e de C3, C4 (retirada), C5 | esperado: 0 linhas (ficha de C2 só 1, o de A) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  begin
    perform public.create_requests(v_c4, jsonb_build_array(jsonb_build_object('type_code', 'vida', 'items', j_vida)), false, null);
    v_t := 'criado';
  exception when others then v_t := sqlerrm;
  end;
  v_ok := v_t = 'client_not_available';
  v_out := v_out || format('%s | M03 | MA | criar para C4 depois de retirar | esperado: client_not_available | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select format('resumo=%s total=%s tipos_c1=%s ficha_c1=%s/%s/%s autor=%s',
           (select string_agg(case s.client_id when v_c1 then 'C1' when v_c2 then 'C2' else 'OUTRO' end || ':' || s.open_count || ':' || s.max_open_stage,
                              ',' order by case s.client_id when v_c1 then 1 else 2 end)
              from public.office_requests_summary(array[v_c1, v_c2, v_c3, v_c4, v_c5]) s),
           public.office_open_request_count(),
           (select string_agg(t.type_code || ':' || t.open_count, ',' order by t.type_code) from public.client_open_types(v_c1) t),
           (select max(l.total_count) from public.list_client_requests(v_c1, 1, 0) l),
           (select max(l.open_count) from public.list_client_requests(v_c1, 1, 0) l),
           (select count(*) from public.list_client_requests(v_c1, 1, 0) l),
           (select bool_and(l.author_name = v_tag || ' MA') from public.list_client_requests(v_c1, 200, 0) l))
    into v_t;
  v_ok := v_t = 'resumo=C1:3:1,C2:1:1 total=4 tipos_c1=automovel:2,vida:1 ficha_c1=3/3/1 autor=t';
  v_out := v_out || format('%s | M04 | MA | resumo da lista Clientes, contagem, tipos em curso, ficha paginada | esperado: resumo=C1:3:1,C2:1:1 total=4 tipos_c1=automovel:2,vida:1 ficha_c1=3/3/1 autor=true | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select format('get=%s itens=%s retirado=%s escritorio=%s',
           count(*), max(jsonb_array_length(g.items)), bool_or(g.access_withdrawn), max(g.office_name) = v_tag || ' Escritório A')
    into v_t from public.get_request(r_auto) g;
  v_ok := v_t = 'get=1 itens=6 retirado=f escritorio=t';
  v_out := v_out || format('%s | M05 | MA | detalhe de um pedido seu (C1, A) | esperado: get=1 itens=6 retirado=false escritorio=true | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- Notificações de clientes: 0 / recusado
  select count(*) into v_n from public.list_my_notifications(200, 0);
  reset role;
  select n.id into n_c1 from public.notifications n where n.recipient_id = v_c1 order by n.created_at, n.id limit 1;
  select n.id into n_c4 from public.notifications n where n.recipient_id = v_c4 limit 1;
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;
  select count(*) into v_n2 from public.notifications;
  begin
    perform public.set_notification_read(n_c1, true);
    v_t := 'marcada';
  exception when others then v_t := sqlerrm;
  end;
  v_ok := v_n = 0 and v_n2 = 0 and v_t = 'not_found';
  v_out := v_out || format('%s | M06 | MA | ler notificações / marcar a de C1 como lida | esperado: 0 / 0 / not_found | obtido: %s / %s / %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2, v_t);

  select count(*) into v_n from public.admin_counts();
  v_ok := v_n = 0;
  v_out := v_out || format('%s | M07 | MA | contagens do admin | esperado: 0 linhas | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n);
  reset role;

  -- ===========================================================================
  -- C1
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c1::text, true);
  set local role authenticated;

  select format('lista=%s retirado=%s em_curso=%s tabela=%s itens=%s recip=%s audit=%s get_auto=%s get_c2=%s doc/dado=%s/%s',
           (select count(*) from public.list_my_requests(200, 0)),
           (select bool_or(l.access_withdrawn) from public.list_my_requests(200, 0) l),
           (select max(l.open_count) from public.list_my_requests(200, 0) l),
           (select count(*) from public.requests),
           (select count(distinct request_id) from public.request_items),
           (select count(*) from public.request_recipients),
           (select count(*) from public.request_audit),
           (select count(*) from public.get_request(r_auto)),
           (select count(*) from public.get_request(r_c2a)),
           (select l.document_count from public.list_my_requests(200, 0) l where l.request_id = r_auto),
           (select l.data_count from public.list_my_requests(200, 0) l where l.request_id = r_auto))
    into v_t;
  v_ok := v_t = 'lista=3 retirado=f em_curso=3 tabela=3 itens=3 recip=3 audit=3 get_auto=1 get_c2=0 doc/dado=4/2';
  v_out := v_out || format('%s | C01 | C1 | ler os seus pedidos (RPC e tabelas), nunca os de C2 | esperado: 3 em tudo, get de C2 = 0, 4 documentos e 2 dados | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  v_t := '';
  begin
    perform public.create_requests(v_c1, jsonb_build_array(jsonb_build_object('type_code', 'vida', 'items', j_vida)), false, null);
    v_t := 'criado;';
  exception when others then v_t := sqlerrm || ';';
  end;
  declare v_sql text; begin
    foreach v_sql in array array[
      format('update public.requests set stage = 2 where id = %L', r_auto),
      format('delete from public.requests where id = %L', r_auto),
      format('insert into public.requests (batch_id, client_id, insurance_type_code, type_name) values (gen_random_uuid(), %L, %L, %L)', v_c1, 'vida', 'Vida'),
      format('update public.notifications set read_at = now() where id = %L', n_c1),
      format('delete from public.notifications where id = %L', n_c1),
      format('insert into public.notifications (recipient_id, kind, title) values (%L, %L, %L)', v_c1, 'pedido_criado', 'x')
    ] loop
      begin
        execute v_sql;
        get diagnostics v_n = row_count;
        v_t := v_t || format('ok(%s);', v_n);
      exception when others then v_t := v_t || sqlstate || ';';
      end;
    end loop;
  end;
  v_ok := v_t = 'not_authorized;' || repeat('42501;', 6);
  v_out := v_out || format('%s | C02 | C1 | criar/alterar/apagar pedido; criar/alterar/apagar notificação direto | esperado: not_authorized + 6x 42501 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select format('lista=%s por_ler=%s contador=%s titulo=%s corpo=%s objeto=%s',
           (select count(*) from public.list_my_notifications(200, 0)),
           (select max(l.unread_count) from public.list_my_notifications(200, 0) l),
           public.my_unread_notification_count(),
           (select string_agg(distinct l.title, ',') from public.list_my_notifications(200, 0) l where l.object_id in (r_auto, r_auto2)),
           (select bool_and(l.body = v_tag || ' Escritório A') from public.list_my_notifications(200, 0) l),
           (select bool_and(l.object_type = 'request' and l.kind = 'pedido_criado') from public.list_my_notifications(200, 0) l))
    into v_t;
  v_ok := v_t = 'lista=3 por_ler=3 contador=3 titulo=Novo pedido: Automóvel corpo=t objeto=t';
  v_out := v_out || format('%s | C03 | C1 | ler notificações (1 por pedido; já entrou) | esperado: lista=3 por_ler=3 contador=3, texto genérico | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select format('%s', (select s.is_read from public.set_notification_read(n_c1, true) s)) into v_t;
  v_t := v_t || '/' || public.my_unread_notification_count();
  v_t := v_t || '/' || (select s.is_read from public.set_notification_read(n_c1, false) s)::text;
  v_t := v_t || '/' || public.my_unread_notification_count();
  begin
    perform public.set_notification_read(n_c4, true);
    v_t := v_t || '/marcada';
  exception when others then v_t := v_t || '/' || sqlerrm;
  end;
  v_ok := v_t = 't/2/false/3/not_found';
  v_out := v_out || format('%s | C04 | C1 | marcar sua como lida e não lida / marcar a de C4 | esperado: true/2/false/3/not_found | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- ===========================================================================
  -- C2 (A e B; nunca entrou)
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_c2, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c2::text, true);
  set local role authenticated;
  select format('lista=%s escritorios=%s tabela=%s de_c1=%s notif=%s',
           (select count(*) from public.list_my_requests(200, 0)),
           (select count(distinct l.office_id) from public.list_my_requests(200, 0) l),
           (select count(*) from public.requests),
           (select count(*) from public.requests where client_id = v_c1),
           (select count(*) from public.notifications))
    into v_t;
  v_ok := v_t = 'lista=2 escritorios=2 tabela=2 de_c1=0 notif=0';
  v_out := v_out || format('%s | C05 | C2 | ler pedidos (A e B), nunca os de C1; nunca entrou = sem notificações | esperado: lista=2 escritorios=2 tabela=2 de_c1=0 notif=0 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- ===========================================================================
  -- C4 (retirou o acesso a A)
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_c4, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c4::text, true);
  set local role authenticated;
  select format('lista=%s retirado=%s data=%s em_curso=%s get=%s get_retirado=%s notif=%s',
           (select count(*) from public.list_my_requests(200, 0)),
           (select bool_and(l.access_withdrawn) from public.list_my_requests(200, 0) l),
           (select bool_and(l.access_withdrawn_at is not null) from public.list_my_requests(200, 0) l),
           (select max(l.open_count) from public.list_my_requests(200, 0) l),
           (select count(*) from public.get_request(r_c4)),
           (select bool_and(g.access_withdrawn) from public.get_request(r_c4) g),
           (select count(*) from public.list_my_notifications(200, 0)))
    into v_t;
  v_ok := v_t = 'lista=1 retirado=t data=t em_curso=0 get=1 get_retirado=t notif=1';
  v_out := v_out || format('%s | C06 | C4 | ver o seu pedido com "Acesso retirado" | esperado: lista=1 retirado=true data=true em_curso=0 get=1 get_retirado=true notif=1 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- C4 volta a aceitar: o pedido reaparece ao escritório com a etapa que tinha
  perform public.reaccept_grant(v_a, v_ver);
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;
  select format('ficha=%s etapa=%s get=%s', count(*), max(l.stage), (select count(*) from public.get_request(r_c4)))
    into v_t from public.list_client_requests(v_c4, 200, 0) l;
  v_ok := v_t = 'ficha=1 etapa=1 get=1';
  v_out := v_out || format('%s | C07 | MA | C4 volta a aceitar: pedidos reaparecem | esperado: ficha=1 etapa=1 get=1 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- ===========================================================================
  -- C1 retira: MA lê 0 pedidos de C1 no pedido seguinte; C1 continua a vê-los
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c1::text, true);
  set local role authenticated;
  update public.consent_grants set status = 'retirada' where id = g_c1a;
  select format('lista=%s retirado=%s', count(*), bool_and(l.access_withdrawn)) into v_t from public.list_my_requests(200, 0) l;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;
  select v_t || format(' | MA: tabela=%s ficha=%s itens=%s audit=%s resumo=%s total=%s',
           (select count(*) from public.requests where client_id = v_c1),
           (select count(*) from public.list_client_requests(v_c1, 200, 0)),
           (select count(*) from public.request_items where request_id in (r_auto, r_vida, r_auto2)),
           (select count(*) from public.request_audit where client_id = v_c1),
           (select count(*) from public.office_requests_summary(array[v_c1])),
           public.office_open_request_count())
    into v_t;
  v_ok := v_t = 'lista=3 retirado=t | MA: tabela=0 ficha=0 itens=0 audit=0 resumo=0 total=2';
  v_out := v_out || format('%s | C08 | C1+MA | C1 retira: MA 0 pedidos de imediato; C1 vê os 3 com "Acesso retirado" | esperado: lista=3 retirado=true | MA: tudo 0, total=2 (C2 e C4) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);
  reset role;

  -- ===========================================================================
  -- Admin
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_adm, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_adm::text, true);
  set local role authenticated;
  select format('requests=%s items=%s recip=%s audit=%s notif=%s get=%s ficha=%s resumo=%s minhas=%s',
           (select count(*) from public.requests),
           (select count(*) from public.request_items),
           (select count(*) from public.request_recipients),
           (select count(*) from public.request_audit),
           (select count(*) from public.notifications),
           (select count(*) from public.get_request(r_auto)),
           (select count(*) from public.list_client_requests(v_c2, 200, 0)),
           (select count(*) from public.office_requests_summary(null)),
           (select count(*) from public.list_my_requests(200, 0)))
    into v_t;
  begin
    perform 1 from public.proposals;
    v_t := v_t || ' proposals=lida';
  exception when others then v_t := v_t || ' proposals=' || sqlstate;
  end;
  begin
    perform public.create_requests(v_c2, jsonb_build_array(jsonb_build_object('type_code', 'vida', 'items', j_vida)), false, null);
    v_t := v_t || ' criar=criado';
  exception when others then v_t := v_t || ' criar=' || sqlerrm;
  end;
  v_ok := v_t = 'requests=0 items=0 recip=0 audit=0 notif=0 get=0 ficha=0 resumo=0 minhas=0 proposals=42501 criar=not_authorized';
  v_out := v_out || format('%s | A01 | ADM | ler pedidos, itens, destinatários, auditoria, notificações, propostas; criar | esperado: 0 em tudo, proposals recusado, not_authorized | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  select count(*), max(c.requests) into v_n, v_n2 from public.admin_counts() c;
  reset role;
  v_ok := v_n = 1 and v_n2 = (select count(*) from public.requests) and v_n2 >= 6;
  v_out := v_out || format('%s | A02 | ADM | contagens com a 4.ª (pedidos) | esperado: 1 linha, requests = total real (>= 6) | obtido: %s linha(s), requests=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);

  -- ===========================================================================
  -- Anónimo
  -- ===========================================================================
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
  set local role anon;
  v_t := '';
  declare v_sql text; begin
    foreach v_sql in array array[
      'select count(*) from public.requests',
      'select count(*) from public.request_items',
      'select count(*) from public.request_recipients',
      'select count(*) from public.request_audit',
      'select count(*) from public.notifications',
      'select count(*) from public.proposals',
      'select count(*) from public.insurance_types',
      'select count(*) from public.get_insurance_catalog()',
      format('select count(*) from public.get_request(%L)', r_auto),
      'select count(*) from public.list_my_requests(25, 0)',
      'select count(*) from public.list_my_notifications(25, 0)',
      'select count(*) from public.admin_counts()',
      format('select count(*) from public.create_requests(%L, %L::jsonb, false, null)', v_c2,
             jsonb_build_array(jsonb_build_object('type_code', 'vida', 'items', j_vida))),
      format('select count(*) from public.set_notification_read(%L, true)', n_c1)
    ] loop
      begin
        execute v_sql into v_n;
        v_t := v_t || format('ok(%s);', v_n);
      exception when others then v_t := v_t || sqlstate || ';';
      end;
    end loop;
  end;
  reset role;
  v_ok := v_t = repeat('42501;', 14);
  v_out := v_out || format('%s | X01 | anon | qualquer leitura ou escrita (tabelas e RPCs) | esperado: 14x recusado (42501) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- ===========================================================================
  -- Servidor (postgres): auditoria, notificações, imutabilidade
  -- ===========================================================================
  select count(*) into v_n from public.requests q
  where q.client_id in (v_c1, v_c2, v_c4)
    and not exists (select 1 from public.request_audit a
                    where a.request_id = q.id and a.action = 'created' and a.actor_id is not null
                      and a.client_id = q.client_id and a.insurance_type_code = q.insurance_type_code);
  select count(*) into v_n2 from public.requests q where q.client_id in (v_c1, v_c2, v_c4);
  v_ok := v_n = 0 and v_n2 = 6;
  v_out := v_out || format('%s | E01 | servidor | 100%% dos pedidos com auditoria "created" (quem, cliente, tipo) | esperado: 0 sem registo de 6 | obtido: %s sem registo de %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);

  select format('C1=%s C2=%s C4=%s',
           (select count(*) from public.notifications where recipient_id = v_c1),
           (select count(*) from public.notifications where recipient_id = v_c2),
           (select count(*) from public.notifications where recipient_id = v_c4))
    into v_t;
  v_ok := v_t = 'C1=3 C2=0 C4=1';
  v_out := v_out || format('%s | E02 | servidor | notificação 1 por pedido só para quem já entrou | esperado: C1=3 C2=0 C4=1 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  v_t := '';
  declare v_sql text; begin
    foreach v_sql in array array[
      format('update public.requests set client_id = %L where id = %L', v_c2, r_auto),
      format('update public.requests set message = %L where id = %L', 'x', r_auto),
      format('delete from public.requests where id = %L', r_auto),
      format('update public.request_items set label = %L where request_id = %L', 'x', r_auto),
      format('delete from public.request_items where request_id = %L', r_auto),
      format('update public.request_recipients set office_id = %L where request_id = %L', v_b, r_auto),
      format('update public.request_audit set action = %L where request_id = %L', 'created', r_auto),
      format('delete from public.request_audit where request_id = %L', r_auto),
      format('update public.notifications set title = %L where id = %L', 'x', n_c1)
    ] loop
      begin
        execute v_sql;
        get diagnostics v_n = row_count;
        v_t := v_t || format('ok(%s);', v_n);
      exception when others then v_t := v_t || sqlstate || ';';
      end;
    end loop;
  end;
  v_ok := v_t = repeat('42501;', 9);
  v_out := v_out || format('%s | E03 | servidor | imutáveis: cliente, mensagem, apagar pedido, lista, destino, auditoria, texto da notificação | esperado: 9x 42501 | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  update public.requests set stage = 2 where id = r_auto;
  select format('etapa=%s data2=%s data3=%s', q.stage, q.documents_sent_at is not null, q.review_started_at is not null)
    into v_t from public.requests q where q.id = r_auto;
  v_ok := v_t = 'etapa=2 data2=t data3=f';
  v_out := v_out || format('%s | E04 | servidor | mudança de etapa (003/004) carimba a data | esperado: etapa=2 data2=true data3=false | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- ---------------------------------------------------------------------------
  -- Relatório. O erro é propositado: obriga ao ROLLBACK de tudo.
  -- ---------------------------------------------------------------------------
  select count(*) filter (where x like 'PASS%'), count(*) filter (where x like 'FAIL%')
    into v_pass, v_fail
  from unnest(v_out) as x;

  raise exception using
    errcode = 'P0001',
    message = format(E'QA 002: %s PASS, %s FAIL (de %s linhas). Erro propositado: ROLLBACK feito, nada ficou gravado.\n%s',
                     v_pass, v_fail, cardinality(v_out), array_to_string(v_out, E'\n'));
end
$qa$;
