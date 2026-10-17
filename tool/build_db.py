#!/usr/bin/env python3
"""Gera assets/db/pokedex.sqlite a partir dos CSV oficiais da PokeAPI.

Só usa a biblioteca padrão (csv, sqlite3, urllib). Documentação do schema em
docs/DATA.md.

Uso:
    python3 tool/build_db.py                 # build completo
    python3 tool/build_db.py --sprites-only  # só atualiza flags de sprite + meta
    python3 tool/build_db.py --csv-dir DIR   # usa CSVs de outro diretório
    python3 tool/build_db.py --ref SHA       # baixa CSVs desse commit (sem cache)

Fonte dos CSV, em ordem de preferência:
  1. --csv-dir, se informado;
  2. .cache/pokeapi-csv/data/v2/csv (git sparse checkout de PokeAPI/pokeapi;
     o SHA vem de `git rev-parse HEAD`);
  3. download via urllib de raw.githubusercontent.com no commit --ref
     (padrão: POKEAPI_REF abaixo) para .cache/pokeapi-csv-raw/<sha>/.
"""

from __future__ import annotations

import argparse
import csv
import datetime as _dt
import os
import re
import sqlite3
import subprocess
import sys
import urllib.request
from collections import defaultdict

SCHEMA_VERSION = 2
# Commit da PokeAPI usado no último build verificado (2026-10-16).
POKEAPI_REF = "5ee47a9a9c1229632ec4b473a9c1c53026e005dd"
EN = "9"  # local_language_id do inglês

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, ".cache")
GIT_CSV_REPO = os.path.join(CACHE, "pokeapi-csv")
GIT_CSV_DIR = os.path.join(GIT_CSV_REPO, "data", "v2", "csv")
DB_PATH = os.path.join(ROOT, "assets", "db", "pokedex.sqlite")
SPRITES = os.path.join(ROOT, "assets", "sprites")

CSV_FILES = [
    "abilities", "ability_names", "ability_prose", "ability_flavor_text",
    "egg_groups", "egg_group_prose",
    "encounter_condition_values", "encounter_condition_value_prose",
    "encounter_condition_value_map", "encounter_conditions",
    "encounter_condition_prose", "encounter_methods", "encounter_method_prose",
    "encounter_slots", "encounters",
    "evolution_chains", "evolution_triggers", "evolution_trigger_prose",
    "generations", "generation_names",
    "growth_rates", "growth_rate_prose",
    "item_categories", "item_category_prose", "item_flag_map", "item_names",
    "item_prose", "item_flavor_text", "items",
    "location_area_prose", "location_areas", "location_names", "locations",
    "machines",
    "natures", "nature_names", "contest_type_names",
    "evolution_variables", "evolution_variable_prose",
    "move_damage_classes", "move_effect_prose", "move_flavor_text", "move_names",
    "moves",
    "pokedex_prose", "pokedex_version_groups", "pokedexes",
    "pokemon", "pokemon_abilities", "pokemon_abilities_past",
    "pokemon_color_names", "pokemon_colors", "pokemon_dex_numbers",
    "pokemon_egg_groups", "pokemon_evolution", "pokemon_form_names",
    "pokemon_forms", "pokemon_form_conditions", "pokemon_form_triggers",
    "pokemon_form_trigger_prose", "pokemon_habitat_names", "pokemon_habitats",
    "pokemon_move_method_prose", "pokemon_move_methods", "pokemon_moves",
    "pokemon_shape_prose", "pokemon_shapes", "pokemon_species",
    "pokemon_species_names", "pokemon_stats", "pokemon_stats_past",
    "pokemon_types", "pokemon_types_past",
    "region_names", "regions",
    "type_efficacy", "type_efficacy_past", "types",
    "version_group_regions", "version_groups", "version_names", "versions",
]

# --------------------------------------------------------------------------
# Curadoria (a PokeAPI não tem essas flags). Fonte: Bulbapedia, páginas
# "Ultra Beast", "Paradox Pokémon", "Starter Pokémon", "Pseudo-legendary
# Pokémon" (consultadas em 2026-10). Cada id é conferido contra o
# identifier do CSV no build, para pegar erro de digitação.
# --------------------------------------------------------------------------

# https://bulbapedia.bulbagarden.net/wiki/Ultra_Beast
ULTRA_BEASTS = {
    793: "nihilego", 794: "buzzwole", 795: "pheromosa", 796: "xurkitree",
    797: "celesteela", 798: "kartana", 799: "guzzlord", 803: "poipole",
    804: "naganadel", 805: "stakataka", 806: "blacephalon",
}

# https://bulbapedia.bulbagarden.net/wiki/Paradox_Pok%C3%A9mon
# note = 'ancient' (Scarlet) ou 'future' (Violet). Koraidon/Miraidon entram
# como paradoxo (a Bulbapedia os classifica assim: são a forma
# antiga/futura de Cyclizar), com note 'ancient-legendary'/'future-legendary'.
PARADOX = {
    984: ("great-tusk", "ancient"), 985: ("scream-tail", "ancient"),
    986: ("brute-bonnet", "ancient"), 987: ("flutter-mane", "ancient"),
    988: ("slither-wing", "ancient"), 989: ("sandy-shocks", "ancient"),
    1005: ("roaring-moon", "ancient"), 1009: ("walking-wake", "ancient"),
    1020: ("gouging-fire", "ancient"), 1021: ("raging-bolt", "ancient"),
    990: ("iron-treads", "future"), 991: ("iron-bundle", "future"),
    992: ("iron-hands", "future"), 993: ("iron-jugulis", "future"),
    994: ("iron-moth", "future"), 995: ("iron-thorns", "future"),
    1006: ("iron-valiant", "future"), 1010: ("iron-leaves", "future"),
    1022: ("iron-boulder", "future"), 1023: ("iron-crown", "future"),
    1007: ("koraidon", "ancient-legendary"),
    1008: ("miraidon", "future-legendary"),
}

# https://bulbapedia.bulbagarden.net/wiki/Starter_Pok%C3%A9mon
# Decisão: a categoria 'starter' cobre a LINHA evolutiva inteira dos 27
# iniciais clássicos (note 'base' no primeiro estágio, 'evolution' nos
# demais), porque no filtro o usuário espera ver Charizard junto de
# Charmander. Pikachu (Yellow / Let's Go, Pikachu!) e Eevee (Let's Go,
# Eevee!) entram como 'partner', só a própria espécie (Raichu e as
# eeveeluções não são iniciais).
STARTER_BASES = {
    1: "bulbasaur", 4: "charmander", 7: "squirtle",
    152: "chikorita", 155: "cyndaquil", 158: "totodile",
    252: "treecko", 255: "torchic", 258: "mudkip",
    387: "turtwig", 390: "chimchar", 393: "piplup",
    495: "snivy", 498: "tepig", 501: "oshawott",
    650: "chespin", 653: "fennekin", 656: "froakie",
    722: "rowlet", 725: "litten", 728: "popplio",
    810: "grookey", 813: "scorbunny", 816: "sobble",
    906: "sprigatito", 909: "fuecoco", 912: "quaxly",
}
STARTER_PARTNERS = {25: "pikachu", 133: "eevee"}

# https://bulbapedia.bulbagarden.net/wiki/Pseudo-legendary_Pok%C3%A9mon
# Estritamente é o estágio final (BST 600); guardamos a linha inteira com
# note 'final' / 'pre-evolution' para o filtro poder escolher.
PSEUDO_BASES = {
    147: "dratini", 246: "larvitar", 371: "bagon", 374: "beldum",
    443: "gible", 633: "deino", 704: "goomy", 782: "jangmo-o",
    885: "dreepy", 996: "frigibax",
}

# Nome amigável (en) dos version groups — a PokeAPI não tem.
VERSION_GROUP_NAMES = {
    1: "Red / Blue", 2: "Yellow", 3: "Gold / Silver", 4: "Crystal",
    5: "Ruby / Sapphire", 6: "Emerald", 7: "FireRed / LeafGreen",
    8: "Diamond / Pearl", 9: "Platinum", 10: "HeartGold / SoulSilver",
    11: "Black / White", 12: "Colosseum", 13: "XD: Gale of Darkness",
    14: "Black 2 / White 2", 15: "X / Y", 16: "Omega Ruby / Alpha Sapphire",
    17: "Sun / Moon", 18: "Ultra Sun / Ultra Moon",
    19: "Let's Go, Pikachu! / Let's Go, Eevee!", 20: "Sword / Shield",
    21: "The Isle of Armor", 22: "The Crown Tundra",
    23: "Brilliant Diamond / Shining Pearl", 24: "Legends: Arceus",
    25: "Scarlet / Violet", 26: "The Teal Mask", 27: "The Indigo Disk",
    28: "Red / Green (Japan)", 29: "Blue (Japan)", 30: "Legends: Z-A",
    31: "Mega Dimension", 32: "Champions",
}
# DLC / variante -> version group "pai". Usado pela aplicabilidade das
# regras de evolução (a DLC herda as regras do jogo base e vice-versa).
VERSION_GROUP_PARENT = {21: 20, 22: 20, 26: 25, 27: 25, 31: 30, 28: 1, 29: 1}
DLC_VERSION_GROUPS = {21, 22, 26, 27, 31}
# Versão (cartucho) de DLC -> versão base. Os encontros dos DLCs de
# Sword/Shield ficam em version_ids próprios na PokeAPI.
VERSION_PARENT = {35: 33, 36: 33, 50: 34, 51: 34,   # IoA/CT -> Sword/Shield
                  42: 40, 43: 40, 52: 41, 53: 41,   # Teal Mask/Indigo Disk -> Scarlet/Violet
                  48: 47}                           # Mega Dimension -> Legends: Z-A
# Nome curado das versões japonesas (a PokeAPI repete "Red", "Green", "Blue").
VERSION_NAMES = {44: "Red (Japan)", 45: "Green (Japan)", 46: "Blue (Japan)"}
# Jogos onde o atributo Beauty existe (Feebas por beleza). BDSP tem Beauty
# (Poffins): Serebii/pokemondb, guias de BDSP (consultados em 2026-10).
BEAUTY_VERSION_GROUPS = {5, 6, 8, 9, 10, 16, 23}
# Gatilhos presos a um jogo: estilo ágil/forte (Legends: Arceus) e torres
# do Kubfu (The Isle of Armor, família Sword/Shield). Meltan candies (17)
# só existe no Pokémon GO: nenhum jogo principal executa a regra.
TRIGGER_ONLY_IN = {11: {24}, 12: {24}, 6: {20, 21, 22}, 7: {20, 21, 22}, 17: set()}
# Item de evolução que não existe no jogo: BDSP não tem Ice Stone, então
# Glaceon só por Ice Rock (Bulbapedia, "Eeveelution"). Thunder Stone
# (Magnezone) e Leaf Stone (Leafeon) herdadas de SwSh funcionam no BDSP.
ITEMS_ABSENT_IN = {23: {"ice-stone"}}
# Exceções da regra "o jogo que registra a própria regra substitui as
# herdadas com outro gatilho": (version_group, evolution_id) que continuam.
# ORAS: Feebas evolui por Beauty (regra 553, registrada em ORAS) E por troca
# com Prism Scale (regra 321, de BW). Bulbapedia, "Feebas".
KEEP_INHERITED = {(16, 321)}
# Jogos de dex fechada: só existem as espécies das dex do jogo (+DLC) e as
# que têm encontro. Nos demais, valem todas as espécies até a geração do
# jogo (dados de troca/transferência).
CLOSED_DEX_VERSION_GROUPS = {19, 20, 21, 22, 24, 25, 26, 27, 30, 31, 32}
# Tamanho da Dex Nacional do jogo (NULL = jogo sem Dex Nacional). Bulbapedia,
# "National Pokédex". BDSP tem Dex Nacional com as 493 espécies até Sinnoh.
NATIONAL_DEX_SIZE = {1: 151, 2: 151, 28: 151, 29: 151, 3: 251, 4: 251,
                     5: 386, 6: 386, 7: 386, 8: 493, 9: 493, 10: 493, 23: 493,
                     11: 649, 14: 649, 15: 721, 16: 721}
