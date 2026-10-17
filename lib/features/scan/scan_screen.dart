import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
import '../detail/evolution/evolution_text.dart';
import '../specimen/specimen_sheet_screen.dart';
import 'matcher.dart';
import 'reading.dart';
import 'resolver.dart';
import 'scan_flow.dart';
import 'scan_format.dart';
import 'scan_pipeline.dart';

/// Conferência da leitura por foto: carimbo da espécie, campos lidos (com "conferir" nos
/// duvidosos), IVs estimados, próxima evolução e onde gravar.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.paths, this.speciesId, this.existingId});
  final List<String> paths;
  final int? speciesId;
  final String? existingId;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

/// Jogo cujo layout a leitura entende.
const _svIdentifier = 'scarlet-violet';

class _ScanScreenState extends State<ScanScreen> {
  final _pages = <PageFields>[];
  final _choices = <String, Reading<Object>>{};
  MergedReading _merged = MergedReading(const []);
  ScanOutcome? _outcome;
  List<NextEvolution> _evolutions = const [];
  int? _chosenPokemonId;
  bool? _shiny;
  String? _gender;
  bool _genderTouched = false;
  String? _target;
  int? _targetSpecies;
  bool _busy = false;
  String _progress = '';
  bool _stamped = false;
  int _run = 0;

  late final AppState _app = AppScope.read(context);

  int get _readVg => _app.dex.versionGroups.where((v) => v.identifier == _svIdentifier).firstOrNull?.id ?? 25;

  /// Jogo da aventura (para a evolução); sem aventura, o da leitura.
  int get _gameVg => _app.contextVersionGroupId ?? _readVg;

  int get _readPages => _pages.where((p) => !p.isEmpty).length;

