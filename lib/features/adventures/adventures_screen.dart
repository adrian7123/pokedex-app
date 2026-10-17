import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/shell.dart';
import '../../core/data/user_database.dart' show Adventure;
import '../../core/state/app_state.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import 'adventure_actions.dart';
import 'can_evolve_section.dart';
import 'game_seal.dart';
import 'new_adventure_page.dart';

/// Aventuras: um save por linha; a ativa é a lente do app inteiro.
class AdventuresScreen extends StatelessWidget {
  const AdventuresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mensageiro próprio: o SnackBar sobe o FAB em vez de cobri-lo.
    return const ScaffoldMessenger(child: _AdventuresBody());
  }
}

class _AdventuresBody extends StatelessWidget {
  const _AdventuresBody();

  void _toast(BuildContext context, String message, {bool offerPokedex = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          persist: false,
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: offerPokedex ? SnackBarAction(label: 'Ver Pokédex', onPressed: () => Shell.goTo(context, 0)) : null,
        ),
      );
  }

  void _created(BuildContext context, String? name) {
    if (name == null || !context.mounted) return;
    _toast(context, '$name criada e ativa', offerPokedex: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dex = state.dex;
    final index = GameIndex.of(dex);
    final text = Theme.of(context).textTheme;

    final live = [
      for (final a in state.adventures)
        if (!a.archived) a,
    ];
    final archived = [
      for (final a in state.adventures)
        if (a.archived) a,
    ];
    final empty = state.adventures.isEmpty;

    // aventura → espécies carimbadas nela; e quantidade de exemplares (para o aviso de exclusão).
    final speciesBy = <String, Set<int>>{};
    final countBy = <String, int>{};
    for (final s in state.allSpecimens) {
      final id = s.adventureId;
      if (id == null) continue;
      speciesBy.putIfAbsent(id, () => {}).add(s.speciesId);
      countBy[id] = (countBy[id] ?? 0) + 1;
    }
    (int, int) progressOf(Adventure a) {
      final game = index.regional(a.versionGroupId);
      final mine = speciesBy[a.id] ?? const <int>{};
      return (mine.where(game.containsKey).length, game.length);
    }

    final active = state.activeAdventure;
    final national = (state.global.length, dex.defaultBySpecies.length);

    Widget row(Adventure a) => _AdventureRow(
      adventure: a,
      active: active?.id == a.id,
      progress: progressOf(a),
      specimens: countBy[a.id] ?? 0,
      onToast: (m, {offerPokedex = false}) => _toast(context, m, offerPokedex: offerPokedex),
    );

    return Scaffold(
      floatingActionButton: empty
          ? null
          : _NewAdventureLauncher(
              onClosed: (name) => _created(context, name),
              closed: (open) => FloatingActionButton.extended(
                heroTag: null,
                onPressed: open,
                elevation: 0,
                focusElevation: 0,
                hoverElevation: 0,
                highlightElevation: 0,
                backgroundColor: Ramp.ink,
                foregroundColor: Ramp.paper,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova aventura'),
              ),
            ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const PageStorageKey('adventures-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, Space.m),
              sliver: SliverToBoxAdapter(child: Text('Aventuras', style: text.headlineMedium)),
            ),
            if (empty)
              SliverToBoxAdapter(child: _EmptyState(onClosed: (name) => _created(context, name)))
            else ...[
              SliverList.list(
                children: [
                  for (final a in live) ...[row(a), const Perforation(indent: Space.gutter + 52 + Space.m)],
                  _NoAdventureRow(
                    active: active == null,
                    progress: national,
                    onTap: () {
                      if (active == null) return;
                      HapticFeedback.selectionClick();
                      state.setActiveAdventure(null);
                      _toast(context, 'Sem aventura: Pokédex Nacional', offerPokedex: true);
                    },
                  ),
                ],
              ),
              if (active != null)
                SliverToBoxAdapter(
                  child: CanEvolveSection(state: state, adventureName: active.name, vgId: active.versionGroupId),
                ),
              if (archived.isNotEmpty)
                SliverList.list(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxxl, Space.gutter, Space.xs),
                      child: Text('Arquivadas', style: text.titleLarge),
                    ),
                    for (var i = 0; i < archived.length; i++) ...[
                      if (i > 0) const Perforation(indent: Space.gutter + 52 + Space.m),
                      row(archived[i]),
                    ],
                  ],
                ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: 96 + MediaQuery.paddingOf(context).bottom)),
          ],
        ),
      ),
    );
  }
}

typedef _Toast = void Function(String message, {bool offerPokedex});

class _AdventureRow extends StatelessWidget {
  const _AdventureRow({
    required this.adventure,
    required this.active,
    required this.progress,
    required this.specimens,
    required this.onToast,
  });

  final Adventure adventure;
  final bool active;
  final (int, int) progress;
  final int specimens;
  final _Toast onToast;

  String _subtitle(AppState state) {
    final a = adventure;
    final vg = state.dex.versionGroupsById[a.versionGroupId];
    final version = vg?.versions.where((v) => v.id == a.versionId).firstOrNull;
    final parts = <String>[
      vg?.name ?? 'Jogo desconhecido',
      if (version != null && version.name != a.name && pickableVersions(vg!).length > 1) version.name,
      if (a.isNuzlocke) 'Nuzlocke',
    ];
    return parts.join(' · ');
  }

