import 'package:flutter/material.dart';

import '../../core/data/labels.dart';
import '../../core/data/models.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/type_badge.dart';
import 'marks.dart';
import 'chip_style.dart';
import 'pokedex_controller.dart';

/// Rotas modais ficam fora da árvore da aba: reexpõe o AppState para os widgets do núcleo.
Future<T?> _sheet<T>(BuildContext context, PokedexController c, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AppScope(state: c.app, child: child),
    );

Future<void> showFilterSheet(BuildContext context, PokedexController c) => _sheet(context, c, FilterSheet(controller: c));

Future<void> showTypeSheet(BuildContext context, PokedexController c) =>
    _sheet(context, c, FilterSheet(controller: c, typesOnly: true));

Future<void> showScopeSheet(BuildContext context, PokedexController c) => _sheet(context, c, _ScopeSheet(controller: c));

Future<void> showSortSheet(BuildContext context, PokedexController c) => _sheet(context, c, _SortSheet(controller: c));

// -----------------------------------------------------------------------------
// Peças comuns

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.first = false});
  final String title;
  final Widget child;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(Space.gutter, first ? Space.s : Space.xxl, Space.gutter, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Space.s),
            child,
          ],
        ),
      );
}

class _Sub extends StatelessWidget {
  const _Sub(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.m, bottom: Space.xs),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );
}

/// Chip liga/desliga no estilo do tema (ativo em tinta, texto papel).
class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.selected, required this.onTap, this.icon, this.semantics});
  final Widget label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final chip = FilterChip(
      label: label,
      selected: selected,
      showCheckmark: false,
      labelStyle: chipLabel(context, selected),
      avatar: icon == null ? null : Icon(icon, size: 18, color: selected ? Ramp.paper : Ramp.n6),
      onSelected: (_) => onTap(),
    );
    if (semantics == null) return chip;
    return Semantics(label: semantics, child: chip);
  }
}

Widget _chips(List<Widget> children) => Wrap(spacing: Space.s, children: children);

Widget _text(String s) => Text(s);

