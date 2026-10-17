import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../core/data/dex_repository.dart';
import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/data/user_database.dart';
import '../../core/state/app_state.dart';
import 'search.dart';

/// Como os tipos marcados combinam.
enum TypeMode {
  any('Qualquer', 'Tem pelo menos um dos tipos marcados.'),
  single('Único', 'Só um tipo, entre os marcados.'),
  dual('Duplo', 'Dois tipos, com pelo menos um dos marcados.'),
  all('Ambos', 'Tem todos os tipos marcados ao mesmo tempo.');

  const TypeMode(this.label, this.hint);
  final String label;
  final String hint;
}

enum CaptureFilter { all, captured, uncaptured }

enum SortKey {
  number('Número'),
  name('Nome (A–Z)'),
  total('Total de stats'),
  hp('PS'),
  attack('Ataque'),
  defense('Defesa'),
  spAttack('At. Esp.'),
  spDefense('Def. Esp.'),
  speed('Velocidade'),
  height('Altura'),
  weight('Peso');

  const SortKey(this.label);
  final String label;

  /// Índice em [DexEntry.stats] quando a ordem é por stat.
  int? get statIndex => switch (this) {
        SortKey.hp => 0,
        SortKey.attack => 1,
        SortKey.defense => 2,
        SortKey.spAttack => 3,
        SortKey.spDefense => 4,
        SortKey.speed => 5,
        SortKey.total => 6,
        _ => null,
      };

  /// Ordens que mostram o valor à direita da linha.
  bool get showsValue => this != SortKey.number && this != SortKey.name;
}

/// Marcas livres por espécie, na ordem dos bits do banco.
enum SpeciesMarkBit {
  star(1, 'Estrela'),
  circle(2, 'Círculo'),
  triangle(4, 'Triângulo'),
  square(8, 'Quadrado'),
  heart(16, 'Coração'),
  diamond(32, 'Losango');

  const SpeciesMarkBit(this.bit, this.label);
  final int bit;
  final String label;
}

/// Uma linha do resultado com a faixa de relevância da busca.
class _Hit {
  _Hit(this.index, this.tier);
  final int index;
  final int tier;
}

/// Estado da aba Pokédex: busca, escopo de jogo, filtros, ordem e o resultado já calculado.
///
/// Vive enquanto o [AppState] viver (a aba é recriada a cada troca, o estado não).
class PokedexController extends ChangeNotifier {
  PokedexController._(this.app) {
    _index();
    _lastVg = scopeVg;
    app.addListener(_onApp);
    search.addListener(_onQuery);
    _restore();
  }

  static final _byApp = Expando<PokedexController>();

  static PokedexController of(AppState app) => _byApp[app] ??= PokedexController._(app);

  final AppState app;
  DexRepository get dex => app.dex;

  /// Campo de busca (o texto sobrevive à troca de abas).
  final search = TextEditingController();

  // ---------------------------------------------------------------------------
  // Índice pré-calculado

  late final List<DexEntry> _entries;
  late final List<String> _names;
  late final List<List<String>> _words;

  /// Palavras que só a forma tem (não estão na variedade padrão): "mega", "alolan", "gmax"...
  late final List<Set<String>> _formWords;

  /// speciesId → espécies que evoluem dela.
  late final Map<int, List<int>> _children;

  /// Faixa de cada stat (hp…speed, total) entre todas as variedades.
  late final List<(int, int)> statBounds;

  /// Gatilhos de evolução que alguma espécie usa, com id → identifier.
  late final Map<int, String> triggerIdentifiers;

  final Map<int, Map<int, int>> _inGameCache = {};
  final Map<int, Set<int>> _availableCache = {};
  final Map<int, Set<int>> _primaryCache = {};

