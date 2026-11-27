# 01 Negócio: 002 Novo pedido (mediador) + clientes com o estado dos pedidos

**Objetivo de negócio:** Substituir o pedido avulso (email, WhatsApp, papel) por um pedido estruturado, com lista certa por tipo de seguro, e dar ao mediador uma vista única de quem tem o quê em curso. É a base de dados e de conceitos (pedido, destinatário, proposta) de tudo o que vem a seguir (003 a 007). Sozinha não poupa tempo ao mediador: o ganho só se mede com a 003 (cliente responde) e a 004 (revisão e ficha). A 002 prova duas coisas: a lista gerada é a que o Henrique pediria, e o mediador prefere criar pedidos aqui a escrever a mensagem à mão.

Para quem: mediadores do escritório do Henrique (fase A do piloto, uso interno, sem pagamento). O cliente final só entra na 003.

**Métrica de sucesso:** em 3 semanas de uso real pelo Henrique (depois do parecer jurídico permitir clientes reais; até lá, com clientes de teste):
- Principal: pelo menos 80% dos pedidos novos da mediação criados na app, e não por mensagem avulsa (contagem de pedidos criados contra os pedidos que o Henrique diz ter feito na semana).
- Qualidade da lista: no máximo 1 em cada 10 pedidos precisa de o mediador acrescentar ou retirar manualmente um item fora da lista gerada (a lista é editável só se isto falhar; ver "Cortar").
- Tempo de criação: menos de 1 minuto do clique em "Novo pedido" até à criação, medido por cronómetro em 10 pedidos.

**Versão mínima que prova valor:**
- Novo pedido: escolher um cliente já existente com concessão ativa, um ou vários tipos dos 13 (um pedido por tipo), ver a lista gerada (`docs/reference/tipos-de-seguro.md`) com a nota do tipo, ativar ou não "condições particulares", mensagem opcional, criar.
- Clientes: na lista, o estado dos pedidos de cada cliente (nº em curso e etapa mais recente); na ficha, os pedidos desse cliente, cada um com tipo, data, etapa e origem.
- Estado em 4 etapas já no modelo; na 002 todos os pedidos ficam em "criado" (as outras etapas mexem-se na 003 e 004).
- Modelo preparado para origem `cliente`, vários destinatários e propostas (decisão do roadmap), sem ecrãs para isso.
- Aviso claro quando o cliente tem concessão pendente, recusada ou retirada: não se cria pedido, e a mensagem diz porquê e o que fazer.

**Cortar ou adiar:**
- Editar a lista gerada item a item por pedido (só se a métrica de qualidade falhar).
- Criar cliente dentro do Novo pedido (já existe "Criar cliente" na 001; só encadear se for trivial).
- Filtros e pesquisa avançada por estado, painel de pedidos de todos os clientes (o "Painel" do protótipo): a vista por cliente chega para um escritório pequeno.
- Lembretes automáticos, notificações push, SMS e WhatsApp.
- Pedidos do cliente, propostas, anúncio aberto (005 a 007).
- Cancelar ou editar pedido depois de criado: só se o Henrique o pedir na primeira semana (custo baixo, mas não prova nada agora).
- Estados "pronto para exportar" e "exportado" do protótipo: pertencem à 004.

**Riscos:**
- Valor invisível sem a 003: o mediador cria pedidos e o cliente não tem onde responder, por isso o pedido é só um registo. Mitigação: enviar o email do pedido (decisão A abaixo) e tratar a 002 e a 003 como um bloco de uso; não avaliar o tempo poupado só com a 002.
- Confiança e legal: criar um pedido não é partilhar dados, mas a lista menciona dados de saúde (nota saúde, exames). O pedido só pode existir com concessão ativa do cliente com esse escritório; sem isto, o mediador não deve conseguir contornar. O texto de consentimento ainda é `v0-rascunho`: nada de clientes reais antes do parecer jurídico.
- Qualidade do catálogo: a lista vem de um documento do Henrique, transcrita do protótipo, e as seguradoras variam (nota das Obras). Mitigação: o catálogo fica em dados editáveis (não em código) para corrigir sem nova versão.
- Custo de suporte: baixo (uso interno). Dúvidas previsíveis: "porque não posso criar pedido para este cliente?" (concessão) e "porque o cliente não recebeu nada?" (envio).
- Modelo demasiado ambicioso: preparar já origem, destinatários e propostas pode atrasar a 002. Mitigação: só tabelas e relações, sem lógica nem ecrãs.

**Decisões em aberto (para o gate 1):**

1. Envio do pedido ao cliente
   - A) Enviar já um email ao criar o pedido, com o link para a app (recomendado). Sem isto, o pedido não chega ao cliente e a 002 não é testável com um cliente real. Reaproveita o envio de email da 001.
   - B) Só registar na 002; o mediador avisa o cliente fora da app e o email chega na 003.
   - C) Email com link copiável, sem envio automático.
   - Recomendação: A, com um email curto (escritório, tipos pedidos, mensagem do mediador, link). Sem lista de documentos no email (evita duplicar a app e expor dados no email).

2. O que o cliente vê na app depois do pedido (antes da 003)
   - A) Ecrã mínimo só de leitura: pedidos em curso com tipo, etapa e a lista do que falta, sem carregar nada (recomendado).
   - B) Nada; o cliente só vê o convite e o consentimento da 001 até à 003.
   - C) Ecrã completo com carregamento (é a 003, não cabe aqui).
   - Recomendação: A, se a 002 e a 003 forem entregues perto uma da outra e o esforço for pequeno (a lista já existe). Se o prazo apertar, B. Em qualquer caso o email de A) da decisão 1 não pode apontar para um ecrã vazio.

3. Pedidos repetidos (mesmo cliente e mesmo tipo com pedido ainda em curso)
   - A) Aviso com confirmação ("já tens um pedido de Automóvel em curso, criar outro?") (recomendado).
   - B) Bloquear.
   - C) Permitir sem aviso.
   - Recomendação: A. Há casos legítimos (dois carros, duas casas), e bloquear gera suporte.

4. Condições particulares: ativas por omissão ou não
   - A) Desativadas por omissão, o mediador liga por pedido (recomendado, é o que está decidido: "o mediador ativa ou desativa por pedido").
   - B) Ativas por omissão.
   - C) Pergunta ao criar.
   - Recomendação: A.

**Veredicto:** avançar, com o âmbito acima. Não avançar com mais do que isto: sem a 003 o ganho de tempo não se mede, e cada extra (filtros, edição de lista, lembretes) adia o ciclo que valida o produto. A métrica de tempo poupado fica para depois da 003 e da 004.
