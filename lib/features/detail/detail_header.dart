import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/navigation.dart';
import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/data/pokeapi_cache.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/stamp.dart';
import '../../core/widgets/type_badge.dart';
import 'detail_common.dart';

/// Topo do detalhe: nº monumental, arte, nome, tipos, carimbo e o jogo desta tela.
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.entry,
    required this.shiny,
    required this.game,
    required this.inDex,
    required this.onPickGame,
    required this.onOpenSpecimens,
  });

  final DexEntry entry;
  final bool shiny;
  final VersionGroup game;
  final bool inDex;
  final VoidCallback onPickGame;
  final VoidCallback onOpenSpecimens;

  static const artSize = 220.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = TypeInks.of(entry.type1);
    final form = entry.formName;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ink.wash(.10), Ramp.paper],
          stops: const [0, .85],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: artSize + Space.l,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: ExcludeSemantics(child: Text(Labels.dexNumber(entry.speciesId), style: text.displayLarge)),
                  ),
                  Positioned(
                    right: -Space.s,
                    bottom: 0,
                    child: SizedBox.square(
                      dimension: artSize,
                      child: Hero(
                        tag: spriteHeroTag(entry.pokemonId),
                        flightShuttleBuilder: (_, _, _, _, _) => PokemonSprite(entry),
                        child: _Artwork(entry: entry, shiny: shiny, size: artSize),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.s),
            Semantics(
              header: true,
              label: '${entry.name}, número ${entry.speciesId}',
              excludeSemantics: true,
              child: Text(entry.name, style: text.headlineMedium),
            ),
            if (entry.genus != null) ...[
              const SizedBox(height: Space.xs),
              Text(entry.genus!, style: text.bodyMedium),
            ],
            if (form != null && form != entry.name) Text(form, style: text.bodySmall),
            const SizedBox(height: Space.m),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [for (final t in entry.types) TypePill(t)],
            ),
            const SizedBox(height: Space.l),
            _ActionRow(entry: entry, onOpenSpecimens: onOpenSpecimens),
            const SizedBox(height: Space.m),
            _GameButton(game: game, onTap: onPickGame),
            if (!inDex) ...[
              const SizedBox(height: Space.xs),
              InfoNote('Não aparece na Pokédex de ${game.name}'),
            ],
          ],
        ),
      ),
    );
  }
}

/// Artwork oficial sob demanda; enquanto carrega (ou offline) mostra o sprite embutido ampliado.
class _Artwork extends StatefulWidget {
  const _Artwork({required this.entry, required this.shiny, required this.size});
  final DexEntry entry;
  final bool shiny;
  final double size;

  @override
  State<_Artwork> createState() => _ArtworkState();
}

class _ArtworkState extends State<_Artwork> {
  static const _base = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork';
  final Map<bool, Future<File?>> _files = {};

  Future<File?> _file(bool shiny) => _files[shiny] ??= PokeApiCache.instance.image(
        shiny ? '$_base/shiny/${widget.entry.pokemonId}.png' : '$_base/${widget.entry.pokemonId}.png',
      );

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final shiny = widget.shiny;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return FutureBuilder<File?>(
      future: _file(shiny),
      builder: (context, snap) {
        final file = snap.connectionState == ConnectionState.done ? snap.data : null;
        final sprite = PokemonSprite(widget.entry, key: ValueKey('sprite-$shiny'), shiny: shiny, size: widget.size);
        final child = file == null
            ? sprite
            : Image.file(
                file,
                key: ValueKey('art-$shiny'),
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                cacheWidth: (widget.size * dpr).round(),
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => sprite,
              );
        return Semantics(
          image: true,
          label: shiny ? '${widget.entry.name} shiny' : widget.entry.name,
          child: AnimatedSwitcher(
            duration: reduce ? Duration.zero : Motion.medium,
            switchInCurve: Motion.standard,
            switchOutCurve: Motion.standard,
            child: child,
          ),
        );
      },
    );
  }
}