# Jogos com a mecânica de Mega Evolução (Bulbapedia, "Mega Evolution").
MEGA_VERSION_GROUPS = {15, 16, 17, 18, 19, 30, 31, 32}
# Megas do jogo base Legends: Z-A. A PokeAPI marca todas as megas novas com
# introduced_in_version_group_id = 31 (Mega Dimension). As 19 espécies do
# DLC (Raichu X/Y, Chimecho, Absol Z, Staraptor, Garchomp Z, Lucario Z,
# Heatran, Darkrai, Golurk, Meowstic, Crabominable, Golisopod, Magearna,
# Zeraora, Scovillain, Glimmora, Tatsugiri, Baxcalibur) ficam em 31.
# Fonte: Serebii "Legends: Z-A Mega Evolutions" + Destructoid "All Mega
# Evolutions in Mega Dimension" (consultados em 2026-10).
ZA_BASE_MEGAS = {
    "clefable-mega", "victreebel-mega", "starmie-mega", "dragonite-mega",
    "meganium-mega", "feraligatr-mega", "skarmory-mega", "froslass-mega",
    "emboar-mega", "excadrill-mega", "scolipede-mega", "scrafty-mega",
    "eelektross-mega", "chandelure-mega", "chesnaught-mega", "delphox-mega",
    "greninja-mega", "pyroar-mega", "floette-mega", "malamar-mega",
    "barbaracle-mega", "dragalge-mega", "hawlucha-mega", "zygarde-mega",
    "drampa-mega", "falinks-mega",
}
# Dex em que a forma regional da região da dex é a primária. Kitakami e
# Blueberry têm region_id = paldea na PokeAPI, mas não são Paldea (e
# Blueberry tem Tauros de Kanto), então ficam de fora.
REGIONAL_DEX = {
    "original-alola": "alola", "original-melemele": "alola", "original-akala": "alola",
    "original-ulaula": "alola", "original-poni": "alola", "updated-alola": "alola",
    "updated-melemele": "alola", "updated-akala": "alola", "updated-ulaula": "alola",
    "updated-poni": "alola", "galar": "galar", "isle-of-armor": "galar",
    "crown-tundra": "galar", "hisui": "hisui", "paldea": "paldea",
}
# Formas que coexistem numa dex sem dado de encontro na PokeAPI:
# (dex, pokemon identifier). Legends: Arceus tem Sneasel de Johto (vira
# Weavile) e de Hisui (vira Sneasler). Bulbapedia, "Sneasel".
EXTRA_DEX_FORMS = {("hisui", "sneasel")}
# Jogos sem nenhuma forma regional (nem por transferência do HOME):
# Brilliant Diamond / Shining Pearl. Bulbapedia, "Regional form".
NO_REGIONAL_FORMS_IN = {23}
# MTs de Brilliant Diamond / Shining Pearl. A PokeAPI só tem 17 das 100
# (machines.csv). Lista completa: pokemondb.net/brilliant-diamond-shining-pearl/tms
# (consultada em 2026-10); conferida no build contra as 17 da PokeAPI e
# contra os golpes do learnset de máquina do BDSP.
BDSP_TMS = (
    "focus-punch dragon-claw water-pulse calm-mind roar toxic hail bulk-up bullet-seed "
    "work-up sunny-day taunt ice-beam blizzard hyper-beam light-screen protect rain-dance "
    "giga-drain safeguard dazzling-gleam solar-beam iron-tail thunderbolt thunder earthquake "
    "low-sweep dig psychic shadow-ball brick-break double-team reflect shock-wave flamethrower "
    "sludge-bomb sandstorm fire-blast rock-tomb aerial-ace torment facade volt-switch rest "
    "attract thief steel-wing skill-swap scald overheat roost focus-blast energy-ball "
    "false-swipe brine fling charge-beam endure dragon-pulse drain-punch will-o-wisp bug-buzz "
    "nasty-plot explosion shadow-claw payback recycle giga-impact rock-polish flash stone-edge "
    "avalanche thunder-wave gyro-ball swords-dance stealth-rock psych-up snarl dark-pulse "
    "rock-slide x-scissor sleep-talk bulldoze poison-jab dream-eater grass-knot swagger pluck "
    "u-turn substitute flash-cannon trick-room cut fly surf strength defog rock-smash "
    "waterfall rock-climb").split()
# Amizade mínima para evoluir: 220 até a gen 7, 160 a partir da gen 8
# (inclusive BDSP). Bulbapedia, "Friendship"; Serebii, BDSP "Friendship".
def happiness_for_gen(gen: int) -> int:
    return 220 if gen <= 7 else 160


# Formas sem condição de forma na PokeAPI: Mega Rayquaza é pelo golpe
# Dragon Ascent (Bulbapedia, "Mega Evolution"). (form identifier, trigger
# identifier, move identifier).
EXTRA_FORM_CONDITIONS = [("rayquaza-mega", "move", "dragon-ascent")]
# Locais de rota do Nuzlocke: Z-A / Mega Dimension se passam em Lumiose
# (Wild Zones), que a PokeAPI não tem; o fallback por região listaria X/Y.
FREE_TEXT_ROUTES = {30, 31, 32}
# Regra de evolução por local (pedra musgosa, campo magnético...) só vale
# no mesmo "ciclo" de jogos: mesma geração do jogo da regra ou remake dele.
# Ex.: Legends: Z-A é Kalos, mas a regra da Route 20 de X/Y não vale lá.
REMAKE_OF = {7: {1, 2}, 10: {3, 4}, 16: {5, 6}, 19: {1, 2}, 23: {8, 9}}

TYPE_NAMES_PT = {
    "normal": "Normal", "fire": "Fogo", "water": "Água", "grass": "Planta",
    "electric": "Elétrico", "ice": "Gelo", "fighting": "Lutador",
    "poison": "Venenoso", "ground": "Terrestre", "flying": "Voador",
    "psychic": "Psíquico", "bug": "Inseto", "rock": "Pedra",
    "ghost": "Fantasma", "dragon": "Dragão", "dark": "Sombrio",
    "steel": "Aço", "fairy": "Fada",
}

REGIONAL_RE = re.compile(r"-(alola|galar|hisui|paldea)(?:-|$)")


# --------------------------------------------------------------------------
# Leitura dos CSV
# --------------------------------------------------------------------------

def resolve_csv_dir(args) -> tuple[str, str, str]:
    """Retorna (diretório, sha, data do commit)."""
    if args.csv_dir:
        return args.csv_dir, args.ref or "desconhecido", ""
    if not args.ref and os.path.isdir(GIT_CSV_DIR):
        sha, date = "desconhecido", ""
        try:
            out = subprocess.run(
                ["git", "-C", GIT_CSV_REPO, "log", "-1", "--format=%H|%cI"],
                capture_output=True, text=True, check=True).stdout.strip()
            sha, date = out.split("|", 1)
        except (OSError, subprocess.CalledProcessError):
            pass
        return GIT_CSV_DIR, sha, date
    ref = args.ref or POKEAPI_REF
    dest = os.path.join(CACHE, "pokeapi-csv-raw", ref)
    os.makedirs(dest, exist_ok=True)
    base = f"https://raw.githubusercontent.com/PokeAPI/pokeapi/{ref}/data/v2/csv/"
    for name in CSV_FILES:
        path = os.path.join(dest, name + ".csv")
        if os.path.exists(path) and os.path.getsize(path) > 0:
            continue
        print(f"baixando {name}.csv", file=sys.stderr)
        with urllib.request.urlopen(base + name + ".csv", timeout=120) as r:
            data = r.read()
        with open(path, "wb") as f:
            f.write(data)
    return dest, ref, ""


class Csv:
    def __init__(self, directory: str):
        self.dir = directory
        self._cache: dict[str, list[dict]] = {}

    def __call__(self, name: str) -> list[dict]:
        if name not in self._cache:
            with open(os.path.join(self.dir, name + ".csv"), encoding="utf-8",
                      newline="") as f:
                self._cache[name] = [
                    {k.strip(): (v.strip() if v is not None else "")
                     for k, v in row.items()}
                    for row in csv.DictReader(f)]
        return self._cache[name]

    def names(self, name: str, key: str, col: str = "name",
              lang_col: str = "local_language_id") -> dict[int, str]:
        return {int(r[key]): r[col] for r in self(name)
                if r[lang_col] == EN and r.get(col)}


def i(v):
    """Inteiro ou None."""
    return int(v) if v not in ("", None) else None


def humanize(identifier: str) -> str:
    return " ".join(w.capitalize() for w in identifier.split("-"))


def clean_text(s: str | None) -> str | None:
    if not s:
        return None
    s = s.replace("­", "").replace("\x0c", " ")
    s = re.sub(r"\s+", " ", s).strip()
    # Marcação da PokeAPI: [texto]{tipo:alvo}
    s = re.sub(r"\[([^\]]*)\]\{[^}]*:([^}]*)\}",
               lambda m: m.group(1) or humanize(m.group(2)), s)
    return s


# --------------------------------------------------------------------------
# Schema
# --------------------------------------------------------------------------

