import 'package:flutter/material.dart';

import '../../app/navigation.dart';
import '../../core/data/models.dart';
import '../../core/data/user_database.dart' show Specimen;
import '../../core/state/app_state.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/stamp.dart';
import '../../core/widgets/type_badge.dart';
import 'marks.dart';
import 'pokedex_controller.dart';

/// Altura da linha da lista compacta.
const rowExtent = 72.0;

/// Carimbo da linha e recuo do picote (alinha com o texto).
const _rowStamp = 52.0;
const _rowGap = Space.m;
const rowTextIndent = Space.gutter + _rowStamp + _rowGap;

// -----------------------------------------------------------------------------
// Reordenação preservando a linha

/// Uma mudança de resultado: de onde cada linha veio, para ela deslizar até o novo lugar.
class FlipFrame {
  FlipFrame({
    required this.version,
    required this.previousIndexOf,
    required this.scrollDelta,
    required this.columns,
    required this.cell,
    required this.viewport,
    required this.reduceMotion,
  }) : _born = DateTime.now();

  final int version;
  final Map<int, int> previousIndexOf;

  /// Deslocamento antigo − novo da rolagem (a lista pode ter voltado ao topo).
  final double scrollDelta;
  final int columns;
  final Size cell;
  final double viewport;
  final bool reduceMotion;
  final DateTime _born;

  /// Só anima quem é construído logo depois da mudança, não quem entra rolando depois.
  bool get fresh => DateTime.now().difference(_born) < const Duration(milliseconds: 150);

  /// Quanto a linha precisa sair deslocada para começar no lugar antigo.
  Offset from(int previous, int current) {
    final dx = ((previous % columns) - (current % columns)) * cell.width;
    final dy = ((previous ~/ columns) - (current ~/ columns)) * cell.height - scrollDelta;
    return Offset(dx, dy);
  }
}

/// Envolve uma linha/célula: desliza do lugar antigo (identidade preservada) ou surge, se é nova.
class FlipSlot extends StatefulWidget {
  const FlipSlot({super.key, required this.frame, required this.id, required this.index, required this.child});
  final FlipFrame? frame;
  final int id;
  final int index;
  final Widget child;

  @override
  State<FlipSlot> createState() => _FlipSlotState();
}

class _FlipSlotState extends State<FlipSlot> with SingleTickerProviderStateMixin {
  AnimationController? _anim;
  Offset _from = Offset.zero;
  bool _entering = false;
  int _seen = -1;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(FlipSlot old) {
    super.didUpdateWidget(old);
    _check();
  }

  void _check() {
    final f = widget.frame;
    if (f == null || f.version == _seen) return;
    _seen = f.version;
    if (f.reduceMotion || !f.fresh) return;
    final prev = f.previousIndexOf[widget.id];
    if (prev == null) {
      _entering = true;
      _from = const Offset(0, Space.m);
    } else {
      final d = f.from(prev, widget.index);
      if (d == Offset.zero) return;
      if (d.dy.abs() > f.viewport) {
        // Veio de longe: não atravessa a tela, só aparece.
        _entering = true;
        _from = const Offset(0, Space.m);
      } else {
        _entering = false;
        _from = d;
      }
    }
    (_anim ??= AnimationController(vsync: this, duration: Motion.medium)).forward(from: 0);
  }

