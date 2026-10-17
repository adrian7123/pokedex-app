import 'package:flutter/material.dart';

import '../../app/navigation.dart';
import '../../app/shell.dart';
import '../../core/data/user_database.dart' show CustomList;
import '../../core/state/app_state.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import 'custom_list_screen.dart';
import 'lists_store.dart';
import 'species_row.dart';

enum _Segment { all, shiny, favorites }

/// Coleção global: todos os exemplares de todas as aventuras, mais as listas livres.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  _Segment _segment = _Segment.all;

  @override
  void initState() {
    super.initState();
    final saved = PageStorage.maybeOf(context)?.readState(context, identifier: 'collection-segment');
    if (saved is int && saved >= 0 && saved < _Segment.values.length) _segment = _Segment.values[saved];
  }

  void _select(_Segment s) {
    setState(() => _segment = s);
    PageStorage.maybeOf(context)?.writeState(context, s.index, identifier: 'collection-segment');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dex = state.dex;
    final text = Theme.of(context).textTheme;

    final specimens = state.allSpecimens.toList()..sort((a, b) => a.caughtAt.compareTo(b.caughtAt));
    final shinyCount = specimens.where((s) => s.isShiny).length;
    final adventureNames = {for (final a in state.adventures) a.id: a.name};

    // speciesId → aventuras de origem, na ordem da primeira captura.
    final origins = <int, List<String>>{};
    for (final s in specimens) {
      final name = s.adventureId == null ? 'Sem aventura' : (adventureNames[s.adventureId] ?? 'Sem aventura');
      final list = origins.putIfAbsent(s.speciesId, () => []);
      if (!list.contains(name)) list.add(name);
    }

    final Iterable<int> ids = switch (_segment) {
      _Segment.all => state.global.keys,
      _Segment.shiny => state.global.entries.where((e) => e.value.shiny).map((e) => e.key),
      _Segment.favorites => state.marks.entries.where((e) => e.value.favorite).map((e) => e.key),
    };
    final rows = [for (final id in ids) ?dex.defaultBySpecies[id]]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final siblings = [for (final e in rows) e.pokemonId];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const PageStorageKey('collection-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, Space.m),
              sliver: SliverToBoxAdapter(child: Text('Coleção', style: text.headlineMedium)),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              sliver: SliverToBoxAdapter(
                child: _Totals(
                  species: state.global.length,
                  of: dex.defaultBySpecies.length,
                  shiny: shinyCount,
                  specimens: specimens.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _ListsSection()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, Space.s),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Segment>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: _Segment.all, label: Text('Todos')),
                      ButtonSegment(value: _Segment.shiny, label: Text('Shiny')),
                      ButtonSegment(value: _Segment.favorites, label: Text('Favoritos')),
                    ],
                    selected: {_segment},
                    onSelectionChanged: (s) => _select(s.first),
                  ),
                ),
              ),
            ),
            if (rows.isEmpty)
              SliverToBoxAdapter(child: _EmptySegment(segment: _segment))
            else
              SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final e = rows[i];
                  final favorite = state.markOf(e.speciesId).favorite;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CollectionRow(
                        entry: e,
                        summary: state.global[e.speciesId] ?? CaptureSummary.none,
                        subtitle: _originLine(origins[e.speciesId]),
                        onTap: () => openDetail(context, e, siblings: siblings, initialTab: 4),
                        trailing: [_FavoriteButton(speciesId: e.speciesId, name: e.name, favorite: favorite)],
                      ),
                      if (i < rows.length - 1) const Perforation(indent: Space.gutter + 52 + Space.m),
                    ],
                  );
                },
              ),
            SliverToBoxAdapter(child: SizedBox(height: Space.xxxl + MediaQuery.paddingOf(context).bottom)),
          ],
        ),
      ),
    );
  }

  static String? _originLine(List<String>? names) {
    if (names == null || names.isEmpty) return null;
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2}';
  }
}

