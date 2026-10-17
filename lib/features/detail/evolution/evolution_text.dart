import 'package:flutter/material.dart';

import '../../../core/data/labels.dart';
import '../../../core/data/models.dart';

/// Papel de uma exigência no bloco: só [form] é tratado à parte (some quando regras de formas
/// cosméticas se fundem, como os 20 padrões do Vivillon).
enum RequirementKind { level, item, trade, action, condition, form, chance }

/// Uma exigência de evolução, uma por linha.
class Requirement {
  const Requirement(
    this.icon,
    this.text, {
    this.chip,
    this.item,
    this.type,
    this.kind = RequirementKind.condition,
    this.repeatUnderChip = true,
  });

  final IconData icon;

  /// Frase completa ("Amizade alta (160+)").
  final String text;

  /// Rótulo curto quando a exigência vira o chip da rota ("Amizade"). Null = usa [text].
  final String? chip;

  /// Item com sprite (pedra, item segurado).
  final ItemRef? item;

  /// Identificador de tipo para o glifo ([knownMoveType], [partyType]).
  final String? type;
  final RequirementKind kind;

  /// Se a frase completa ainda aparece embaixo quando esta exigência é o chip.
  /// "Fire Stone" no chip já diz tudo; "Amizade" no chip pede "Amizade alta (160+)" embaixo.
  final bool repeatUnderChip;

  String get chipLabel => chip ?? text;
  bool get _hasShortChip => chip != null && chip != text;
}

/// Exigências de uma regra: o chip (principal) e as demais, uma por linha.
class RequirementBlock {
  RequirementBlock(this.requirements, {required this.isFallback, this.chipIndex = 0})
      : assert(requirements.isNotEmpty);

  final List<Requirement> requirements;

  /// Regra geral mostrada porque o jogo não tem regra registrada.
  final bool isFallback;

  /// Qual exigência vai no chip. Ajustado quando ramos irmãos teriam o mesmo chip.
  int chipIndex;

  Requirement get chip => requirements[chipIndex];

  /// Linhas abaixo do chip, na ordem original.
  List<Requirement> get lines => [
        for (var i = 0; i < requirements.length; i++)
          if (i != chipIndex || (requirements[i].repeatUnderChip && requirements[i]._hasShortChip)) requirements[i],
      ];

  /// Sprite do chip: o item da própria exigência principal.
  ItemRef? get chipItem => chip.item;

  /// Leitura para leitor de tela: "Nível 16" / "Amizade alta (160+), De dia, Subir de nível".
  String get spoken => [for (final r in requirements) r.text].join(', ');

  /// Assinatura para fundir regras iguais (sem as linhas de forma exigida).
  String get signature => [
        if (isFallback) '~',
        for (final r in requirements)
          if (r.kind != RequirementKind.form) '${r.text}#${r.item?.id ?? ''}',
      ].join('|');

  String get formSignature => [
        for (final r in requirements)
          if (r.kind == RequirementKind.form) r.text,
      ].join('|');

  RequirementBlock withoutForm() => RequirementBlock(
        [for (final r in requirements) if (r.kind != RequirementKind.form) r],
        isFallback: isFallback,
      );
}

/// Nome de exibição de uma variedade: formas regionais em pt-BR ("Raichu de Alola");
/// as demais ficam com o nome da PokeAPI ("Midnight Lycanroc").
String evolutionDisplayName(DexEntry e) {
  final region = Labels.regional[e.regional];
  if (region != null) return '${e.speciesName} de $region';
  return e.isDefault ? e.speciesName : e.name;
}

