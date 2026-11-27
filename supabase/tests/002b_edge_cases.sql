-- =============================================================================
-- QA 002 Novo pedido: casos-limite da criação (complementa 002_isolation_matrix)
-- Ficheiro : supabase/tests/002b_edge_cases.sql
-- Data     : 2026-11-27
-- Spec     : docs/features/002-novo-pedido/02-spec.md (US 1.2, 1.4, 1.6, 1.7,
--            1.8, 2.1, 7.1, 7.2)
-- Requer   : migrações 001 a 001e e 20261127120000_002_requests aplicadas.
--
-- COMO CORRER (SQL Editor do Supabase, ou API de gestão, como postgres)
--   Colar o ficheiro inteiro e correr. TERMINA SEMPRE EM ERRO, de propósito:
--   o erro é o relatório ("QA 002b: N PASS, N FAIL ...") e obriga ao ROLLBACK
--   de tudo (utilizadores, escritório, concessões, pedidos, notificações,
--   auditoria e a desativação temporária de 1 item e 1 tipo do catálogo).
--
-- Simulação de papéis: igual à 001 e à 002 (set local role + request.jwt.claims).
-- Dados (novos, @example.invalid, "qa002b-..."): escritório A; MA; C1 (ativa,
-- já entrou), C2 (ativa, já entrou; retira a meio), C3 (ativa, nunca entrou).
--
-- Casos
--   B01  13 tipos de uma vez: 13 pedidos, 1 batch, mesma mensagem e condições,
--        13 auditorias, 13 notificações (texto sem itens da lista)
--   B02  atomicidade com 13 tipos: o 13.º com item inválido => 0 criados
--   B03  mensagem: 500 emojis (500 code points) aceite; 501 recusada;
--        100 famílias ZWJ (5 code points cada = 500) aceite; 101 recusada
--   B04  mensagem com "<script>" e quebras de linha: guardada literal
--   B05  item livre: 200 code points com emojis aceite; 201 recusado; tab,
--        NEL (U+0085) e "<" recusados; espaços nas pontas aparados; & " '
--        guardados literais
--   B06  60 itens aceite; 61 recusado
--   B07  lista só com itens livres: list_edited = true
--   B08  repetido com 2 tipos em curso: detail com os 2; confirm_repeat null
--        conta como "não confirmado"
--   B09  concessão retirada a meio (depois de abrir o Novo pedido): criar 13
--        tipos => client_not_available, 0 criados; tipos em curso 0 linhas
--   B10  catálogo mudado a meio: item desativado => invalid_item; tipo
--        desativado => invalid_input (nada criado)
--   B11  cliente e mediador sem escritório não criam; cliente lê 0 em
--        client_open_types / office_requests_summary
--   B12  office_requests_summary com 201 ids => 0 linhas (limite 200)
-- =============================================================================

do $qa$
declare
  v_tag  text := 'qa002b-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 10);
  v_ver  text;
  v_a    uuid := gen_random_uuid();
  v_ma   uuid := gen_random_uuid();
  v_m0   uuid := gen_random_uuid();  -- mediador sem escritório
  v_c1   uuid := gen_random_uuid();
  v_c2   uuid := gen_random_uuid();
  v_c3   uuid := gen_random_uuid();
  g_c2a  uuid;
  j_all  jsonb;      -- 13 tipos com a lista do catálogo
  j_bad  jsonb;
  j_pets jsonb;
  j_vida jsonb;
  v_item uuid;
  v_rid  uuid;
  v_batch uuid;
  v_out  text[] := '{}';
  v_ok   boolean;
  v_t    text;
  v_det  text;
  v_n    bigint;
  v_n2   bigint;
  v_pass int; v_fail int;
  v_free jsonb;