/// Carimbo grande da espécie + favorito + marcas.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.entry, required this.onOpenSpecimens});
  final DexEntry entry;
  final VoidCallback onOpenSpecimens;

  static const marks = <(int, IconData, String)>[
    (1, Icons.star_outline_rounded, 'Estrela'),
    (2, Icons.circle_outlined, 'Círculo'),
    (4, Icons.change_history_rounded, 'Triângulo'),
    (8, Icons.crop_square_rounded, 'Quadrado'),
    (16, Icons.favorite_border_rounded, 'Coração'),
    (32, Icons.diamond_outlined, 'Losango'),
  ];

  Future<void> _capture(BuildContext context) async {
    final state = AppScope.read(context);
    final was = state.stampOf(entry.speciesId);
    final undo = await state.toggleCapture(entry);
    if (!context.mounted) return;
    if (undo == null) {
      onOpenSpecimens();
      showUndoSnack(context, 'Os exemplares têm ficha. Apague por aqui se quiser.');
      return;
    }
    showUndoSnack(context, was == StampState.empty ? '${entry.speciesName} carimbado' : 'Carimbo removido', undo);
  }

  Future<void> _shiny(BuildContext context) async {
    final state = AppScope.read(context);
    final was = state.stampOf(entry.speciesId);
    final undo = await state.toggleShiny(entry);
    if (!context.mounted) return;
    showUndoSnack(context, was == StampState.shiny ? 'Shiny removido' : '${entry.speciesName} shiny carimbado', undo);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final sid = entry.speciesId;
    final stamp = state.stampOf(sid);
    final count = state.scoped[sid]?.count ?? 0;
    final mark = state.markOf(sid);
    final adventure = state.activeAdventure;

    final status = switch (stamp) {
      StampState.empty => 'Não carimbado',
      StampState.stamped => 'Carimbado',
      StampState.shiny => 'Carimbado shiny',
    };
    final where = adventure == null ? '' : ' em ${adventure.name}';
    final sub = count == 0
        ? 'Toque para carimbar, segure para shiny'
        : '$count ${count == 1 ? 'exemplar' : 'exemplares'}$where';
    final active = [for (final m in marks) if (mark.marks & m.$1 != 0) m];

    return Row(
      children: [
        StampSlot(
          seed: sid,
          ink: TypeInks.of(entry.type1).ink,
          state: stamp,
          size: 64,
          onTap: () => _capture(context),
          onLongPress: () => _shiny(context),
          semanticLabel: '$status. Toque para alternar o carimbo, toque longo para shiny',
          child: PokemonSprite(entry, shiny: stamp == StampState.shiny),
        ),
        const SizedBox(width: Space.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: text.titleMedium?.copyWith(color: stamp == StampState.shiny ? Gold.text : null),
              ),
              Text(sub, style: text.bodySmall),
              if (active.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Semantics(
                    label: 'Marcas: ${active.map((m) => m.$3).join(', ')}',
                    child: Wrap(
                      spacing: Space.xs,
                      children: [for (final m in active) Icon(m.$2, size: 16, color: Ramp.n6)],
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: mark.favorite ? 'Tirar dos favoritos' : 'Favoritar',
          isSelected: mark.favorite,
          onPressed: () => state.toggleFavorite(sid),
          icon: const Icon(Icons.favorite_border_rounded, color: Ramp.n6),
          selectedIcon: const Icon(Icons.favorite_rounded, color: Ramp.ink),
        ),
        MenuAnchor(
          alignmentOffset: const Offset(-120, 0),
          style: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Ramp.paper),
            surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          ),
          menuChildren: [
            for (final m in marks)
              CheckboxMenuButton(
                value: mark.marks & m.$1 != 0,
                closeOnActivate: false,
                onChanged: (_) => state.toggleMark(sid, m.$1),
                trailingIcon: Icon(m.$2, size: 20, color: Ramp.n6),
                child: Text(m.$3),
              ),
          ],
          builder: (context, controller, _) => IconButton(
            tooltip: 'Marcas',
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            icon: Icon(
              active.isEmpty ? Icons.bookmark_border_rounded : Icons.bookmark_rounded,
              color: active.isEmpty ? Ramp.n6 : Ramp.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Jogo: Scarlet / Violet ▾" — troca o jogo só nesta tela.
class _GameButton extends StatelessWidget {
  const _GameButton({required this.game, required this.onTap});
  final VersionGroup game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Jogo: ${game.name}. Trocar jogo',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Container(
              height: 36,
              padding: const EdgeInsets.only(left: Space.m, right: Space.xs),
              decoration: BoxDecoration(
                color: Ramp.paper,
                border: Border.all(color: Ramp.n2),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_esports_outlined, size: 18, color: Ramp.n6),
                  const SizedBox(width: Space.s),
                  Text('Jogo: ', style: text.bodySmall),
                  Flexible(child: Text(game.name, style: text.titleSmall, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.arrow_drop_down_rounded, color: Ramp.n6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Folha para escolher o jogo desta tela. Devolve o version group escolhido.
Future<int?> pickGame(
  BuildContext context, {
  required int speciesId,
  required int selected,
  required bool Function(int vgId) inDex,
}) {
  final state = AppScope.read(context);
  final games = state.dex.versionGroups.where((v) => v.isPlayable).toList()
    ..sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
  final adventureGame = state.contextVersionGroupId;
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .75),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.l),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xs),
              child: Text('Jogo desta tela', style: text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.m),
              child: Text('Muda golpes, evolução e locais só aqui.', style: text.bodyMedium),
            ),
            for (final g in games)
              InkWell(
                onTap: () => Navigator.of(context).pop(g.id),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.s),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                g.name,
                                style: text.titleMedium?.copyWith(color: inDex(g.id) ? null : Ramp.n6),
                              ),
                              if (g.id == adventureGame)
                                Text('Jogo da aventura ativa', style: text.bodySmall)
                              else if (!inDex(g.id))
                                Text('Fora da Pokédex deste jogo', style: text.bodySmall),
                            ],
                          ),
                        ),
                        if (g.id == selected) const Icon(Icons.check_rounded, color: Ramp.ink),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
