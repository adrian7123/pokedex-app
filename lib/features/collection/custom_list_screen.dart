import 'package:flutter/material.dart';

import '../../app/navigation.dart';
import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/data/user_database.dart' show CustomList, CustomListItem;
import '../../core/state/app_state.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/type_badge.dart';
import 'lists_store.dart';
import 'species_row.dart';

Future<void> openCustomList(BuildContext context, String listId) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CustomListScreen(listId: listId)));

/// Diálogo de nome de lista. Devolve o nome aparado, ou null se cancelado.
Future<String?> askListName(BuildContext context, {required String title, required String action, String initial = ''}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(title: title, action: action, initial: initial),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.action, required this.initial});
  final String title;
  final String action;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final valid = _controller.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Nome da lista'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: valid ? _submit : null, child: Text(widget.action)),
      ],
    );
  }
}

/// Uma lista livre: os Pokémon na ordem em que entraram.
class CustomListScreen extends StatefulWidget {
  const CustomListScreen({super.key, required this.listId});
  final String listId;

  @override
  State<CustomListScreen> createState() => _CustomListScreenState();
}

class _CustomListScreenState extends State<CustomListScreen> {
  late final ListsStore _store = ListsStore(AppScope.read(context).user);
  late final Stream<CustomList?> _list = _store.watchList(widget.listId);
  late final Stream<List<CustomListItem>> _items = _store.watchItems(widget.listId);
  List<CustomListItem> _current = const [];
  String _name = '';

  Future<void> _rename() async {
    final name = await askListName(context, title: 'Renomear lista', action: 'Salvar', initial: _name);
    if (name == null) return;
    await _store.rename(widget.listId, name);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir “$_name”?'),
        content: const Text('A lista some; seus exemplares e carimbos continuam onde estão.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.of(context).pop();
    await _store.delete(widget.listId);
  }

  Future<void> _remove(CustomListItem item, DexEntry entry) async {
    await _store.remove(item.listId, item.pokemonId);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text('${entry.name} saiu da lista'),
          action: SnackBarAction(label: 'Desfazer', onPressed: () => _store.restore(item)),
        ),
      );
  }

  Future<void> _add() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PickerSheet(store: _store, listId: widget.listId, initial: {for (final i in _current) i.pokemonId}),
  );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return StreamBuilder<CustomList?>(
      stream: _list,
      builder: (context, listSnap) {
        _name = listSnap.data?.name ?? _name;
        return Scaffold(
          appBar: AppBar(
            title: Text(_name),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Mais opções',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) => v == 'rename' ? _rename() : _delete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Renomear')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir lista')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            elevation: 0,
            highlightElevation: 0,
            backgroundColor: Ramp.ink,
            foregroundColor: Ramp.paper,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar Pokémon'),
          ),
          body: StreamBuilder<List<CustomListItem>>(
            stream: _items,
            builder: (context, snap) {
              _current = snap.data ?? const [];
              if (!snap.hasData) return const SizedBox.shrink();
              final rows = [
                for (final item in _current)
                  if (state.dex.byPokemonId[item.pokemonId] case final e?) (item, e),
              ];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lista vazia', style: text.titleLarge),
                      const SizedBox(height: Space.xs),
                      Text('Busque por nome ou número para adicionar Pokémon a esta lista.', style: text.bodyMedium),
                    ],
                  ),
                );
              }
              final siblings = [for (final r in rows) r.$2.pokemonId];
              return ListView.builder(
                padding: EdgeInsets.only(top: Space.s, bottom: 96 + bottom),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final (item, e) = rows[i];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CollectionRow(
                        entry: e,
                        summary: state.global[e.speciesId] ?? CaptureSummary.none,
                        subtitle: e.isDefault ? null : e.formName,
                        onTap: () => openDetail(context, e, siblings: siblings),
                        hero: false,
                        trailing: [
                          IconButton(
                            tooltip: 'Remover ${e.name} da lista',
                            onPressed: () => _remove(item, e),
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: Ramp.n6),
                          ),
                        ],
                      ),
                      if (i < rows.length - 1) const Perforation(indent: Space.gutter + 52 + Space.m),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Busca simples para adicionar/remover Pokémon da lista sem sair da folha.
class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.store, required this.listId, required this.initial});
  final ListsStore store;
  final String listId;
  final Set<int> initial;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late final Set<int> _members = {...widget.initial};
  String _query = '';

  List<DexEntry> _results(List<DexEntry> entries) {
    final q = DexEntry.normalize(_query);
    if (q.isEmpty) return const [];
    final n = int.tryParse(q.replaceAll('#', ''));
    final out = <DexEntry>[];
    for (final e in entries) {
      if (n != null ? e.speciesId == n : e.searchKey.contains(q)) {
        out.add(e);
        if (out.length == 40) break;
      }
    }
    return out;
  }

  Future<void> _toggle(DexEntry e) async {
    final inList = _members.contains(e.pokemonId);
    setState(() => inList ? _members.remove(e.pokemonId) : _members.add(e.pokemonId));
    if (inList) {
      await widget.store.remove(widget.listId, e.pokemonId);
    } else {
      await widget.store.add(widget.listId, e.pokemonId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dex = AppScope.read(context).dex;
    final results = _results(dex.entries);
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * .82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.m),
              child: Text('Adicionar à lista', style: text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: TextField(
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Nome ou número',
                  prefixIcon: Icon(Icons.search_rounded, color: Ramp.n6),
                ),
              ),
            ),
            const SizedBox(height: Space.s),
            Expanded(
              child: _query.trim().isEmpty
                  ? const SizedBox.shrink()
                  : results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Space.gutter),
                      child: Text('Nenhum Pokémon com esse nome ou número.', style: text.bodyMedium),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: Space.l + media.padding.bottom),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final e = results[i];
                        final inList = _members.contains(e.pokemonId);
                        return InkWell(
                          onTap: () => _toggle(e),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.xs),
                            child: Row(
                              children: [
                                SizedBox.square(dimension: 48, child: PokemonSprite(e, size: 48)),
                                const SizedBox(width: Space.m),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(e.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Wrap(
                                        spacing: Space.m,
                                        children: [
                                          Text(Labels.dexNumber(e.nationalNumber), style: text.bodySmall),
                                          for (final t in e.types) TypeDot(t),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label: inList ? 'Na lista' : 'Fora da lista',
                                  child: Icon(
                                    inList ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                    color: inList ? Ramp.ink : Ramp.n5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
