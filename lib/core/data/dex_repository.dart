import 'package:drift/drift.dart' show QueryRow;

import 'dex_database.dart';
import 'models.dart';

/// Acesso ao banco de referência. O índice (todas as variedades, dex, jogos, tipos) fica em
/// memória após [load]; consultas pesadas (golpes, evolução, encontros) vão ao SQLite sob demanda.
class DexRepository {
  DexRepository(this.db);
  final DexDatabase db;

  late final List<DexEntry> entries;
  late final Map<int, DexEntry> byPokemonId;

  /// speciesId → variedade padrão
  late final Map<int, DexEntry> defaultBySpecies;

  /// speciesId → todas as variedades
  late final Map<int, List<DexEntry>> formsBySpecies;
  late final Map<String, TypeInfo> types;
  late final Map<int, TypeInfo> typesById;
  late final List<Generation> generations;
  late final Map<int, Region> regions;
  late final List<VersionGroup> versionGroups;
  late final Map<int, VersionGroup> versionGroupsById;
  late final Map<int, Pokedex> pokedexes;

  /// pokedexId → (speciesId → número regional)
  late final Map<int, Map<int, int>> pokedexNumbers;
  late final List<NamedRef> abilities;
  late final List<NamedRef> eggGroups;
  late final List<NamedRef> moves;
  late final List<NamedRef> evolutionTriggers;

  /// tipo atacante → tipo defensor → fator (0/50/100/200)
  late final Map<String, Map<String, int>> efficacy;

