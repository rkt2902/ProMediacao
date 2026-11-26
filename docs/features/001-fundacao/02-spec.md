# 02 Spec: 001 Fundação (autenticação, perfis, escritórios e consentimento)

**Problema:** Sem identidade, escritórios e consentimento do cliente não há produto, e o isolamento entre escritórios e o registo auditável de consentimento têm de nascer certos.

**Objetivo:** Cada pessoa entra com o seu perfil, o cliente decide com que escritório partilha (e retira quando quiser), e nenhum escritório ou o admin vê mais do que lhe cabe.

Pressupostos: decisões 1 e 2 abaixo assumidas como A. Se o Henrique escolher outra opção, mudam as US 4 e 5 e o modelo (ver "Decisões em aberto"). Estado atual: nada existe (app é o esqueleto do contador, Supabase vazio), por isso tudo é novo.

## User stories

1. Como mediador, admin ou cliente com palavra-passe, quero entrar com email e palavra-passe e recuperá-la, para aceder ao meu espaço.
   - Dado um mediador ou admin com conta, Quando entra com credenciais corretas, Então vê o seu ecrã inicial; com credenciais erradas vê "Email ou palavra-passe incorretos" sem indicar qual falhou. Mediador e admin não têm entrada por link mágico.
   - Dado um cliente que já definiu palavra-passe, Quando entra com email e palavra-passe corretos, Então entra sem precisar de link; com dados errados vê a mesma mensagem genérica.
   - Dado um utilizador sem sessão, Quando pede qualquer dado, Então recebe 0 linhas.
   - Dado "Esqueci-me da palavra-passe" (todos os perfis), Quando indica o email, Então recebe o email de recuperação do Supabase e a resposta é igual exista ou não a conta; o pedido fica bloqueado 60 s após cada envio.
   - Dado um cliente que ainda não tem palavra-passe, Quando usa "Esqueci-me da palavra-passe", Então pode defini-la por esse email.

2. Como admin, quero criar escritórios, convidar mediadores e ver 3 contagens, para pôr a plataforma a funcionar sem ver dados pessoais.
   - Dado o admin, Quando cria um escritório e convida um mediador por email, Então o mediador fica ligado a esse único escritório e recebe o convite.
   - Dado o admin, Quando abre o painel, Então vê só: nº de escritórios, mediadores e clientes.
   - Dado o admin, Quando consulta a base de dados com o seu perfil, Então nome e email de mediadores e clientes não são devolvidos e não há acesso a concessões nem a dados de clientes.
   - Dado um mediador a tentar pertencer a 2 escritórios, Então a operação é recusada.

3. Como mediador, quero criar um cliente (nome e email) e reenviar-lhe o link, para o pôr a partilhar dados comigo.
   - Dado o mediador, Quando cria o cliente, Então fica criada uma concessão **pendente** para o escritório e o cliente recebe o link mágico com o nome do escritório e do mediador em destaque.
   - Dado uma concessão pendente ou recusada, Quando o mediador pede dados do cliente, Então só vê nome, email e estado (o necessário para reenviar o link ou saber que recusou) e nada mais.
   - Dado um cliente que recusou, Quando o mediador abre a lista, Então vê-o com o estado "Recusado" e sem ações (sem "Reenviar pedido").
   - Dado um link expirado ou perdido, Quando o mediador carrega "Reenviar pedido", Então o cliente recebe novo link; o botão fica bloqueado 60 s após cada envio.
   - Dado um email que já é cliente de outro escritório, Quando o mediador o cria, Então é criada só a concessão pendente para o seu escritório, sem revelar dados do cliente nem de outros escritórios.

