import 'package:flutter/material.dart';

/// O chip M3 usa o mesmo `labelStyle` do tema em todos os estados; o ativo (fundo tinta)
/// precisa do estilo secundário (texto papel) explicitamente.
TextStyle? chipLabel(BuildContext context, bool selected) =>
    selected ? Theme.of(context).chipTheme.secondaryLabelStyle : null;