SCHEMA = """
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT) WITHOUT ROWID;

CREATE TABLE regions (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);
CREATE TABLE generations (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  main_region_id INTEGER);
CREATE TABLE version_groups (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  generation_id INTEGER NOT NULL, sort_order INTEGER NOT NULL, parent_id INTEGER,
  is_dlc INTEGER NOT NULL, is_closed_dex INTEGER NOT NULL, national_dex_size INTEGER,
  has_mega_evolution INTEGER NOT NULL, route_source TEXT NOT NULL);
CREATE TABLE versions (id INTEGER PRIMARY KEY, version_group_id INTEGER NOT NULL,
  identifier TEXT NOT NULL, name TEXT NOT NULL, parent_version_id INTEGER);
CREATE TABLE version_group_species (version_group_id INTEGER NOT NULL, species_id INTEGER NOT NULL,
  in_regional_dex INTEGER NOT NULL, has_encounters INTEGER NOT NULL, in_national_dex INTEGER NOT NULL,
  PRIMARY KEY (version_group_id, species_id)) WITHOUT ROWID;
CREATE TABLE version_group_regions (version_group_id INTEGER NOT NULL, region_id INTEGER NOT NULL,
  source TEXT NOT NULL, PRIMARY KEY (version_group_id, region_id)) WITHOUT ROWID;
CREATE TABLE pokedexes (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  region_id INTEGER, is_main_series INTEGER NOT NULL, size INTEGER NOT NULL);
CREATE TABLE pokedex_version_groups (pokedex_id INTEGER NOT NULL, version_group_id INTEGER NOT NULL,
  PRIMARY KEY (pokedex_id, version_group_id)) WITHOUT ROWID;
CREATE TABLE pokedex_entries (pokedex_id INTEGER NOT NULL, species_id INTEGER NOT NULL,
  number INTEGER NOT NULL, PRIMARY KEY (pokedex_id, species_id)) WITHOUT ROWID;
CREATE TABLE pokedex_entry_forms (pokedex_id INTEGER NOT NULL, species_id INTEGER NOT NULL,
  pokemon_id INTEGER NOT NULL, is_primary INTEGER NOT NULL, source TEXT NOT NULL,
  PRIMARY KEY (pokedex_id, species_id, pokemon_id)) WITHOUT ROWID;

CREATE TABLE types (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  name_pt TEXT NOT NULL, generation_id INTEGER NOT NULL);
CREATE TABLE type_efficacy (attacking_type_id INTEGER NOT NULL, defending_type_id INTEGER NOT NULL,
  factor INTEGER NOT NULL, PRIMARY KEY (attacking_type_id, defending_type_id)) WITHOUT ROWID;
CREATE TABLE type_efficacy_past (attacking_type_id INTEGER NOT NULL, defending_type_id INTEGER NOT NULL,
  factor INTEGER NOT NULL, generation_id INTEGER NOT NULL,
  PRIMARY KEY (attacking_type_id, defending_type_id, generation_id)) WITHOUT ROWID;

CREATE TABLE colors (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);
CREATE TABLE shapes (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);
CREATE TABLE habitats (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);
CREATE TABLE growth_rates (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);
CREATE TABLE egg_groups (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);

CREATE TABLE species (
  id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL, genus TEXT,
  generation_id INTEGER NOT NULL, evolution_chain_id INTEGER, evolves_from_species_id INTEGER,
  is_legendary INTEGER NOT NULL, is_mythical INTEGER NOT NULL, is_baby INTEGER NOT NULL,
  gender_rate INTEGER NOT NULL, capture_rate INTEGER, base_happiness INTEGER,
  hatch_counter INTEGER, growth_rate_id INTEGER, color_id INTEGER, shape_id INTEGER,
  habitat_id INTEGER, has_gender_differences INTEGER NOT NULL, forms_switchable INTEGER NOT NULL,
  sort_order INTEGER NOT NULL);
CREATE TABLE species_egg_groups (species_id INTEGER NOT NULL, egg_group_id INTEGER NOT NULL,
  PRIMARY KEY (species_id, egg_group_id)) WITHOUT ROWID;
CREATE TABLE species_categories (species_id INTEGER NOT NULL, category TEXT NOT NULL, note TEXT,
  PRIMARY KEY (category, species_id)) WITHOUT ROWID;

CREATE TABLE pokemon (
  id INTEGER PRIMARY KEY, species_id INTEGER NOT NULL, identifier TEXT NOT NULL,
  name TEXT NOT NULL, form_name TEXT, is_default INTEGER NOT NULL,
  height INTEGER, weight INTEGER, base_experience INTEGER, sort_order INTEGER,
  type1_id INTEGER NOT NULL, type2_id INTEGER,
  hp INTEGER, attack INTEGER, defense INTEGER, sp_attack INTEGER, sp_defense INTEGER,
  speed INTEGER, total INTEGER,
  ev_hp INTEGER, ev_attack INTEGER, ev_defense INTEGER, ev_sp_attack INTEGER,
  ev_sp_defense INTEGER, ev_speed INTEGER,
  ability1_id INTEGER, ability2_id INTEGER, hidden_ability_id INTEGER,
  is_mega INTEGER NOT NULL, is_gmax INTEGER NOT NULL, regional TEXT, is_totem INTEGER NOT NULL,
  is_alternate_form INTEGER NOT NULL, is_battle_only INTEGER NOT NULL,
  has_sprite INTEGER NOT NULL DEFAULT 0, has_shiny_sprite INTEGER NOT NULL DEFAULT 0);
CREATE INDEX pokemon_species_idx ON pokemon (species_id);
CREATE TABLE pokemon_forms (
  id INTEGER PRIMARY KEY, pokemon_id INTEGER NOT NULL, identifier TEXT NOT NULL,
  form_identifier TEXT, name TEXT NOT NULL, form_name TEXT, is_default INTEGER NOT NULL,
  is_battle_only INTEGER NOT NULL, is_mega INTEGER NOT NULL,
  introduced_in_version_group_id INTEGER, form_order INTEGER, sort_order INTEGER);
CREATE TABLE form_triggers (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);
CREATE TABLE form_conditions (pokemon_form_id INTEGER NOT NULL, trigger_id INTEGER NOT NULL,
  item_id INTEGER, ability_id INTEGER, move_id INTEGER, base_form_id INTEGER);
CREATE INDEX form_conditions_form_idx ON form_conditions (pokemon_form_id);
CREATE TABLE pokemon_types_past (pokemon_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
  slot INTEGER NOT NULL, type_id INTEGER NOT NULL,
  PRIMARY KEY (pokemon_id, generation_id, slot)) WITHOUT ROWID;
CREATE TABLE pokemon_stats_past (pokemon_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
  stat TEXT NOT NULL, base_stat INTEGER NOT NULL,
  PRIMARY KEY (pokemon_id, generation_id, stat)) WITHOUT ROWID;

CREATE TABLE abilities (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  short_effect TEXT, effect_is_flavor INTEGER NOT NULL, generation_id INTEGER NOT NULL);
CREATE TABLE pokemon_abilities (pokemon_id INTEGER NOT NULL, slot INTEGER NOT NULL,
  ability_id INTEGER NOT NULL, is_hidden INTEGER NOT NULL,
  PRIMARY KEY (pokemon_id, slot)) WITHOUT ROWID;
CREATE INDEX pokemon_abilities_ability_idx ON pokemon_abilities (ability_id);
CREATE TABLE pokemon_abilities_past (pokemon_id INTEGER NOT NULL, generation_id INTEGER NOT NULL,
  slot INTEGER NOT NULL, ability_id INTEGER, is_hidden INTEGER NOT NULL,
  PRIMARY KEY (pokemon_id, generation_id, slot)) WITHOUT ROWID;

CREATE TABLE item_categories (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  pocket_id INTEGER);
CREATE TABLE items (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  category_id INTEGER, short_effect TEXT, effect_is_flavor INTEGER NOT NULL,
  is_holdable INTEGER NOT NULL, is_evolution_item INTEGER NOT NULL,
  is_mega_stone INTEGER NOT NULL, has_sprite INTEGER NOT NULL DEFAULT 0);

CREATE TABLE damage_classes (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL);
CREATE TABLE moves (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  type_id INTEGER, power INTEGER, pp INTEGER, accuracy INTEGER, priority INTEGER,
  damage_class_id INTEGER, generation_id INTEGER, effect_chance INTEGER,
  short_effect TEXT, effect_is_flavor INTEGER NOT NULL);
CREATE TABLE move_methods (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);
CREATE TABLE machines (version_group_id INTEGER NOT NULL, move_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL, machine_number INTEGER NOT NULL, label TEXT NOT NULL,
  PRIMARY KEY (version_group_id, move_id, item_id)) WITHOUT ROWID;
CREATE TABLE learnsets (pokemon_id INTEGER NOT NULL, version_group_id INTEGER NOT NULL,
  method_id INTEGER NOT NULL, level INTEGER NOT NULL, move_id INTEGER NOT NULL,
  sort_order INTEGER, mastery INTEGER,
  PRIMARY KEY (pokemon_id, version_group_id, method_id, level, move_id)) WITHOUT ROWID;
CREATE INDEX learnsets_move_idx ON learnsets (move_id, version_group_id);

CREATE TABLE evolution_chains (id INTEGER PRIMARY KEY, baby_trigger_item_id INTEGER);
CREATE TABLE evolution_triggers (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL);
CREATE TABLE evolutions (
  id INTEGER PRIMARY KEY, evolution_chain_id INTEGER NOT NULL,
  from_species_id INTEGER, evolved_species_id INTEGER NOT NULL,
  trigger_id INTEGER NOT NULL, version_group_id INTEGER, is_default INTEGER NOT NULL,
  trigger_item_id INTEGER, min_level INTEGER, gender_id INTEGER, location_id INTEGER,
  held_item_id INTEGER, time_of_day TEXT, known_move_id INTEGER, known_move_type_id INTEGER,
  min_happiness INTEGER, min_beauty INTEGER, min_affection INTEGER,
  relative_physical_stats INTEGER, party_species_id INTEGER, party_type_id INTEGER,
  trade_species_id INTEGER, needs_overworld_rain INTEGER NOT NULL,
  turn_upside_down INTEGER NOT NULL, needs_multiplayer INTEGER NOT NULL,
  near_special_rock INTEGER NOT NULL, region_id INTEGER,
  required_pokemon_form_id INTEGER, evolved_pokemon_form_id INTEGER,
  used_move_id INTEGER, min_move_count INTEGER, min_steps INTEGER,
  min_damage_taken INTEGER, nature_bitmask INTEGER, condition_expression TEXT,
  percentage_chance INTEGER);
CREATE INDEX evolutions_chain_idx ON evolutions (evolution_chain_id);
CREATE TABLE evolution_version_groups (evolution_id INTEGER NOT NULL, version_group_id INTEGER NOT NULL,
  min_happiness INTEGER, PRIMARY KEY (version_group_id, evolution_id)) WITHOUT ROWID;
CREATE TABLE evolution_variables (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, symbol TEXT NOT NULL,
  data_type TEXT, version_group_id INTEGER, source TEXT, name TEXT, description TEXT);
CREATE TABLE natures (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  increased_stat TEXT, decreased_stat TEXT, likes_flavor TEXT, hates_flavor TEXT,
  game_index INTEGER NOT NULL);

CREATE TABLE locations (id INTEGER PRIMARY KEY, region_id INTEGER, identifier TEXT NOT NULL,
  name TEXT NOT NULL, subtitle TEXT);
CREATE TABLE location_areas (id INTEGER PRIMARY KEY, location_id INTEGER NOT NULL,
  identifier TEXT, name TEXT);
CREATE TABLE encounter_methods (id INTEGER PRIMARY KEY, identifier TEXT NOT NULL, name TEXT NOT NULL,
  sort_order INTEGER);
CREATE TABLE encounter_condition_values (id INTEGER PRIMARY KEY, condition_identifier TEXT NOT NULL,
  identifier TEXT NOT NULL, name TEXT NOT NULL, is_default INTEGER NOT NULL);
CREATE TABLE encounters (id INTEGER PRIMARY KEY, version_id INTEGER NOT NULL,
  location_area_id INTEGER NOT NULL, pokemon_id INTEGER NOT NULL, method_id INTEGER NOT NULL,
  min_level INTEGER, max_level INTEGER, rarity INTEGER, slots INTEGER NOT NULL);
CREATE INDEX encounters_pokemon_idx ON encounters (pokemon_id, version_id);
CREATE INDEX encounters_area_idx ON encounters (version_id, location_area_id);
CREATE TABLE encounter_conditions (encounter_id INTEGER NOT NULL, condition_value_id INTEGER NOT NULL,
  PRIMARY KEY (encounter_id, condition_value_id)) WITHOUT ROWID;
"""