  @override
  void initState() {
    super.initState();
    _target = widget.existingId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _addPages(widget.paths));
  }

  Future<void> _addPages(List<String> paths) async {
    if (paths.isEmpty) return;
    final lx = Lexicons.of(_app.dex);
    setState(() => _busy = true);
    for (var i = 0; i < paths.length; i++) {
      if (!mounted) return;
      setState(() => _progress = paths.length == 1 ? 'Lendo a foto…' : 'Lendo foto ${i + 1} de ${paths.length}…');
      _pages.add(await scanPage(paths[i], lx));
    }
    _merged = MergedReading(_pages);
    // Escolhas já feitas continuam valendo se a opção ainda existe.
    _choices.forEach((key, r) {
      final options = _merged.conflicts[key];
      final pick = options?.where((o) => o.sameValue(r)).firstOrNull;
      if (pick != null) _merged.choose(key, pick);
    });
    await _resolve();
  }

  Future<void> _resolve() async {
    final run = ++_run;
    if (mounted) setState(() => _busy = true);
    final outcome = await resolveScan(
      _merged,
      _app.dex,
      vgId: _readVg,
      chosenPokemonId: _chosenPokemonId,
      givenSpeciesId: widget.speciesId,
    );
    final entry = outcome.entry;
    final evolutions = entry == null ? const <NextEvolution>[] : await nextEvolutions(_app.dex, entry, _gameVg);
    if (!mounted || run != _run) return;
    setState(() {
      _outcome = outcome;
      _evolutions = evolutions;
      _busy = false;
      _initTarget(entry);
      if (!_genderTouched) _gender = outcome.value<String>(F.gender) ?? _targetSpecimen?.gender;
    });
    if (entry != null && !_stamped) {
      // O carimbo cai depois que a leitura aparece.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _stamped = true);
      });
    }
  }

  void _initTarget(DexEntry? entry) {
    if (widget.existingId != null || entry == null || _targetSpecies == entry.speciesId) return;
    _targetSpecies = entry.speciesId;
    final mine = _app.specimensOf(entry.speciesId, scopedOnly: true);
    // Um único carimbo rápido (sem ficha) é quase sempre o que se quer completar.
    final bare = mine.where(_isBare).toList();
    _target = mine.length == 1 && bare.length == 1 ? bare.first.id : null;
  }

  static bool _isBare(Specimen s) =>
      s.nickname == null && s.level == null && s.nature == null && s.ivs == null && s.stats == null && s.moves == null;

  Specimen? get _targetSpecimen => _target == null ? null : _app.specimenById(_target!);

  bool get _shinyValue => _shiny ?? _targetSpecimen?.isShiny ?? (_outcome?.value<bool>(F.isShiny) ?? false);

  // ---------------------------------------------------------------------------
  // Rascunho

  SpecimenDraft _draft() {
    final o = _outcome!;
    final entry = o.entry!;
    final base = _targetSpecimen;
    final d = base != null
        ? SpecimenDraft.fromSpecimen(base)
        : SpecimenDraft(speciesId: entry.speciesId, pokemonId: entry.pokemonId, adventureId: _app.activeAdventure?.id);
    d
      ..speciesId = entry.speciesId
      ..pokemonId = entry.pokemonId
      ..isShiny = _shinyValue;
    final nick = o.value<String>(F.nickname);
    if (nick != null) d.nickname = nick;
    d.level = o.value<int>(F.level) ?? d.level;
    switch (o.genderRate) {
      case -1:
        d.gender = null;
      case 0:
        d.gender = 'm';
      case 8:
        d.gender = 'f';
      default:
        if (_gender != null || _genderTouched) d.gender = _gender;
    }
    d.nature = o.value<String>(F.nature) ?? d.nature;
    d.abilityId = o.value<int>(F.abilityId) ?? d.abilityId;
    d.heldItemId = o.value<int>(F.heldItemId) ?? d.heldItemId;
    d.ballItemId = o.value<int>(F.ballItemId) ?? d.ballItemId;
    d.teraType = o.value<String>(F.teraType) ?? d.teraType;
    d.caughtWhere = o.value<String>(F.caughtWhere) ?? d.caughtWhere;
    final moves = o.value<List<int>>(F.moves);
    if (moves != null && moves.isNotEmpty) {
      d.moves
        ..clear()
        ..addAll(moves);
    }
    final stats = o.stats;
    for (var i = 0; i < 6; i++) {
      if (stats[i] != null) d.stats[i] = stats[i];
      final r = o.ivRanges[i];
      if (r != null && r.$1 == r.$2) d.ivs[i] = r.$1;
    }
    return d;
  }

  /// Chaves de destaque da ficha (contrato de [SpecimenSheetScreen]).
  static const _sheetKeys = {
    F.pokemonId: 'form',
    F.nickname: 'nickname',
    F.level: 'level',
    F.gender: 'gender',
    F.isShiny: 'shiny',
    F.nature: 'nature',
    F.abilityId: 'ability',
    F.heldItemId: 'heldItem',
    F.ballItemId: 'ball',
    F.teraType: 'tera',
    F.caughtWhere: 'caughtWhere',
    F.moves: 'moves',
  };

  Set<String> _highlighted() {
    final o = _outcome!;
    return {
      for (final k in o.values.keys)
        if (k.startsWith('stat')) 'stats' else ?_sheetKeys[k],
      if (_genderTouched) 'gender',
      if (_shiny != null) 'shiny',
    };
  }

  Future<void> _save() async {
    final entry = _outcome?.entry;
    if (entry == null) return;
    final draft = _draft();
    final updating = _target != null;
    await _app.saveDraft(draft, existingId: _target);
    if (!mounted) return;
    Navigator.of(context).pop(ScanSaved(entry, updated: updating));
  }

  void _review() {
    if (_outcome?.entry == null) return;
    final draft = _draft();
    final highlighted = _highlighted();
    final existing = _target;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SpecimenSheetScreen(draft: draft, existingId: existing, highlighted: highlighted),
      ),
    );
  }

  Future<void> _addAnother() async {
    final paths = await pickSummaryPhotos(context, another: true);
    if (paths.isEmpty || !mounted) return;
    await _addPages(paths);
  }

  Future<void> _chooseSpecies() async {
    final e = await pickSpecies(context);
    if (e == null || !mounted) return;
    _chosenPokemonId = e.pokemonId;
    await _resolve();
  }

  void _useAlternative(DexEntry e) {
    _chosenPokemonId = e.pokemonId;
    _resolve();
  }

  void _pick(String key, Reading<Object> r) {
    _choices[key] = r;
    _merged.choose(key, r);
    _resolve();
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final o = _outcome;
    final Widget body;
    if (o == null) {
      body = _Working(progress: _progress);
    } else if (_merged.isEmpty && _chosenPokemonId == null) {
      body = _Failure(onRetry: _addAnother, onChoose: _chooseSpecies);
    } else {
      body = _result(context, o);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingId != null ? 'Atualizar por foto' : 'Carimbar por foto'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: SizedBox(
            height: 2,
            child: _busy && o != null ? const LinearProgressIndicator(minHeight: 2, color: Ramp.ink, backgroundColor: Ramp.n2) : null,
          ),
        ),
      ),
      body: body,
      bottomNavigationBar: o?.entry == null ? null : _bottomBar(context),
    );
  }

  Widget _bottomBar(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Ramp.paper),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.s, Space.gutter, Space.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Perforation(),
                const SizedBox(height: Space.m),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        onPressed: _busy ? null : _review,
                        child: const Text('Revisar ficha'),
                      ),
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        onPressed: _busy ? null : _save,
                        child: Text(_target == null ? 'Salvar' : 'Atualizar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _result(BuildContext context, ScanOutcome o) {
    final text = Theme.of(context).textTheme;
    final names = ScanNames.of(_app.dex);
    final entry = o.entry;
    final pages = _readPages;
    final conflicts = [
      for (final c in _merged.conflicts.entries)
        if (c.key != F.currentHp && c.key != F.dexNumber) c,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.l, Space.gutter, Space.xxl),
      children: [
        if (entry == null)
          _Unknown(onChoose: _chooseSpecies)
        else
          _Header(entry: entry, outcome: o, shiny: _shinyValue, stamped: _stamped, onChange: _chooseSpecies),
        if (o.alternatives.isNotEmpty) ...[
          const SizedBox(height: Space.m),
          Text('Também pode ser', style: text.labelMedium),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final a in o.alternatives)
                ActionChip(
                  avatar: PokemonSprite(a, size: 24),
                  label: Text(evolutionDisplayName(a)),
                  onPressed: () => _useAlternative(a),
                ),
            ],
          ),
        ],
        for (final w in o.warnings) ...[
          const SizedBox(height: Space.m),
          Text(w, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: Space.l),
        Row(
          children: [
            Expanded(
              child: Text(
                pages == 1 ? '1 página lida' : '$pages páginas lidas',
                style: text.labelMedium,
              ),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _addAnother,
              icon: const Icon(Icons.add_a_photo_outlined, size: 20),
              label: const Text('Adicionar outra página'),
            ),
          ],
        ),
        if (conflicts.isNotEmpty) ...[
          const _SectionTitle('Leituras diferentes'),
          Text('As fotos discordam. Toque na leitura certa.', style: text.bodyMedium),
          for (final c in conflicts) _ConflictRow(field: c.key, options: c.value, names: names, onPick: _pick),
        ],
        const _SectionTitle('Leitura'),
        ..._fields(context, o, names),
        if (entry != null && o.stats.any((s) => s != null)) ...[
          const _SectionTitle('Stats e IVs estimados'),
          _StatsBlock(outcome: o),
        ],
        if (entry != null && entry.evolutionChainId != null) ...[
          const _SectionTitle('Próxima evolução'),
          _EvolutionBlock(
            evolutions: _evolutions,
            level: o.value<int>(F.level),
            game: _app.dex.versionGroupsById[_gameVg]?.name,
          ),
        ],
        if (entry != null) ..._targetSection(context, entry, names),
      ],
    );
  }

  List<Widget> _fields(BuildContext context, ScanOutcome o, ScanNames names) {
    final text = Theme.of(context).textTheme;
    final entry = o.entry;
    final rows = <Widget>[];
    void row(String label, String key, String? value) {
      if (value == null) return;
      rows.add(_FieldRow(label: label, check: o.low.contains(key), child: Text(value, style: text.titleMedium)));
    }

    final level = o.value<int>(F.level);
    row('Nível', F.level, level == null ? null : '$level');
    rows.add(_genderRow(context, o));
    rows.add(_FieldRow(
      label: 'Shiny',
      check: _shiny == null && _targetSpecimen == null,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Switch(
          value: _shinyValue,
          activeTrackColor: Gold.ink,
          onChanged: (v) => setState(() => _shiny = v),
        ),
      ),
    ));
    final nature = o.value<String>(F.nature);
    row('Natureza', F.nature, nature == null ? null : names.nature(nature));
    final ability = o.value<int>(F.abilityId);
    row('Habilidade', F.abilityId, ability == null ? null : names.ability(ability));
    final item = o.value<int>(F.heldItemId);
    row('Item', F.heldItemId, item == null ? null : names.item(item));
    final tera = o.value<String>(F.teraType);
    if (tera != null) {
      rows.add(_FieldRow(
        label: 'Tipo Tera',
        check: o.low.contains(F.teraType),
        child: Align(alignment: Alignment.centerLeft, child: TypePill(tera, dense: true)),
      ));
    }
    final ball = o.value<int>(F.ballItemId);
    row('Pokébola', F.ballItemId, ball == null ? null : names.item(ball));
    row('Local', F.caughtWhere, o.value<String>(F.caughtWhere));
    final moves = o.value<List<int>>(F.moves);
    if (moves != null && moves.isNotEmpty) {
      rows.add(_FieldRow(
        label: 'Golpes',
        check: o.low.contains(F.moves),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final m in moves) Text(names.move(m), style: text.titleMedium)],
        ),
      ));
    }
    if (entry == null && rows.length <= 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: Space.s),
        child: Text('Pouca coisa lida. Escolha a espécie e complete na ficha.', style: text.bodyMedium),
      ));
    }
    return [
      for (var i = 0; i < rows.length; i++) ...[if (i > 0) const Perforation(), rows[i]],
    ];
  }

  Widget _genderRow(BuildContext context, ScanOutcome o) {
    final text = Theme.of(context).textTheme;
    final rate = o.genderRate;
    if (rate == -1 || rate == 0 || rate == 8) {
      return _FieldRow(
        label: 'Gênero',
        child: Text(rate == -1 ? 'Sem gênero' : ScanNames.gender(rate == 0 ? 'm' : 'f'), style: text.titleMedium),
      );
    }
    return _FieldRow(
      label: 'Gênero',
      check: !_genderTouched && (o.low.contains(F.gender) || _gender == null),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: 'm', icon: Icon(Icons.male_rounded, size: 18), label: Text('Macho')),
            ButtonSegment(value: 'f', icon: Icon(Icons.female_rounded, size: 18), label: Text('Fêmea')),
          ],
          selected: {?_gender},
          onSelectionChanged: (s) => setState(() {
            _genderTouched = true;
            _gender = s.firstOrNull;
          }),
        ),
      ),
    );
  }

  List<Widget> _targetSection(BuildContext context, DexEntry entry, ScanNames names) {
    final mine = _app.specimensOf(entry.speciesId, scopedOnly: true);
    final target = _targetSpecimen;
    final list = [
      ...mine,
      if (target != null && !mine.any((s) => s.id == target.id)) target,
    ];
    if (list.isEmpty) return const [];
    final text = Theme.of(context).textTheme;
    final date = DateFormat.yMMMd('pt_BR');
    String label(Specimen s) {
      final name = s.nickname ?? evolutionDisplayName(_app.dex.byPokemonId[s.pokemonId] ?? entry);
      return [name, if (s.level != null) 'Nv. ${s.level}', if (s.isShiny) 'shiny'].join(' · ');
    }

    final diff = target == null ? const <(String, String, String)>[] : names.diff(SpecimenDraft.fromSpecimen(target), _draft());
    return [
      const _SectionTitle('Onde gravar'),
      RadioGroup<String>(
        groupValue: _target ?? '',
        onChanged: (v) => setState(() => _target = (v == null || v.isEmpty) ? null : v),
        child: Column(
          children: [
            for (final s in list) ...[
              RadioListTile<String>(
                value: s.id,
                contentPadding: EdgeInsets.zero,
                title: Text('Atualizar ${label(s)}', style: text.titleMedium),
                subtitle: Text('Carimbado em ${date.format(s.caughtAt)}', style: text.bodySmall),
              ),
              if (s.id == _target) _DiffList(diff: diff),
            ],
            RadioListTile<String>(
              value: '',
              contentPadding: EdgeInsets.zero,
              title: Text('Criar novo exemplar', style: text.titleMedium),
            ),
          ],
        ),
      ),
    ];
  }
}

