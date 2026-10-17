import 'package:flutter/material.dart';

import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/data/specimen_draft.dart';
import '../../core/data/user_database.dart';
import '../../core/logic/stats_calc.dart';
import '../../core/state/app_state.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/stamp.dart';
import '../../core/widgets/type_badge.dart';
import '../detail/detail_common.dart';
import '../pokedex/chip_style.dart';
import 'pickers.dart';
import 'sheet_widgets.dart';
import 'stats_table.dart';

/// Abre a ficha do exemplar. Devolve o id gravado, ou null se o usuário saiu sem salvar.
Future<String?> openSpecimenSheet(
  BuildContext context,
  SpecimenDraft draft, {
  String? existingId,
  Set<String> highlighted = const {},
}) {
  final page = SpecimenSheetScreen(draft: draft, existingId: existingId, highlighted: highlighted);
  if (MediaQuery.disableAnimationsOf(context)) {
    return Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => page,
      ),
    );
  }
  return Navigator.of(context).push<String>(MaterialPageRoute<String>(builder: (_) => page));
}

/// Ficha completa de um exemplar. A leitura por foto abre esta mesma tela com o rascunho
/// preenchido e [highlighted] com os campos lidos ('level', 'gender', 'nature', 'ability',
/// 'ball', 'heldItem', 'tera', 'moves', 'stats', 'nickname', 'shiny', 'form'), marcados
/// "da foto" até o usuário mexer neles.
class SpecimenSheetScreen extends StatefulWidget {
  const SpecimenSheetScreen({super.key, required this.draft, this.existingId, this.highlighted = const {}});

  final SpecimenDraft draft;

  /// Exemplar a atualizar; null cria um novo.
  final String? existingId;
  final Set<String> highlighted;

  @override
  State<SpecimenSheetScreen> createState() => _SpecimenSheetScreenState();
}

class _SpecimenSheetScreenState extends State<SpecimenSheetScreen> {
  late final SpecimenDraft _d;
  late final String _initial;
  late final Set<String> _hl = {...widget.highlighted};
  bool _saving = false;

  late final _nickname = TextEditingController(text: _d.nickname ?? '');
  late final _caughtWhere = TextEditingController(text: _d.caughtWhere ?? '');
  late final _notes = TextEditingController(text: _d.notes ?? '');
  late final _level = TextEditingController(text: _d.level?.toString() ?? '');
  late final _seenCtl = _controllers(_d.stats);
  late final _evCtl = _controllers(_d.evs);
  late final _ivCtl = _controllers(_d.ivs);

  final _details = <int, Future<SpeciesDetail>>{};
  final _learnsets = <String, Future<(List<LearnedMove>, VersionGroup?)>>{};
  int? _fallbackGame;
  Map<int, String>? _moveNames;

  AppState get _state => AppScope.read(context);

  @override
  void initState() {
    super.initState();
    _d = _copy(widget.draft);
    // Aventura apagada não pode ir para o banco (chave estrangeira).
    final advId = _d.adventureId;
    if (advId != null && !_state.adventures.any((a) => a.id == advId)) _d.adventureId = null;
    _initial = _signature(_d);
  }

  @override
  void dispose() {
    for (final c in [_nickname, _caughtWhere, _notes, _level, ..._seenCtl, ..._evCtl, ..._ivCtl]) {
      c.dispose();
    }
    super.dispose();
  }

  static List<TextEditingController> _controllers(List<int?> v) =>
      [for (final x in v) TextEditingController(text: x?.toString() ?? '')];

  static List<int?> _six(List<int?> v) => [for (var i = 0; i < 6; i++) i < v.length ? v[i] : null];

  /// Cópia de trabalho: a tela nunca altera o rascunho de quem a abriu.
  static SpecimenDraft _copy(SpecimenDraft s) => SpecimenDraft(
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
        moves: {...s.moves}.take(4).toList(),
        teraType: s.teraType,
        notes: s.notes,
      );