  Future<void> load() async {
    final results = await Future.wait([
      db.rows('SELECT id, identifier, name_pt FROM types ORDER BY id'),
      db.rows('SELECT id, identifier, main_region_id FROM generations ORDER BY id'),
      db.rows('SELECT id, identifier, name FROM regions'),
      db.rows('SELECT id, identifier, name, generation_id, sort_order, parent_id, is_dlc FROM version_groups ORDER BY sort_order'),
      db.rows('SELECT id, identifier, name, version_group_id FROM versions ORDER BY id'),
      db.rows('SELECT pokedex_id, version_group_id FROM pokedex_version_groups'),
      db.rows('SELECT id, identifier, name, region_id, is_main_series, size FROM pokedexes'),
      db.rows('SELECT pokedex_id, species_id, number FROM pokedex_entries'),
      db.rows('''
        SELECT p.id, p.species_id, p.identifier, p.name, p.form_name, p.is_default, p.type1_id, p.type2_id,
               p.hp, p.attack, p.defense, p.sp_attack, p.sp_defense, p.speed, p.total, p.height, p.weight,
               p.is_mega, p.is_gmax, p.regional, p.is_battle_only, p.has_sprite, p.has_shiny_sprite,
               p.ability1_id, p.ability2_id, p.hidden_ability_id, p.sort_order,
               s.name AS species_name, s.genus, s.generation_id, s.is_legendary, s.is_mythical, s.is_baby,
               s.evolution_chain_id, s.evolves_from_species_id, s.sort_order AS species_order
        FROM pokemon p JOIN species s ON s.id = p.species_id
        ORDER BY s.sort_order, p.is_default DESC, p.sort_order, p.id'''),
      db.rows('SELECT species_id, category, note FROM species_categories'),
      db.rows('SELECT species_id, egg_group_id FROM species_egg_groups'),
      db.rows('SELECT DISTINCT from_species_id, trigger_id FROM evolutions WHERE from_species_id IS NOT NULL'),
      db.rows('SELECT id, name FROM abilities ORDER BY name'),
      db.rows('SELECT id, name FROM egg_groups ORDER BY name'),
      db.rows('SELECT id, name FROM moves ORDER BY name'),
      db.rows('SELECT id, name FROM evolution_triggers ORDER BY id'),
      db.rows('''SELECT a.identifier AS atk, d.identifier AS def, e.factor FROM type_efficacy e
                 JOIN types a ON a.id = e.attacking_type_id JOIN types d ON d.id = e.defending_type_id'''),
    ]);

    typesById = {
      for (final r in results[0]) r.i('id'): TypeInfo(id: r.i('id'), identifier: r.s('identifier'), namePt: r.s('name_pt')),
    };
    types = {for (final t in typesById.values) t.identifier: t};
    generations = [
      for (final r in results[1])
        Generation(id: r.i('id'), identifier: r.s('identifier'), mainRegionId: r.ni('main_region_id')),
    ];
    regions = {for (final r in results[2]) r.i('id'): Region(id: r.i('id'), identifier: r.s('identifier'), name: r.s('name'))};

    final versionsByVg = <int, List<Version>>{};
    for (final r in results[4]) {
      final v = Version(id: r.i('id'), identifier: r.s('identifier'), name: r.s('name'), versionGroupId: r.i('version_group_id'));
      versionsByVg.putIfAbsent(v.versionGroupId, () => []).add(v);
    }
    final dexByVg = <int, List<int>>{};
    for (final r in results[5]) {
      dexByVg.putIfAbsent(r.i('version_group_id'), () => []).add(r.i('pokedex_id'));
    }
    versionGroups = [
      for (final r in results[3])
        VersionGroup(
          id: r.i('id'),
          identifier: r.s('identifier'),
          name: r.s('name'),
          generationId: r.i('generation_id'),
          sortOrder: r.i('sort_order'),
          parentId: r.ni('parent_id'),
          isDlc: r.b('is_dlc'),
          versions: versionsByVg[r.i('id')] ?? const [],
          pokedexIds: (dexByVg[r.i('id')] ?? [])..sort(),
        ),
    ];
    versionGroupsById = {for (final v in versionGroups) v.id: v};

    pokedexes = {
      for (final r in results[6])
        r.i('id'): Pokedex(
          id: r.i('id'),
          identifier: r.s('identifier'),
          name: r.s('name'),
          regionId: r.ni('region_id'),
          isMainSeries: r.b('is_main_series'),
          size: r.i('size'),
        ),
    };
    pokedexNumbers = {};
    for (final r in results[7]) {
      pokedexNumbers.putIfAbsent(r.i('pokedex_id'), () => {})[r.i('species_id')] = r.i('number');
    }

    final cats = <int, Set<String>>{};
    for (final r in results[9]) {
      final set = cats.putIfAbsent(r.i('species_id'), () => {});
      final cat = r.s('category');
      final note = r.ns('note');
      if (cat == 'pseudo-legendary' && note != 'final') {
        set.add('pseudo-legendary-line');
      } else {
        set.add(cat);
      }
      if (cat == 'starter' && note == 'base') set.add('starter-base');
    }
    final eggs = <int, Set<int>>{};
    for (final r in results[10]) {
      eggs.putIfAbsent(r.i('species_id'), () => {}).add(r.i('egg_group_id'));
    }
    final triggers = <int, Set<int>>{};
    for (final r in results[11]) {
      triggers.putIfAbsent(r.i('from_species_id'), () => {}).add(r.i('trigger_id'));
    }

    entries = [for (final r in results[8]) _entry(r, cats, eggs, triggers)];
    byPokemonId = {for (final e in entries) e.pokemonId: e};
    formsBySpecies = {};
    defaultBySpecies = {};
    for (final e in entries) {
      formsBySpecies.putIfAbsent(e.speciesId, () => []).add(e);
      if (e.isDefault) defaultBySpecies[e.speciesId] = e;
    }

    abilities = [for (final r in results[12]) NamedRef(r.i('id'), r.s('name'))];
    eggGroups = [for (final r in results[13]) NamedRef(r.i('id'), r.s('name'))];
    moves = [for (final r in results[14]) NamedRef(r.i('id'), r.s('name'))];
    evolutionTriggers = [for (final r in results[15]) NamedRef(r.i('id'), r.s('name'))];
    efficacy = {};
    for (final r in results[16]) {
      efficacy.putIfAbsent(r.s('atk'), () => {})[r.s('def')] = r.i('factor');
    }
  }

