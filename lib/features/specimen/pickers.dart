import 'package:flutter/material.dart';

import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/type_badge.dart';
import '../detail/detail_common.dart';

/// Resultado de uma folha de escolha: null = fechou sem escolher; `(value: null)` = "nenhum".
typedef Picked<T> = ({T? value});

/// Folha com lista (e busca opcional) para escolher um valor.
Future<Picked<T>?> showListPicker<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) label,
  T? selected,
  Widget Function(T)? leading,
  Widget Function(T)? detail,
  String? noneLabel,
  String? searchHint,
}) =>
    showModalBottomSheet<Picked<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ListPicker<T>(
        title: title,
        options: options,
        label: label,
        selected: selected,
        leading: leading,
        detail: detail,
        noneLabel: noneLabel,
        searchHint: searchHint,
      ),
    );

class _ListPicker<T> extends StatefulWidget {
  const _ListPicker({
    required this.title,
    required this.options,
    required this.label,
    required this.selected,
    required this.leading,
    required this.detail,
    required this.noneLabel,
    required this.searchHint,
  });

  final String title;
  final List<T> options;
  final String Function(T) label;
  final T? selected;
  final Widget Function(T)? leading;
  final Widget Function(T)? detail;
  final String? noneLabel;
  final String? searchHint;

  @override
  State<_ListPicker<T>> createState() => _ListPickerState<T>();
}

class _ListPickerState<T> extends State<_ListPicker<T>> {
  String _query = '';
  late final List<String> _norm = [for (final o in widget.options) DexEntry.normalize(widget.label(o))];

