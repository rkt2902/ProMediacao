# Pesquisa 02: modelo de receita e concorrentes

Data: 2026-11-25 · Autor: bizdev · Resolve a decisão 2 da secção 7 de `docs/business/context.md` e dá apoio à decisão 3.
Estado: **proposta**. Os números marcados como *estimativa* não foram medidos nem confirmados com fornecedores.

## 1. Concorrentes e alternativas

Limitações da pesquisa:
- fiz 5 pesquisas web;
- os sites capterra.pt e spendbase.co não abriram nesta sessão, porque estão fora dos domínios de rede permitidos;
- quase nenhum software de mediação publica preços.

Também não encontrei nenhum portal português de recolha de documentos feito para mediadores de seguros. Pode ser uma oportunidade, ou pode querer dizer que existe e não aparece online. O Henrique deve confirmar com colegas, por exemplo na APROSE.

| # | Quem | O que faz | Preço público | O que a ProDossier faz e eles não |
|---|---|---|---|---|
| 1 | **WhatsApp, email e papel** (o que se usa hoje) | É o mais usado: grátis e todos o conhecem. | 0 € | Tem uma lista por tipo de seguro, um arquivo reutilizável e uma ficha já extraída. **É este o concorrente a bater**: se poupar pouco tempo, ninguém muda. |
| 2 | **Insly** (Estónia, à venda em PT) | Software de gestão para corretores e MGAs: apólices, comissões, portal de cliente. | Preço inicial de 4.000 € na Capterra PT. Não diz se é mensual ou anual. | Faz só uma coisa: recolher e preparar a ficha. É muito mais barato e simples, e não precisa de migrar a carteira. |
| 3 | **ebroker** (Espanha) | ERP de distribuição de seguros para corredurías, com app móvel. | Sob orçamento. Vende por licença ou por SaaS. | Está pensada para o mediador pequeno em PT, com as listas PT por seguradora. O ebroker é para corretoras de média ou grande dimensão. |
| 4 | **Better Agency, EzLynx, NowCerts** (EUA) e **Softseguros** (América Latina) | CRM ou sistema de gestão para agências de seguros. | Não aparece nos resultados. | Não estão adaptados ao mercado PT nem às seguradoras PT, e não têm alojamento na UE garantido. São concorrentes só em teoria. |
| 5 | **CRM genéricos** (HubSpot, Pipedrive) | Gerem contactos e o funil de vendas. Têm modelos para seguros. | O HubSpot começa em cerca de 12 USD por utilizador e por mês. | Não recolhem documentos por tipo de seguro nem extraem dados. São complementares, não substitutos. |
| 6 | **Content Snare** (Austrália) | Portal genérico para pedir documentos e dados a clientes, com lembretes. Muito usado por contabilistas. | 29, 59, 99 ou 179 USD por mês, conforme o plano (Jotform). Há também um plano Lite de 9 USD por mês com 2 pedidos ativos (SpotSaaS, maio de 2026). Cobra pelos pedidos ativos. | Não traz listas de seguros, não extrai com IA nem gera a ficha, e não tem área de cliente com apólices. **É a referência de preço mais útil.** |
| 7 | **Klippa DocHorizon** (Países Baixos; segundo um diretório, agora Doxis AI.dp, informação não verificada) | API de OCR e extração de documentos com IA. | Sob orçamento: subscrição mais um valor por documento. | É uma peça técnica para empresas grandes. A ProDossier faz a mesma extração com um custo marginal de cerca de 0,001 USD (*estimativa*) e já dentro do fluxo do mediador. |

**Diferenciação defensável:**
1. Listas por tipo de seguro e por seguradora portuguesa (o "Documentos Seguros.pdf").
2. Atalho das condições particulares.
3. Documentos do cliente reutilizados entre pedidos.
4. Ficha pronta a introduzir nos portais das seguradoras.
5. Português de Portugal, RGPD e alojamento na UE.
6. Preço baixo, possível porque a IA custa quase nada.

