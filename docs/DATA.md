# Camada de dados embutida

O app traz um SQLite somente leitura, `assets/db/pokedex.sqlite`, gerado a partir dos CSV oficiais da PokeAPI. Também traz sprites pequenos (96×96) em `assets/sprites/`. Tudo o que o app filtra e busca offline sai daqui. Flavor text, artwork oficial e renders do HOME **não** vão embutidos: o app busca na API quando precisa e guarda em cache.

## Como gerar

```bash
# 1. CSVs da PokeAPI (git sparse checkout em .cache/, uma vez)
git clone --depth 1 --filter=blob:none --sparse https://github.com/PokeAPI/pokeapi.git .cache/pokeapi-csv
git -C .cache/pokeapi-csv sparse-checkout set data/v2/csv
#    (sem esse checkout, o script baixa os CSV via urllib no commit POKEAPI_REF)

# 2. Banco
python3 tool/build_db.py

# 3. Sprites (lê o banco; no fim chama build_db.py --sprites-only)
bash tool/fetch_sprites.sh
```

- `tool/build_db.py` usa só a stdlib do Python 3 (csv, sqlite3, urllib). Ele grava em `.tmp`, roda `ANALYZE` e `VACUUM` e troca o arquivo de forma atômica. Se o diretório `assets/sprites/` existir, as flags de sprite já saem preenchidas.
- `tool/fetch_sprites.sh` faz um partial clone esparso (`--filter=blob:none --sparse`, padrões no-cone) de `PokeAPI/sprites` em `.cache/pokeapi-sprites`. Ele copia só os ids/itens que existem no banco e apaga PNGs de 0 byte.
- `.cache/` fica fora do git. Nada vai para `/tmp`.

### Build verificado

| | |
|---|---|
| PokeAPI (`meta.pokeapi_sha`) | `5ee47a9a9c1229632ec4b473a9c1c53026e005dd` (2026-10-16) |
| PokeAPI/sprites (`meta.sprites_sha`) | `289e842364648ec0495ae4ba12f48d5cbfbf670b` |
| `pokedex.sqlite` | 25,6 MiB (≈6,9 MiB em gzip, que é o que pesa no APK), `schema_version` 2 |
| Sprites | 2,9 MiB de Pokémon (1342 normais + 1342 shiny) + 0,5 MiB de itens (151) |
| Conferência | 1025 espécies, 1351 pokémon; dex lumiose-city 232, hyperspace 132, kitakami 200, paldea 400, blueberry 243; 8116 linhas em `evolution_version_groups`; 100 MTs no BDSP |

Quase todo o tamanho do banco vem dos learnsets: 638 mil linhas, ≈10 MiB de tabela mais ≈9 MiB do índice por golpe. Os encontros ocupam ≈5 MiB com índices. Todo o resto soma menos de 1,5 MiB.

## Convenções

- Os ids são os mesmos da PokeAPI em todas as tabelas, então dá para cruzar com a API on-line (`/pokemon/{id}`, `/pokemon-species/{id}`...).
- Nomes (`name`) em inglês, porque a PokeAPI não tem pt-BR. A exceção é `types.name_pt`. Quando falta o nome en, o script usa o identifier humanizado (`koraidon-limited-build` vira "Koraidon (Limited Build)").
- Booleanos são `INTEGER` 0/1. Campo ausente é `NULL`, nunca string vazia.
- `version_group` é a unidade de jogo da PokeAPI: Sword e Shield formam um grupo, The Isle of Armor é outro. `version` é o cartucho (sword, shield). Learnsets, máquinas e regras de evolução vêm por version group; encontros vêm por version.
- Os sprites têm caminho fixo e o banco guarda só a flag:
  - `assets/sprites/pokemon/{pokemon.id}.png` (`pokemon.has_sprite`);
  - `assets/sprites/pokemon/shiny/{pokemon.id}.png` (`has_shiny_sprite`);
  - `assets/sprites/items/{items.identifier}.png` (`items.has_sprite`, só itens de evolução e megapedras).

## Tabelas

### Metadados

**meta** (`key`, `value`)

| key | valor |
|---|---|
| `schema_version` | versão do schema (hoje `2`); o app deve recopiar o asset quando mudar |
| `built_at` | ISO-8601 UTC do build |
| `pokeapi_sha`, `pokeapi_commit_date`, `source` | origem dos CSV |
| `sprites_sha`, `sprites_checked` | origem dos sprites; `1` se as flags foram conferidas |
| `missing_sprites`, `missing_shiny_sprites`, `missing_item_sprites` | ids separados por vírgula |
| `encounters_raw_rows` | linhas de `encounters.csv` antes da agregação |

### Jogos, regiões e dex

