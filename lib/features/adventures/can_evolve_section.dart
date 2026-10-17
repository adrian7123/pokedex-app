import 'package:flutter/material.dart';

import '../../app/navigation.dart';
import '../../core/data/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import 'adventure_actions.dart';

/// Pares origem → destino: a origem está carimbada na aventura, o destino ainda não,
/// e o destino existe no jogo. A exigência fica no detalhe.
List<(DexEntry, DexEntry)> canEvolveNow(AppState state, int vgId) {
  final dex = state.dex;
  final index = GameIndex.of(dex);
  final stamped = {
    for (final e in state.scoped.entries)
      if (e.value.count > 0) e.key,
  };
  final available = index.available(vgId);
  final regional = index.regional(vgId);
  final out = <(DexEntry, DexEntry)>[];
  for (final to in dex.defaultBySpecies.values) {
    final from = to.evolvesFromSpeciesId;
    if (from == null || !stamped.contains(from) || stamped.contains(to.speciesId)) continue;
    if (!available.contains(to.speciesId)) continue;
    final fromEntry = dex.byPokemonId[dex.formInGame(vgId, from)] ?? dex.defaultBySpecies[from];
    final toEntry = dex.byPokemonId[dex.formInGame(vgId, to.speciesId)] ?? to;
    if (fromEntry == null) continue;
    out.add((fromEntry, toEntry));
  }
  int order(DexEntry e) => regional[e.speciesId] ?? 100000 + e.sortOrder;
  out.sort((a, b) {
    final c = order(a.$1).compareTo(order(b.$1));
    return c != 0 ? c : order(a.$2).compareTo(order(b.$2));
  });
  return out;
}

class CanEvolveSection extends StatefulWidget {
  const CanEvolveSection({super.key, required this.state, required this.adventureName, required this.vgId});
  final AppState state;
  final String adventureName;
  final int vgId;

  @override
  State<CanEvolveSection> createState() => _CanEvolveSectionState();
}

class _CanEvolveSectionState extends State<CanEvolveSection> {
  static const _preview = 6;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pairs = canEvolveNow(widget.state, widget.vgId);
    final shown = _all ? pairs : pairs.take(_preview).toList();
    final siblings = [for (final p in pairs) p.$2.pokemonId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxxl, Space.gutter, Space.xs),
          child: Text('Pode evoluir agora', style: text.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.s),
          child: Text(
            pairs.isEmpty
                ? 'Nada pendente: nenhum carimbado em ${widget.adventureName} tem evolução que ainda falte na cartela.'
                : 'Carimbados em ${widget.adventureName} cuja evolução ainda falta. Toque para ver a exigência.',
            style: text.bodyMedium,
          ),
        ),
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const Perforation(indent: Space.gutter),
          _EvolveRow(
            from: shown[i].$1,
            to: shown[i].$2,
            onTap: () => openDetail(context, shown[i].$2, siblings: siblings),
          ),
        ],
        if (pairs.length > _preview)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter - Space.s),
            child: TextButton(
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all ? 'Mostrar menos' : 'Mostrar todas (${pairs.length})'),
            ),
          ),
      ],
    );
  }
}

class _EvolveRow extends StatelessWidget {
  const _EvolveRow({required this.from, required this.to, required this.onTap});
  final DexEntry from;
  final DexEntry to;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${from.name} pode evoluir para ${to.name}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter - Space.xs, Space.xs, Space.m, Space.xs),
          child: Row(
            children: [
              SizedBox.square(dimension: 44, child: PokemonSprite(from, size: 44)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: Ramp.n5),
              ),
              SizedBox.square(
                dimension: 44,
                child: Hero(tag: spriteHeroTag(to.pokemonId), child: PokemonSprite(to, size: 44)),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(to.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('de ${from.name}', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Ramp.n5),
            ],
          ),
        ),
      ),
    );
  }
}