  DexEntry _entry(QueryRow r, Map<int, Set<String>> cats, Map<int, Set<int>> eggs, Map<int, Set<int>> triggers) {
    final sid = r.i('species_id');
    return DexEntry(
      pokemonId: r.i('id'),
      speciesId: sid,
      identifier: r.s('identifier'),
      name: r.s('name'),
      speciesName: r.s('species_name'),
      formName: r.ns('form_name'),
      isDefault: r.b('is_default'),
      type1: typesById[r.i('type1_id')]!.identifier,
      type2: r.ni('type2_id') == null ? null : typesById[r.ni('type2_id')]!.identifier,
      generationId: r.i('generation_id'),
      stats: [
        r.i('hp'),
        r.i('attack'),
        r.i('defense'),
        r.i('sp_attack'),
        r.i('sp_defense'),
        r.i('speed'),
        r.i('total'),
      ],
      height: r.ni('height') ?? 0,
      weight: r.ni('weight') ?? 0,
      isLegendary: r.b('is_legendary'),
      isMythical: r.b('is_mythical'),
      isBaby: r.b('is_baby'),
      isMega: r.b('is_mega'),
      isGmax: r.b('is_gmax'),
      regional: r.ns('regional'),
      isBattleOnly: r.b('is_battle_only'),
      categories: cats[sid] ?? const {},
      abilityIds: {?r.ni('ability1_id'), ?r.ni('ability2_id'), ?r.ni('hidden_ability_id')},
      eggGroupIds: eggs[sid] ?? const {},
      hasSprite: r.b('has_sprite'),
      hasShinySprite: r.b('has_shiny_sprite'),
      sortOrder: r.i('species_order'),
      evolutionChainId: r.ni('evolution_chain_id'),
      evolvesFromSpeciesId: r.ni('evolves_from_species_id'),
      evolvesByTriggerIds: triggers[sid] ?? const {},
      genus: r.ns('genus'),
    );
  }

  // ---------------------------------------------------------------------------
  // Jogos

  /// Jogo base (DLC e variantes JP apontam para o pai).
  VersionGroup baseOf(int vgId) {
    final vg = versionGroupsById[vgId]!;
    return vg.parentId == null ? vg : versionGroupsById[vg.parentId]!;
  }

  /// Dex de um jogo, incluindo as das DLCs dele.
  List<int> pokedexIdsFor(int vgId) {
    final base = baseOf(vgId);
    return {
      ...base.pokedexIds,
      for (final vg in versionGroups)
        if (vg.parentId == base.id && vg.isDlc) ...vg.pokedexIds,
    }.toList();
  }

  /// Espécies disponíveis no jogo (união das dex do jogo + DLCs) com o menor número regional.
  Map<int, int> speciesInGame(int vgId) {
    final out = <int, int>{};
    for (final dexId in pokedexIdsFor(vgId)) {
      final offset = _dexOffset(vgId, dexId);
      pokedexNumbers[dexId]?.forEach((sid, n) {
        final num = n + offset;
        if (!out.containsKey(sid) || out[sid]! > num) out[sid] = num;
      });
    }
    return out;
  }

  /// DLCs continuam a numeração depois da dex base (ex.: Kitakami depois de Paldea).
  int _dexOffset(int vgId, int dexId) {
    final ids = pokedexIdsFor(vgId);
    var offset = 0;
    for (final id in ids) {
      if (id == dexId) return offset;
      offset += pokedexes[id]?.size ?? 0;
    }
    return offset;
  }

  // ---------------------------------------------------------------------------
  // Detalhe

  Future<SpeciesDetail> speciesDetail(int speciesId, int pokemonId) async {
    final rows = await Future.wait([
      db.rows('''SELECT s.gender_rate, s.capture_rate, s.base_happiness, s.hatch_counter, g.name AS growth
                 FROM species s LEFT JOIN growth_rates g ON g.id = s.growth_rate_id WHERE s.id = ?''', [speciesId]),
      db.rows('''SELECT e.name FROM species_egg_groups se JOIN egg_groups e ON e.id = se.egg_group_id
                 WHERE se.species_id = ? ORDER BY e.id''', [speciesId]),
      db.rows('''SELECT a.id, a.name, a.short_effect, pa.is_hidden FROM pokemon_abilities pa
                 JOIN abilities a ON a.id = pa.ability_id WHERE pa.pokemon_id = ? ORDER BY pa.slot''', [pokemonId]),
      db.rows('''SELECT base_experience, ev_hp, ev_attack, ev_defense, ev_sp_attack, ev_sp_defense, ev_speed
                 FROM pokemon WHERE id = ?''', [pokemonId]),
    ]);
    final s = rows[0].first;
    final p = rows[3].first;
    const evCols = {
      'ev_hp': 'PS',
      'ev_attack': 'Ataque',
      'ev_defense': 'Defesa',
      'ev_sp_attack': 'At. Esp.',
      'ev_sp_defense': 'Def. Esp.',
      'ev_speed': 'Velocidade',
    };
    return SpeciesDetail(
      genderRate: s.ni('gender_rate') ?? -1,
      captureRate: s.ni('capture_rate'),
      baseHappiness: s.ni('base_happiness'),
      hatchCounter: s.ni('hatch_counter'),
      growthRate: s.ns('growth'),
      eggGroups: [for (final r in rows[1]) r.s('name')],
      abilities: [
        for (final r in rows[2])
          Ability(id: r.i('id'), name: r.s('name'), shortEffect: r.ns('short_effect'), isHidden: r.b('is_hidden')),
      ],
      evYield: {
        for (final e in evCols.entries)
          if ((p.ni(e.key) ?? 0) > 0) e.value: p.i(e.key),
      },
      baseExperience: p.ni('base_experience'),
    );
  }

