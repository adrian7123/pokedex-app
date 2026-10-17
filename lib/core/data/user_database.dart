import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'user_database.g.dart';

/// Uma aventura: um save de um jogo específico.
class Adventures extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// version_groups.id do banco de referência (jogo base, nunca DLC).
  IntColumn get versionGroupId => integer()();

  /// versions.id (cartucho: FireRed ou LeafGreen); define encontros e exclusivos.
  IntColumn get versionId => integer().nullable()();
  BoolColumn get isNuzlocke => boolean().withDefault(const Constant(false))();
  TextColumn get nuzlockeRules => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Um exemplar capturado. Sem aventura = "Sem aventura".
class Specimens extends Table {
  TextColumn get id => text()();
  TextColumn get adventureId => text().nullable().references(Adventures, #id, onDelete: KeyAction.cascade)();
  IntColumn get speciesId => integer()();
  IntColumn get pokemonId => integer()();
  BoolColumn get isShiny => boolean().withDefault(const Constant(false))();
  TextColumn get nickname => text().nullable()();
  IntColumn get level => integer().nullable()();
  TextColumn get nature => text().nullable()();
  IntColumn get abilityId => integer().nullable()();

  /// 'm', 'f' ou null
  TextColumn get gender => text().nullable()();
  IntColumn get ballItemId => integer().nullable()();
  TextColumn get caughtWhere => text().nullable()();
  IntColumn get heldItemId => integer().nullable()();

  /// "hp,atk,def,spa,spd,spe"; null quando não informado.
  TextColumn get ivs => text().nullable()();
  TextColumn get evs => text().nullable()();

  /// Até 4 move ids separados por vírgula.
  TextColumn get moves => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Posição no time (1–6) da aventura; null fora do time.
  IntColumn get teamSlot => integer().nullable()();

  /// Nuzlocke: false = no cemitério.
  BoolColumn get isAlive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get caughtAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Marcas globais por espécie: favorito e símbolos livres.
class SpeciesMarks extends Table {
  IntColumn get speciesId => integer()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();

  /// Bits: 1 estrela, 2 círculo, 4 triângulo, 8 quadrado, 16 coração, 32 losango.
  IntColumn get marks => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {speciesId};
}

class CustomLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CustomListItems extends Table {
  TextColumn get listId => text().references(CustomLists, #id, onDelete: KeyAction.cascade)();
  IntColumn get pokemonId => integer()();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {listId, pokemonId};
}

/// Nuzlocke: primeiro encontro por local.
class NuzlockeEncounters extends Table {
  TextColumn get id => text()();
  TextColumn get adventureId => text().references(Adventures, #id, onDelete: KeyAction.cascade)();

  /// location_areas.id ou locations.id do banco de referência; null quando é texto livre.
  IntColumn get locationAreaId => integer().nullable()();
  TextColumn get locationLabel => text()();
  IntColumn get speciesId => integer().nullable()();
  TextColumn get specimenId => text().nullable()();

  /// caught / fainted / fled / skipped
  TextColumn get outcome => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Preferências simples (aventura ativa, modo da lista...).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Adventures, Specimens, SpeciesMarks, CustomLists, CustomListItems, NuzlockeEncounters, Settings])
class UserDatabase extends _$UserDatabase {
  UserDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'user'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX specimens_species ON specimens (species_id)');
          await customStatement('CREATE INDEX specimens_adventure ON specimens (adventure_id)');
        },
        beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
      );
}
