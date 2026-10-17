import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';

/// Sprite embutido (96px) de uma variedade. Cai para o padrão da espécie quando falta arquivo.
class PokemonSprite extends StatelessWidget {
  const PokemonSprite(this.entry, {super.key, this.shiny = false, this.size});
  final DexEntry entry;
  final bool shiny;
  final double? size;

  @override
  Widget build(BuildContext context) => Image.asset(
        entry.spritePath(shiny: shiny),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Icon(Icons.catching_pokemon, color: Ramp.n3, size: (size ?? 40) * .6),
      );
}

/// Separador de picote: a cartela não tem caixas, só pontilhado.
class Perforation extends StatelessWidget {
  const Perforation({super.key, this.indent = 0});
  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent),
        child: CustomPaint(size: const Size(double.infinity, 2), painter: _Dots()),
      );
}

class _Dots extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Ramp.n3;
    for (var x = 1.0; x < size.width; x += 6) {
      canvas.drawCircle(Offset(x, 1), 1, p);
    }
  }

  @override
  bool shouldRepaint(_Dots oldDelegate) => false;
}