| Tabela | Colunas | Observações |
|---|---|---|
| `regions` | id, identifier, name | 11 (inclui orre) |
| `generations` | id, identifier, name, main_region_id | 9 |
| `version_groups` | id, identifier, **name** (curado: "Sword / Shield", "Legends: Z-A"...), generation_id, sort_order (ordem cronológica da PokeAPI), **parent_id** (DLC/variante → jogo base), **is_dlc**, **is_closed_dex**, **national_dex_size**, **has_mega_evolution**, **route_source** | 32. DLC: isle-of-armor e crown-tundra → sword-shield; teal-mask e indigo-disk → scarlet-violet; mega-dimension → legends-za. Variantes JP red-green-japan e blue-japan → red-blue (parent, sem is_dlc). Colunas curadas abaixo. |
| `versions` | id, version_group_id, identifier, name, **parent_version_id** | 53. `parent_version_id`: versão de DLC → cartucho base (the-isle-of-armor-shield → shield, the-teal-mask-violet → violet, mega-dimension → legends-za...). Nomes das versões japonesas curados: "Red (Japan)", "Green (Japan)", "Blue (Japan)" |
| `version_group_regions` | version_group_id, region_id, source | `source`: `pokeapi` (CSV), `pokedex` (deduzido das dex do jogo; é o caso de Z-A), `parent`/`dlc` (herdado entre DLC e jogo base) |
| `pokedexes` | id, identifier, name, region_id, is_main_series, size | 35; `size` é a quantidade de espécies |
| `pokedex_version_groups` | pokedex_id, version_group_id | dex de cada jogo/DLC. Z-A: lumiose-city (34) + hyperspace (35); mega-dimension: hyperspace. A dex `national` não está ligada a nenhum jogo (use `national_dex_size`) |
| `pokedex_entries` | pokedex_id, species_id, number | PK (pokedex_id, species_id); número regional |
| **`pokedex_entry_forms`** | pokedex_id, species_id, pokemon_id, is_primary, source | Qual variedade (`pokemon.id`) aparece em cada entrada de dex. Exatamente uma `is_primary=1` por entrada (8010 entradas, 8055 linhas). Ver abaixo |
| **`version_group_species`** | version_group_id, species_id, in_regional_dex, has_encounters, in_national_dex | "Disponível no jogo" (11.546 linhas). Ver abaixo |

Colunas curadas de `version_groups` (constantes no topo de `tool/build_db.py`):