  List<T> get _visible {
    final q = DexEntry.normalize(_query.trim());
    if (q.isEmpty) return widget.options;
    final starts = <T>[];
    final contains = <T>[];
    for (var i = 0; i < _norm.length; i++) {
      if (_norm[i].startsWith(q)) {
        starts.add(widget.options[i]);
      } else if (_norm[i].contains(q)) {
        contains.add(widget.options[i]);
      }
    }
    return [...starts, ...contains];
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final visible = _visible;
    final none = widget.noneLabel != null && _query.trim().isEmpty;
    final searchable = widget.searchHint != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: searchable ? .9 : .6,
        minChildSize: .4,
        maxChildSize: 1,
        builder: (context, scroll) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.m),
              child: Text(widget.title, style: text.titleLarge),
            ),
            if (searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.s),
                child: TextField(
                  autofocus: widget.options.length > 40,
                  textInputAction: TextInputAction.search,
                  onChanged: (s) => setState(() => _query = s),
                  onSubmitted: (_) {
                    if (visible.isNotEmpty) Navigator.pop(context, (value: visible.first));
                  },
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded, color: Ramp.n6),
                  ),
                ),
              ),
            Expanded(
              child: visible.isEmpty && !none
                  ? ListView(
                      controller: scroll,
                      children: [EmptyNote(icon: Icons.search_off_rounded, title: 'Nada com “${_query.trim()}”.')],
                    )
                  : ListView.builder(
                      controller: scroll,
                      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.l),
                      itemCount: visible.length + (none ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (none && i == 0) {
                          return PickerRow(
                            label: widget.noneLabel!,
                            selected: widget.selected == null,
                            muted: true,
                            onTap: () => Navigator.pop(context, (value: null)),
                          );
                        }
                        final o = visible[i - (none ? 1 : 0)];
                        return PickerRow(
                          label: widget.label(o),
                          selected: o == widget.selected,
                          leading: widget.leading?.call(o),
                          detail: widget.detail?.call(o),
                          onTap: () => Navigator.pop(context, (value: o)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de uma folha de escolha: 56dp, sem caixa; a escolhida em peso forte com marca.
class PickerRow extends StatelessWidget {
  const PickerRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.detail,
    this.subtitle,
    this.muted = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? detail;
  final String? subtitle;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = selected ? text.titleMedium : (muted ? text.bodyMedium : text.bodyLarge);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.s),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: Space.m)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: style),
                      if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                if (detail != null) ...[const SizedBox(width: Space.s), detail!],
                SizedBox(
                  width: 32,
                  child: selected ? const Icon(Icons.check_rounded, color: Ramp.ink) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Os 18 tipos na ordem da cartela de tipos.
List<String> get teraTypes => TypeInks.byIdentifier.keys.toList();

/// Folha do tipo Tera: os 18 tipos como pílulas que quebram linha.
Future<Picked<String>?> showTeraPicker(BuildContext context, {String? selected}) =>
    showModalBottomSheet<Picked<String>>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Tipo Tera', style: text.titleLarge)),
                    TextButton(
                      onPressed: () => Navigator.pop(context, (value: null)),
                      child: const Text('Sem tipo Tera'),
                    ),
                  ],
                ),
                const SizedBox(height: Space.s),
                Wrap(
                  spacing: Space.xs,
                  children: [
                    for (final t in teraTypes)
                      Semantics(
                        selected: t == selected,
                        button: true,
                        child: InkWell(
                          onTap: () => Navigator.pop(context, (value: t)),
                          borderRadius: BorderRadius.circular(Radii.pill),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Radii.pill),
                                border: Border.all(
                                  color: t == selected ? TypeInks.of(t).ink : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Padding(padding: const EdgeInsets.all(1), child: TypePill(t)),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

/// Rótulo curto de como o golpe é aprendido: "Nv. 12", "TM24", "Ovo".
String learnLabel(LearnedMove m) {
  if (m.method == 'level-up') return m.level == 0 ? 'Ao evoluir' : 'Nv. ${m.level}';
  if (m.method == 'machine') return m.machine ?? Labels.moveMethod['machine']!;
  return Labels.moveMethod[m.method] ?? m.method;
}

/// Folha de golpes: primeiro os que a variedade aprende no jogo; "Todos os golpes" para o resto.
Future<int?> showMovePicker(
  BuildContext context, {
  required Future<(List<LearnedMove>, VersionGroup?)> learnset,
  required VersionGroup game,
  required Set<int> exclude,
}) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MovePicker(learnset: learnset, game: game, exclude: exclude),
    );

class _MovePicker extends StatefulWidget {
  const _MovePicker({required this.learnset, required this.game, required this.exclude});
  final Future<(List<LearnedMove>, VersionGroup?)> learnset;
  final VersionGroup game;
  final Set<int> exclude;

  @override
  State<_MovePicker> createState() => _MovePickerState();
}

class _MovePickerState extends State<_MovePicker> {
  String _query = '';
  bool _all = false;
  List<String>? _allNorm;

  bool _matches(String norm, String q) => q.isEmpty || norm.contains(q);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dex = AppScope.read(context).dex;
    final q = DexEntry.normalize(_query.trim());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .9,
        minChildSize: .4,
        maxChildSize: 1,
        builder: (context, scroll) => FutureBuilder<(List<LearnedMove>, VersionGroup?)>(
          future: widget.learnset,
          builder: (context, snap) {
            final learned = <int, LearnedMove>{};
            for (final m in snap.data?.$1 ?? const <LearnedMove>[]) {
              learned.putIfAbsent(m.moveId, () => m);
            }
            final source = snap.data?.$2;
            final loading = snap.connectionState != ConnectionState.done;
            final showAll = _all || (!loading && learned.isEmpty);

            final rows = <Widget>[];
            if (showAll) {
              _allNorm ??= [for (final m in dex.moves) DexEntry.normalize(m.name)];
              for (var i = 0; i < dex.moves.length; i++) {
                final m = dex.moves[i];
                if (widget.exclude.contains(m.id) || !_matches(_allNorm![i], q)) continue;
                final l = learned[m.id];
                rows.add(
                  PickerRow(
                    label: m.name,
                    selected: false,
                    subtitle: l == null ? null : learnLabel(l),
                    detail: l?.type == null ? null : TypePill(l!.type!, dense: true),
                    onTap: () => Navigator.pop(context, m.id),
                  ),
                );
              }
            } else {
              for (final m in learned.values) {
                if (widget.exclude.contains(m.moveId) || !_matches(DexEntry.normalize(m.name), q)) continue;
                rows.add(
                  PickerRow(
                    label: m.name,
                    selected: false,
                    subtitle: learnLabel(m),
                    detail: m.type == null ? null : TypePill(m.type!, dense: true),
                    onTap: () => Navigator.pop(context, m.moveId),
                  ),
                );
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.m),
                  child: Text('Adicionar golpe', style: text.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.s),
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Aprende no jogo')),
                      ButtonSegment(value: true, label: Text('Outro golpe')),
                    ],
                    selected: {showAll},
                    onSelectionChanged: (s) => setState(() => _all = s.first),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.s),
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    onChanged: (s) => setState(() => _query = s),
                    decoration: InputDecoration(
                      hintText: showAll ? 'Buscar em todos os golpes' : 'Buscar golpe',
                      prefixIcon: const Icon(Icons.search_rounded, color: Ramp.n6),
                    ),
                  ),
                ),
                if (!loading && learned.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.s),
                    child: InfoNote('Sem lista de golpes desta forma no jogo. Mostrando todos os golpes.'),
                  )
                else if (!showAll && source != null && source.id != widget.game.id)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.s),
                    child: InfoNote('Dados de ${source.name}: a PokeAPI não tem os golpes de ${widget.game.name}.'),
                  ),
                Expanded(
                  child: loading && !showAll
                      ? const Center(
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Ramp.n4),
                          ),
                        )
                      : rows.isEmpty
                          ? ListView(
                              controller: scroll,
                              children: [
                                EmptyNote(
                                  icon: Icons.search_off_rounded,
                                  title: q.isEmpty ? 'Nenhum golpe para mostrar.' : 'Nada com “${_query.trim()}”.',
                                  hint: showAll ? null : 'Toque em “Outro golpe” para buscar em todos.',
                                ),
                              ],
                            )
                          : ListView(
                              controller: scroll,
                              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.l),
                              children: rows,
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
