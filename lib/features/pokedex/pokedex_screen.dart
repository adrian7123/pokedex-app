import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/shell.dart';
import '../../core/state/app_state.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/type_badge.dart';
import '../scan/scan_flow.dart';
import 'dex_tiles.dart';
import 'filter_sheet.dart';
import 'chip_style.dart';
import 'pokedex_controller.dart';

/// Aba Pokédex: busca, escopo de jogo, filtros e a lista (ou a cartela em grade).
class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  PokedexController? _c;
  final _scroll = ScrollController();
  final _headerKey = GlobalKey();
  FlipFrame? _frame;
  double _pendingDelta = 0;

  PokedexController get c => _c!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    _c = PokedexController.of(AppScope.read(context))..addListener(_onChange);
    // Pedido de rolagem ao topo que ficou de quando a aba não estava montada.
    c.takeScrollReset();
  }

  @override
  void dispose() {
    _c?.removeListener(_onChange);
    _scroll.dispose();
    super.dispose();
  }

  /// Mudança do usuário volta a lista ao começo (mantendo a busca fixa no topo) e guarda
  /// quanto a rolagem andou, para as linhas deslizarem do lugar em que estavam na tela.
  void _onChange() {
    if (!mounted) return;
    if (c.takeScrollReset() && _scroll.hasClients) {
      final old = _scroll.offset;
      final header = _headerKey.currentContext?.size?.height ?? 0;
      final target = math.min(old, header);
      if (old != target) {
        _scroll.jumpTo(target);
        _pendingDelta += old - target;
      }
    }
    setState(() {});
  }

  List<int> _siblings() => [for (final e in c.result) e.pokemonId];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final result = c.result;
    final version = c.version;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          final inner = width - Space.gutter * 2;
          final grid = c.grid;
          final cols = grid ? math.max(4, (inner / 96).floor()) : 1;
          final cellW = grid ? inner / cols : width;
          final stamp = grid ? math.min(cellW - Space.m, 76.0) : 52.0;
          final cellH = grid ? cellExtent(stamp) : rowExtent;
          if (_frame?.version != version) {
            _frame = FlipFrame(
              version: version,
              previousIndexOf: c.previousIndexOf,
              scrollDelta: _pendingDelta,
              columns: cols,
              cell: Size(cellW, cellH),
              viewport: box.maxHeight,
              reduceMotion: reduce,
            );
            _pendingDelta = 0;
          }
          final frame = _frame;

          int? findIndex(Key key) => key is ValueKey<int> ? c.indexOf[key.value] : null;

          final Widget body;
          if (c.moveLoading) {
            body = SliverFillRemaining(hasScrollBody: false, child: _Loading(move: c.move?.name ?? ''));
          } else if (result.isEmpty) {
            body = SliverFillRemaining(hasScrollBody: false, child: _Empty(c: c));
          } else if (grid) {
            body = SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisExtent: cellH),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final e = result[i];
                    return FlipSlot(
                      key: ValueKey<int>(e.pokemonId),
                      frame: frame,
                      id: e.pokemonId,
                      index: i,
                      child: DexCell(entry: e, controller: c, app: app, stamp: stamp, siblings: _siblings),
                    );
                  },
                  childCount: result.length,
                  findChildIndexCallback: findIndex,
                ),
              ),
            );
          } else {
            body = SliverFixedExtentList(
              itemExtent: rowExtent,
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final e = result[i];
                  return FlipSlot(
                    key: ValueKey<int>(e.pokemonId),
                    frame: frame,
                    id: e.pokemonId,
                    index: i,
                    child: DexRow(entry: e, controller: c, app: app, siblings: _siblings),
                  );
                },
                childCount: result.length,
                findChildIndexCallback: findIndex,
              ),
            );
          }

          return CustomScrollView(
            key: const PageStorageKey('pokedex-scroll'),
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: KeyedSubtree(key: _headerKey, child: _Header(c: c, app: app)),
              ),
              SliverPersistentHeader(pinned: true, delegate: _SearchHeader(c)),
              SliverToBoxAdapter(child: _QuickChips(c: c)),
              SliverToBoxAdapter(child: _Summary(c: c)),
              body,
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Topo

