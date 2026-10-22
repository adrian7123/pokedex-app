import 'package:flutter/material.dart';

import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/type_badge.dart';

/// Um bloco por tipo: em quem os golpes dele batem forte e de quem ele apanha forte.
/// Toque abre o resto (golpes fracos, sem efeito, resistências, imunidades).
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
      itemCount: types.length,
      itemBuilder: (context, i) {
        final t = types[i];
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
            if (i < types.length - 1) const Perforation(indent: Space.gutter),
          ],
        );
      },
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
      hint: open ? 'Recolher detalhes' : 'Ver golpes fracos, resistências e imunidades',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.m, Space.gutter, Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    TypeIcon(type, size: 22),
                    const SizedBox(width: Space.s),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(color: ink.text),
                      ),
                    ),
                    Text(open ? 'menos' : 'mais', style: text.labelMedium),
                    AnimatedRotation(
                      turns: open ? .5 : 0,
                      duration: reduce ? Duration.zero : Motion.short,
                      curve: Motion.standard,
                      child: const Icon(Icons.expand_more_rounded, size: 20, color: Ramp.n5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.s),
              _Group(label: 'Golpes tipo $name são fortes contra', factor: '2×', types: strong),
              const SizedBox(height: Space.m),
              _Group(label: 'Pokémon tipo $name leva dano dobrado de', factor: '2×', types: weak),
              AnimatedSize(
                duration: reduce ? Duration.zero : Motion.medium,
                curve: Motion.emphasized,
                alignment: Alignment.topCenter,
                child: !open
                    ? const SizedBox(width: double.infinity)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Space.m),
                          _Group(label: 'Golpes tipo $name são fracos contra', factor: '½×', types: notVery),
                          const SizedBox(height: Space.m),
                          _Group(label: 'Golpes tipo $name não afetam', factor: '0×', types: noEffect),
                          const SizedBox(height: Space.m),
                          _Group(label: 'Pokémon tipo $name resiste a', factor: '½×', types: resists),
                          const SizedBox(height: Space.m),
                          _Group(label: 'Pokémon tipo $name é imune a', factor: '0×', types: immune),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rótulo em frase + multiplicador, e os tipos com nome (nunca só o ícone).
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.factor, required this.types});
  final String label;
  final String factor;
  final List<String> types;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [TextSpan(text: '  $factor', style: text.labelMedium)],
          ),
          style: text.titleSmall,
        ),
        const SizedBox(height: Space.xs + 2),
        if (types.isEmpty)
          Text('nenhum tipo', style: text.bodySmall)
        else
          Wrap(
            spacing: Space.xs + 2,
            runSpacing: Space.xs + 2,
            children: [for (final t in types) TypePill(t, dense: true)],
          ),
      ],
    );
  }
}
