import 'package:flutter/material.dart';

import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/data/pokeapi_cache.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/type_badge.dart';
import 'detail_common.dart';

/// Uma entrada de texto da Pokédex vinda da PokeAPI.
class FlavorEntry {
  const FlavorEntry({required this.text, required this.versionId, required this.versionName});
  final String text;
  final int? versionId;
  final String versionName;
}

/// Busca os textos em inglês da espécie (null = offline sem cache).
Future<List<FlavorEntry>?> fetchFlavor(int speciesId) async {
  final json = await PokeApiCache.instance.json('https://pokeapi.co/api/v2/pokemon-species/$speciesId/');
  if (json == null) return null;
  final raw = json['flavor_text_entries'];
  if (raw is! List) return const [];
  final out = <FlavorEntry>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final lang = e['language'];
    if (lang is! Map || lang['name'] != 'en') continue;
    final version = e['version'];
    final url = version is Map ? version['url'] as String? : null;
    final id = url == null ? null : int.tryParse(RegExp(r'/version/(\d+)/?$').firstMatch(url)?.group(1) ?? '');
    out.add(
      FlavorEntry(
        text: _clean(e['flavor_text'] as String? ?? ''),
        versionId: id,
        versionName: version is Map ? (version['name'] as String? ?? '') : '',
      ),
    );
  }
  return out;
}

String _clean(String s) => s
    .replaceAll('­\n', '')
    .replaceAll(RegExp(r'[\n\f\r]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Aba "Sobre": descrição, dados, stats base e fraquezas.
class AboutTab extends StatelessWidget {
  const AboutTab({
    super.key,
    required this.entry,
    required this.game,
    required this.detail,
    required this.flavor,
    required this.intro,
  });

  final DexEntry entry;
  final VersionGroup game;
  final Future<SpeciesDetail> detail;
  final Future<List<FlavorEntry>?> flavor;
  final Animation<double> intro;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      sliver: SliverList.list(
        children: [
          Reveal(animation: intro, index: 0, child: _Flavor(flavor: flavor, game: game)),
          Reveal(animation: intro, index: 1, child: _Data(entry: entry, detail: detail)),
          Reveal(animation: intro, index: 2, child: _Stats(entry: entry, intro: intro)),
          Reveal(animation: intro, index: 3, child: _Weaknesses(entry: entry)),
        ],
      ),
    );
  }
}

class _Flavor extends StatelessWidget {
  const _Flavor({required this.flavor, required this.game});
  final Future<List<FlavorEntry>?> flavor;
  final VersionGroup game;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dex = AppScope.read(context).dex;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: FutureBuilder<List<FlavorEntry>?>(
        future: flavor,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Text('Buscando a descrição da Pokédex…', style: text.bodySmall);
          }
          final list = snap.data;
          if (list == null) {
            return const InfoNote('Descrição disponível quando houver internet', icon: Icons.cloud_off_rounded);
          }
          if (list.isEmpty) return const InfoNote('A PokeAPI não tem descrição deste Pokémon.');

