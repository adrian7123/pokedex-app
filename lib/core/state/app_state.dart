import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/dex_repository.dart';
import '../data/models.dart';
import '../data/user_database.dart';
import '../widgets/stamp.dart';

/// Resumo das capturas de uma espécie num escopo (aventura ativa ou global).
class CaptureSummary {
  const CaptureSummary({required this.count, required this.shiny});
  final int count;
  final bool shiny;
  static const none = CaptureSummary(count: 0, shiny: false);
}

class SpeciesMark {
  const SpeciesMark({this.favorite = false, this.marks = 0});
  final bool favorite;
  final int marks;
}

/// Estado do app: dados de referência + dados do usuário observados do Drift.
class AppState extends ChangeNotifier {
  AppState({required this.dex, required this.user});

  final DexRepository dex;
  final UserDatabase user;
  static const _uuid = Uuid();

  List<Adventure> adventures = const [];
  Adventure? activeAdventure;
  List<Specimen> _specimens = const [];
  Map<int, SpeciesMark> marks = const {};

  /// speciesId → resumo no escopo atual (aventura ativa; sem aventura = todos os exemplares).
  Map<int, CaptureSummary> scoped = const {};

  /// speciesId → resumo em todas as aventuras.
  Map<int, CaptureSummary> global = const {};

  final _subs = <StreamSubscription<Object?>>[];
  String? _activeId;

  Future<void> init() async {
    final setting = await (user.select(user.settings)..where((s) => s.key.equals('active_adventure'))).getSingleOrNull();
    _activeId = setting?.value;
    _subs.add(
      (user.select(user.adventures)..orderBy([(a) => OrderingTerm.desc(a.createdAt)])).watch().listen((rows) {
        adventures = rows;
        activeAdventure = rows.where((a) => a.id == _activeId && !a.archived).firstOrNull;
        _recompute();
      }),
    );
    _subs.add(user.select(user.specimens).watch().listen((rows) {
      _specimens = rows;
      _recompute();
    }));
    _subs.add(user.select(user.speciesMarks).watch().listen((rows) {
      marks = {for (final m in rows) m.speciesId: SpeciesMark(favorite: m.favorite, marks: m.marks)};
      notifyListeners();
    }));
  }

  void _recompute() {
    final g = <int, (int, bool)>{};
    final s = <int, (int, bool)>{};
    final scopeId = activeAdventure?.id;
    for (final sp in _specimens) {
      final cur = g[sp.speciesId] ?? (0, false);
      g[sp.speciesId] = (cur.$1 + 1, cur.$2 || sp.isShiny);
      if (scopeId == null || sp.adventureId == scopeId) {
        final c = s[sp.speciesId] ?? (0, false);
        s[sp.speciesId] = (c.$1 + 1, c.$2 || sp.isShiny);
      }
    }
    global = {for (final e in g.entries) e.key: CaptureSummary(count: e.value.$1, shiny: e.value.$2)};
    scoped = {for (final e in s.entries) e.key: CaptureSummary(count: e.value.$1, shiny: e.value.$2)};
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Contexto de jogo

  /// Jogo da aventura ativa; null = sem jogo (Pokédex Nacional, regras gerais).
  int? get contextVersionGroupId => activeAdventure?.versionGroupId;

  VersionGroup? get contextVersionGroup {
    final id = contextVersionGroupId;
    return id == null ? null : dex.versionGroupsById[id];
  }

  Future<void> setActiveAdventure(String? id) async {
    _activeId = id;
    if (id == null) {
      await (user.delete(user.settings)..where((s) => s.key.equals('active_adventure'))).go();
    } else {
      await user.into(user.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: 'active_adventure', value: id));
    }
    activeAdventure = adventures.where((a) => a.id == id).firstOrNull;
    _recompute();
  }

  Future<String> createAdventure({required String name, required int versionGroupId, int? versionId, bool nuzlocke = false}) async {
    final id = _uuid.v4();
    await user.into(user.adventures).insert(
          AdventuresCompanion.insert(
            id: id,
            name: name,
            versionGroupId: versionGroupId,
            versionId: Value(versionId),
            isNuzlocke: Value(nuzlocke),
            createdAt: DateTime.now(),
          ),
        );
    await setActiveAdventure(id);
    return id;
  }

  // ---------------------------------------------------------------------------
  // Carimbos

  StampState stampOf(int speciesId) {
    final c = scoped[speciesId] ?? CaptureSummary.none;
    if (c.count == 0) return StampState.empty;
    return c.shiny ? StampState.shiny : StampState.stamped;
  }

