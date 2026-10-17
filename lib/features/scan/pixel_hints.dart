/// Dicas de imagem para o que o OCR não lê: o ícone de gênero (círculo azul ♂ / vermelho ♀) e um
/// possível ícone de shiny na linha do nome.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'ocr_page.dart';

class PixelImage {
  PixelImage(this.width, this.height, this.rgba);
  final int width;
  final int height;
  final Uint8List rgba;
}

/// Decodifica a foto (o decodificador nativo já aplica a orientação EXIF).
Future<PixelImage?> decodePixels(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final out = data == null ? null : PixelImage(img.width, img.height, data.buffer.asUint8List());
    img.dispose();
    codec.dispose();
    return out;
  } catch (_) {
    return null;
  }
}

class IconHints {
  const IconHints({this.gender, this.genderSure = false, this.shinyLikely = false});

  /// 'm' / 'f' / null
  final String? gender;
  final bool genderSure;
  final bool shinyLikely;
}

enum _Px { none, blue, red, other }

/// Procura os ícones à direita do nome, na mesma faixa de altura.
IconHints iconHints(PixelImage img, OcrPage page, ui.Rect name) {
  final h = math.max(name.height, 6.0);
  final left = name.right + .4 * h;
  final right = name.left + 21 * h;
  final top = name.top - .35 * h;
  final bottom = name.bottom + .35 * h;
  final step = math.max(1.0, h / 8);
  final cols = ((right - left) / step).floor();
  final rows = ((bottom - top) / step).floor();
  if (cols <= 0 || rows <= 0) return const IconHints();

  // Palavras do OCR na faixa: texto não é ícone.
  final words = [
    for (final l in page.lines)
      for (final w in l.words)
        if (w.box.overlaps(ui.Rect.fromLTRB(left, top, right, bottom))) w.box.inflate(step),
  ];

  final grid = List<_Px>.filled(cols * rows, _Px.none);
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final p = ui.Offset(left + c * step, top + r * step);
      if (words.any((b) => b.contains(p))) continue;
      final q = page.toImage(p);
      final x = q.dx.round();
      final y = q.dy.round();
      if (x < 0 || y < 0 || x >= img.width || y >= img.height) continue;
      final i = (y * img.width + x) * 4;
      grid[r * cols + c] = _classify(img.rgba[i], img.rgba[i + 1], img.rgba[i + 2]);
    }
  }

  // Componentes conexos por classe de cor.
  final seen = List<bool>.filled(grid.length, false);
  final blobs = <(_Px, int, double, double)>[]; // classe, células, largura px, altura px
  for (var start = 0; start < grid.length; start++) {
    if (seen[start] || grid[start] == _Px.none) continue;
    final kind = grid[start];
    final stack = [start];
    seen[start] = true;
    var count = 0;
    var minC = cols, maxC = 0, minR = rows, maxR = 0;
    while (stack.isNotEmpty) {
      final k = stack.removeLast();
      count++;
      final r = k ~/ cols;
      final c = k % cols;
      minC = math.min(minC, c);
      maxC = math.max(maxC, c);
      minR = math.min(minR, r);
      maxR = math.max(maxR, r);
      for (final (dr, dc) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nr = r + dr;
        final nc = c + dc;
        if (nr < 0 || nc < 0 || nr >= rows || nc >= cols) continue;
        final n = nr * cols + nc;
        if (seen[n] || grid[n] != kind) continue;
        seen[n] = true;
        stack.add(n);
      }
    }
    final w = (maxC - minC + 1) * step;
    final hh = (maxR - minR + 1) * step;
    final fill = count / ((maxC - minC + 1) * (maxR - minR + 1));
    // Tamanho de ícone (entre metade e quase duas alturas de letra), razoavelmente cheio.
    if (w >= .45 * h && hh >= .45 * h && w <= 1.9 * h && hh <= 1.9 * h && fill >= .3) {
      blobs.add((kind, count, w, hh));
    }
  }

  (_Px, int, double, double)? biggest(_Px k) {
    (_Px, int, double, double)? best;
    for (final b in blobs) {
      if (b.$1 == k && (best == null || b.$2 > best.$2)) best = b;
    }
    return best;
  }

  final blue = biggest(_Px.blue);
  final red = biggest(_Px.red);
  String? gender;
  var sure = false;
  if (blue != null && red == null) {
    gender = 'm';
    sure = true;
  } else if (red != null && blue == null) {
    gender = 'f';
    sure = true;
  } else if (blue != null && red != null) {
    gender = blue.$2 >= red.$2 ? 'm' : 'f';
  }
  // Ícone extra saturado além do de gênero: possível marca de shiny.
  final extras = blobs.where((b) => b.$1 == _Px.other || (b.$1 == _Px.red && gender == 'm') || (b.$1 == _Px.red && gender == 'f' && b != red));
  return IconHints(gender: gender, genderSure: sure, shinyLikely: extras.isNotEmpty);
}

_Px _classify(int r, int g, int b) {
  final mx = math.max(r, math.max(g, b));
  final mn = math.min(r, math.min(g, b));
  final v = mx / 255;
  if (mx == 0) return _Px.none;
  final s = (mx - mn) / mx;
  if (s < .4 || v < .5) return _Px.none;
  double hue;
  final d = (mx - mn).toDouble();
  if (mx == r) {
    hue = 60 * (((g - b) / d) % 6);
  } else if (mx == g) {
    hue = 60 * ((b - r) / d + 2);
  } else {
    hue = 60 * ((r - g) / d + 4);
  }
  if (hue < 0) hue += 360;
  if (hue >= 185 && hue <= 235 && v >= .55) return _Px.blue;
  if ((hue >= 330 || hue <= 15) && v >= .5) return _Px.red;
  return _Px.other;
}