class _Header extends StatelessWidget {
  const _Header({required this.c, required this.app});
  final PokedexController c;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final adventure = app.activeAdventure;
    final game = app.contextVersionGroup;
    final (done, total) = app.progress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.l, Space.xs, 0),
          child: Row(
            children: [
              Expanded(child: Text('Pokédex', style: text.headlineMedium)),
              IconButton(
                tooltip: 'Carimbar por foto',
                icon: const Icon(Icons.photo_camera_outlined),
                color: Ramp.ink,
                onPressed: () => openScanFlow(context),
              ),
              IconButton(
                tooltip: 'Resetar busca, filtros e ordem',
                icon: const Icon(Icons.restart_alt_rounded),
                color: Ramp.ink,
                disabledColor: Ramp.n3,
                onPressed: c.isCustomized ? c.resetAll : null,
              ),
              IconButton(
                tooltip: c.grid ? 'Ver em lista' : 'Ver em grade',
                icon: Icon(c.grid ? Icons.view_agenda_outlined : Icons.grid_view_rounded),
                color: Ramp.ink,
                onPressed: () => c.grid = !c.grid,
              ),
              IconButton(
                tooltip: 'Ordenar: ${c.sort.label}',
                icon: Badge(
                  smallSize: 7,
                  backgroundColor: Ramp.ink,
                  isLabelVisible: c.sort != SortKey.number,
                  child: const Icon(Icons.sort_rounded),
                ),
                color: Ramp.ink,
                onPressed: () => showSortSheet(context, c),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => Shell.goTo(context, 1),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.s, Space.gutter, Space.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: adventure == null
                              ? [TextSpan(text: 'Pokédex Nacional', style: text.titleMedium)]
                              : [
                                  TextSpan(text: 'Aventura ', style: text.bodyMedium),
                                  TextSpan(text: adventure.name, style: text.titleMedium),
                                  if (game != null) TextSpan(text: ' · ${game.name}', style: text.bodyMedium),
                                ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Space.s),
                    Text('$done/$total carimbos', style: text.labelMedium),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: Ramp.n5),
                  ],
                ),
                const SizedBox(height: Space.s),
                _ProgressBar(value: total == 0 ? 0 : done / total),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      value: '${(value * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: reduce ? Duration.zero : Motion.long,
        curve: Motion.emphasized,
        builder: (context, v, _) => Container(
          height: 4,
          decoration: BoxDecoration(color: Ramp.n2, borderRadius: BorderRadius.circular(Radii.pill)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Ramp.ink, borderRadius: BorderRadius.circular(Radii.pill)),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Busca (fica presa no topo ao rolar)

class _SearchHeader extends SliverPersistentHeaderDelegate {
  _SearchHeader(this.c);
  final PokedexController c;

  static const _extent = 48.0 + Space.s * 2 + 2;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => ColoredBox(
        color: Ramp.paper,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.s, Space.gutter, Space.s),
              child: _SearchField(c: c),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Opacity(opacity: overlapsContent ? 1 : 0, child: const Perforation()),
            ),
          ],
        ),
      );

  @override
  bool shouldRebuild(_SearchHeader old) => old.c != c;
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: c.search,
          builder: (context, value, _) => TextField(
            controller: c.search,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            enableSuggestions: false,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou número',
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
              prefixIcon: const Icon(Icons.search_rounded, color: Ramp.n6),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close_rounded, color: Ramp.n6),
                      onPressed: c.search.clear,
                    ),
            ),
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// Chips de filtro rápido (quebram linha)

class _QuickChips extends StatelessWidget {
  const _QuickChips({required this.c});
  final PokedexController c;

