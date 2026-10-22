import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../features/adventures/adventures_screen.dart';
import '../features/collection/collection_screen.dart';
import '../features/pokedex/pokedex_screen.dart';
import '../features/reference/reference_screen.dart';

/// Shell com as 4 abas. Troca de aba em eixo compartilhado horizontal: a direção segue a ordem.
class Shell extends StatefulWidget {
  const Shell({super.key});

  static void goTo(BuildContext context, int index) => context.findAncestorStateOfType<_ShellState>()?._select(index);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  bool _reverse = false;

  static const _tabs = <Widget>[
    PokedexScreen(key: PageStorageKey('pokedex')),
    AdventuresScreen(key: PageStorageKey('adventures')),
    CollectionScreen(key: PageStorageKey('collection')),
    ReferenceScreen(key: PageStorageKey('reference')),
  ];

  void _select(int i) {
    if (i == _index) return;
    setState(() {
      _reverse = i < _index;
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Voltar do sistema fora da Pokédex leva para a Pokédex; só nela o app fecha.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: PageTransitionSwitcher(
          duration: reduce ? Duration.zero : Motion.medium,
          reverse: _reverse,
          transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
            animation: primary,
            secondaryAnimation: secondary,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Ramp.paper,
            child: child,
          ),
          child: KeyedSubtree(key: ValueKey(_index), child: _tabs[_index]),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Ramp.n2))),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.catching_pokemon_outlined), selectedIcon: Icon(Icons.catching_pokemon), label: 'Pokédex'),
              NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Aventuras'),
              NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark), label: 'Coleção'),
              NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Tipos'),
            ],
          ),
        ),
      ),
    );
  }
}
