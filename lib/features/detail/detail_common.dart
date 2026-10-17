import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Entrada de uma seção: aparece com leve subida, escalonada por [index], uma vez por página.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.animation, required this.index, required this.child});
  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * .12).clamp(0.0, .5);
    final curve = Interval(start, start + .5, curve: Motion.emphasized);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = curve.transform(animation.value);
        if (t >= 1) return child!;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
        );
      },
      child: child,
    );
  }
}

/// Título de seção: mais espaço acima do que abaixo.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.first = false});
  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: first ? Space.xl : Space.xxxl, bottom: Space.m),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

/// Linha discreta de aviso (fonte dos dados, ausência de dados).
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline_rounded});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: Ramp.n5)),
        const SizedBox(width: Space.s),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// Estado vazio honesto, sem ilustração.
class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key, required this.icon, required this.title, this.hint});
  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxxl, Space.gutter, Space.xl),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Ramp.n4),
          const SizedBox(height: Space.m),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (hint != null) ...[
            const SizedBox(height: Space.xs),
            Text(hint!, style: text.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// SnackBar curta com "Desfazer" opcional.
void showUndoSnack(BuildContext context, String message, [Future<void> Function()? undo]) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      action: undo == null ? null : SnackBarAction(label: 'Desfazer', onPressed: () => undo()),
    ),
  );
}

/// "87,5%" / "50%"
String percent(double fraction) {
  final v = fraction * 100;
  final s = v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  return '${s.replaceAll('.', ',')}%';
}