4. Como cliente, quero entrar pelo link mágico (e, se quiser, passar a usar palavra-passe) e aceitar ou recusar a partilha, para só dar acesso a quem eu escolho.
   - Dado o link válido, Quando o cliente abre, Então vê o texto de consentimento (versão `v0-rascunho`), o nome do escritório e do mediador, e os botões "Aceitar" e "Recusar".
   - Dado um link expirado, Quando o cliente abre o ecrã de entrada e indica o email, Então pode pedir novo link, com resposta igual exista ou não a conta; o pedido fica bloqueado 60 s após cada envio.
   - Dado um cliente sem palavra-passe, Quando pede link no ecrã de entrada, Então continua a entrar por link mágico, sempre.
   - Dado a primeira entrada por link, Quando o cliente entra, Então é convidado a criar palavra-passe com "Criar palavra-passe" e "Agora não"; "Agora não" leva-o em frente sem bloqueio e o convite volta a aparecer no máximo na entrada seguinte por link.
   - Dado o convite adiado, Quando o cliente abre a conta, Então encontra "Criar palavra-passe" (ou "Alterar palavra-passe" se já existir).
   - Dado o ecrã de criar ou alterar palavra-passe (um só campo, sem confirmação, com opção de mostrar/ocultar), Então as 5 regras ficam visíveis e cada uma muda de estado em tempo real à medida que escreve: mínimo 10 caracteres, uma maiúscula, uma minúscula, um número, um carácter especial.
   - Dado uma palavra-passe que falha uma ou mais regras, Quando tenta guardar, Então "Guardar" fica inativo ou a gravação é recusada, e cada regra em falta aparece com a sua mensagem (ex.: "Falta uma maiúscula", "Mínimo de 10 caracteres"); uma palavra-passe que cumpre as 5 é aceite.
   - Dado as regras, Então cada uma é testável isoladamente (ex.: 9 caracteres falha; 10 sem número falha) e a mesma política é imposta no Supabase Auth: um pedido direto à API com palavra-passe fraca é recusado.
   - Dado um leitor de ecrã, Então cada regra é anunciada com o seu estado ("cumprida" / "por cumprir") e a mudança é comunicada sem depender só da cor (ícone e texto).
   - Dado um cliente com concessão pendente, Quando aceita ou recusa, Então a palavra-passe nunca é exigida, nem antes nem depois do consentimento.
   - Dado um cliente com palavra-passe, Quando pede também um link mágico, Então entra por link na mesma conta, sem perder a palavra-passe.
   - Dado um cliente que já tem conta e uma concessão pendente, Quando entra na app, Então vê o convite (escritório, mediador, texto) e pode aceitar ou recusar dentro da app, sem depender de email nem de link; pode também pedir reenvio do link a partir da app.
   - Dado "Aceitar", Então a concessão passa a ativa, e fica um registo de auditoria com cliente, escritório, data/hora, ação e versão do texto aceite.
   - Dado "Recusar", Então a concessão fica recusada, o mediador continua sem acesso a dados do cliente, e fica registo.
   - Dado uma concessão pendente ou recusada, Então o mediador não consegue ativá-la nem aceitar em nome do cliente.

5. Como cliente, quero ver "Com quem partilho" e retirar o acesso, para controlar os meus dados.
   - Dado o cliente, Quando abre o ecrã, Então vê cada escritório com estado (pendente, ativo, retirado) e data.
   - Dado uma concessão ativa, Quando carrega "Retirar acesso" e confirma, Então passa a retirada e fica registo de auditoria.
   - Dado a retirada feita, Quando o mediador faz o pedido seguinte, Então recebe 0 linhas, sem cache nem atraso, e deixa de ver também os dados que ele próprio escreveu no perfil desse cliente (decisão 2 = A).
   - Dado a retirada, Quando o cliente volta a aceitar, Então nasce uma nova concessão (novo registo, nova versão do texto) e os dados reaparecem.

6. Como qualquer perfil, quero ver só o que me pertence, para que não haja fugas entre escritórios.
   - **Matriz de isolamento (critério central, testada contra a base de dados com utilizadores de teste, não só na UI).** Dados: escritórios A e B, mediadores MA e MB, clientes C1 (concessão ativa com A), C2 (ativa com A e B), C3 (pendente com A), C4 (retirada com A), C5 (recusada com A), admin, anónimo. Resultado esperado de cada leitura/escrita:

   | Quem | Ação | Esperado |
   | --- | --- | --- |
   | MA | listar clientes | C1, C2 completos; C3 e C5 só nome, email e estado; C4 nada |
   | MA | ler clientes, concessões, auditoria de B | 0 linhas |
   | MA | ler concessões de C2 com B | 0 linhas |
   | MA | alterar estado de uma concessão | recusado |
   | MA | alterar ou apagar auditoria | recusado |
   | MB | ler C1, C3, C4, C5 | 0 linhas |
   | C2 | ler concessões | só as suas (A e B), nunca as de C1 |
   | C1 | ler escritório B | só nome do escritório se tiver concessão; senão 0 linhas |
   | C1 | retirar concessão de outro cliente | recusado |
   | Cliente | alterar ou apagar auditoria | recusado |
   | Admin | ler nome ou email de qualquer pessoa, concessões, auditoria | 0 linhas / recusado; só 3 contagens |
   | Anónimo | qualquer leitura ou escrita | 0 linhas / recusado |

   - Dado qualquer linha da matriz, Então o resultado coincide; uma divergência bloqueia o fecho da feature.
   - Dado criação ou retirada de concessão, Então 100% geram registo de auditoria.

## Fora de âmbito

- Pedidos, documentos, extração, ficha, templates, SMS/WhatsApp, encriptação por escritório, 2FA.
- Autorregisto do cliente e diretório público de escritórios (modelo preparado, ver decisão 1).
- Papéis dentro do escritório, transferir mediadores, escritórios criados pelo mediador, concessão por documento.
- Painel de admin para além das 3 contagens; suporte ao cliente pelo admin.
- Registo do acesso de serviço (service role) do dono do projeto: medida em falta, a escrever para o jurista.
- Texto final de consentimento (usa-se `v0-rascunho`, trocável sem código). Sem clientes reais até haver parecer jurídico.

## Estados a cobrir