begin
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
         case when u.k <> 'c3' then now() end
  from (values (v_ma, 'ma'), (v_m0, 'm0'), (v_c1, 'c1'), (v_c2, 'c2'), (v_c3, 'c3')) as u(id, k);

  insert into public.profiles (id, role, full_name, email)
  select u.id, u.r::public.app_role, v_tag || ' ' || upper(u.k), v_tag || '-' || u.k || '@example.invalid'
  from (values (v_ma, 'ma', 'mediador'), (v_m0, 'm0', 'mediador'), (v_c1, 'c1', 'cliente'),
               (v_c2, 'c2', 'cliente'), (v_c3, 'c3', 'cliente')) as u(id, k, r);

  insert into public.offices (id, name) values (v_a, v_tag || ' Escritório A');
  insert into public.office_members (user_id, office_id) values (v_ma, v_a);

  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c1, v_a, 'ativa', v_ver, v_ma), (v_c3, v_a, 'ativa', v_ver, v_ma);
  insert into public.consent_grants (client_id, office_id, status, consent_version, created_by)
    values (v_c2, v_a, 'ativa', v_ver, v_ma) returning id into g_c2a;

  -- Os 13 tipos, cada um com a lista completa do catálogo (como a app envia)
  select jsonb_agg(jsonb_build_object('type_code', t.code, 'items',
           (select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position)
            from public.insurance_type_items i where i.type_code = t.code and i.active))
         order by t.sort_order)
    into j_all
  from public.insurance_types t where t.active;
  select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position) into j_pets
    from public.insurance_type_items i where i.type_code = 'pets' and i.active;
  select jsonb_agg(jsonb_build_object('catalog_item_id', i.id) order by i.position) into j_vida
    from public.insurance_type_items i where i.type_code = 'vida' and i.active;

  -- ===========================================================================
  -- MA
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;

  v_ok := auth.uid() = v_ma and current_user = 'authenticated' and private.my_role() = 'mediador';
  v_out := v_out || format('%s | S1 | MA | simulação de sessão | obtido: %s %s',
                           case when v_ok then 'PASS' else 'FAIL' end, current_user, private.my_role());

  -- B02 (antes do B01, para C1 ainda não ter pedidos): 12 tipos válidos + o 13.º com item inválido
  j_bad := jsonb_set(j_all, '{12,items}', (j_all -> 12 -> 'items') || jsonb_build_array(jsonb_build_object('kind', 'D', 'label', 'x > y')));
  begin
    perform public.create_requests(v_c1, j_bad, false, null);
    v_t := 'sem erro';
  exception when others then
    get stacked diagnostics v_det = pg_exception_detail;
    v_t := sqlerrm || ' detail=' || coalesce(v_det, '');
  end;
  reset role;
  select count(*) into v_n from public.requests q where q.client_id = v_c1;
  select count(*) into v_n2 from public.notifications n where n.recipient_id = v_c1;
  set local role authenticated;
  v_ok := v_t = 'invalid_item detail=obras' and v_n = 0 and v_n2 = 0;
  v_out := v_out || format('%s | B02 | MA | 13 tipos, o 13.º com item "x > y" | esperado: invalid_item detail=obras, 0 pedidos, 0 notificações | obtido: %s; pedidos=%s notif=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t, v_n, v_n2);

  -- B01 13 tipos de uma vez
  select count(*), count(distinct x.batch_id), min(x.batch_id::text)::uuid into v_n, v_n2, v_batch
  from public.create_requests(v_c1, j_all, true, 'Bom dia 👋') x;
  reset role;
  select format('pedidos=%s batch=%s etapa=%s cond=%s msg=%s editada=%s auditoria=%s notif=%s titulos_ok=%s corpo_ok=%s sem_itens=%s',
           v_n, v_n2,
           (select string_agg(distinct q.stage::text, ',') from public.requests q where q.batch_id = v_batch),
           (select bool_and(q.allow_policy_conditions) from public.requests q where q.batch_id = v_batch),
           (select count(distinct q.message) || ':' || max(q.message) from public.requests q where q.batch_id = v_batch),
           (select bool_or(q.list_edited) from public.requests q where q.batch_id = v_batch),
           (select count(*) from public.request_audit a join public.requests q on q.id = a.request_id
             where q.batch_id = v_batch and a.action = 'created' and a.actor_id = v_ma and a.office_id = v_a),
           (select count(*) from public.notifications n where n.recipient_id = v_c1),
           (select bool_and(n.title = 'Novo pedido: ' || q.type_name and n.kind = 'pedido_criado' and n.object_type = 'request')
              from public.notifications n join public.requests q on q.id = n.object_id where n.recipient_id = v_c1),
           (select bool_and(n.body = v_tag || ' Escritório A') from public.notifications n where n.recipient_id = v_c1),
           not exists (select 1 from public.notifications n join public.request_items i on i.request_id = n.object_id
                        where n.recipient_id = v_c1 and (position(i.label in n.title) > 0 or position(i.label in coalesce(n.body, '')) > 0)))
    into v_t;
  set local role authenticated;
  v_ok := v_t = 'pedidos=13 batch=1 etapa=1 cond=t msg=1:Bom dia 👋 editada=f auditoria=13 notif=13 titulos_ok=t corpo_ok=t sem_itens=t';
  v_out := v_out || format('%s | B01 | MA | 13 tipos de uma vez para C1 (já entrou) | esperado: 13 pedidos, 1 batch, etapa 1, mesma mensagem e condições, 13 auditorias, 13 notificações sem itens | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- B03 mensagem em code points (C3, Pets; cada criação confirmada como repetida)
  v_t := '';
  declare v_msg text; i int := 0; begin
    foreach v_msg in array array[
      repeat('😀', 500),
      repeat('😀', 501),
      repeat(U&'\+01F468\200D\+01F469\200D\+01F467', 100),
      repeat(U&'\+01F468\200D\+01F469\200D\+01F467', 101),
      '   ' || repeat('a', 500) || '   '
    ] loop
      i := i + 1;
      begin
        select x.request_id into v_rid from public.create_requests(v_c3,
          jsonb_build_array(jsonb_build_object('type_code', 'pets', 'confirm_repeat', true, 'items', j_pets)), false, v_msg) x;
        reset role;
        v_t := v_t || 'ok(' || (select char_length(q.message) from public.requests q where q.id = v_rid) || ');';
        set local role authenticated;
      exception when others then v_t := v_t || sqlerrm || ';';
      end;
    end loop;
  end;
  v_ok := v_t = 'ok(500);message_too_long;ok(500);message_too_long;ok(500);';
  v_out := v_out || format('%s | B03 | MA | mensagem: 500 emojis / 501 / 100 famílias ZWJ (500 cp) / 101 / 500 com espaços nas pontas | esperado: ok(500);message_too_long;ok(500);message_too_long;ok(500); | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- B04 mensagem com HTML e quebras de linha: guardada literal
  select x.request_id into v_rid from public.create_requests(v_c3,
    jsonb_build_array(jsonb_build_object('type_code', 'pets', 'confirm_repeat', true, 'items', j_pets)), false,
    E'<script>alert(1)</script>\nLinha 2 & "aspas" ''plica''') x;
  reset role;
  select q.message into v_t from public.requests q where q.id = v_rid;
  set local role authenticated;
  v_ok := v_t = E'<script>alert(1)</script>\nLinha 2 & "aspas" ''plica''';
  v_out := v_out || format('%s | B04 | MA | mensagem com <script>, quebra de linha, & e aspas | esperado: guardada literal (escape é na saída) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, replace(v_t, E'\n', '\n'));

  -- B05 itens livres (C3, Vida confirmada)
  v_t := '';
  declare v_lbl text; begin
    foreach v_lbl in array array[
      repeat('🚗', 200),
      repeat('🚗', 201),
      E'Fotos\tdo carro',
      U&'Fotos\0085do carro',
      'Fotos < 3',
      '   Fotos do carro   ',
      'Recibos & "outros" ''extras'''
    ] loop
      begin
        select x.request_id into v_rid from public.create_requests(v_c3,
          jsonb_build_array(jsonb_build_object('type_code', 'vida', 'confirm_repeat', true,
            'items', jsonb_build_array(jsonb_build_object('kind', 'I', 'label', v_lbl)))), false, null) x;
        reset role;
        v_t := v_t || 'ok(' || (select i.label from public.request_items i where i.request_id = v_rid and i.position = 1) || ');';
        set local role authenticated;
      exception when others then v_t := v_t || sqlerrm || ';';
      end;
    end loop;
  end;
  v_ok := v_t = 'ok(' || repeat('🚗', 200) || ');invalid_item;invalid_item;invalid_item;invalid_item;ok(Fotos do carro);ok(Recibos & "outros" ''extras'');';
  v_out := v_out || format('%s | B05 | MA | item livre: 200 emojis / 201 / tab / NEL U+0085 / "<" / espaços nas pontas / & e aspas | esperado: ok;invalid_item x4;ok(aparado);ok(literal) | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, replace(v_t, repeat('🚗', 200), '<200 emojis>'));

  -- B06 60 itens aceite; 61 recusado
  select jsonb_agg(jsonb_build_object('kind', 'D', 'label', 'Item ' || g)) into v_free from generate_series(1, 60) g;
  v_t := '';
  begin
    select x.request_id into v_rid from public.create_requests(v_c3, jsonb_build_array(
      jsonb_build_object('type_code', 'obras', 'items', v_free)), false, null) x;
    reset role;
    v_t := 'ok(' || (select count(*) from public.request_items i where i.request_id = v_rid) || ');';
    set local role authenticated;
  exception when others then v_t := sqlerrm || ';';
  end;
  begin
    perform public.create_requests(v_c3, jsonb_build_array(
      jsonb_build_object('type_code', 'saude', 'items', v_free || jsonb_build_array(jsonb_build_object('kind', 'D', 'label', 'Item 61')))), false, null);
    v_t := v_t || 'criado;';
  exception when others then v_t := v_t || sqlerrm || ';';
  end;
  v_ok := v_t = 'ok(60);invalid_item;';
  v_out := v_out || format('%s | B06 | MA | lista com 60 itens / 61 itens | esperado: ok(60);invalid_item; | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- B07 lista só com itens livres (todos os do catálogo tirados): list_edited
  reset role;
  select q.list_edited::text || '/' || (select string_agg(distinct i.source, ',') from public.request_items i where i.request_id = q.id)
    into v_t from public.requests q where q.client_id = v_c3 and q.insurance_type_code = 'obras';
  set local role authenticated;
  v_ok := v_t = 'true/livre';
  v_out := v_out || format('%s | B07 | MA | lista só com itens livres | esperado: list_edited=true, source=livre | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- B08 repetido com 2 tipos em curso (C1 tem os 13): detail com os 2; confirm_repeat null = não confirmado
  begin
    perform public.create_requests(v_c1, jsonb_build_array(
      jsonb_build_object('type_code', 'saude', 'items', (select jsonb_agg(jsonb_build_object('catalog_item_id', i.id)) from public.insurance_type_items i where i.type_code = 'saude' and i.active)),
      jsonb_build_object('type_code', 'vida', 'confirm_repeat', null, 'items', j_vida)), false, null);
    v_t := 'sem erro';
  exception when others then
    get stacked diagnostics v_det = pg_exception_detail;
    v_t := sqlerrm || ' detail=' || coalesce(v_det, '');
  end;
  select count(*) into v_n from public.client_open_types(v_c1);
  v_ok := v_t = 'repeated_request detail=saude,vida' and v_n = 13;
  v_out := v_out || format('%s | B08 | MA | 2 tipos em curso (um com confirm_repeat=null) | esperado: repeated_request detail=saude,vida; tipos em curso=13 | obtido: %s; tipos em curso=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t, v_n);

  -- B09 concessão retirada a meio: MA já abriu o Novo pedido (tipos em curso lidos), C2 retira, MA cria
  select count(*) into v_n from public.client_open_types(v_c2);   -- 0, mas a chamada funciona (ativa)
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_c2, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c2::text, true);
  set local role authenticated;
  update public.consent_grants set status = 'retirada' where id = g_c2a;
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_ma, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ma::text, true);
  set local role authenticated;
  begin
    perform public.create_requests(v_c2, j_all, false, 'Olá');
    v_t := 'sem erro';
  exception when others then v_t := sqlerrm || '/' || sqlstate;
  end;
  reset role;
  select count(*) into v_n2 from public.requests q where q.client_id = v_c2;
  select v_t || format(' pedidos=%s notif=%s', v_n2, (select count(*) from public.notifications n where n.recipient_id = v_c2)) into v_t;
  set local role authenticated;
  select count(*) into v_n from public.client_open_types(v_c2);
  v_ok := v_t = 'client_not_available/42501 pedidos=0 notif=0' and v_n = 0;
  v_out := v_out || format('%s | B09 | C2+MA | C2 retira com o Novo pedido aberto; MA cria 13 tipos | esperado: client_not_available, 0 pedidos, 0 notificações, tipos em curso 0 | obtido: %s; tipos em curso=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t, v_n);

  -- B10 catálogo mudado a meio (como admin/migração): item e tipo desativados
  reset role;
  select i.id into v_item from public.insurance_type_items i where i.type_code = 'pets' and i.position = 1;
  update public.insurance_type_items set active = false where id = v_item;
  update public.insurance_types set active = false where code = 'responsabilidade_civil';
  set local role authenticated;
  v_t := '';
  begin
    perform public.create_requests(v_c3, jsonb_build_array(
      jsonb_build_object('type_code', 'pets', 'confirm_repeat', true, 'items', j_pets)), false, null);
    v_t := 'criado;';
  exception when others then
    get stacked diagnostics v_det = pg_exception_detail;
    v_t := sqlerrm || ' detail=' || coalesce(v_det, '') || ';';
  end;
  begin
    perform public.create_requests(v_c3, jsonb_build_array(
      jsonb_build_object('type_code', 'responsabilidade_civil', 'items', jsonb_build_array(jsonb_build_object('kind', 'D', 'label', 'x')))), false, null);
    v_t := v_t || 'criado;';
  exception when others then
    get stacked diagnostics v_det = pg_exception_detail;
    v_t := v_t || sqlerrm || ' detail=' || coalesce(v_det, '') || ';';
  end;
  select count(*) into v_n from public.get_insurance_catalog();
  v_ok := v_t = 'invalid_item detail=pets;invalid_input detail=responsabilidade_civil;' and v_n = 12;
  v_out := v_out || format('%s | B10 | MA | item do catálogo e tipo desativados depois de a app carregar | esperado: invalid_item detail=pets; invalid_input detail=responsabilidade_civil; catálogo 12 | obtido: %s catálogo=%s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t, v_n);

  -- B12 resumo da lista Clientes com mais de 200 ids
  select count(*) into v_n from public.office_requests_summary(array[v_c1]);
  select count(*) into v_n2 from public.office_requests_summary(array[v_c1] || array(select gen_random_uuid() from generate_series(1, 200)));
  v_ok := v_n = 1 and v_n2 = 0;
  v_out := v_out || format('%s | B12 | MA | office_requests_summary com 1 id / 201 ids | esperado: 1 / 0 (limite 200, sem erro) | obtido: %s / %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_n, v_n2);
  reset role;

  -- ===========================================================================
  -- B11 cliente e mediador sem escritório
  -- ===========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_c1, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_c1::text, true);
  set local role authenticated;
  begin
    perform public.create_requests(v_c1, jsonb_build_array(jsonb_build_object('type_code', 'pets', 'confirm_repeat', true, 'items', j_pets)), false, null);
    v_t := 'criado';
  exception when others then v_t := sqlerrm;
  end;
  select count(*) into v_n from public.client_open_types(v_c1);
  select count(*) into v_n2 from public.office_requests_summary(null);
  v_t := v_t || format(' open=%s resumo=%s contagem=%s', v_n, v_n2, public.office_open_request_count());
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', v_m0, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_m0::text, true);
  set local role authenticated;
  begin
    perform public.create_requests(v_c1, jsonb_build_array(jsonb_build_object('type_code', 'pets', 'items', j_pets)), false, null);
    v_t := v_t || ' | m0: criado';
  exception when others then v_t := v_t || ' | m0: ' || sqlerrm;
  end;
  reset role;
  v_ok := v_t = 'not_authorized open=0 resumo=0 contagem=0 | m0: not_authorized';
  v_out := v_out || format('%s | B11 | C1, M sem escritório | criar pedido; tipos em curso; resumo; contagem | esperado: not_authorized, 0, 0, 0 | not_authorized | obtido: %s',
                           case when v_ok then 'PASS' else 'FAIL' end, v_t);

  -- ---------------------------------------------------------------------------
  -- Relatório. O erro é propositado: obriga ao ROLLBACK de tudo.
  -- ---------------------------------------------------------------------------
  select count(*) filter (where x like 'PASS%'), count(*) filter (where x like 'FAIL%')
    into v_pass, v_fail
  from unnest(v_out) as x;

  raise exception using
    errcode = 'P0001',
    message = format(E'QA 002b: %s PASS, %s FAIL (de %s linhas). Erro propositado: ROLLBACK feito, nada ficou gravado.\n%s',
                     v_pass, v_fail, cardinality(v_out), array_to_string(v_out, E'\n'));
end
$qa$;
