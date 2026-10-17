/// Texto reconhecido numa foto, já endireitado: as caixas ficam num referencial girado pela
/// inclinação média das linhas, então "à direita" e "abaixo" valem mesmo com a foto torta.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'matcher.dart';

class OcrWord {
  OcrWord(this.text, this.box);
  final String text;
  final Rect box;
}

class OcrLine {
  OcrLine(this.text, this.box, this.words) : folded = fold(text);
  final String text;
  final Rect box;
  final List<OcrWord> words;

  /// [fold] do texto, para âncoras e expressões.
  final String folded;
  double get h => box.height;
  Offset get center => box.center;

  /// Linha com as palavras a partir de [from] (o que sobra depois de uma âncora).
  OcrLine? tail(int from) {
    if (from >= words.length) return null;
    final rest = words.sublist(from);
    final box = rest.map((w) => w.box).reduce((a, b) => a.expandToInclude(b));
    return OcrLine(rest.map((w) => w.text).join(' '), box, rest);
  }
}

class OcrPage {
  OcrPage({required this.lines, required this.angle, this.imageSize});
  final List<OcrLine> lines;

  /// Inclinação (radianos) que foi desfeita. Para voltar à imagem: gire por +angle.
  final double angle;

  /// Tamanho da imagem processada, quando conhecido.
  final Size? imageSize;

  /// Altura típica de linha, a régua das tolerâncias.
  late final double lineHeight = () {
    final hs = [for (final l in lines) l.h]..sort();
    return hs.isEmpty ? 16.0 : hs[hs.length ~/ 2];
  }();

  /// Ponto do referencial endireitado → ponto da imagem.
  Offset toImage(Offset p) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Offset(p.dx * c - p.dy * s, p.dx * s + p.dy * c);
  }
}

/// Linha crua: texto e os 4 cantos (sentido horário a partir do canto superior esquerdo).
class RawLine {
  RawLine(this.text, this.corners, this.words);
  final String text;
  final List<Offset> corners;
  final List<(String, List<Offset>)> words;
}

/// Endireita as linhas pela mediana das inclinações (ponderada pela largura).
OcrPage buildPage(List<RawLine> raw, {Size? imageSize}) {
  final angles = <(double, double)>[];
  for (final l in raw) {
    if (l.corners.length < 2 || l.text.trim().length < 3) continue;
    final d = l.corners[1] - l.corners[0];
    if (d.distance < 1) continue;
    angles.add((math.atan2(d.dy, d.dx), d.distance));
  }
  var angle = 0.0;
  if (angles.isNotEmpty) {
    angles.sort((a, b) => a.$1.compareTo(b.$1));
    final total = angles.fold<double>(0, (s, a) => s + a.$2);
    var acc = 0.0;
    for (final a in angles) {
      acc += a.$2;
      if (acc >= total / 2) {
        angle = a.$1;
        break;
      }
    }
    // Acima de ~35° não é inclinação de foto: é a foto de lado, e o OCR já trata.
    if (angle.abs() > .6) angle = 0;
  }
  final c = math.cos(-angle);
  final s = math.sin(-angle);
  Offset rot(Offset p) => Offset(p.dx * c - p.dy * s, p.dx * s + p.dy * c);
  Rect box(List<Offset> pts) {
    final r = pts.map(rot).toList();
    var l = r.first.dx, t = r.first.dy, ri = l, b = t;
    for (final p in r) {
      l = math.min(l, p.dx);
      t = math.min(t, p.dy);
      ri = math.max(ri, p.dx);
      b = math.max(b, p.dy);
    }
    return Rect.fromLTRB(l, t, ri, b);
  }

  final lines = <OcrLine>[];
  for (final l in raw) {
    if (l.corners.isEmpty || l.text.trim().isEmpty) continue;
    final words = [
      for (final (t, pts) in l.words)
        if (pts.isNotEmpty && t.trim().isNotEmpty) OcrWord(t, box(pts)),
    ];
    lines.add(OcrLine(l.text.trim(), box(l.corners), words.isEmpty ? [OcrWord(l.text.trim(), box(l.corners))] : words));
  }
  lines.sort((a, b) => a.box.top.compareTo(b.box.top));
  return OcrPage(lines: lines, angle: angle, imageSize: imageSize);
}
