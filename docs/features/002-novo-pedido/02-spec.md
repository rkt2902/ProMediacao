# 02 Spec: 002 Novo pedido (mediador) + clientes com o estado dos pedidos

**Problema:** O mediador pede documentos por mensagem avulsa, sem lista certa por tipo de seguro e sem ver quem tem o quê em curso.

**Objetivo:** O mediador cria, para um cliente com concessão ativa, um pedido por tipo de seguro com a lista gerada, e vê o estado dos pedidos na lista de Clientes e na ficha do cliente.

Pressupostos: recomendações A do bizdev nas 4 decisões do `01-business.md` (ver "Decisões em aberto"). Já existe (001): perfis, escritórios, concessões (pendente, ativa, recusada, retirada), lista "Clientes" do mediador, painel de contagens do admin, envio de email, auditoria. Tudo o resto é novo.

## Modelo (resumo, sem esquema)

- **Pedido**: cliente, tipo de seguro, origem (`mediador`; `cliente` só preparado), etapa, condições particulares (sim/não), mensagem, lista (cópia), autor, datas.
- **Destinatário**: escritório que recebe o pedido (ligação própria, para vários no futuro). Pedido do mediador: um só.
- **Proposta**: só preparada (relação ao pedido), sem ecrãs nem dados.
- **Etapas**: 1 criado, 2 documentos enviados, 3 em análise, 4 enviado às seguradoras. Na 002 só se atinge "criado". Transições: 1 para 2 na 003 (cliente envia); 2 para 3 e 3 para 4 na 004 (revisão do mediador).
- **Catálogo**: 13 tipos e respetivos itens (D/I) e nota, em dados (fonte: `docs/reference/tipos-de-seguro.md`), editáveis sem nova versão da app. O pedido guarda uma **cópia** da lista no momento da criação: alterar o catálogo depois não muda pedidos existentes.

## User stories

1. Como mediador, quero criar pedidos para um cliente do meu escritório, para substituir a mensagem avulsa por uma lista certa.
   - 1.1 Dado "Novo pedido", Quando escolho o cliente, Então só aparecem clientes com concessão **ativa** com o meu escritório.
   - 1.2 Dado um cliente escolhido, Quando seleciono N tipos (1 a 13), Então é criado exatamente 1 pedido por tipo (N pedidos), todos na etapa "criado", todos com a mesma mensagem e a mesma opção de condições particulares.
   - 1.3 Dado um tipo selecionado, Então vejo "O cliente vai receber": a nota do tipo e a lista com cada item marcado como Documento ou Dado, igual ao catálogo.
   - 1.4 Dado a lista de um pedido, Quando retiro um item ou acrescento um item livre (texto, marcado Documento ou Dado), Então o pedido criado guarda a lista editada; o catálogo não muda. Não é possível criar um pedido com a lista vazia.
   - 1.5 Dado "Condições particulares", Então vem desativada por omissão; se ativada, o pedido guarda a opção e a lista mostra a nota "O cliente pode enviar as condições particulares da apólice atual em vez dos documentos um a um".
   - 1.6 Dado a mensagem opcional, Então aceita até 500 caracteres, com contador; vazia é válido.
   - 1.7 Dado "Criar", Então ou são criados todos os N pedidos ou nenhum (criação atómica), e o mediador vê confirmação com o número de pedidos e o regresso à ficha do cliente.
   - 1.8 Dado um cliente que já tem pedido em curso (etapa 1 a 3) do mesmo tipo, Quando seleciono esse tipo, Então vejo o aviso "Já existe um pedido de <tipo> em curso" e só crio se confirmar; sem confirmação, esse tipo não é criado.
   - 1.9 Dado a criação concluída, Então cada pedido gera auditoria (quem, quando, cliente, tipo).

2. Como mediador, quero que o pedido só exista com concessão ativa, para não contornar o consentimento.
   - 2.1 Dado um cliente com concessão pendente, recusada ou retirada, Quando tento criar pedido (UI ou pedido direto à API), Então é recusado. Na UI, o cliente não aparece na escolha; se vier da ficha ou da lista, vejo o motivo: pendente ("Ainda não aceitou. Reenvie o pedido de partilha"), recusada ("Recusou a partilha. Não é possível criar pedidos"), retirada ("Retirou o acesso. Só volta a ser possível se aceitar de novo").
   - 2.2 Dado um mediador de outro escritório, Quando tenta criar pedido para este cliente, Então é recusado sem revelar se o cliente existe.
   - 2.3 Dado a concessão passada a retirada com pedidos abertos, Então (decisão 26/11 ponto 2 da 001) o escritório deixa de ver esses pedidos de imediato (0 linhas, sem cache); não são apagados; se o cliente voltar a aceitar (nova concessão), os pedidos reaparecem com a etapa que tinham. Ver decisão A5.

