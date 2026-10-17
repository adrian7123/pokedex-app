# Superfície: app Pokédex (shell + Pokédex, detalhe, Aventuras, Coleção, Consulta)

Modo: Operate. Plataforma: Flutter (Android primeiro, iOS junto). Build code-led.

Público e tarefa: jogador consultando no meio do jogo, uma mão, offline. Buscar, filtrar por jogo, ver como evolui no jogo ativo, carimbar captura (toque) / shiny (toque longo).

Restrições fixadas: só tema claro; neutro + cor do tipo como acento; mínimo/moderno; Hero lista→detalhe e shared-axis entre abas; respeitar reduzir animações; Material 3 para estrutura e controles; sem scroll lateral.

## Direction contract

THESIS: A Pokédex é uma cartela da Pokémon Stamp Rally da JR que você preenche. Recusa o padrão da categoria: cards saturados na cor do tipo com artwork estourando a borda.

OWN-WORLD: Papel quase branco (#FAFAF7) e rampa neutra fixa de 8 passos até a tinta #17171A; picote pontilhado no lugar de bordas e cards; carimbos circulares vetoriais em tinta translúcida na cor do tipo, levemente girados e desalinhados como borracha real; shiny em tinta ouro (#C9A227); gótica arredondada japonesa (M PLUS Rounded 1c) em só 5 tamanhos, hierarquia por peso; números tabulares.

STORY: O jogador vê de cara quanto da cartela da aventura já carimbou, acha qualquer Pokémon em segundos, entende a exigência exata de cada evolução no seu jogo e carimba com um toque.

FIRST VIEWPORT: Título "Pokédex" 30sp extra-bold à esquerda, alternância lista/grade à direita; linha da aventura ativa com barra fina e "88/151 carimbos"; campo de busca pílula 48dp; chips de filtro quebrando linha; lista sem caixas: anel de carimbo 52dp com sprite, nº tabular, nome 17sp bold, tipos como ponto+nome; NavigationBar M3 de 4 abas. Ação primária (carimbar) no próprio anel de cada linha.

FORM: Cartela de Stamp Rally, posição 6 de 7 na lista; seed: none (unavailable). Movimento-assinatura: o carimbo — pressão (escala 1.0→0.94→1.0 com spring), tinta assenta (opacidade+blur→nítido) com rotação aleatória ±8°; ouro com brilho curto no shiny. Raises: uma exigência por linha na evolução e nº monumental no detalhe (sinalização); reordenação animada preservando a linha (painel de portões); escala de tipo curta (horário); sem cromo/caixas (Metro); deslizar entre vizinhos da dex (feed); neutros só da rampa (ficha de exposição).

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
