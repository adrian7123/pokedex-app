/// Da leitura somada para a espécie/forma, validando cada campo contra o banco.
library;

import '../../core/data/dex_repository.dart';
import '../../core/data/models.dart';
import '../../core/logic/stats_calc.dart';
import 'matcher.dart';
import 'reading.dart';
import 'sv_parser.dart' show speciesKey;

/// Como a espécie foi decidida.
enum SpeciesSource { read, inferred, chosen, given, none }

class ScanOutcome {
  ScanOutcome({
    required this.entry,
    required this.source,
    required this.speciesConfidence,
    required this.alternatives,
    required this.values,
    required this.low,
    required this.ivRanges,
    required this.natureKnown,
    required this.warnings,
    this.genderRate,
  });

  /// Proporção de fêmeas em oitavos (-1 = sem gênero), quando a espécie é conhecida.
  final int? genderRate;

  final DexEntry? entry;
  final SpeciesSource source;
  final Confidence speciesConfidence;

  /// Outras espécies/formas que explicam a leitura quase tão bem.
  final List<DexEntry> alternatives;

  /// Valores finais por campo ([F]); stats em [F.stat].
  final Map<String, Reading<Object>> values;

  /// Campos para conferir.
  final Set<String> low;

  /// Faixas de IV por stat (null = sem leitura ou nada explica o valor).
  final List<(int, int)?> ivRanges;
  final bool natureKnown;
  final List<String> warnings;

  T? value<T extends Object>(String key) {
    final v = values[key]?.value;
    return v is T ? v : null;
  }

  List<int?> get stats => [for (var i = 0; i < 6; i++) value<int>(F.stat(i))];
}

Nature _bias(int? up, int? down) => Nature(id: 0, identifier: '', name: '', increased: up, decreased: down);

/// Pontua uma variedade contra o que foi lido. Positivo = combina.
double _score(
  DexEntry e,
  DexRepository dex,
  int vgId, {
  int? ability,
  int? level,
  required List<int?> stats,
  Nature? nature,
  int? dexNumber,
  Map<int, int>? regional,
}) {
  var s = 0.0;
  if (ability != null) s += e.abilityIds.contains(ability) ? 4 : -4;
  if (level != null) {
    for (var i = 0; i < 6; i++) {
      final obs = stats[i];
      if (obs == null) continue;
      final base = e.stats[i];
      final lo = StatsCalc.value(i, base, 0, 0, level, nature ?? (i == 0 ? null : _bias(null, i)));
      final hiPlain = StatsCalc.value(i, base, 31, 0, level, nature ?? (i == 0 ? null : _bias(i, null)));
      final hiEv = StatsCalc.value(i, base, 31, 252, level, nature ?? (i == 0 ? null : _bias(i, null)));
      if (obs >= lo && obs <= hiPlain) {
        s += 1;
      } else if (obs > hiPlain && obs <= hiEv) {
        s += .3;
      } else {
        s -= 3;
      }
    }
  }
  if (dexNumber != null && (e.speciesId == dexNumber || regional?[e.speciesId] == dexNumber)) s += 2;
  if (dex.formInGame(vgId, e.speciesId) == e.pokemonId) s += .5;
  return s;
}

bool _selectable(DexEntry e) => !e.isMega && !e.isGmax && !e.isBattleOnly;

