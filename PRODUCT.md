# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter 3.47 / Dart 3.13, Android + iOS from one codebase (iOS still owes safe areas, Reduce Motion and edge-swipe back). Local data with Drift (SQLite); state with ChangeNotifier, following the owner's other apps (movva-app). Distributed as a signed APK (keystore + `key.properties` versioned in the repo, same pattern as movva-app); no store release for now.

## Users

The owner (Adrian), a Pokémon player who runs several games at once (FireRed, Shield, Violet, Legends Z-A…) and wants one pocket reference while playing: look something up fast, mid-session, often one-handed, often without connection.

## Product Purpose

An offline Pokédex built on PokeAPI data that answers, in seconds, "what is this Pokémon, how does it evolve in *my* game, and do I already have it?". Success: search and filters return instantly offline; the evolution requirement for the game being played is always one tap away; captures (including shiny and full specimen sheets) are tracked per adventure.

## Positioning

Unlike generic Pokédex apps, the active **adventure** (a specific game save) is the lens: dex, evolution rules, moves and progress are all filtered to the game you are playing, while a global collection sums every specimen across adventures.

## Operating Context

- Used beside a console or another phone screen, mid-game, in short bursts.
- Frequent actions: search by name/number, mark captured (one tap) or shiny (long press), check "how does X evolve here".
- Less frequent: filling a specimen sheet (level, nature, ability, ball, IVs/EVs, moves, item), building the team of 6, Nuzlocke encounter log, type-chart lookups.

## Capabilities and Constraints

- **Data, embedded:** a SQLite built by script from PokeAPI CSVs ships inside the app — species, forms, types, every game/DLC regional dex, categories (legendary, mythical, ultra beast, paradox, starter, baby, mega, gigantamax, regional forms), base stats, abilities, egg groups, evolution chains with per-game rules (18 triggers), moves + learnsets, locations per game. Small sprites (normal + shiny) are bundled.
- **Data, on demand + cached:** Pokédex flavor text, encounter details, official artwork / HOME renders. Optional "download all images" later.
- **Data gaps:** PokeAPI has no Z-A moves or flavor text and almost no Scarlet/Violet flavor text; show the most recent game's data with a visible note naming the source game.
- **Language:** UI in pt-BR; PokeAPI data (moves, abilities, flavor text) stays in English (PokeAPI has no pt-BR). Type names are translated by the app.
- **Storage:** local only, no login, no backup/sync.
- **Navigation:** 4 bottom tabs — Pokédex · Aventuras · Coleção · Consulta.
- **Filters (all combinable):** game/regional dex, generation, type (single/dual), categories, my progress (captured, shiny, favourite, marks, can evolve), advanced (ability, move, egg group, stat range, evolution method).
- **Detail:** artwork header + tabs Sobre · Evolução · Golpes · Onde achar · Meus exemplares; a game selector (default: active adventure's game) drives data, moves and evolution rules.
- **Evolution:** horizontal chain; branches (Eevee, Tyrogue) stack vertically in the next column; no horizontal scroll; condition chip per step; captured stages marked.
- **Adventures:** game + regional dex, progress, current team of 6 with combined weaknesses, "can evolve now" list, Nuzlocke (route list from game data + free text, graveyard, rules).
- **Collection:** global union of specimens; multiple specimens per species; quick flags; free custom lists.
- **Type reference:** advantage/disadvantage list, 1–2 type calculator, 18×18 matrix, and per-Pokémon weaknesses.
- **Phasing:** F1 data + list/search/filters + detail (evolution, moves, types) + quick capture + motion. F2 adventures, collection, sheets, lists. F3 Nuzlocke, full type reference, polish.

## Brand Commitments

- App name: **Pokédex**.
- Light theme only.
- Clean, minimal, modern; neutral surfaces with the Pokémon's type colour as the accent. The dataDex app the owner showed is functional reference only — its saturated full-colour cards are explicitly not the look.
- Fluid, functional screen-transition motion (Hero list→detail, shared-axis between tabs), respecting the system reduce-motion setting.

## Evidence on Hand

PokeAPI data and sprites (BSD-3 code/data; images © The Pokémon Company, personal APK use). No invented content needed.

## Product Principles

1. The game you are playing is the lens.
2. Offline and instant beat complete and slow.
3. One tap to record, depth only when asked.
4. The Pokémon artwork is the colour; the interface stays quiet.

## Accessibility & Inclusion

Respect system font scale (sp) and reduce-motion; 48dp touch targets; colour is never the only carrier of type identity (always paired with a name or icon).
