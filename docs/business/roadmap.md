# Roadmap dos pedidos

Aprovado pelo Henrique a 2026-11-27. Cada linha passa ainda pelo `/feature` (gates 1 a 4); esta é a ordem e o âmbito de partida.

## Modelo (três conceitos)

- **Pedido**: um cliente, um tipo de seguro e a lista automática do que pedir. Guarda a origem (`mediador` ou `cliente`) e o estado em 4 etapas (criado, documentos enviados, em análise, enviado às seguradoras).
- **Destinatário**: o escritório que recebe o pedido. Pedido do mediador: um só (o escritório dele). Pedido do cliente: um ou vários; cada escritório vê só o seu e nunca os outros (decisão de 2026-11-25).
- **Proposta**: a resposta de um escritório a um pedido (seguradora, prémio, coberturas, validade, PDF). Um pedido do cliente pode receber várias.

A 002 já cria o modelo preparado para a origem `cliente`, vários destinatários e propostas, para as features seguintes não precisarem de migrações destrutivas.

## Ecrãs

Mediador:
- **Novo pedido**: escolher o cliente e um ou vários tipos de seguro; a lista do que pedir é gerada.
- **Clientes**: lista com o estado dos pedidos de cada cliente; ficha do cliente com os seus pedidos.
- **Pedidos recebidos** de clientes, com "Responder com proposta" (006).

Cliente:
- **Os meus seguros**, por seguro; dentro, os pedidos e as propostas recebidas lado a lado (006).
- **Novo pedido**: tipos de seguro, escolher escritórios ou lançar anúncio (005, 007).
- **Ecrã do pedido**: o que falta enviar, a quem foi enviado, as propostas que chegaram.

## Sequência

| # | Feature | Para quê |
| --- | --- | --- |
| 002 | Novo pedido (mediador) + clientes com o estado dos pedidos | Base de pedidos e tipos de seguro |
| 003 | O cliente responde: carrega documentos ou condições particulares, com progresso | Arquivo reutilizável |
| 004 | Revisão do mediador, extração com IA e ficha (PDF e Excel) | Fecha o ciclo da fase A do piloto |
| 005 | O cliente inicia pedidos a escritórios que escolhe + registo sem convite + ecrã por pedido | Pedir a vários escritórios |
| 006 | Propostas: o escritório responde; o cliente vê o ecrã por seguro com as propostas | Receber vários orçamentos |
| 007 | Anúncio aberto com diretório de escritórios | Só depois do parecer jurídico |

Ciclo principal primeiro (002 a 004): é o que valida o produto na mediação do Henrique e mede o tempo poupado.

## Anúncio aberto (007)

- Os escritórios aderentes veem só um **resumo anónimo**: tipo de seguro, zona e dados gerais (por exemplo, faixa etária, tipo de veículo), sem nome, contactos nem documentos.
- Os interessados respondem "tenho interesse"; o cliente vê a lista e dá acesso a quem quiser, com o consentimento por escritório que já existe (`consent_grants`). Só aí os dados são partilhados.
- Depende do parecer jurídico (RGPD, dados de saúde; ASF, pergunta 11 de `research/08-juridico.md`), de um diretório de escritórios aderentes e do registo do cliente sem convite. Só faz sentido com vários escritórios (fase B do piloto).
- Mantém-se o modelo de receita: sem cobrança por lead nem comissão.
