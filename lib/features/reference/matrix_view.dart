import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/type_badge.dart';

/// Matriz 18×18 (atacante nas linhas, defensor nas colunas) que cabe na largura do celular.
/// O resultado aparece ao tocar (ou arrastar com toque longo) numa casa.
class MatrixView extends StatefulWidget {
  const MatrixView({super.key, required this.types});
  final List<String> types;

  @override
  State<MatrixView> createState() => _MatrixViewState();
}

class _MatrixViewState extends State<MatrixView> {
  (int, int)? _sel;

  void _pick(Offset local, double cell) {
    final n = widget.types.length;
    final col = (local.dx / cell).floor();
    final row = (local.dy / cell).floor();
    if (row < 0 || col < 0 || row >= n || col >= n) return;
    if (_sel == (row, col)) return;
    HapticFeedback.selectionClick();
    setState(() => _sel = (row, col));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dex = AppScope.of(context).dex;
    final types = widget.types;
    final n = types.length;
    String nameOf(String t) => dex.types[t]?.namePt ?? t;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('↓ Linhas: tipo do golpe     → Colunas: tipo de quem leva o golpe', style: text.titleSmall),
          const SizedBox(height: Space.m),
          LayoutBuilder(
            builder: (context, box) {
              final cell = (box.maxWidth / (n + 1)).floorToDouble().clamp(12.0, 32.0);
              final sel = _sel;
              Widget header(int i, {required bool isRow}) {
                final active = sel != null && (isRow ? sel.$1 == i : sel.$2 == i);
                final t = types[i];
                return Container(
                  width: cell,
                  height: cell,
                  alignment: Alignment.center,
                  decoration: active ? BoxDecoration(color: TypeInks.of(t).wash(.3), shape: BoxShape.circle) : null,
                  child: Opacity(
                    opacity: sel == null || active ? 1 : .45,
                    child: TypeIcon(t, size: cell * .68),
                  ),
                );
              }

              return SizedBox(
                width: cell * (n + 1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox.square(dimension: cell),
                        for (var j = 0; j < n; j++) header(j, isRow: false),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(children: [for (var i = 0; i < n; i++) header(i, isRow: true)]),
                        Semantics(
                          label: 'Tabela de tipos. Toque numa casa para ver o resultado.',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (d) => _pick(d.localPosition, cell),
                            onLongPressStart: (d) => _pick(d.localPosition, cell),
                            onLongPressMoveUpdate: (d) => _pick(d.localPosition, cell),
                            child: CustomPaint(
                              size: Size.square(cell * n),
                              painter: _MatrixPainter(types: types, efficacy: dex.efficacy, cell: cell, selected: sel),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Space.l),
          _Readout(sel: _sel, types: types, nameOf: nameOf),
          const SizedBox(height: Space.xl),
          const _Legend(),
        ],
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({required this.sel, required this.types, required this.nameOf});
  final (int, int)? sel;
  final List<String> types;
  final String Function(String) nameOf;

  static String factorLabel(int f) => switch (f) {
    0 => '0×',
    50 => '½×',
    200 => '2×',
    _ => '1×',
  };

  static String factorWord(int f) => switch (f) {
    0 => 'não causa dano',
    50 => 'metade do dano',
    200 => 'dano dobrado',
    _ => 'dano normal',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = sel;
    if (s == null) {
      return SizedBox(
        height: 64,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Toque numa casa da tabela para ver o resultado.', style: text.bodyMedium),
        ),
      );
    }
    final atk = types[s.$1];
    final def = types[s.$2];
    final f = AppScope.of(context).dex.efficacy[atk]?[def] ?? 100;
    TextSpan typeName(String t) => TextSpan(
      text: nameOf(t),
      style: text.titleMedium?.copyWith(color: TypeInks.of(t).text),
    );
    return Semantics(
      liveRegion: true,
      label: 'Golpe tipo ${nameOf(atk)} em Pokémon tipo ${nameOf(def)}: ${factorLabel(f)}, ${factorWord(f)}',
      excludeSemantics: true,
      child: SizedBox(
        height: 64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                style: text.bodyMedium,
                children: [const TextSpan(text: 'Golpe tipo '), typeName(atk), const TextSpan(text: ' em Pokémon tipo '), typeName(def)],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Space.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(factorLabel(f), style: text.headlineMedium?.copyWith(height: 1)),
                const SizedBox(width: Space.s),
                Flexible(child: Text(factorWord(f), style: text.titleSmall, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget item(int factor, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size.square(18),
          painter: _CellPainter(factor: factor, ink: TypeInks.of('fire').ink),
        ),
        const SizedBox(width: Space.s),
        Text(label, style: style),
      ],
    );
    return Wrap(
      spacing: Space.l,
      runSpacing: Space.s,
      children: [
        item(200, '2× dano dobrado (na cor do golpe)'),
        item(100, '1× dano normal'),
        item(50, '½× metade do dano'),
        item(0, '0× não causa dano'),
      ],
    );
  }
}

/// Uma célula: 2× tinta cheia do atacante, ½× ponto neutro, 0× tinta preta, 1× casa vazia.
/// Forma e cor juntas, para a leitura não depender só da cor.
void _paintCell(Canvas canvas, Rect r, int factor, Color ink) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width * .18));
  switch (factor) {
    case 200:
      canvas.drawRRect(rr, Paint()..color = ink);
    case 0:
      canvas.drawRRect(rr, Paint()..color = Ramp.ink);
    case 50:
      canvas.drawRRect(rr, Paint()..color = Ramp.n1);
      canvas.drawCircle(r.center, r.width * .2, Paint()..color = Ramp.n5);
    default:
      canvas.drawRRect(rr, Paint()..color = Ramp.n1);
  }
}

class _CellPainter extends CustomPainter {
  _CellPainter({required this.factor, required this.ink});
  final int factor;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) => _paintCell(canvas, Offset.zero & size, factor, ink);

  @override
  bool shouldRepaint(_CellPainter old) => old.factor != factor || old.ink != ink;
}

class _MatrixPainter extends CustomPainter {
  _MatrixPainter({required this.types, required this.efficacy, required this.cell, required this.selected});
  final List<String> types;
  final Map<String, Map<String, int>> efficacy;
  final double cell;
  final (int, int)? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final n = types.length;
    const gap = 1.0;
    for (var i = 0; i < n; i++) {
      final atk = types[i];
      final ink = TypeInks.of(atk).ink;
      for (var j = 0; j < n; j++) {
        final f = efficacy[atk]?[types[j]] ?? 100;
        final r = Rect.fromLTWH(j * cell + gap / 2, i * cell + gap / 2, cell - gap, cell - gap);
        _paintCell(canvas, r, f, ink);
      }
    }
    final s = selected;
    if (s == null) return;

    // Fora da cruz selecionada, o papel cobre parcialmente: linha e coluna saltam.
    final veil = Paint()..color = Ramp.paper.withValues(alpha: .62);
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (i == s.$1 || j == s.$2) continue;
        canvas.drawRect(Rect.fromLTWH(j * cell, i * cell, cell, cell), veil);
      }
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Ramp.n6;
    canvas.drawRect(Rect.fromLTWH(0, s.$1 * cell, n * cell, cell), line);
    canvas.drawRect(Rect.fromLTWH(s.$2 * cell, 0, cell, n * cell), line);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s.$2 * cell - 1.5, s.$1 * cell - 1.5, cell + 3, cell + 3), Radius.circular(cell * .24)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Ramp.ink,
    );
  }

  @override
  bool shouldRepaint(_MatrixPainter old) => old.selected != selected || old.cell != cell || old.types != types;
}