// -----------------------------------------------------------------------------
// Partes

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.s),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
}

/// Marca de campo para conferir.
class _Check extends StatelessWidget {
  const _Check();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Conferir este campo',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 2),
          decoration: BoxDecoration(color: Ramp.n2, borderRadius: BorderRadius.circular(Radii.pill)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_outlined, size: 14, color: Ramp.ink),
              const SizedBox(width: Space.xs),
              ExcludeSemantics(
                child: Text('conferir', style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          ),
        ),
      );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child, this.check = false});
  final String label;
  final Widget child;
  final bool check;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.s),
          child: Row(
            children: [
              SizedBox(width: 104, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
              Expanded(child: child),
              if (check) ...[const SizedBox(width: Space.s), const _Check()],
            ],
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.entry, required this.outcome, required this.shiny, required this.stamped, required this.onChange});
  final DexEntry entry;
  final ScanOutcome outcome;
  final bool shiny;
  final bool stamped;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final nick = outcome.value<String>(F.nickname);
    final level = outcome.value<int>(F.level);
    final note = switch (outcome.source) {
      SpeciesSource.inferred => 'Deduzida pela habilidade e pelos stats.',
      SpeciesSource.read when outcome.speciesConfidence == Confidence.low =>
        outcome.alternatives.isEmpty ? 'Nome lido com falhas.' : 'Forma não deu para distinguir pela foto.',
      SpeciesSource.given when outcome.speciesConfidence == Confidence.low => 'Forma não deu para distinguir pela foto.',
      _ => null,
    };
    final name = evolutionDisplayName(entry);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StampSlot(
              seed: entry.speciesId,
              ink: TypeInks.of(entry.type1).ink,
              state: !stamped ? StampState.empty : (shiny ? StampState.shiny : StampState.stamped),
              size: 96,
              semanticLabel: shiny ? '$name shiny' : name,
              child: PokemonSprite(entry, shiny: shiny),
            ),
            const SizedBox(width: Space.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: text.headlineMedium),
                  if (nick != null) ...[
                    const SizedBox(height: Space.xs),
                    Text('Apelido “$nick”', style: text.bodyLarge),
                  ],
                  const SizedBox(height: Space.xs),
                  Text(
                    [Labels.dexNumber(entry.speciesId), if (level != null) 'Nv. $level'].join(' · '),
                    style: text.labelMedium,
                  ),
                  const SizedBox(height: Space.s),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [for (final t in entry.types) TypePill(t, dense: true)],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s),
        Row(
          children: [
            if (note != null) ...[
              Flexible(child: Text(note, style: text.bodyMedium)),
              const SizedBox(width: Space.s),
              const _Check(),
            ],
            const Spacer(),
            TextButton(onPressed: onChange, child: const Text('Trocar espécie')),
          ],
        ),
      ],
    );
  }
}

