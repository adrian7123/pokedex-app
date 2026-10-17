import 'package:flutter/material.dart';

import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/type_badge.dart';

/// Calculadora defensiva: 1 ou 2 tipos → quanto cada tipo atacante causa.
class CalculatorView extends StatefulWidget {
  const CalculatorView({super.key, required this.types});
  final List<String> types;

  @override
  State<CalculatorView> createState() => _CalculatorViewState();
}

class _CalculatorViewState extends State<CalculatorView> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  List<String> _defs = [];
  DexEntry? _from;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggle(String t) {
    setState(() {
      _from = null;
      if (_defs.contains(t)) {
        _defs = [..._defs]..remove(t);
      } else if (_defs.length < 2) {
        _defs = [..._defs, t];
      } else {
        // Já há dois: o mais antigo sai.
        _defs = [_defs[1], t];
      }
    });
  }

  void _usePokemon(DexEntry e) {
    _search.clear();
    _focus.unfocus();
    setState(() {
      _query = '';
      _from = e;
      _defs = e.types;
    });
  }

  List<DexEntry> _results(List<DexEntry> entries) {
    final q = DexEntry.normalize(_query);
    if (q.isEmpty) return const [];
    final n = int.tryParse(q.replaceAll('#', ''));
    final out = <DexEntry>[];
    for (final e in entries) {
      if (n != null ? e.speciesId == n : e.searchKey.contains(q)) {
        out.add(e);
        if (out.length == 6) break;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dex = AppScope.of(context).dex;
    final results = _results(dex.entries);
    String nameOf(String t) => dex.types[t]?.namePt ?? t;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _search,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Usar os tipos de um Pokémon',
              prefixIcon: const Icon(Icons.search_rounded, color: Ramp.n6),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close_rounded, color: Ramp.n6),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
          if (_query.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.m),
                child: Text('Nenhum Pokémon com esse nome ou número.', style: text.bodyMedium),
              )
            else
              for (final e in results) _ResultRow(entry: e, onTap: () => _usePokemon(e)),
          ],
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Tipos defensores',
                    style: text.titleMedium,
                    children: [TextSpan(text: '  até 2', style: text.bodySmall)],
                  ),
                ),
              ),
              if (_defs.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _defs = [];
                    _from = null;
                  }),
                  child: const Text('Limpar'),
                ),
            ],
          ),
          if (_from != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: Text('Tipos de ${_from!.name}', style: text.bodySmall),
            ),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.s,
            runSpacing: 0,
            children: [
              for (final t in widget.types) _TypeToggle(type: t, name: nameOf(t), selected: _defs.contains(t), onTap: () => _toggle(t)),
            ],
          ),
          const SizedBox(height: Space.xxl),
          if (_defs.isEmpty)
            Text('Escolha 1 ou 2 tipos para ver o dano que cada tipo de ataque causa.', style: text.bodyMedium)
          else
            _Result(defs: _defs, types: widget.types, title: _defs.map(nameOf).join(' / ')),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.entry, required this.onTap});
  final DexEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sheet),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            SizedBox.square(dimension: 44, child: PokemonSprite(entry, size: 44)),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Wrap(
                    spacing: Space.m,
                    children: [
                      Text(Labels.dexNumber(entry.nationalNumber), style: text.bodySmall),
                      for (final t in entry.types) TypeDot(t),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pílula de tipo selecionável (mesma linguagem da TypePill), com alvo de toque de 48dp.
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.name, required this.selected, required this.onTap});
  final String type;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = TypeInks.of(type);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: AnimatedContainer(
            duration: reduce ? Duration.zero : Motion.short,
            curve: Motion.standard,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            decoration: BoxDecoration(
              color: selected ? ink.wash(.3) : ink.wash(.1),
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: selected ? ink.text : Colors.transparent, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[Icon(Icons.check_rounded, size: 16, color: ink.text), const SizedBox(width: Space.xs)],
                TypeIcon(type, size: 16),
                const SizedBox(width: 6),
                Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ink.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.defs, required this.types, required this.title});
  final List<String> defs;
  final List<String> types;
  final String title;

  static const _groups = [
    (400, '4×', 'Fraqueza dupla'),
    (200, '2×', 'Fraqueza'),
    (100, '1×', 'Dano normal'),
    (50, '½×', 'Resistência'),
    (25, '¼×', 'Resistência dupla'),
    (0, '0×', 'Imunidade'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dex = AppScope.of(context).dex;
    final byFactor = <int, List<String>>{};
    for (final a in types) {
      byFactor.putIfAbsent(dex.damageAgainst(a, defs), () => []).add(a);
    }
    final shown = [
      for (final g in _groups)
        if (byFactor[g.$1]?.isNotEmpty ?? false) g,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dano recebido por $title', style: text.titleLarge),
        const SizedBox(height: Space.m),
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const Perforation(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 56, child: Text(shown[i].$2, style: text.headlineMedium?.copyWith(height: 1))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shown[i].$3, style: text.titleSmall),
                      const SizedBox(height: Space.s),
                      Wrap(
                        spacing: Space.xs + 2,
                        runSpacing: Space.xs + 2,
                        children: [for (final t in byFactor[shown[i].$1]!) TypePill(t, dense: true)],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
