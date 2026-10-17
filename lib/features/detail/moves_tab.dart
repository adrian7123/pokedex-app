import 'package:flutter/material.dart';

import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/type_badge.dart';
import 'detail_common.dart';

/// Métodos mostrados, na ordem dos segmentos. Variantes raras entram no método mais próximo.
const _methods = <(String, Set<String>)>[
  ('level-up', {'level-up'}),
  ('machine', {'machine'}),
  ('egg', {'egg', 'light-ball-egg'}),
  ('tutor', {'tutor'}),
];

/// Aba "Golpes" do jogo selecionado.
class MovesTab extends StatefulWidget {
  const MovesTab({super.key, required this.game, required this.learnset});
  final VersionGroup game;
  final Future<(List<LearnedMove>, VersionGroup?)> learnset;

  @override
  State<MovesTab> createState() => _MovesTabState();
}

class _MovesTabState extends State<MovesTab> {
  String? _method;
  final Set<int> _open = {};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<LearnedMove>, VersionGroup?)>(
      future: widget.learnset,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: Space.xxxl),
              child: Center(
                child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Ramp.n4)),
              ),
            ),
          );
        }
        final (moves, origin) = snap.data ?? (const <LearnedMove>[], null);
        if (moves.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyNote(icon: Icons.bolt_outlined, title: 'A PokeAPI não tem golpes deste Pokémon.'),
          );
        }
        final present = [
          for (final m in _methods)
            if (moves.any((mv) => m.$2.contains(mv.method))) m,
        ];
        if (present.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyNote(icon: Icons.bolt_outlined, title: 'Só há golpes por métodos especiais neste jogo.'),
          );
        }
        final method = present.firstWhere((m) => m.$1 == _method, orElse: () => present.first);
        final shown = [for (final mv in moves) if (method.$2.contains(mv.method)) mv];
        final showColumn = method.$1 == 'level-up' || method.$1 == 'machine';
        final text = Theme.of(context).textTheme;

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
              sliver: SliverList.list(
                children: [
                  if (origin != null && origin.id != widget.game.id) ...[
                    InfoNote('Golpes de ${origin.name} — ${widget.game.name} ainda sem dados'),
                    const SizedBox(height: Space.l),
                  ],
                  if (present.length > 1)
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        for (final m in present) ButtonSegment(value: m.$1, label: Text(Labels.moveMethod[m.$1] ?? m.$1)),
                      ],
                      selected: {method.$1},
                      onSelectionChanged: (s) => setState(() {
                        _method = s.first;
                        _open.clear();
                      }),
                    )
                  else
                    Text(Labels.moveMethod[method.$1] ?? method.$1, style: text.titleMedium),
                  const SizedBox(height: Space.l),
                  _HeaderRow(showColumn: showColumn, columnLabel: method.$1 == 'machine' ? 'Máq.' : 'Nv.'),
                  const SizedBox(height: Space.xs),
                ],
              ),
            ),
            SliverList.separated(
              itemCount: shown.length,
              separatorBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Perforation(),
              ),
              itemBuilder: (context, i) {
                final mv = shown[i];
                final key = mv.moveId * 1000 + mv.level;
                return _MoveRow(
                  move: mv,
                  showColumn: showColumn,
                  open: _open.contains(key),
                  onTap: () => setState(() => _open.contains(key) ? _open.remove(key) : _open.add(key)),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

const _numWidth = 40.0;
const _colWidth = 52.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.showColumn, required this.columnLabel});
  final bool showColumn;
  final String columnLabel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget num(String s) => SizedBox(width: _numWidth, child: Text(s, style: style, textAlign: TextAlign.right));
    return ExcludeSemantics(
      child: Row(
        children: [
          if (showColumn) SizedBox(width: _colWidth, child: Text(columnLabel, style: style)),
          Expanded(child: Text('Golpe', style: style)),
          num('Poder'),
          num('Prec.'),
          num('PP'),
        ],
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.move, required this.showColumn, required this.open, required this.onTap});
  final LearnedMove move;
  final bool showColumn;
  final bool open;
  final VoidCallback onTap;

  static const _classIcons = {
    'physical': Icons.sports_mma_outlined,
    'special': Icons.flare_rounded,
    'status': Icons.adjust_rounded,
  };

  String get _column {
    if (move.method == 'machine') return move.machine ?? '—';
    if (move.level == 0) return 'Evo.';
    return '${move.level}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final dc = move.damageClass;
    Widget num(int? v) => SizedBox(
          width: _numWidth,
          child: Text(v?.toString() ?? '—', style: text.bodyLarge, textAlign: TextAlign.right),
        );
    return Semantics(
      button: true,
      expanded: open,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showColumn)
                    SizedBox(width: _colWidth, child: Text(_column, style: text.titleSmall?.copyWith(color: Ramp.n6))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(move.name, style: text.titleMedium),
                        const SizedBox(height: Space.xs),
                        Wrap(
                          spacing: Space.s,
                          runSpacing: Space.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (move.type != null) TypePill(move.type!, dense: true),
                            if (dc != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_classIcons[dc] ?? Icons.adjust_rounded, size: 16, color: Ramp.n6),
                                  const SizedBox(width: Space.xs),
                                  Text(Labels.damageClass[dc] ?? dc, style: text.bodySmall),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  num(move.power),
                  num(move.accuracy),
                  num(move.pp),
                ],
              ),
              AnimatedSize(
                duration: reduce ? Duration.zero : Motion.medium,
                curve: Motion.emphasized,
                alignment: Alignment.topLeft,
                child: open
                    ? Padding(
                        padding: EdgeInsets.only(top: Space.s, left: showColumn ? _colWidth : 0),
                        child: Text(move.shortEffect ?? 'A PokeAPI não tem descrição deste golpe.', style: text.bodyMedium),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