/// [vgId]: jogo da leitura (Scarlet/Violet). [chosenPokemonId]: escolha manual do usuário.
/// [givenSpeciesId]: espécie do exemplar que pediu "Atualizar por foto".
Future<ScanOutcome> resolveScan(
  MergedReading reading,
  DexRepository dex, {
  required int vgId,
  int? chosenPokemonId,
  int? givenSpeciesId,
}) async {
  final warnings = <String>[];
  final ability = reading.value<int>(F.abilityId);
  final abilitySure = ability != null && !reading.isLow(F.abilityId);
  final level = reading.value<int>(F.level);
  final stats = [for (var i = 0; i < 6; i++) reading.value<int>(F.stat(i))];
  final natureId = reading.value<String>(F.nature);
  final nature = natureId == null ? null : dex.natures.where((n) => n.identifier == natureId).firstOrNull;
  final dexNumber = reading.value<int>(F.dexNumber);
  final moves = reading.value<List<int>>(F.moves) ?? const <int>[];
  final readSpecies = reading.value<int>(speciesKey);
  final regional = dex.speciesInGame(vgId);

  double score(DexEntry e) => _score(
        e,
        dex,
        vgId,
        ability: abilitySure ? ability : null,
        level: level,
        stats: stats,
        nature: nature,
        dexNumber: dexNumber,
        regional: regional,
      );

  /// Ordena por pontuação; empates próximos vão para o desempate pelos golpes aprendidos.
  Future<List<(DexEntry, double)>> rank(Iterable<DexEntry> pool) async {
    final ranked = [for (final e in pool.where(_selectable)) (e, score(e))]..sort((a, b) => b.$2.compareTo(a.$2));
    if (ranked.length > 1 && moves.isNotEmpty && ranked[0].$2 - ranked[1].$2 < 1.5) {
      final top = ranked.take(5).toList();
      final rescored = <(DexEntry, double)>[];
      for (final (e, s) in top) {
        final (learn, _) = await dex.learnset(e.pokemonId, vgId);
        final known = {for (final m in learn) m.moveId};
        var bonus = 0.0;
        for (final m in moves) {
          bonus += known.contains(m) ? .6 : -1;
        }
        rescored.add((e, s + bonus));
      }
      rescored.sort((a, b) => b.$2.compareTo(a.$2));
      return [...rescored, ...ranked.skip(5)];
    }
    return ranked;
  }

  DexEntry? entry;
  var source = SpeciesSource.none;
  var conf = Confidence.low;
  var alternatives = <DexEntry>[];

  if (chosenPokemonId != null) {
    entry = dex.byPokemonId[chosenPokemonId];
    source = SpeciesSource.chosen;
    conf = Confidence.high;
  } else {
    var speciesId = givenSpeciesId;
    if (speciesId != null) {
      source = SpeciesSource.given;
      if (readSpecies != null && readSpecies != speciesId && !reading.isLow(speciesKey)) {
        final other = dex.defaultBySpecies[readSpecies]?.speciesName;
        if (other != null) warnings.add('A foto parece ser de $other, não deste exemplar.');
      }
    } else if (readSpecies != null) {
      final forms = dex.formsBySpecies[readSpecies] ?? const <DexEntry>[];
      // Nome que casa com uma espécie, mas a habilidade não existe em nenhuma forma dela:
      // é um apelido parecido com o nome de outra espécie.
      final contradicts = abilitySure && forms.isNotEmpty && forms.every((f) => !f.abilityIds.contains(ability));
      if (!contradicts) {
        speciesId = readSpecies;
        source = SpeciesSource.read;
      }
    }

    if (speciesId != null) {
      final ranked = await rank(dex.formsBySpecies[speciesId] ?? const []);
      if (ranked.isNotEmpty) {
        entry = ranked.first.$1;
        final speciesHigh = source == SpeciesSource.given || !reading.isLow(speciesKey);
        final tie = ranked.length > 1 && ranked.first.$2 - ranked[1].$2 < 1;
        conf = speciesHigh && !tie ? Confidence.high : Confidence.low;
        if (tie) {
          // Formas indistinguíveis pela leitura: fica a do jogo, e as outras viram sugestão.
          final inGame = dex.formInGame(vgId, speciesId);
          final pick = ranked.where((r) => r.$1.pokemonId == inGame).firstOrNull;
          if (pick != null && ranked.first.$2 - pick.$2 < 1) entry = pick.$1;
          alternatives = [
            for (final r in ranked)
              if (r.$1 != entry && ranked.first.$2 - r.$2 < 1) r.$1,
          ];
        }
      }
    } else {
      final enough = abilitySure || (level != null && stats.whereType<int>().length >= 4);
      if (enough) {
        final available = dex.availableInGame(vgId);
        final pool = available.isEmpty
            ? dex.entries
            : [
                for (final sid in available) ...?dex.formsBySpecies[sid],
              ];
        final ranked = await rank(pool);
        if (ranked.isNotEmpty && ranked.first.$2 >= 3) {
          entry = ranked.first.$1;
          source = SpeciesSource.inferred;
          alternatives = [
            for (final r in ranked.skip(1).take(6))
              if (ranked.first.$2 - r.$2 < 1.5) r.$1,
          ].take(3).toList();
        }
      } else if (dexNumber != null && dex.defaultBySpecies[dexNumber] != null) {
        entry = dex.defaultBySpecies[dexNumber];
        source = SpeciesSource.inferred;
      }
    }
  }

  final values = <String, Reading<Object>>{
    for (final e in reading.chosen.entries)
      if (!e.key.startsWith('_')) e.key: e.value,
  };
  final low = <String>{
    for (final e in values.entries)
      if (!e.value.isHigh) e.key,
  };

  // Apelido: o nome lido que não é o nome da espécie.
  final name = reading.value<String>(F.name);
  values.remove(F.nickname);
  low.remove(F.nickname);
  if (entry != null && name != null && similarity(name, entry.speciesName) < .8) {
    final nick = reading.chosen[F.nickname] ?? reading.chosen[F.name]!;
    values[F.nickname] = nick;
    if (!nick.isHigh) low.add(F.nickname);
  } else if (entry == null && name != null) {
    values[F.nickname] = reading.chosen[F.name]!.withConfidence(Confidence.low);
  }

  var ivRanges = List<(int, int)?>.filled(6, null);
  int? genderRate;
  if (entry != null) {
    values[F.pokemonId] = Reading(entry.pokemonId, conf);
    if (conf == Confidence.low) low.add(F.pokemonId);

    if (ability != null && !entry.abilityIds.contains(ability)) low.add(F.abilityId);

    // Gênero: espécie sem gênero ou de gênero único decide sozinha.
    final detail = await dex.speciesDetail(entry.speciesId, entry.pokemonId);
    genderRate = detail.genderRate;
    switch (detail.genderRate) {
      case -1:
        values.remove(F.gender);
        low.remove(F.gender);
      case 0:
        values[F.gender] = const Reading<Object>('m', Confidence.high);
        low.remove(F.gender);
      case 8:
        values[F.gender] = const Reading<Object>('f', Confidence.high);
        low.remove(F.gender);
    }

    if (moves.isNotEmpty) {
      final (learn, _) = await dex.learnset(entry.pokemonId, vgId);
      final known = {for (final m in learn) m.moveId};
      if (known.isNotEmpty && moves.any((m) => !known.contains(m))) low.add(F.moves);
    }

    if (level != null) {
      for (var i = 0; i < 6; i++) {
        final obs = stats[i];
        if (obs == null) continue;
        final base = entry.stats[i];
        final lo = StatsCalc.value(i, base, 0, 0, level, nature ?? (i == 0 ? null : _bias(null, i)));
        final hi = StatsCalc.value(i, base, 31, 252, level, nature ?? (i == 0 ? null : _bias(i, null)));
        if (obs < lo || obs > hi) low.add(F.stat(i));
      }
      ivRanges = [
        for (var i = 0; i < 6; i++)
          if (stats[i] == null)
            null
          else if (nature != null || i == 0)
            StatsCalc.ivRange(i, stats[i]!, entry.stats[i], level, nature: nature)
          else
            // Sem natureza: neutra; se não fechar, tenta com o stat favorecido ou prejudicado.
            StatsCalc.ivRange(i, stats[i]!, entry.stats[i], level) ??
                _union(
                  StatsCalc.ivRange(i, stats[i]!, entry.stats[i], level, nature: _bias(i, null)),
                  StatsCalc.ivRange(i, stats[i]!, entry.stats[i], level, nature: _bias(null, i)),
                ),
      ];
    }
  }

  return ScanOutcome(
    entry: entry,
    source: source,
    speciesConfidence: conf,
    alternatives: alternatives,
    values: values,
    low: low,
    ivRanges: ivRanges,
    natureKnown: nature != null,
    warnings: warnings,
    genderRate: genderRate,
  );
}

(int, int)? _union((int, int)? a, (int, int)? b) {
  if (a == null) return b;
  if (b == null) return a;
  return (a.$1 < b.$1 ? a.$1 : b.$1, a.$2 > b.$2 ? a.$2 : b.$2);
}
