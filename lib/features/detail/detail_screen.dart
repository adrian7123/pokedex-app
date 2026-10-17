import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import 'about_tab.dart';
import 'detail_header.dart';
import 'encounters_tab.dart';
import 'evolution/evolution_view.dart';
import 'moves_tab.dart';
import 'specimens_tab.dart';

/// Detalhe de um Pokémon. Deslizar para os lados troca para o vizinho da lista de origem.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.pokemonId, this.siblings, this.initialTab = 0});
  final int pokemonId;

  /// Ordem da lista de onde veio, para deslizar ao vizinho.
  final List<int>? siblings;

  /// 0 Sobre · 1 Evolução · 2 Golpes · 3 Onde achar · 4 Meus exemplares
  final int initialTab;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final List<int> _ids;
  late final int _initialIndex;
  late final PageController _pages;
  late int _current;
  late int _tab = widget.initialTab.clamp(0, _tabLabels.length - 1);

  /// Jogo escolhido nesta tela; null = padrão de cada Pokémon.
  int? _game;

  @override
  void initState() {
    super.initState();
    final s = widget.siblings;
    _ids = s != null && s.contains(widget.pokemonId) ? s : [widget.pokemonId];
    _initialIndex = _ids.indexOf(widget.pokemonId);
    _current = _initialIndex;
    _pages = PageController(initialPage: _initialIndex);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dex = AppScope.read(context).dex;
    return Scaffold(
      body: PageView.builder(
        controller: _pages,
        allowImplicitScrolling: true,
        itemCount: _ids.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) {
          final entry = dex.byPokemonId[_ids[i]];
          if (entry == null) return const SizedBox.shrink();
          return HeroMode(
            enabled: i == _initialIndex && _current == _initialIndex,
            child: _DetailPage(
              key: ValueKey(entry.pokemonId),
              entry: entry,
              active: i == _current,
              tab: _tab,
              onTab: (t) => setState(() => _tab = t),
              game: _game,
              onGame: (g) => setState(() => _game = g),
            ),
          );
        },
      ),
    );
  }
}

const _tabLabels = ['Sobre', 'Evolução', 'Golpes', 'Onde achar', 'Meus exemplares'];

class _DetailPage extends StatefulWidget {
  const _DetailPage({
    super.key,
    required this.entry,
    required this.active,
    required this.tab,
    required this.onTab,
    required this.game,
    required this.onGame,
  });

  final DexEntry entry;
  final bool active;
  final int tab;
  final ValueChanged<int> onTab;
  final int? game;
  final ValueChanged<int> onGame;

