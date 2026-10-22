import 'package:flutter/material.dart';

import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import 'advantages_view.dart';
import 'calculator_view.dart';
import 'matrix_view.dart';

enum _Mode {
  calculator('Fraquezas', 'Vai enfrentar ou usar um Pokémon? Veja quais tipos de golpe causam mais dano nele e quais quase não fazem efeito.'),
  advantages('Por tipo', 'Para cada tipo: contra quem os golpes dele são fortes e de quem ele leva dano dobrado. Toque num tipo para ver o resto.'),
  matrix('Tabela', 'Todos os tipos de uma vez. Cada linha é o tipo do golpe; cada coluna, o tipo de quem leva o golpe.');

  const _Mode(this.label, this.intro);
  final String label;
  final String intro;
}

/// Tipos: quem bate forte em quem, em três leituras (fraquezas de um Pokémon, por tipo, tabela completa).
class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  _Mode _mode = _Mode.calculator;

  @override
  void initState() {
    super.initState();
    final saved = PageStorage.maybeOf(context)?.readState(context, identifier: 'reference-mode');
    if (saved is int && saved >= 0 && saved < _Mode.values.length) _mode = _Mode.values[saved];
  }

  void _select(_Mode m) {
    setState(() => _mode = m);
    PageStorage.maybeOf(context)?.writeState(context, m.index, identifier: 'reference-mode');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dex = AppScope.of(context).dex;
    final types = dex.typesById.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    final ids = [for (final t in types) t.identifier];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: PageStorageKey('reference-${_mode.name}'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, Space.l),
              sliver: SliverToBoxAdapter(child: Text('Tipos', style: text.headlineMedium)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Mode>(
                    showSelectedIcon: false,
                    segments: [
                      for (final m in _Mode.values) ButtonSegment(value: m, label: Text(m.label)),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => _select(s.first),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.m, Space.gutter, Space.xl),
              sliver: SliverToBoxAdapter(child: Text(_mode.intro, style: text.bodyMedium)),
            ),
            ...switch (_mode) {
              _Mode.advantages => [AdvantagesSliver(types: ids)],
              _Mode.calculator => [SliverToBoxAdapter(child: CalculatorView(types: ids))],
              _Mode.matrix => [SliverToBoxAdapter(child: MatrixView(types: ids))],
            },
            SliverToBoxAdapter(child: SizedBox(height: Space.xxxl + MediaQuery.paddingOf(context).bottom)),
          ],
        ),
      ),
    );
  }
}
