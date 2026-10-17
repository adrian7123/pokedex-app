/// Modelos de leitura do banco de referência. Nomes de dados em inglês (PokeAPI);
/// rótulos de UI em pt-BR ficam em `labels.dart`.
library;

class TypeInfo {
  const TypeInfo({required this.id, required this.identifier, required this.namePt});
  final int id;
  final String identifier;
  final String namePt;
}

class Generation {
  const Generation({required this.id, required this.identifier, required this.mainRegionId});
  final int id;
  final String identifier;
  final int? mainRegionId;

  /// "Geração IV"
  String get label => 'Geração ${_roman[id - 1]}';
  String get roman => _roman[id - 1];
  static const _roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
}

class Region {
  const Region({required this.id, required this.identifier, required this.name});
  final int id;
  final String identifier;
  final String name;
}

class VersionGroup {
  const VersionGroup({
    required this.id,
    required this.identifier,
    required this.name,
    required this.generationId,
    required this.sortOrder,
    required this.parentId,
    required this.isDlc,
    required this.versions,
    required this.pokedexIds,
    required this.isClosedDex,
    required this.hasMegaEvolution,
    required this.routeSource,
  });
  final int id;
  final String identifier;
  final String name;
  final int generationId;
  final int sortOrder;
  final int? parentId;
  final bool isDlc;
  final List<Version> versions;
  final List<int> pokedexIds;

  /// Jogo que não tem Pokédex Nacional (só a regional + DLC).
  final bool isClosedDex;
  final bool hasMegaEvolution;

  /// Origem das rotas do Nuzlocke: `encounters`, `region-locations` ou `free-text`.
  final String routeSource;

  /// Dynamax/Gigantamax só existe em Sword/Shield.
  bool get hasGigantamax => identifier == 'sword-shield';

  /// Jogos que viram "aventura": série principal, sem DLC (que herda do jogo base) e sem variantes JP.
  bool get isPlayable => !isDlc && parentId == null && identifier != 'champions' && identifier != 'colosseum' && identifier != 'xd';
}

class Version {
  const Version({
    required this.id,
    required this.identifier,
    required this.name,
    required this.versionGroupId,
    this.parentVersionId,
  });
  final int id;
  final String identifier;
  final String name;
  final int versionGroupId;

  /// Versão de DLC aponta para o cartucho base (ex.: Shield + Isle of Armor → Shield).
  final int? parentVersionId;
}

class Pokedex {
  const Pokedex({
    required this.id,
    required this.identifier,
    required this.name,
    required this.regionId,
    required this.isMainSeries,
    required this.size,
  });
  final int id;
  final String identifier;
  final String name;
  final int? regionId;
  final bool isMainSeries;
  final int size;
}

/// Uma variedade (pokemon.id) com tudo que a lista precisa para buscar, filtrar e desenhar.
class DexEntry {
  DexEntry({
    required this.pokemonId,
    required this.speciesId,
    required this.identifier,
    required this.name,
    required this.speciesName,
    required this.formName,
    required this.isDefault,
    required this.type1,
    required this.type2,
    required this.generationId,
    required this.stats,
    required this.height,
    required this.weight,
    required this.isLegendary,
    required this.isMythical,
    required this.isBaby,
    required this.isMega,
    required this.isGmax,
    required this.regional,
    required this.isBattleOnly,
    required this.categories,
    required this.abilityIds,
    required this.eggGroupIds,
    required this.hasSprite,
    required this.hasShinySprite,
    required this.sortOrder,
    required this.evolutionChainId,
    required this.evolvesFromSpeciesId,
    required this.evolvesByTriggerIds,
    required this.genus,
  });

  final int pokemonId;
  final int speciesId;
  final String identifier;
  final String name;
  final String speciesName;
  final String? formName;
  final bool isDefault;
  final String type1;
  final String? type2;
  final int generationId;

  /// hp, attack, defense, sp_attack, sp_defense, speed, total
  final List<int> stats;
  final int height;
  final int weight;
  final bool isLegendary;
  final bool isMythical;
  final bool isBaby;
  final bool isMega;
  final bool isGmax;
  final String? regional;
  final bool isBattleOnly;

  /// ultra-beast, paradox, starter, starter-base, pseudo-legendary
  final Set<String> categories;
  final Set<int> abilityIds;
  final Set<int> eggGroupIds;
  final bool hasSprite;
  final bool hasShinySprite;
  final int sortOrder;
  final int? evolutionChainId;
  final int? evolvesFromSpeciesId;

  /// Gatilhos das regras que levam esta espécie a evoluir (para o filtro "método de evolução").
  final Set<int> evolvesByTriggerIds;
  final String? genus;

  int get nationalNumber => speciesId;
  int get total => stats[6];
  List<String> get types => [type1, ?type2];

  /// Variedade para o sprite: algumas formas não têm arquivo, então caem no padrão da espécie.
  String spritePath({bool shiny = false}) {
    final ok = shiny ? hasShinySprite : hasSprite;
    final id = ok ? pokemonId : speciesId;
    return shiny ? 'assets/sprites/pokemon/shiny/$id.png' : 'assets/sprites/pokemon/$id.png';
  }

  /// Texto normalizado para a busca (sem acento, minúsculo).
  late final String searchKey = normalize('$name $speciesName ${formName ?? ''} $identifier');

