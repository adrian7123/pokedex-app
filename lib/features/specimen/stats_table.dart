import 'package:flutter/material.dart';

import '../../core/data/labels.dart';
import '../../core/logic/stats_calc.dart';
import '../../core/theme/tokens.dart';
import '../detail/detail_common.dart';
import 'sheet_widgets.dart';

/// Limites de cada coluna da tabela de stats.
abstract final class StatLimits {
  static const statMin = 1;
  static const statMax = 999;
  static const evMax = 252;
  static const evTotal = 510;
  static const ivMax = 31;

  static bool statOk(int? v) => v == null || (v >= statMin && v <= statMax);
  static bool evOk(int? v) => v == null || v <= evMax;
  static bool ivOk(int? v) => v == null || v <= ivMax;
  static int evSum(List<int?> evs) => evs.fold(0, (a, b) => a + (b ?? 0));
}

enum StatColumn { seen, ev, iv }

/// Uma linha por stat: visto no jogo · EVs · IVs · faixa estimada de IV.
/// Lê na mesma ordem da tela de resumo do jogo, de cima para baixo.
class StatsTable extends StatelessWidget {
  const StatsTable({
    super.key,
    required this.seen,
    required this.evs,
    required this.ivs,
    required this.seenCtl,
    required this.evCtl,
    required this.ivCtl,
    required this.ranges,
    required this.onChanged,
  });

  final List<int?> seen;
  final List<int?> evs;
  final List<int?> ivs;
  final List<TextEditingController> seenCtl;
  final List<TextEditingController> evCtl;
  final List<TextEditingController> ivCtl;

  /// Faixas estimadas; null quando falta nível ou stat visto para estimar.
  final List<(int, int)?>? ranges;
  final void Function(StatColumn column, int index, int? value) onChanged;

  static const _field = 52.0;
  static const _gap = 6.0;
  static const _estimate = 52.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;
    final r = ranges;

    Widget head(String s, double w, {TextAlign align = TextAlign.center}) =>
        SizedBox(width: w, child: Text(s, style: text.labelMedium, textAlign: align));

    final rows = <Widget>[
      ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: Row(
            children: [
              const Spacer(),
              head('Visto', _field),
              const SizedBox(width: _gap),
              head('EVs', _field),
              const SizedBox(width: _gap),
              head('IVs', _field),
              if (r != null) ...[const SizedBox(width: _gap), head('Estim.', _estimate, align: TextAlign.right)],
            ],
          ),
        ),
      ),
    ];

    for (var i = 0; i < 6; i++) {
      final name = Labels.stats[i];
      final range = r?[i];
      final hasSeen = seen[i] != null;
      final iv = ivs[i];
      final mismatch = range != null && iv != null && (iv < range.$1 || iv > range.$2);
      final impossible = r != null && hasSeen && range == null;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs / 2),
          child: Row(
            children: [
              Expanded(child: Text(name, style: text.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
              SizedBox(
                width: _field,
                child: NumField(
                  controller: seenCtl[i],
                  semanticLabel: i == 0 ? '$name máximo visto' : '$name visto',
                  invalid: !StatLimits.statOk(seen[i]),
                  onChanged: (v) => onChanged(StatColumn.seen, i, v),
                ),
              ),
              const SizedBox(width: _gap),
              SizedBox(
                width: _field,
                child: NumField(
                  controller: evCtl[i],
                  semanticLabel: 'EVs de $name',
                  invalid: !StatLimits.evOk(evs[i]),
                  onChanged: (v) => onChanged(StatColumn.ev, i, v),
                ),
              ),
              const SizedBox(width: _gap),
              SizedBox(
                width: _field,
                child: NumField(
                  controller: ivCtl[i],
                  semanticLabel: 'IV de $name',
                  invalid: !StatLimits.ivOk(iv),
                  last: i == 5,
                  onChanged: (v) => onChanged(StatColumn.iv, i, v),
                ),
              ),
              if (r != null) ...[
                const SizedBox(width: _gap),
                SizedBox(
                  width: _estimate,
                  child: Semantics(
                    label: !hasSeen
                        ? 'sem estimativa de $name'
                        : impossible
                            ? 'nenhum IV explica o $name visto'
                            : 'IV estimado de $name: ${StatsCalc.label(range)}',
                    excludeSemantics: true,
                    child: Text(
                      hasSeen ? StatsCalc.label(range) : '—',
                      textAlign: TextAlign.right,
                      style: text.titleSmall?.copyWith(
                        color: impossible || mismatch ? error : (hasSeen ? Ramp.ink : Ramp.n4),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final evTotal = StatLimits.evSum(evs);
    final problems = [
      if (seen.any((v) => !StatLimits.statOk(v))) 'Stats vistos vão de 1 a 999.',
      if (evs.any((v) => !StatLimits.evOk(v))) 'EVs vão até 252 por stat.',
      if (ivs.any((v) => !StatLimits.ivOk(v))) 'IVs vão de 0 a 31.',
    ];
    final anyImpossible = r != null && [for (var i = 0; i < 6; i++) seen[i] != null && r[i] == null].any((x) => x);
    final anyMismatch = r != null &&
        [
          for (var i = 0; i < 6; i++)
            r[i] != null && ivs[i] != null && (ivs[i]! < r[i]!.$1 || ivs[i]! > r[i]!.$2),
        ].any((x) => x);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...rows,
        const SizedBox(height: Space.s),
        Text(
          'Total de EVs: $evTotal de ${StatLimits.evTotal}',
          style: text.bodySmall?.copyWith(color: evTotal > StatLimits.evTotal ? error : null),
        ),
        if (evTotal > StatLimits.evTotal)
          Text('Passou de ${StatLimits.evTotal}: o jogo não permite.', style: text.bodySmall?.copyWith(color: error)),
        if (problems.isNotEmpty)
          Text(
            problems.join(' '),
            style: text.bodySmall?.copyWith(color: error),
          ),
        const SizedBox(height: Space.s),
        if (r == null)
          const InfoNote('Informe o nível e os stats vistos para estimar os IVs.', icon: Icons.calculate_outlined)
        else ...[
          const InfoNote('Estimativa assume os EVs informados (0 se vazio).', icon: Icons.calculate_outlined),
          if (anyImpossible)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                '“?”: nenhum IV explica o valor visto. Confira natureza, EVs ou forma.',
                style: text.bodySmall?.copyWith(color: error),
              ),
            ),
          if (anyMismatch)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                'Algum IV informado está fora da faixa estimada (em vermelho).',
                style: text.bodySmall?.copyWith(color: error),
              ),
            ),
        ],
      ],
    );
  }
}