3. Como mediador, quero ver o estado dos pedidos de cada cliente na lista de Clientes e na ficha, para saber quem tem o quê em curso.
   - 3.1 Dado a lista "Clientes", Então cada cliente com concessão ativa mostra o nº de pedidos em curso (etapas 1 a 3) e a etapa mais avançada entre eles (na 002 sempre "Criado"); sem pedidos mostra "Sem pedidos".
   - 3.2 Dado um cliente com concessão pendente ou recusada, Então a lista não mostra pedidos (só o estado da concessão, como na 001).
   - 3.3 Dado "Abrir ficha", Então vejo o nome e email do cliente e os seus pedidos **deste escritório**, mais recentes primeiro, cada um com tipo, data de criação, etapa (das 4), origem ("Mediador") e etiqueta "Condições particulares" se ativa.
   - 3.4 Dado um pedido na ficha, Quando o abro, Então vejo a lista guardada (com a nota), a mensagem e quem o criou. Só leitura.
   - 3.5 Dado a ficha, Então tem a ação "Novo pedido" com o cliente já escolhido; na lista de Clientes também, por cliente com concessão ativa.
   - 3.6 Dado pedidos de um cliente com vários escritórios (C2), Então o meu escritório vê só os pedidos destinados a ele.

4. Como cliente, quero ver os pedidos que recebi, para saber o que o escritório me pede (só leitura; carregar é a 003).
   - 4.1 Dado um pedido criado, Então o cliente recebe SEMPRE um email curto com escritório, tipos pedidos, mensagem do mediador e link para a app; o email não inclui a lista de documentos nem dados de saúde.
   - 4.2 Dado o cliente com sessão, Então vê no seu painel ("Os meus pedidos") os seus pedidos (tipo, escritório, data, etapa das 4, lista do que falta) só em leitura, sem botão de carregar até à 003; sem pedidos: "Ainda não tem pedidos".
   - 4.3 Dado um pedido de escritório com concessão retirada, Então o cliente ainda o vê, com a etiqueta "Acesso retirado" e sem ações.
   - 4.4 Dado o email não enviado (falha), Então o pedido fica criado e o mediador vê "Pedido criado, mas o email não foi enviado" com "Reenviar email" (bloqueado 60 s após cada envio, como na 001).

5. Como admin, quero ver a contagem de pedidos, sem ver o seu conteúdo.
   - 5.1 Dado o painel, Então mostra uma quarta contagem: nº de pedidos (total).
   - 5.2 Dado o admin, Quando consulta pedidos, listas, mensagens, destinatários ou clientes, Então recebe 0 linhas / recusado; só existe a contagem agregada.

6. Como equipa, quero a matriz de isolamento dos pedidos testada contra a base de dados, como na 001.
   - Dados: escritórios A e B, MA, MB, clientes C1 (ativa com A), C2 (ativa com A e B), C3 (pendente com A), C4 (retirada com A), C5 (recusada com A), admin, anónimo.

   | Quem | Ação | Esperado |
   | --- | --- | --- |
   | MA | criar pedido para C1 ou C2 (escritório A) | permitido |
   | MA | criar pedido para C3, C4, C5 | recusado |
   | MA | criar pedido para C1 com destino B | recusado |
   | MA | ler pedidos de C1, C2 (destino A) | só os do escritório A |
   | MA | ler pedidos de C2 destinados a B, e pedidos de C3, C4, C5 | 0 linhas |
   | MB | ler pedidos destinados a A | 0 linhas |
   | MA | alterar etapa, lista ou apagar pedido | recusado (na 002 não há edição) |
   | MA | acrescentar proposta ou outro destinatário a um pedido | recusado |
   | C1 | ler os seus pedidos | todos os seus |
   | C2 | ler pedidos | só os seus (A e B), nunca os de C1 |
   | C1 | criar, alterar ou apagar pedido | recusado |
   | Admin | ler pedidos ou destinatários | 0 linhas; só a contagem |
   | Anónimo | qualquer leitura ou escrita | 0 linhas / recusado |
   | MA | alterar o catálogo | recusado (só admin/migração) |
   | MA | ler o catálogo | permitido |
   | C1 | ler notificações | só as suas |
   | C1 | marcar como lida uma notificação sua / de outro cliente | permitido / recusado |
   | C1 | criar ou apagar notificações | recusado |
   | MA, MB, Admin, Anónimo | ler ou escrever notificações | 0 linhas / recusado |
   | Servidor | criar notificação ao criar pedido (cliente com conta ativa) | permitido, 1 por pedido |

   - Dado qualquer linha, Então o resultado coincide; uma divergência bloqueia o fecho. Após retirada de C1, MA lê 0 pedidos de C1 no pedido seguinte.