  static String _signature(SpecimenDraft d) => [
        d.pokemonId,
        d.adventureId,
        d.isShiny,
        d.nickname?.trim() ?? '',
        d.level,
        d.nature,
        d.abilityId,
        d.gender,
        d.ballItemId,
        d.caughtWhere?.trim() ?? '',
        d.heldItemId,
        d.ivs.join(','),
        d.evs.join(','),
        d.stats.join(','),
        d.moves.join(','),
        d.teraType,
        d.notes?.trim() ?? '',
      ].join('|');

  /// Rascunho vindo da foto e ainda não salvo também conta como alteração.
  bool get _dirty => _signature(_d) != _initial || (widget.existingId == null && widget.highlighted.isNotEmpty);

  bool _from(String key) => _hl.contains(key);

  /// Aplica uma edição; o campo deixa de estar marcado "da foto" quando o usuário mexe nele.
  void _edit(String? key, VoidCallback change) => setState(() {
        change();
        if (key != null) _hl.remove(key);
      });

  // ---------------------------------------------------------------------------
  // Dados derivados

  DexEntry get _variety => _state.dex.byPokemonId[_d.pokemonId] ?? _state.dex.defaultBySpecies[_d.speciesId]!;

  List<DexEntry> get _forms => [
        for (final e in _state.dex.formsBySpecies[_d.speciesId] ?? const <DexEntry>[])
          if ((!e.isBattleOnly && !e.isMega && !e.isGmax) || e.pokemonId == _d.pokemonId) e,
      ];

  Adventure? get _adventure => _state.adventures.where((a) => a.id == _d.adventureId).firstOrNull;

  /// Jogo da aventura do exemplar; sem aventura, o jogo mais recente em que a espécie aparece.
  VersionGroup get _game {
    final dex = _state.dex;
    final adv = _adventure;
    final own = adv == null ? null : dex.versionGroupsById[adv.versionGroupId];
    if (own != null) return own;
    _fallbackGame ??= () {
      final games = dex.versionGroups.where((v) => v.isPlayable).toList()
        ..sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
      for (final g in games) {
        if (dex.availableInGame(g.id).contains(_d.speciesId)) return g.id;
      }
      return games.first.id;
    }();
    return dex.versionGroupsById[_fallbackGame]!;
  }

  Future<SpeciesDetail> get _detail => _details[_d.pokemonId] ??= _state.dex.speciesDetail(_d.speciesId, _d.pokemonId);

  Future<(List<LearnedMove>, VersionGroup?)> get _learnset {
    final g = _game.id;
    return _learnsets['${_d.pokemonId}-$g'] ??= _state.dex.learnset(_d.pokemonId, g);
  }

  Nature? get _nature {
    final n = _d.nature;
    if (n == null) return null;
    final key = n.toLowerCase();
    return _state.dex.natures.where((x) => x.identifier == key || x.name.toLowerCase() == key).firstOrNull;
  }

  bool get _showTera {
    if (_d.teraType != null || _from('tera')) return true;
    final adv = _adventure;
    if (adv == null) return true;
    return _state.dex.baseOf(adv.versionGroupId).identifier == 'scarlet-violet';
  }

  String _moveName(int id) => (_moveNames ??= {for (final m in _state.dex.moves) m.id: m.name})[id] ?? 'Golpe #$id';

  /// Faixas de IV; null quando falta nível válido ou nenhum stat visto.
  List<(int, int)?>? get _ranges {
    final lvl = _d.level;
    if (lvl == null || lvl < 1 || lvl > 100) return null;
    final seen = [for (final v in _d.stats) StatLimits.statOk(v) ? v : null];
    if (seen.every((v) => v == null)) return null;
    final evs = [for (final v in _d.evs) StatLimits.evOk(v) ? v : null];
    return StatsCalc.ivRanges(_variety, lvl, seen, evs: evs, nature: _nature);
  }

  String? get _levelError {
    final l = _d.level;
    return l != null && (l < 1 || l > 100) ? 'De 1 a 100' : null;
  }

