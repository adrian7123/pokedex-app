import 'package:flutter/material.dart';

import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import 'advantages_view.dart';
import 'calculator_view.dart';
import 'matrix_view.dart';

enum _Mode { advantages, calculator, matrix }

/// Consulta: tabela de tipos em três leituras (vantagens, calculadora, matriz).
class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  _Mode _mode = _Mode.advantages;

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
              sliver: SliverToBoxAdapter(child: Text('Consulta', style: text.headlineMedium)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Mode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: _Mode.advantages, label: Text('Vantagens')),
                      ButtonSegment(value: _Mode.calculator, label: Text('Calculadora')),
                      ButtonSegment(value: _Mode.matrix, label: Text('Matriz')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => _select(s.first),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
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
