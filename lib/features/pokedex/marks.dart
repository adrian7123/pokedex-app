import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pokedex_controller.dart';

/// Ícone de favorito da espécie (o coração fica para a marca "coração").
const favoriteIcon = Icons.bookmark_rounded;

/// Glifo de uma marca livre, em traço como as marcas da caixa do jogo.
class MarkGlyph extends StatelessWidget {
  const MarkGlyph(this.mark, {super.key, this.size = 16, this.color});
  final SpeciesMarkBit mark;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mark) {
      SpeciesMarkBit.star => Icons.star_outline_rounded,
      SpeciesMarkBit.circle => Icons.circle_outlined,
      SpeciesMarkBit.triangle => Icons.change_history_rounded,
      SpeciesMarkBit.square => Icons.crop_square_rounded,
      SpeciesMarkBit.heart => Icons.favorite_border_rounded,
      SpeciesMarkBit.diamond => Icons.crop_square_rounded,
    };
    final glyph = Icon(icon, size: mark == SpeciesMarkBit.diamond ? size * .82 : size, color: color);
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: mark == SpeciesMarkBit.diamond ? Transform.rotate(angle: math.pi / 4, child: glyph) : glyph,
      ),
    );
  }
}