          final versions = <int, (Version, VersionGroup)>{
            for (final vg in dex.versionGroups)
              for (final v in vg.versions) v.id: (v, vg),
          };
          final mine = {
            for (final vg in dex.versionGroups)
              if (vg.id == game.id || vg.parentId == game.id)
                for (final v in vg.versions) v.id,
          };
          var pick = list.where((e) => mine.contains(e.versionId)).firstOrNull;
          final fallback = pick == null;
          if (pick == null) {
            final sorted = [...list]..sort((a, b) {
                final sa = versions[a.versionId]?.$2.sortOrder ?? -1;
                final sb = versions[b.versionId]?.$2.sortOrder ?? -1;
                return sb.compareTo(sa) != 0 ? sb.compareTo(sa) : (b.versionId ?? 0).compareTo(a.versionId ?? 0);
              });
            pick = sorted.first;
          }
          final source = versions[pick.versionId]?.$1.name ?? pick.versionName;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pick.text, style: text.bodyLarge),
              if (fallback) ...[
                const SizedBox(height: Space.xs),
                Text('Texto de $source', style: text.bodySmall),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Data extends StatelessWidget {
  const _Data({required this.entry, required this.detail});
  final DexEntry entry;
  final Future<SpeciesDetail> detail;


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Dados'),
        FutureBuilder<SpeciesDetail>(
          future: detail,
          builder: (context, snap) {
            final d = snap.data;
            return LayoutBuilder(
              builder: (context, box) {
                final half = (box.maxWidth - Space.l) / 2;
                Widget cell(String label, Widget value, {bool full = false}) => SizedBox(
                      width: full ? box.maxWidth : half,
                      child: _Pair(label: label, value: value),
                    );
                Widget plain(String v) => Text(v, style: Theme.of(context).textTheme.titleMedium);
                final growth = d?.growthRate;
                return Wrap(
                  spacing: Space.l,
                  runSpacing: Space.l,
                  children: [
                    cell('Altura', plain(Labels.height(entry.height))),
                    cell('Peso', plain(Labels.weight(entry.weight))),
                    if (d != null) ...[
                      if (d.abilities.isNotEmpty)
                        cell('Habilidades', Column(children: [for (final a in d.abilities) _AbilityRow(a)]), full: true),
                      cell('Gênero', _GenderBar(rate: d.genderRate), full: true),
                      cell('Grupos de ovo', plain(d.eggGroups.isEmpty ? '—' : d.eggGroups.join(', '))),
                      cell('Ciclos de ovo', plain(d.hatchCounter?.toString() ?? '—')),
                      cell('Taxa de captura', plain(d.captureRate?.toString() ?? '—')),
                      cell('Felicidade base', plain(d.baseHappiness?.toString() ?? '—')),
                      cell(
                        'Crescimento',
                        plain(
                          growth == null
                              ? '—'
                              : Labels.growthRate[growth] ?? growth,
                        ),
                      ),
                      cell('Experiência base', plain(d.baseExperience?.toString() ?? '—')),
                      cell(
                        'EVs concedidos',
                        plain(d.evYield.isEmpty ? '—' : d.evYield.entries.map((e) => '${e.value} ${e.key}').join(' · ')),
                        full: true,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          value,
        ],
      );
}

class _AbilityRow extends StatelessWidget {
  const _AbilityRow(this.ability);
  final Ability ability;

  void _open(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        builder: (context) {
          final text = Theme.of(context).textTheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, MediaQuery.paddingOf(context).bottom + Space.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ability.name, style: text.titleLarge),
                if (ability.isHidden) Text('Habilidade oculta', style: text.bodySmall),
                const SizedBox(height: Space.m),
                Text(ability.shortEffect ?? 'A PokeAPI não tem descrição desta habilidade.', style: text.bodyLarge),
              ],
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => _open(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Flexible(child: Text(ability.name, style: text.titleMedium)),
            if (ability.isHidden) ...[
              const SizedBox(width: Space.s),
              Text('oculta', style: text.bodySmall),
            ],
            const Spacer(),
            const Icon(Icons.info_outline_rounded, size: 18, color: Ramp.n5),
          ],
        ),
      ),
    );
  }
}

class _GenderBar extends StatelessWidget {
  const _GenderBar({required this.rate});

  /// Oitavos de chance de ser fêmea; -1 = sem gênero.
  final int rate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (rate < 0) return Text('Sem gênero', style: text.titleMedium);
    final female = rate / 8;
    final male = 1 - female;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Row(
        children: [
          const Icon(Icons.male_rounded, size: 18, color: Ramp.ink, semanticLabel: 'Macho'),
          const SizedBox(width: 2),
          Text(percent(male), style: text.titleSmall),
          const SizedBox(width: Space.s),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Ramp.n3),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: male,
                      child: const ColoredBox(color: Ramp.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.s),
          Text(percent(female), style: text.titleSmall),
          const SizedBox(width: 2),
          const Icon(Icons.female_rounded, size: 18, color: Ramp.n6, semanticLabel: 'Fêmea'),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.entry, required this.intro});
  final DexEntry entry;
  final Animation<double> intro;

  static const _grow = Interval(.25, .95, curve: Motion.emphasized);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final values = entry.stats.sublist(0, 6);
    final top = values.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Stats base'),
        AnimatedBuilder(
          animation: intro,
          builder: (context, _) {
            final t = _grow.transform(intro.value);
            return Column(
              children: [
                for (var i = 0; i < 6; i++)
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        SizedBox(width: 92, child: Text(Labels.stats[i], style: text.bodyMedium)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.pill),
                            child: SizedBox(
                              height: 4,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  const ColoredBox(color: Ramp.n1),
                                  FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (values[i] / 255).clamp(0.0, 1.0) * t,
                                    child: const ColoredBox(color: Ramp.ink),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${values[i]}',
                            textAlign: TextAlign.right,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: values[i] == top ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: Space.s),
        const Perforation(),
        const SizedBox(height: Space.s),
        Row(
          children: [
            Expanded(child: Text('Total', style: text.titleMedium)),
            Text('${entry.total}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}

class _Weaknesses extends StatelessWidget {
  const _Weaknesses({required this.entry});
  final DexEntry entry;

  static const _groups = <(String, List<(int, String)>)>[
    ('Fraco contra', [(400, '4×'), (200, '2×')]),
    ('Resiste', [(50, '½×'), (25, '¼×')]),
    ('Imune', [(0, '0×')]),
  ];

  @override
  Widget build(BuildContext context) {
    final dex = AppScope.read(context).dex;
    final text = Theme.of(context).textTheme;
    final byFactor = <int, List<String>>{};
    for (final t in dex.typesById.values) {
      if (!TypeInks.byIdentifier.containsKey(t.identifier) || !dex.efficacy.containsKey(t.identifier)) continue;
      byFactor.putIfAbsent(dex.damageAgainst(t.identifier, entry.types), () => []).add(t.identifier);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Fraquezas'),
        for (final (label, rows) in _groups)
          if (rows.any((r) => byFactor[r.$1]?.isNotEmpty ?? false)) ...[
            Padding(
              padding: const EdgeInsets.only(top: Space.m, bottom: Space.s),
              child: Text(label, style: text.titleMedium),
            ),
            for (final (factor, mult) in rows)
              if (byFactor[factor]?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(mult, style: text.titleSmall),
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [for (final t in byFactor[factor]!) TypePill(t, dense: true)],
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
