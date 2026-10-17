/// Textos de exibição da leitura e a próxima evolução no jogo.
library;

import '../../core/data/dex_repository.dart';
import '../../core/data/models.dart';
import '../../core/data/specimen_draft.dart';
import '../detail/evolution/evolution_text.dart';
import 'matcher.dart';

/// Nomes por id, montados uma vez por repositório.
class ScanNames {
  ScanNames._(this.dex)
      : abilities = {for (final a in dex.abilities) a.id: a.name},
        moves = {for (final m in dex.moves) m.id: m.name},
        items = {for (final i in [...dex.holdableItems, ...dex.balls]) i.id: i.name},
        natures = {for (final n in dex.natures) n.identifier: n};

  final DexRepository dex;
  final Map<int, String> abilities;
  final Map<int, String> moves;
  final Map<int, String> items;
  final Map<String, Nature> natures;

  static final _cache = Expando<ScanNames>();
  static ScanNames of(DexRepository dex) => _cache[dex] ??= ScanNames._(dex);

  String ability(int id) => abilities[id] ?? '#$id';
  String move(int id) => moves[id] ?? '#$id';
  String item(int id) => items[id] ?? '#$id';
  String type(String identifier) => dex.types[identifier]?.namePt ?? identifier;

  /// "Modest (Modesta)"
  String nature(String identifier) {
    final en = natures[identifier]?.name ?? identifier;
    final pt = naturePtName(identifier);
    return pt == null ? en : '$en ($pt)';
  }

  static String gender(String? g) => switch (g) {
        'm' => 'Macho',
        'f' => 'Fêmea',
        _ => 'Sem gênero',
      };

  String species(int pokemonId) {
    final e = dex.byPokemonId[pokemonId];
    return e == null ? '#$pokemonId' : evolutionDisplayName(e);
  }

  /// Diferenças campo a campo entre a ficha atual e a nova: (rótulo, antes, depois).
  List<(String, String, String)> diff(SpecimenDraft before, SpecimenDraft after) {
    final out = <(String, String, String)>[];
    void add(String label, Object? a, Object? b, String Function(Object) show) {
      final sa = a == null ? '—' : show(a);
      final sb = b == null ? '—' : show(b);
      if (sa != sb) out.add((label, sa, sb));
    }

    add('Forma', before.pokemonId, after.pokemonId, (v) => species(v as int));
    add('Apelido', before.nickname, after.nickname, (v) => '$v');
    add('Nível', before.level, after.level, (v) => '$v');
    add('Gênero', before.gender, after.gender, (v) => gender(v as String));
    add('Shiny', before.isShiny, after.isShiny, (v) => v == true ? 'Sim' : 'Não');
    add('Natureza', before.nature, after.nature, (v) => nature(v as String));
    add('Habilidade', before.abilityId, after.abilityId, (v) => ability(v as int));
    add('Item', before.heldItemId, after.heldItemId, (v) => item(v as int));
    add('Pokébola', before.ballItemId, after.ballItemId, (v) => item(v as int));
    add('Tipo Tera', before.teraType, after.teraType, (v) => type(v as String));
    add('Local', before.caughtWhere, after.caughtWhere, (v) => '$v');
    add(
      'Golpes',
      before.moves.isEmpty ? null : before.moves,
      after.moves.isEmpty ? null : after.moves,
      (v) => (v as List<int>).map(move).join(', '),
    );
    const short = ['PS', 'Atq', 'Def', 'AtE', 'DfE', 'Vel'];
    String six(Object v) {
      final l = v as List<int?>;
      return [for (var i = 0; i < 6; i++) if (l[i] != null) '${short[i]} ${l[i]}'].join(' · ');
    }

    add('Stats', before.stats.every((x) => x == null) ? null : before.stats, after.stats.every((x) => x == null) ? null : after.stats, six);
    add('IVs', before.ivs.every((x) => x == null) ? null : before.ivs, after.ivs.every((x) => x == null) ? null : after.ivs, six);
    return out;
  }
}

class NextEvolution {
  const NextEvolution(this.target, this.block, this.minLevel);
  final DexEntry target;
  final RequirementBlock block;
  final int? minLevel;
}

/// Evoluções diretas da variedade no jogo [vgId], com a exigência em pt-BR.
Future<List<NextEvolution>> nextEvolutions(DexRepository dex, DexEntry entry, int vgId) async {
  final chainId = entry.evolutionChainId;
  if (chainId == null) return const [];
  final chain = await dex.evolutionChain(chainId, vgId: vgId);
  final available = dex.availableInGame(vgId);
  final out = <NextEvolution>[];
  final seen = <String>{};
  for (final r in chain.rules) {
    if (r.fromSpeciesId != entry.speciesId) continue;
    if (available.isNotEmpty && !available.contains(r.toSpeciesId)) continue;
    final target = (r.evolvedPokemonId == null ? null : dex.byPokemonId[r.evolvedPokemonId]) ??
        dex.byPokemonId[dex.formInGame(vgId, r.toSpeciesId)] ??
        dex.defaultBySpecies[r.toSpeciesId];
    if (target == null) continue;
    final block = describeEvolution(
      r,
      typeName: (t) => dex.types[t]?.namePt ?? t,
      speciesName: (id) => dex.defaultBySpecies[id]?.speciesName ?? '#$id',
    );
    if (!seen.add('${target.pokemonId}|${block.signature}')) continue;
    out.add(NextEvolution(target, block, r.trigger == 'level-up' ? r.minLevel : null));
  }
  return out;
}
