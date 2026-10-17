import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/navigation.dart';
import '../../../core/data/labels.dart';
import '../../../core/data/models.dart';
import '../../../core/state/scope.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/sprite.dart';
import '../../../core/widgets/stamp.dart';
import '../../../core/widgets/type_badge.dart';
import 'evolution_graph.dart';
import 'evolution_text.dart';

/// Diâmetro do carimbo do posto e altura da linha da rota (centro do carimbo).
const double _stamp = 56;
const double _lineY = _stamp / 2;
const Duration _stagger = Duration(milliseconds: 40);

/// Cadeia evolutiva no jogo [versionGroupId]: postos da cartela ligados por rotas pontilhadas,
/// com as exigências de cada trecho.
///
/// Devolve uma [Column] de altura intrínseca (sem scroll próprio): coloque dentro do scroll
/// vertical da aba. Já aplica a margem lateral [Space.gutter]; o pai não deve somar outra.
class EvolutionView extends StatefulWidget {
  const EvolutionView({super.key, required this.speciesId, required this.pokemonId, this.versionGroupId});

  final int speciesId;
  final int pokemonId;
  final int? versionGroupId;

  @override
  State<EvolutionView> createState() => _EvolutionViewState();
}

class _EvolutionViewState extends State<EvolutionView> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(vsync: this, duration: Motion.long);
  Future<EvolutionGraph?>? _future;
  int? _chainId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future == null) _load();
  }

  @override
  void didUpdateWidget(EvolutionView old) {
    super.didUpdateWidget(old);
    if (old.versionGroupId != widget.versionGroupId) {
      _load();
    } else if (old.speciesId != widget.speciesId) {
      final chain = AppScope.read(context).dex.defaultBySpecies[widget.speciesId]?.evolutionChainId;
      if (chain != _chainId) _load();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _load() {
    final dex = AppScope.read(context).dex;
    _chainId = dex.defaultBySpecies[widget.speciesId]?.evolutionChainId;
    final chainId = _chainId;
    final future = chainId == null ? Future<EvolutionGraph?>.value(null) : EvolutionGraph.load(dex, chainId, widget.versionGroupId);
    _future = future;
    future.then((graph) {
      if (!mounted || _future != future) return;
      if (MediaQuery.disableAnimationsOf(context) || graph == null) {
        _reveal.value = 1;
        return;
      }
      final steps = math.min(_stepsOf(graph), 12);
      _reveal.duration = Motion.medium + _stagger * steps;
      _reveal.forward(from: 0);
    }, onError: (_) {});
  }

  /// Quantos degraus a sequência de entrada tem (colunas: 2 por estágio; linhas: 1 por trecho).
  int _stepsOf(EvolutionGraph g) => math.max(2 * g.maxDepth, g.fans.length + 1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.l, Space.gutter, Space.xl),
      child: FutureBuilder<EvolutionGraph?>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError && !snap.hasData) {
            return Text(
              'Não deu para carregar a cadeia evolutiva.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
            );
          }
          if (snap.connectionState != ConnectionState.done && !snap.hasData) return const _Skeleton();
          final graph = snap.data;
          if (graph == null || !graph.evolves) return _NoEvolution(graph: graph);
          return _Chain(
            graph: graph,
            reveal: _reveal,
            steps: math.min(_stepsOf(graph), 12),
            currentSpeciesId: widget.speciesId,
            currentPokemonId: widget.pokemonId,
            versionGroupId: widget.versionGroupId,
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Cadeia

class _Chain extends StatelessWidget {
  const _Chain({
    required this.graph,
    required this.reveal,
    required this.steps,
    required this.currentSpeciesId,
    required this.currentPokemonId,
    required this.versionGroupId,
  });

  final EvolutionGraph graph;
  final AnimationController reveal;
  final int steps;
  final int currentSpeciesId;
  final int currentPokemonId;
  final int? versionGroupId;

  /// Fatia da animação de entrada do degrau [index]: começa 40ms depois do anterior.
  Animation<double> _stage(int index) {
    final total = (Motion.medium + _stagger * steps).inMilliseconds;
    final i = math.min(index, steps);
    final begin = (_stagger * i).inMilliseconds / total;
    final end = math.min(1.0, begin + Motion.medium.inMilliseconds / total);
    return reveal.drive(CurveTween(curve: Interval(begin, end, curve: Motion.emphasized)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final vg = versionGroupId;
    final available = vg == null ? null : app.dex.availableInGame(vg);
    final exact = graph.nodes.any((n) => n.pokemonId == currentPokemonId);
    final siblings = [for (final n in graph.nodes) n.pokemonId];

    Widget post(EvoNode n, double width, int index) => _Reveal(
      animation: _stage(index),
      child: _Post(
        node: n,
        width: width,
        current: n.speciesId == currentSpeciesId && (!exact || n.pokemonId == currentPokemonId),
        opened: n.pokemonId == currentPokemonId,
        inGame: available == null || available.contains(n.speciesId),
        currentSpeciesId: currentSpeciesId,
        siblings: siblings,
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final double scale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 2.0);
        final double postW = 88 * math.min(scale, 1.35);
        final double minRoute = 128 * math.min(scale, 1.6);
        final depth = graph.maxDepth;
        final routeW = depth == 0 ? 0.0 : (c.maxWidth - (depth + 1) * postW) / depth;
        final columns = depth >= 2 && routeW >= minRoute;

        final children = <Widget>[];
        if (columns) {
          // Colunas = estágios; ramos empilhados na coluna seguinte.
          final w = math.min(routeW, 240.0);
          Widget subtree(EvoNode n) {
            if (n.edges.isEmpty) return post(n, postW, 2 * n.depth);
            return _Fan(
              from: post(n, postW, 2 * n.depth),
              edges: n.edges,
              routeWidth: w,
              routeAnimation: (e) => _stage(2 * e.to.depth - 1),
              dest: subtree,
            );
          }

          for (final (i, r) in graph.roots.indexed) {
            if (i > 0) children.add(const SizedBox(height: Space.xl));
            children.add(subtree(r));
          }
        } else {
          // Em linhas: cada posto que evolui abre um leque [origem] → [exigências] → [destino].
          final fans = graph.fans;
          for (final (k, n) in fans.indexed) {
            if (k > 0) children.add(const SizedBox(height: Space.xxl));
            children.add(
              _Fan(
                from: post(n, postW, k),
                edges: n.edges,
                routeWidth: null,
                routeAnimation: (_) => _stage(k + 1),
                dest: (d) => post(d, postW, k + 2),
              ),
            );
          }
          for (final r in graph.roots) {
            if (r.edges.isNotEmpty) continue;
            children
              ..add(const SizedBox(height: Space.xxl))
              ..add(post(r, postW, fans.length + 1));
          }
        }

        final forms = graph.battleForms;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...children,
            if (forms.isNotEmpty) _BattleForms(forms: forms),
          ],
        );
      },
    );
  }
}

/// Um posto de origem e seus trechos empilhados (um por ramo).
class _Fan extends StatelessWidget {
  const _Fan({required this.from, required this.edges, required this.routeWidth, required this.routeAnimation, required this.dest});

  final Widget from;
  final List<EvoEdge> edges;

  /// Largura fixa da rota (modo colunas) ou null para ocupar o espaço livre (modo linhas).
  final double? routeWidth;
  final Animation<double> Function(EvoEdge) routeAnimation;
  final Widget Function(EvoNode) dest;

  @override
  Widget build(BuildContext context) {
    final fixed = routeWidth;
    final branches = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, e) in edges.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: fixed == null ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (fixed == null)
                  Expanded(
                    child: _Route(edge: e, first: i == 0, last: i == edges.length - 1, progress: routeAnimation(e)),
                  )
                else
                  SizedBox(
                    width: fixed,
                    child: _Route(edge: e, first: i == 0, last: i == edges.length - 1, progress: routeAnimation(e)),
                  ),
                Align(alignment: Alignment.topLeft, child: dest(e.to)),
              ],
            ),
          ),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fixed == null ? MainAxisSize.max : MainAxisSize.min,
      children: [
        from,
        if (fixed == null) Expanded(child: branches) else branches,
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Posto

class _Post extends StatelessWidget {
  const _Post({
    required this.node,
    required this.width,
    required this.current,
    required this.opened,
    required this.inGame,
    required this.currentSpeciesId,
    required this.siblings,
  });

  final EvoNode node;
  final double width;
  final bool current;

  /// É a variedade aberta no detalhe: o nome não reabre a mesma tela.
  final bool opened;
  final bool inGame;
  final int currentSpeciesId;
  final List<int> siblings;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context).textTheme;
    final e = node.entry;
    final name = evolutionDisplayName(e);
    final ink = TypeInks.of(e.type1).ink;
    final stamp = app.stampOf(e.speciesId);
    final stampLabel = switch (stamp) {
      StampState.empty => 'não carimbado',
      StampState.stamped => 'carimbado',
      StampState.shiny => 'carimbado shiny',
    };
    final nameStyle = current
        ? theme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
            decorationColor: ink,
            decorationThickness: 2,
          )
        : theme.titleSmall;
    final canOpen = !opened;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: inGame ? 1 : .45,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StampSlot(
                  seed: e.speciesId,
                  ink: ink,
                  state: stamp,
                  size: _stamp,
                  semanticLabel: '$name, $stampLabel. Toque para carimbar, toque longo para shiny',
                  onTap: () => _capture(context, e, shiny: false, currentSpeciesId: currentSpeciesId),
                  onLongPress: () => _capture(context, e, shiny: true, currentSpeciesId: currentSpeciesId),
                  child: PokemonSprite(e, shiny: stamp == StampState.shiny),
                ),
                Semantics(
                  button: canOpen,
                  label: canOpen ? 'Abrir $name' : name,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: canOpen ? () => openDetail(context, e, siblings: siblings) : null,
                    borderRadius: BorderRadius.circular(Space.s),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.xs),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name, style: nameStyle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(Labels.dexNumber(e.speciesId), style: theme.labelMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!inGame) Text('fora deste jogo', style: theme.labelMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Mesmos gestos da lista: toque carimba/descarimba, toque longo carimba shiny; SnackBar com Desfazer.
Future<void> _capture(BuildContext context, DexEntry e, {required bool shiny, required int currentSpeciesId}) async {
  final app = AppScope.read(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final name = evolutionDisplayName(e);
  final before = app.stampOf(e.speciesId);
  final undo = shiny ? await app.toggleShiny(e) : await app.toggleCapture(e);
  if (!context.mounted) return;
  if (undo == null) {
    // Só restam exemplares com ficha: removê-los é decisão da aba "Meus exemplares".
    if (e.speciesId == currentSpeciesId) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(persist: false, content: Text('$name tem exemplares com ficha. Remova em Meus exemplares.')));
    } else {
      openDetail(context, e, initialTab: 4);
    }
    return;
  }
  final message = shiny
      ? (before == StampState.shiny ? 'Shiny removido' : '$name carimbado como shiny')
      : (before == StampState.empty ? '$name carimbado' : 'Carimbo removido');
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        persist: false,
        content: Text(message),
        action: SnackBarAction(label: 'Desfazer', onPressed: () => undo()),
      ),
    );
}

