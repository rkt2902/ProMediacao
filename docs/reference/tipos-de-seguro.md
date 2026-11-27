# Tipos de seguro e o que pedir ao cliente

Fonte: documento "Documentos Seguros" do Henrique, tal como transcrito no protótipo (https://claude.ai/artifact/MWLvfyRNXQu6L1N4KngYY6, extraído a 2026-11-27). É o catálogo inicial da lista automática da feature 002. Legenda: **D** = documento a carregar; **I** = dado a preencher.

Blocos reutilizados:
- **CC**: D · Cartão de Cidadão (NIF, nome completo, data de nascimento)
- **CC tomador**: D · Dados do tomador (Cartão de Cidadão)
- **Morada**: I · Morada
- **Imóvel**: I · Morada do risco, se diferente da do tomador · I · Área em m², n.º de WC e assoalhadas · I · Capital do edifício · I · Capital do recheio · D · Caderneta predial do imóvel · I · Ano de construção · I · Ano das obras (canalização, eletricidade, etc.)
- **Nota saúde**: "Se tiver problemas de saúde: todos os exames e relatórios recentes da patologia."

| # | Tipo | Itens | Nota |
| --- | --- | --- | --- |
| 1 | Vida | CC · Morada · I Capital seguro ou em dívida · I Profissão · I Prazo | Nota saúde |
| 2 | Vida Habitação | CC · Morada · I Capital seguro ou em dívida · I Taxas do empréstimo · I Prazo · I Profissão · D Exames e relatórios médicos (se aplicável) | Nota saúde |
| 3 | Doenças Graves | CC · Morada · I Capital seguro · I Profissão · I Prazo | Pode ser incluído no Seguro de Vida ou contratado em separado |
| 4 | Multirriscos Habitação | CC · Imóvel | |
| 5 | Multirriscos Negócio | CC tomador · I CAE · Imóvel | Capital do recheio enquadrado na atividade exercida no espaço e no seu conteúdo |
| 6 | Saúde | CC tomador · Morada · I Data de nascimento de todas as pessoas a incluir · I Coberturas e capitais pretendidos | Para menores, o tomador é a mãe ou o pai. Com seguro de saúde há mais de 2 anos é possível transferir os períodos de carência |
| 7 | Acidentes Pessoais | CC tomador · Morada · I Coberturas pretendidas · I Profissão | Individual ou de grupo |
| 8 | Automóvel | CC tomador · Morada · D Carta de condução · D Documento Único Automóvel (DUA / livrete) · I Coberturas pretendidas · I Franquias (danos próprios) | Se o condutor for diferente do tomador, pedir também o CC, a carta de condução e a morada do condutor |
| 9 | Acidentes de Trabalho (prémio fixo) | D Dados do tomador (empresa) · Morada · I CAE · I Nome e data de nascimento dos trabalhadores · D Recibos de vencimento (horas, salário base, subsídios) · D Apólice em vigor | Pedir a apólice em vigor |
| 10 | Acidentes de Trabalho (prémio variável) | D Dados do tomador (empresa) · Morada · I CAE · I Massa salarial · D Apólice em vigor | Pedir a apólice em vigor |
| 11 | Pets | CC tomador · D Livro do animal e micro-chip · I Tipo de atividade do animal (companhia, provas desportivas, etc.) | |
| 12 | Responsabilidade Civil | D Dados do tomador (CC para trabalhadores independentes) · Morada · I CAE | |
| 13 | Obras | D Dados do tomador (CC para particulares) · I Morada da obra · D Plantas · D Orçamentos · D Caderno de encargos · D Memória descritiva da obra · I Percentagem de obra realizada | Os documentos pedidos variam de seguradora para seguradora |

Opção em todos os tipos: o cliente pode enviar as **condições particulares** da apólice atual em vez dos documentos um a um (o mediador ativa ou desativa por pedido).

Do protótipo, ecrã Novo pedido do mediador: cliente, grelha dos 13 tipos, caixa "Permitir condições particulares", mensagem opcional, e ao lado "O cliente vai receber" com a nota do tipo e a lista (Documento / Dado). Estados no painel: À espera do cliente, Pronto para exportar, Exportado; etiqueta "Pedido pelo cliente". Cliente: 4 etapas (Pedido criado, Documentos enviados, Em análise pelo mediador, Enviado às seguradoras).