class _Unknown extends StatelessWidget {
  const _Unknown({required this.onChoose});
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        const StampSlot(seed: 0, ink: Ramp.n4, state: StampState.empty, size: 96, child: Icon(Icons.question_mark_rounded, color: Ramp.n4)),
        const SizedBox(width: Space.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Espécie não reconhecida', style: text.titleLarge),
              const SizedBox(height: Space.xs),
              Text('O nome pode ser um apelido. Escolha a espécie para gravar.', style: text.bodyMedium),
              const SizedBox(height: Space.s),
              FilledButton(onPressed: onChoose, child: const Text('Escolher espécie')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConflictRow extends StatelessWidget {
  const _ConflictRow({required this.field, required this.options, required this.names, required this.onPick});
  final String field;
  final List<Reading<Object>> options;
  final ScanNames names;
  final void Function(String, Reading<Object>) onPick;

  String get _label => switch (field) {
        F.level => 'Nível',
        F.gender => 'Gênero',
        F.nature => 'Natureza',
        F.abilityId => 'Habilidade',
        F.heldItemId => 'Item',
        F.ballItemId => 'Pokébola',
        F.teraType => 'Tipo Tera',
        F.caughtWhere => 'Local',
        F.moves => 'Golpes',
        F.nickname || F.name => 'Nome',
        F.isShiny => 'Shiny',
        '_species' => 'Espécie',
        _ when field.startsWith('stat') => Labels.stats[int.tryParse(field.substring(4)) ?? 0],
        _ => field,
      };

  String _show(Object v) => switch (field) {
        F.gender => ScanNames.gender(v as String),
        F.nature => names.nature(v as String),
        F.abilityId => names.ability(v as int),
        F.heldItemId || F.ballItemId => names.item(v as int),
        F.teraType => names.type(v as String),
        F.moves => (v as List<int>).map(names.move).join(', '),
        F.isShiny => v == true ? 'Sim' : 'Não',
        '_species' => names.dex.defaultBySpecies[v]?.speciesName ?? '$v',
        _ => '$v',
      };

  @override
  Widget build(BuildContext context) => _FieldRow(
        label: _label,
        child: Wrap(
          spacing: Space.s,
          runSpacing: Space.s,
          children: [
            for (final r in options)
              ActionChip(
                label: Text('${_show(r.value)} · foto ${r.page + 1}'),
                onPressed: () => onPick(field, r),
              ),
          ],
        ),
      );
}

class _StatsBlock extends StatelessWidget {
  const _StatsBlock({required this.outcome});
  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final o = outcome;
    final stats = o.stats;
    final level = o.value<int>(F.level);
    final current = o.value<int>(F.currentHp);
    final notes = <String>[
      if (level == null) 'Sem o nível, não dá para estimar IVs.',
      if (level != null && !o.natureKnown) 'Sem a natureza, os stats afetados por ela ficam com faixa larga. A página Informações afina.',
      if (level != null) 'IVs supõem nenhum EV treinado.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: Row(
            children: [
              const SizedBox(width: 104),
              Expanded(child: Text('Valor', style: text.labelMedium)),
              SizedBox(width: 72, child: Text('IV', style: text.labelMedium, textAlign: TextAlign.end)),
            ],
          ),
        ),
        for (var i = 0; i < 6; i++)
          if (stats[i] != null) ...[
            const Perforation(),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s),
                child: Row(
                  children: [
                    SizedBox(width: 104, child: Text(Labels.stats[i], style: text.bodyMedium)),
                    Expanded(
                      child: Row(
                        children: [
                          Text('${stats[i]}', style: text.titleMedium),
                          if (i == 0 && current != null && current != stats[0]) ...[
                            const SizedBox(width: Space.s),
                            Text('agora $current', style: text.labelMedium),
                          ],
                          if (o.low.contains(F.stat(i))) ...[const SizedBox(width: Space.s), const _Check()],
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        level == null ? '—' : StatsCalc.label(o.ivRanges[i]),
                        style: text.titleMedium,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.only(top: Space.s),
            child: Text(n, style: text.bodySmall),
          ),
      ],
    );
  }
}

class _EvolutionBlock extends StatelessWidget {
  const _EvolutionBlock({required this.evolutions, required this.level, required this.game});
  final List<NextEvolution> evolutions;
  final int? level;
  final String? game;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (evolutions.isEmpty) {
      return Text(game == null ? 'Último estágio da linha.' : 'Último estágio da linha em $game.', style: text.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (game != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s),
            child: Text('Regras de $game', style: text.labelMedium),
          ),
        for (var i = 0; i < evolutions.length; i++) ...[
          if (i > 0) const Perforation(indent: 56),
          _EvolutionRow(evolution: evolutions[i], level: level),
        ],
      ],
    );
  }
}

class _EvolutionRow extends StatelessWidget {
  const _EvolutionRow({required this.evolution, required this.level});
  final NextEvolution evolution;
  final int? level;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final e = evolution;
    final ink = TypeInks.of(e.target.type1);
    final ready = e.minLevel != null && level != null && level! >= e.minLevel!;
    final missing = e.minLevel != null && level != null && !ready ? e.minLevel! - level! : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(dimension: 48, child: PokemonSprite(e.target, size: 48)),
          const SizedBox(width: Space.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: evolutionDisplayName(e.target), style: text.titleMedium),
                      TextSpan(text: ' — ${e.block.chip.chipLabel}', style: text.bodyLarge),
                    ],
                  ),
                ),
                for (final r in e.block.lines)
                  Text(r.text, style: text.bodySmall),
                if (e.block.isFallback) Text('Regra geral (o jogo não tem regra registrada).', style: text.bodySmall),
                if (ready)
                  Text('Já pode evoluir', style: text.titleSmall?.copyWith(color: ink.text))
                else if (missing != null)
                  Text(missing == 1 ? 'Falta 1 nível' : 'Faltam $missing níveis', style: text.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffList extends StatelessWidget {
  const _DiffList({required this.diff});
  final List<(String, String, String)> diff;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (diff.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: Space.xxxl, bottom: Space.s),
        child: Text('Nada muda nos campos lidos.', style: text.bodySmall),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: Space.xxxl, bottom: Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, before, after) in diff)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 88, child: Text(label, style: text.bodySmall)),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: before, style: text.bodySmall),
                          TextSpan(text: '  →  ', style: text.bodySmall),
                          TextSpan(text: after, style: text.titleSmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.progress});
  final String progress;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StampSlot(
                seed: 7,
                ink: Ramp.n4,
                state: StampState.empty,
                size: 96,
                child: Icon(Icons.document_scanner_outlined, color: Ramp.n4, size: 32),
              ),
              const SizedBox(height: Space.l),
              Text(progress.isEmpty ? 'Lendo a foto…' : progress, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: Space.m),
              const SizedBox(
                width: 160,
                child: LinearProgressIndicator(minHeight: 2, color: Ramp.ink, backgroundColor: Ramp.n2),
              ),
            ],
          ),
        ),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry, required this.onChoose});
  final VoidCallback onRetry;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_search_rounded, size: 36, color: Ramp.n4),
            const SizedBox(height: Space.m),
            Text('Não consegui ler esta foto', style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Space.s),
            Text(
              'Enquadre só a tela do Switch, sem reflexo, e use a página Golpes e Estatísticas do resumo.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                  label: const Text('Tentar outra foto'),
                ),
                OutlinedButton(onPressed: onChoose, child: const Text('Escolher a espécie')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