  void _index() {
    _entries = dex.entries;
    _names = [for (final e in _entries) DexEntry.normalize(e.name)];
    _words = [for (final e in _entries) e.searchKey.split(' ').toSet().toList()];
    _formWords = [
      for (var i = 0; i < _entries.length; i++)
        if (_entries[i].isDefault)
          const <String>{}
        else
          _words[i].toSet().difference((dex.defaultBySpecies[_entries[i].speciesId]?.searchKey ?? '').split(' ').toSet()),
    ];
    _children = {};
    for (final e in dex.defaultBySpecies.values) {
      final from = e.evolvesFromSpeciesId;
      if (from != null) _children.putIfAbsent(from, () => []).add(e.speciesId);
    }
    statBounds = [
      for (var s = 0; s < 7; s++)
        _entries.fold<(int, int)>((1 << 30, 0), (acc, e) => (e.stats[s] < acc.$1 ? e.stats[s] : acc.$1, e.stats[s] > acc.$2 ? e.stats[s] : acc.$2)),
    ];
    // Os ids de evolution_triggers seguem a ordem da PokeAPI, a mesma de Labels.evolutionTrigger.
    final keys = Labels.evolutionTrigger.keys.toList();
    final used = <int>{for (final e in _entries) ...e.evolvesByTriggerIds};
    triggerIdentifiers = {
      for (final t in dex.evolutionTriggers)
        if (t.id >= 1 && t.id <= keys.length && used.contains(t.id)) t.id: keys[t.id - 1],
    };
  }

  /// Espécies do jogo (com DLC) → número regional. Cacheado por jogo.
  Map<int, int> speciesInGame(int vg) => _inGameCache[vg] ??= dex.speciesInGame(vg);

  /// Espécies obtíveis no jogo (dex regional + encontros + Nacional do jogo). Cacheado.
  Set<int> availableInGame(int vg) => _availableCache[vg] ??= dex.availableInGame(vg);

  /// pokemonIds que representam cada espécie no jogo (Meowth de Galar na dex de Galar).
  Set<int> _primaryIn(int vg) => _primaryCache[vg] ??= {
        for (final sid in {...speciesInGame(vg).keys, ...availableInGame(vg)}) dex.formInGame(vg, sid),
      };

  // ---------------------------------------------------------------------------
  // Escopo de jogo

  bool _followAdventure = true;
  int? _pickedVg;

  /// O escopo acompanha o jogo da aventura ativa.
  bool get followsAdventure => _followAdventure;

  /// Jogo do escopo; null = Pokédex Nacional.
  int? get scopeVg => _followAdventure ? app.contextVersionGroupId : _pickedVg;

  VersionGroup? get scopeVersionGroup => scopeVg == null ? null : dex.versionGroupsById[scopeVg];

  /// Escolhe o escopo sem mexer na aventura ativa. [vg] null = Nacional.
  void setScope(int? vg) {
    final adventureVg = app.contextVersionGroupId;
    _followAdventure = vg == adventureVg;
    _pickedVg = vg;
    if (_lastVg == scopeVg) {
      notifyListeners();
      return;
    }
    _lastVg = scopeVg;
    if (move != null) _fetchMove();
    _changed();
  }

  int? _lastVg;

  bool _regionalOnly = true;

  /// No escopo de um jogo: só a dex regional (padrão) ou tudo que dá para obter nele.
  bool get regionalOnly => _regionalOnly;
  set regionalOnly(bool v) {
    if (v == _regionalOnly) return;
    _regionalOnly = v;
    if (scopeVg != null) _changed();
  }

  /// Espécies do escopo atual; null = Nacional (todas).
  Set<int>? _scopeSpecies(int? vg) {
    if (vg == null) return null;
    return _regionalOnly ? speciesInGame(vg).keys.toSet() : availableInGame(vg);
  }

  /// Número regional no escopo de um jogo (null fora da dex regional ou no Nacional).
  int? regionalNumberOf(DexEntry e) {
    final vg = scopeVg;
    return vg == null ? null : speciesInGame(vg)[e.speciesId];
  }

