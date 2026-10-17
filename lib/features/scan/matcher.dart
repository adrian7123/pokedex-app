/// Comparação tolerante entre o que o OCR leu e os dicionários fechados do banco.
library;

import 'dart:math' as math;

import '../../core/data/dex_repository.dart';
import '../pokedex/search.dart' show editDistance;

/// Texto dobrado: minúsculo, sem acento, só letras/dígitos separados por um espaço.
String fold(String s) {
  const from = 'áàâãäåéèêëíìîïóòôõöúùûüçñýÿ';
  const to = 'aaaaaaeeeeiiiiooooouuuucnyy';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    final c = i < 0 ? ch : to[i];
    final code = c.codeUnitAt(0);
    final keep = (code >= 0x61 && code <= 0x7a) || (code >= 0x30 && code <= 0x39);
    b.write(keep ? c : ' ');
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Dobrado e sem espaços ("Sp. Atk" → "spatk").
String squash(String s) => fold(s).replaceAll(' ', '');

/// Em nomes, o OCR troca letra por dígito parecido. Aplicado dos dois lados da comparação.
String _letters(String s) => s.replaceAll('0', 'o').replaceAll('1', 'l').replaceAll('5', 's');

/// 1.0 = igual; 0.0 = nada a ver. Normalizada pelo maior comprimento.
double similarity(String a, String b) {
  final x = _letters(squash(a));
  final y = _letters(squash(b));
  if (x.isEmpty || y.isEmpty) return 0;
  final len = math.max(x.length, y.length);
  return 1 - editDistance(x, y, max: len) / len;
}

class Hit<T> {
  const Hit(this.value, this.score, this.key);
  final T value;
  final double score;
  final String key;
}

/// Dicionário fechado (espécies, golpes, habilidades...) com busca por distância de edição.
class Lexicon<T> {
  Lexicon(Iterable<(String, T)> items) {
    for (final (name, value) in items) {
      final k = _letters(squash(name));
      if (k.isEmpty) continue;
      _items.add((k, value));
      _exact.putIfAbsent(k, () => value);
    }
  }

  final _items = <(String, T)>[];
  final _exact = <String, T>{};

  /// Melhor entrada com semelhança ≥ [min]. Palavras curtas só casam exatas (3 letras com 1 erro
  /// já viram outro golpe).
  Hit<T>? best(String raw, {double min = .8}) {
    final q = _letters(squash(raw));
    if (q.length < 2) return null;
    final exact = _exact[q];
    if (exact != null) return Hit(exact, 1, q);
    if (q.length <= 4) return null;
    Hit<T>? top;
    for (final (k, v) in _items) {
      final len = math.max(k.length, q.length);
      final budget = ((1 - min) * len).floor();
      if (budget < 1 || (k.length - q.length).abs() > budget) continue;
      final d = editDistance(q, k, max: budget);
      if (d > budget) continue;
      final score = 1 - d / len;
      if (top == null || score > top.score) top = Hit(v, score, k);
    }
    return top;
  }
}

/// Naturezas em pt-BR (tradução de fã: o jogo oficial não tem pt-BR, então aceitamos variantes).
/// identifier → nomes no feminino; o masculino é gerado.
const naturesPt = <String, List<String>>{
  'hardy': ['Firme', 'Resistente', 'Robusta'],
  'lonely': ['Solitária'],
  'brave': ['Corajosa', 'Valente', 'Brava'],
  'adamant': ['Adamante', 'Rígida', 'Obstinada'],
  'naughty': ['Travessa', 'Levada', 'Malcriada'],
  'bold': ['Ousada', 'Audaciosa'],
  'docile': ['Dócil'],
  'relaxed': ['Relaxada', 'Descontraída'],
  'impish': ['Marota', 'Traquina', 'Brincalhona'],
  'lax': ['Negligente', 'Descuidada', 'Displicente', 'Frouxa'],
  'timid': ['Tímida'],
  'hasty': ['Apressada'],
  'serious': ['Séria'],
  'jolly': ['Alegre', 'Jovial'],
  'naive': ['Ingênua'],
  'modest': ['Modesta'],
  'mild': ['Amena', 'Branda', 'Meiga', 'Suave'],
  'quiet': ['Quieta', 'Silenciosa'],
  'bashful': ['Acanhada', 'Envergonhada'],
  'rash': ['Imprudente', 'Precipitada', 'Impulsiva'],
  'calm': ['Calma', 'Serena'],
  'gentle': ['Gentil'],
  'sassy': ['Atrevida', 'Insolente'],
  'careful': ['Cuidadosa', 'Cautelosa'],
  'quirky': ['Peculiar', 'Excêntrica', 'Estranha'],
};

/// Nome pt-BR de exibição da natureza ("Modesta").
String? naturePtName(String identifier) => naturesPt[identifier]?.first;

Iterable<String> _withMasculine(String name) sync* {
  yield name;
  if (name.endsWith('a')) yield '${name.substring(0, name.length - 1)}o';
}

/// Dicionários do banco, montados uma vez por repositório.
class Lexicons {
  Lexicons._(this.dex)
      : species = Lexicon([for (final e in dex.defaultBySpecies.values) (e.speciesName, e.speciesId)]),
        moves = Lexicon([for (final m in dex.moves) (m.name, m.id)]),
        abilities = Lexicon([for (final a in dex.abilities) (a.name, a.id)]),
        natures = Lexicon([
          for (final n in dex.natures) ...[
            (n.name, n.identifier),
            for (final pt in naturesPt[n.identifier] ?? const <String>[])
              for (final v in _withMasculine(pt)) (v, n.identifier),
          ],
        ]),
        items = Lexicon([for (final i in dex.holdableItems) (i.name, i.id)]),
        balls = Lexicon([for (final b in dex.balls) (b.name, b.id)]),
        types = Lexicon([
          for (final t in dex.types.values) ...[(t.namePt, t.identifier), (t.identifier, t.identifier)],
        ]);

  final DexRepository dex;
  final Lexicon<int> species;
  final Lexicon<int> moves;
  final Lexicon<int> abilities;
  final Lexicon<String> natures;
  final Lexicon<int> items;
  final Lexicon<int> balls;
  final Lexicon<String> types;

  static final _cache = Expando<Lexicons>();
  static Lexicons of(DexRepository dex) => _cache[dex] ??= Lexicons._(dex);
}