// -----------------------------------------------------------------------------
// Folha de filtros

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key, required this.controller, this.typesOnly = false});
  final PokedexController controller;
  final bool typesOnly;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: typesOnly ? .62 : .92,
        minChildSize: .4,
        maxChildSize: 1,
        builder: (context, scroll) => ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            final text = Theme.of(context).textTheme;
            final clearable = typesOnly
                ? c.types.isNotEmpty || c.typeMode != TypeMode.any
                : c.activeFilterCount > 0;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.s, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text(typesOnly ? 'Tipo' : 'Filtros', style: text.headlineMedium)),
                      TextButton(
                        onPressed: clearable ? (typesOnly ? c.clearTypes : c.clearFilters) : null,
                        child: const Text('Limpar'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.only(bottom: Space.xxl),
                    children: typesOnly
                        ? [_TypesSection(c: c, first: true)]
                        : [
                            _TypesSection(c: c, first: true),
                            _Section(
                              title: 'Geração',
                              child: _chips([
                                for (final g in c.dex.generations)
                                  _Toggle(
                                    label: _text(g.roman),
                                    semantics: g.label,
                                    selected: c.generations.contains(g.id),
                                    onTap: () => c.toggleGeneration(g.id),
                                  ),
                              ]),
                            ),
                            _CategoriesSection(c: c),
                            _ProgressSection(c: c),
                            _AdvancedSection(c: c),
                            _DisplaySection(c: c),
                            _Section(
                              title: 'Ordenar por',
                              child: _chips([
                                for (final s in SortKey.values)
                                  _Toggle(label: _text(s.label), selected: c.sort == s, onTap: () => c.sort = s),
                              ]),
                            ),
                          ],
                  ),
                ),
                _Footer(c: c),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) {
    final n = c.result.length;
    final label = c.moveLoading
        ? 'Buscando quem aprende ${c.move?.name ?? ''}…'
        : n == 0
            ? 'Nenhum Pokémon'
            : 'Mostrar $n Pokémon';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Perforation(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Space.gutter,
            Space.m,
            Space.gutter,
            Space.m + MediaQuery.paddingOf(context).bottom,
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Tipos

class _TypesSection extends StatelessWidget {
  const _TypesSection({required this.c, this.first = false});
  final PokedexController c;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Tipos',
      first: first,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.xs,
            children: [
              for (final t in c.dex.typesById.values)
                _TypeToggle(type: t.identifier, name: t.namePt, selected: c.types.contains(t.identifier), onTap: () => c.toggleType(t.identifier)),
            ],
          ),
          const SizedBox(height: Space.m),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TypeMode>(
              showSelectedIcon: false,
              segments: [for (final m in TypeMode.values) ButtonSegment(value: m, label: Text(m.label))],
              selected: {c.typeMode},
              onSelectionChanged: (s) => c.setTypeMode(s.first),
            ),
          ),
          _Sub(c.typeMode.hint),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.name, required this.selected, required this.onTap});
  final String type;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = TypeInks.of(type);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Motion.short,
            curve: Motion.standard,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: selected ? ink.text : ink.text.withValues(alpha: 0), width: 2),
            ),
            child: TypePill(type),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Categorias

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) => _Section(
        title: 'Categorias',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chips([
              for (final e in Labels.categories.entries)
                _Toggle(label: _text(e.value), selected: c.categories.contains(e.key), onTap: () => c.toggleCategory(e.key)),
            ]),
            if (c.categories.contains('regional')) ...[
              const _Sub('Região da forma (nenhuma marcada = todas)'),
              _chips([
                for (final r in Labels.regional.entries)
                  _Toggle(label: _text(r.value), selected: c.regionalForms.contains(r.key), onTap: () => c.toggleRegionalForm(r.key)),
              ]),
            ],
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// Meu progresso

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) => _Section(
        title: 'Meu progresso',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _chips([
              _Toggle(
                label: _text('Carimbados'),
                selected: c.capture == CaptureFilter.captured,
                onTap: () => c.setCapture(CaptureFilter.captured),
              ),
              _Toggle(
                label: _text('Não carimbados'),
                selected: c.capture == CaptureFilter.uncaptured,
                onTap: () => c.setCapture(CaptureFilter.uncaptured),
              ),
              _Toggle(
                label: _text('Shiny'),
                icon: Icons.auto_awesome_rounded,
                selected: c.shinyOnly,
                onTap: () => c.setShinyOnly(!c.shinyOnly),
              ),
              _Toggle(
                label: _text('Favoritos'),
                icon: favoriteIcon,
                selected: c.favoritesOnly,
                onTap: () => c.setFavoritesOnly(!c.favoritesOnly),
              ),
              _Toggle(
                label: _text('Pode evoluir'),
                icon: Icons.arrow_upward_rounded,
                selected: c.canEvolveOnly,
                onTap: () => c.setCanEvolveOnly(!c.canEvolveOnly),
              ),
            ]),
            const _Sub('Pode evoluir: carimbados cuja próxima evolução ainda falta.'),
            const _Sub('Marcas (qualquer uma das marcadas)'),
            _chips([
              for (final m in SpeciesMarkBit.values)
                _Toggle(
                  semantics: 'Marca ${m.label.toLowerCase()}',
                  label: MarkGlyph(m, size: 18, color: c.marksMask & m.bit != 0 ? Ramp.paper : Ramp.n6),
                  selected: c.marksMask & m.bit != 0,
                  onTap: () => c.toggleMarkBit(m.bit),
                ),
            ]),
          ],
        ),
      );
}