  bool get _hasErrors =>
      _levelError != null ||
      _d.stats.any((v) => !StatLimits.statOk(v)) ||
      _d.evs.any((v) => !StatLimits.evOk(v)) ||
      _d.ivs.any((v) => !StatLimits.ivOk(v)) ||
      StatLimits.evSum(_d.evs) > StatLimits.evTotal;

  // ---------------------------------------------------------------------------
  // Ações

  void _snack(String message) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(persist: false, content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_hasErrors) {
      _snack('Confira os campos em vermelho antes de salvar.');
      return;
    }
    setState(() => _saving = true);
    try {
      // Espécies de gênero fixo gravam o gênero certo mesmo sem o usuário escolher.
      final rate = (await _detail).genderRate;
      if (rate == -1) {
        _d.gender = null;
      } else if (rate == 0) {
        _d.gender = 'm';
      } else if (rate == 8) {
        _d.gender = 'f';
      }
    } catch (_) {
      // Sem detalhe da espécie: mantém o que o usuário escolheu.
    }
    try {
      final id = await _state.saveDraft(_d, existingId: widget.existingId);
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Não foi possível salvar a ficha. Tente de novo.');
    }
  }

  Future<bool> _confirmDiscard() async {
    final text = Theme.of(context).textTheme;
    final fromPhoto = widget.existingId == null && widget.highlighted.isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Ramp.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sheet)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        title: const Text('Descartar alterações?'),
        content: Text(fromPhoto ? 'Os dados lidos da foto não serão salvos.' : 'O que você mudou nesta ficha não será salvo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Continuar editando')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(c).colorScheme.error),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _pickForm() async {
    final current = _variety;
    final picked = await showListPicker<DexEntry>(
      context,
      title: 'Forma',
      options: _forms,
      label: (e) => e.formName ?? e.name,
      selected: current,
      leading: (e) => SizedBox.square(dimension: 40, child: PokemonSprite(e, shiny: _d.isShiny)),
    );
    final e = picked?.value;
    if (e == null || !mounted || e.pokemonId == current.pokemonId) return;
    _edit('form', () {
      _d.pokemonId = e.pokemonId;
      // Habilidade de outra forma deixa de valer.
      if (_d.abilityId != null && !e.abilityIds.contains(_d.abilityId)) _d.abilityId = null;
    });
  }

  Future<void> _pickBall(ItemRef? current) async {
    final picked = await showListPicker<ItemRef>(
      context,
      title: 'Pokébola',
      options: _state.dex.balls,
      label: (b) => b.name,
      selected: current,
      leading: (b) => ItemSprite(b),
      noneLabel: 'Não informada',
      searchHint: 'Buscar pokébola',
    );
    if (picked == null || !mounted) return;
    _edit('ball', () => _d.ballItemId = picked.value?.id);
  }

  Future<void> _pickItem(ItemRef? current) async {
    final picked = await showListPicker<ItemRef>(
      context,
      title: 'Item segurado',
      options: _state.dex.holdableItems,
      label: (b) => b.name,
      selected: current,
      leading: (b) => ItemSprite(b),
      noneLabel: 'Nenhum item',
      searchHint: 'Buscar item',
    );
    if (picked == null || !mounted) return;
    _edit('heldItem', () => _d.heldItemId = picked.value?.id);
  }

  Future<void> _pickTera() async {
    final picked = await showTeraPicker(context, selected: _d.teraType);
    if (picked == null || !mounted) return;
    _edit('tera', () => _d.teraType = picked.value);
  }

  Future<void> _pickNature(Nature? current) async {
    final picked = await showListPicker<Nature>(
      context,
      title: 'Natureza',
      options: _state.dex.natures,
      label: (n) => n.name,
      selected: current,
      detail: (n) => NatureEffect(n, statNames: Labels.stats),
      noneLabel: 'Não informada',
    );
    if (picked == null || !mounted) return;
    _edit('nature', () => _d.nature = picked.value?.identifier);
  }

  Future<void> _addMove() async {
    final id = await showMovePicker(context, learnset: _learnset, game: _game, exclude: _d.moves.toSet());
    if (id == null || !mounted || _d.moves.length >= 4 || _d.moves.contains(id)) return;
    _edit('moves', () => _d.moves.add(id));
  }

  void _useEstimate(List<(int, int)?> r) => _edit(null, () {
        for (var i = 0; i < 6; i++) {
          final x = r[i];
          if (x == null || x.$1 != x.$2) continue;
          _d.ivs[i] = x.$1;
          _ivCtl[i].text = '${x.$1}';
        }
      });

  // ---------------------------------------------------------------------------
  // Tela

  @override
  Widget build(BuildContext context) {
    AppScope.of(context);
    final ranges = _ranges;
    return PopScope<Object?>(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(widget.existingId == null ? 'Nova ficha' : 'Editar ficha'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Space.s),
              child: TextButton(
                onPressed: _saving ? null : _save,
                child: Text('Salvar', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _saving ? Ramp.n4 : null)),
              ),
            ),
          ],
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            Space.gutter,
            Space.s,
            Space.gutter,
            MediaQuery.paddingOf(context).bottom + Space.xxxl,
          ),
          children: [
            _header(),
            _identity(),
            _natureSection(),
            _abilitySection(),
            _movesSection(),
            _statsSection(ranges),
            _notesSection(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final text = Theme.of(context).textTheme;
    final v = _variety;
    final nick = _d.nickname?.trim() ?? '';
    final forms = _forms;
    final adventures = [for (final a in _state.adventures) if (!a.archived || a.id == _d.adventureId) a];
    final form = v.formName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StampSlot(
              seed: _d.speciesId,
              ink: TypeInks.of(v.type1).ink,
              state: _d.isShiny ? StampState.shiny : StampState.stamped,
              size: 88,
              semanticLabel: _d.isShiny ? '${v.name} shiny' : v.name,
              child: PokemonSprite(v, shiny: _d.isShiny),
            ),
            const SizedBox(width: Space.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nick.isEmpty ? v.name : nick, style: text.headlineMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (nick.isNotEmpty)
                    Text(v.name, style: text.bodyMedium)
                  else if (form != null && form != v.name)
                    Text(form, style: text.bodySmall),
                  const SizedBox(height: Space.s),
                  Wrap(
                    spacing: Space.s,
                    runSpacing: Space.xs,
                    children: [for (final t in v.types) TypePill(t, dense: true)],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.l),
        if (forms.length > 1) ...[
          LabeledField(
            label: 'Forma',
            fromPhoto: _from('form'),
            child: PickerField(
              value: form ?? v.name,
              placeholder: v.name,
              semanticLabel: 'Forma',
              leading: SizedBox.square(dimension: 32, child: PokemonSprite(v, shiny: _d.isShiny)),
              onTap: _pickForm,
            ),
          ),
          const SizedBox(height: Space.m),
        ],
        _shinyRow(),
        const SizedBox(height: Space.m),
        LabeledField(
          label: 'Aventura',
          child: DropdownButtonFormField<String>(
            initialValue: _d.adventureId ?? '',
            isExpanded: true,
            style: text.bodyLarge,
            dropdownColor: Ramp.paper,
            borderRadius: BorderRadius.circular(Radii.sheet),
            icon: const Icon(Icons.expand_more_rounded, color: Ramp.n6),
            items: [
              const DropdownMenuItem(value: '', child: Text('Sem aventura')),
              for (final a in adventures)
                DropdownMenuItem(value: a.id, child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (id) => _edit(null, () => _d.adventureId = (id == null || id.isEmpty) ? null : id),
          ),
        ),
      ],
    );
  }

  Widget _shinyRow() {
    final text = Theme.of(context).textTheme;
    final on = _d.isShiny;
    void toggle() => _edit('shiny', () => _d.isShiny = !_d.isShiny);
    return MergeSemantics(
      child: InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(on ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined, color: on ? Gold.text : Ramp.n6),
              const SizedBox(width: Space.m),
              Text('Shiny', style: text.bodyLarge),
              if (_from('shiny')) ...[const SizedBox(width: Space.s), const FromPhotoTag()],
              const Spacer(),
              Switch(
                value: on,
                onChanged: (_) => toggle(),
                thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Ramp.paper : Ramp.n5),
                trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Gold.ink : Ramp.n1),
                trackOutlineColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? Colors.transparent : Ramp.n4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identity() {
    final dex = _state.dex;
    final ball = _d.ballItemId == null ? null : dex.balls.where((b) => b.id == _d.ballItemId).firstOrNull;
    final item = _d.heldItemId == null ? null : dex.holdableItems.where((b) => b.id == _d.heldItemId).firstOrNull;
    final tera = _d.teraType;
    const gap = SizedBox(height: Space.l);
    return SheetSection(
      title: 'Identidade',
      children: [
        LabeledField(
          label: 'Apelido',
          fromPhoto: _from('nickname'),
          child: TextField(
            controller: _nickname,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (s) => _edit('nickname', () => _d.nickname = s),
            decoration: InputDecoration(hintText: _variety.speciesName),
          ),
        ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: LabeledField(
                label: 'Nível',
                fromPhoto: _from('level'),
                error: _levelError,
                child: NumField(
                  controller: _level,
                  semanticLabel: 'Nível',
                  hint: '1–100',
                  invalid: _levelError != null,
                  onChanged: (x) => _edit('level', () => _d.level = x),
                ),
              ),
            ),
            const SizedBox(width: Space.m),
            Expanded(child: LabeledField(label: 'Gênero', fromPhoto: _from('gender'), child: _gender())),
          ],
        ),
        gap,
        LabeledField(
          label: 'Pokébola',
          fromPhoto: _from('ball'),
          child: PickerField(
            value: ball?.name ?? (_d.ballItemId == null ? null : 'Item #${_d.ballItemId}'),
            placeholder: 'Não informada',
            semanticLabel: 'Pokébola',
            leading: ball == null ? null : ItemSprite(ball, size: 28),
            onTap: () => _pickBall(ball),
          ),
        ),
        gap,
        LabeledField(
          label: 'Local ou jogo de captura',
          child: TextField(
            controller: _caughtWhere,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (s) => _edit(null, () => _d.caughtWhere = s),
            decoration: const InputDecoration(hintText: 'Rota 3, ovo, troca…'),
          ),
        ),
        gap,
        LabeledField(
          label: 'Item segurado',
          fromPhoto: _from('heldItem'),
          child: PickerField(
            value: item?.name ?? (_d.heldItemId == null ? null : 'Item #${_d.heldItemId}'),
            placeholder: 'Nenhum item',
            semanticLabel: 'Item segurado',
            leading: item == null ? null : ItemSprite(item, size: 28),
            onTap: () => _pickItem(item),
          ),
        ),
        if (_showTera) ...[
          gap,
          LabeledField(
            label: 'Tipo Tera',
            fromPhoto: _from('tera'),
            child: PickerField(
              value: tera == null ? null : (dex.types[tera]?.namePt ?? tera),
              placeholder: 'Não informado',
              semanticLabel: 'Tipo Tera',
              leading: tera == null ? null : TypeIcon(tera, size: 20),
              onTap: _pickTera,
            ),
          ),
        ],
      ],
    );
  }

  Widget _gender() => FutureBuilder<SpeciesDetail>(
        future: _detail,
        builder: (context, snap) {
          final text = Theme.of(context).textTheme;
          final fixed = switch (snap.data?.genderRate) {
            -1 => 'Sem gênero',
            0 => 'Sempre macho',
            8 => 'Sempre fêmea',
            _ => null,
          };
          if (fixed != null) {
            return SizedBox(
              height: 48,
              child: Align(alignment: Alignment.centerLeft, child: Text(fixed, style: text.bodyLarge)),
            );
          }
          return SegmentedButton<String>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: 'm', icon: Icon(Icons.male_rounded), label: Text('Macho')),
              ButtonSegment(value: 'f', icon: Icon(Icons.female_rounded), label: Text('Fêmea')),
            ],
            selected: {?_d.gender},
            onSelectionChanged: (s) => _edit('gender', () => _d.gender = s.firstOrNull),
          );
        },
      );

  Widget _natureSection() {
    final nat = _nature;
    final text = Theme.of(context).textTheme;
    return SheetSection(
      title: 'Natureza',
      fromPhoto: _from('nature'),
      children: [
        PickerField(
          value: nat?.name,
          placeholder: 'Não informada',
          semanticLabel: 'Natureza',
          detail: nat == null ? null : NatureEffect(nat, statNames: Labels.stats),
          onTap: () => _pickNature(nat),
        ),
        if (_d.nature != null && nat == null)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs, left: Space.l),
            child: Text(
              'Natureza “${_d.nature}” não reconhecida. Escolha na lista.',
              style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _abilitySection() => SheetSection(
        title: 'Habilidade',
        fromPhoto: _from('ability'),
        children: [
          FutureBuilder<SpeciesDetail>(
            future: _detail,
            builder: (context, snap) {
              final text = Theme.of(context).textTheme;
              final abilities = snap.data?.abilities;
              if (abilities == null) {
                return snap.hasError
                    ? const InfoNote('Não foi possível carregar as habilidades desta forma.')
                    : const SizedBox(height: 48);
              }
              final selected = abilities.where((a) => a.id == _d.abilityId).firstOrNull;
              final foreign = _d.abilityId != null && selected == null;
              final foreignName = foreign
                  ? (_state.dex.abilities.where((a) => a.id == _d.abilityId).firstOrNull?.name ?? 'Habilidade #${_d.abilityId}')
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: Space.s,
                    runSpacing: Space.s,
                    children: [
                      for (final a in abilities)
                        ChoiceChip(
                          label: Text(a.isHidden ? '${a.name} · oculta' : a.name),
                          selected: a.id == _d.abilityId,
                          showCheckmark: false,
                          labelStyle: chipLabel(context, a.id == _d.abilityId),
                          onSelected: (on) => _edit('ability', () => _d.abilityId = on ? a.id : null),
                        ),
                      if (foreign)
                        InputChip(
                          label: Text(foreignName!),
                          selected: true,
                          showCheckmark: false,
                          labelStyle: chipLabel(context, true),
                          deleteIcon: const Icon(Icons.close_rounded, size: 18, color: Ramp.paper),
                          deleteButtonTooltipMessage: 'Remover',
                          onDeleted: () => _edit('ability', () => _d.abilityId = null),
                        ),
                    ],
                  ),
                  if (foreign)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.s),
                      child: Text(
                        '$foreignName não é habilidade desta forma. Confira a forma ou escolha outra.',
                        style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                      ),
                    )
                  else if (selected?.shortEffect != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.m),
                      child: Text(selected!.shortEffect!, style: text.bodyMedium),
                    ),
                ],
              );
            },
          ),
        ],
      );

  Widget _movesSection() {
    final text = Theme.of(context).textTheme;
    final game = _game;
    return SheetSection(
      title: 'Golpes',
      fromPhoto: _from('moves'),
      trailing: Text('${_d.moves.length} de 4', style: text.labelMedium),
      children: [
        FutureBuilder<(List<LearnedMove>, VersionGroup?)>(
          future: _learnset,
          builder: (context, snap) {
            final learned = <int, LearnedMove>{};
            for (final m in snap.data?.$1 ?? const <LearnedMove>[]) {
              learned.putIfAbsent(m.moveId, () => m);
            }
            final loaded = snap.connectionState == ConnectionState.done;
            final source = snap.data?.$2;
            final sourceName = source?.name ?? game.name;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (loaded && source != null && source.id != game.id)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s),
                    child: InfoNote('Lista de golpes com dados de ${source.name}.'),
                  ),
                if (_d.moves.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: Text('Nenhum golpe anotado.', style: text.bodyMedium),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _d.moves.length,
                    proxyDecorator: (child, _, _) => Material(color: Ramp.n1, borderRadius: BorderRadius.circular(Radii.sheet), child: child),
                    onReorderItem: (from, to) => _edit('moves', () {
                      final m = _d.moves.removeAt(from);
                      _d.moves.insert(to, m);
                    }),
                    itemBuilder: (context, i) {
                      final id = _d.moves[i];
                      final l = learned[id];
                      return Padding(
                        key: ValueKey(id),
                        padding: const EdgeInsets.symmetric(vertical: Space.xs / 2),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: const SizedBox.square(
                                dimension: 48,
                                child: Icon(Icons.drag_indicator_rounded, color: Ramp.n5),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l?.name ?? _moveName(id), style: text.titleMedium),
                                  if (l != null) ...[
                                    const SizedBox(height: Space.xs),
                                    Wrap(
                                      spacing: Space.s,
                                      runSpacing: Space.xs,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (l.type != null) TypePill(l.type!, dense: true),
                                        Text(learnLabel(l), style: text.bodySmall),
                                      ],
                                    ),
                                  ] else if (loaded)
                                    Text('Não aprende em $sourceName', style: text.bodySmall),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remover golpe',
                              icon: const Icon(Icons.close_rounded, color: Ramp.n6),
                              onPressed: () => _edit('moves', () => _d.moves.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (_d.moves.length < 4)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addMove,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Adicionar golpe'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _statsSection(List<(int, int)?>? ranges) {
    final text = Theme.of(context).textTheme;
    final exact = ranges == null
        ? const <int>[]
        : [
            for (var i = 0; i < 6; i++)
              if (ranges[i] != null && ranges[i]!.$1 == ranges[i]!.$2) i,
          ];
    final pending = ranges != null && exact.any((i) => _d.ivs[i] != ranges[i]!.$1);
    final anyRange = ranges != null && ranges.any((r) => r != null);
    return SheetSection(
      title: 'Stats',
      fromPhoto: _from('stats'),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Space.m),
          child: Text('“Visto” é o valor da tela de resumo do jogo; no PS, o máximo.', style: text.bodySmall),
        ),
        StatsTable(
          seen: _d.stats,
          evs: _d.evs,
          ivs: _d.ivs,
          seenCtl: _seenCtl,
          evCtl: _evCtl,
          ivCtl: _ivCtl,
          ranges: ranges,
          onChanged: (column, i, value) => _edit(column == StatColumn.seen ? 'stats' : null, () {
            switch (column) {
              case StatColumn.seen:
                _d.stats[i] = value;
              case StatColumn.ev:
                _d.evs[i] = value;
              case StatColumn.iv:
                _d.ivs[i] = value;
            }
          }),
        ),
        if (ranges != null) ...[
          const SizedBox(height: Space.s),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: pending ? () => _useEstimate(ranges) : null,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Usar estimativa'),
            ),
          ),
          if (anyRange && exact.isEmpty)
            Text('Nenhuma faixa fechou num valor só ainda; em níveis mais altos ela estreita.', style: text.bodySmall)
          else if (exact.isNotEmpty && exact.length < 6)
            Text('Preenche só os IVs com um valor único.', style: text.bodySmall),
        ],
      ],
    );
  }

  Widget _notesSection() {
    OutlineInputBorder border(BorderSide side) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.sheet), borderSide: side);
    return SheetSection(
      title: 'Anotações',
      children: [
        TextField(
          controller: _notes,
          minLines: 3,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (s) => _edit(null, () => _d.notes = s),
          decoration: InputDecoration(
            hintText: 'Como conseguiu, planos de treino, o que quiser lembrar',
            border: border(BorderSide.none),
            enabledBorder: border(BorderSide.none),
            focusedBorder: border(const BorderSide(color: Ramp.ink, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
