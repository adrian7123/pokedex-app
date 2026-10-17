import 'package:flutter/animation.dart';

/// Rampa neutra fixa papel → tinta. Nenhum cinza fora dela.
abstract final class Ramp {
  static const paper = Color(0xFFFAFAF7);
  static const n1 = Color(0xFFF2F1EC);
  static const n2 = Color(0xFFE2E1DB);
  static const n3 = Color(0xFFC9C8C1);
  static const n4 = Color(0xFFA9A8A1);
  static const n5 = Color(0xFF84837D);
  static const n6 = Color(0xFF5E5D58);
  static const ink = Color(0xFF17171A);
}

/// Tinta dourada do carimbo shiny.
abstract final class Gold {
  static const ink = Color(0xFFC9A227);
  static const text = Color(0xFF8A6C12);
}

/// Cor de um tipo: [ink] para carimbos e áreas, [text] para texto sobre o papel (≥4.5:1).
class TypeInk {
  const TypeInk(this.ink, this.text);
  final Color ink;
  final Color text;

  /// Fundo suave do tipo, misturado ao papel.
  Color wash([double amount = .14]) => Color.lerp(Ramp.paper, ink, amount)!;
}

abstract final class TypeInks {
  static const Map<String, TypeInk> byIdentifier = {
    'normal': TypeInk(Color(0xFF828282), Color(0xFF707070)),
    'fire': TypeInk(Color(0xFFE4613E), Color(0xFFC9401C)),
    'water': TypeInk(Color(0xFF3099E1), Color(0xFF1A76B5)),
    'grass': TypeInk(Color(0xFF439837), Color(0xFF377E2E)),
    'electric': TypeInk(Color(0xFFDFBC28), Color(0xFF836E14)),
    'ice': TypeInk(Color(0xFF47C8C8), Color(0xFF257A7A)),
    'fighting': TypeInk(Color(0xFFE49021), Color(0xFFA06313)),
    'poison': TypeInk(Color(0xFF9354CB), Color(0xFF9150CA)),
    'ground': TypeInk(Color(0xFFA4733C), Color(0xFF956937)),
    'flying': TypeInk(Color(0xFF74AAD0), Color(0xFF3776A2)),
    'psychic': TypeInk(Color(0xFFE96C8C), Color(0xFFD92050)),
    'bug': TypeInk(Color(0xFF9F9F28), Color(0xFF72721D)),
    'rock': TypeInk(Color(0xFFA9A481), Color(0xFF747050)),
    'ghost': TypeInk(Color(0xFF6F4570), Color(0xFF6F4570)),
    'dragon': TypeInk(Color(0xFF576FBC), Color(0xFF536CBB)),
    'dark': TypeInk(Color(0xFF4F4747), Color(0xFF4F4747)),
    'steel': TypeInk(Color(0xFF74B0CB), Color(0xFF387996)),
    'fairy': TypeInk(Color(0xFFE18CE1), Color(0xFFBC31BC)),
  };

  static const fallback = TypeInk(Ramp.n5, Ramp.n6);

  static TypeInk of(String? identifier) => byIdentifier[identifier] ?? fallback;
}

/// Escala de tipo curta: só estes 5 tamanhos no app inteiro. Hierarquia por peso.
abstract final class TypeSize {
  static const caption = 13.0;
  static const body = 15.0;
  static const title = 17.0;
  static const headline = 28.0;
  static const monument = 56.0;
}

abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const xxxl = 40.0;

  /// Margem lateral das telas.
  static const gutter = 20.0;
}

abstract final class Radii {
  static const sheet = 16.0;
  static const pill = 999.0;
}

abstract final class Motion {
  static const short = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const long = Duration(milliseconds: 420);

  /// Desaceleração enfatizada do Material 3.
  static const emphasized = Cubic(0.05, 0.7, 0.1, 1.0);
  static const standard = Cubic(0.2, 0.0, 0.0, 1.0);
}
