import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/data/models.dart';
import '../../core/data/specimen_draft.dart';
import '../../core/data/user_database.dart';
import '../../core/state/app_state.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import '../../core/widgets/stamp.dart';
import '../scan/scan_flow.dart';
import '../specimen/specimen_sheet_screen.dart';
import 'detail_common.dart';

/// Aba "Meus exemplares": todos os exemplares da espécie, em todas as aventuras.
/// Cada exemplar abre a ficha; a leitura por foto entra por [openScanFlow].
class SpecimensTab extends StatelessWidget {
  const SpecimensTab({super.key, required this.entry});
  final DexEntry entry;

  Future<void> _add(BuildContext context) async {
    final state = AppScope.read(context);
    final draft = SpecimenDraft(
      speciesId: entry.speciesId,
      pokemonId: entry.pokemonId,
      adventureId: state.activeAdventure?.id,
    );
    final id = await openSpecimenSheet(context, draft);
    if (id == null || !context.mounted) return;
    showUndoSnack(context, 'Exemplar adicionado', () => state.deleteSpecimen(id));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final list = state.specimensOf(entry.speciesId);
    final count = list.length;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.l, bottom: Space.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 0 ? 'Nenhum exemplar' : '$count ${count == 1 ? 'exemplar' : 'exemplares'}',
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: Space.xs),
                  Wrap(
                    spacing: Space.s,
                    children: [
                      TextButton.icon(
                        onPressed: () => _add(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Adicionar exemplar'),
                      ),
                      TextButton.icon(
                        onPressed: () => openScanFlow(context, speciesId: entry.speciesId),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Adicionar por foto'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyNote(
                icon: Icons.inventory_2_outlined,
                title: 'Nada carimbado ainda.',
                hint: 'Toque no carimbo do topo ou adicione um exemplar aqui.',
              ),
            )
          else
            SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Perforation(),
              itemBuilder: (context, i) => _SpecimenRow(specimen: list[i], entry: entry, state: state),
            ),
        ],
      ),
    );
  }
}

enum _RowAction { edit, photo, delete }

class _SpecimenRow extends StatelessWidget {
  const _SpecimenRow({required this.specimen, required this.entry, required this.state});
  final Specimen specimen;
  final DexEntry entry;
  final AppState state;

  static final _date = DateFormat.yMMMd('pt_BR');

  Future<void> _edit(BuildContext context) async {
    final before = specimen;
    final id = await openSpecimenSheet(context, SpecimenDraft.fromSpecimen(before), existingId: before.id);
    if (id == null || !context.mounted) return;
    showUndoSnack(context, 'Ficha salva', () => state.saveSpecimen(before.toCompanion(false)));
  }

  Future<void> _toggleShiny(BuildContext context) async {
    final s = specimen;
    await state.saveSpecimen(s.toCompanion(false).copyWith(isShiny: Value(!s.isShiny)));
    if (!context.mounted) return;
    showUndoSnack(
      context,
      s.isShiny ? 'Shiny removido' : 'Marcado como shiny',
      () => state.saveSpecimen(s.toCompanion(false)),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final s = specimen;
    await state.deleteSpecimen(s.id);
    if (!context.mounted) return;
    showUndoSnack(context, 'Exemplar apagado', () => state.saveSpecimen(s.toCompanion(false)));
  }

  /// Dados principais da ficha: nível, gênero, natureza, habilidade e situação na aventura.
  List<String> _facts() {
    final s = specimen;
    final dex = state.dex;
    final nature = s.nature == null ? null : dex.natures.where((n) => n.identifier == s.nature).firstOrNull;
    final ability = s.abilityId == null ? null : dex.abilities.where((a) => a.id == s.abilityId).firstOrNull;
    return [
      if (s.level != null) 'Nv. ${s.level}',
      if (s.gender == 'm') 'Macho' else if (s.gender == 'f') 'Fêmea',
      if (nature != null) nature.name else ?s.nature,
      ?ability?.name,
      if (s.teamSlot != null) 'No time',
      if (!s.isAlive) 'No cemitério',
    ];
  }

  /// Golpes resumidos, na ordem da ficha.
  String? _moves() {
    final csv = specimen.moves;
    if (csv == null || csv.trim().isEmpty) return null;
    final ids = csv.split(',').map((x) => int.tryParse(x.trim())).whereType<int>().toList();
    if (ids.isEmpty) return null;
    final names = {
      for (final m in state.dex.moves)
        if (ids.contains(m.id)) m.id: m.name,
    };
    return ids.map((id) => names[id] ?? 'Golpe #$id').join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = specimen;
    final variety = state.dex.byPokemonId[s.pokemonId] ?? entry;
    final adventure = state.adventures.where((a) => a.id == s.adventureId).firstOrNull;
    final origin = s.adventureId == null ? 'Sem aventura' : (adventure?.name ?? 'Aventura apagada');
    final facts = _facts();
    final moves = _moves();
    final nick = s.nickname;
    return InkWell(
      onTap: () => _edit(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StampSlot(
              seed: s.speciesId,
              ink: TypeInks.of(variety.type1).ink,
              state: s.isShiny ? StampState.shiny : StampState.stamped,
              size: 44,
              child: PokemonSprite(variety, shiny: s.isShiny),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nick ?? variety.name, style: text.titleMedium),
                    if (nick != null) Text(variety.name, style: text.bodySmall),
                    Text('$origin · ${_date.format(s.caughtAt)}', style: text.bodySmall),
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: Space.xs),
                      Text(facts.join(' · '), style: text.bodySmall?.copyWith(color: Ramp.ink)),
                    ],
                    if (moves != null) Text(moves, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (facts.isEmpty && moves == null) Text('Ficha em branco. Toque para preencher.', style: text.bodySmall),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: s.isShiny ? 'Desmarcar shiny' : 'Marcar como shiny',
              onPressed: () => _toggleShiny(context),
              icon: Icon(
                s.isShiny ? Icons.auto_awesome_rounded : Icons.auto_awesome_outlined,
                color: s.isShiny ? Gold.text : Ramp.n6,
              ),
            ),
            PopupMenuButton<_RowAction>(
              tooltip: 'Mais ações',
              icon: const Icon(Icons.more_vert_rounded, color: Ramp.n6),
              color: Ramp.paper,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sheet)),
              onSelected: (a) => switch (a) {
                _RowAction.edit => _edit(context),
                _RowAction.photo => openScanFlow(context, speciesId: s.speciesId, existingId: s.id),
                _RowAction.delete => _delete(context),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _RowAction.edit,
                  child: ListTile(leading: Icon(Icons.edit_note_rounded), title: Text('Editar ficha')),
                ),
                PopupMenuItem(
                  value: _RowAction.photo,
                  child: ListTile(leading: Icon(Icons.photo_camera_outlined), title: Text('Atualizar por foto')),
                ),
                PopupMenuItem(
                  value: _RowAction.delete,
                  child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Apagar exemplar')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