# --------------------------------------------------------------------------
# Build
# --------------------------------------------------------------------------

def insert(db, table, rows):
    rows = list(rows)
    if not rows:
        return 0
    cols = list(rows[0].keys())
    db.executemany(
        f"INSERT INTO {table} ({','.join(cols)}) VALUES ({','.join('?' * len(cols))})",
        [tuple(r[c] for c in cols) for r in rows])
    return len(rows)


def latest_flavor(rows, key, text_col="flavor_text", lang_col="language_id"):
    """Texto en do version group mais recente por chave (fallback de efeito)."""
    best: dict[int, tuple[int, str]] = {}
    for r in rows:
        if r[lang_col] != EN or not r[text_col]:
            continue
        k, vg = int(r[key]), int(r["version_group_id"])
        if k not in best or vg > best[k][0]:
            best[k] = (vg, r[text_col])
    return {k: v[1] for k, v in best.items()}


def build(db: sqlite3.Connection, C: Csv, sha: str, commit_date: str):
    db.executescript(SCHEMA)

    # ---- regiões, gerações, jogos -----------------------------------------
    region_names = C.names("region_names", "region_id")
    insert(db, "regions", ({"id": int(r["id"]), "identifier": r["identifier"],
                            "name": region_names.get(int(r["id"]), humanize(r["identifier"]))}
                           for r in C("regions")))
    gen_names = C.names("generation_names", "generation_id")
    insert(db, "generations", ({"id": int(r["id"]), "identifier": r["identifier"],
                                "name": gen_names.get(int(r["id"]), humanize(r["identifier"])),
                                "main_region_id": i(r["main_region_id"])}
                               for r in C("generations")))
    vgs = {int(r["id"]): r for r in C("version_groups")}
    missing_vg = set(vgs) - set(VERSION_GROUP_NAMES)
    if missing_vg:
        print(f"AVISO: version groups sem nome curado: {sorted(missing_vg)}", file=sys.stderr)
    version_names = C.names("version_names", "version_id")
    versions = {int(r["id"]): r for r in C("versions")}
    version_vg = {vid: int(r["version_group_id"]) for vid, r in versions.items()}
    for child, parent in VERSION_PARENT.items():
        assert version_vg[child] in VERSION_GROUP_PARENT and \
            VERSION_GROUP_PARENT[version_vg[child]] == version_vg[parent], (child, parent)

    def family(vg):
        """O version group, o pai e os filhos (DLC instalado)."""
        root = VERSION_GROUP_PARENT.get(vg, vg)
        return {root} | {c for c, p in VERSION_GROUP_PARENT.items() if p == root}

    enc_vgs = {version_vg[int(r["version_id"])] for r in C("encounters")}

    def route_source(vg):
        if vg in FREE_TEXT_ROUTES:
            return "free-text"
        return "encounters" if family(vg) & enc_vgs else "region-locations"

    insert(db, "version_groups", ({
        "id": vid, "identifier": r["identifier"],
        "name": VERSION_GROUP_NAMES.get(vid, humanize(r["identifier"])),
        "generation_id": int(r["generation_id"]), "sort_order": int(r["order"]),
        "parent_id": VERSION_GROUP_PARENT.get(vid),
        "is_dlc": int(vid in DLC_VERSION_GROUPS),
        "is_closed_dex": int(vid in CLOSED_DEX_VERSION_GROUPS),
        "national_dex_size": NATIONAL_DEX_SIZE.get(vid),
        "has_mega_evolution": int(vid in MEGA_VERSION_GROUPS),
        "route_source": route_source(vid)} for vid, r in vgs.items()))
    for vid, ident in ((44, "red-japan"), (45, "green-japan"), (46, "blue-japan")):
        assert versions[vid]["identifier"] == ident, (vid, versions[vid]["identifier"])
    insert(db, "versions", ({"id": vid, "version_group_id": int(r["version_group_id"]),
                             "identifier": r["identifier"],
                             "name": VERSION_NAMES.get(vid) or version_names.get(vid)
                             or humanize(r["identifier"]),
                             "parent_version_id": VERSION_PARENT.get(vid)}
                            for vid, r in versions.items()))

    dex_names = C.names("pokedex_prose", "pokedex_id")
    dex_sizes = defaultdict(int)
    for r in C("pokemon_dex_numbers"):
        dex_sizes[int(r["pokedex_id"])] += 1
    pokedexes = {int(r["id"]): r for r in C("pokedexes")}
    insert(db, "pokedexes", ({"id": did, "identifier": r["identifier"],
                              "name": dex_names.get(did, humanize(r["identifier"])),
                              "region_id": i(r["region_id"]),
                              "is_main_series": int(r["is_main_series"]),
                              "size": dex_sizes[did]} for did, r in pokedexes.items()))
    insert(db, "pokedex_version_groups", ({"pokedex_id": int(r["pokedex_id"]),
                                           "version_group_id": int(r["version_group_id"])}
                                          for r in C("pokedex_version_groups")))
    insert(db, "pokedex_entries", ({"pokedex_id": int(r["pokedex_id"]),
                                    "species_id": int(r["species_id"]),
                                    "number": int(r["pokedex_number"])}
                                   for r in C("pokemon_dex_numbers")))

    # Regiões de cada version group: CSV + regiões das dex ligadas (Z-A e
    # DLCs não estão em version_group_regions.csv) + herança do pai.
    vg_regions: dict[int, dict[int, str]] = defaultdict(dict)
    for r in C("version_group_regions"):
        vg_regions[int(r["version_group_id"])][int(r["region_id"])] = "pokeapi"
    for r in C("pokedex_version_groups"):
        reg = i(pokedexes[int(r["pokedex_id"])]["region_id"])
        if reg:
            vg_regions[int(r["version_group_id"])].setdefault(reg, "pokedex")
    for child, parent in VERSION_GROUP_PARENT.items():
        for reg in list(vg_regions[parent]):
            vg_regions[child].setdefault(reg, "parent")
        for reg in list(vg_regions[child]):
            vg_regions[parent].setdefault(reg, "dlc")
    insert(db, "version_group_regions", ({"version_group_id": vg, "region_id": reg, "source": src}
                                         for vg, regs in sorted(vg_regions.items())
                                         for reg, src in sorted(regs.items())))

    # ---- tipos --------------------------------------------------------------
    type_names = C.names("type_names", "type_id")
    types = [r for r in C("types") if r["identifier"] in TYPE_NAMES_PT]
    assert len(types) == 18, len(types)
    insert(db, "types", ({"id": int(r["id"]), "identifier": r["identifier"],
                          "name": type_names.get(int(r["id"]), humanize(r["identifier"])),
                          "name_pt": TYPE_NAMES_PT[r["identifier"]],
                          "generation_id": int(r["generation_id"])} for r in types))
    insert(db, "type_efficacy", ({"attacking_type_id": int(r["damage_type_id"]),
                                  "defending_type_id": int(r["target_type_id"]),
                                  "factor": int(r["damage_factor"])}
                                 for r in C("type_efficacy")))
    insert(db, "type_efficacy_past", ({"attacking_type_id": int(r["damage_type_id"]),
                                       "defending_type_id": int(r["target_type_id"]),
                                       "factor": int(r["damage_factor"]),
                                       "generation_id": int(r["generation_id"])}
                                      for r in C("type_efficacy_past")))

    # ---- lookups de espécie -------------------------------------------------
    def lookup(table, base, names_csv, key):
        n = C.names(names_csv, key)
        insert(db, table, ({"id": int(r["id"]), "identifier": r["identifier"],
                            "name": n.get(int(r["id"]), humanize(r["identifier"]))}
                           for r in C(base)))
    lookup("colors", "pokemon_colors", "pokemon_color_names", "pokemon_color_id")
    lookup("shapes", "pokemon_shapes", "pokemon_shape_prose", "pokemon_shape_id")
    lookup("habitats", "pokemon_habitats", "pokemon_habitat_names", "pokemon_habitat_id")
    lookup("growth_rates", "growth_rates", "growth_rate_prose", "growth_rate_id")
    lookup("egg_groups", "egg_groups", "egg_group_prose", "egg_group_id")

    # ---- espécies -----------------------------------------------------------
    sp_names = {int(r["pokemon_species_id"]): r for r in C("pokemon_species_names")
                if r["local_language_id"] == EN}
    species = {int(r["id"]): r for r in C("pokemon_species")}
    insert(db, "species", ({
        "id": sid, "identifier": r["identifier"],
        "name": sp_names.get(sid, {}).get("name") or humanize(r["identifier"]),
        "genus": sp_names.get(sid, {}).get("genus") or None,
        "generation_id": int(r["generation_id"]),
        "evolution_chain_id": i(r["evolution_chain_id"]),
        "evolves_from_species_id": i(r["evolves_from_species_id"]),
        "is_legendary": int(r["is_legendary"]), "is_mythical": int(r["is_mythical"]),
        "is_baby": int(r["is_baby"]), "gender_rate": int(r["gender_rate"]),
        "capture_rate": i(r["capture_rate"]), "base_happiness": i(r["base_happiness"]),
        "hatch_counter": i(r["hatch_counter"]), "growth_rate_id": i(r["growth_rate_id"]),
        "color_id": i(r["color_id"]), "shape_id": i(r["shape_id"]),
        "habitat_id": i(r["habitat_id"]),
        "has_gender_differences": int(r["has_gender_differences"]),
        "forms_switchable": int(r["forms_switchable"]),
        "sort_order": int(r["order"])} for sid, r in species.items()))
    insert(db, "species_egg_groups", ({"species_id": int(r["species_id"]),
                                       "egg_group_id": int(r["egg_group_id"])}
                                      for r in C("pokemon_egg_groups")))

    # ---- categorias curadas ---------------------------------------------------
    children = defaultdict(list)
    for sid, r in species.items():
        if r["evolves_from_species_id"]:
            children[int(r["evolves_from_species_id"])].append(sid)

    def line_of(base):
        out, stack = [], [base]
        while stack:
            s = stack.pop()
            out.append(s)
            stack.extend(children[s])
        return out

    def check(sid, ident):
        actual = species[sid]["identifier"]
        assert actual == ident, f"curadoria: {sid} é {actual}, esperado {ident}"

    cats = []
    for sid, ident in ULTRA_BEASTS.items():
        check(sid, ident)
        cats.append((sid, "ultra-beast", None))
    for sid, (ident, note) in PARADOX.items():
        check(sid, ident)
        cats.append((sid, "paradox", note))
    for base, ident in STARTER_BASES.items():
        check(base, ident)
        for s in line_of(base):
            cats.append((s, "starter", "base" if s == base else "evolution"))
    for sid, ident in STARTER_PARTNERS.items():
        check(sid, ident)
        cats.append((sid, "starter", "partner"))
    for base, ident in PSEUDO_BASES.items():
        check(base, ident)
        for s in line_of(base):
            cats.append((s, "pseudo-legendary",
                         "final" if not children[s] else "pre-evolution"))
    insert(db, "species_categories", ({"species_id": s, "category": c, "note": n}
                                      for s, c, n in cats))

    # ---- pokémon + formas -----------------------------------------------------
    forms = {int(r["id"]): r for r in C("pokemon_forms")}
    form_names = {int(r["pokemon_form_id"]): r for r in C("pokemon_form_names")
                  if r["local_language_id"] == EN}
    default_form_of = {}
    for fid, f in forms.items():
        if f["is_default"] == "1":
            default_form_of[int(f["pokemon_id"])] = fid

    stats_by = defaultdict(dict)
    stat_cols = {1: "hp", 2: "attack", 3: "defense", 4: "sp_attack", 5: "sp_defense", 6: "speed"}
    for r in C("pokemon_stats"):
        sid = int(r["stat_id"])
        if sid in stat_cols:
            stats_by[int(r["pokemon_id"])][stat_cols[sid]] = (int(r["base_stat"]), int(r["effort"]))
    types_by = defaultdict(dict)
    for r in C("pokemon_types"):
        types_by[int(r["pokemon_id"])][int(r["slot"])] = int(r["type_id"])
    abil_by = defaultdict(dict)
    for r in C("pokemon_abilities"):
        abil_by[int(r["pokemon_id"])][int(r["slot"])] = (int(r["ability_id"]), int(r["is_hidden"]))

    pokemon_rows = []
    for r in C("pokemon"):
        pid, sid = int(r["id"]), int(r["species_id"])
        ident = r["identifier"]
        fid = default_form_of.get(pid)
        f = forms.get(fid) if fid else None
        fn = form_names.get(fid, {}) if fid else {}
        sname = sp_names.get(sid, {}).get("name") or humanize(species[sid]["identifier"])
        is_default = int(r["is_default"])
        if is_default:
            name = sname
        elif fn.get("pokemon_name"):
            name = fn["pokemon_name"]
        else:
            # Formas sem nome en na PokeAPI (ex.: Koraidon Limited Build).
            rest = ident[len(species[sid]["identifier"]) + 1:] if ident.startswith(
                species[sid]["identifier"] + "-") else ident
            name = f"{sname} ({humanize(rest)})"
        st = stats_by[pid]
        tp = types_by[pid]
        ab = abil_by[pid]
        is_mega = int(bool(f and f["is_mega"] == "1") or "-mega" in ident)
        # Totens (Raticate de Alola Totem, Marowak Totem...) não contam como
        # forma regional: não são capturáveis e têm flag própria.
        is_totem = int("-totem" in ident)
        m = REGIONAL_RE.search(ident)
        regional = m.group(1) if m and not ident.endswith("-cap") and not is_totem else None
        pokemon_rows.append({
            "id": pid, "species_id": sid, "identifier": ident, "name": name,
            "form_name": fn.get("form_name") or None, "is_default": is_default,
            "height": i(r["height"]), "weight": i(r["weight"]),
            "base_experience": i(r["base_experience"]), "sort_order": i(r["order"]),
            "type1_id": tp[1], "type2_id": tp.get(2),
            **{c: st.get(c, (None, None))[0] for c in stat_cols.values()},
            "total": sum(v[0] for v in st.values()) if st else None,
            **{"ev_" + c: st.get(c, (None, None))[1] for c in stat_cols.values()},
            "ability1_id": ab.get(1, (None,))[0], "ability2_id": ab.get(2, (None,))[0],
            "hidden_ability_id": ab.get(3, (None,))[0],
            "is_mega": is_mega, "is_gmax": int(ident.endswith("-gmax")),
            "regional": regional, "is_totem": is_totem, "is_alternate_form": int(not is_default),
            "is_battle_only": int(bool(f and f["is_battle_only"] == "1")),
        })
    insert(db, "pokemon", pokemon_rows)
    pokemon_ids = {p["id"] for p in pokemon_rows}
    pokemon_by_id = {p["id"]: p for p in pokemon_rows}
    pokemon_by_ident = {p["identifier"]: p for p in pokemon_rows}

    # ---- formas por dex e disponibilidade por jogo ----------------------------
    # Encontros brutos por version group (pokémon e espécie).
    enc_pokemon_by_vg = defaultdict(set)
    for r in C("encounters"):
        enc_pokemon_by_vg[version_vg[int(r["version_id"])]].add(int(r["pokemon_id"]))
    # Espécies com forma regional: candidatas = variedade padrão + regionais
    # capturáveis (sem forma de batalha nem totem).
    pair_forms = defaultdict(list)
    for p in pokemon_rows:
        if p["regional"] and not p["is_battle_only"]:
            pair_forms[p["species_id"]].append(p)
    default_pokemon = {p["species_id"]: p for p in pokemon_rows if p["is_default"]}
    dex_vgs = defaultdict(set)
    for r in C("pokedex_version_groups"):
        dex_vgs[int(r["pokedex_id"])].add(int(r["version_group_id"]))
    for dex_ident, ident in EXTRA_DEX_FORMS:
        assert dex_ident in {d["identifier"] for d in pokedexes.values()}, dex_ident
        assert ident in pokemon_by_ident, ident
    entry_forms = []
    for r in C("pokemon_dex_numbers"):
        did, sid = int(r["pokedex_id"]), int(r["species_id"])
        dident = pokedexes[did]["identifier"]
        base = default_pokemon[sid]
        if sid not in pair_forms:
            entry_forms.append((did, sid, base["id"], 1, "default"))
            continue
        region = REGIONAL_DEX.get(dident)
        same_region = sorted((p for p in pair_forms[sid] if p["regional"] == region),
                             key=lambda p: p["id"]) if region else []
        primary = same_region[0] if same_region else base
        seen_enc = set().union(*(enc_pokemon_by_vg[vg] for vg in dex_vgs[did])) \
            if dex_vgs[did] else set()
        rows = {primary["id"]: (1, "regional-dex" if same_region else "default")}
        for p in [base] + pair_forms[sid]:
            if p["id"] in rows:
                continue
            if p in same_region:
                rows[p["id"]] = (0, "regional-dex")
            elif p["id"] in seen_enc:
                rows[p["id"]] = (0, "encounter")
            elif (dident, p["identifier"]) in EXTRA_DEX_FORMS:
                rows[p["id"]] = (0, "curated")
        entry_forms.extend((did, sid, pid, prim, src) for pid, (prim, src) in rows.items())
    insert(db, "pokedex_entry_forms", ({"pokedex_id": d, "species_id": s, "pokemon_id": p,
                                        "is_primary": pr, "source": src}
                                       for d, s, p, pr, src in entry_forms))

    # Disponibilidade por version group. Para regras de evolução, um jogo
    # com DLC conta com as dex e encontros da família (jogo base + DLCs).
    vg_dexes = defaultdict(set)
    for did, vgset in dex_vgs.items():
        for vg in vgset:
            vg_dexes[vg].add(did)
    dex_species = defaultdict(set)
    for r in C("pokemon_dex_numbers"):
        dex_species[int(r["pokedex_id"])].add(int(r["species_id"]))
    dex_pokemon = defaultdict(set)
    for d, s, p, pr, src in entry_forms:
        dex_pokemon[d].add(p)
    species_of_pokemon = {p["id"]: p["species_id"] for p in pokemon_rows}
    vgs_species_rows = []
    avail_species, avail_pokemon = {}, {}
    for vg in sorted(vgs):
        in_dex = set().union(*(dex_species[d] for d in vg_dexes[vg])) if vg_dexes[vg] else set()
        # Jogo base soma os encontros dos DLCs (premissa: DLC instalado).
        own = {vg} | {c for c, p in VERSION_GROUP_PARENT.items()
                      if p == vg and c in DLC_VERSION_GROUPS}
        enc_sp = {species_of_pokemon[p] for v in own for p in enc_pokemon_by_vg[v]
                  if p in species_of_pokemon}
        nat = NATIONAL_DEX_SIZE.get(vg)
        nat_sp = {s for s in species if nat and s <= nat}
        for s in sorted(in_dex | enc_sp | nat_sp):
            vgs_species_rows.append({"version_group_id": vg, "species_id": s,
                                     "in_regional_dex": int(s in in_dex),
                                     "has_encounters": int(s in enc_sp),
                                     "in_national_dex": int(s in nat_sp)})
    for vg in vgs:
        fam = family(vg)
        sp, pk = set(), set()
        for f in fam:
            for d in vg_dexes[f]:
                sp |= dex_species[d]
                pk |= dex_pokemon[d]
            pk |= enc_pokemon_by_vg[f]
            sp |= {species_of_pokemon[p] for p in enc_pokemon_by_vg[f] if p in species_of_pokemon}
            nat = NATIONAL_DEX_SIZE.get(f)
            if nat:
                sp |= {s for s in species if s <= nat}
        # Variedades sabidamente ausentes (só espécies com forma regional):
        # com dado de encontro, padrão/regional sem dex nem encontro; sem
        # encontro, só a variedade padrão quando a dex do jogo lista outra
        # forma como primária e não lista a padrão (Growlithe de Kanto em
        # Legends: Arceus). Regionais de outra região sem evidência ficam.
        has_enc = any(enc_pokemon_by_vg[f] for f in fam)
        absent = set()
        for s in sp & set(pair_forms):
            cands = [default_pokemon[s]] + pair_forms[s]
            if has_enc:
                absent |= {p["id"] for p in cands if p["id"] not in pk}
            elif any(s in dex_species[d] for f in fam for d in vg_dexes[f]) \
                    and default_pokemon[s]["id"] not in pk:
                absent.add(default_pokemon[s]["id"])
        avail_species[vg], avail_pokemon[vg] = sp, absent
    insert(db, "version_group_species", vgs_species_rows)

    pname = {p["id"]: p["name"] for p in pokemon_rows}
    form_by_ident = {f["identifier"]: fid for fid, f in forms.items()}

    def introduced(fid, f):
        vg = i(f["introduced_in_version_group_id"])
        if f["identifier"] in ZA_BASE_MEGAS:
            assert vg in (30, 31) and f["is_mega"] == "1", (f["identifier"], vg)
            return 30
        return vg
    missing = ZA_BASE_MEGAS - set(form_by_ident)
    assert not missing, f"megas de Z-A sem forma: {missing}"
    insert(db, "pokemon_forms", ({
        "id": fid, "pokemon_id": int(f["pokemon_id"]), "identifier": f["identifier"],
        "form_identifier": f["form_identifier"] or None,
        "name": form_names.get(fid, {}).get("pokemon_name") or pname.get(int(f["pokemon_id"]))
        or humanize(f["identifier"]),
        "form_name": form_names.get(fid, {}).get("form_name") or None,
        "is_default": int(f["is_default"]), "is_battle_only": int(f["is_battle_only"]),
        "is_mega": int(f["is_mega"]),
        "introduced_in_version_group_id": introduced(fid, f),
        "form_order": i(f["form_order"]), "sort_order": i(f["order"])}
        for fid, f in forms.items()))
    ft_names = C.names("pokemon_form_trigger_prose", "pokemon_form_trigger_id")
    insert(db, "form_triggers", ({"id": int(r["id"]), "identifier": r["identifier"],
                                  "name": ft_names.get(int(r["id"]), humanize(r["identifier"]))}
                                 for r in C("pokemon_form_triggers")))
    form_cond_rows = [{"pokemon_form_id": int(r["pokemon_form_id"]),
                       "trigger_id": int(r["form_trigger_id"]),
                       "item_id": i(r["trigger_item_id"]),
                       "ability_id": i(r["trigger_ability_id"]),
                       "move_id": i(r["trigger_move_id"]),
                       "base_form_id": i(r["base_form_id"])}
                      for r in C("pokemon_form_conditions")]
    ft_by_ident = {r["identifier"]: int(r["id"]) for r in C("pokemon_form_triggers")}
    move_by_ident = {r["identifier"]: int(r["id"]) for r in C("moves")}
    for form_ident, trig, move in EXTRA_FORM_CONDITIONS:
        fid = form_by_ident[form_ident]
        if any(c["pokemon_form_id"] == fid for c in form_cond_rows):
            print(f"AVISO: {form_ident} já tem condição na PokeAPI; curadoria ignorada",
                  file=sys.stderr)
            continue
        form_cond_rows.append({"pokemon_form_id": fid, "trigger_id": ft_by_ident[trig],
                               "item_id": None, "ability_id": None,
                               "move_id": move_by_ident[move], "base_form_id": None})
    insert(db, "form_conditions", form_cond_rows)
    insert(db, "pokemon_types_past", ({"pokemon_id": int(r["pokemon_id"]),
                                       "generation_id": int(r["generation_id"]),
                                       "slot": int(r["slot"]), "type_id": int(r["type_id"])}
                                      for r in C("pokemon_types_past")))
    stat_ident = {1: "hp", 2: "attack", 3: "defense", 4: "sp_attack", 5: "sp_defense",
                  6: "speed", 9: "special"}
    insert(db, "pokemon_stats_past", ({"pokemon_id": int(r["pokemon_id"]),
                                       "generation_id": int(r["generation_id"]),
                                       "stat": stat_ident.get(int(r["stat_id"]), r["stat_id"]),
                                       "base_stat": int(r["base_stat"])}
                                      for r in C("pokemon_stats_past")))

    # ---- habilidades ----------------------------------------------------------
    ab_names = C.names("ability_names", "ability_id")
    ab_prose = C.names("ability_prose", "ability_id", "short_effect")
    ab_flavor = latest_flavor(C("ability_flavor_text"), "ability_id")
    used_abilities = {int(r["ability_id"]) for r in C("pokemon_abilities")}
    abil_rows = []
    for r in C("abilities"):
        aid = int(r["id"])
        if r["is_main_series"] != "1" and aid not in used_abilities:
            continue
        eff = clean_text(ab_prose.get(aid))
        abil_rows.append({"id": aid, "identifier": r["identifier"],
                          "name": ab_names.get(aid, humanize(r["identifier"])),
                          "short_effect": eff or clean_text(ab_flavor.get(aid)),
                          "effect_is_flavor": int(not eff and aid in ab_flavor),
                          "generation_id": int(r["generation_id"])})
    insert(db, "abilities", abil_rows)
    insert(db, "pokemon_abilities", ({"pokemon_id": int(r["pokemon_id"]), "slot": int(r["slot"]),
                                      "ability_id": int(r["ability_id"]),
                                      "is_hidden": int(r["is_hidden"])}
                                     for r in C("pokemon_abilities")))
    insert(db, "pokemon_abilities_past", ({"pokemon_id": int(r["pokemon_id"]),
                                           "generation_id": int(r["generation_id"]),
                                           "slot": int(r["slot"]),
                                           "ability_id": i(r["ability_id"]),
                                           "is_hidden": int(r["is_hidden"])}
                                          for r in C("pokemon_abilities_past")))

    # ---- itens ----------------------------------------------------------------
    evo = C("pokemon_evolution")
    evo_held = {i(r["held_item_id"]) for r in evo} - {None}
    evo_items = ({i(r["trigger_item_id"]) for r in evo} | evo_held
                 | {i(r["baby_trigger_item_id"]) for r in C("evolution_chains")}) - {None}
    cat_names = C.names("item_category_prose", "item_category_id")
    cats_rows = {int(r["id"]): r for r in C("item_categories")}
    insert(db, "item_categories", ({"id": cid, "identifier": r["identifier"],
                                    "name": cat_names.get(cid, humanize(r["identifier"])),
                                    "pocket_id": i(r["pocket_id"])}
                                   for cid, r in cats_rows.items()))
    mega_cat = {cid for cid, r in cats_rows.items() if r["identifier"] == "mega-stones"}
    holdable = {int(r["item_id"]) for r in C("item_flag_map") if r["item_flag_id"] in ("5", "6", "7")}
    it_names = C.names("item_names", "item_id")
    it_prose = C.names("item_prose", "item_id", "short_effect")
    it_flavor = latest_flavor(C("item_flavor_text"), "item_id", lang_col="language_id")
    item_rows = []
    for r in C("items"):
        iid = int(r["id"])
        eff = clean_text(it_prose.get(iid))
        is_mega = int(i(r["category_id"]) in mega_cat)
        is_evo = int(iid in evo_items)
        item_rows.append({"id": iid, "identifier": r["identifier"],
                          "name": it_names.get(iid, humanize(r["identifier"])),
                          "category_id": i(r["category_id"]),
                          "short_effect": eff or clean_text(it_flavor.get(iid)),
                          "effect_is_flavor": int(not eff and iid in it_flavor),
                          "is_holdable": int(iid in holdable or iid in evo_held
                                             or bool(is_mega)),
                          "is_evolution_item": is_evo, "is_mega_stone": is_mega})
    insert(db, "items", item_rows)
    item_ident = {r["id"]: r["identifier"] for r in item_rows}

    # ---- golpes ---------------------------------------------------------------
    insert(db, "damage_classes", ({"id": int(r["id"]), "identifier": r["identifier"]}
                                  for r in C("move_damage_classes")))
    mv_names = C.names("move_names", "move_id")
    mv_eff = C.names("move_effect_prose", "move_effect_id", "short_effect")
    mv_flavor = latest_flavor(C("move_flavor_text"), "move_id")
    valid_types = {int(t["id"]) for t in types}
    move_rows = []
    for r in C("moves"):
        mid = int(r["id"])
        if mid >= 10000:  # golpes Shadow (Colosseum/XD) e afins
            continue
        chance = i(r["effect_chance"])
        eff = mv_eff.get(i(r["effect_id"])) if r["effect_id"] else None
        if eff:
            eff = eff.replace("$effect_chance", str(chance) if chance is not None else "")
        eff = clean_text(eff)
        tid = i(r["type_id"])
        # A PokeAPI grava 0 em vez de vazio em alguns golpes da gen 8/9
        # (status com poder 0, Tachyon Cutter com precisão 0). Nenhum golpe
        # tem poder 0 nem precisão 0%: 0 vira NULL ("—").
        move_rows.append({"id": mid, "identifier": r["identifier"],
                          "name": mv_names.get(mid, humanize(r["identifier"])),
                          "type_id": tid if tid in valid_types else None,
                          "power": i(r["power"]) or None, "pp": i(r["pp"]),
                          "accuracy": i(r["accuracy"]) or None, "priority": i(r["priority"]),
                          "damage_class_id": i(r["damage_class_id"]),
                          "generation_id": i(r["generation_id"]), "effect_chance": chance,
                          "short_effect": eff or clean_text(mv_flavor.get(mid)),
                          "effect_is_flavor": int(not eff and mid in mv_flavor)})
    insert(db, "moves", move_rows)
    move_ids = {m["id"] for m in move_rows}
    mm_names = C.names("pokemon_move_method_prose", "pokemon_move_method_id")
    insert(db, "move_methods", ({"id": int(r["id"]), "identifier": r["identifier"],
                                 "name": mm_names.get(int(r["id"]), humanize(r["identifier"]))}
                                for r in C("pokemon_move_methods")))
    it_name_by_id = {r["id"]: r["name"] for r in item_rows}
    seen = set()
    mach = []
    for r in C("machines"):
        key = (int(r["version_group_id"]), int(r["move_id"]), int(r["item_id"]))
        if key in seen or key[1] not in move_ids:
            continue
        seen.add(key)
        num = int(r["machine_number"])
        label = it_name_by_id.get(key[2]) or item_ident.get(key[2], "").upper()
        # HMs viraram MT nos jogos sem HM (BDSP: HM01..HM08 são TM93..TM100).
        # Nos jogos com HM, a PokeAPI numera as HMs acima de 100.
        if item_ident.get(key[2], "").startswith("hm") and num <= 100:
            label = f"TM{num:02d}"
        mach.append({"version_group_id": key[0], "move_id": key[1], "item_id": key[2],
                     "machine_number": num, "label": label})
    # BDSP: completa as 100 MTs (a PokeAPI só tem 17), conferindo contra o CSV.
    mv_by_ident = {m["identifier"]: m["id"] for m in move_rows}
    it_by_ident = {v: k for k, v in item_ident.items()}
    assert len(BDSP_TMS) == 100 and len(set(BDSP_TMS)) == 100
    have = {(m["machine_number"], m["move_id"]) for m in mach if m["version_group_id"] == 23}
    for num, ident in enumerate(BDSP_TMS, 1):
        mid = mv_by_ident[ident]
        assert all(n != num or mv == mid for n, mv in have), f"BDSP TM{num}: diverge da PokeAPI"
        if (num, mid) in have:
            continue
        iid = it_by_ident[f"tm{num:02d}"]
        mach.append({"version_group_id": 23, "move_id": mid, "item_id": iid,
                     "machine_number": num, "label": f"TM{num:02d}"})
    insert(db, "machines", mach)
    bdsp_learn = {int(r["move_id"]) for r in C("pokemon_moves")
                  if r["version_group_id"] == "23" and r["pokemon_move_method_id"] == "4"}
    bdsp_tm = {mv_by_ident[x] for x in BDSP_TMS}
    if bdsp_learn - bdsp_tm:
        print(f"AVISO: golpes de máquina do BDSP fora da lista de MTs: "
              f"{sorted(bdsp_learn - bdsp_tm)}", file=sys.stderr)
    insert(db, "learnsets", ({"pokemon_id": int(r["pokemon_id"]),
                              "version_group_id": int(r["version_group_id"]),
                              "method_id": int(r["pokemon_move_method_id"]),
                              "level": int(r["level"] or 0), "move_id": int(r["move_id"]),
                              "sort_order": i(r["order"]), "mastery": i(r["mastery"])}
                             for r in C("pokemon_moves")
                             if int(r["move_id"]) in move_ids
                             and int(r["pokemon_id"]) in pokemon_ids))

    # ---- evolução -------------------------------------------------------------
    insert(db, "evolution_chains", ({"id": int(r["id"]),
                                     "baby_trigger_item_id": i(r["baby_trigger_item_id"])}
                                    for r in C("evolution_chains")))
    trig_names = C.names("evolution_trigger_prose", "evolution_trigger_id")
    insert(db, "evolution_triggers", ({"id": int(r["id"]), "identifier": r["identifier"],
                                       "name": trig_names.get(int(r["id"]), humanize(r["identifier"]))}
                                      for r in C("evolution_triggers")))
    known_cols = {
        "id", "evolved_species_id", "evolution_trigger_id", "version_group_id", "is_default",
        "trigger_item_id", "minimum_level", "gender_id", "location_id", "held_item_id",
        "time_of_day", "known_move_id", "known_move_type_id", "minimum_happiness",
        "minimum_beauty", "minimum_affection", "relative_physical_stats", "party_species_id",
        "party_type_id", "trade_species_id", "needs_overworld_rain", "turn_upside_down",
        "needs_multiplayer", "near_special_rock", "region_id", "required_pokemon_form_id",
        "evolved_pokemon_form_id", "used_move_id", "minimum_move_count", "minimum_steps",
        "minimum_damage_taken", "nature_bitmask", "condition_expression", "percentage_chance"}
    extra = set(evo[0].keys()) - known_cols
    if extra:
        print(f"AVISO: colunas novas em pokemon_evolution.csv não mapeadas: {sorted(extra)}",
              file=sys.stderr)
    evo_rows = []
    for r in evo:
        esid = int(r["evolved_species_id"])
        evo_rows.append({
            "id": int(r["id"]),
            "evolution_chain_id": int(species[esid]["evolution_chain_id"]),
            "from_species_id": i(species[esid]["evolves_from_species_id"]),
            "evolved_species_id": esid, "trigger_id": int(r["evolution_trigger_id"]),
            "version_group_id": i(r["version_group_id"]), "is_default": int(r["is_default"] or 0),
            "trigger_item_id": i(r["trigger_item_id"]), "min_level": i(r["minimum_level"]),
            "gender_id": i(r["gender_id"]), "location_id": i(r["location_id"]),
            "held_item_id": i(r["held_item_id"]), "time_of_day": r["time_of_day"] or None,
            "known_move_id": i(r["known_move_id"]), "known_move_type_id": i(r["known_move_type_id"]),
            "min_happiness": i(r["minimum_happiness"]), "min_beauty": i(r["minimum_beauty"]),
            "min_affection": i(r["minimum_affection"]),
            "relative_physical_stats": i(r["relative_physical_stats"]),
            "party_species_id": i(r["party_species_id"]), "party_type_id": i(r["party_type_id"]),
            "trade_species_id": i(r["trade_species_id"]),
            "needs_overworld_rain": int(r["needs_overworld_rain"] or 0),
            "turn_upside_down": int(r["turn_upside_down"] or 0),
            "needs_multiplayer": int(r["needs_multiplayer"] or 0),
            "near_special_rock": int(r["near_special_rock"] or 0),
            "region_id": i(r["region_id"]),
            "required_pokemon_form_id": i(r["required_pokemon_form_id"]),
            "evolved_pokemon_form_id": i(r["evolved_pokemon_form_id"]),
            "used_move_id": i(r["used_move_id"]), "min_move_count": i(r["minimum_move_count"]),
            "min_steps": i(r["minimum_steps"]), "min_damage_taken": i(r["minimum_damage_taken"]),
            "nature_bitmask": i(r["nature_bitmask"]),
            "condition_expression": r["condition_expression"] or None,
            "percentage_chance": i(r["percentage_chance"])})
    # Forma exigida implícita: quando a espécie de origem tem regra para uma
    # variedade não padrão (forma regional, Pikachu de boné, Eevee parceiro),
    # a regra sem forma exigida vale só para a variedade padrão. Preenche
    # required_pokemon_form_id com a forma padrão dela (como a PokeAPI já faz
    # com Pikachu e Eevee). Variações cosméticas da mesma variedade (Burmy,
    # Shellos, Deerling...) não contam: Burmy de qualquer capa vira Mothim.
    form_pokemon = {fid: int(f["pokemon_id"]) for fid, f in forms.items()}
    variant_sources = {e["from_species_id"] for e in evo_rows
                       if e["required_pokemon_form_id"] is not None
                       and not pokemon_by_id[form_pokemon[e["required_pokemon_form_id"]]]["is_default"]}
    filled = 0
    for e in evo_rows:
        if e["required_pokemon_form_id"] is None and e["from_species_id"] in variant_sources:
            e["required_pokemon_form_id"] = default_form_of[default_pokemon[e["from_species_id"]]["id"]]
            filled += 1
    insert(db, "evolutions", evo_rows)
    print(f"evolutions: {filled} regras com forma exigida padrão preenchida", file=sys.stderr)

    insert(db, "evolution_variables", ({
        "id": int(r["id"]), "identifier": r["identifier"], "symbol": r["symbol"],
        "data_type": r["data_type"] or None, "version_group_id": i(r["version_group_id"]),
        "source": r["source"] or None,
        "name": next((p["name"] for p in C("evolution_variable_prose")
                      if p["evolution_variable_id"] == r["id"] and p["local_language_id"] == EN), None),
        "description": next((p["description"] for p in C("evolution_variable_prose")
                             if p["evolution_variable_id"] == r["id"]
                             and p["local_language_id"] == EN), None)}
        for r in C("evolution_variables")))

    # Naturezas. Neutras (aumenta = diminui) ficam com stat/sabor NULL. O bit
    # i de evolutions.nature_bitmask corresponde a natures.id = i + 1.
    nat_names = C.names("nature_names", "nature_id")
    flavor = {int(r["contest_type_id"]): r["flavor"].lower() for r in C("contest_type_names")
              if r["local_language_id"] == EN}
    nat_rows = []
    for r in C("natures"):
        neutral = r["increased_stat_id"] == r["decreased_stat_id"]
        nat_rows.append({
            "id": int(r["id"]), "identifier": r["identifier"],
            "name": nat_names.get(int(r["id"]), humanize(r["identifier"])),
            "increased_stat": None if neutral else stat_cols[int(r["increased_stat_id"])],
            "decreased_stat": None if neutral else stat_cols[int(r["decreased_stat_id"])],
            "likes_flavor": None if neutral else flavor[int(r["likes_flavor_id"])],
            "hates_flavor": None if neutral else flavor[int(r["hates_flavor_id"])],
            "game_index": int(r["game_index"])})
    assert len(nat_rows) == 25, len(nat_rows)
    insert(db, "natures", nat_rows)

    location_region = {int(r["id"]): i(r["region_id"]) for r in C("locations")}
    species_gen = {sid: int(r["generation_id"]) for sid, r in species.items()}
    absent_items = {vg: {it_by_ident[x] for x in idents} for vg, idents in ITEMS_ABSENT_IN.items()}

    # Variedade obtida por evolução de outra disponível não está ausente
    # (Graveler de Alola em Let's Go vem do Geodude de Alola).
    def var_of(form_id, sid):
        return form_pokemon[form_id] if form_id is not None else default_pokemon[sid]["id"]
    for vg, absent_pk in avail_pokemon.items():
        if vg in NO_REGIONAL_FORMS_IN:
            absent_pk |= {p["id"] for ps in pair_forms.values() for p in ps}
            continue
        regs = set(vg_regions.get(vg, {}))
        by_region = {(e["evolved_species_id"], e["required_pokemon_form_id"])
                     for e in evo_rows if e["region_id"] in regs}
        changed = True
        while changed:
            changed = False
            for e in evo_rows:
                if e["region_id"] is None and (e["evolved_species_id"],
                                               e["required_pokemon_form_id"]) in by_region:
                    continue  # Goomy em Hisui só vira Sliggoo de Hisui
                if e["region_id"] is not None and e["region_id"] not in regs:
                    continue
                vs = var_of(e["required_pokemon_form_id"], e["from_species_id"])
                vd = var_of(e["evolved_pokemon_form_id"], e["evolved_species_id"])
                if vd in absent_pk and vs not in absent_pk \
                        and e["from_species_id"] in avail_species[vg]:
                    absent_pk.discard(vd)
                    changed = True
    ctx = {"species_gen": species_gen, "avail_species": avail_species,
           "avail_pokemon": avail_pokemon, "form_pokemon": form_pokemon,
           "default_form_pokemon": {sid: p["id"] for sid, p in default_pokemon.items()},
           "absent_items": absent_items}
    happy_rules = {e["id"] for e in evo_rows if e["min_happiness"] is not None}
    insert(db, "evolution_version_groups",
           ({"evolution_id": e, "version_group_id": vg,
             "min_happiness": happiness_for_gen(int(vgs[vg]["generation_id"]))
             if e in happy_rules else None}
            for vg, e in evolution_applicability(evo_rows, vgs, vg_regions, location_region, ctx)))

    # ---- locais e encontros ---------------------------------------------------
    loc_names = {int(r["location_id"]): r for r in C("location_names")
                 if r["local_language_id"] == EN}
    insert(db, "locations", ({"id": int(r["id"]), "region_id": i(r["region_id"]),
                              "identifier": r["identifier"],
                              "name": loc_names.get(int(r["id"]), {}).get("name")
                              or humanize(r["identifier"]),
                              "subtitle": loc_names.get(int(r["id"]), {}).get("subtitle") or None}
                             for r in C("locations")))
    area_names = C.names("location_area_prose", "location_area_id")
    insert(db, "location_areas", ({"id": int(r["id"]), "location_id": int(r["location_id"]),
                                   "identifier": r["identifier"] or None,
                                   "name": area_names.get(int(r["id"])) or None}
                                  for r in C("location_areas")))
    em_names = C.names("encounter_method_prose", "encounter_method_id")
    insert(db, "encounter_methods", ({"id": int(r["id"]), "identifier": r["identifier"],
                                      "name": em_names.get(int(r["id"]), humanize(r["identifier"])),
                                      "sort_order": i(r["order"])}
                                     for r in C("encounter_methods")))
    cond_ident = {int(r["id"]): r["identifier"] for r in C("encounter_conditions")}
    ecv_names = C.names("encounter_condition_value_prose", "encounter_condition_value_id")
    insert(db, "encounter_condition_values", ({
        "id": int(r["id"]), "condition_identifier": cond_ident.get(int(r["encounter_condition_id"]), ""),
        "identifier": r["identifier"],
        "name": ecv_names.get(int(r["id"]), humanize(r["identifier"])),
        "is_default": int(r["is_default"])} for r in C("encounter_condition_values")))

    # Agrega slots: mesmo (versão, área, pokémon, método, condições) vira uma
    # linha com faixa de nível e soma de raridade.
    slots = {int(r["id"]): r for r in C("encounter_slots")}
    conds = defaultdict(list)
    for r in C("encounter_condition_value_map"):
        conds[int(r["encounter_id"])].append(int(r["encounter_condition_value_id"]))
    groups: dict[tuple, dict] = {}
    for r in C("encounters"):
        eid = int(r["id"])
        slot = slots[int(r["encounter_slot_id"])]
        key = (int(r["version_id"]), int(r["location_area_id"]), int(r["pokemon_id"]),
               int(slot["encounter_method_id"]), tuple(sorted(conds.get(eid, ()))))
        g = groups.get(key)
        lo, hi, rar = i(r["min_level"]), i(r["max_level"]), i(slot["rarity"])
        if g is None:
            groups[key] = {"min": lo, "max": hi, "rarity": rar, "slots": 1}
        else:
            g["min"] = min(x for x in (g["min"], lo) if x is not None) if (g["min"] or lo) else None
            g["max"] = max(x for x in (g["max"], hi) if x is not None) if (g["max"] or hi) else None
            g["rarity"] = (g["rarity"] or 0) + (rar or 0) if (g["rarity"] is not None or rar) else None
            g["slots"] += 1
    enc_rows, enc_conds = [], []
    for n, (key, g) in enumerate(sorted(groups.items(), key=lambda kv: kv[0][:4] + (kv[0][4],)), 1):
        enc_rows.append({"id": n, "version_id": key[0], "location_area_id": key[1],
                         "pokemon_id": key[2], "method_id": key[3], "min_level": g["min"],
                         "max_level": g["max"], "rarity": g["rarity"], "slots": g["slots"]})
        enc_conds.extend({"encounter_id": n, "condition_value_id": c} for c in key[4])
    insert(db, "encounters", enc_rows)
    insert(db, "encounter_conditions", enc_conds)

    # ---- meta -----------------------------------------------------------------
    meta = {
        "schema_version": str(SCHEMA_VERSION),
        "built_at": _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat(),
        "pokeapi_sha": sha,
        "pokeapi_commit_date": commit_date,
        "source": "https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv",
        "encounters_raw_rows": str(len(C("encounters"))),
    }
    db.executemany("INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)", meta.items())


