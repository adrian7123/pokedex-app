import '../data/models.dart';

/// Fórmulas de stats das gerações 3+ (iguais em Scarlet/Violet).
abstract final class StatsCalc {
  /// Valor do stat [i] (0 = PS) para base, IV, EV, nível e natureza.
  static int value(int i, int base, int iv, int ev, int level, Nature? nature) {
    final core = ((2 * base + iv + ev ~/ 4) * level) ~/ 100;
    if (i == 0) return base == 1 ? 1 : core + level + 10; // Shedinja tem sempre 1 PS
    final v = core + 5;
    return nature == null ? v : (v * nature.factor(i)).floor();
  }

  /// Faixa de IVs (0–31) compatível com o stat visto. Sem EVs informados assume 0.
  /// Devolve null quando nenhum IV explica o valor (EVs altos, natureza errada, forma errada).
  static (int, int)? ivRange(int i, int observed, int base, int level, {int ev = 0, Nature? nature}) {
    int? lo;
    int? hi;
    for (var iv = 0; iv <= 31; iv++) {
      if (value(i, base, iv, ev, level, nature) == observed) {
        lo ??= iv;
        hi = iv;
      }
    }
    return lo == null ? null : (lo, hi!);
  }

  /// Faixas dos 6 stats; posições sem stat visto ficam null.
  static List<(int, int)?> ivRanges(DexEntry entry, int level, List<int?> observed, {List<int?>? evs, Nature? nature}) => [
        for (var i = 0; i < 6; i++)
          observed[i] == null
              ? null
              : ivRange(i, observed[i]!, entry.stats[i], level, ev: evs?[i] ?? 0, nature: nature),
      ];

  /// Rótulo curto de uma faixa: "31", "28–31", "?".
  static String label((int, int)? r) => r == null ? '?' : (r.$1 == r.$2 ? '${r.$1}' : '${r.$1}–${r.$2}');
}
