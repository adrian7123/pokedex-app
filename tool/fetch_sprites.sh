#!/usr/bin/env bash
# Baixa os sprites pequenos (96x96) do repo PokeAPI/sprites e copia para
# assets/sprites. Rodar DEPOIS de tool/build_db.py (lê ids e itens do banco).
#
#   bash tool/fetch_sprites.sh
#
# - git partial clone esparso (--filter=blob:none --sparse, no-cone) em
#   .cache/pokeapi-sprites: só baixa os blobs dos padrões pedidos.
# - copia assets/sprites/pokemon/{id}.png, .../shiny/{id}.png para cada
#   pokemon.id do banco, e assets/sprites/items/{identifier}.png só para
#   itens de evolução e megapedras.
# - remove arquivos de 0 byte e chama build_db.py --sprites-only, que marca
#   has_sprite/has_shiny_sprite e grava as lacunas na tabela meta.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="$ROOT/.cache/pokeapi-sprites"
DB="$ROOT/assets/db/pokedex.sqlite"
OUT="$ROOT/assets/sprites"

[ -f "$DB" ] || { echo "rode tool/build_db.py antes" >&2; exit 1; }

if [ ! -d "$CACHE/.git" ]; then
  git clone --depth 1 --filter=blob:none --sparse --no-checkout \
    https://github.com/PokeAPI/sprites.git "$CACHE"
fi
git -C "$CACHE" sparse-checkout set --no-cone \
  '/sprites/pokemon/*.png' \
  '/sprites/pokemon/shiny/*.png' \
  '/sprites/items/*.png'
git -C "$CACHE" checkout
SPRITES_SHA="$(git -C "$CACHE" rev-parse HEAD)"
echo "sprites PokeAPI/sprites @ $SPRITES_SHA"

mkdir -p "$OUT/pokemon/shiny" "$OUT/items"
# Limpa só os PNG (preserva .gitkeep e afins).
find "$OUT/pokemon" "$OUT/items" -maxdepth 2 -name '*.png' -delete

python3 -I - "$DB" "$CACHE/sprites" "$OUT" <<'PY'
import os, shutil, sqlite3, sys
db_path, src, out = sys.argv[1:4]
db = sqlite3.connect(db_path)
ids = [r[0] for r in db.execute("SELECT id FROM pokemon ORDER BY id")]
items = [r[0] for r in db.execute(
    "SELECT identifier FROM items WHERE is_evolution_item=1 OR is_mega_stone=1")]
def cp(a, b):
    if os.path.isfile(a) and os.path.getsize(a) > 0:
        shutil.copyfile(a, b)
        return True
    return False
n = sum(cp(f"{src}/pokemon/{i}.png", f"{out}/pokemon/{i}.png") for i in ids)
s = sum(cp(f"{src}/pokemon/shiny/{i}.png", f"{out}/pokemon/shiny/{i}.png") for i in ids)
it = sum(cp(f"{src}/items/{x}.png", f"{out}/items/{x}.png") for x in items)
print(f"copiados: {n}/{len(ids)} normais, {s}/{len(ids)} shiny, {it}/{len(items)} itens")
PY

find "$OUT" -type f -name '*.png' -size 0 -print -delete
python3 "$ROOT/tool/build_db.py" --sprites-only --sprites-sha "$SPRITES_SHA"
# --apparent-size: tamanho real dos arquivos (o btrfs/ext4 arredonda blocos)
du -sh --apparent-size "$OUT/pokemon" "$OUT/items"