def evolution_applicability(evo_rows, vgs, vg_regions, location_region, ctx):
    """Deriva em quais version groups cada regra de evolução vale.

    A PokeAPI guarda em `version_group_id` o jogo em que a regra foi
    registrada (válida dali em diante até ser substituída), não a lista de
    jogos. Heurística (documentada em docs/DATA.md):
      1. DLC e variantes japonesas usam a ordem do jogo pai.
      2. Só regras com ordem <= ordem do jogo alvo.
      3. Espécies de origem e evoluída têm de existir no jogo: geração <= a
         do jogo; Dex Nacional, se houver; nos jogos de dex fechada, dex ou
         encontro da família do jogo (e a variedade exigida/resultante
         também).
      4. Gatilhos presos a um jogo (TRIGGER_ONLY_IN), Beauty só nos jogos
         com o atributo, item que não existe no jogo (ITEMS_ABSENT_IN).
      5. Regra com location_id só vale se a região do local for uma das
         regiões do jogo e o jogo for da mesma geração da regra ou remake
         (REMAKE_OF); regra com region_id só na região.
      6. Para cada (espécie evoluída, forma evoluída, forma exigida,
         gatilho), fica só o grupo de regras mais recente.
      7. Se a família do jogo (ou, sem regra própria nenhuma, o último jogo
         anterior que registrou regras) registrou regra para (espécie
         evoluída, forma evoluída, forma exigida), as herdadas de jogos
         anteriores com outro gatilho saem, exceto regras por local e
         KEEP_INHERITED.
      8. Se sobrar regra com region_id da região do jogo, as regras sem
         region_id da mesma espécie/forma exigida saem (Pikachu em Alola só
         vira Raichu de Alola).
    """
    def root(vg):
        return VERSION_GROUP_PARENT.get(vg, vg)

    def eff_order(vg):
        return int(vgs[root(vg)]["order"])

    species_gen = ctx["species_gen"]
    form_pokemon = ctx["form_pokemon"]
    default_pk = ctx["default_form_pokemon"]
    registering = {root(e["version_group_id"]) for e in evo_rows if e["version_group_id"]}

    def variety(form_id, species_id):
        return form_pokemon[form_id] if form_id is not None else default_pk[species_id]

    out = []
    for target in sorted(vgs):
        t_order = eff_order(target)
        t_gen = int(vgs[target]["generation_id"])
        regions = set(vg_regions.get(target, {}))
        nat = NATIONAL_DEX_SIZE.get(target)
        closed = target in CLOSED_DEX_VERSION_GROUPS
        sp_ok, pk_absent = ctx["avail_species"][target], ctx["avail_pokemon"][target]
        absent = ctx["absent_items"].get(target, set())
        cand = []
        for e in evo_rows:
            vg = e["version_group_id"]
            if vg is None or eff_order(vg) > t_order:
                continue
            src, dst = e["from_species_id"], e["evolved_species_id"]
            if max(species_gen[src], species_gen[dst]) > t_gen:
                continue
            if nat and max(src, dst) > nat:
                continue
            if closed:
                if src not in sp_ok or dst not in sp_ok:
                    continue
            # Só a variedade de origem: Ponyta de Kanto no IoA vira Rapidash
            # de Kanto mesmo sem encontro do Rapidash.
            if (closed or target in NO_REGIONAL_FORMS_IN) and \
                    variety(e["required_pokemon_form_id"], src) in pk_absent:
                continue
            only = TRIGGER_ONLY_IN.get(e["trigger_id"])
            if only is not None and target not in only:
                continue
            if e["min_beauty"] is not None and target not in BEAUTY_VERSION_GROUPS:
                continue
            if e["trigger_item_id"] in absent or e["held_item_id"] in absent:
                continue
            if e["location_id"] is not None:
                reg = location_region.get(e["location_id"])
                if reg is not None and reg not in regions:
                    continue
                same_gen = vgs[vg]["generation_id"] == vgs[target]["generation_id"]
                if not same_gen and vg not in REMAKE_OF.get(target, ()):
                    continue
            if e["region_id"] is not None and e["region_id"] not in regions:
                continue
            cand.append(e)

        def key3(e):
            return (e["evolved_species_id"], e["evolved_pokemon_form_id"],
                    e["required_pokemon_form_id"])
        best: dict[tuple, int] = {}
        for e in cand:
            k = key3(e) + (e["trigger_id"],)
            best[k] = max(best.get(k, -1), eff_order(e["version_group_id"]))
        kept = [e for e in cand
                if eff_order(e["version_group_id"]) == best[key3(e) + (e["trigger_id"],)]]

        # 7. Jogo que registra a própria regra substitui as herdadas.
        anchor = root(target)
        if anchor not in registering:
            prev = [vg for vg in registering if int(vgs[vg]["order"]) < t_order]
            anchor = max(prev, key=lambda vg: int(vgs[vg]["order"])) if prev else None
        own = {key3(e) for e in kept if root(e["version_group_id"]) == anchor}
        kept = [e for e in kept
                if key3(e) not in own or root(e["version_group_id"]) == anchor
                or e["location_id"] is not None or (target, e["id"]) in KEEP_INHERITED]

        regional = {(e["evolved_species_id"], e["required_pokemon_form_id"])
                    for e in kept if e["region_id"] is not None}
        for e in kept:
            if e["region_id"] is None and (e["evolved_species_id"],
                                           e["required_pokemon_form_id"]) in regional:
                continue
            out.append((target, e["id"]))
    return out