// -----------------------------------------------------------------------------
// Rota

class _Route extends StatelessWidget {
  const _Route({required this.edge, required this.first, required this.last, required this.progress});

  final EvoEdge edge;
  final bool first;
  final bool last;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: edge.spoken(evolutionDisplayName),
      excludeSemantics: true,
      child: CustomPaint(
        painter: _RoutePainter(progress: progress, first: first, last: last),
        child: FadeTransition(
          opacity: progress,
          child: Padding(
            padding: EdgeInsets.only(left: Space.m, right: Space.l, bottom: last ? 0 : Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, b) in edge.blocks.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.s),
                      child: Text('ou', style: theme.titleSmall?.copyWith(color: Ramp.n6)),
                    ),
                  _BlockView(block: b, onLine: i == 0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, required this.onLine});

  final RequirementBlock block;

  /// O primeiro bloco senta o chip em cima da linha da rota.
  final bool onLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final chip = _Chip(requirement: block.chip);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onLine)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _stamp),
            child: Align(alignment: Alignment.centerLeft, child: chip),
          )
        else
          chip,
        for (final r in block.lines)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 18,
                  child: Center(child: _Lead(requirement: r, size: 14)),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(r.text, style: theme.bodySmall)),
              ],
            ),
          ),
        if (block.isFallback)
          Padding(
            padding: const EdgeInsets.only(top: Space.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: Center(child: Icon(Icons.info_outline_rounded, size: 14, color: Ramp.n6)),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text('Regra geral, pode variar neste jogo', style: theme.labelMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Placa da rota: pílula de papel que cobre o pontilhado, com a exigência principal.
class _Chip extends StatelessWidget {
  const _Chip({required this.requirement});
  final Requirement requirement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.s, 5, Space.m, 5),
      decoration: BoxDecoration(
        color: Ramp.paper,
        border: Border.all(color: Ramp.n2),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Lead(requirement: requirement, size: 16, itemSize: 22),
          const SizedBox(width: 6),
          Flexible(child: Text(requirement.chipLabel, style: Theme.of(context).textTheme.titleSmall)),
        ],
      ),
    );
  }
}