**Fraqueza:** não há integração com os portais das seguradoras, porque continua a ser preciso introduzir os dados à mão. Um CRM grande pode copiar a recolha de documentos. A proteção está no conhecimento do terreno, não na tecnologia.

## 2. Custos de base (*estimativa*)

| Item | Ordem de grandeza |
|---|---|
| Supabase Pro (UE) | cerca de 25 USD por mês |
| IA (Haiku) | cerca de 0,001 USD por pedido, não medido. Com o modelo maior para digitalizações más, admito até 0,01–0,05 USD. Mesmo assim, 1.000 pedidos custam menos de 50 USD. |
| SMS para os links | cerca de 0,04–0,08 € por SMS, a confirmar no fornecedor. Pode custar mais do que a IA. |
| Domínio, email transacional, contas das lojas | cerca de 10–20 € por mês, em média |
| **Total fixo** | **cerca de 40–70 € por mês**, antes de suporte e jurista |

O custo que pesa não é a infraestrutura, são:
- o tempo do Henrique em suporte;
- a parte jurídica: o RGPD com dados de saúde, um acordo de subcontratante (DPA) com cada mediador e uma entidade jurídica para faturar.

## 3. Opções de receita

### A. Uso interno, sem cobrar
- **Como funciona:** só a mediação do Henrique usa a app. O valor está no tempo poupado.
- **Valor (*estimativa*):** com 40 pedidos por mês e 20–30 minutos poupados em cada um, são cerca de 13–20 horas por mês. O custo é de 40–70 € por mês.
- **Prós:**
  - não precisa de empresa, DPA com terceiros nem suporte;
  - permite validar a extração com documentos reais;
  - o risco legal é o mais baixo.
- **Contras:**
  - não há receita;
  - não prova que outros pagariam;
  - o desenvolvimento só se paga em tempo poupado.

### B. Subscrição mensal por escritório de mediação
- **Como funciona:** um preço fixo por escritório, com escalões pelo número de pedidos ativos, como faz o Content Snare. A proposta, ainda por testar, é:
  - Essencial: 29 € por mês, até 25 pedidos ativos;
  - Escritório: 59 € por mês, até 100 pedidos ativos e 3 utilizadores.
- **O cliente final nunca paga.**
- **Receita (*estimativa*):**
  - 10 escritórios a uma média de 40 € dão cerca de 400 € por mês;
  - 50 escritórios dão cerca de 2.000 € por mês;
  - a margem bruta fica acima de 90%.
- **Prós:**
  - é previsível e simples de explicar;
  - é o modelo a que os mediadores já estão habituados no software;
  - o preço fica muito abaixo dos sistemas de gestão completos.
- **Contras:**
  - 29 € por mês tem de competir com o WhatsApp, que é grátis;
  - obriga a ter empresa, faturação, DPA e suporte;
  - um mediador pequeno, com poucos pedidos, pode achar caro.

### C. Por pedido ou híbrido (base mais consumo)
- **Como funciona:** por exemplo, 0 € de base e 1,50 € por pedido concluído. Em alternativa, 15 € por mês com 10 pedidos incluídos e 1 € por cada pedido extra.
- **Receita (*estimativa*):** um escritório com 30 pedidos por mês paga cerca de 35–45 €, um valor parecido com o da opção B.
- **Prós:**
  - a barreira de entrada é baixa;
  - o preço acompanha o valor entregue;
  - serve para mediadores com volume sazonal.
- **Contras:**
  - a fatura muda todos os meses;
  - obriga a medir e faturar cada pedido;
  - pode levar o mediador a usar a app só nos pedidos difíceis, o que reduz o hábito;
  - **cuidado:** o preço não pode depender de apólices vendidas nem do prémio. Ver a secção 4.

## 4. Linhas vermelhas (secção 3 do contexto)

