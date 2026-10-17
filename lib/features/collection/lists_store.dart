import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/data/user_database.dart';

/// Listas livres (CustomLists / CustomListItems) direto no banco do usuário.
class ListsStore {
  const ListsStore(this.db);
  final UserDatabase db;
  static const _uuid = Uuid();

  Stream<List<CustomList>> watchLists() =>
      (db.select(db.customLists)..orderBy([(l) => OrderingTerm.asc(l.createdAt)])).watch();

  Stream<CustomList?> watchList(String id) =>
      (db.select(db.customLists)..where((l) => l.id.equals(id))).watchSingleOrNull();

  /// listId → quantidade de Pokémon.
  Stream<Map<String, int>> watchCounts() => db
      .customSelect(
        'SELECT list_id, COUNT(*) AS n FROM custom_list_items GROUP BY list_id',
        readsFrom: {db.customListItems},
      )
      .watch()
      .map((rows) => {for (final r in rows) r.read<String>('list_id'): r.read<int>('n')});

  Stream<List<CustomListItem>> watchItems(String listId) => (db.select(db.customListItems)
        ..where((i) => i.listId.equals(listId))
        ..orderBy([(i) => OrderingTerm.asc(i.position)]))
      .watch();

  Future<String> create(String name) async {
    final id = _uuid.v4();
    await db.into(db.customLists).insert(CustomListsCompanion.insert(id: id, name: name, createdAt: DateTime.now()));
    return id;
  }

  Future<void> rename(String id, String name) =>
      (db.update(db.customLists)..where((l) => l.id.equals(id))).write(CustomListsCompanion(name: Value(name)));

  /// Os itens saem junto (cascade).
  Future<void> delete(String id) => (db.delete(db.customLists)..where((l) => l.id.equals(id))).go();

  Future<void> add(String listId, int pokemonId) async {
    final row = await db.customSelect(
      'SELECT COALESCE(MAX(position), 0) AS p FROM custom_list_items WHERE list_id = ?',
      variables: [Variable.withString(listId)],
      readsFrom: {db.customListItems},
    ).getSingle();
    await db.into(db.customListItems).insertOnConflictUpdate(
          CustomListItemsCompanion.insert(listId: listId, pokemonId: pokemonId, position: row.read<int>('p') + 1),
        );
  }

  Future<void> remove(String listId, int pokemonId) =>
      (db.delete(db.customListItems)..where((i) => i.listId.equals(listId) & i.pokemonId.equals(pokemonId))).go();

  Future<void> restore(CustomListItem item) => db.into(db.customListItems).insertOnConflictUpdate(item);
}
