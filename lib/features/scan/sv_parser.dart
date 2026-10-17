/// Leitura do resumo do Pokémon em Scarlet/Violet a partir das linhas do OCR.
///
/// Acha as âncoras do layout ("Golpes Atuais", "Habilidade", "Nv.", rótulos do hexágono de stats,
/// "Natureza", "Item", "Tipo Tera") e lê o valor no vizinho geométrico: à direita na mesma altura
/// ou logo abaixo. Rótulos em pt-BR (tradução do jogo) e em inglês.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'matcher.dart';
import 'ocr_page.dart';
import 'reading.dart';

class SummaryParse {
  SummaryParse(this.fields, {this.nameBox});
  final PageFields fields;

  /// Caixa do nome (referencial endireitado), para procurar os ícones de gênero e shiny ao lado.
  final Rect? nameBox;
}

SummaryParse parseSummary(OcrPage page, Lexicons lx) => _Parser(page, lx).run();

/// Leitura interna da espécie pelo nome (speciesId); a variedade é decidida depois.
const speciesKey = '_species';

class _Num {
  _Num(this.box, this.a, this.b, {required this.clean});
  final Rect box;
  final int a;
  final int? b;
  final bool clean;
}

class _Parser {
  _Parser(this.page, this.lx) : h = page.lineHeight;
  final OcrPage page;
  final Lexicons lx;
  final double h;
  final out = PageFields();
  final used = <OcrLine>{};
  OcrLine? _levelLine;
  Rect? _nameBox;

  List<OcrLine> get lines => page.lines;

  SummaryParse run() {
    out.lineCount = lines.length;
    _level();
    _name();
    _stats();
    _ability();
    _moves();
    _nature();
    _heldItem();
    _tera();
    _ball();
    _caughtWhere();
    _dexNumber();
    _speciesElsewhere();
    return SummaryParse(out, nameBox: _nameBox);
  }

  // ---------------------------------------------------------------------------
  // Ferramentas

  /// Quantas palavras do começo da linha formam a âncora (0 = não é âncora).
  int _anchor(OcrLine l, List<String> keys, {double min = .8}) {
    final ws = l.words;
    for (var n = math.min(3, ws.length); n >= 1; n--) {
      final q = squash(ws.take(n).map((w) => w.text).join(' '));
      if (q.isEmpty) continue;
      for (final k in keys) {
        if (k.length <= 4 ? q == k : similarity(q, k) >= min) return n;
      }
    }
    return 0;
  }

  /// Valor de uma âncora: o resto da linha, a linha à direita na mesma altura, ou a de baixo.
  OcrLine? _valueOf(OcrLine anchor, int consumed) {
    final tail = anchor.tail(consumed);
    if (tail != null && squash(tail.text).isNotEmpty) return tail;
    OcrLine? best;
    var bestCost = double.infinity;
    for (final l in lines) {
      if (identical(l, anchor) || used.contains(l)) continue;
      final dcy = (l.center.dy - anchor.center.dy).abs();
      final gap = l.box.left - anchor.box.right;
      double? cost;
      if (dcy <= .7 * h && gap >= -.5 * h && gap <= 16 * h) {
        cost = gap.abs();
      } else {
        final dy = l.box.top - anchor.box.bottom;
        if (dy >= -.3 * h && dy <= 2.2 * h && (l.box.left - anchor.box.left).abs() <= 3 * h) cost = 2 * h + dy;
      }
      if (cost != null && cost < bestCost) {
        best = l;
        bestCost = cost;
      }
    }
    return best;
  }

  /// Ícone lido como letra solta ("O", "©") antes do nome ou do golpe.
  static bool _isJunk(String t) => squash(t).length <= 1;

  /// 'm', 'f' ou '' para um símbolo de gênero como o OCR costuma devolver.
  static String _genderGlyph(String t) {
    final s = t.trim();
    if (s.isEmpty || s.length > 2) return '';
    if (s.contains('♂') || const {'σ', 'ơ', 'ď', 'đ', 'δ', 'o', 'O', '0', 'd', '6', 'ó', 'ô'}.contains(s)) return 'm';
    if (s.contains('♀') || const {'Q', 'q', '9', 'φ', 'ç', 'Ç', '¥', 'ọ'}.contains(s)) return 'f';
    return '';
  }

  static final _digitsRe = RegExp(r'^\d{1,3}$');