- **Não há comissão por apólice, percentagem do prémio, pagamento de seguradoras por leads nem "Comparar preços" com encaminhamento pago.** Qualquer destas formas liga a receita à distribuição de seguros. Isso pode fazer da ProDossier um distribuidor ou intermediário sujeito a registo na ASF (Lei 7/2019) e cria conflito de interesses. Um jurista tem de confirmar antes de considerar qualquer uma delas.
- **Não se cobra nada ao cliente final.** Faria a app parecer um serviço de seguros e prejudicaria a confiança.
- O crédito tem a mesma lógica com o Banco de Portugal (DL 81-C/2017): nunca cobrar por crédito concedido.

## 5. Recomendação por fases

1. **Fase 0, agora e até a app funcionar na mediação do Henrique: opção A.**
   - Medir o custo real de IA por pedido e o tempo poupado por pedido (cronometrar 10 pedidos com e sem a app).
   - Sem estes números, qualquer preço é um palpite.
2. **Fase 1, piloto com 3–5 mediadores conhecidos: opção B, grátis durante 3 meses, com o preço anunciado desde o primeiro dia.**
   - Os primeiros clientes ficam com o preço garantido, por exemplo 29 € por mês para sempre.
   - **Sinal de validação:** pelo menos 3 dos 5 aceitam pagar no fim do piloto e cada um usa pelo menos 8 pedidos por mês.
   - Se menos de 2 aceitarem pagar, não se abre a outros mediadores e volta-se à opção A.
3. **Fase 2, abertura: opção B com escalões por pedidos ativos.**
   - Isto já capta o lado bom da opção C sem tornar a fatura imprevisível.
   - Só se passa à opção C pura se o piloto mostrar que o problema é o volume baixo ou sazonal, e não o preço.

**Risco a resolver antes da fase 1:** a plataforma é de um mediador que concorre com os outros. Outros mediadores vão ter receio de que o Henrique veja os clientes deles. É preciso:
- uma entidade separada (ou pelo menos um DPA claro);
- o admin sem acesso ao conteúdo dos documentos de outros escritórios;
- isolamento por escritório, com RLS no Supabase.

Isto pesa mais na venda do que o preço.

## Fontes (pesquisas de 2026-11-25)

- Software de mediação em PT/PT:
  - [Capterra PT: Insly](https://www.capterra.pt/software/131631/insly)
  - [Capterra PT: Better Agency](https://www.capterra.pt/software/211611/better-agency)
  - [Capterra PT: EzLynx](https://www.capterra.pt/software/102928/ezlynx)
  - [Pipedrive: CRM para seguros](https://www.pipedrive.com/pt/industries/insurance-crm)
  - [Innowise: melhores CRM para seguros](https://innowise.com/pt/blog/melhor-crm-para-seguro/)
  - [ECO Seguros: CRM no setor segurador (mar. 2026)](https://eco.sapo.pt/2026/03/30/crm-da-base-de-dados-ao-motor-da-relacao-com-o-cliente)
- ebroker:
  - [softwaredoit.es: ebroker](https://www.softwaredoit.es/ebroker/ebroker.html)
  - [App Store: ebroker mobile](https://apps.apple.com/mx/app/ebroker-mobile/id6499311415)
- Softseguros:
  - [Capterra: Softseguros](https://www.capterra.com/p/241819/Softseguros/)
  - [Spendbase: Softseguros](https://www.spendbase.co/pt/discounts/softseguros/)
- Content Snare:
  - [Jotform: alternativas ao Content Snare](https://www.jotform.com/blog/content-snare-alternatives/)
  - [SpotSaaS: preços do Content Snare](https://www.spotsaas.com/product/content-snare/pricing)
  - [Capterra: preços do Content Snare](https://www.capterra.com/p/167019/Content-Snare/pricing/)
- Klippa:
  - [Klippa: pedido de preço](https://www.klippa.com/en/dochorizon/dochorizon-pricing-request)
  - [apis.io: perfil FinOps da Klippa](https://apis.io/finops/klippa/klippa-finops/)
  - [Krowdbase: Klippa DocHorizon](https://www.krowdbase.com/software/klippa-dochorizon)
- Os preços do Supabase, dos SMS e do HubSpot são de memória ou dos resumos das pesquisas e não foram confirmados nas páginas oficiais. Confirmar antes de fixar preços.
