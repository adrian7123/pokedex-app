import '../../../core/data/dex_database.dart';
import '../../../core/data/dex_repository.dart';
import '../../../core/data/labels.dart';
import '../../../core/data/models.dart';
import 'evolution_text.dart';

/// Um posto da cartela: uma variedade (pokemon.id) dentro da cadeia.
class EvoNode {
  EvoNode(this.entry);
  final DexEntry entry;
  final List<EvoEdge> edges = [];
  final List<EvoEdge> incoming = [];
  int depth = 0;

  int get pokemonId => entry.pokemonId;
  int get speciesId => entry.speciesId;
}

/// Um trecho da rota: origem → destino, com uma ou mais alternativas ("ou").
class EvoEdge {
  EvoEdge(this.from, this.to, this.blocks);
  final EvoNode from;
  final EvoNode to;
  final List<RequirementBlock> blocks;

  String spoken(String Function(DexEntry) name) =>
      '${name(from.entry)} evolui para ${name(to.entry)}: ${[for (final b in blocks) b.spoken].join('; ou ')}';
}

/// Cadeia pronta para desenhar: postos, trechos e formas de batalha, já no contexto do jogo.
class EvolutionGraph {
  EvolutionGraph._(this.roots, this.nodes, this.formChanges, this.speciesOrder);

  final List<EvoNode> roots;
  final List<EvoNode> nodes;
  final Map<int, List<FormChange>> formChanges;
  final List<int> speciesOrder;

  bool get evolves => nodes.any((n) => n.edges.isNotEmpty);

  int get maxDepth => nodes.fold(0, (m, n) => n.depth > m ? n.depth : m);

  /// Nós com trechos de saída, na ordem da cadeia (para a disposição em linhas).
  List<EvoNode> get fans {
    final out = <EvoNode>[];
    void walk(EvoNode n) {
      if (n.edges.isNotEmpty) out.add(n);
      for (final e in n.edges) {
        walk(e.to);
      }
    }

    roots.forEach(walk);
    return out;
  }

  /// Formas de batalha na ordem da cadeia.
  List<FormChange> get battleForms => [
        for (final sid in speciesOrder) ...?formChanges[sid],
      ];

  static Future<EvolutionGraph> load(DexRepository dex, int chainId, int? vgId) async {
    final chain = await dex.evolutionChain(chainId, vgId: vgId);

    // Formas exigidas (pokemon_forms) e naturezas: o modelo do núcleo ainda não traz.
    final formIds = {for (final r in chain.rules) ?r.requiredFormId}.toList();
    final forms = <int, _FormInfo>{};
    if (formIds.isNotEmpty) {
      final rows = await dex.db.rows(
        'SELECT id, pokemon_id, form_name, is_default FROM pokemon_forms WHERE id IN (${List.filled(formIds.length, '?').join(',')})',
        formIds,
      );
      for (final r in rows) {
        forms[r.i('id')] = _FormInfo(r.i('pokemon_id'), r.ns('form_name'), r.b('is_default'));
      }
    }
    final natures = <int, List<String>>{};
    final masks = await dex.db.rows(
      'SELECT id, nature_bitmask FROM evolutions WHERE evolution_chain_id = ? AND nature_bitmask IS NOT NULL',
      [chainId],
    );
    if (masks.isNotEmpty) {
      final names = {for (final r in await dex.db.rows('SELECT id, name FROM natures ORDER BY id')) r.i('id'): r.s('name')};
      for (final m in masks) {
        final mask = m.i('nature_bitmask');
        natures[m.i('id')] = [
          for (final e in names.entries)
            if ((mask >> (e.key - 1)) & 1 == 1) e.value,
        ];
      }
    }
    return _build(dex, chain, vgId, forms, natures);
  }