/// Totais como uma linha tipográfica: o número carrega o peso, a palavra fica leve.
class _Totals extends StatelessWidget {
  const _Totals({required this.species, required this.of, required this.shiny, required this.specimens});
  final int species;
  final int of;
  final int shiny;
  final int specimens;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final big = text.headlineMedium;
    final soft = text.headlineMedium?.copyWith(color: Ramp.n5, fontWeight: FontWeight.w700);
    final label = text.bodyMedium;
    Widget figure(List<InlineSpan> number, String word) => Text.rich(
      TextSpan(
        children: [
          ...number,
          TextSpan(text: ' $word', style: label),
        ],
      ),
    );
    return Wrap(
      spacing: Space.xl,
      runSpacing: Space.s,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        figure([TextSpan(text: '$species', style: big), TextSpan(text: '/$of', style: soft)], 'espécies carimbadas'),
        figure([
          TextSpan(
            text: '$shiny',
            style: big?.copyWith(color: Gold.text),
          ),
        ], 'shiny'),
        figure([TextSpan(text: '$specimens', style: big)], specimens == 1 ? 'exemplar' : 'exemplares'),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.speciesId, required this.name, required this.favorite});
  final int speciesId;
  final String name;
  final bool favorite;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: favorite ? 'Tirar $name dos favoritos' : 'Favoritar $name',
    isSelected: favorite,
    onPressed: () => AppScope.read(context).toggleFavorite(speciesId),
    icon: const Icon(Icons.star_outline_rounded, color: Ramp.n5),
    selectedIcon: const Icon(Icons.star_rounded, color: Gold.ink),
  );
}

class _EmptySegment extends StatelessWidget {
  const _EmptySegment({required this.segment});
  final _Segment segment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (title, body) = switch (segment) {
      _Segment.all => ('Nada carimbado ainda', 'Na Pokédex, toque no anel de um Pokémon para carimbar. Toque longo carimba shiny.'),
      _Segment.shiny => ('Nenhum shiny ainda', 'Toque longo no anel de um Pokémon carimba em ouro.'),
      _Segment.favorites => ('Nenhum favorito', 'Toque na estrela de um Pokémon da coleção para guardá-lo aqui.'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(body, style: text.bodyMedium),
          if (segment != _Segment.favorites) ...[
            const SizedBox(height: Space.l),
            OutlinedButton(onPressed: () => Shell.goTo(context, 0), child: const Text('Abrir a Pokédex')),
          ],
        ],
      ),
    );
  }
}

/// "Minhas listas": listas livres com contagem, criar e abrir.
class _ListsSection extends StatefulWidget {
  const _ListsSection();

  @override
  State<_ListsSection> createState() => _ListsSectionState();
}

class _ListsSectionState extends State<_ListsSection> {
  late final ListsStore _store = ListsStore(AppScope.read(context).user);
  late final Stream<List<CustomList>> _lists = _store.watchLists();
  late final Stream<Map<String, int>> _counts = _store.watchCounts();

  Future<void> _create() async {
    final name = await askListName(context, title: 'Nova lista', action: 'Criar');
    if (name == null || !mounted) return;
    final id = await _store.create(name);
    if (!mounted) return;
    await openCustomList(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<CustomList>>(
      stream: _lists,
      builder: (context, listsSnap) => StreamBuilder<Map<String, int>>(
        stream: _counts,
        builder: (context, countsSnap) {
          final lists = listsSnap.data ?? const <CustomList>[];
          final counts = countsSnap.data ?? const <String, int>{};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.s, 0),
                child: Row(
                  children: [
                    Expanded(child: Text('Minhas listas', style: text.titleLarge)),
                    TextButton.icon(onPressed: _create, icon: const Icon(Icons.add_rounded, size: 20), label: const Text('Nova lista')),
                  ],
                ),
              ),
              if (listsSnap.hasData && lists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  child: Text('Monte listas livres: time dos sonhos, trocas pendentes, o que caçar.', style: text.bodyMedium),
                ),
              for (var i = 0; i < lists.length; i++) ...[
                if (i > 0) const Perforation(indent: Space.gutter + 40 + Space.m),
                _ListRow(list: lists[i], count: counts[lists[i].id] ?? 0),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.list, required this.count});
  final CustomList list;
  final int count;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => openCustomList(context, list.id),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.s, Space.gutter - Space.xs, Space.s),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Ramp.n1, shape: BoxShape.circle),
              child: const Icon(Icons.format_list_bulleted_rounded, size: 20, color: Ramp.n6),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(list.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('$count Pokémon', style: text.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Ramp.n5),
          ],
        ),
      ),
    );
  }
}
