import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/models.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';

/// Marca discreta de campo que veio da leitura por foto: o usuário confere antes de salvar.
class FromPhotoTag extends StatelessWidget {
  const FromPhotoTag({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'preenchido pela foto, confira',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_outlined, size: 14, color: Ramp.n6),
            const SizedBox(width: Space.xs),
            Text('da foto', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );
}

/// Seção da ficha: picote acima, título com mais respiro em cima do que embaixo, sem caixa.
class SheetSection extends StatelessWidget {
  const SheetSection({
    super.key,
    required this.title,
    required this.children,
    this.fromPhoto = false,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final bool fromPhoto;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.xxl),
          const Perforation(),
          Padding(
            padding: const EdgeInsets.only(top: Space.xxl, bottom: Space.m),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: Space.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                      if (fromPhoto) const FromPhotoTag(),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          ...children,
        ],
      );
}

/// Campo rotulado: rótulo em cima, controle, e erro inline embaixo.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.fromPhoto = false, this.error, this.help});
  final String label;
  final Widget child;
  final bool fromPhoto;
  final String? error;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: Wrap(
            spacing: Space.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(label, style: text.titleSmall),
              if (fromPhoto) const FromPhotoTag(),
            ],
          ),
        ),
        child,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs, left: Space.l),
            child: Text(error!, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
          )
        else if (help != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.xs, left: Space.l),
            child: Text(help!, style: text.bodySmall),
          ),
      ],
    );
  }
}

/// Campo de escolha com o mesmo corpo pílula dos campos de texto; abre uma folha.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.onTap,
    required this.value,
    required this.placeholder,
    required this.semanticLabel,
    this.leading,
    this.detail,
  });

  final VoidCallback onTap;

  /// null mostra o [placeholder].
  final String? value;
  final String placeholder;
  final String semanticLabel;
  final Widget? leading;

  /// Linha secundária à direita do valor (ex.: ↑/↓ da natureza).
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$semanticLabel: ${value ?? placeholder}',
      excludeSemantics: true,
      child: Material(
        color: Ramp.n1,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.fromLTRB(leading == null ? Space.l : Space.m, Space.xs, Space.m, Space.xs),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: Space.m)],
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      style: value == null ? text.bodyMedium : text.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (detail != null) ...[const SizedBox(width: Space.s), detail!],
                  const SizedBox(width: Space.xs),
                  const Icon(Icons.expand_more_rounded, color: Ramp.n6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo numérico curto (nível, stats, EVs, IVs): teclado numérico, só dígitos, borda de erro inline.
class NumField extends StatelessWidget {
  const NumField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.semanticLabel,
    this.invalid = false,
    this.hint,
    this.last = false,
  });

  final TextEditingController controller;
  final ValueChanged<int?> onChanged;
  final String semanticLabel;
  final bool invalid;
  final String? hint;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    OutlineInputBorder border(double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          borderSide: BorderSide(color: error, width: w),
        );
    return Semantics(
      label: semanticLabel,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
        onChanged: (s) => onChanged(int.tryParse(s)),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 14),
          enabledBorder: invalid ? border(1.5) : null,
          focusedBorder: invalid ? border(2) : null,
        ),
      ),
    );
  }
}

/// Sprite de item (pokébola, item segurado) com recaída para um ícone quando não há arquivo.
class ItemSprite extends StatelessWidget {
  const ItemSprite(this.item, {super.key, this.size = 32});
  final ItemRef? item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final i = item;
    final fallback = Icon(Icons.catching_pokemon_rounded, size: size * .75, color: Ramp.n4);
    if (i == null || !i.hasSprite) return SizedBox.square(dimension: size, child: Center(child: fallback));
    return Image.asset(
      i.spritePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => SizedBox.square(dimension: size, child: Center(child: fallback)),
    );
  }
}

/// "↑ Ataque  ↓ At. Esp." (ícones, não glifos) ou "neutra".
class NatureEffect extends StatelessWidget {
  const NatureEffect(this.nature, {super.key, required this.statNames});
  final Nature nature;
  final List<String> statNames;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final up = nature.increased;
    final down = nature.decreased;
    if (up == null || down == null || up == down) return Text('neutra', style: style);
    return Semantics(
      label: 'aumenta ${statNames[up]}, diminui ${statNames[down]}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_upward_rounded, size: 14, color: Ramp.ink),
          Text(statNames[up], style: style?.copyWith(color: Ramp.ink)),
          const SizedBox(width: Space.s),
          const Icon(Icons.arrow_downward_rounded, size: 14, color: Ramp.n5),
          Text(statNames[down], style: style),
        ],
      ),
    );
  }
}
