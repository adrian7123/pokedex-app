import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Selo redondo do cartucho: sigla em tinta sobre o neutro claro. Ativa ganha anel de tinta.
class GameSeal extends StatelessWidget {
  const GameSeal({super.key, required this.code, this.active = false, this.icon, this.size = 52});
  final String code;
  final bool active;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.3);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Ramp.n1,
          shape: BoxShape.circle,
          border: Border.all(color: active ? Ramp.ink : Ramp.n2, width: active ? 2 : 1),
        ),
        child: icon != null
            ? Icon(icon, size: size * .44, color: Ramp.n6)
            : Text(code, maxLines: 1, style: style, textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4)),
      ),
    );
  }
}