  @override
  State<_DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<_DetailPage> with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: _tabLabels.length, vsync: this, initialIndex: widget.tab);
  late int _shown = widget.tab;

  /// Fade-through entre abas.
  late final AnimationController _fade = AnimationController(vsync: this, value: 1);

  /// Entrada escalonada das seções, uma vez por página.
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _introStarted = false;

  final _scroll = ScrollController();
  final _headerKey = GlobalKey();
  bool _titleVisible = false;
  bool _shiny = false;

  late final int _defaultGame;
  final Map<int, bool> _available = {};
  late final Future<SpeciesDetail> _detail;
  late final Future<List<FlavorEntry>?> _flavor;
  final Map<int, Future<(List<LearnedMove>, VersionGroup?)>> _learnsets = {};
  final Map<int, Future<Map<Version, List<Encounter>>>> _encounters = {};

  DexEntry get entry => widget.entry;
  int get _gameId => widget.game ?? _defaultGame;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    _defaultGame = _pickDefaultGame(state.contextVersionGroupId);
    _detail = state.dex.speciesDetail(entry.speciesId, entry.pokemonId);
    _flavor = fetchFlavor(entry.speciesId);
    _tabs.addListener(_onTab);
    _scroll.addListener(_onScroll);
    if (widget.active) WidgetsBinding.instance.addPostFrameCallback((_) => _startIntro());
  }

  @override
  void didUpdateWidget(_DetailPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _startIntro();
    // Vizinhos já montados acompanham a aba escolhida, sem animar.
    if (!widget.active && widget.tab != _shown) {
      final t = widget.tab;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.active) return;
        _shown = t;
        _tabs.animateTo(t, duration: Duration.zero);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _fade.dispose();
    _intro.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Jogo da aventura; sem aventura, o jogo mais recente em que o Pokémon aparece; senão Scarlet/Violet.
  int _pickDefaultGame(int? adventureGame) {
    final dex = AppScope.read(context).dex;
    if (adventureGame != null && dex.versionGroupsById.containsKey(adventureGame)) return adventureGame;
    final games = dex.versionGroups.where((v) => v.isPlayable).toList()
      ..sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
    for (final g in games) {
      if (_isAvailable(g.id)) return g.id;
    }
    return dex.versionGroups.where((v) => v.identifier == 'scarlet-violet').firstOrNull?.id ?? games.first.id;
  }

  bool _isAvailable(int vgId) =>
      _available[vgId] ??= AppScope.read(context).dex.availableInGame(vgId).contains(entry.speciesId);

  void _startIntro() {
    if (_introStarted || !mounted) return;
    _introStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  void _onScroll() {
    final show = _scroll.offset > 260;
    if (show != _titleVisible) setState(() => _titleVisible = show);
  }

  Future<void> _onTab() async {
    final next = _tabs.index;
    if (next == _shown) return;
    if (widget.active) widget.onTab(next);
    if (MediaQuery.disableAnimationsOf(context)) {
      _keepTabsPinned();
      setState(() => _shown = next);
      return;
    }
    await _fade.animateTo(0, duration: Motion.short ~/ 2, curve: Curves.easeIn);
    if (!mounted) return;
    _keepTabsPinned();
    setState(() => _shown = _tabs.index);
    _fade.animateTo(1, duration: Motion.medium, curve: Motion.emphasized);
  }

  /// Ao trocar de aba com o topo recolhido, a nova aba começa logo abaixo das abas fixas.
  void _keepTabsPinned() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_scroll.hasClients) return;
    final h = box.size.height;
    if (_scroll.offset > h) _scroll.jumpTo(h);
  }

  void _openSpecimens() => _tabs.animateTo(4);

  Future<void> _pickGame() async {
    final picked = await pickGame(context, selected: _gameId, inDex: _isAvailable);
    if (picked != null && mounted) widget.onGame(picked);
  }

  Future<(List<LearnedMove>, VersionGroup?)> _learnsetFor(int vg) =>
      _learnsets[vg] ??= AppScope.read(context).dex.learnset(entry.pokemonId, vg);

  /// Versões do jogo base; as de DLC já vêm agregadas pelo repositório.
  Future<Map<Version, List<Encounter>>> _encountersFor(VersionGroup vg) => _encounters[vg.id] ??=
      AppScope.read(context).dex.encounters(entry.pokemonId, AppScope.read(context).dex.baseOf(vg.id).versions);

  Widget _tabSliver(VersionGroup game) => switch (_shown) {
        0 => AboutTab(entry: entry, game: game, detail: _detail, flavor: _flavor, intro: _intro),
        1 => SliverToBoxAdapter(
            child: EvolutionView(speciesId: entry.speciesId, pokemonId: entry.pokemonId, versionGroupId: game.id),
          ),
        2 => MovesTab(game: game, learnset: _learnsetFor(game.id)),
        3 => EncountersTab(game: game, encounters: _encountersFor(game)),
        _ => SpecimensTab(entry: entry),
      };

  @override
  Widget build(BuildContext context) {
    final dex = AppScope.of(context).dex;
    final game = dex.versionGroupsById[_gameId]!;
    final wash = TypeInks.of(entry.type1).wash(.10);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final text = Theme.of(context).textTheme;
    final available = _isAvailable(game.id);
    final formId = available ? dex.formInGame(game.id, entry.speciesId) : entry.pokemonId;
    final gameForm = formId == entry.pokemonId ? null : dex.byPokemonId[formId]?.name;

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: wash,
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: AnimatedOpacity(
            opacity: _titleVisible ? 1 : 0,
            duration: reduce ? Duration.zero : Motion.short,
            child: Text(entry.name, style: text.titleLarge),
          ),
          actions: [
            IconButton(
              tooltip: _shiny ? 'Ver cores normais' : 'Ver shiny',
              isSelected: _shiny,
              onPressed: () => setState(() => _shiny = !_shiny),
              icon: const Icon(Icons.auto_awesome_outlined, color: Ramp.n6),
              selectedIcon: const Icon(Icons.auto_awesome_rounded, color: Gold.text),
            ),
            const SizedBox(width: Space.xs),
          ],
        ),
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: _headerKey,
            child: DetailHeader(
              entry: entry,
              shiny: _shiny,
              game: game,
              inDex: available,
              gameForm: gameForm,
              onPickGame: _pickGame,
              onOpenSpecimens: _openSpecimens,
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabsHeader(
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter - 16),
              tabs: [for (final t in _tabLabels) Tab(text: t)],
            ),
          ),
        ),
        SliverFadeTransition(
          opacity: _fade,
          sliver: KeyedSubtree(key: ValueKey('tab-$_shown-${game.id}'), child: _tabSliver(game)),
        ),
        SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.xxxl)),
      ],
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: Ramp.paper, child: tabBar);

  @override
  bool shouldRebuild(_TabsHeader old) => old.tabBar != tabBar;
}
