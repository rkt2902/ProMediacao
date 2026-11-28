# Renders da 002 Novo pedido (gate 2)

Referências visuais de cada ecrã, **antes** da implementação. HTML estático feito só com os tokens de `docs/design/DESIGN.md` (mais os propostos em `../03-design.md`, "Tokens propostos") e as fontes reais de `assets/fonts/`. O flutter-dev integra com os widgets de `lib/core/widgets/`; não copia o HTML.

- Tamanhos: telemóvel 390 × 844, tablet 768 × 1024, desktop 1280 × 800 (PNG a 2×). `-completo-` = página inteira (o que se vê com scroll; a barra fixa aparece no fim).
- Páginas em `src/`: um HTML por ecrã; o estado escolhe-se por parâmetro (ex.: `novo-pedido.html?estado=repetido`, `meus-pedidos.html?folha=notificacoes&lista=vazio`, `pedido.html?perfil=cliente&estado=retirado`). `estado.js` e `colofao.js` vêm da 001; `pedidos.css` tem os componentes novos; `catalogo.js` tem os 13 tipos e os fragmentos partilhados. Cortes 640 e 1100, como na app.
- **Gerar de novo:** `node docs/features/002-novo-pedido/renders/src/shoot.js [nomes separados por vírgula, aceita prefixo*]` (a lista está em `src/shots.js`; serve a raiz do repositório por HTTP local porque o Chromium bloqueia fontes em `file://`). Para abrir no navegador: `python3 -m http.server` na raiz e `http://localhost:8000/docs/features/002-novo-pedido/renders/src/novo-pedido.html`.
- Ícones: subconjunto da fonte Material Icons do Flutter (`src/fonts/`, Apache 2.0) com os mesmos codepoints de `Icons.*` (novos: `notifications_none`, `description_outlined`, `edit_note`, `chevron_right`, `search`, `radio_button_checked`).
- Dados fictícios (fixtures do `03-design.md`); emails em `exemplo.pt`.

## Para o gate 2 (um por ecrã)

| # | Ficheiro | O que mostra |
| --- | --- | --- |
| 1 | `novo-pedido-desktop.png` | Novo pedido: escolhas à esquerda, a folha "O cliente vai receber" à direita, barra "Criar 2 pedidos" |
| 2 | `novo-pedido-completo-telemovel.png` | O mesmo no telemóvel, página inteira (folha por baixo) |
| 3 | `novo-pedido-repetido-desktop.png` | Pedido repetido: aviso por baixo do tipo, "Criar 1 pedido" até confirmar |
| 4 | `novo-pedido-escolher-cliente-desktop.png` | Escolher o cliente: só ativos, e a lista diz porquê |
| 5 | `clientes-desktop.png` | Clientes com a coluna Pedidos e "Novo pedido" |
| 6 | `ficha-pedidos-criados-desktop.png` | Ficha depois de criar: "2 pedidos criados" e linhas novas com realce |
| 7 | `ficha-email-falhou-desktop.png` | Pedidos criados, email por enviar, "Reenviar email" |
| 8 | `meus-pedidos-telemovel.png` | Cliente: Os meus pedidos, sino com 2 |
| 9 | `pedido-cliente-completo-telemovel.png` | Cliente: o pedido, o que lhe pedem e as 4 etapas |
| 10 | `notificacoes-desktop.png` | Painel de notificações (por ler e lidas) |
| 11 | `email-pedido-telemovel.png` | Email do pedido (sem lista nem dados) |
| 12 | `fluxo-1-novo-pedido.png` | Storyboard do mediador (Clientes → pedido aberto) |

## Índice

Todos em `-telemovel`, `-tablet` e `-desktop`, salvo indicação.

### 1. Novo pedido (mediador)
| Ficheiros | Estado |
| --- | --- |
| `novo-pedido-*`, `novo-pedido-completo-*` | Populado (vindo da ficha): Vida e Automóvel, item tirado e acrescentado, condições particulares, mensagem |
| `novo-pedido-escolher-cliente-*` | Vindo de Clientes: pesquisa "Ma", só clientes com acesso ativo |
| `novo-pedido-sem-tipos-*` | Cliente escolhido, sem tipos: folha vazia tracejada, "Criar" desativado com a razão |
| `novo-pedido-repetido-*` (página inteira) | Tipo já em curso: aviso com "Criar outro na mesma" / "Tirar este tipo" |
| `novo-pedido-acrescentar-item-*` (página inteira) | Acrescentar item: texto + Documento / Dado a preencher |
| `novo-pedido-lista-vazia-*` (página inteira) | Todos os itens de Vida tirados: erro na folha, "Criar" desativado |
| `novo-pedido-a-carregar-*` | Catálogo a carregar: skeleton nos tipos e na folha |
| `novo-pedido-a-criar-*` | "A criar…" com spinner; escolhas inertes |
| `novo-pedido-erro-*` | Falha ao criar: nada criado, escolha mantida |
| `novo-pedido-sem-concessao-*` | O cliente retirou o acesso entre abrir e criar |
| `novo-pedido-erro-catalogo-*` | Tipos de seguro não carregaram |
| `novo-pedido-offline-*` | Offline: tudo editável, "Criar" desativado com a razão |
| `novo-pedido-sem-clientes-*` | Vazio: nenhum cliente com acesso ativo |
| `novo-pedido-sem-acesso-pendente-*`, `-recusada-*`, `-retirada-*` | Cliente sem concessão ativa: motivo e o que fazer |