  List<Specimen> specimensOf(int speciesId, {bool scopedOnly = false}) => [
        for (final s in _specimens)
          if (s.speciesId == speciesId && (!scopedOnly || activeAdventure == null || s.adventureId == activeAdventure!.id)) s,
      ]..sort((a, b) => b.caughtAt.compareTo(a.caughtAt));

  Iterable<Specimen> get allSpecimens => _specimens;

  /// Toque no carimbo: carimba se vazio; se já carimbado, remove o exemplar mais recente sem ficha.
  /// Devolve uma ação de desfazer, ou null quando não havia o que remover sem perder dados.
  Future<Future<void> Function()?> toggleCapture(DexEntry entry) async {
    final mine = specimensOf(entry.speciesId, scopedOnly: true);
    if (mine.isEmpty) {
      final id = await _insert(entry, shiny: false);
      return () => _deleteById(id);
    }
    final bare = mine.where(_isBare).firstOrNull;
    if (bare == null) return null;
    await _deleteById(bare.id);
    return () => user.into(user.specimens).insert(bare);
  }

  /// Toque longo: carimbo shiny. Promove o exemplar simples a shiny ou cria um novo.
  Future<Future<void> Function()?> toggleShiny(DexEntry entry) async {
    final mine = specimensOf(entry.speciesId, scopedOnly: true);
    final shiny = mine.where((s) => s.isShiny && _isBare(s)).firstOrNull;
    if (shiny != null) {
      await (user.update(user.specimens)..where((s) => s.id.equals(shiny.id))).write(const SpecimensCompanion(isShiny: Value(false)));
      return () async {
        await (user.update(user.specimens)..where((s) => s.id.equals(shiny.id))).write(const SpecimensCompanion(isShiny: Value(true)));
      };
    }
    final bare = mine.where((s) => !s.isShiny && _isBare(s)).firstOrNull;
    if (bare != null) {
      await (user.update(user.specimens)..where((s) => s.id.equals(bare.id))).write(const SpecimensCompanion(isShiny: Value(true)));
      return () async {
        await (user.update(user.specimens)..where((s) => s.id.equals(bare.id))).write(const SpecimensCompanion(isShiny: Value(false)));
      };
    }
    final id = await _insert(entry, shiny: true);
    return () => _deleteById(id);
  }

  bool _isBare(Specimen s) =>
      s.nickname == null && s.level == null && s.nature == null && s.ivs == null && s.evs == null && s.moves == null && s.notes == null;

  Future<String> _insert(DexEntry entry, {required bool shiny}) async {
    final id = _uuid.v4();
    await user.into(user.specimens).insert(
          SpecimensCompanion.insert(
            id: id,
            adventureId: Value(activeAdventure?.id),
            speciesId: entry.speciesId,
            pokemonId: entry.pokemonId,
            isShiny: Value(shiny),
            caughtAt: DateTime.now(),
          ),
        );
    return id;
  }

  Future<void> _deleteById(String id) => (user.delete(user.specimens)..where((s) => s.id.equals(id))).go();

  Future<void> deleteSpecimen(String id) => _deleteById(id);

  Future<void> saveSpecimen(SpecimensCompanion data) => user.into(user.specimens).insertOnConflictUpdate(data);

  // ---------------------------------------------------------------------------
  // Marcas

  SpeciesMark markOf(int speciesId) => marks[speciesId] ?? const SpeciesMark();

  Future<void> toggleFavorite(int speciesId) {
    final m = markOf(speciesId);
    return user.into(user.speciesMarks).insertOnConflictUpdate(
          SpeciesMarksCompanion.insert(speciesId: Value(speciesId), favorite: Value(!m.favorite), marks: Value(m.marks)),
        );
  }

  Future<void> toggleMark(int speciesId, int bit) {
    final m = markOf(speciesId);
    return user.into(user.speciesMarks).insertOnConflictUpdate(
          SpeciesMarksCompanion.insert(speciesId: Value(speciesId), favorite: Value(m.favorite), marks: Value(m.marks ^ bit)),
        );
  }

  // ---------------------------------------------------------------------------
  // Progresso

  /// Carimbados / total na dex do jogo da aventura ativa (ou nacional).
  (int, int) progress() {
    final vg = contextVersionGroupId;
    final species = vg == null ? dex.defaultBySpecies.keys : dex.speciesInGame(vg).keys;
    var done = 0;
    var total = 0;
    for (final s in species) {
      total++;
      if ((scoped[s]?.count ?? 0) > 0) done++;
    }
    return (done, total);
  }
}