// -----------------------------------------------------------------------------
// Avançados

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) {
    final vg = c.scopeVersionGroup;
    final (lo, hi) = c.statBounds[c.statIndex];
    final range = c.statRange ?? RangeValues(lo.toDouble(), hi.toDouble());
    const statNames = [...Labels.stats, 'Total'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'Habilidade',
          child: _RefPicker(
            options: c.dex.abilities,
            selected: c.ability,
            hint: 'Buscar habilidade',
            onSelect: c.setAbility,
          ),
        ),
        _Section(
          title: 'Golpe',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RefPicker(
                options: c.dex.moves,
                selected: c.move,
                hint: 'Buscar golpe',
                loading: c.moveLoading,
                onSelect: c.setMove,
              ),
              _Sub(
                c.moveFailed
                    ? 'Não deu para consultar os golpes agora. Tente escolher de novo.'
                    : vg == null
                        ? 'Quem aprende em qualquer jogo, por qualquer método.'
                        : 'Quem aprende em ${vg.name}, por qualquer método.',
              ),
            ],
          ),
        ),
        _Section(
          title: 'Grupo de ovo',
          child: _chips([
            for (final g in c.dex.eggGroups)
              _Toggle(label: _text(g.name), selected: c.eggGroups.contains(g.id), onTap: () => c.toggleEggGroup(g.id)),
          ]),
        ),
        _Section(
          title: 'Método de evolução',
          child: _chips([
            for (final t in c.triggerIdentifiers.entries)
              _Toggle(
                label: _text(Labels.evolutionTrigger[t.value] ?? t.value),
                selected: c.triggers.contains(t.key),
                onTap: () => c.toggleTrigger(t.key),
              ),
          ]),
        ),
        _Section(
          title: 'Faixa de stat',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chips([
                for (var i = 0; i < statNames.length; i++)
                  _Toggle(label: _text(statNames[i]), selected: c.statIndex == i, onTap: () => c.setStatIndex(i)),
              ]),
              const SizedBox(height: Space.s),
              RangeSlider(
                min: lo.toDouble(),
                max: hi.toDouble(),
                divisions: hi - lo,
                values: range,
                labels: RangeLabels('${range.start.round()}', '${range.end.round()}'),
                onChanged: c.setStatRange,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l),
                child: Row(
                  children: [
                    Text('${range.start.round()}', style: Theme.of(context).textTheme.titleSmall),
                    Expanded(
                      child: Text(
                        c.statRange == null ? 'Sem limite de ${statNames[c.statIndex]}' : statNames[c.statIndex],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text('${range.end.round()}', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Campo com sugestões em linha (sem sobreposição): escolhe um nome de uma lista grande.
class _RefPicker extends StatefulWidget {
  const _RefPicker({required this.options, required this.selected, required this.hint, required this.onSelect, this.loading = false});
  final List<NamedRef> options;
  final NamedRef? selected;
  final String hint;
  final ValueChanged<NamedRef?> onSelect;
  final bool loading;

  @override
  State<_RefPicker> createState() => _RefPickerState();
}

class _RefPickerState extends State<_RefPicker> {
  final _text = TextEditingController();
  late final List<String> _norm = [for (final o in widget.options) DexEntry.normalize(o.name)];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  List<NamedRef> _matches() {
    final q = DexEntry.normalize(_text.text);
    if (q.isEmpty) return const [];
    final starts = <NamedRef>[];
    final contains = <NamedRef>[];
    for (var i = 0; i < _norm.length; i++) {
      if (_norm[i].startsWith(q)) {
        starts.add(widget.options[i]);
      } else if (_norm[i].contains(q)) {
        contains.add(widget.options[i]);
      }
    }
    return [...starts, ...contains].take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    if (sel != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          label: Text(sel.name),
          labelStyle: chipLabel(context, true),
          selected: true,
          showCheckmark: false,
          avatar: widget.loading
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Ramp.paper))
              : null,
          deleteIcon: const Icon(Icons.close_rounded, size: 18, color: Ramp.paper),
          deleteButtonTooltipMessage: 'Remover',
          onDeleted: () => widget.onSelect(null),
          onPressed: () => widget.onSelect(null),
        ),
      );
    }
    final matches = _matches();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            controller: _text,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (matches.isNotEmpty) _pick(matches.first);
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search_rounded, color: Ramp.n6),
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
            ),
          ),
        ),
        for (final m in matches)
          InkWell(
            onTap: () => _pick(m),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Text(m.name, style: text.bodyLarge),
            ),
          ),
        if (_text.text.isNotEmpty && matches.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
            child: Text('Nada com “${_text.text}”.', style: text.bodySmall),
          ),
      ],
    );
  }

  void _pick(NamedRef m) {
    _text.clear();
    FocusScope.of(context).unfocus();
    widget.onSelect(m);
  }
}

// -----------------------------------------------------------------------------
// Exibição

class _DisplaySection extends StatelessWidget {
  const _DisplaySection({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) {
    final forced = c.formsForcedByFilter;
    return _Section(
      title: 'Exibição',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.scopeVg != null) ...[
            _DexModeToggle(c: c),
            const SizedBox(height: Space.s),
          ],
          SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: c.formsVisible,
        onChanged: forced ? null : (v) => c.showForms = v,
        title: Text('Mostrar formas alternativas', style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text(
          forced
              ? 'Ligado pelo filtro de Mega, Gigantamax ou formas regionais.'
              : 'Megas, Gigantamax e formas regionais em linhas próprias.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
          ),
        ],
      ),
    );
  }
}

