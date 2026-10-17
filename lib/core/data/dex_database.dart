import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dex_asset.dart';

/// Banco de referência embutido (assets/db/pokedex.sqlite), aberto somente leitura.
///
/// O asset é copiado para o diretório de suporte do app na primeira execução e sempre que
/// [kDexAssetBuiltAt] mudar (novo build do banco numa atualização do app). Os dados do
/// usuário ficam em outro arquivo, então a troca não toca neles.
class DexDatabase extends GeneratedDatabase {
  DexDatabase._(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  // Sem PRAGMA query_only: o Drift grava o user_version depois do beforeOpen ao abrir.
  // A cópia local é descartável (recopiada do asset) e só recebe SELECTs via [rows].
  MigrationStrategy get migration => MigrationStrategy(onCreate: (_) async {}, onUpgrade: (_, _, _) async {});

  static Future<DexDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'pokedex.sqlite'));
    final marker = File(p.join(dir.path, 'pokedex.built_at'));
    final current = await marker.exists() ? (await marker.readAsString()).trim() : null;
    if (!await file.exists() || current != kDexAssetBuiltAt) {
      final data = await rootBundle.load('assets/db/pokedex.sqlite');
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      await tmp.rename(file.path);
      await marker.writeAsString(kDexAssetBuiltAt);
    }
    final executor = NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA temp_store = MEMORY'),
    );
    return DexDatabase._(executor);
  }

  Future<List<QueryRow>> rows(String sql, [List<Object?> args = const []]) =>
      customSelect(sql, variables: [for (final a in args) Variable(a)]).get();
}

extension QueryRowX on QueryRow {
  int i(String k) => data[k] as int;
  int? ni(String k) => data[k] as int?;
  String s(String k) => data[k] as String;
  String? ns(String k) => data[k] as String?;
  bool b(String k) => (data[k] as int? ?? 0) == 1;
}