  Widget _label(String text, bool selected, {bool dropdown = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
          if (dropdown) Icon(Icons.arrow_drop_down_rounded, size: 20, color: selected ? Ramp.paper : Ramp.n6),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final vg = c.scopeVersionGroup;
    final scopeName = vg == null ? 'Nacional' : (c.regionalOnly ? vg.name : '${vg.name} · tudo');
    final scopeSelected = !c.followsAdventure;

    final types = c.types.toList();
    final typeNames = types.map((t) => c.dex.types[t]?.namePt ?? t).toList();
    final typeSelected = types.isNotEmpty || c.typeMode == TypeMode.single || c.typeMode == TypeMode.dual;
    final typeLabel = switch (types.length) {
      0 => switch (c.typeMode) {
          TypeMode.single => 'Tipo único',
          TypeMode.dual => 'Tipo duplo',
          _ => 'Tipo',
        },
      1 => typeNames.first,
      _ => '${typeNames.first} +${types.length - 1}',
    };

    final sheetCount = c.sheetOnlyFilterCount;
    final uncaptured = c.capture == CaptureFilter.uncaptured;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, 0),
      child: Wrap(
        spacing: Space.s,
        children: [
          FilterChip(
            label: _label(scopeName, scopeSelected, dropdown: true),
            tooltip: 'Pokédex do jogo',
            selected: scopeSelected,
            labelStyle: chipLabel(context, scopeSelected),
            showCheckmark: false,
            onSelected: (_) => showScopeSheet(context, c),
          ),
          FilterChip(
            avatar: types.length == 1 ? TypeIcon(types.first, size: 16, color: Ramp.paper) : null,
            label: _label(typeLabel, typeSelected, dropdown: true),
            selected: typeSelected,
            labelStyle: chipLabel(context, typeSelected),
            showCheckmark: false,
            onSelected: (_) => showTypeSheet(context, c),
          ),
          FilterChip(
            label: const Text('Não carimbados'),
            selected: uncaptured,
            labelStyle: chipLabel(context, uncaptured),
            showCheckmark: false,
            onSelected: (_) => c.setCapture(CaptureFilter.uncaptured),
          ),
          FilterChip(
            avatar: Icon(sheetCount == 0 ? Icons.add_rounded : Icons.tune_rounded, size: 18, color: sheetCount == 0 ? Ramp.n6 : Ramp.paper),
            label: Text(sheetCount == 0 ? 'Filtros' : 'Filtros · $sheetCount'),
            selected: sheetCount > 0,
            labelStyle: chipLabel(context, sheetCount > 0),
            showCheckmark: false,
            onSelected: (_) => showFilterSheet(context, c),
          ),
          if (c.activeFilterCount > 0)
            ActionChip(
              avatar: const Icon(Icons.close_rounded, size: 18, color: Ramp.n6),
              label: const Text('Limpar'),
              onPressed: c.clearFilters,
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    final n = c.result.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.s),
      child: Row(
        children: [
          Expanded(child: Text(c.moveLoading ? 'Buscando…' : '$n Pokémon', style: style)),
          if (c.sort != SortKey.number) Text('Ordem: ${c.sort.label}', style: style),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Estados

class _Loading extends StatelessWidget {
  const _Loading({required this.move});
  final String move;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxxl, Space.gutter, 0),
        child: Column(
          children: [
            const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Ramp.n4)),
            const SizedBox(height: Space.l),
            Text('Buscando quem aprende $move…', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final searching = c.search.text.trim().isNotEmpty;
    final suggestion = c.suggestion;
    final filtered = c.activeFilterCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxxl, Space.gutter, 0),
      child: Column(
        children: [
          Text(
            searching ? 'Nada encontrado para “${c.search.text.trim()}”' : 'Nenhum Pokémon com esses filtros',
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.s),
          Text(
            searching
                ? (filtered ? 'Os filtros ligados também limitam a busca.' : 'Confira a grafia ou busque pelo número.')
                : 'Tire algum filtro ou troque a Pokédex do jogo.',
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              if (searching && suggestion != null)
                FilledButton(
                  onPressed: () => c.search.value = TextEditingValue(
                    text: suggestion,
                    selection: TextSelection.collapsed(offset: suggestion.length),
                  ),
                  child: Text('Você quis dizer $suggestion?'),
                ),
              if (filtered) OutlinedButton(onPressed: c.clearFilters, child: const Text('Limpar filtros')),
              if (searching && !filtered && suggestion == null)
                OutlinedButton(onPressed: c.search.clear, child: const Text('Limpar busca')),
            ],
          ),
        ],
      ),
    );
  }
}