/// Sprite do item, glifo do tipo ou ícone Material da exigência.
class _Lead extends StatelessWidget {
  const _Lead({required this.requirement, required this.size, this.itemSize});
  final Requirement requirement;
  final double size;
  final double? itemSize;

  @override
  Widget build(BuildContext context) {
    final item = requirement.item;
    final icon = Icon(requirement.icon, size: size, color: Ramp.n6);
    if (item != null && item.hasSprite) {
      final s = itemSize ?? size + 4;
      return Image.asset(item.spritePath, width: s, height: s, filterQuality: FilterQuality.medium, errorBuilder: (_, _, _) => icon);
    }
    final type = requirement.type;
    if (type != null) return TypeIcon(type, size: size);
    return icon;
  }
}

/// Linha de rota em picote: horizontal no centro do carimbo, tronco vertical quando há ramos
/// empilhados, e a seta presa à borda do próximo posto. Desenha até [progress] (a tinta descendo).
class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.progress, required this.first, required this.last, this.arrow = true}) : super(repaint: progress);

  final Animation<double> progress;
  final bool first;
  final bool last;
  final bool arrow;

  static const _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.value.clamp(0.0, 1.0);
    if (p <= 0) return;
    final dot = Paint()..color = Ramp.n3;
    if (!first) {
      for (var y = 1.0; y < _lineY; y += _gap) {
        canvas.drawCircle(Offset(1, y), 1, dot);
      }
    }
    if (!last) {
      for (var y = _lineY + _gap; y < size.height; y += _gap) {
        canvas.drawCircle(Offset(1, y), 1, dot);
      }
    }
    final end = (size.width - (arrow ? 4 : 1)) * p;
    for (var x = 1.0; x <= end; x += _gap) {
      canvas.drawCircle(Offset(x, _lineY), 1, dot);
    }
    if (arrow && p > .8) {
      final tip = size.width - 1;
      final head = Path()
        ..moveTo(tip - 5, _lineY - 5)
        ..lineTo(tip, _lineY)
        ..lineTo(tip - 5, _lineY + 5);
      canvas.drawPath(
        head,
        Paint()
          ..color = Ramp.n4.withValues(alpha: (p - .8) / .2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.first != first || old.last != last || old.arrow != arrow || old.progress != progress;
}

/// Entrada: surge com fade e desliza 8dp da esquerda.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Transform.translate(offset: Offset(-8 * (1 - animation.value), 0), child: child),
      child: child,
    ),
  );
}