  /// Golpes da variedade no jogo. Sem dados no jogo (Z-A, DLC sem learnset próprio), cai para o
  /// jogo mais recente que tenha, e devolve qual foi usado.
  Future<(List<LearnedMove>, VersionGroup?)> learnset(int pokemonId, int vgId) async {
    final candidates = <int>[vgId, ?versionGroupsById[vgId]?.parentId];
    for (final id in candidates) {
      final moves = await _learnsetRows(pokemonId, id);
      if (moves.isNotEmpty) return (moves, versionGroupsById[id]);
    }
    // Fallback: o jogo mais recente com golpes (fora Champions, que só tem "train").
    final recent = await db.rows('''
      SELECT l.version_group_id AS vg FROM learnsets l JOIN version_groups v ON v.id = l.version_group_id
      WHERE l.pokemon_id = ? AND v.identifier <> 'champions'
      GROUP BY l.version_group_id ORDER BY MAX(v.sort_order) DESC LIMIT 1''', [pokemonId]);
    if (recent.isEmpty) {
      final entry = byPokemonId[pokemonId];
      if (entry != null && !entry.isDefault) {
        final def = defaultBySpecies[entry.speciesId];
        if (def != null) return learnset(def.pokemonId, vgId);
      }
      return (const <LearnedMove>[], null);
    }
    final id = recent.first.i('vg');
    return (await _learnsetRows(pokemonId, id), versionGroupsById[id]);
  }

  Future<List<LearnedMove>> _learnsetRows(int pokemonId, int vgId) async {
    final rows = await db.rows('''
      SELECT l.method_id, mm.identifier AS method, l.level, m.id AS move_id, m.name, ty.identifier AS type,
             dc.identifier AS damage_class, m.power, m.accuracy, m.pp, m.short_effect,
             (SELECT mc.label FROM machines mc WHERE mc.version_group_id = l.version_group_id
                AND mc.move_id = l.move_id ORDER BY mc.machine_number LIMIT 1) AS machine
      FROM learnsets l
      JOIN moves m ON m.id = l.move_id
      JOIN move_methods mm ON mm.id = l.method_id
      LEFT JOIN types ty ON ty.id = m.type_id
      LEFT JOIN damage_classes dc ON dc.id = m.damage_class_id
      WHERE l.pokemon_id = ? AND l.version_group_id = ?
      ORDER BY l.method_id, l.level, l.sort_order, m.name''', [pokemonId, vgId]);
    return [
      for (final r in rows)
        LearnedMove(
          moveId: r.i('move_id'),
          name: r.s('name'),
          type: r.ns('type'),
          damageClass: r.ns('damage_class'),
          power: r.ni('power'),
          accuracy: r.ni('accuracy'),
          pp: r.ni('pp'),
          methodId: r.i('method_id'),
          method: r.s('method'),
          level: r.i('level'),
          machine: r.ns('machine'),
          shortEffect: r.ns('short_effect'),
        ),
    ];
  }

  /// Variedades que aprendem o golpe no jogo (filtro avançado). Sem jogo: em qualquer jogo.
  Future<Set<int>> whoLearns(int moveId, int? vgId) async {
    final rows = vgId == null
        ? await db.rows('SELECT DISTINCT pokemon_id FROM learnsets WHERE move_id = ?', [moveId])
        : await db.rows(
            'SELECT DISTINCT pokemon_id FROM learnsets WHERE move_id = ? AND version_group_id IN (?, ?)',
            [moveId, vgId, versionGroupsById[vgId]?.parentId ?? vgId],
          );
    return {for (final r in rows) r.i('pokemon_id')};
  }

