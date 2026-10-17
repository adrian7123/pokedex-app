import 'package:drift/drift.dart' show Value;

import 'user_database.dart';

/// Ficha editável de um exemplar. A ficha manual e a leitura por foto preenchem o mesmo
/// rascunho; [AppState.saveDraft] grava como novo exemplar ou por cima de um existente.
class SpecimenDraft {
  SpecimenDraft({
    required this.speciesId,
    required this.pokemonId,
    this.adventureId,
    this.isShiny = false,
    this.nickname,
    this.level,
    this.nature,
    this.abilityId,
    this.gender,
    this.ballItemId,
    this.caughtWhere,
    this.heldItemId,
    List<int?>? ivs,
    List<int?>? evs,
    List<int?>? stats,
    List<int>? moves,
    this.teraType,
    this.notes,
  })  : ivs = ivs ?? List.filled(6, null),
        evs = evs ?? List.filled(6, null),
        stats = stats ?? List.filled(6, null),
        moves = moves ?? [];

  factory SpecimenDraft.fromSpecimen(Specimen s) => SpecimenDraft(
        speciesId: s.speciesId,
        pokemonId: s.pokemonId,
        adventureId: s.adventureId,
        isShiny: s.isShiny,
        nickname: s.nickname,
        level: s.level,
        nature: s.nature,
        abilityId: s.abilityId,
        gender: s.gender,
        ballItemId: s.ballItemId,
        caughtWhere: s.caughtWhere,
        heldItemId: s.heldItemId,
        ivs: _six(s.ivs),
        evs: _six(s.evs),
        stats: _six(s.stats),
        moves: [for (final m in (s.moves ?? '').split(',')) ?int.tryParse(m)],
        teraType: s.teraType,
        notes: s.notes,
      );

  int speciesId;
  int pokemonId;
  String? adventureId;
  bool isShiny;
  String? nickname;
  int? level;

  /// natures.identifier
  String? nature;
  int? abilityId;

  /// 'm', 'f' ou null
  String? gender;
  int? ballItemId;
  String? caughtWhere;
  int? heldItemId;

  /// Ordem: hp, atk, def, spa, spd, spe. null = não informado.
  final List<int?> ivs;
  final List<int?> evs;

  /// Stats vistos no jogo (PS máximo).
  final List<int?> stats;

  /// move ids, até 4.
  final List<int> moves;

  /// identifier do tipo Tera.
  String? teraType;
  String? notes;

  SpecimensCompanion toCompanion({required String id, required DateTime caughtAt}) => SpecimensCompanion(
        id: Value(id),
        adventureId: Value(adventureId),
        speciesId: Value(speciesId),
        pokemonId: Value(pokemonId),
        isShiny: Value(isShiny),
        nickname: Value(_blank(nickname)),
        level: Value(level),
        nature: Value(nature),
        abilityId: Value(abilityId),
        gender: Value(gender),
        ballItemId: Value(ballItemId),
        caughtWhere: Value(_blank(caughtWhere)),
        heldItemId: Value(heldItemId),
        ivs: Value(_join(ivs)),
        evs: Value(_join(evs)),
        stats: Value(_join(stats)),
        moves: Value(moves.isEmpty ? null : moves.take(4).join(',')),
        teraType: Value(teraType),
        notes: Value(_blank(notes)),
        caughtAt: Value(caughtAt),
      );

  static List<int?> _six(String? csv) {
    final parts = (csv ?? '').split(',');
    return [for (var i = 0; i < 6; i++) i < parts.length ? int.tryParse(parts[i]) : null];
  }

  static String? _join(List<int?> v) => v.every((x) => x == null) ? null : v.map((x) => x?.toString() ?? '').join(',');

  static String? _blank(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