// -----------------------------------------------------------------------------
// Formas de batalha, sem evolução, carregando

class _BattleForms extends StatelessWidget {
  const _BattleForms({required this.forms});
  final List<FormChange> forms;

  @override
  Widget build(BuildContext context) {
    final dex = AppScope.read(context).dex;
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Perforation(),
          const SizedBox(height: Space.xl),
          Text('Formas de batalha', style: theme.titleMedium),
          const SizedBox(height: Space.s),
          for (final f in forms)
            if (dex.byPokemonId[f.pokemonId] case final entry?)
              InkWell(
                onTap: () => openDetail(context, entry),
                borderRadius: BorderRadius.circular(Space.s),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.xs),
                    child: Row(
                      children: [
                        SizedBox.square(dimension: 48, child: PokemonSprite(entry, size: 48)),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(f.name, style: theme.titleSmall),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  _Lead(
                                    requirement: Requirement(
                                      f.isGmax ? Icons.open_in_full_rounded : Icons.auto_awesome_outlined,
                                      '',
                                      item: f.item,
                                    ),
                                    size: 14,
                                    itemSize: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(f.isGmax ? 'Fator Gigantamax' : (f.item?.name ?? 'Megaevolução'), style: theme.bodySmall),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _NoEvolution extends StatelessWidget {
  const _NoEvolution({required this.graph});
  final EvolutionGraph? graph;

  @override
  Widget build(BuildContext context) {
    final forms = graph?.battleForms ?? const <FormChange>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Não evolui.', style: Theme.of(context).textTheme.bodyLarge),
        if (forms.isNotEmpty) _BattleForms(forms: forms),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget slot() => const SizedBox(
      width: 88,
      child: Center(
        child: StampSlot(seed: 0, ink: Ramp.n3, state: StampState.empty, size: _stamp),
      ),
    );
    return Semantics(
      label: 'Carregando evolução',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: .6,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              slot(),
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, _stamp),
                  painter: _RoutePainter(progress: const AlwaysStoppedAnimation(1), first: true, last: true, arrow: false),
                ),
              ),
              slot(),
            ],
          ),
        ),
      ),
    );
  }
}