  static String normalize(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ♀♂’\'.:-';
    const to = 'aaaaaeeeeiiiiooooouuuucnfm    ';
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : (i < to.length ? to[i] : ' '));
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class Ability {
  const Ability({required this.id, required this.name, required this.shortEffect, required this.isHidden});
  final int id;
  final String name;
  final String? shortEffect;
  final bool isHidden;
}

class NamedRef {
  const NamedRef(this.id, this.name);
  final int id;
  final String name;
}

/// Golpe aprendido num jogo.
class LearnedMove {
  const LearnedMove({
    required this.moveId,
    required this.name,
    required this.type,
    required this.damageClass,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.methodId,
    required this.method,
    required this.level,
    required this.machine,
    required this.shortEffect,
  });
  final int moveId;
  final String name;
  final String? type;
  final String? damageClass; // status / physical / special
  final int? power;
  final int? accuracy;
  final int? pp;
  final int methodId;
  final String method; // level-up, machine, egg, tutor...
  final int level;
  final String? machine;
  final String? shortEffect;
}

/// Uma regra de evolução já resolvida para exibição.
class EvolutionRule {
  const EvolutionRule({
    required this.id,
    required this.fromSpeciesId,
    required this.toSpeciesId,
    required this.trigger,
    required this.minLevel,
    required this.item,
    required this.heldItem,
    required this.timeOfDay,
    required this.knownMove,
    required this.knownMoveType,
    required this.location,
    required this.minHappiness,
    required this.minBeauty,
    required this.minAffection,
    required this.relativePhysicalStats,
    required this.partySpecies,
    required this.partyType,
    required this.tradeSpecies,
    required this.genderId,
    required this.needsOverworldRain,
    required this.turnUpsideDown,
    required this.needsMultiplayer,
    required this.nearSpecialRock,
    required this.region,
    required this.requiredFormId,
    required this.evolvedFormId,
    required this.evolvedPokemonId,
    required this.usedMove,
    required this.minMoveCount,
    required this.minSteps,
    required this.minDamageTaken,
    required this.conditionExpression,
    required this.percentageChance,
    required this.isFallback,
  });

  final int id;
  final int fromSpeciesId;
  final int toSpeciesId;
  final String trigger;
  final int? minLevel;
  final ItemRef? item;
  final ItemRef? heldItem;
  final String? timeOfDay;
  final String? knownMove;
  final String? knownMoveType;
  final String? location;
  final int? minHappiness;
  final int? minBeauty;
  final int? minAffection;
  final int? relativePhysicalStats;
  final String? partySpecies;
  final String? partyType;
  final String? tradeSpecies;
  final int? genderId;
  final bool needsOverworldRain;
  final bool turnUpsideDown;
  final bool needsMultiplayer;
  final bool nearSpecialRock;
  final String? region;
  final int? requiredFormId;
  final int? evolvedFormId;

  /// Variedade resultante quando a regra gera uma forma (ex.: Raichu de Alola).
  final int? evolvedPokemonId;
  final String? usedMove;
  final int? minMoveCount;
  final int? minSteps;
  final int? minDamageTaken;
  final String? conditionExpression;
  final int? percentageChance;

  /// Regra geral (is_default) mostrada porque o jogo não tem regra registrada.
  final bool isFallback;
}

class ItemRef {
  const ItemRef({required this.id, required this.identifier, required this.name, required this.hasSprite});
  final int id;
  final String identifier;
  final String name;
  final bool hasSprite;
  String get spritePath => 'assets/sprites/items/$identifier.png';
}

/// Megas/gmax: forma que se alcança por item/fator, sem ser evolução.
class FormChange {
  const FormChange({required this.pokemonId, required this.name, required this.item, required this.isGmax});
  final int pokemonId;
  final String name;
  final ItemRef? item;
  final bool isGmax;
}

class EvolutionChain {
  const EvolutionChain({required this.chainId, required this.speciesIds, required this.rules, required this.formChanges});
  final int chainId;

  /// Espécies da cadeia em ordem.
  final List<int> speciesIds;
  final List<EvolutionRule> rules;

  /// speciesId → megas/gmax
  final Map<int, List<FormChange>> formChanges;
}

class Encounter {
  const Encounter({
    required this.area,
    required this.method,
    required this.minLevel,
    required this.maxLevel,
    required this.rarity,
    required this.conditions,
  });
  final String area;
  final String method;
  final int minLevel;
  final int maxLevel;
  final int rarity;
  final String? conditions;
}

class SpeciesDetail {
  const SpeciesDetail({
    required this.genderRate,
    required this.captureRate,
    required this.baseHappiness,
    required this.hatchCounter,
    required this.growthRate,
    required this.eggGroups,
    required this.abilities,
    required this.evYield,
    required this.baseExperience,
  });
  final int genderRate;
  final int? captureRate;
  final int? baseHappiness;
  final int? hatchCounter;
  final String? growthRate;
  final List<String> eggGroups;
  final List<Ability> abilities;

  /// stat (pt-BR) → valor
  final Map<String, int> evYield;
  final int? baseExperience;
}

/// Natureza: [increased]/[decreased] são índices em stats (0 hp … 5 speed); null = neutra.
class Nature {
  const Nature({required this.id, required this.identifier, required this.name, this.increased, this.decreased});
  final int id;
  final String identifier;
  final String name;
  final int? increased;
  final int? decreased;

  /// Multiplicador da natureza no stat [i] (1.1, 0.9 ou 1.0). PS nunca muda.
  double factor(int i) => i == increased ? 1.1 : (i == decreased ? 0.9 : 1.0);
}