### 2. Clientes (mediador, evolução da 001)
| Ficheiros | Estado |
| --- | --- |
| `clientes-*`, `clientes-completo-telemovel` | Populado: 4 colunas (largo), Estado e pedidos (médio), empilhado (compacto) |
| `clientes-a-carregar-*` | Skeleton com a coluna Pedidos |
| `clientes-erro-*` | Lista não carregou |
| `clientes-offline-*` | Offline: Novo pedido, Criar cliente e ações desativados |

O vazio e as folhas de Criar cliente são os da 001 (sem mudanças).

### 3. Ficha do cliente e pedido aberto (mediador)
| Ficheiros | Estado |
| --- | --- |
| `ficha-*`, `ficha-completo-telemovel` | Populado: 3 pedidos deste escritório |
| `ficha-pedidos-criados-*` | Sucesso: "2 pedidos criados", linhas novas com realce |
| `ficha-email-falhou-*` | Pedidos criados, email não enviado, "Reenviar email" |
| `ficha-email-reenviado-*` | Reenviado, bloqueado até 10:17 |
| `ficha-sem-pedidos-*` | Vazio: "Sem pedidos" + "Novo pedido" |
| `ficha-a-carregar-*`, `ficha-erro-*`, `ficha-offline-*` | A carregar, erro, offline |
| `ficha-sem-acesso-*` | Cliente de outro escritório, inexistente ou que retirou o acesso |
| `pedido-mediador-*`, `pedido-mediador-completo-telemovel` | Pedido aberto, só leitura |
| `pedido-mediador-a-carregar-*`, `pedido-mediador-erro-*` | A carregar, erro |

### 4 e 5. Os meus pedidos e o pedido (cliente)
| Ficheiros | Estado |
| --- | --- |
| `meus-pedidos-*`, `meus-pedidos-completo-telemovel` | Populado: em curso, acesso retirado, Com quem partilho |
| `meus-pedidos-vazio-*`, `-a-carregar-*`, `-erro-*`, `-offline-*` | Vazio, a carregar, erro, offline |
| `pedido-cliente-*`, `pedido-cliente-completo-telemovel` | Pedido: mensagem, o que lhe pedem, faixa de etapas |
| `pedido-cliente-acesso-retirado-*` | Escritório sem acesso: carimbo "Acesso retirado", sem ações |
| `pedido-cliente-a-carregar-*`, `-erro-*`, `-offline-*` | A carregar, erro, offline |
| `pedido-cliente-sem-acesso-*` | Pedido não encontrado (não é seu ou não existe) |

### 6. Sino e notificações (cliente)
| Ficheiros | Estado |
| --- | --- |
| `notificacoes-*` | 2 por ler + 2 lidas; folha lateral (tablet, desktop), ecrã inteiro (telemóvel) |
| `notificacoes-todas-lidas-*`, `notificacoes-vazio-*` | Todas lidas (sem contador); sem notificações |
| `notificacoes-a-carregar-*`, `notificacoes-erro-*`, `notificacoes-offline-*` | A carregar, erro, offline (último estado conhecido) |
| `sino-estados.png` | O sino na linha do separador: 0, 2, 9+, foco, aberto, compacto |

### 7. Email
| Ficheiros | Estado |
| --- | --- |
| `email-pedido-telemovel`, `-desktop` | Email do pedido com mensagem |
| `email-pedido-sem-mensagem-telemovel`, `-desktop` | Sem mensagem do mediador |

### Fluxos
| Ficheiro | Fluxo |
| --- | --- |
| `fluxo-1-novo-pedido.png` | Clientes → escolher cliente → tipos e lista → a criar → ficha → pedido aberto |
| `fluxo-2-cliente.png` | Email → Os meus pedidos → Notificações → pedido |
| `fluxo-3-excecoes.png` | Repetido → falha → email não enviado → reenviado (e ramos) |

## Não incluído

Escala de texto 1.3 e 320 de largura (ficam para os goldens do Modo 2). O estado "Vai ser criado um segundo pedido" (depois de confirmar o repetido) só está descrito no `03-design.md`.