  static EvolutionGraph _build(
    DexRepository dex,
    EvolutionChain chain,
    int? vgId,
    Map<int, _FormInfo> forms,
    Map<int, List<String>> natures,
  ) {
    final order = {for (final (i, id) in chain.speciesIds.indexed) id: i};
    final nodes = <int, EvoNode>{};
    EvoNode? node(int pid) {
      final e = dex.byPokemonId[pid];
      if (e == null) return null;
      return nodes.putIfAbsent(pid, () => EvoNode(e));
    }

    int defaultPid(int sid) => dex.defaultBySpecies[sid]?.pokemonId ?? sid;
    int basePid(int sid) => vgId == null ? defaultPid(sid) : dex.formInGame(vgId, sid);

    final rules = [
      for (final r in chain.rules)
        if (dex.defaultBySpecies.containsKey(r.fromSpeciesId) && dex.defaultBySpecies.containsKey(r.toSpeciesId)) r,
    ];
    final targets = {for (final r in rules) r.toSpeciesId};
    bool isRootSpecies(int sid) => !targets.contains(sid);

    // 1. Destinos: a variedade que a regra gera (Raichu de Alola) ou a padrão da espécie.
    final destOf = <int, int>{};
    for (final r in rules) {
      final evolved = r.evolvedPokemonId;
      final pid = evolved != null && dex.byPokemonId[evolved]?.speciesId == r.toSpeciesId ? evolved : defaultPid(r.toSpeciesId);
      destOf[r.id] = pid;
      node(pid);
    }
    // 2. Postos iniciais: a variedade do jogo (Growlithe de Hisui em Legends: Arceus).
    for (final sid in chain.speciesIds) {
      if (isRootSpecies(sid) && rules.any((r) => r.fromSpeciesId == sid && r.requiredFormId == null)) node(basePid(sid));
    }

    // 3. Origens. Forma exigida que já é posto: sai dele. Espécie inicial: a variedade vira posto
    // próprio (Sneasel e Sneasel de Hisui empilhados). Senão: linha "Precisa ser ..." no trecho.
    final grouped = <(int, int), List<RequirementBlock>>{};
    String typeName(String t) => dex.types[t]?.namePt ?? t;
    String speciesName(int sid) => dex.defaultBySpecies[sid]?.speciesName ?? '';
    for (final r in rules) {
      int? fromPid;
      String? requiredForm;
      String? requiredFormChip;
      final f = forms[r.requiredFormId];
      final variety = f == null ? null : dex.byPokemonId[f.pokemonId];
      if (variety != null && variety.speciesId == r.fromSpeciesId) {
        final cosmetic = !f!.isDefault && f.formName != null;
        if (nodes.containsKey(variety.pokemonId) || isRootSpecies(r.fromSpeciesId)) {
          fromPid = variety.pokemonId;
        } else if (!variety.isDefault) {
          requiredForm = evolutionDisplayName(variety);
          final region = Labels.regional[variety.regional];
          requiredFormChip = region != null ? 'Forma de $region' : (variety.formName ?? variety.name);
        }
        if (cosmetic && requiredForm == null) {
          requiredForm = '${variety.speciesName} (${f.formName})';
          requiredFormChip = f.formName;
        }
      }
      fromPid ??= _primaryOf(nodes.values, r.fromSpeciesId)?.pokemonId ?? basePid(r.fromSpeciesId);
      if (node(fromPid) == null || node(destOf[r.id]!) == null) continue;
      final block = describeEvolution(
        r,
        typeName: typeName,
        speciesName: speciesName,
        natures: natures[r.id],
        requiredForm: requiredForm,
        requiredFormChip: requiredFormChip,
      );
      grouped.putIfAbsent((fromPid, destOf[r.id]!), () => []).add(block);
    }

    // 4. Trechos: regras iguais (formas cosméticas) se fundem; diferentes viram alternativas.
    for (final MapEntry(key: (from, to), value: blocks) in grouped.entries) {
      final bySignature = <String, List<RequirementBlock>>{};
      for (final b in blocks) {
        bySignature.putIfAbsent(b.signature, () => []).add(b);
      }
      final merged = [
        for (final same in bySignature.values)
          same.length > 1 && same.map((b) => b.formSignature).toSet().length > 1 ? same.first.withoutForm() : same.first,
      ];
      final edge = EvoEdge(nodes[from]!, nodes[to]!, merged);
      edge.from.edges.add(edge);
      edge.to.incoming.add(edge);
    }

    // Toda espécie da cadeia aparece, mesmo sem regra.
    for (final sid in chain.speciesIds) {
      if (!nodes.values.any((n) => n.speciesId == sid)) node(basePid(sid));
    }

    int rank(EvoNode n) => (order[n.speciesId] ?? 999) * 2 + (n.entry.isDefault ? 0 : 1);
    int compare(EvoNode a, EvoNode b) {
      final c = rank(a).compareTo(rank(b));
      return c != 0 ? c : a.pokemonId.compareTo(b.pokemonId);
    }

    for (final n in nodes.values) {
      n.edges.sort((a, b) => compare(a.to, b.to));
      disambiguateChips([for (final e in n.edges) e.blocks]);
    }
    final roots = [for (final n in nodes.values) if (n.incoming.isEmpty) n]..sort(compare);
    void depthOf(EvoNode n, int d, Set<EvoNode> seen) {
      if (!seen.add(n)) return;
      if (d > n.depth) n.depth = d;
      for (final e in n.edges) {
        depthOf(e.to, d + 1, seen);
      }
      seen.remove(n);
    }

    for (final r in roots) {
      depthOf(r, 0, {});
    }
    return EvolutionGraph._(roots, nodes.values.toList(), chain.formChanges, chain.speciesIds);
  }

  static EvoNode? _primaryOf(Iterable<EvoNode> nodes, int speciesId) {
    EvoNode? best;
    for (final n in nodes) {
      if (n.speciesId != speciesId) continue;
      if (best == null || (n.entry.isDefault && !best.entry.isDefault)) best = n;
    }
    return best;
  }
}

class _FormInfo {
  const _FormInfo(this.pokemonId, this.formName, this.isDefault);
  final int pokemonId;
  final String? formName;
  final bool isDefault;
}
