# Pesquisa 01: nome e marca

Data: 2026-11-25 · Autor: bizdev · Resolve a decisão 1 da secção 7 de `docs/business/context.md`.
Estado: **proposta**. Nada está verificado no INPI nem no DNS.pt; isso cabe ao Henrique (ver secção 4).

## 1. Critérios

1. Não pode ser só de seguros: o crédito vem a seguir.
2. Não pode fazer a app parecer seguradora, banco ou mediador registado. A app é uma ferramenta do mediador (ASF, Lei 7/2019; Banco de Portugal, DL 81-C/2017).
3. Tem de ser registável como marca: nomes descritivos ("mediação", "finanças", "seguros") são fracos no INPI e difíceis de defender.
4. Fácil de dizer e escrever em PT, com domínio .pt sem acentos.

## 2. Opções

### A. ProMediação (nome atual do repo)

- **Indícios na web:** não encontrei empresa nem app chamada "ProMediação". Há dezenas de "… Mediação Imobiliária, Lda." com prefixos parecidos (Proveco, Proeza), e "mediação" também é mediação de conflitos (Lei 29/2013).
- **Domínio:** não consegui testar: `promediacao.pt` e `promediacao.com` não resolveram nesta sessão, o que pode querer dizer que estão livres ou que a rede da sessão os bloqueia. Fica inconclusivo.
- **Prós:** o mediador percebe logo para quem é. O repo e o package id (`pt.promediacao.promediacao`) já usam este nome.
- **Contras:**
  - "Mediação" é exatamente o nome da atividade regulada. Um cliente final pode achar que a app é o mediador.
  - Não serve para o crédito, onde o termo legal é "intermediação de crédito".
  - É genérico: "Pro" + palavra descritiva tem pouca distintividade no INPI, e fica confundível com o imobiliário.
  - O "ç" obriga a usar `promediacao` no domínio e no email.
- **Lei 7/2019:** não confirmei se a lei reserva o uso de "mediação/mediador de seguros" em firmas ou marcas a entidades registadas na ASF. Isto tem de ser visto por um jurista antes de adotar a opção A.

### B. ProDossier (sugerido no planeamento; o protótipo já se chama "Dossier")

- **Indícios na web:** não encontrei empresa nem app "ProDossier". Os nomes próximos são "Dossier Mobile" (Dossier Systems, EUA, App Store) e "PRO.FILE" (PROCAD, PLM alemão), ambos de outra área.
- **Domínio:** `prodossier.pt` e `prodossier.com` não resolveram nesta sessão. Fica inconclusivo.
- **Prós:**
  - É neutro: serve para seguros, crédito e qualquer processo com documentos.
  - Descreve o que o produto entrega, que é o dossier do cliente pronto a usar.
  - Não tem nenhum termo regulado e não tem acentos.
  - É coerente com o protótipo que já foi mostrado.
- **Contras:**
  - "Dossier" é grafia francesa/inglesa (em PT-PT é "dossiê"), mas é de uso corrente.
  - O prefixo "Pro" é muito usado, o que dá distintividade média.
  - "Dossier" sozinho é uma palavra comum, por isso a proteção vem do conjunto "ProDossier" e do logótipo.

### C. Reúne (alternativa minha)

- **Ideia:** o verbo diz o que a app faz, que é reunir os documentos e dados do cliente num só sítio, sem dizer de que produto financeiro se trata. É curto e português.
- **Indícios na web:** não encontrei app nem empresa "Reúne". A palavra aparece apenas como verbo em textos do gov.pt (Bolsa de Documentos, Carteira Digital da Empresa), num espaço vizinho.
- **Domínio:** `reune.pt` não resolveu nesta sessão. Fica inconclusivo. Por ser uma palavra comum e curta, é provável que o .com esteja ocupado.
- **Prós:**
  - É o mais distintivo para o cliente final.
  - Não tem termos regulados e funciona para seguros e crédito.
  - Soa a produto de consumo, o que ajuda na área do cliente.
- **Contras:**
  - O acento obriga a escrever `reune` no domínio, o que pode confundir.
  - É um verbo comum, por isso o registo pode exigir marca figurativa (logótipo).
  - Não diz ao mediador para que serve: precisa de um descritor, por exemplo "Reúne · documentos para mediadores".
  - Obriga a mudar o nome do repo, do package id e do protótipo.