| Estado | Comportamento |
| --- | --- |
| Vazio | Mediador sem clientes: mensagem e botão "Criar cliente". Cliente sem concessões: "Ainda não partilhas dados com nenhum escritório". Admin sem escritórios: botão "Criar escritório". Contagens a 0. |
| A carregar | Indicador em listas e ações; botões desativados durante envio para evitar duplicados (criar cliente, aceitar, retirar). |
| Erro | Copy em PT-PT com tratamento formal (ex.: "Introduza o seu email"). Mensagem com ação de repetir; link expirado ou inválido com explicação e pedido de novo link; email duplicado; falha de envio de email. Palavra-passe errada: "Email ou palavra-passe incorretos", igual exista ou não a conta. Palavra-passe fraca (menos de 8 caracteres) ou confirmação diferente: mensagem junto ao campo. Nunca mostrar erros técnicos. |
| Palavra-passe adiada | Cliente sem palavra-passe: entra por link; convite "Criar palavra-passe / Agora não" na entrada por link e sempre disponível na conta; nenhuma funcionalidade bloqueada. |
| Offline | Sem ligação: aviso visível e ações de escrita bloqueadas; nunca mostrar como retirado ou aceite algo não confirmado pelo servidor. |
| Sem permissão | Acesso a dados de outro escritório ou sem concessão devolve vazio ou "Sem acesso", sem revelar se o registo existe. Sessão do cliente com concessão retirada: mediador deixa de ver o cliente na lista. |
| Conteúdo longo | Nomes e emails longos truncados com reticências sem partir o layout; texto de consentimento com scroll e botões sempre visíveis; listas paginadas. |

## Dados e permissões

| Dado | Lido por | Escrito por | Regra (RLS) | Novo? |
| --- | --- | --- | --- | --- |
| Perfil (id, papel, nome, email) | O próprio; mediador: clientes com concessão ativa (completo) ou pendente/recusada (só nome, email, estado); nunca admin | O próprio (nome); criação por admin (mediador) ou mediador (cliente) | Admin sem SELECT sobre nome e email. Mediador: SELECT na tabela de perfis só com concessão ativa do seu escritório; para pendente/recusada, vista (ou função security definer) que junta perfil e concessão do seu escritório e expõe apenas nome, email e estado. Retirada: nada | Novo |
| Escritório (id, nome) | Admin; mediadores desse escritório; cliente com concessão (qualquer estado) nesse escritório | Admin | Pertença ou concessão | Novo |
| Pertença mediador-escritório (1 só escritório) | Admin (sem dados pessoais), o próprio mediador | Admin | Restrição única por mediador | Novo |
| Concessão cliente-escritório (estado: pendente, ativa, recusada, retirada; versão do texto; datas) | Cliente (as suas); mediadores do escritório (as do seu escritório) | Criar: mediador (só pendente) ou cliente (futuro); mudar estado: só o cliente titular | Mediador nunca ativa nem retira; sem admin | Novo |
| Dados do perfil do cliente escritos pelo mediador | Mediadores do escritório só com concessão ativa; o cliente | Mediador com concessão ativa | Retirada oculta-os de imediato (decisão 2 = A) | Novo |
| Auditoria de consentimento (cliente, escritório, ação, versão do texto, data/hora, autor) | Cliente (a sua); mediadores do escritório (do seu escritório) | Só por trigger/função de servidor ao mudar a concessão | Só INSERT; UPDATE e DELETE bloqueados para todos os perfis da app | Novo |
| Texto de consentimento (versão, conteúdo) | Utilizadores autenticados | Admin/migração | Só leitura na app | Novo |
| Contagens (escritórios, mediadores, clientes) | Admin | n/a | Função agregada sem dados pessoais; ver nota de risco com poucos escritórios | Novo |

**Credenciais (Supabase Auth):** email e palavra-passe ficam no Auth, não em tabelas da app; cada pessoa só altera a sua palavra-passe, com sessão válida. Sem novas tabelas nem alterações à matriz de isolamento.

## Decisões tomadas (gate 1 aprovado)

- Autenticação do cliente (decisão de 2026-11-26, altera a decisão 4): convite e primeira entrada por link mágico; depois, palavra-passe opcional (adiável) e entrada por palavra-passe ou link; mediador e admin só palavra-passe; "Esqueci-me da palavra-passe" para todos.
- Autorregisto do cliente: adiar a interface, modelo preparado para os dois modos (diretório público de escritórios fica para a feature em que o cliente inicia pedidos).
- Dados que o mediador escreveu no perfil do cliente: deixam de ser visíveis ao escritório quando o cliente retira o acesso.
- Email: Supabase por defeito. Limites de envio e entrega podem afetar a métrica dos 10 minutos; rever se falhar.
- Link expirado, convite na app, estado "Recusado" visível e bloqueio de 60 s no reenvio: ver US 3 e 4.
- Copy com tratamento formal.

## Decisões em aberto

Nenhuma.