  Future<void> _activate(BuildContext context) async {
    if (active) return;
    HapticFeedback.selectionClick();
    final state = AppScope.read(context);
    final wasArchived = adventure.archived;
    await state.activateAdventure(adventure);
    onToast(wasArchived ? '${adventure.name} desarquivada e ativa' : '${adventure.name} ativa', offerPokedex: true);
  }

  Future<void> _rename(BuildContext context) async {
    final state = AppScope.read(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: adventure.name),
    );
    if (name == null || name == adventure.name) return;
    await state.renameAdventure(adventure.id, name);
  }

  Future<void> _archive(BuildContext context) async {
    final state = AppScope.read(context);
    final archiving = !adventure.archived;
    await state.archiveAdventure(adventure, archived: archiving);
    onToast(archiving ? '${adventure.name} arquivada' : '${adventure.name} desarquivada');
  }

  Future<void> _delete(BuildContext context) async {
    final state = AppScope.read(context);
    final error = Theme.of(context).colorScheme.error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir “${adventure.name}”?'),
        content: Text(
          specimens == 0
              ? 'A aventura não tem exemplares. Isso não pode ser desfeito.'
              : 'Os $specimens ${specimens == 1 ? 'exemplar' : 'exemplares'} desta aventura, com fichas e carimbos, '
                    'também serão apagados. Isso não pode ser desfeito.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await state.deleteAdventure(adventure);
    onToast('${adventure.name} excluída');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final (done, total) = progress;
    final dim = adventure.archived;

    return Semantics(
      selected: active,
      button: !active,
      hint: active ? null : 'Tornar ativa',
      child: InkWell(
        onTap: () => _activate(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.m, 0, Space.m),
          child: Row(
            children: [
              Opacity(
                opacity: dim ? .55 : 1,
                child: GameSeal(code: gameCode(state.dex, adventure), active: active),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            adventure.name,
                            style: text.titleLarge?.copyWith(color: dim ? Ramp.n6 : null),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (active) ...[const SizedBox(width: Space.s), const _ActiveTag()],
                      ],
                    ),
                    Text(_subtitle(state), style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Space.s),
                    _Progress(done: done, total: total),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções de ${adventure.name}',
                icon: const Icon(Icons.more_vert_rounded, color: Ramp.n6),
                onSelected: (v) => switch (v) {
                  'rename' => _rename(context),
                  'archive' => _archive(context),
                  _ => _delete(context),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Renomear')),
                  PopupMenuItem(value: 'archive', child: Text(adventure.archived ? 'Desarquivar' : 'Arquivar')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Excluir',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAdventureRow extends StatelessWidget {
  const _NoAdventureRow({required this.active, required this.progress, required this.onTap});
  final bool active;
  final (int, int) progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: active,
      button: !active,
      hint: active ? null : 'Usar a Pokédex Nacional',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // Alinha com as linhas que têm menu (48dp) à direita.
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.m, 48, Space.m),
          child: Row(
            children: [
              GameSeal(code: '', icon: Icons.public_rounded, active: active),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text('Sem aventura', style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (active) ...[const SizedBox(width: Space.s), const _ActiveTag()],
                      ],
                    ),
                    Text('Pokédex Nacional · todos os exemplares', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Space.s),
                    _Progress(done: progress.$1, total: progress.$2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveTag extends StatelessWidget {
  const _ActiveTag();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.check_circle_rounded, size: 16, color: Ramp.ink),
      const SizedBox(width: Space.xs),
      Text('Ativa', style: Theme.of(context).textTheme.titleSmall),
    ],
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$done de $total carimbos',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 4, backgroundColor: Ramp.n2, color: Ramp.ink),
            ),
          ),
          const SizedBox(width: Space.m),
          Text('$done/$total carimbos', style: text.bodySmall),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});
  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Renomear aventura'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
      decoration: const InputDecoration(hintText: 'Nome da aventura'),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
      FilledButton(onPressed: _controller.text.trim().isEmpty ? null : _submit, child: const Text('Salvar')),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClosed});
  final ValueChanged<String?> onClosed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nenhuma aventura ainda', style: text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(
            'Crie uma para cada save que você está jogando: a Pokédex passa a mostrar a dex, '
            'as evoluções e o progresso daquele jogo.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: Space.l),
          _NewAdventureLauncher(
            onClosed: onClosed,
            closed: (open) => FilledButton.icon(onPressed: open, icon: const Icon(Icons.add_rounded), label: const Text('Nova aventura')),
          ),
        ],
      ),
    );
  }
}

/// Abre a criação com transformação de contêiner a partir do botão (corte seco com animações reduzidas).
class _NewAdventureLauncher extends StatelessWidget {
  const _NewAdventureLauncher({required this.closed, required this.onClosed});
  final Widget Function(VoidCallback open) closed;
  final ValueChanged<String?> onClosed;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return OpenContainer<String>(
      transitionDuration: reduce ? Duration.zero : Motion.long,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Ramp.ink,
      openColor: Ramp.paper,
      middleColor: Ramp.paper,
      closedShape: const StadiumBorder(),
      tappable: false,
      onClosed: onClosed,
      closedBuilder: (_, open) => closed(open),
      openBuilder: (_, close) => NewAdventurePage(onDone: (name) => close(returnValue: name)),
    );
  }
}
