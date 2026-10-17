import 'package:drift/drift.dart' show Value;

import '../../core/data/dex_repository.dart';
import '../../core/data/models.dart';
import '../../core/data/user_database.dart';
import '../../core/state/app_state.dart';

/// Operações de aventura que o AppState ainda não expõe (renomear, arquivar, excluir).
extension AdventureActions on AppState {
  Future<void> renameAdventure(String id, String name) =>
      (user.update(user.adventures)..where((a) => a.id.equals(id))).write(AdventuresCompanion(name: Value(name)));

  /// Arquivar a ativa volta o app para "Sem aventura".
  Future<void> archiveAdventure(Adventure a, {required bool archived}) async {
    if (archived && activeAdventure?.id == a.id) await setActiveAdventure(null);
    await (user.update(user.adventures)..where((t) => t.id.equals(a.id))).write(AdventuresCompanion(archived: Value(archived)));
  }

  /// Desarquiva (se preciso) e torna ativa.
  Future<void> activateAdventure(Adventure a) async {
    if (a.archived) await archiveAdventure(a, archived: false);
    await setActiveAdventure(a.id);
  }

  /// Apaga a aventura; exemplares e encontros Nuzlocke dela saem em cascata.
  Future<void> deleteAdventure(Adventure a) async {
    if (activeAdventure?.id == a.id) await setActiveAdventure(null);
    await (user.delete(user.adventures)..where((t) => t.id.equals(a.id))).go();
  }
}

/// Consultas por jogo memorizadas: o banco de referência não muda durante a execução.
class GameIndex {
  GameIndex._(this.dex);
  final DexRepository dex;
  static final _byDex = Expando<GameIndex>();

  static GameIndex of(DexRepository dex) => _byDex[dex] ??= GameIndex._(dex);

  final _dex = <int, Map<int, int>>{};
  final _available = <int, Set<int>>{};

  /// Dex regional do jogo (speciesId → nº), base do progresso.
  Map<int, int> regional(int vgId) => _dex[vgId] ??= dex.speciesInGame(vgId);

  /// Espécies obtíveis no jogo.
  Set<int> available(int vgId) => _available[vgId] ??= dex.availableInGame(vgId);

  /// "Paldea + Kitakami + Blueberry"
  String dexNames(int vgId) => [
    for (final id in dex.pokedexIdsFor(vgId))
      if (dex.pokedexes[id] case final p?) p.name,
  ].join(' + ');
}

/// Cartuchos escolhíveis de um jogo (sem variantes derivadas).
List<Version> pickableVersions(VersionGroup vg) {
  final main = [
    for (final v in vg.versions)
      if (v.parentVersionId == null) v,
  ];
  return main.isEmpty ? vg.versions : main;
}

/// Sigla curta do cartucho para o selo da aventura ("FR", "VI", "ZA").
String gameCode(DexRepository dex, Adventure a) {
  final vg = dex.versionGroupsById[a.versionGroupId];
  final version = vg?.versions.where((v) => v.id == a.versionId).firstOrNull;
  if (version != null) return versionCode(version);
  if (vg == null) return '?';
  final codes = [for (final v in pickableVersions(vg)) versionCode(v)];
  if (codes.every((c) => c.length == 1)) return codes.join();
  return codes.first;
}

String versionCode(Version v) => _codes[v.identifier] ?? _initials(v.name);

String _initials(String name) {
  final words = name.split(RegExp(r'[^A-Za-z0-9]+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, words.first.length.clamp(1, 2)).toUpperCase();
  return words.take(2).map((w) => w[0]).join().toUpperCase();
}

const _codes = {
  'red': 'R',
  'blue': 'B',
  'yellow': 'Y',
  'gold': 'G',
  'silver': 'S',
  'crystal': 'C',
  'ruby': 'R',
  'sapphire': 'S',
  'emerald': 'E',
  'firered': 'FR',
  'leafgreen': 'LG',
  'diamond': 'D',
  'pearl': 'P',
  'platinum': 'PT',
  'heartgold': 'HG',
  'soulsilver': 'SS',
  'black': 'B',
  'white': 'W',
  'black-2': 'B2',
  'white-2': 'W2',
  'x': 'X',
  'y': 'Y',
  'omega-ruby': 'OR',
  'alpha-sapphire': 'AS',
  'sun': 'S',
  'moon': 'M',
  'ultra-sun': 'US',
  'ultra-moon': 'UM',
  'lets-go-pikachu': 'LP',
  'lets-go-eevee': 'LE',
  'sword': 'SW',
  'shield': 'SH',
  'brilliant-diamond': 'BD',
  'shining-pearl': 'SP',
  'legends-arceus': 'LA',
  'scarlet': 'SC',
  'violet': 'VI',
  'legends-za': 'ZA',
};