7. Como cliente, quero ser avisado dentro da app quando recebo um pedido, para não depender só do email. (Mecanismo genérico, reutilizável por outras features.)
   - 7.1 Dado um pedido criado para um cliente que já tem conta ativa (já entrou alguma vez), Então é criada 1 notificação para esse cliente (1 por pedido); para um cliente que nunca entrou, não é criada (só o email, 4.1); ao primeiro acesso não aparecem notificações antigas de pedidos já visíveis no painel.
   - 7.2 Dado uma notificação, Então tem: tipo (ex.: "pedido_criado"), destinatário (utilizador), texto curto, estado lida/não lida, data e ligação ao objeto (tipo e id, ex.: pedido). Sem dados da lista, de saúde nem de outros escritórios no texto.
   - 7.3 Dado o cliente com sessão, Então vê um sino com o contador de não lidas (oculto a 0; "9+" acima de 9) e, ao abrir, a lista por data decrescente, paginada; vazio: "Sem notificações".
   - 7.4 Dado uma notificação não lida, Quando o cliente a abre, Então passa a lida e o contador desce; o clique leva ao pedido. Se a concessão do escritório foi retirada, o pedido abre na mesma, com a etiqueta "Acesso retirado" e sem ações (4.3).
   - 7.5 Dado o cliente, Então só lê e marca como lidas as suas notificações; não pode criá-las, alterá-las além de lida/não lida, nem apagá-las. Mediador e admin: 0 linhas das notificações de clientes.
   - 7.6 Dado offline ou erro, Então o sino mostra o último estado conhecido com aviso, e "marcar como lida" só é dado como feito após confirmação do servidor.
   - 7.7 Dado o telemóvel, tablet e desktop, Então o sino está sempre acessível; a lista abre como painel (desktop) ou ecrã (telemóvel).

## Fora de âmbito

- Push no telemóvel (backlog); notificações para mediador/admin; preferências de notificação.

- Upload ou resposta do cliente com documentos e condições particulares (003); revisão, extração com IA e ficha PDF/Excel (004); estados "pronto para exportar" e "exportado".
- Pedidos iniciados pelo cliente, vários destinatários com ecrãs, propostas, anúncio aberto (005 a 007): só o modelo fica preparado.
- Cancelar, editar ou apagar um pedido depois de criado.
- Criar cliente dentro do Novo pedido (usa-se "Criar cliente" da 001).
- Painel geral de pedidos com filtros e pesquisa: **não cabe**; a lista de Clientes com o estado chega para um escritório pequeno. Rever se o Henrique pedir.
- Lembretes, push, SMS, WhatsApp; editor do catálogo na app (edita-se em dados).
- Clientes reais antes do parecer jurídico.

## Estados a cobrir

