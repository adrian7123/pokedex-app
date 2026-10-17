import 'package:flutter/material.dart';

import '../../app/navigation.dart';
import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/stamp.dart';

/// Linha de Pokémon da coleção: carimbo no estado global, nº, nome, uma linha de apoio
/// e ações à direita. Toque na linha abre o detalhe.
class CollectionRow extends StatelessWidget {
  const CollectionRow({
    super.key,
    required this.entry,
    required this.summary,
    required this.subtitle,
    required this.onTap,
    this.trailing = const [],
    this.hero = true,
  });

  final DexEntry entry;
  final CaptureSummary summary;
  final String? subtitle;
  final VoidCallback onTap;
  final List<Widget> trailing;

  /// Sprite com Hero para o detalhe. Desligado onde a mesma espécie aparece na rota de baixo.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = summary.count == 0
        ? StampState.empty
        : summary.shiny
        ? StampState.shiny
        : StampState.stamped;
    final status = switch (state) {
      StampState.empty => 'sem carimbo',
      StampState.stamped => '${summary.count} ${summary.count == 1 ? 'exemplar' : 'exemplares'}',
      StampState.shiny => '${summary.count} ${summary.count == 1 ? 'exemplar' : 'exemplares'}, com shiny',
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter - 2, Space.xs, Space.s, Space.xs),
        child: Row(
          children: [
            StampSlot(
              seed: entry.speciesId,
              ink: TypeInks.of(entry.type1).ink,
              state: state,
              semanticLabel: '${entry.name}, $status',
              child: hero
                  ? Hero(
                      tag: spriteHeroTag(entry.pokemonId),
                      child: PokemonSprite(entry, shiny: state == StampState.shiny),
                    )
                  : PokemonSprite(entry, shiny: state == StampState.shiny),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Labels.dexNumber(entry.nationalNumber), style: text.bodySmall),
                  Text(entry.name, style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) Text(subtitle!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (summary.count > 1)
              Padding(
                padding: const EdgeInsets.only(left: Space.s),
                child: Text('×${summary.count}', style: text.titleMedium),
              ),
            ...trailing,
          ],
        ),
      ),
    );
  }
}