  /// Regional com 3 dígitos no escopo de um jogo; nacional com 4 no Nacional e para quem
  /// é obtível no jogo mas fica fora da dex regional.
  String numberLabel(DexEntry e) {
    final n = regionalNumberOf(e);
    if (n == null) return Labels.dexNumber(e.speciesId);
    return '#${n.toString().padLeft(3, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Exibição e ordem (lembradas na sessão)

  bool _grid = false;
  bool get grid => _grid;
  set grid(bool v) {
    if (v == _grid) return;
    _grid = v;
    notifyListeners();
  }

  SortKey _sort = SortKey.number;
  SortKey get sort => _sort;
  set sort(SortKey v) {
    if (v == _sort) return;
    _sort = v;
    _changed();
  }

  bool _showForms = false;
  bool get showForms => _showForms;
  set showForms(bool v) {
    if (v == _showForms) return;
    _showForms = v;
    _changed();
  }

  /// Filtros de forma (mega, gmax, regional) ligam as formas alternativas por conta própria.
  bool get formsForcedByFilter => categories.contains('mega') || categories.contains('gmax') || categories.contains('regional');

  bool get formsVisible => _showForms || formsForcedByFilter;

  // ---------------------------------------------------------------------------
  // Filtros

  final Set<String> types = {};
  TypeMode typeMode = TypeMode.any;
  final Set<int> generations = {};
  final Set<String> categories = {};

  /// Sub-escolha de "Formas regionais"; vazio = qualquer região.
  final Set<String> regionalForms = {};
  CaptureFilter capture = CaptureFilter.all;
  bool shinyOnly = false;
  bool favoritesOnly = false;
  int marksMask = 0;
  bool canEvolveOnly = false;
  NamedRef? ability;
  NamedRef? move;
  final Set<int> eggGroups = {};
  final Set<int> triggers = {};
  int statIndex = 6;

  /// null = faixa inteira (filtro desligado).
  RangeValues? statRange;

  Set<int>? _learners;
  bool moveLoading = false;
  bool moveFailed = false;
  int _moveToken = 0;

  void toggleType(String t) => _toggle(types, t);
  void setTypeMode(TypeMode m) {
    typeMode = m;
    _changed();
  }

  void toggleGeneration(int g) => _toggle(generations, g);
  void toggleCategory(String c) {
    if (c == 'regional' && categories.contains(c)) regionalForms.clear();
    _toggle(categories, c);
  }

  void toggleRegionalForm(String r) => _toggle(regionalForms, r);
  void setCapture(CaptureFilter c) {
    capture = capture == c ? CaptureFilter.all : c;
    _changed();
  }

  void setShinyOnly(bool v) {
    shinyOnly = v;
    _changed();
  }

  void setFavoritesOnly(bool v) {
    favoritesOnly = v;
    _changed();
  }

  void toggleMarkBit(int bit) {
    marksMask ^= bit;
    _changed();
  }

  void setCanEvolveOnly(bool v) {
    canEvolveOnly = v;
    _changed();
  }

  void setAbility(NamedRef? a) {
    ability = a;
    _changed();
  }

  void setMove(NamedRef? m) {
    move = m;
    _fetchMove();
    _changed();
  }

  void toggleEggGroup(int id) => _toggle(eggGroups, id);
  void toggleTrigger(int id) => _toggle(triggers, id);

  void setStatIndex(int i) {
    if (i == statIndex) return;
    statIndex = i;
    statRange = null;
    _changed();
  }

  void setStatRange(RangeValues r) {
    final (lo, hi) = statBounds[statIndex];
    statRange = (r.start <= lo && r.end >= hi) ? null : r;
    _changed();
  }

  void _toggle<T>(Set<T> set, T v) {
    if (!set.remove(v)) set.add(v);
    _changed();
  }

  /// Filtros de progresso dependem dos carimbos: recalculam quando o AppState muda.
  bool get _dependsOnProgress =>
      capture != CaptureFilter.all || shinyOnly || favoritesOnly || marksMask != 0 || canEvolveOnly;

  /// Quantos filtros estão ligados (escopo de jogo e ordem não contam).
  int get activeFilterCount =>
      (types.isNotEmpty || typeMode == TypeMode.single || typeMode == TypeMode.dual ? 1 : 0) +
      (generations.isNotEmpty ? 1 : 0) +
      (categories.isNotEmpty ? 1 : 0) +
      (capture != CaptureFilter.all ? 1 : 0) +
      (shinyOnly ? 1 : 0) +
      (favoritesOnly ? 1 : 0) +
      (marksMask != 0 ? 1 : 0) +
      (canEvolveOnly ? 1 : 0) +
      (ability != null ? 1 : 0) +
      (move != null ? 1 : 0) +
      (eggGroups.isNotEmpty ? 1 : 0) +
      (triggers.isNotEmpty ? 1 : 0) +
      (statRange != null ? 1 : 0) +
      (_showForms ? 1 : 0);

  /// Filtros que só aparecem na folha (o chip "Filtros" conta estes).
  int get sheetOnlyFilterCount =>
      activeFilterCount -
      (types.isNotEmpty || typeMode == TypeMode.single || typeMode == TypeMode.dual ? 1 : 0) -
      (capture == CaptureFilter.uncaptured ? 1 : 0);

  void clearTypes() {
    types.clear();
    typeMode = TypeMode.any;
    _changed();
  }

  void clearFilters() {
    types.clear();
    typeMode = TypeMode.any;
    generations.clear();
    categories.clear();
    regionalForms.clear();
    capture = CaptureFilter.all;
    shinyOnly = false;
    favoritesOnly = false;
    marksMask = 0;
    canEvolveOnly = false;
    ability = null;
    move = null;
    _learners = null;
    moveLoading = false;
    moveFailed = false;
    _moveToken++;
    eggGroups.clear();
    triggers.clear();
    statIndex = 6;
    statRange = null;
    _showForms = false;
    _changed();
  }

  Future<void> _fetchMove() async {
    final m = move;
    final token = ++_moveToken;
    _learners = null;
    moveFailed = false;
    if (m == null) {
      moveLoading = false;
      return;
    }
    moveLoading = true;
    final vg = scopeVg;
    final List<int?> games;
    if (vg == null) {
      games = const [null];
    } else {
      final base = dex.baseOf(vg);
      games = [base.id, for (final g in dex.versionGroups) if (g.parentId == base.id && g.isDlc) g.id];
    }
    try {
      final sets = await Future.wait([for (final g in games) dex.whoLearns(m.id, g)]);
      if (token != _moveToken) return;
      _learners = {for (final s in sets) ...s};
    } catch (_) {
      if (token != _moveToken) return;
      moveFailed = true;
      _learners = const {};
    }
    moveLoading = false;
    _dirty = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Busca

  String _query = '';
  String get query => _query;

  void _onQuery() {
    final q = DexEntry.normalize(search.text);
    if (q == _query) return;
    _query = q;
    _changed();
  }

  /// Sugestão para busca sem resultado (o nome mais próximo dentro do escopo e dos filtros).
  String? get suggestion {
    _ensure();
    return _suggestion;
  }

  // ---------------------------------------------------------------------------
  // Resultado

  bool _dirty = true;
  bool _resetScroll = false;
  List<DexEntry> _result = const [];
  Map<int, int> _indexOf = const {};
  Map<int, int> _previousIndexOf = const {};
  String? _suggestion;
  int _version = 0;

  /// Muda a cada recálculo; as linhas usam para animar da posição antiga para a nova.
  int get version {
    _ensure();
    return _version;
  }

  List<DexEntry> get result {
    _ensure();
    return _result;
  }

  /// pokemonId → posição no resultado atual.
  Map<int, int> get indexOf {
    _ensure();
    return _indexOf;
  }

  /// pokemonId → posição no resultado anterior.
  Map<int, int> get previousIndexOf {
    _ensure();
    return _previousIndexOf;
  }

  /// A última mudança veio do usuário (busca, filtro, ordem): a lista volta para o topo.
  bool takeScrollReset() {
    final r = _resetScroll;
    _resetScroll = false;
    return r;
  }

  // ---------------------------------------------------------------------------
  // Persistência: filtros, ordem, exibição e escopo ficam salvos entre aberturas do app.

  static const _settingsKey = 'pokedex_state';
  Timer? _saveTimer;
  String? _savedJson;
  bool _restored = false;

  /// Algo difere do padrão (o botão Resetar só acende nesse caso).
  bool get isCustomized =>
      activeFilterCount > 0 || _sort != SortKey.number || !_followAdventure || !_regionalOnly || search.text.isNotEmpty;

  /// Volta busca, filtros, ordem e escopo ao padrão (o modo lista/grade é preferência e fica).
  void resetAll() {
    _followAdventure = true;
    _pickedVg = null;
    _lastVg = scopeVg;
    _regionalOnly = true;
    _sort = SortKey.number;
    search.clear();
    clearFilters();
  }

  Map<String, Object?> _toJson() => {
        'grid': _grid,
        'sort': _sort.name,
        'showForms': _showForms,
        'regionalOnly': _regionalOnly,
        'followAdventure': _followAdventure,
        'pickedVg': _pickedVg,
        'types': types.toList(),
        'typeMode': typeMode.name,
        'generations': generations.toList(),
        'categories': categories.toList(),
        'regionalForms': regionalForms.toList(),
        'capture': capture.name,
        'shinyOnly': shinyOnly,
        'favoritesOnly': favoritesOnly,
        'marksMask': marksMask,
        'canEvolveOnly': canEvolveOnly,
        'ability': ability?.id,
        'move': move?.id,
        'eggGroups': eggGroups.toList(),
        'triggers': triggers.toList(),
        'statIndex': statIndex,
        'statRange': statRange == null ? null : [statRange!.start, statRange!.end],
      };

  void _apply(Map<String, Object?> j) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    List<X> list<X>(Object? v) => [for (final x in (v as List? ?? const [])) x as X];
    NamedRef? ref(List<NamedRef> all, Object? id) => id == null ? null : all.where((r) => r.id == id).firstOrNull;

    _grid = j['grid'] as bool? ?? false;
    _sort = pick(SortKey.values, j['sort'], SortKey.number);
    _showForms = j['showForms'] as bool? ?? false;
    _regionalOnly = j['regionalOnly'] as bool? ?? true;
    _followAdventure = j['followAdventure'] as bool? ?? true;
    final picked = j['pickedVg'] as int?;
    _pickedVg = picked != null && dex.versionGroupsById.containsKey(picked) ? picked : null;
    types
      ..clear()
      ..addAll(list<String>(j['types']).where(dex.types.containsKey));
    typeMode = pick(TypeMode.values, j['typeMode'], TypeMode.any);
    generations
      ..clear()
      ..addAll(list<int>(j['generations']));
    categories
      ..clear()
      ..addAll(list<String>(j['categories']));
    regionalForms
      ..clear()
      ..addAll(list<String>(j['regionalForms']));
    capture = pick(CaptureFilter.values, j['capture'], CaptureFilter.all);
    shinyOnly = j['shinyOnly'] as bool? ?? false;
    favoritesOnly = j['favoritesOnly'] as bool? ?? false;
    marksMask = j['marksMask'] as int? ?? 0;
    canEvolveOnly = j['canEvolveOnly'] as bool? ?? false;
    ability = ref(dex.abilities, j['ability']);
    move = ref(dex.moves, j['move']);
    eggGroups
      ..clear()
      ..addAll(list<int>(j['eggGroups']));
    triggers
      ..clear()
      ..addAll(list<int>(j['triggers']));
    final si = j['statIndex'] as int? ?? 6;
    statIndex = si >= 0 && si < statBounds.length ? si : 6;
    final range = j['statRange'] as List?;
    statRange = range == null ? null : RangeValues((range[0] as num).toDouble(), (range[1] as num).toDouble());
  }

  Future<void> _restore() async {
    try {
      final row = await (app.user.select(app.user.settings)..where((s) => s.key.equals(_settingsKey))).getSingleOrNull();
      if (row != null) {
        _savedJson = row.value;
        _apply(jsonDecode(row.value) as Map<String, Object?>);
        _lastVg = scopeVg;
        if (move != null) _fetchMove();
      }
    } catch (_) {
      // Estado salvo ilegível (versão antiga): começa do padrão.
    }
    _restored = true;
    _changed();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!_restored) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    final json = jsonEncode(_toJson());
    if (json == _savedJson) return;
    _savedJson = json;
    await app.user.into(app.user.settings).insertOnConflictUpdate(SettingsCompanion(key: const Value(_settingsKey), value: Value(json)));
  }

