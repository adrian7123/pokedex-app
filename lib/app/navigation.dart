import 'package:flutter/material.dart';

import '../core/data/models.dart';
import '../core/theme/tokens.dart';
import '../features/detail/detail_screen.dart';

/// Tag do Hero do sprite: o carimbo da lista voa até o topo do detalhe.
String spriteHeroTag(int pokemonId) => 'sprite-$pokemonId';

/// Abre o detalhe. A rota cruza com fade enquanto o Hero do sprite faz o movimento principal.
Future<void> openDetail(BuildContext context, DexEntry entry, {List<int>? siblings}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: reduce ? Duration.zero : Motion.long,
      reverseTransitionDuration: reduce ? Duration.zero : Motion.medium,
      pageBuilder: (_, _, _) => DetailScreen(pokemonId: entry.pokemonId, siblings: siblings),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: const Interval(0, .6, curve: Motion.standard)),
        child: child,
      ),
    ),
  );
}
