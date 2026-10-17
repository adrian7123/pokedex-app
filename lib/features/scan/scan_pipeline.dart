/// Uma foto → campos: OCR no aparelho (ML Kit), leitura do layout e dicas de imagem.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'matcher.dart';
import 'ocr_page.dart';
import 'pixel_hints.dart';
import 'reading.dart';
import 'sv_parser.dart';

List<Offset> _pts(List<math.Point<int>> pts, Rect box) => pts.length >= 4
    ? [for (final p in pts) Offset(p.x.toDouble(), p.y.toDouble())]
    : [box.topLeft, box.topRight, box.bottomRight, box.bottomLeft];

/// OCR da foto. O ML Kit roda fora da thread de UI (canal nativo).
Future<OcrPage> recognize(String path) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    final raw = [
      for (final b in result.blocks)
        for (final l in b.lines)
          RawLine(l.text, _pts(l.cornerPoints, l.boundingBox), [
            for (final e in l.elements) (e.text, _pts(e.cornerPoints, e.boundingBox)),
          ]),
    ];
    return buildPage(raw);
  } finally {
    await recognizer.close();
  }
}

/// Lê uma página do resumo. Nunca lança: falha vira página vazia.
Future<PageFields> scanPage(String path, Lexicons lx) async {
  OcrPage page;
  try {
    page = await recognize(path);
  } catch (_) {
    return PageFields();
  }
  final parse = parseSummary(page, lx);
  final fields = parse.fields;
  final name = parse.nameBox;
  if (name == null) return fields;

  final pixels = await decodePixels(path);
  if (pixels == null) return fields;
  // Coordenadas do OCR e da imagem decodificada precisam ser o mesmo espaço (orientação EXIF).
  final maxRight = page.lines.fold<double>(0, (m, l) => math.max(m, page.toImage(l.box.bottomRight).dx));
  final maxBottom = page.lines.fold<double>(0, (m, l) => math.max(m, page.toImage(l.box.bottomRight).dy));
  if (maxRight > pixels.width * 1.05 || maxBottom > pixels.height * 1.05) return fields;

  final hints = iconHints(pixels, page, name);
  final textGender = fields.fields[F.gender];
  if (hints.gender != null) {
    final agrees = textGender == null || textGender.value == hints.gender;
    fields.put(F.gender, hints.gender!, hints.genderSure && agrees ? Confidence.high : Confidence.low);
  }
  fields.put(F.isShiny, hints.shinyLikely, Confidence.low);
  return fields;
}