  /// Cadeia evolutiva com as regras válidas no jogo [vgId] (ou as regras gerais, sem jogo).
  /// Espécies sem regra registrada no jogo recebem a regra geral marcada como fallback.
  Future<EvolutionChain> evolutionChain(int chainId, {int? vgId}) async {
    final species = await db.rows(
      'SELECT id FROM species WHERE evolution_chain_id = ? ORDER BY sort_order, id',
      [chainId],
    );
    final speciesIds = [for (final r in species) r.i('id')];
    const select = '''
      SELECT e.id, e.from_species_id, e.evolved_species_id, t.identifier AS trigger, e.min_level,
             it.id AS item_id, it.identifier AS item_ident, it.name AS item_name, it.has_sprite AS item_sprite,
             hi.id AS held_id, hi.identifier AS held_ident, hi.name AS held_name, hi.has_sprite AS held_sprite,
             e.time_of_day, km.name AS known_move, kt.identifier AS known_move_type, l.name AS location,
             e.min_happiness, e.min_beauty, e.min_affection, e.relative_physical_stats,
             ps.name AS party_species, pt.identifier AS party_type, ts.name AS trade_species, e.gender_id,
             e.needs_overworld_rain, e.turn_upside_down, e.needs_multiplayer, e.near_special_rock,
             rg.name AS region, e.required_pokemon_form_id, e.evolved_pokemon_form_id,
             ef.pokemon_id AS evolved_pokemon_id, um.name AS used_move, e.min_move_count, e.min_steps,
             e.min_damage_taken, e.condition_expression, e.percentage_chance
      FROM evolutions e
      JOIN evolution_triggers t ON t.id = e.trigger_id
      LEFT JOIN items it ON it.id = e.trigger_item_id
      LEFT JOIN items hi ON hi.id = e.held_item_id
      LEFT JOIN moves km ON km.id = e.known_move_id
      LEFT JOIN types kt ON kt.id = e.known_move_type_id
      LEFT JOIN locations l ON l.id = e.location_id
      LEFT JOIN species ps ON ps.id = e.party_species_id
      LEFT JOIN types pt ON pt.id = e.party_type_id
      LEFT JOIN species ts ON ts.id = e.trade_species_id
      LEFT JOIN regions rg ON rg.id = e.region_id
      LEFT JOIN pokemon_forms ef ON ef.id = e.evolved_pokemon_form_id
      LEFT JOIN moves um ON um.id = e.used_move_id''';

    final defaults = await db.rows('$select WHERE e.evolution_chain_id = ? AND e.is_default = 1 ORDER BY e.id', [chainId]);
    var rules = <EvolutionRule>[];
    if (vgId == null) {
      rules = [for (final r in defaults) _rule(r, fallback: false)];
    } else {
      final base = baseOf(vgId).id;
      final inGame = await db.rows(
        '$select JOIN evolution_version_groups v ON v.evolution_id = e.id '
        'WHERE e.evolution_chain_id = ? AND v.version_group_id = ? ORDER BY e.id',
        [chainId, base],
      );
      rules = [for (final r in inGame) _rule(r, fallback: false)];
      final covered = {for (final r in rules) r.toSpeciesId};
      for (final r in defaults) {
        if (!covered.contains(r.i('evolved_species_id'))) rules.add(_rule(r, fallback: true));
      }
    }

    final forms = await db.rows('''
      SELECT p.id, p.species_id, p.name, p.is_gmax, it.id AS item_id, it.identifier AS item_ident,
             it.name AS item_name, it.has_sprite AS item_sprite
      FROM pokemon p
      JOIN species s ON s.id = p.species_id
      LEFT JOIN pokemon_forms f ON f.pokemon_id = p.id AND f.is_default = 1
      LEFT JOIN form_conditions fc ON fc.pokemon_form_id = f.id
      LEFT JOIN items it ON it.id = fc.item_id
      WHERE s.evolution_chain_id = ? AND (p.is_mega = 1 OR p.is_gmax = 1)
      ORDER BY p.is_gmax, p.id''', [chainId]);
    final formChanges = <int, List<FormChange>>{};
    for (final r in forms) {
      formChanges.putIfAbsent(r.i('species_id'), () => []).add(
            FormChange(
              pokemonId: r.i('id'),
              name: r.s('name'),
              isGmax: r.b('is_gmax'),
              item: r.ni('item_id') == null
                  ? null
                  : ItemRef(id: r.i('item_id'), identifier: r.s('item_ident'), name: r.s('item_name'), hasSprite: r.b('item_sprite')),
            ),
          );
    }
    return EvolutionChain(chainId: chainId, speciesIds: speciesIds, rules: rules, formChanges: formChanges);
  }

