import 'package:flutter/material.dart';

import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/type_badge.dart';

/// Glifo do tipo num círculo lavado na própria cor. O nome vem no rótulo de acessibilidade
/// e no tooltip (toque longo), para a cor nunca ser a única pista.
class TypeDisc extends StatelessWidget {
  const TypeDisc(this.type, {super.key, this.size = 28});
  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = AppScope.read(context).dex.types[type]?.namePt ?? type;
    return Tooltip(
      message: name,
      excludeFromSemantics: true,
      child: Semantics(
        label: name,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: TypeInks.of(type).wash(.2), shape: BoxShape.circle),
          child: TypeIcon(type, size: size * .56),
        ),
      ),
    );
  }
}

/// Discos de tipo que quebram linha; "nenhum" quando a lista é vazia.
class TypeDiscWrap extends StatelessWidget {
  const TypeDiscWrap(this.types, {super.key});
  final List<String> types;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return SizedBox(
        height: 28,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('nenhum', style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }
    return Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [for (final t in types) TypeDisc(t)]);
  }
}
