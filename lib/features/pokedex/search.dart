/// Busca tolerante da Pokédex: número, prefixo, substring e erro de digitação.
library;

import 'dart:math' as math;

/// Faixas de relevância, da melhor para a pior.
abstract final class MatchTier {
  static const regionalNumber = 0;
  static const nationalNumber = 1;
  static const namePrefix = 2;
  static const wordPrefix = 3;
  static const contains = 4;
  static const fuzzy = 5;
  static const none = -1;
}

/// "25", "#025", "0025" → 25. Qualquer outra coisa → null.
int? parseDexNumber(String raw) {
  final m = RegExp(r'^#?\s*0*(\d{1,4})$').firstMatch(raw.trim());
  if (m == null) return null;
  final n = int.parse(m.group(1)!);
  return n == 0 ? null : n;
}

/// Erros tolerados para um termo: nada abaixo de 4 letras, 1 até 6, 2 a partir de 7.
int typoBudget(int length) {
  if (length < 4) return 0;
  if (length <= 6) return 1;
  return 2;
}

/// Distância de edição com transposição (OSA). Para quando passa de [max] e devolve max + 1.
int editDistance(String a, String b, {int max = 1 << 20}) {
  if (a == b) return 0;
  final la = a.length;
  final lb = b.length;
  if ((la - lb).abs() > max) return max + 1;
  if (la == 0) return lb;
  if (lb == 0) return la;
  var prev2 = List<int>.filled(lb + 1, 0);
  var prev = List<int>.generate(lb + 1, (j) => j);
  var cur = List<int>.filled(lb + 1, 0);
  for (var i = 1; i <= la; i++) {
    cur[0] = i;
    var rowMin = cur[0];
    final ca = a.codeUnitAt(i - 1);
    for (var j = 1; j <= lb; j++) {
      final cb = b.codeUnitAt(j - 1);
      final cost = ca == cb ? 0 : 1;
      var v = math.min(math.min(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + cost);
      if (i > 1 && j > 1 && ca == b.codeUnitAt(j - 2) && a.codeUnitAt(i - 2) == cb) {
        v = math.min(v, prev2[j - 2] + 1);
      }
      cur[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > max) return max + 1;
    final t = prev2;
    prev2 = prev;
    prev = cur;
    cur = t;
  }
  return prev[lb];
}

/// O termo bate com a palavra por erro de digitação: a palavra inteira ou o começo dela
/// (para quem ainda está digitando) fica dentro do orçamento de erros.
bool fuzzyWordMatch(String term, String word) {
  final budget = typoBudget(term.length);
  if (budget == 0) return false;
  if (editDistance(term, word, max: budget) <= budget) return true;
  if (word.length > term.length) {
    final head = word.substring(0, term.length);
    if (editDistance(term, head, max: budget) <= budget) return true;
  }
  return false;
}