  EvolutionRule _rule(QueryRow r, {required bool fallback}) => EvolutionRule(
        id: r.i('id'),
        fromSpeciesId: r.i('from_species_id'),
        toSpeciesId: r.i('evolved_species_id'),
        trigger: r.s('trigger'),
        minLevel: r.ni('min_level'),
        item: r.ni('item_id') == null
            ? null
            : ItemRef(id: r.i('item_id'), identifier: r.s('item_ident'), name: r.s('item_name'), hasSprite: r.b('item_sprite')),
        heldItem: r.ni('held_id') == null
            ? null
            : ItemRef(id: r.i('held_id'), identifier: r.s('held_ident'), name: r.s('held_name'), hasSprite: r.b('held_sprite')),
        timeOfDay: r.ns('time_of_day'),
        knownMove: r.ns('known_move'),
        knownMoveType: r.ns('known_move_type'),
        location: r.ns('location'),
        minHappiness: r.ni('min_happiness'),
        minBeauty: r.ni('min_beauty'),
        minAffection: r.ni('min_affection'),
        relativePhysicalStats: r.ni('relative_physical_stats'),
        partySpecies: r.ns('party_species'),
        partyType: r.ns('party_type'),
        tradeSpecies: r.ns('trade_species'),
        genderId: r.ni('gender_id'),
        needsOverworldRain: r.b('needs_overworld_rain'),
        turnUpsideDown: r.b('turn_upside_down'),
        needsMultiplayer: r.b('needs_multiplayer'),
        nearSpecialRock: r.b('near_special_rock'),
        region: r.ns('region'),
        requiredFormId: r.ni('required_pokemon_form_id'),
        evolvedFormId: r.ni('evolved_pokemon_form_id'),
        evolvedPokemonId: r.ni('evolved_pokemon_id'),
        usedMove: r.ns('used_move'),
        minMoveCount: r.ni('min_move_count'),
        minSteps: r.ni('min_steps'),
        minDamageTaken: r.ni('min_damage_taken'),
        conditionExpression: r.ns('condition_expression'),
        percentageChance: r.ni('percentage_chance'),
        isFallback: fallback,
      );

  /// Onde achar a variedade nas versões dadas. Vazio quando a PokeAPI não tem encontros do jogo.
  Future<Map<Version, List<Encounter>>> encounters(int pokemonId, List<Version> versions) async {
    final out = <Version, List<Encounter>>{};
    for (final v in versions) {
      final rows = await db.rows('''
        SELECT COALESCE(la.name, lo.name) AS area, em.name AS method, e.min_level, e.max_level, e.rarity,
               group_concat(cv.name, ' + ') AS conditions
        FROM encounters e
        JOIN location_areas la ON la.id = e.location_area_id
        JOIN locations lo ON lo.id = la.location_id
        JOIN encounter_methods em ON em.id = e.method_id
        LEFT JOIN encounter_conditions ec ON ec.encounter_id = e.id
        LEFT JOIN encounter_condition_values cv ON cv.id = ec.condition_value_id AND cv.is_default = 0
        WHERE e.pokemon_id = ? AND e.version_id = ?
        GROUP BY e.id
        ORDER BY la.location_id, em.sort_order, e.min_level''', [pokemonId, v.id]);
      if (rows.isEmpty) continue;
      out[v] = [
        for (final r in rows)
          Encounter(
            area: r.s('area'),
            method: r.s('method'),
            minLevel: r.i('min_level'),
            maxLevel: r.i('max_level'),
            rarity: r.ni('rarity') ?? 0,
            conditions: r.ns('conditions'),
          ),
      ];
    }
    return out;
  }

  /// Multiplicador de dano (%) de um tipo atacante contra a combinação defensora.
  int damageAgainst(String attacking, List<String> defending) {
    var f = 100;
    for (final d in defending) {
      f = f * (efficacy[attacking]?[d] ?? 100) ~/ 100;
    }
    return f;
  }
}