String _thousands(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Transforma uma regra numa lista de exigências em pt-BR. Nomes de golpes, itens, locais e
/// espécies continuam em inglês (PokeAPI); tipos saem traduzidos por [typeName].
///
/// [natures]: nomes das naturezas exigidas (Toxtricity). [requiredForm]: nome da forma exigida
/// da espécie de origem quando ela não é a padrão e não aparece como posto próprio na cadeia;
/// [requiredFormChip] é o rótulo curto dela ("Sandy Cloak").
RequirementBlock describeEvolution(
  EvolutionRule r, {
  required String Function(String typeIdentifier) typeName,
  required String Function(int speciesId) speciesName,
  List<String>? natures,
  String? requiredForm,
  String? requiredFormChip,
}) {
  final reqs = <Requirement>[];
  var levelUpAction = false;
  var heldConsumed = false;
  var timeConsumed = false;
  var locationAsDestination = false;

  switch (r.trigger) {
    case 'level-up':
      if (r.minLevel != null) {
        reqs.add(Requirement(Icons.trending_up_rounded, 'Nível ${r.minLevel}', kind: RequirementKind.level));
      } else {
        levelUpAction = true;
      }
    case 'in-battle-level-up':
      reqs.add(
        r.minLevel != null
            ? Requirement(Icons.trending_up_rounded, 'Nível ${r.minLevel}', kind: RequirementKind.level)
            : const Requirement(Icons.trending_up_rounded, 'Subir de nível', kind: RequirementKind.action),
      );
      reqs.add(const Requirement(Icons.sports_martial_arts_rounded, 'Subindo de nível durante uma batalha', chip: 'Em batalha'));
    case 'trade':
      final held = r.heldItem;
      if (r.tradeSpecies != null) {
        reqs.add(Requirement(Icons.swap_horiz_rounded, 'Troca por ${r.tradeSpecies}', chip: 'Troca', kind: RequirementKind.trade));
      } else if (held != null) {
        heldConsumed = true;
        reqs.add(Requirement(
          Icons.swap_horiz_rounded,
          'Troca segurando ${held.name}',
          chip: 'Troca',
          item: held,
          kind: RequirementKind.trade,
        ));
      } else {
        reqs.add(const Requirement(Icons.swap_horiz_rounded, 'Troca', kind: RequirementKind.trade));
      }
    case 'use-item':
      final item = r.item;
      reqs.add(
        item == null
            ? const Requirement(Icons.backpack_outlined, 'Usar um item', kind: RequirementKind.item)
            : Requirement(
                Icons.backpack_outlined,
                'Usar ${item.name}',
                chip: item.name,
                item: item,
                kind: RequirementKind.item,
                repeatUnderChip: false,
              ),
      );
    case 'shed':
      reqs.add(const Requirement(
        Icons.group_add_outlined,
        'Vaga livre no time e Poké Ball na bolsa',
        chip: 'Vaga no time',
        kind: RequirementKind.action,
      ));
      reqs.add(Requirement(Icons.call_split_rounded, 'Surge quando ${speciesName(r.fromSpeciesId)} evolui'));
    case 'spin':
      heldConsumed = true;
      timeConsumed = true;
      reqs.add(const Requirement(
        Icons.rotate_right_rounded,
        'Girar o personagem segurando um doce',
        chip: 'Girar',
        kind: RequirementKind.action,
      ));
      reqs.add(const Requirement(Icons.tune_rounded, 'O sentido e o tempo do giro, a hora e o doce definem a forma'));
    case 'tower-of-darkness':
      reqs.add(const Requirement(Icons.castle_outlined, 'Vencer a Torre da Escuridão', chip: 'Torre da Escuridão', kind: RequirementKind.action));
    case 'tower-of-waters':
      reqs.add(const Requirement(Icons.castle_outlined, 'Vencer a Torre das Águas', chip: 'Torre das Águas', kind: RequirementKind.action));
    case 'three-critical-hits':
      reqs.add(const Requirement(Icons.gps_fixed_rounded, '3 golpes críticos numa batalha', chip: '3 críticos', kind: RequirementKind.action));
    case 'take-damage':
      locationAsDestination = true;
      final n = r.minDamageTaken;
      reqs.add(Requirement(
        Icons.heart_broken_outlined,
        n == null ? 'Sofrer dano sem desmaiar' : 'Sofrer $n de dano sem desmaiar',
        chip: n == null ? 'Sofrer dano' : '$n de dano',
        kind: RequirementKind.action,
      ));
    case 'agile-style-move' || 'strong-style-move':
      final style = r.trigger == 'agile-style-move' ? 'Estilo Ágil' : 'Estilo Forte';
      final move = r.usedMove ?? 'o golpe';
      final count = r.minMoveCount == null ? '' : ' ${r.minMoveCount}×';
      reqs.add(Requirement(Icons.bolt_rounded, 'Usar $move em $style$count', chip: r.usedMove ?? style, kind: RequirementKind.action));
    case 'recoil-damage':
      final n = r.minDamageTaken;
      reqs.add(Requirement(
        Icons.heart_broken_outlined,
        n == null ? 'Sofrer dano de recuo sem desmaiar' : 'Sofrer $n de dano de recuo sem desmaiar',
        chip: n == null ? 'Dano de recuo' : '$n de recuo',
        kind: RequirementKind.action,
      ));
    case 'use-move':
      final move = r.usedMove ?? 'o golpe';
      final count = r.minMoveCount == null ? '' : ' ${r.minMoveCount}×';
      reqs.add(Requirement(Icons.bolt_rounded, 'Usar $move$count', chip: r.usedMove, kind: RequirementKind.action));
    case 'three-defeated-bisharp':
      heldConsumed = true;
      final crest = r.heldItem;
      reqs.add(Requirement(
        Icons.emoji_events_outlined,
        "Derrotar 3 Bisharp que seguram ${crest?.name ?? "Leader's Crest"}",
        chip: '3 Bisharp',
        item: crest,
        kind: RequirementKind.action,
      ));
    case 'gimmighoul-coins':
      reqs.add(const Requirement(Icons.paid_outlined, 'Juntar 999 Gimmighoul Coins', chip: '999 moedas', kind: RequirementKind.action));
    case 'meltan-candies':
      reqs.add(const Requirement(
        Icons.phone_android_rounded,
        '400 Meltan Candy (Pokémon GO)',
        chip: 'Pokémon GO',
        kind: RequirementKind.action,
      ));
    default:
      reqs.add(const Requirement(Icons.help_outline_rounded, 'Condição especial', chip: 'Especial', kind: RequirementKind.action));
  }

  // Condições, em ordem de prioridade para o chip.
  final held = r.heldItem;
  if (held != null && !heldConsumed) {
    reqs.add(Requirement(Icons.back_hand_outlined, 'Segurando ${held.name}', chip: held.name, item: held, kind: RequirementKind.item));
  }
  if (r.knownMove != null) {
    reqs.add(Requirement(Icons.bolt_rounded, 'Conhecendo o golpe ${r.knownMove}', chip: r.knownMove));
  }
  final moveType = r.knownMoveType;
  if (moveType != null) {
    final t = typeName(moveType);
    reqs.add(Requirement(Icons.bolt_rounded, 'Conhecendo golpe do tipo $t', chip: 'Golpe $t', type: moveType));
  }
  if (r.location != null) {
    reqs.add(Requirement(
      Icons.place_outlined,
      locationAsDestination ? 'Ir a ${r.location}' : 'Em ${r.location}',
    ));
  }
  if (r.nearSpecialRock) {
    reqs.add(const Requirement(Icons.landscape_outlined, 'Perto de pedra especial', chip: 'Pedra especial'));
  }
  final happiness = r.minHappiness;
  if (happiness != null) {
    reqs.add(Requirement(
      Icons.favorite_border_rounded,
      happiness >= 220 ? 'Amizade $happiness+' : 'Amizade alta ($happiness+)',
      chip: 'Amizade',
    ));
  }
  if (r.minAffection != null) {
    reqs.add(Requirement(Icons.favorite_rounded, 'Afeto ${r.minAffection}+ corações', chip: 'Afeto'));
  }
  if (r.minBeauty != null) {
    reqs.add(Requirement(Icons.auto_awesome_outlined, 'Beleza ${r.minBeauty}+', chip: 'Beleza'));
  }
  if (r.partySpecies != null) {
    reqs.add(Requirement(Icons.groups_outlined, 'Com ${r.partySpecies} no time', chip: '${r.partySpecies} no time'));
  }
  final partyType = r.partyType;
  if (partyType != null) {
    final t = typeName(partyType);
    reqs.add(Requirement(Icons.groups_outlined, 'Com Pokémon do tipo $t no time', chip: '$t no time', type: partyType));
  }
  if (r.trigger != 'trade' && r.tradeSpecies != null) {
    reqs.add(Requirement(Icons.swap_horiz_rounded, 'Troca por ${r.tradeSpecies}', chip: 'Troca', kind: RequirementKind.trade));
  }
  switch (r.relativePhysicalStats) {
    case 1:
      reqs.add(const Requirement(Icons.balance_rounded, 'Ataque > Defesa'));
    case -1:
      reqs.add(const Requirement(Icons.balance_rounded, 'Ataque < Defesa'));
    case 0:
      reqs.add(const Requirement(Icons.balance_rounded, 'Ataque = Defesa'));
  }
  if (r.needsOverworldRain) {
    reqs.add(const Requirement(Icons.water_drop_outlined, 'Com chuva no mapa', chip: 'Chuva'));
  }
  if (r.turnUpsideDown) {
    reqs.add(const Requirement(Icons.screen_rotation_rounded, 'Com o aparelho de cabeça para baixo', chip: 'De cabeça para baixo'));
  }
  final steps = r.minSteps;
  if (steps != null) {
    final n = _thousands(steps);
    reqs.add(Requirement(Icons.directions_walk_rounded, 'Andar $n passos com ele fora da Poké Ball', chip: '$n passos'));
  }
  final time = Labels.timeOfDay[r.timeOfDay];
  if (time != null && !timeConsumed) {
    reqs.add(Requirement(_timeIcon(r.timeOfDay!), _capitalize(time)));
  }
  switch (r.genderId) {
    case 1:
      reqs.add(const Requirement(Icons.female_rounded, 'Só fêmea'));
    case 2:
      reqs.add(const Requirement(Icons.male_rounded, 'Só macho'));
  }
  if (r.region != null) {
    reqs.add(Requirement(Icons.public_rounded, 'Em ${r.region}'));
  }
  if (r.needsMultiplayer) {
    reqs.add(const Requirement(Icons.people_outline_rounded, 'Em modo multijogador', chip: 'Multijogador'));
  }
  if (natures != null && natures.isNotEmpty) {
    final list = natures.length == 1
        ? natures.first
        : '${natures.sublist(0, natures.length - 1).join(', ')} ou ${natures.last}';
    reqs.add(Requirement(Icons.psychology_outlined, 'Natureza $list', chip: 'Natureza'));
  }
  if (requiredForm != null) {
    reqs.add(Requirement(
      Icons.category_outlined,
      'Precisa ser $requiredForm',
      chip: requiredFormChip,
      kind: RequirementKind.form,
    ));
  }
  final chance = r.percentageChance;
  if (chance != null) {
    reqs.add(Requirement(Icons.casino_outlined, '$chance% de chance', kind: RequirementKind.chance));
  }
  final expr = r.conditionExpression?.trim();
  if (expr != null && expr.isNotEmpty && r.trigger != 'spin') {
    // EC/PID decidem um sorteio que a chance já descreve; o resto não tem tradução direta.
    final isRandomSplit = chance != null && (expr.startsWith('EC ') || expr.startsWith('PID '));
    if (!isRandomSplit) {
      reqs.add(const Requirement(Icons.help_outline_rounded, 'Condição especial do jogo'));
    }
  }
  if (levelUpAction) {
    reqs.add(const Requirement(Icons.trending_up_rounded, 'Subir de nível', kind: RequirementKind.action));
  }

  return RequirementBlock(reqs, isFallback: r.isFallback);
}

IconData _timeIcon(String time) => switch (time) {
      'day' => Icons.wb_sunny_outlined,
      'night' => Icons.nightlight_outlined,
      'dusk' => Icons.wb_twilight_rounded,
      _ => Icons.brightness_2_outlined,
    };

/// Ramos irmãos (mesmo posto de origem) com o mesmo chip ficam indistinguíveis ("Nível 20" ×3 no
/// Tyrogue, "Amizade" no Espeon e no Umbreon). Troca o chip pela primeira exigência que só aquele
/// ramo tem ("Ataque > Defesa", "De dia").
void disambiguateChips(List<List<RequirementBlock>> siblingEdges) {
  if (siblingEdges.length < 2) return;
  for (var e = 0; e < siblingEdges.length; e++) {
    final otherLabels = <String>{};
    final otherChips = <String>{};
    for (var o = 0; o < siblingEdges.length; o++) {
      if (o == e) continue;
      for (final b in siblingEdges[o]) {
        otherChips.add(b.chip.chipLabel);
        for (final r in b.requirements) {
          otherLabels.add(r.chipLabel);
        }
      }
    }
    for (final b in siblingEdges[e]) {
      if (!otherChips.contains(b.chip.chipLabel)) continue;
      for (var i = 0; i < b.requirements.length; i++) {
        final r = b.requirements[i];
        if (!otherLabels.contains(r.chipLabel)) {
          b.chipIndex = i;
          break;
        }
      }
    }
  }
}