### Descartada: ProFinanças

- Lembra o Portal das Finanças (AT), o que cria confusão e desconfiança num portal que pede documentos pessoais.
- Há marcas fortes no mesmo campo, como o Doutor Finanças (intermediário de crédito registado no BdP).
- Aponta mais para o crédito do que para os seguros, que são o núcleo atual.
- É descritivo e fraco no INPI.

## 3. Recomendação

**B: ProDossier.** É a opção que cumpre os quatro critérios com menos risco:

- é neutra entre seguros e crédito;
- não tem nenhum termo regulado;
- já é reconhecida pelo protótipo.

A opção C fica como plano B, se o INPI ou o DNS.pt mostrarem conflito com ProDossier.

A opção A só deve ser escolhida se um jurista confirmar que "mediação" no nome não cria problema com a ASF. Mesmo nesse caso, continua a não servir para o crédito.

O repo e o package id podem continuar `ProMediacao` / `pt.promediacao` como nome interno: mudar o nome visível não obriga a mudá-los já. Convém decidir isto antes de publicar nas lojas, porque depois o package id fica fixo.

## 4. O que o Henrique tem de verificar (não consegui fazer online)

1. **INPI** (servicosonline.inpi.pt, pesquisa de marcas): procurar o nome exato e as variantes (por exemplo "Pro Dossier", "Dossier", "Reune"). Fazer o mesmo no **TMview/EUIPO**, que cobre as marcas da UE válidas em Portugal. As classes de Nice relevantes são:
   - **9:** software;
   - **42:** SaaS;
   - **35:** gestão de documentos e negócios;
   - **36:** seguros e serviços financeiros, onde deve evitar reivindicar mais do que precisa.
2. **DNS.pt** (pesquisa WHOIS de domínios): ver se `prodossier.pt`, `reune.pt` e `promediacao.pt` estão livres. Ver os `.com` num registrador (por exemplo o WHOIS da ICANN).
3. **Registo Nacional de Pessoas Coletivas:** se for criar uma empresa ou mudar a firma, pedir o certificado de admissibilidade com o nome escolhido.
4. **Lojas e redes:** ver a App Store, o Google Play e o handle no Instagram e no LinkedIn.
5. **Jurista (só para a opção A):** confirmar se a Lei 7/2019 ou a Norma ASF 13/2020-R restringem o uso de "mediação" em marcas de terceiros que não estão registados como mediadores.

## Fontes

Todas as pesquisas foram feitas a 2026-11-25. Nenhuma mostrou uso dos nomes exatos.

- Pesquisa "ProMediação":
  - [iberinform: Proveco](https://www.iberinform.pt/empresa/24302455/proveco-sociedade-de-mediacao-imobiliaria-lda)
  - [gov.pt: pesquisar empresa de mediação imobiliária](https://www.gov.pt/servicos/pesquisar-uma-empresa-de-mediacao-imobiliaria)
- Pesquisa "ProDossier":
  - [App Store: Dossier Mobile](https://apps.apple.com/es/app/dossier-mobile/id1310696004)
  - [App Store: PRO.FILE FLEX](https://apps.apple.com/es/app/pro-file-flex/id1593399541)
- Pesquisa "Reúne": [gov.pt: Bolsa de Documentos](https://www.gov.pt/plataformas-digitais/bolsa-de-documentos)
- Pesquisa "ProFinanças": [Portal da Queixa: Doutor Finanças](https://portaldaqueixa.com/brands/doutor-financas)
- Lei 7/2019: [Diário da República](https://diariodarepublica.pt/dr/detalhe/lei/7-2019-117821873) e [ECO: o que muda com o novo regime](https://eco.sapo.pt/descodificador/o-que-muda-na-distribuicao-de-seguros-com-novo-regime/). Não encontrei a regra sobre a denominação.
- Domínios: os pedidos diretos a promediacao.pt/.com, prodossier.pt/.com e reune.pt falharam por DNS nesta sessão. O resultado é inconclusivo: para testar a partir da sessão, estes hosts teriam de ser permitidos nas definições de rede.
