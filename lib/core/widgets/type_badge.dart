import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../state/scope.dart';
import '../theme/tokens.dart';

/// Glifo do tipo tingido com a tinta do tipo (ou outra cor).
class TypeIcon extends StatelessWidget {
  const TypeIcon(this.type, {super.key, this.size = 16, this.color});
  final String type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/types/$type.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color ?? TypeInks.of(type).ink, BlendMode.srcIn),
        excludeFromSemantics: true,
      );
}

/// Tipo na lista: ponto de tinta + nome. Cor nunca sozinha: sempre com o nome.
class TypeDot extends StatelessWidget {
  const TypeDot(this.type, {super.key});
  final String type;

  @override
  Widget build(BuildContext context) {
    final name = AppScope.read(context).dex.types[type]?.namePt ?? type;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: TypeInks.of(type).ink, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Tipo em destaque (detalhe, golpes, tabela): pílula lavada com glifo e nome na cor de texto do tipo.
class TypePill extends StatelessWidget {
  const TypePill(this.type, {super.key, this.dense = false, this.onTap});
  final String type;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = TypeInks.of(type);
    final name = AppScope.read(context).dex.types[type]?.namePt ?? type;
    final pill = Container(
      height: dense ? 26 : 32,
      padding: EdgeInsets.symmetric(horizontal: dense ? Space.s : Space.m),
      decoration: BoxDecoration(color: ink.wash(.16), borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TypeIcon(type, size: dense ? 13 : 16),
          SizedBox(width: dense ? 5 : 6),
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ink.text),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(Radii.pill), child: pill);
  }
}