def update_sprite_flags(db: sqlite3.Connection):
    """Marca has_sprite/has_shiny_sprite conforme assets/sprites e grava as
    lacunas em meta. Roda no fim do build e via --sprites-only."""
    pdir = os.path.join(SPRITES, "pokemon")
    sdir = os.path.join(pdir, "shiny")
    idir = os.path.join(SPRITES, "items")

    def ok(path):
        return os.path.isfile(path) and os.path.getsize(path) > 0

    ids = [r[0] for r in db.execute("SELECT id FROM pokemon ORDER BY id")]
    miss, miss_shiny = [], []
    for pid in ids:
        a = ok(os.path.join(pdir, f"{pid}.png"))
        b = ok(os.path.join(sdir, f"{pid}.png"))
        db.execute("UPDATE pokemon SET has_sprite=?, has_shiny_sprite=? WHERE id=?",
                   (int(a), int(b), pid))
        if not a:
            miss.append(pid)
        if not b:
            miss_shiny.append(pid)
    items = db.execute("SELECT id, identifier FROM items WHERE is_evolution_item=1 "
                       "OR is_mega_stone=1").fetchall()
    miss_items = []
    for iid, ident in items:
        a = ok(os.path.join(idir, f"{ident}.png"))
        db.execute("UPDATE items SET has_sprite=? WHERE id=?", (int(a), iid))
        if not a:
            miss_items.append(ident)
    sprites_present = os.path.isdir(pdir)
    meta = {
        "sprites_checked": "1" if sprites_present else "0",
        "missing_sprites": ",".join(map(str, miss)) if sprites_present else "",
        "missing_shiny_sprites": ",".join(map(str, miss_shiny)) if sprites_present else "",
        "missing_item_sprites": ",".join(miss_items) if sprites_present else "",
    }
    db.executemany("INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)", meta.items())
    return miss, miss_shiny, miss_items


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--csv-dir")
    ap.add_argument("--ref", help="commit da PokeAPI para baixar via urllib")
    ap.add_argument("--out", default=DB_PATH)
    ap.add_argument("--sprites-only", action="store_true")
    ap.add_argument("--sprites-sha", help="commit do PokeAPI/sprites (grava em meta)")
    args = ap.parse_args()

    if args.sprites_only:
        db = sqlite3.connect(args.out)
        miss, miss_s, miss_i = update_sprite_flags(db)
        if args.sprites_sha:
            db.execute("INSERT OR REPLACE INTO meta (key, value) VALUES ('sprites_sha', ?)",
                       (args.sprites_sha,))
        db.commit()
        db.execute("VACUUM")
        db.close()
        print(f"sprites: {len(miss)} pokémon sem sprite, {len(miss_s)} sem shiny, "
              f"{len(miss_i)} itens sem sprite")
        return

    csv_dir, sha, date = resolve_csv_dir(args)
    print(f"CSV: {csv_dir} (PokeAPI {sha})")
    C = Csv(csv_dir)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    tmp = args.out + ".tmp"
    if os.path.exists(tmp):
        os.remove(tmp)
    db = sqlite3.connect(tmp)
    db.execute("PRAGMA journal_mode=OFF")
    db.execute("PRAGMA synchronous=OFF")
    db.execute("PRAGMA page_size=4096")
    build(db, C, sha, date)
    update_sprite_flags(db)
    # Preserva o SHA dos sprites de um build anterior (fetch_sprites.sh).
    if os.path.exists(args.out):
        try:
            old = sqlite3.connect(args.out)
            row = old.execute("SELECT value FROM meta WHERE key='sprites_sha'").fetchone()
            old.close()
            if row:
                db.execute("INSERT OR REPLACE INTO meta (key, value) VALUES ('sprites_sha', ?)", row)
        except sqlite3.Error:
            pass
    db.commit()
    db.execute("ANALYZE")
    db.commit()
    db.execute("VACUUM")
    db.close()
    os.replace(tmp, args.out)

    db = sqlite3.connect(args.out)
    tables = [r[0] for r in db.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")]
    for t in tables:
        print(f"{t:28s} {db.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0]:>8d}")
    db.close()
    print(f"tamanho: {os.path.getsize(args.out) / 1024 / 1024:.2f} MiB -> {args.out}")


if __name__ == "__main__":
    main()
