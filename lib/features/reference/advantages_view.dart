import 'package:flutter/material.dart';

import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/type_badge.dart';
import 'type_disc.dart';

const double _typeColumn = 104;

/// Uma linha por tipo: contra quem ele bate forte e quem bate forte nele.
/// Toque expande os demais multiplicadores (atacando à esquerda, defendendo à direita).
class AdvantagesSliver extends StatefulWidget {
  const AdvantagesSliver({super.key, required this.types});
  final List<String> types;

  @override
  State<AdvantagesSliver> createState() => _AdvantagesSliverState();
}

class _AdvantagesSliverState extends State<AdvantagesSliver> {
  final _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final eff = AppScope.of(context).dex.efficacy;
    final types = widget.types;

    List<String> attacking(String t, int factor) => [
      for (final d in types)
        if ((eff[t]?[d] ?? 100) == factor) d,
    ];
    List<String> defending(String t, int factor) => [
      for (final a in types)
        if ((eff[a]?[t] ?? 100) == factor) a,
    ];

    return SliverList.builder(
      itemCount: types.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return const _Header();
        final t = types[i - 1];
        final open = _open.contains(t);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypeRow(
              type: t,
              open: open,
              strong: attacking(t, 200),
              weak: defending(t, 200),
              noEffect: attacking(t, 0),
              notVery: attacking(t, 50),
              resists: defending(t, 50),
              immune: defending(t, 0),
              onTap: () => setState(() => open ? _open.remove(t) : _open.add(t)),
            ),
            if (i < types.length) const Perforation(indent: Space.gutter),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.s),
      child: Row(
        children: [
          SizedBox(
            width: _typeColumn,
            child: Text('Tipo', style: style),
          ),
          const SizedBox(width: Space.m),
          Expanded(child: Text('Forte contra', style: style)),
          const SizedBox(width: Space.m),
          Expanded(child: Text('Fraco contra', style: style)),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.open,
    required this.strong,
    required this.weak,
    required this.noEffect,
    required this.notVery,
    required this.resists,
    required this.immune,
    required this.onTap,
  });

  final String type;
  final bool open;
  final List<String> strong;
  final List<String> weak;
  final List<String> noEffect;
  final List<String> notVery;
  final List<String> resists;
  final List<String> immune;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final ink = TypeInks.of(type);
    final name = AppScope.read(context).dex.types[type]?.namePt ?? type;

    return Semantics(
      expanded: open,
      button: true,
      hint: open ? 'Recolher detalhes' : 'Ver todos os multiplicadores',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.m, Space.gutter, Space.m),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _typeColumn,
                    height: 28,
                    child: Row(
                      children: [
                        TypeIcon(type, size: 20),
                        const SizedBox(width: Space.s - 2),
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(color: ink.text),
                          ),
                        ),
                        AnimatedRotation(
                          turns: open ? .5 : 0,
                          duration: reduce ? Duration.zero : Motion.short,
                          curve: Motion.standard,
                          child: const Icon(Icons.expand_more_rounded, size: 18, color: Ramp.n5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(child: TypeDiscWrap(strong)),
                  const SizedBox(width: Space.m),
                  Expanded(child: TypeDiscWrap(weak)),
                ],
              ),
              AnimatedSize(
                duration: reduce ? Duration.zero : Motion.medium,
                curve: Motion.emphasized,
                alignment: Alignment.topCenter,
                child: !open
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: Space.l),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: _typeColumn + Space.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Group(label: 'Não afeta', types: noEffect),
                                  const SizedBox(height: Space.m),
                                  _Group(label: 'Pouco efetivo', types: notVery),
                                ],
                              ),
                            ),
                            const SizedBox(width: Space.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Group(label: 'Resiste a', types: resists),
                                  const SizedBox(height: Space.m),
                                  _Group(label: 'Imune a', types: immune),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.types});
  final String label;
  final List<String> types;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: Space.xs),
      TypeDiscWrap(types),
    ],
  );
}