  /// "25", "32/42", "32 / 42", "32I42" (barra lida como I) → número(s).
  static _Num? _parseNum(String text, Rect box) {
    final s = text.replaceAll(' ', '');
    if (s.isEmpty || !RegExp(r'\d').hasMatch(s)) return null;
    if (_digitsRe.hasMatch(s)) return _Num(box, int.parse(s), null, clean: true);
    final slash = RegExp(r'^(\d{1,3})/(\d{1,3})$').firstMatch(s);
    if (slash != null) return _Num(box, int.parse(slash[1]!), int.parse(slash[2]!), clean: true);
    final fixed = s.replaceAll(RegExp('[oO]'), '0').replaceAll(RegExp('[sS]'), '5');
    if (_digitsRe.hasMatch(fixed.replaceAll(RegExp('[lIi!|]'), '1'))) {
      // Só dígitos depois da troca: ou é um número com letra trocada, ou a barra virou "1"/"I".
      final sep = RegExp(r'^(\d{1,3})[lIi!|/\\](\d{1,3})$').firstMatch(fixed);
      if (sep != null) return _Num(box, int.parse(sep[1]!), int.parse(sep[2]!), clean: false);
      return _Num(box, int.parse(fixed.replaceAll(RegExp('[lIi!|]'), '1')), null, clean: false);
    }
    final sep = RegExp(r'^(\d{1,3})[lIi!|/\\](\d{1,3})$').firstMatch(fixed);
    if (sep != null) return _Num(box, int.parse(sep[1]!), int.parse(sep[2]!), clean: false);
    // "32142": barra lida como 1 no meio de 4–6 dígitos.
    final run = RegExp(r'^\d{4,6}$').firstMatch(fixed);
    if (run != null) {
      final d = run[0]!;
      for (final cut in [d.length ~/ 2, d.length ~/ 2 - 1, d.length ~/ 2 + 1]) {
        if (cut < 1 || cut >= d.length - 1 || d[cut] != '1') continue;
        final a = int.parse(d.substring(0, cut));
        final b = int.parse(d.substring(cut + 1));
        if (a <= b && b <= 999) return _Num(box, a, b, clean: false);
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Nível e nome

  static final _levelRe = RegExp(r'(?:^| )(?:nv|lv|lvl|nu|nw|niv|nivel|hv)\s?([0-9olis]{1,3})(?= |$)');

  void _level() {
    int? best;
    var clean = false;
    for (final l in lines) {
      final m = _levelRe.firstMatch(l.folded);
      if (m == null) continue;
      final raw = m[1]!;
      if (!RegExp(r'\d').hasMatch(raw)) continue;
      final fixed = raw.replaceAll('o', '0').replaceAll('l', '1').replaceAll('i', '1').replaceAll('s', '5');
      final n = int.tryParse(fixed);
      if (n == null || n < 1 || n > 100) continue;
      final isClean = raw == fixed;
      if (best == null || (isClean && !clean)) {
        best = n;
        clean = isClean;
        _levelLine = l;
      }
    }
    if (best != null) {
      used.add(_levelLine!);
      out.put(F.level, best, clean ? Confidence.high : Confidence.low);
    }
  }

  void _name() {
    final lv = _levelLine;
    if (lv == null) return;
    OcrLine? cand;
    var bestCost = double.infinity;
    for (final l in lines) {
      if (used.contains(l) || !RegExp('[A-Za-z]').hasMatch(l.text)) continue;
      final dy = lv.box.top - l.box.bottom;
      final dl = (l.box.left - lv.box.left).abs();
      if (dy < -.4 * h || dy > 3 * h || dl > 5 * h) continue;
      final cost = dy.abs() + dl * .3;
      if (cost < bestCost) {
        cand = l;
        bestCost = cost;
      }
    }
    if (cand == null) return;
    used.add(cand);
    final words = [...cand.words];
    while (words.length > 1 && _isJunk(words.first.text)) {
      words.removeAt(0);
    }
    var gender = '';
    if (words.length > 1) {
      gender = _genderGlyph(words.last.text);
      if (gender.isNotEmpty) words.removeLast();
    }
    if (words.isEmpty) return;
    var name = words.map((w) => w.text).join(' ').trim();
    if (name.endsWith('♂') || name.endsWith('♀')) {
      gender = name.endsWith('♂') ? 'm' : 'f';
      name = name.substring(0, name.length - 1).trim();
    }
    name = name.replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}.!?♀♂]+$', unicode: true), '');
    if (name.isEmpty) return;
    _nameBox = words.map((w) => w.box).reduce((a, b) => a.expandToInclude(b));

    // Símbolo de gênero solto à direita, na mesma altura.
    if (gender.isEmpty) {
      for (final l in lines) {
        if (used.contains(l) || l.text.trim().length > 2) continue;
        if ((l.center.dy - cand.center.dy).abs() > .7 * h || l.box.left < _nameBox!.right) continue;
        if (l.box.left - _nameBox!.right > 22 * h) continue;
        gender = _genderGlyph(l.text);
        if (gender.isNotEmpty) break;
      }
    }
    if (gender.isNotEmpty) out.put(F.gender, gender, Confidence.low);

    out.put(F.name, name, Confidence.high);
    final hit = lx.species.best(name, min: .8);
    if (hit != null) {
      out.put(speciesKey, hit.value, hit.score >= .92 ? Confidence.high : Confidence.low);
    } else {
      final tidy = RegExp(r'^[\p{L}\p{N} .\-]{1,12}$', unicode: true).hasMatch(name);
      out.put(F.nickname, name, tidy ? Confidence.high : Confidence.low);
    }
  }

  // ---------------------------------------------------------------------------
  // Stats (hexágono: rótulo em cima, número embaixo)

  static const _statKeys = [
    ['hp', 'ps', 'pv'],
    ['ataque', 'attack', 'atk', 'ataq'],
    ['defesa', 'defense', 'def'],
    ['spatk', 'ataqueespecial', 'atesp', 'spatq', 'atqesp', 'spatt'],
    ['spdef', 'defesaespecial', 'defesp', 'spdefesa', 'spdf'],
    ['velocidade', 'speed', 'vel', 'spe'],
  ];

  void _stats() {
    final labels = <(int, OcrLine, Rect, OcrLine?)>[];
    for (final l in lines) {
      if (used.contains(l)) continue;
      var bestStat = -1;
      var bestN = 0;
      for (var i = 0; i < 6; i++) {
        final n = _anchor(l, _statKeys[i], min: .78);
        if (n > bestN) {
          bestN = n;
          bestStat = i;
        }
      }
      if (bestStat < 0) continue;
      final tail = l.tail(bestN);
      // Rótulo com texto que não é número ("Ataque do oponente...") não é rótulo do hexágono.
      if (tail != null && _parseNum(tail.text, tail.box) == null) continue;
      final labelBox = l.words.take(bestN).map((w) => w.box).reduce((a, b) => a.expandToInclude(b));
      labels.add((bestStat, l, labelBox, tail));
    }
    if (labels.isEmpty) return;
    for (final (_, l, _, _) in labels) {
      used.add(l);
    }

    final nums = <_Num>[];
    final numLines = <_Num, OcrLine>{};
    for (final l in lines) {
      if (used.contains(l)) continue;
      final whole = _parseNum(l.text, l.box);
      if (whole != null) {
        nums.add(whole);
        numLines[whole] = l;
        continue;
      }
      for (final w in l.words) {
        final n = _parseNum(w.text, w.box);
        if (n != null) {
          nums.add(n);
          numLines[n] = l;
        }
      }
    }

    final pairs = <(double, int, _Num)>[];
    for (final (stat, _, box, tail) in labels) {
      if (tail != null) {
        final n = _parseNum(tail.text, tail.box);
        if (n != null) pairs.add((0, stat, n));
      }
      for (final n in nums) {
        if (stat != 0 && n.b != null) continue;
        final dy = n.box.top - box.bottom;
        final dcx = (n.box.center.dx - box.center.dx).abs();
        double? cost;
        if (dy >= -.4 * h && dy <= 2.5 * h && dcx <= math.max(box.width, n.box.width) / 2 + 1.5 * h) {
          cost = dy.abs() + dcx * .5;
        } else {
          final dcy = (n.box.center.dy - box.center.dy).abs();
          final gap = n.box.left - box.right;
          if (dcy <= .6 * h && gap >= -.3 * h && gap <= 5 * h) cost = gap.abs() + .5 * h;
        }
        if (cost != null) pairs.add((cost, stat, n));
      }
    }
    pairs.sort((a, b) => a.$1.compareTo(b.$1));
    final doneStats = <int>{};
    final doneNums = <_Num>{};
    for (final (_, stat, n) in pairs) {
      if (doneStats.contains(stat) || doneNums.contains(n)) continue;
      doneStats.add(stat);
      doneNums.add(n);
      final l = numLines[n];
      if (l != null) used.add(l);
      var value = n.b ?? n.a;
      var clean = n.clean;
      if (stat == 0 && n.b != null) {
        if (n.a > n.b!) {
          value = n.a;
          clean = false;
        } else {
          out.put(F.currentHp, n.a, Confidence.low);
        }
      }
      if (value < 1 || value > 999) continue;
      out.put(F.stat(stat), value, clean ? Confidence.high : Confidence.low);
    }
  }

  // ---------------------------------------------------------------------------
  // Habilidade, golpes, natureza, item, Tera, bola, local

  void _ability() {
    for (final l in lines) {
      if (used.contains(l)) continue;
      final n = _anchor(l, const ['habilidade', 'ability', 'abilidade', 'habiidade']);
      if (n == 0) continue;
      final v = _valueOf(l, n);
      if (v == null) continue;
      Hit<int>? hit = lx.abilities.best(v.text, min: .8);
      // Descrição colada na mesma linha: tenta só as primeiras palavras.
      for (var k = 1; hit == null && k <= math.min(3, v.words.length - 1); k++) {
        hit = lx.abilities.best(v.words.take(k).map((w) => w.text).join(' '), min: .85);
      }
      if (hit == null) continue;
      used
        ..add(l)
        ..add(v);
      out.put(F.abilityId, hit.value, hit.score >= .9 ? Confidence.high : Confidence.low);
      return;
    }
  }

  static final _ppRe = RegExp(r'\d{1,2}\s*[/|Il]\s*\d{1,2}');

  bool _ppBeside(OcrLine l) => lines.any(
        (o) =>
            !identical(o, l) &&
            o.box.left > l.box.left &&
            (o.center.dy - l.center.dy).abs() <= .7 * h &&
            _ppRe.hasMatch(o.text),
      );

  void _moves() {
    OcrLine? anchor;
    for (final l in lines) {
      final n = _anchor(l, const ['golpesatuais', 'currentmoves', 'golpesconhecidos', 'moves']);
      if (n > 0 && n == l.words.length) {
        anchor = l;
        used.add(l);
        break;
      }
    }
    final found = <(double, int, double)>[]; // top, moveId, score
    for (final l in lines) {
      if (used.contains(l)) continue;
      if (anchor != null) {
        final top = l.box.top;
        if (top < anchor.box.top + .3 * h || top > anchor.box.bottom + 12 * h) continue;
        if (l.box.left < anchor.box.left - 4 * h || l.box.left > anchor.box.left + 12 * h) continue;
      }
      final words = l.text.replaceAll(_ppRe, ' ').trim().split(RegExp(r'\s+'));
      while (words.length > 1 && _isJunk(words.first)) {
        words.removeAt(0);
      }
      final text = words.join(' ');
      if (squash(text).length < 3) continue;
      var hit = lx.moves.best(text, min: .78);
      if (hit == null && words.length > 1) hit = lx.moves.best(words.skip(1).join(' '), min: .82);
      if (hit == null) continue;
      if (anchor == null && !_ppBeside(l) && (hit.score < .95 || words.length > 3)) continue;
      used.add(l);
      found.add((l.box.top, hit.value, hit.score));
    }
    if (found.isEmpty) return;
    found.sort((a, b) => a.$1.compareTo(b.$1));
    final ids = <int>[];
    var minScore = 1.0;
    for (final (_, id, score) in found) {
      if (ids.contains(id)) continue;
      if (ids.length == 4) {
        minScore = 0;
        break;
      }
      ids.add(id);
      minScore = math.min(minScore, score);
    }
    out.put(F.moves, ids, minScore >= .9 ? Confidence.high : Confidence.low);
  }

  void _nature() {
    for (final l in lines) {
      if (used.contains(l)) continue;
      final ws = l.words;
      final at = ws.indexWhere((w) {
        final s = squash(w.text);
        return s == 'natureza' || s == 'nature' || (s.length >= 6 && (similarity(s, 'natureza') >= .8 || similarity(s, 'nature') >= .8));
      });
      if (at < 0) continue;
      Hit<String>? hit;
      for (var i = 0; i < ws.length && hit == null; i++) {
        if (i == at) continue;
        final m = lx.natures.best(ws[i].text, min: .8);
        if (m != null) hit = m;
      }
      if (hit == null && at == ws.length - 1) {
        final v = _valueOf(l, ws.length);
        if (v != null) {
          final m = lx.natures.best(v.words.first.text, min: .8);
          if (m != null) {
            used.add(v);
            hit = m;
          }
        }
      }
      if (hit == null) continue;
      used.add(l);
      out.put(F.nature, hit.value, hit.score >= .9 ? Confidence.high : Confidence.low);
      return;
    }
  }

  static bool _isNone(String t) => const {'nenhum', 'nenhuma', 'none', 'nada', 'sem'}.contains(squash(t));

  void _heldItem() {
    for (final l in lines) {
      if (used.contains(l)) continue;
      final n = _anchor(l, const [
        'itemsegurado',
        'objetosegurado',
        'helditem',
        'itemmantido',
        'itemequipado',
        'item',
        'objeto',
      ]);
      if (n == 0) continue;
      final v = _valueOf(l, n);
      if (v == null || _isNone(v.text)) continue;
      final hit = lx.items.best(v.text, min: .82);
      if (hit == null) continue;
      used
        ..add(l)
        ..add(v);
      out.put(F.heldItemId, hit.value, hit.score >= .92 ? Confidence.high : Confidence.low);
      return;
    }
  }

  void _tera() {
    for (final l in lines) {
      if (used.contains(l)) continue;
      final n = _anchor(l, const ['tipotera', 'teratipo', 'teratype', 'tera']);
      if (n == 0) continue;
      final v = _valueOf(l, n);
      if (v == null) continue;
      final hit = lx.types.best(v.words.first.text, min: .8) ?? lx.types.best(v.text, min: .8);
      if (hit == null) continue;
      used
        ..add(l)
        ..add(v);
      out.put(F.teraType, hit.value, hit.score >= .9 ? Confidence.high : Confidence.low);
      return;
    }
  }

  void _ball() {
    for (final l in lines) {
      if (used.contains(l)) continue;
      final f = l.folded;
      if (!f.contains('ball') && !f.contains('bola')) continue;
      final hit = lx.balls.best(l.text, min: .85);
      if (hit == null) continue;
      used.add(l);
      out.put(F.ballItemId, hit.value, Confidence.low);
      return;
    }
  }

  static final _metRe = RegExp(
    r'(?:encontrad[oa]|capturad[oa]|conhecid[oa]|chocad[oa]|recebid[oa]|met|caught|hatched)\s+(?:em|no|na|nos|nas|in|at)\s+(.+)',
    caseSensitive: false,
  );
  static final _metCut = RegExp(
    r'(?:\s+(?:em|on|no dia|at|ao|com|with)\s+.*\d.*|\s*\d{1,2}[/.-]\d{1,2}.*|[.,;].*)$',
    caseSensitive: false,
  );

  void _caughtWhere() {
    for (final l in lines) {
      if (used.contains(l)) continue;
      final m = _metRe.firstMatch(l.text);
      if (m == null) continue;
      final place = m[1]!.replaceFirst(_metCut, '').trim();
      if (place.length < 3) continue;
      used.add(l);
      out.put(F.caughtWhere, place, Confidence.low);
      return;
    }
  }

  static final _dexRe = RegExp(r'^(?:n|no|nr|num|numero|dex|dex no|n dex|pokedex)\s?0*(\d{1,4})$');

  void _dexNumber() {
    for (final l in lines) {
      if (used.contains(l)) continue;
      final m = _dexRe.firstMatch(l.folded);
      if (m == null) continue;
      final n = int.parse(m[1]!);
      if (n == 0) continue;
      out.put(F.dexNumber, n, Confidence.low);
      return;
    }
  }

  /// Com apelido no lugar do nome, o nome da espécie às vezes aparece em outra linha (página
  /// Informações). Linha curta que casa bem com uma espécie vira a leitura da espécie.
  void _speciesElsewhere() {
    if (out.fields.containsKey(speciesKey)) return;
    Hit<int>? best;
    for (final l in lines) {
      if (used.contains(l) || l.words.length > 2) continue;
      final hit = lx.species.best(l.text, min: .9);
      if (hit != null && (best == null || hit.score > best.score)) best = hit;
    }
    if (best != null) out.put(speciesKey, best.value, best.score >= .97 ? Confidence.high : Confidence.low);
  }
}