  @override
  void dispose() {
    _anim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Estrutura fixa (translate + opacity) para o filho nunca ser recriado no fim da animação.
    final anim = _anim;
    return AnimatedBuilder(
      animation: anim ?? const AlwaysStoppedAnimation<double>(1),
      child: widget.child,
      builder: (context, child) {
        final running = anim != null && anim.isAnimating;
        final t = running ? Motion.emphasized.transform(anim.value) : 1.0;
        return Transform.translate(
          offset: _from * (1 - t),
          child: Opacity(opacity: _entering ? t : 1, child: child),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Gestos do carimbo

bool _isBare(Specimen s) =>
    s.nickname == null && s.level == null && s.nature == null && s.ivs == null && s.evs == null && s.moves == null && s.notes == null;

void _snack(ScaffoldMessengerState messenger, String text, {Future<void> Function()? undo}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        persist: false,
        content: Text(text),
        duration: const Duration(seconds: 3),
        action: undo == null ? null : SnackBarAction(label: 'Desfazer', onPressed: () => undo()),
      ),
    );
}

/// Toque no carimbo: carimba ou remove o exemplar sem ficha.
Future<void> tapStamp(BuildContext context, DexEntry e, List<int> Function() siblings) async {
  final app = AppScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  final was = app.stampOf(e.speciesId);
  final undo = await app.toggleCapture(e);
  if (undo == null) {
    if (!context.mounted) return;
    _snack(messenger, 'Esse carimbo tem ficha preenchida. Remova em Meus exemplares.');
    openDetail(context, e, siblings: siblings(), initialTab: 4);
    return;
  }
  _snack(messenger, was == StampState.empty ? '${e.name} carimbado' : 'Carimbo removido', undo: undo);
}

/// Toque longo: carimbo em ouro (shiny), ou tira o ouro do exemplar simples.
Future<void> holdStamp(BuildContext context, DexEntry e) async {
  final app = AppScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  final removing = app.specimensOf(e.speciesId, scopedOnly: true).any((s) => s.isShiny && _isBare(s));
  final undo = await app.toggleShiny(e);
  _snack(messenger, removing ? 'Ouro removido de ${e.name}' : '${e.name} carimbado em ouro', undo: undo);
}

String _stampLabel(DexEntry e, StampState s) => switch (s) {
  StampState.empty => 'Carimbar ${e.name}. Toque longo carimba em ouro',
  StampState.stamped => '${e.name} carimbado. Toque para remover',
  StampState.shiny => '${e.name} carimbado em ouro. Toque para remover',
};

class _Stamp extends StatelessWidget {
  const _Stamp({required this.entry, required this.state, required this.size, required this.siblings});
  final DexEntry entry;
  final StampState state;
  final double size;
  final List<int> Function() siblings;

  @override
  Widget build(BuildContext context) => StampSlot(
    seed: entry.speciesId,
    ink: TypeInks.of(entry.type1).ink,
    state: state,
    size: size,
    semanticLabel: _stampLabel(entry, state),
    onTap: () => tapStamp(context, entry, siblings),
    onLongPress: () => holdStamp(context, entry),
    child: Hero(
      tag: spriteHeroTag(entry.pokemonId),
      child: PokemonSprite(entry, shiny: state == StampState.shiny),
    ),
  );
}

// -----------------------------------------------------------------------------
// Linha da lista

class DexRow extends StatelessWidget {
  const DexRow({super.key, required this.entry, required this.controller, required this.app, required this.siblings});

  final DexEntry entry;
  final PokedexController controller;
  final AppState app;
  final List<int> Function() siblings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final e = entry;
    final state = app.stampOf(e.speciesId);
    final mark = app.markOf(e.speciesId);
    final value = controller.sortValueOf(e);
    final number = controller.numberLabel(e);
    return SizedBox(
      height: rowExtent,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () => openDetail(context, e, siblings: siblings()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Row(
                  children: [
                    _Stamp(entry: e, state: state, size: _rowStamp, siblings: siblings),
                    const SizedBox(width: _rowGap),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: number, style: text.labelMedium),
                                const TextSpan(text: '  '),
                                TextSpan(text: e.name, style: text.titleLarge),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              TypeDot(e.type1),
                              if (e.type2 != null) ...[const SizedBox(width: Space.m), TypeDot(e.type2!)],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (mark.favorite || mark.marks != 0) ...[const SizedBox(width: Space.s), _MarkStrip(mark: mark)],
                    if (value != null) ...[const SizedBox(width: Space.m), Text(value, style: text.titleSmall)],
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: Space.gutter,
            bottom: 0,
            child: Perforation(indent: rowTextIndent),
          ),
        ],
      ),
    );
  }
}

class _MarkStrip extends StatelessWidget {
  const _MarkStrip({required this.mark});
  final SpeciesMark mark;

  @override
  Widget build(BuildContext context) {
    final labels = [
      if (mark.favorite) 'favorito',
      for (final m in SpeciesMarkBit.values)
        if (mark.marks & m.bit != 0) m.label.toLowerCase(),
    ];
    return Semantics(
      label: 'Marcas: ${labels.join(', ')}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark.favorite) const Icon(favoriteIcon, size: 16, color: Ramp.n6),
          for (final m in SpeciesMarkBit.values)
            if (mark.marks & m.bit != 0)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: MarkGlyph(m, size: 14, color: Ramp.n6),
              ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Célula da grade (a cartela)

/// Altura da célula para um carimbo de [stamp] dp.
double cellExtent(double stamp) => stamp + Space.xs + 20 + Space.m;

class DexCell extends StatelessWidget {
  const DexCell({super.key, required this.entry, required this.controller, required this.app, required this.stamp, required this.siblings});

  final DexEntry entry;
  final PokedexController controller;
  final AppState app;
  final double stamp;
  final List<int> Function() siblings;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final state = app.stampOf(e.speciesId);
    return Semantics(
      label: '${e.name}, ${controller.numberLabel(e)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.sheet),
        onTap: () => openDetail(context, e, siblings: siblings()),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Stamp(entry: e, state: state, size: stamp, siblings: siblings),
            const SizedBox(height: Space.xs),
            SizedBox(height: 20, child: Text(controller.numberLabel(e), style: Theme.of(context).textTheme.labelMedium, maxLines: 1)),
          ],
        ),
      ),
    );
  }
}