| Coluna | Significado |
|---|---|
| `is_closed_dex` | 1 nos jogos em que só existem as espécies das dex do jogo (+DLC) e as que têm encontro: Let's Go, Sword/Shield (+DLC), Legends: Arceus, Scarlet/Violet (+DLC), Z-A (+Mega Dimension) e Champions. Nos demais, os dados do jogo têm todas as espécies até a geração dele (troca/transferência) |
| `national_dex_size` | tamanho da Dex Nacional do jogo: 151 (RB/Y), 251 (GS/C), 386 (RS/E/FRLG), 493 (DP/Pt/HGSS/**BDSP**), 649 (BW/B2W2), 721 (XY/ORAS). NULL nos jogos sem Dex Nacional (Colosseum/XD, SM/USUM e todos desde Let's Go, exceto BDSP) |
| `has_mega_evolution` | 1 em X/Y, ORAS, Sun/Moon, USUM, Let's Go, Legends: Z-A, Mega Dimension e Champions. Megas (`pokemon.is_mega`) só devem aparecer como formas obtíveis nesses jogos |
| `route_source` | de onde sai a lista de rotas do Nuzlocke: `encounters` (áreas com encontro nas versões do jogo e dos DLCs), `region-locations` (sem encontros na PokeAPI: `locations` da região do jogo; BDSP, Legends: Arceus, Scarlet/Violet + DLC) ou `free-text` (Z-A, Mega Dimension e Champions: a PokeAPI não tem as Wild Zones de Lumiose, e o fallback por região listaria as rotas de X/Y; o app usa só texto livre, com aviso) |

**`pokedex_entry_forms`**: a regra é que, numa dex regional de Alola (as 10 dex de SM/USUM), Galar (galar, isle-of-armor, crown-tundra), Hisui ou Paldea (`paldea`), a variedade com `pokemon.regional` igual à região é a primária (a de menor id quando há várias, como `tauros-paldea-combat-breed`). Nas outras dex, a primária é a variedade padrão. `source` diz de onde veio a linha:

- `default`: variedade padrão (espécies sem forma regional têm só essa linha);
- `regional-dex`: forma regional da região da dex (inclusive as outras raças do Tauros de Paldea);
- `encounter`: outra variedade (padrão ou regional) com encontro nas versões do jogo da dex. Exemplos: Meowth de Kanto na dex de Galar, Slowpoke de Kanto na do IoA, formas de Alola na dex de Let's Go;
- `curated`: coexistência sem dado de encontro na PokeAPI. Hoje só o Sneasel de Johto em Hisui.

Só entram a variedade padrão e as formas regionais. As demais variedades (Rotom, raças, tamanhos do Pumpkaboo...) seguem em `pokemon` por espécie. Kitakami e Blueberry têm `region_id = paldea` na PokeAPI, mas ficam com a variedade padrão como primária, porque não são Paldea (Blueberry tem Tauros de Kanto) e não há encontros para confirmar as formas de lá.

**`version_group_species`**: uma linha por espécie disponível no jogo, com três flags. `in_regional_dex` vem das dex do jogo (o jogo base já inclui as dex dos DLCs, como na PokeAPI). `has_encounters` vem dos encontros nas versões do jogo, e o jogo base soma os dos DLCs. `in_national_dex` vale 1 quando `species.id <= national_dex_size`. Para o filtro, o app deve mostrar dois filtros distintos: "Dex regional" (`in_regional_dex = 1`) e "Disponível no jogo" (qualquer linha). Em FireRed/LeafGreen são 151 espécies na dex de Kanto, 386 disponíveis, e 41 têm encontro fora da dex (Togepi, Sneasel, Lugia...). Em SM/USUM e Colosseum/XD (sem Dex Nacional, mas com troca), a tabela tem só dex + encontros.

### Espécies e Pokémon

**species**: id, identifier, name, genus, generation_id, evolution_chain_id, evolves_from_species_id, is_legendary, is_mythical, is_baby, gender_rate (−1 = sem gênero; senão, oitavos de chance de ser fêmea), capture_rate, base_happiness, hatch_counter, growth_rate_id, color_id, shape_id, habitat_id, has_gender_differences, forms_switchable, sort_order (ordem nacional com agrupamento de família da PokeAPI).

Lookups `colors`, `shapes`, `habitats`, `growth_rates` e `egg_groups` têm (id, identifier, name). Grupos de ovo de cada espécie ficam em `species_egg_groups (species_id, egg_group_id)`.

**species_categories** (species_id, category, note): curadoria do script, com fonte Bulbapedia e ids conferidos contra o identifier no build.

| category | note | conteúdo |
|---|---|---|
| `ultra-beast` | — | 11: Nihilego…Guzzlord, Poipole, Naganadel, Stakataka, Blacephalon |
| `paradox` | `ancient` / `future` | 10 + 10 (Great Tusk…Raging Bolt / Iron Treads…Iron Crown) |
| `paradox` | `ancient-legendary` / `future-legendary` | Koraidon, Miraidon (a Bulbapedia os trata como paradoxo) |
| `starter` | `base` / `evolution` | as 27 linhas iniciais completas (81 espécies). Decisão: o filtro "inicial" mostra Charmander **e** Charizard; `note='base'` isola o primeiro estágio |
| `starter` | `partner` | Pikachu (Yellow/Let's Go Pikachu) e Eevee (Let's Go Eevee), só a espécie; Raichu e eeveeluções não entram |
| `pseudo-legendary` | `final` / `pre-evolution` | 10 linhas (Dratini, Larvitar, Bagon, Beldum, Gible, Deino, Goomy, Jangmo-o, Dreepy, Frigibax). A definição estrita é o estágio final (BST 600), use `note='final'` |

As categorias lendário, mítico e bebê vêm das flags de `species`. As categorias mega, gigantamax e regional vêm das flags de `pokemon`.

**pokemon** (variedades: 1025 padrão + 326 alternativas)

| Coluna | Significado |
|---|---|
| id, species_id, identifier | `10034 / 6 / charizard-mega-x` |
| name | nome de exibição en: espécie para o padrão; para formas, `pokemon_name` da PokeAPI ("Mega Charizard X", "Alolan Raichu", "Gigantamax Venusaur", "Paldean Tauros (Combat Breed)") |
| form_name | rótulo da forma ("Galarian Form", "Mega Charizard X"), pode ser NULL |
| is_default | variedade padrão da espécie |
| height, weight | decímetros e hectogramas (como na PokeAPI) |
| base_experience, sort_order | |
| type1_id, type2_id | tipos atuais (slot 1/2) |
| hp, attack, defense, sp_attack, sp_defense, speed, total | stats base |
| ev_* | EV dado ao derrotar |
| ability1_id, ability2_id, hidden_ability_id | habilidades (slots 1, 2, 3/oculta) |
| is_mega | forma mega (inclui as megas de Z-A) |
| is_gmax | `-gmax` |
| regional | `alola` / `galar` / `hisui` / `paldea` / NULL. Bonés do Pikachu (`pikachu-alola-cap`) e totens (`raticate-totem-alola`, `marowak-totem`) **não** contam |
| is_totem | formas Totem de SM/USUM (`-totem`, 12). Não são capturáveis; o app deve escondê-las das listas de formas |
| is_alternate_form | `NOT is_default` |
| is_battle_only | megas, gmax, formas de batalha |
| has_sprite, has_shiny_sprite | arquivo presente em assets |

O índice `pokemon_species_idx` serve para listar as formas de uma espécie.

**pokemon_forms**: id, pokemon_id, identifier, form_identifier, name, form_name, is_default, is_battle_only, is_mega, introduced_in_version_group_id, form_order, sort_order. Cobre as 1579 formas, inclusive as cosméticas que não são variedade (letras do Unown, padrões do Vivillon, cremes da Alcremie). As regras de evolução apontam para `pokemon_forms.id` (`required_pokemon_form_id` e `evolved_pokemon_form_id`).

`introduced_in_version_group_id` das megas novas de Z-A: a PokeAPI marca as 49 com 31 (Mega Dimension). O build remapeia para **30** (Legends: Z-A) as 26 do jogo base: Clefable, Victreebel, Starmie, Dragonite, Meganium, Feraligatr, Skarmory, Froslass, Emboar, Excadrill, Scolipede, Scrafty, Eelektross, Chandelure, Chesnaught, Delphox, Greninja, Pyroar, Floette, Malamar, Barbaracle, Dragalge, Hawlucha, Zygarde, Drampa e Falinks. As 23 formas das 19 espécies do DLC continuam em 31. Fonte: Serebii ("Legends: Z-A Mega Evolutions") e a lista do DLC da Destructoid, que bate com as 49 da PokeAPI; o build falha se algum identifier sumir.

**form_conditions** (pokemon_form_id, trigger_id, item_id, ability_id, move_id, base_form_id) e **form_triggers**: o que muda a forma. Pode ser item segurado (megapedra → mega), item consumido, item-chave, habilidade, fator gigantamax ou golpe. Exemplo: Mega Charizard X ← Charizardite X. A tabela não tem jogo. Para saber se a mega existe no jogo, use `version_groups.has_mega_evolution` e `pokemon_forms.introduced_in_version_group_id`. A Mega Rayquaza não tem condição na PokeAPI, e o build acrescenta `trigger = move`, `move_id = 620` (Dragon Ascent). Com isso, as 97 megas têm condição.

**pokemon_types_past** (pokemon_id, generation_id, slot, type_id): tipos antigos, válidos **até** `generation_id` inclusive. Exemplo: Clefairy era Normal até a gen 5.

**pokemon_stats_past** (pokemon_id, generation_id, stat, base_stat): o mesmo para stats. `stat='special'` só aparece na gen 1.

**pokemon_abilities_past**: o mesmo para habilidades (`ability_id` NULL quando o slot não existia).

### Habilidades

- **abilities**: id, identifier, name, short_effect, effect_is_flavor, generation_id. São 314, as da série principal mais qualquer outra usada por um Pokémon. Todas têm `short_effect` vindo de `ability_prose`.
- **pokemon_abilities**: pokemon_id, slot, ability_id, is_hidden. PK (pokemon_id, slot), mais um índice por `ability_id` para o filtro avançado.

### Tipos

- **types**: id, identifier, name, **name_pt**, generation_id. Só os 18 tipos jogáveis. Normal, Fogo, Água, Planta, Elétrico, Gelo, Lutador, Venenoso, Terrestre, Voador, Psíquico, Inseto, Pedra, Fantasma, Dragão, Sombrio, Aço, Fada. Stellar, unknown e shadow ficam de fora.
- **type_efficacy**: attacking_type_id, defending_type_id, factor. Tabela 18×18 completa (324 linhas, inclusive as de 100) com valores 0/50/100/200. Para dois tipos, o fator final é `f1 * f2 / 100` (0, 25, 50, 100, 200, 400).
- **type_efficacy_past**: as 6 linhas que mudaram, válidas até `generation_id`. Na gen 1, Venenoso↔Inseto era 200 e Fantasma→Psíquico era 0. Até a gen 5, Aço resistia a Fantasma/Sombrio.

### Itens

- **items**: id, identifier, name, category_id, short_effect, effect_is_flavor, is_holdable, is_evolution_item, is_mega_stone, has_sprite. São 2223, todos os itens da PokeAPI (custa ≈200 KiB).
  - `is_evolution_item`: usado como gatilho, item segurado ou incenso de bebê em alguma regra (59 itens).
  - `is_mega_stone`: categoria `mega-stones` (92, incluindo as de Z-A).
  - `is_holdable`: flags holdable da PokeAPI (incompletas), itens segurados de evolução e megapedras.
- **item_categories**: id, identifier, name, pocket_id.

### Golpes e learnsets

- **moves**: id, identifier, name, type_id, power, pp, accuracy, priority, damage_class_id (`damage_classes`: 1 status, 2 physical, 3 special), generation_id, effect_chance, short_effect, effect_is_flavor. São 919; os golpes Shadow de Colosseum/XD (ids ≥ 10000) ficam de fora. `$effect_chance` já vem resolvido no texto. `power` e `accuracy` NULL significam "—" (status, poder variável, nunca erra). A PokeAPI grava 0 em 18 golpes da gen 8/9 (Tachyon Cutter, Hard Press, Snowscape...), e o build converte esse 0 para NULL. Nenhum golpe tem poder 0 nem precisão 0%.
- **move_methods**: id, identifier, name. São 1 level-up, 2 egg, 3 tutor, 4 machine, 5 stadium-surfing-pikachu, 6 light-ball-egg, 7 colosseum-purification, 8 xd-shadow, 9 xd-purification, 10 form-change, 11 zygarde-cube e 12 train (Champions).
- **learnsets** (WITHOUT ROWID): pokemon_id, version_group_id, method_id, level (0 quando o método não é level-up), move_id, sort_order, mastery (nível de maestria em Legends: Arceus).
  - PK (pokemon_id, version_group_id, method_id, level, move_id) responde a "golpes do Pokémon Y no jogo Z", já em ordem de método e nível.
  - O índice `learnsets_move_idx (move_id, version_group_id)` responde a "quem aprende o golpe X no jogo Z".
- **machines** (WITHOUT ROWID): version_group_id, move_id, item_id, machine_number, label. `label` é o nome do item ("TM24", "TR05", "HM03", "TM149"). A exceção são os itens HM com `machine_number <= 100`: nos jogos sem HM (BDSP), o rótulo vira `TM{número}`, então HM01 Cut aparece como TM93. Nos jogos com HM, a PokeAPI numera as HMs acima de 100. Para o método 4, junte com `learnsets` por (version_group_id, move_id). Um golpe pode ter mais de uma máquina no mesmo jogo.
  - BDSP: a PokeAPI só tem 17 das 100 MTs. O build completa as outras 83 com a lista do pokemondb.net (`BDSP_TMS` no script, item `tmNN`). Antes disso, confere a lista contra as 17 da PokeAPI e contra os 100 golpes de máquina do learnset do BDSP. Agora nenhum golpe de máquina fica sem número em jogo nenhum.

### Evolução

- **evolution_chains**: id, baby_trigger_item_id.
- **evolution_triggers**: id, identifier, name. Os 18 gatilhos: level-up, trade, use-item, shed, spin, tower-of-darkness, tower-of-waters, three-critical-hits, take-damage, in-battle-level-up, agile-style-move, strong-style-move, recoil-damage, use-move, three-defeated-bisharp, gimmighoul-coins, meltan-candies, unclassified.

**evolutions** guarda as 676 regras com **todas** as colunas de `pokemon_evolution.csv`, renomeadas para snake_case. A única normalização é em `required_pokemon_form_id` (ver a linha da tabela).

| Coluna | Significado |
|---|---|
| id | id da regra na PokeAPI |
| evolution_chain_id, from_species_id | derivados da espécie evoluída (para filtrar por cadeia sem join) |
| evolved_species_id | espécie resultante |
| trigger_id | gatilho |
| **version_group_id** | jogo em que a regra foi registrada (ver abaixo) |
| is_default | regra "canônica" atual da espécie (a PokeAPI marca 641 de 676) |
| trigger_item_id | item usado (pedra etc.) |
| min_level | nível mínimo |
| gender_id | 1 fêmea, 2 macho |
| location_id | local exigido (pedra musgosa, campo magnético...) |
| held_item_id | item segurado (troca com Metal Coat etc.) |
| time_of_day | `day` / `night` / `dusk` / `full-moon` |
| known_move_id, known_move_type_id | conhece o golpe / um golpe do tipo |
| min_happiness, min_beauty, min_affection | `min_happiness` é o valor cru da PokeAPI, que é inconsistente: 17 regras têm 160, e Pichu, Chingling e Swadloon têm 220. Para exibir, use `evolution_version_groups.min_happiness`: 220 até a gen 7 e 160 a partir da gen 8, inclusive BDSP |
| relative_physical_stats | 1 Atk>Def, −1 Atk<Def, 0 igual (Tyrogue) |
| party_species_id, party_type_id | espécie/tipo no time (Mantyke, Pancham) |
| trade_species_id | troca por espécie específica (Karrablast↔Shelmet) |
| needs_overworld_rain, turn_upside_down, needs_multiplayer, near_special_rock | 0/1 |
| region_id | só vale nessa região; costuma gerar forma regional (Pikachu → Raichu de Alola em Alola) |
| required_pokemon_form_id, evolved_pokemon_form_id | forma exigida / forma resultante (`pokemon_forms.id`). **Normalizado no build:** quando a espécie de origem tem alguma regra para uma variedade não padrão (forma regional, Pikachu de boné, Eevee parceiro), as regras dela com forma exigida NULL passam a exigir a forma padrão da variedade padrão. Isso afeta 20 regras: Vulpix → Ninetales (Fire Stone) exige `vulpix`, Sneasel → Weavile exige `sneasel`, e o mesmo vale para Slowpoke, Wooper, Yamask, Meowth, Growlithe, Voltorb, Zorua, Darumaka, Ponyta, Zigzagoon etc. Variações cosméticas da mesma variedade não contam, então Burmy de qualquer capa vira Mothim. NULL quer dizer "qualquer forma"; ficam 535 NULL e 141 preenchidas |
| used_move_id, min_move_count | usar o golpe N vezes (Barb Barrage, Rage Fist) |
| min_steps | passos (Pawmo, Bramblin, Rellor) |
| min_damage_taken | dano sofrido sem desmaiar (Basculin branco, Yamask de Galar) |
| nature_bitmask | máscara de naturezas (Toxtricity Amped/Low Key). O bit `i` corresponde a `natures.id = i + 1` (não a `game_index`): `(nature_bitmask >> (natures.id - 1)) & 1`. A regra 433 (Amped) dá Hardy, Brave, Adamant, Naughty, Docile, Impish, Lax, Hasty, Jolly, Naive, Rash, Sassy e Quirky |
| condition_expression | expressão RPN da PokeAPI (`EC 100 % 0 !=` para Dudunsparce, `PID 16 >> 10 % 4 <=` para Wurmple até a gen 5, `SPIN_DIR`/`SPIN_SEC` para Alcremie). Os símbolos estão em `evolution_variables` |
| percentage_chance | chance da regra (Maushold 1%/99%, Dudunsparce) |

**natures** (id, identifier, name, increased_stat, decreased_stat, likes_flavor, hates_flavor, game_index): as 25 naturezas, para a ficha do exemplar e para decodificar `nature_bitmask`. `increased_stat`/`decreased_stat` usam os nomes das colunas de `pokemon` (`attack`, `defense`, `sp_attack`, `sp_defense`, `speed`). Sabores: `spicy`, `dry`, `sweet`, `bitter`, `sour`. Nas 5 naturezas neutras (Hardy, Docile, Serious, Bashful, Quirky), stat e sabor ficam NULL. `game_index` é o índice interno do jogo e **não** é o bit da máscara.

**evolution_variables** (id, identifier, symbol, data_type, version_group_id, source, name, description): os símbolos de `condition_expression`. São `EC` (encryption constant, gen 6+), `PID` (personality value, gens 3–5), `SPIN_DIR` (0 horário, 1 anti-horário) e `SPIN_SEC` (segundos girando), estes dois do Milcery.

#### `version_group_id` por regra

O CSV atual **tem** `version_group_id` em cada regra, mas o campo não é uma lista de jogos. Ele indica o jogo em que aquela variante da regra foi registrada. Uma regra criada em Red/Blue (Charmander nível 16) vale em todos os jogos seguintes. Leafeon tem uma regra por local para cada geração (Eterna Forest em DP, Pinwheel Forest em BW, Route 20 em XY...) e uma regra de Leaf Stone desde Sword/Shield. Por isso o build deriva a tabela **evolution_version_groups** (evolution_id, version_group_id, **min_happiness**), PK (version_group_id, evolution_id), com 8116 linhas, que é a que o app deve usar para "como X evolui **no meu jogo**". `min_happiness` traz a amizade exigida naquele jogo (NULL quando a regra não pede amizade). A heurística é esta:

1. DLCs e variantes JP usam a ordem do jogo base (`parent_id`). Regras de DLC valem no jogo base, porque o app assume DLC instalado.
2. Uma regra só vale em jogos com `sort_order` maior ou igual ao do jogo dela.
3. **A espécie tem de existir no jogo.** As espécies de origem e evoluída precisam ser da geração do jogo ou anterior; com isso, Spritzee → Aromatisse, registrada em BW, só vale a partir de XY. Nos jogos com Dex Nacional, elas também precisam ter número ≤ `national_dex_size`, o que tira Sylveon do BDSP. Nos jogos de dex fechada (`is_closed_dex`), elas precisam estar na dex ou nos encontros da família do jogo (jogo base + DLCs). Isso tira de Let's Go Espeon, Crobat, Steelix e afins. Nesses jogos e no BDSP, a regra também sai quando a **variedade exigida** está sabidamente ausente:
   - com dado de encontro (Let's Go, SwSh + DLC), quando a variedade não está em `pokedex_entry_forms` nem nos encontros (Graveler de Alola em Let's Go conta porque vem do Geodude de Alola);
   - sem dado de encontro, quando a dex do jogo lista outra forma como primária e não lista a padrão. Assim saem de Legends: Arceus o Growlithe, o Voltorb e o Zorua de Kanto/Unova;
   - no BDSP, que não tem forma regional nenhuma, todas as regras de formas regionais saem.
4. Gatilhos presos a um jogo: estilos ágil/forte só em Legends: Arceus; torres do Kubfu só em Sword/Shield (+DLC); `meltan-candies` em nenhum (é do Pokémon GO). Beauty só em RS, E, DP, Pt, HGSS, ORAS e **BDSP** (Poffins). Itens que não existem no jogo: no BDSP não há Ice Stone, então Glaceon fica só com o Ice Rock.
5. Regra com `location_id` só vale se o local for de uma região do jogo **e** o jogo for da mesma geração da regra ou um remake dela (DP→BDSP, RS/E→ORAS, RB/Y→FRLG/LGPE, GS/C→HGSS). Assim a Route 20 de XY não vale em Z-A, mesmo Z-A sendo Kalos. Regra com `region_id` só vale nos jogos dessa região.
6. Para cada combinação (espécie evoluída, forma evoluída, forma exigida, gatilho), fica só o grupo de regras mais recente. Em SV, Sylveon fica com felicidade 160 e a regra de afeição de XY sai.
7. **Regra própria substitui as herdadas com outro gatilho.** Se a família do jogo registrou regra para (espécie evoluída, forma evoluída, forma exigida), as regras herdadas de jogos anteriores com outro gatilho saem. Em Z-A, Mega Dimension e Champions, Overqwil fica só com "usar Barb Barrage 20 vezes" (516), e a regra de SV (515) sai. Um jogo sem nenhuma regra própria (Champions, USUM...) segue o último jogo anterior que registrou. Duas coisas não saem:
   - regras por local, que já passaram pelo filtro de geração/remake. No BDSP, Leafeon fica com a pedra musgosa de DP **e** a Leaf Stone de SwSh. A Bulbapedia ("Eeveelution") diz que as duas funcionam, mas o talk page da Leafeon contesta. A Thunder Stone do Magnezone também vale (guias de BDSP);
   - as exceções curadas em `KEEP_INHERITED`. Em ORAS, Feebas evolui por Beauty (regra própria) **e** por troca com Prism Scale.
8. Quando sobra regra com `region_id` da região do jogo, as regras sem região da mesma espécie e forma exigida saem. Em Sun/Moon, Pikachu → só Raichu de Alola.

`min_happiness` por jogo: 220 até a gen 7 e 160 a partir da gen 8. A gen é a do version group, então o BDSP é gen 8 (Serebii, "Friendship" do BDSP; Bulbapedia, "Friendship"). Golbat → Crobat pede 220 em Gold/Silver e 160 em Sword/Shield.

Limites conhecidos da heurística, para o app tratar:

- Pode faltar regra num jogo quando a PokeAPI não registrou a variante. A consulta "espécie da dex do jogo cuja pré-evolução também está na dex, sem regra no jogo" retorna estes casos:
  - **Probopass em Legends: Arceus**: a regra de Thunder Stone só aparece em SV;
  - **Runerigus em Legends: Z-A e Mega Dimension** (dex hyperspace, com Yamask): a única regra é a 459, de Galar, que exige o local dusty-bowl e o Yamask de Galar;
  - **Melmetal** em Let's Go, Z-A e Mega Dimension: o gatilho `meltan-candies` não é executado em jogo principal.

  Fallback sugerido: mostrar as regras `is_default=1` com o aviso "regra geral (pode variar neste jogo)". Se a regra tiver `location_id` de um local fora das regiões do jogo (`version_group_regions`), o app deve omitir o local e manter o aviso, para não mostrar Dusty Bowl num jogo de Kalos. Para Meltan, mostrar "só no Pokémon GO".
- Z-A e Mega Dimension herdam as regras de SV/SwSh, exceto 1 regra própria (Overqwil por uso de golpe). As mudanças específicas de Z-A que a PokeAPI ainda não registrou não aparecem. Sem encontros e com dex de Kalos, as formas regionais de outras regiões não têm evidência e não são filtradas: Meowth de Alola/Galar e Slowpoke de Galar continuam com as regras deles em Z-A.
- Mecânicas fora de evolução (troca, região, versão do cartucho) não são validadas, porque `versions` não entra na regra.

### Locais e encontros ("Onde achar" e rotas do Nuzlocke)

- **locations**: id, region_id, identifier, name, subtitle. São 1104; `region_id` pode ser NULL.
- **location_areas**: id, location_id, identifier, name. São 1539; `name` vem da PokeAPI e já inclui o local ("Oreburgh mine (B1F)"); 248 áreas não têm nome, então use `locations.name`.
- **encounter_methods**: id, identifier, name, sort_order (walk, surf, old-rod, gift, static...).
- **encounter_condition_values**: id, condition_identifier (`swarm`, `time`, `radar`, `season`, `weather`...), identifier, name, is_default.
- **encounters**: id, version_id, location_area_id, pokemon_id, method_id, min_level, max_level, rarity, slots. A tabela é **agregada**. Os slots com mesmos versão, área, pokémon, método e condições viram uma linha, com faixa de nível min/max, `rarity` somada (% do método naquela área) e `slots` com quantos slots foram unidos. Foram 117.127 linhas brutas, agora 84.972.
  - Índices: `(pokemon_id, version_id)` para "Onde achar" e `(version_id, location_area_id)` para a lista de rotas.
- **encounter_conditions** (encounter_id, condition_value_id): a linha só vale quando **todas** as suas condições valem (por exemplo, `time-night` + `swarm-no`).

**DLCs de Sword/Shield**: os encontros de The Isle of Armor e The Crown Tundra ficam nas versões próprias (35/50 e 36/51). Uma aventura em Shield deve consultar `version_id IN (34, 50, 51)`, ou seja, a versão e as filhas por `versions.parent_version_id`. Em Shield, por exemplo, o Spheal tem 0 encontros na versão 34 e 46 na 51. Teal Mask, Indigo Disk e Mega Dimension já têm `parent_version_id`, mas ainda não têm encontros.

A lista de rotas do Nuzlocke segue `version_groups.route_source`:

- `encounters`: as áreas com encontros na versão e nas filhas;
- `region-locations`: `locations` da região do jogo (`version_group_regions`);
- `free-text`: Z-A, Mega Dimension e Champions. O app usa só texto livre, com o aviso "a base não tem os locais deste jogo".

## Consultas de exemplo

**Dex de um jogo com tipos** (Pokédex de Hisui, Legends: Arceus). Use a forma primária da entrada, e não `is_default`, para Growlithe sair como Growlithe de Hisui (Fogo/Pedra):

```sql
SELECT d.number, s.id AS species_id, p.name, t1.name_pt AS tipo1, t2.name_pt AS tipo2,
       p.id AS pokemon_id, p.has_sprite
FROM pokedex_entries d
JOIN species s ON s.id = d.species_id
JOIN pokedex_entry_forms f ON f.pokedex_id = d.pokedex_id AND f.species_id = d.species_id
                          AND f.is_primary = 1
JOIN pokemon p ON p.id = f.pokemon_id
JOIN types t1 ON t1.id = p.type1_id
LEFT JOIN types t2 ON t2.id = p.type2_id
WHERE d.pokedex_id = (SELECT id FROM pokedexes WHERE identifier = 'hisui')
ORDER BY d.number;
-- Para um jogo com várias dex: WHERE d.pokedex_id IN
--   (SELECT pokedex_id FROM pokedex_version_groups WHERE version_group_id = ?)
-- Outras formas da entrada (Meowth de Kanto em Galar): f.is_primary = 0.
```

**Disponível no jogo** (filtro distinto de "Dex regional"; FireRed/LeafGreen):

```sql
SELECT s.id, s.name, a.in_regional_dex, a.has_encounters, a.in_national_dex
FROM version_group_species a
JOIN species s ON s.id = a.species_id
WHERE a.version_group_id = (SELECT id FROM version_groups WHERE identifier = 'firered-leafgreen')
ORDER BY s.id;
-- "Dex regional": AND a.in_regional_dex = 1 (151); "Disponível": todas (386).
```

**Regras de evolução de uma cadeia num version group** (Eevee em Scarlet/Violet):

```sql
SELECT fs.name AS de, s.name AS para, t.identifier AS gatilho, e.min_level,
       it.name AS item, hi.name AS segurando, e.time_of_day, v.min_happiness,
       e.min_affection, kt.name_pt AS tipo_golpe, l.name AS local,
       e.region_id, e.required_pokemon_form_id, e.evolved_pokemon_form_id
FROM evolution_version_groups v
JOIN evolutions e ON e.id = v.evolution_id
JOIN species s ON s.id = e.evolved_species_id
LEFT JOIN species fs ON fs.id = e.from_species_id
JOIN evolution_triggers t ON t.id = e.trigger_id
LEFT JOIN items it ON it.id = e.trigger_item_id
LEFT JOIN items hi ON hi.id = e.held_item_id
LEFT JOIN types kt ON kt.id = e.known_move_type_id
LEFT JOIN locations l ON l.id = e.location_id
WHERE e.evolution_chain_id = (SELECT evolution_chain_id FROM species WHERE identifier = 'eevee')
  AND v.version_group_id = (SELECT id FROM version_groups WHERE identifier = 'scarlet-violet')
ORDER BY s.sort_order, e.id;
```

**Quem aprende o golpe X no jogo Z** (Earthquake em Scarlet/Violet, com a MT):

```sql
SELECT p.id, p.name, mm.identifier AS metodo, l.level, mc.label AS maquina
FROM learnsets l
JOIN pokemon p ON p.id = l.pokemon_id
JOIN move_methods mm ON mm.id = l.method_id
LEFT JOIN machines mc ON mc.version_group_id = l.version_group_id
                     AND mc.move_id = l.move_id AND l.method_id = 4
WHERE l.move_id = (SELECT id FROM moves WHERE identifier = 'earthquake')
  AND l.version_group_id = (SELECT id FROM version_groups WHERE identifier = 'scarlet-violet')
ORDER BY p.species_id, p.id;
```

**Golpes do Pokémon Y no jogo Z** (usa a PK):

```sql
SELECT mm.identifier AS metodo, l.level, m.name, ty.name_pt, m.power, m.accuracy, m.pp,
       mc.label AS maquina
FROM learnsets l
JOIN moves m ON m.id = l.move_id
JOIN move_methods mm ON mm.id = l.method_id
LEFT JOIN types ty ON ty.id = m.type_id
LEFT JOIN machines mc ON mc.version_group_id = l.version_group_id
                     AND mc.move_id = l.move_id AND l.method_id = 4
WHERE l.pokemon_id = ?1 AND l.version_group_id = ?2
ORDER BY l.method_id, l.level, m.name;
```

**Fraquezas de um par de tipos** (Água/Terrestre):

```sql
SELECT a.name_pt AS ataque, ef1.factor * COALESCE(ef2.factor, 100) / 100 AS fator
FROM types a
JOIN type_efficacy ef1 ON ef1.attacking_type_id = a.id AND ef1.defending_type_id = ?1
LEFT JOIN type_efficacy ef2 ON ef2.attacking_type_id = a.id AND ef2.defending_type_id = ?2
ORDER BY fator DESC, a.id;
-- ?2 = NULL para tipo único. Resultado Água/Terrestre: Planta 400; Elétrico 0;
-- Fogo, Venenoso, Pedra, Aço 50; o resto 100.
```

**Onde achar** (Pokémon numa versão, com os DLCs da versão):

```sql
SELECT la.name AS area, v.name AS versao, em.name AS metodo, e.min_level, e.max_level,
       e.rarity, group_concat(cv.name, ' + ') AS condicoes
FROM encounters e
JOIN versions v ON v.id = e.version_id
JOIN location_areas la ON la.id = e.location_area_id
JOIN encounter_methods em ON em.id = e.method_id
LEFT JOIN encounter_conditions ec ON ec.encounter_id = e.id
LEFT JOIN encounter_condition_values cv ON cv.id = ec.condition_value_id
WHERE e.pokemon_id = ?1
  AND e.version_id IN (SELECT id FROM versions WHERE id = ?2 OR parent_version_id = ?2)
GROUP BY e.id
ORDER BY la.location_id, em.sort_order;
```

**Naturezas que permitem uma evolução** (Toxel → Toxtricity Amped):

```sql
SELECT n.name FROM natures n, evolutions e
WHERE e.id = 433 AND (e.nature_bitmask >> (n.id - 1)) & 1
ORDER BY n.id;
```

## Lacunas conhecidas

| Lacuna | Detalhe | O que o app faz |
|---|---|---|
| **Legends: Z-A / Mega Dimension sem learnsets** | Têm dex (lumiose-city 232, hyperspace 132), megas novas, megapedras e a lista de MTs (`machines`: 107 em Z-A, 53 em Mega Dimension), mas nenhuma linha em `learnsets` | Mostrar o learnset de Scarlet/Violet com o aviso "dados de Scarlet/Violet" |
| DLCs sem learnset próprio | the-isle-of-armor, the-crown-tundra, the-teal-mask e the-indigo-disk não têm linhas. Os golpes estão no jogo base (20/25) | Usar `parent_id` |
| Champions (vg 32) | Só o método `train` (19.810 linhas); dex `champions` fora da série principal | Tratar como jogo à parte ou ocultar |
| Legends: Arceus | Learnset parcial (2230 linhas, level-up + tutor, com `mastery`), sem máquinas | — |
| **Encontros ausentes** | Sem encontros para BDSP, Legends: Arceus, Scarlet/Violet (+DLC), Z-A (+Mega Dimension) e Champions. Colosseum/XD têm poucos. Let's Go, Sword/Shield + DLC e os jogos até USUM estão cobertos. Os DLCs de SwSh ficam em versões filhas (`parent_version_id`) | "Onde achar" mostra um aviso; o Nuzlocke segue `route_source` |
| **Locais de Z-A** | A PokeAPI não tem nenhum local de Legends: Z-A / Mega Dimension (Wild Zones, Hyperspace). `locations` de Kalos são as 106 de X/Y | `route_source = 'free-text'`: rotas só em texto livre, com aviso |
| Regras de evolução | Heurística de aplicabilidade (seção acima). Z-A tem só 1 regra própria. Sem regra no jogo: Probopass em PLA, Runerigus em Z-A/Mega Dimension, Melmetal (só Pokémon GO) | Fallback `is_default=1` com aviso, omitindo local fora da região do jogo |
| Leaf Stone no BDSP | A Bulbapedia ("Eeveelution") diz que funciona, mas o talk page da Leafeon contesta. O build mantém a regra 407 | Mostrar as duas (Moss Rock e Leaf Stone) |
| Formas por dex | `pokedex_entry_forms` usa a regra de região e os encontros. Sem encontro na PokeAPI (PLA, SV + DLC, Z-A), as formas de outra região só aparecem se curadas (hoje só o Sneasel de Johto em Hisui). Kitakami e Blueberry usam a variedade padrão | Mostrar a primária; as outras formas da espécie seguem em `pokemon` |
| Megas sem jogo | `form_conditions` não tem version group. A disponibilidade vem de `has_mega_evolution` + `introduced_in_version_group_id` (as megas de Z-A foram curadas para 30/31) | Esconder megas em jogos com `has_mega_evolution = 0` |
| Amizade | `evolutions.min_happiness` é o valor cru da PokeAPI (160 ou 220, sem critério) | Usar `evolution_version_groups.min_happiness` |
| Sprites ausentes | 9 pokémon sem sprite normal nem shiny: 10264–10267 (builds do Koraidon), 10268–10271 (modos do Miraidon) e 10301 (Mega Zygarde). Lista em `meta.missing_sprites` | Usar o sprite da variedade padrão da espécie |
| Formas cosméticas | Unown, Vivillon e afins existem em `pokemon_forms`, mas não têm sprite embutido (só por `pokemon.id`) | Artwork on-line sob demanda |
| Textos de efeito | 88 golpes (quase todos da gen 9 e de Legends: Arceus) e 660 itens não têm `short_effect` na PokeAPI. Para eles, o build usa o texto de jogo en mais recente, com `effect_is_flavor = 1`. 5 golpes e 609 itens ficam sem texto | Mostrar o texto; se `effect_is_flavor`, rotular como descrição do jogo |
| Flavor text de espécie | Não embutido (decisão de produto) | API sob demanda + cache |
| `is_holdable` | Flags holdable da PokeAPI incompletas; o build completa com itens de evolução segurados e megapedras | Não usar como filtro estrito |
| Sem pt-BR | Só tipos têm nome pt-BR (curados no script) | — |

## Uso no app (Drift)

- Copiar o asset para o diretório de dados no primeiro uso, ou quando `meta.schema_version`/`built_at` mudar, e abrir **somente leitura**.
- Os dados do usuário (aventuras, exemplares, listas) ficam num banco separado. Para juntar com os dados de referência, o app pode usar `ATTACH`. Assim a troca do asset numa atualização não toca nos dados do usuário.
- Os ids da PokeAPI são estáveis. Referencie `species.id` e `pokemon.id` no banco do usuário.