| Estado | Comportamento |
| --- | --- |
| Vazio | Sem clientes com concessão ativa: "Ainda não tem clientes com acesso ativo" e ligação a "Criar cliente". Cliente sem pedidos: "Sem pedidos" com botão "Novo pedido". Cliente (perfil) sem pedidos: "Ainda não tem pedidos". |
| A carregar | Indicador na lista, na ficha e na pré-visualização da lista; "Criar" desativado com indicador durante o envio, sem duplicar pedidos. |
| Erro | Copy formal em PT-PT, sem erros técnicos, com "Tentar novamente" e seleção preservada. Casos: falha ao criar (nada criado), falha do catálogo, concessão deixou de estar ativa entre abrir e criar ("Este cliente já não partilha dados consigo"), falha de email (4.4). |
| Offline | Aviso visível; "Criar" e "Reenviar email" bloqueados; nunca mostrar como criado algo não confirmado pelo servidor; seleção preservada. |
| Sucesso | Confirmação "N pedido(s) criado(s)" com ligação à ficha; a ficha mostra os novos pedidos. |
| Sem permissão | Cliente sem concessão ativa ou de outro escritório: vazio ou "Sem acesso", sem revelar existência. |
| Conteúdo longo | Nomes, emails e mensagens longos truncados com reticências na lista e quebra de linha na leitura; listas com muitos itens com scroll e botão "Criar" sempre visível; lista de clientes e pedidos paginada. |
| Responsivo | Telemóvel, tablet e desktop: a pré-visualização "O cliente vai receber" fica ao lado no desktop e por baixo no telemóvel; todas as ações usáveis nos três tamanhos. |

## Dados e permissões

| Dado | Lido por | Escrito por | Regra (RLS) | Novo? |
| --- | --- | --- | --- | --- |
| Catálogo (tipos, itens D/I, notas) | Utilizadores autenticados | Admin/migração | Só leitura na app | Novo |
| Pedido (cliente, tipo, origem, etapa, condições, mensagem, cópia da lista, autor) | Cliente titular; mediadores do escritório destinatário **com concessão ativa** | Mediador: só criar, com concessão ativa do cliente com o seu escritório, origem `mediador`, etapa "criado" (atómico, N pedidos) | Retirada oculta de imediato ao escritório; sem UPDATE/DELETE para a app na 002; admin sem acesso | Novo |
| Destinatário do pedido | Cliente titular; mediadores desse escritório (concessão ativa) | Criado com o pedido (1 escritório) | Igual ao pedido; admin sem acesso | Novo |
| Proposta | Ninguém na 002 | Ninguém | Só estrutura preparada, sem permissões abertas | Novo |
| Auditoria de pedido (criação) | Mediadores do escritório; cliente (o seu) | Só servidor, ao criar | Só INSERT, como na 001 | Novo |
| Email do pedido | Cliente | Função de servidor ao criar; reenvio pelo mediador | Só envia para o cliente titular; limite 60 s | Novo |
| Notificação (tipo, destinatário, texto, lida, data, ligação ao objeto) | Só o destinatário (cliente) | Criar: só servidor (ao criar pedido); o cliente só muda lida/não lida | Sem acesso de mediador, admin ou anónimo; sem DELETE | Novo |
| Contagem de pedidos | Admin | n/a | Função agregada sem dados pessoais, junta-se às 3 existentes | Alteração |
| Perfil e concessão (lista Clientes) | Mediador | Já existe | Reutiliza as regras da 001 | Existe |

## Decisões em aberto

| Decisão | A | B | C | Recomendação |
| --- | --- | --- | --- | --- |
Todas decididas no gate 1, 27/11.

| Decisão | Resultado |
| --- | --- |
| 1. Envio do pedido ao cliente | **Decidido no gate 1, 27/11** (difere da recomendação): email curto SEMPRE ao criar (US 4.1) mais notificação in-app se o cliente já tem conta ativa (US 7). Risco: limite de emails do Supabase por defeito (2 por hora) |
| 2. O que o cliente vê antes da 003 | **Decidido no gate 1, 27/11**: o pedido aparece no painel do cliente com as 4 etapas, só leitura (US 4.2), mais o sino de notificações (US 7) |
| 3. Pedido repetido | **Decidido no gate 1, 27/11**: A, aviso com confirmação (US 1.8) |
| 4. Condições particulares por omissão | **Decidido no gate 1, 27/11**: A, desativadas (US 1.5) |
| 5. Pedidos abertos na retirada | **Decidido no gate 1, 27/11**: A, ocultos ao escritório, não apagados, reaparecem com nova concessão (US 2.3, 4.3) |
| 6. Editar a lista no pedido | **Decidido no gate 1, 27/11**: A, retirar itens e acrescentar itens livres, só neste pedido (US 1.4); a métrica de qualidade mede-se pelos pedidos com lista alterada |
| 7. Painel geral de pedidos com filtros | **Decidido no gate 1, 27/11**: A, fica para depois |
