/// Campos lidos de uma ou mais páginas do resumo, com confiança e origem.
library;

import 'package:flutter/foundation.dart';

enum Confidence { low, high }

/// Chaves dos campos. Batem com os nomes de [SpecimenDraft] para a ficha destacar o que veio da foto.
abstract final class F {
  static const pokemonId = 'pokemonId';
  static const nickname = 'nickname';
  static const level = 'level';
  static const gender = 'gender';
  static const isShiny = 'isShiny';
  static const nature = 'nature';
  static const abilityId = 'abilityId';
  static const heldItemId = 'heldItemId';
  static const ballItemId = 'ballItemId';
  static const teraType = 'teraType';
  static const caughtWhere = 'caughtWhere';
  static const moves = 'moves';
  static const stats = 'stats';
  static const ivs = 'ivs';

  /// Internos (não vão para a ficha).
  static const name = '_name';
  static const dexNumber = '_dexNumber';
  static const currentHp = '_currentHp';
  static String stat(int i) => 'stat$i';
}

/// Um valor lido. [page] é o índice da foto (0 = primeira).
@immutable
class Reading<T extends Object> {
  const Reading(this.value, this.confidence, {this.page = 0});
  final T value;
  final Confidence confidence;
  final int page;

  bool get isHigh => confidence == Confidence.high;
  Reading<T> onPage(int p) => Reading(value, confidence, page: p);
  Reading<T> withConfidence(Confidence c) => Reading(value, c, page: page);

  bool sameValue(Reading<Object> other) => valueEquals(value, other.value);
}

bool valueEquals(Object a, Object b) => (a is List && b is List) ? listEquals(a, b) : a == b;

/// O que uma foto rendeu: campos + geometria para as dicas de imagem.
class PageFields {
  final fields = <String, Reading<Object>>{};

  /// Linhas lidas (para a mensagem de falha e depuração).
  int lineCount = 0;

  void put(String key, Object value, Confidence c) => fields[key] = Reading(value, c);

  bool get isEmpty => fields.isEmpty;
}

/// Leitura somada das páginas: um valor escolhido por campo e os conflitos para o usuário decidir.
class MergedReading {
  MergedReading(List<PageFields> pages) {
    for (var p = 0; p < pages.length; p++) {
      pages[p].fields.forEach((key, r) => _add(key, r.onPage(p)));
    }
  }

  final chosen = <String, Reading<Object>>{};

  /// Campo → opções diferentes com a mesma força. Ao escolher, o conflito some.
  final conflicts = <String, List<Reading<Object>>>{};

  void _add(String key, Reading<Object> r) {
    final open = conflicts[key];
    if (open != null) {
      final same = open.indexWhere((o) => o.sameValue(r));
      if (same >= 0) {
        if (r.isHigh && !open[same].isHigh) open[same] = r;
        return;
      }
      if (r.isHigh && open.every((o) => !o.isHigh)) {
        conflicts.remove(key);
        chosen[key] = r;
      } else if (r.isHigh || open.every((o) => !o.isHigh)) {
        open.add(r);
      }
      return;
    }
    final cur = chosen[key];
    if (cur == null) {
      chosen[key] = r;
    } else if (cur.sameValue(r)) {
      if (r.isHigh && !cur.isHigh) chosen[key] = r;
    } else if (r.isHigh && !cur.isHigh) {
      chosen[key] = r;
    } else if (r.isHigh == cur.isHigh) {
      chosen.remove(key);
      conflicts[key] = [cur, r];
    }
  }

  void choose(String key, Reading<Object> r) {
    conflicts.remove(key);
    chosen[key] = r.withConfidence(Confidence.high);
  }

  T? value<T extends Object>(String key) {
    final v = chosen[key]?.value;
    return v is T ? v : null;
  }

  bool isLow(String key) => chosen[key] != null && !chosen[key]!.isHigh;

  bool get isEmpty => chosen.isEmpty && conflicts.isEmpty;
}
