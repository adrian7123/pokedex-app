import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import 'detail_common.dart';

/// Aba "Onde achar": cartucho → área → método, com nível e raridade.
class EncountersTab extends StatelessWidget {
  const EncountersTab({super.key, required this.game, required this.encounters});
  final VersionGroup game;
  final Future<Map<Version, List<Encounter>>> encounters;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<Version, List<Encounter>>>(
      future: encounters,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: Space.xxxl),
              child: Center(
                child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Ramp.n4)),
              ),
            ),
          );
        }
        final data = snap.data ?? const {};
        if (data.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyNote(
              icon: Icons.map_outlined,
              title: 'A PokeAPI ainda não tem locais de ${game.name}.',
              hint: 'Troque o jogo no topo para ver onde ele aparece em outros jogos.',
            ),
          );
        }
        final groups = _group(data);
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          sliver: SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (context, i) => _VersionBlock(group: groups[i], first: i == 0),
          ),
        );
      },
    );
  }

  /// Cartuchos com a mesma lista (Scarlet e Violet quase sempre) viram um bloco só.
  static List<_Group> _group(Map<Version, List<Encounter>> data) {
    final out = <_Group>[];
    final bySignature = <String, _Group>{};
    for (final MapEntry(key: version, value: list) in data.entries) {
      final areas = _areas(list);
      final signature = areas
          .map((a) => '${a.name}|${a.rows.map((r) => '${r.method}/${r.conditions}/${r.min}/${r.max}/${r.rarity}').join(',')}')
          .join(';');
      final existing = bySignature[signature];
      if (existing != null) {
        existing.versions.add(version);
      } else {
        final g = _Group([version], areas);
        bySignature[signature] = g;
        out.add(g);
      }
    }
    return out;
  }

  /// Área → linhas, juntando níveis e somando a raridade do mesmo método e condição.
  static List<_Area> _areas(List<Encounter> list) {
    final areas = <String, Map<String, _Row>>{};
    for (final e in list) {
      final rows = areas.putIfAbsent(e.area, () => {});
      final key = '${e.method}|${e.conditions ?? ''}';
      final cur = rows[key];
      if (cur == null) {
        rows[key] = _Row(e.method, e.conditions, e.minLevel, e.maxLevel, e.rarity);
      } else {
        rows[key] = _Row(
          e.method,
          e.conditions,
          e.minLevel < cur.min ? e.minLevel : cur.min,
          e.maxLevel > cur.max ? e.maxLevel : cur.max,
          (cur.rarity + e.rarity).clamp(0, 100),
        );
      }
    }
    return [for (final a in areas.entries) _Area(a.key, a.value.values.toList())];
  }
}

class _Group {
  _Group(this.versions, this.areas);
  final List<Version> versions;
  final List<_Area> areas;
}

class _Area {
  const _Area(this.name, this.rows);
  final String name;
  final List<_Row> rows;
}

class _Row {
  const _Row(this.method, this.conditions, this.min, this.max, this.rarity);
  final String method;
  final String? conditions;
  final int min;
  final int max;
  final int rarity;
}

class _VersionBlock extends StatelessWidget {
  const _VersionBlock({required this.group, required this.first});
  final _Group group;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(group.versions.map((v) => v.name).join(' · '), first: first),
        for (var i = 0; i < group.areas.length; i++) ...[
          if (i > 0) const Perforation(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.areas[i].name, style: text.titleMedium),
                const SizedBox(height: Space.xs),
                for (final r in group.areas[i].rows)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.method, style: text.bodyMedium),
                              if (r.conditions != null) Text(r.conditions!, style: text.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.m),
                        Text(
                          r.min == r.max ? 'Nv. ${r.min}' : 'Nv. ${r.min}–${r.max}',
                          style: text.bodyLarge,
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            r.rarity > 0 ? '${r.rarity}%' : '',
                            textAlign: TextAlign.right,
                            style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