/// Dex regional (padrão) ou tudo que dá para obter no jogo.
class _DexModeToggle extends StatelessWidget {
  const _DexModeToggle({required this.c});
  final PokedexController c;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: true, label: Text('Só a dex regional')),
            ButtonSegment(value: false, label: Text('Tudo obtível no jogo')),
          ],
          selected: {c.regionalOnly},
          onSelectionChanged: (s) => c.regionalOnly = s.first,
        ),
      );
}

// -----------------------------------------------------------------------------
// Escopo de jogo

class _ScopeSheet extends StatelessWidget {
  const _ScopeSheet({required this.controller});
  final PokedexController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final dex = c.dex;
    final text = Theme.of(context).textTheme;
    final adventureVg = c.app.contextVersionGroupId;
    final current = c.scopeVg;
    final byGen = <int, List<VersionGroup>>{};
    for (final vg in dex.versionGroups.where((v) => v.isPlayable)) {
      byGen.putIfAbsent(vg.generationId, () => []).add(vg);
    }
    final hasDlc = {for (final v in dex.versionGroups) if (v.isDlc && v.parentId != null) v.parentId!};

    Widget tile({required String title, required String subtitle, required bool selected, required VoidCallback onTap}) =>
        Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.s),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: selected ? text.titleMedium : text.bodyLarge),
                        Text(subtitle, style: text.bodySmall),
                      ],
                    ),
                  ),
                  if (selected) const Icon(Icons.check_rounded, color: Ramp.ink),
                ],
              ),
            ),
          ),
        );

    void pick(int? vg) {
      c.setScope(vg);
      Navigator.of(context).pop();
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      minChildSize: .4,
      maxChildSize: 1,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.only(bottom: Space.xxl + MediaQuery.paddingOf(context).bottom),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Text('Pokédex do jogo', style: text.headlineMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, Space.m),
            child: Text('Muda só esta lista. A aventura ativa continua a mesma.', style: text.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.m),
            child: ListenableBuilder(listenable: c, builder: (context, _) => _DexModeToggle(c: c)),
          ),
          tile(
            title: 'Pokédex Nacional',
            subtitle: '${dex.defaultBySpecies.length} espécies${adventureVg == null ? ' · padrão' : ''}',
            selected: current == null,
            onTap: () => pick(null),
          ),
          for (final g in dex.generations)
            if (byGen[g.id] != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, Space.xs),
                child: Text(g.label, style: text.titleMedium),
              ),
              for (final vg in byGen[g.id]!)
                tile(
                  title: vg.name,
                  subtitle: [
                    '${c.speciesInGame(vg.id).length} na dex',
                    '${c.availableInGame(vg.id).length} obtíveis',
                    if (hasDlc.contains(vg.id)) 'com DLC',
                    if (vg.id == adventureVg) 'aventura ativa',
                  ].join(' · '),
                  selected: current == vg.id,
                  onTap: () => pick(vg.id),
                ),
            ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Ordem

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.controller});
  final PokedexController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final text = Theme.of(context).textTheme;
    String hint(SortKey s) => switch (s) {
          SortKey.number => c.scopeVg == null ? 'Nº nacional' : 'Nº regional do jogo',
          SortKey.name => 'Ordem alfabética',
          SortKey.height || SortKey.weight => 'Maior primeiro',
          _ => 'Maior primeiro',
        };
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.s),
              child: Text('Ordenar por', style: text.headlineMedium),
            ),
            for (final s in SortKey.values)
              Semantics(
                selected: c.sort == s,
                button: true,
                child: InkWell(
                  onTap: () {
                    c.sort = s;
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: Row(
                      children: [
                        Expanded(child: Text(s.label, style: c.sort == s ? text.titleMedium : text.bodyLarge)),
                        Text(hint(s), style: text.bodySmall),
                        const SizedBox(width: Space.m),
                        SizedBox(
                          width: 24,
                          child: c.sort == s ? const Icon(Icons.check_rounded, color: Ramp.ink) : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