  void _changed({bool resetScroll = true}) {
    _dirty = true;
    _resetScroll = _resetScroll || resetScroll;
    notifyListeners();
  }

  void _onApp() {
    final vg = scopeVg;
    if (vg != _lastVg) {
      _lastVg = vg;
      if (move != null) _fetchMove();
      _changed();
      return;
    }
    if (_dependsOnProgress) _changed(resetScroll: false);
  }

  void _ensure() {
    if (!_dirty) return;
    _dirty = false;
    final previous = _indexOf;
    _compute();
    _previousIndexOf = previous;
    _version++;
  }

  void _compute() {
    final vg = scopeVg;
    final inGame = vg == null ? null : speciesInGame(vg);
    final scope = _scopeSpecies(vg);
    final primary = vg == null ? null : _primaryIn(vg);
    final game = vg == null ? null : dex.baseOf(vg);
    _suggestion = null;
    if (move != null && moveLoading) {
      _result = const [];
      _indexOf = const {};
      return;
    }
    final formsOn = formsVisible;
    final q = _query;
    final tokens = q.isEmpty ? const <String>[] : q.split(' ');
    final number = parseDexNumber(search.text);
    final hits = <_Hit>[];
    final pool = <int>[];
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (scope != null && !scope.contains(e.speciesId)) continue;
      // Totens nunca entram; megas e gmax só nos jogos que têm a mecânica.
      if (e.identifier.contains('-totem')) continue;
      if (game != null && ((e.isMega && !game.hasMegaEvolution) || (e.isGmax && !game.hasGigantamax))) continue;
      if (!_passes(e, scope)) continue;
      final isPrimary = primary == null ? e.isDefault : primary.contains(e.pokemonId);
      final hiddenForm = !isPrimary && !formsOn;
      if (q.isEmpty) {
        if (!hiddenForm) hits.add(_Hit(i, 0));
        continue;
      }
      if (!hiddenForm) pool.add(i);
      final tier = _match(i, e, inGame, number, q, tokens, hiddenForm: hiddenForm);
      if (tier != MatchTier.none) hits.add(_Hit(i, tier));
    }
    final cmp = _comparator(inGame);
    hits.sort((a, b) {
      if (q.isNotEmpty && a.tier != b.tier) return a.tier - b.tier;
      return cmp(a.index, b.index);
    });
    _result = [for (final h in hits) _entries[h.index]];
    _indexOf = {for (var i = 0; i < _result.length; i++) _result[i].pokemonId: i};
    if (_result.isEmpty && q.length >= 3 && number == null) _suggestion = _suggest(q, pool);
  }

  int _match(int i, DexEntry e, Map<int, int>? inGame, int? number, String q, List<String> tokens, {required bool hiddenForm}) {
    if (number != null) {
      if (hiddenForm) return MatchTier.none;
      if (inGame != null && inGame[e.speciesId] == number) return MatchTier.regionalNumber;
      if (e.speciesId == number) return MatchTier.nationalNumber;
      return MatchTier.none;
    }
    final words = _words[i];
    if (hiddenForm) {
      // Forma escondida só aparece quando a busca cita algo que só ela tem ("mega", "alolan").
      final own = _formWords[i];
      final citesForm = tokens.any((t) => own.any((w) => w.startsWith(t)));
      if (!citesForm) return MatchTier.none;
      final all = tokens.every((t) => words.any((w) => w.startsWith(t)));
      return all ? MatchTier.wordPrefix : MatchTier.none;
    }
    if (_names[i].startsWith(q)) return MatchTier.namePrefix;
    if (tokens.length == 1) {
      if (words.any((w) => w.startsWith(q))) return MatchTier.wordPrefix;
      if (e.searchKey.contains(q)) return MatchTier.contains;
      if (words.any((w) => fuzzyWordMatch(q, w))) return MatchTier.fuzzy;
      return MatchTier.none;
    }
    if (e.searchKey.contains(q)) return MatchTier.contains;
    var fuzzy = false;
    for (final t in tokens) {
      if (words.any((w) => w.startsWith(t))) continue;
      if (words.any((w) => fuzzyWordMatch(t, w))) {
        fuzzy = true;
        continue;
      }
      return MatchTier.none;
    }
    return fuzzy ? MatchTier.fuzzy : MatchTier.contains;
  }

  String? _suggest(String q, List<int> pool) {
    var best = 1 << 20;
    String? name;
    final limit = q.length <= 4 ? 2 : (q.length / 2).ceil();
    for (final i in pool) {
      for (final w in _words[i]) {
        final d = editDistance(q, w, max: limit);
        if (d < best) {
          best = d;
          name = _entries[i].name;
        }
      }
    }
    return best <= limit ? name : null;
  }

  int Function(int, int) _comparator(Map<int, int>? inGame) {
    // No escopo de um jogo: dex regional primeiro, depois quem só é obtível (pelo nº nacional).
    int number(int i) {
      final e = _entries[i];
      if (inGame == null) return e.speciesId;
      return inGame[e.speciesId] ?? (100000 + e.speciesId);
    }

    int byNumber(int a, int b) {
      final d = number(a) - number(b);
      return d != 0 ? d : a - b;
    }

    final stat = _sort.statIndex;
    return switch (_sort) {
      SortKey.number => byNumber,
      SortKey.name => (a, b) {
          final d = _names[a].compareTo(_names[b]);
          return d != 0 ? d : byNumber(a, b);
        },
      SortKey.height => (a, b) {
          final d = _entries[b].height - _entries[a].height;
          return d != 0 ? d : byNumber(a, b);
        },
      SortKey.weight => (a, b) {
          final d = _entries[b].weight - _entries[a].weight;
          return d != 0 ? d : byNumber(a, b);
        },
      _ => (a, b) {
          final d = _entries[b].stats[stat!] - _entries[a].stats[stat];
          return d != 0 ? d : byNumber(a, b);
        },
    };
  }

  /// Valor mostrado à direita da linha quando a ordem é por stat/altura/peso.
  String? sortValueOf(DexEntry e) {
    if (!_sort.showsValue) return null;
    return switch (_sort) {
      SortKey.height => Labels.height(e.height),
      SortKey.weight => Labels.weight(e.weight),
      _ => '${e.stats[_sort.statIndex!]}',
    };
  }

  bool _stamped(int speciesId) => (app.scoped[speciesId]?.count ?? 0) > 0;

  bool _passes(DexEntry e, Set<int>? scope) {
    if (types.isNotEmpty || typeMode == TypeMode.single || typeMode == TypeMode.dual) {
      final ok = switch (typeMode) {
        TypeMode.any => types.contains(e.type1) || types.contains(e.type2),
        TypeMode.single => e.type2 == null && (types.isEmpty || types.contains(e.type1)),
        TypeMode.dual => e.type2 != null && (types.isEmpty || types.contains(e.type1) || types.contains(e.type2)),
        TypeMode.all => types.every((t) => t == e.type1 || t == e.type2),
      };
      if (!ok) return false;
    }
    if (generations.isNotEmpty && !generations.contains(e.generationId)) return false;
    if (categories.isNotEmpty && !categories.any((c) => _inCategory(e, c))) return false;
    final sid = e.speciesId;
    switch (capture) {
      case CaptureFilter.all:
        break;
      case CaptureFilter.captured:
        if (!_stamped(sid)) return false;
      case CaptureFilter.uncaptured:
        if (_stamped(sid)) return false;
    }
    if (shinyOnly && !(app.scoped[sid]?.shiny ?? false)) return false;
    if (favoritesOnly || marksMask != 0) {
      final m = app.markOf(sid);
      if (favoritesOnly && !m.favorite) return false;
      if (marksMask != 0 && (m.marks & marksMask) == 0) return false;
    }
    if (canEvolveOnly) {
      if (!_stamped(sid)) return false;
      final next = _children[sid];
      if (next == null || !next.any((c) => (scope == null || scope.contains(c)) && !_stamped(c))) return false;
    }
    if (ability != null && !e.abilityIds.contains(ability!.id)) return false;
    if (move != null) {
      final l = _learners;
      if (l == null) return false;
      if (!l.contains(e.pokemonId)) {
        final def = e.isDefault ? null : dex.defaultBySpecies[sid];
        if (def == null || !l.contains(def.pokemonId)) return false;
      }
    }
    if (eggGroups.isNotEmpty && !e.eggGroupIds.any(eggGroups.contains)) return false;
    if (triggers.isNotEmpty && !e.evolvesByTriggerIds.any(triggers.contains)) return false;
    final r = statRange;
    if (r != null) {
      final v = e.stats[statIndex];
      if (v < r.start.round() || v > r.end.round()) return false;
    }
    return true;
  }

  bool _inCategory(DexEntry e, String c) => switch (c) {
        'legendary' => e.isLegendary,
        'mythical' => e.isMythical,
        'baby' => e.isBaby,
        'mega' => e.isMega,
        'gmax' => e.isGmax,
        'regional' => e.regional != null && (regionalForms.isEmpty || regionalForms.contains(e.regional)),
        _ => e.categories.contains(c),
      };
}
