import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import 'adventure_actions.dart';
import 'game_seal.dart';

/// Nova aventura em três passos: jogo → cartucho (se houver mais de um) → nome e Nuzlocke.
/// Fecha devolvendo o nome da aventura criada (já ativa), ou null se cancelada.
class NewAdventurePage extends StatefulWidget {
  const NewAdventurePage({super.key, required this.onDone});
  final void Function(String? name) onDone;

  @override
  State<NewAdventurePage> createState() => _NewAdventurePageState();
}

class _NewAdventurePageState extends State<NewAdventurePage> {
  int _step = 0;
  bool _reverse = false;
  VersionGroup? _game;
  Version? _version;
  final _name = TextEditingController();
  bool _nuzlocke = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _go(int step) => setState(() {
    _reverse = step < _step;
    _step = step;
  });

  void _back() {
    if (_step == 0) {
      widget.onDone(null);
      return;
    }
    // Jogo de cartucho único pula o passo 2 também na volta.
    final versions = _game == null ? const <Version>[] : pickableVersions(_game!);
    _go(_step == 2 && versions.length <= 1 ? 0 : _step - 1);
  }

  void _pickGame(VersionGroup vg) {
    _game = vg;
    final versions = pickableVersions(vg);
    if (versions.length > 1) {
      _version = null;
      _go(1);
    } else {
      _pickVersion(versions.firstOrNull, vg);
    }
  }

  void _pickVersion(Version? v, VersionGroup vg) {
    _version = v;
    _name.text = v?.name ?? vg.name;
    _go(2);
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final vg = _game;
    if (name.isEmpty || vg == null || _saving) return;
    setState(() => _saving = true);
    await AppScope.read(context).createAdventure(name: name, versionGroupId: vg.id, versionId: _version?.id, nuzlocke: _nuzlocke);
    if (!mounted) return;
    widget.onDone(name);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    const titles = ['Escolha o jogo', 'Qual versão?', 'Nome da aventura'];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: _step == 0 ? 'Cancelar' : 'Voltar',
            icon: Icon(_step == 0 ? Icons.close_rounded : Icons.arrow_back_rounded),
            onPressed: _back,
          ),
          title: Text(titles[_step]),
        ),
        body: PageTransitionSwitcher(
          duration: reduce ? Duration.zero : Motion.medium,
          reverse: _reverse,
          transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
            animation: primary,
            secondaryAnimation: secondary,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Ramp.paper,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              0 => _GameStep(onPick: _pickGame),
              1 => _VersionStep(game: _game!, onPick: (v) => _pickVersion(v, _game!)),
              _ => _NameStep(
                game: _game!,
                version: _version,
                controller: _name,
                nuzlocke: _nuzlocke,
                saving: _saving,
                onNuzlocke: (v) => setState(() => _nuzlocke = v),
                onCreate: _create,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _GameStep extends StatelessWidget {
  const _GameStep({required this.onPick});
  final ValueChanged<VersionGroup> onPick;

  @override
  Widget build(BuildContext context) {
    final dex = AppScope.read(context).dex;
    final index = GameIndex.of(dex);
    final text = Theme.of(context).textTheme;
    final games = dex.versionGroups.where((v) => v.isPlayable).toList();
    final gens = dex.generations.toList()..sort((a, b) => b.id.compareTo(a.id));

    final children = <Widget>[];
    for (final g in gens) {
      final inGen = games.where((v) => v.generationId == g.id).toList()..sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
      if (inGen.isEmpty) continue;
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(Space.gutter, children.isEmpty ? Space.s : Space.xxl, Space.gutter, Space.xs),
          child: Text(g.label, style: text.titleSmall?.copyWith(color: Ramp.n6)),
        ),
      );
      for (var i = 0; i < inGen.length; i++) {
        final vg = inGen[i];
        if (i > 0) children.add(const Perforation(indent: Space.gutter));
        children.add(
          InkWell(
            onTap: () => onPick(vg),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.m, Space.m, Space.m),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vg.name, style: text.titleLarge),
                        const SizedBox(height: 2),
                        Text(index.dexNames(vg.id), style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.m),
                  Text('${index.regional(vg.id).length}', style: text.titleSmall?.copyWith(color: Ramp.n6)),
                  const Icon(Icons.chevron_right_rounded, color: Ramp.n5),
                ],
              ),
            ),
          ),
        );
      }
    }
    return ListView(
      padding: EdgeInsets.only(bottom: Space.xxl + MediaQuery.paddingOf(context).bottom),
      children: children,
    );
  }
}

class _VersionStep extends StatelessWidget {
  const _VersionStep({required this.game, required this.onPick});
  final VersionGroup game;
  final ValueChanged<Version> onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final versions = pickableVersions(game);
    return ListView(
      padding: EdgeInsets.only(bottom: Space.xxl + MediaQuery.paddingOf(context).bottom),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.s, Space.gutter, Space.l),
          child: Text('${game.name}: a versão define os exclusivos e onde cada Pokémon aparece.', style: text.bodyMedium),
        ),
        for (var i = 0; i < versions.length; i++) ...[
          if (i > 0) const Perforation(indent: Space.gutter + 52 + Space.m),
          InkWell(
            onTap: () => onPick(versions[i]),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.m, Space.m, Space.m),
              child: Row(
                children: [
                  GameSeal(code: versionCode(versions[i])),
                  const SizedBox(width: Space.m),
                  Expanded(child: Text(versions[i].name, style: text.titleLarge)),
                  const Icon(Icons.chevron_right_rounded, color: Ramp.n5),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.game,
    required this.version,
    required this.controller,
    required this.nuzlocke,
    required this.saving,
    required this.onNuzlocke,
    required this.onCreate,
  });

  final VersionGroup game;
  final Version? version;
  final TextEditingController controller;
  final bool nuzlocke;
  final bool saving;
  final ValueChanged<bool> onNuzlocke;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dex = AppScope.read(context).dex;
    final index = GameIndex.of(dex);
    final total = index.regional(game.id).length;
    final code = version != null ? versionCode(version!) : (game.versions.isEmpty ? '?' : versionCode(game.versions.first));

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.s, Space.gutter, Space.l),
              children: [
                Row(
                  children: [
                    GameSeal(code: code),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(version?.name ?? game.name, style: text.titleLarge),
                          Text('${game.name} · $total na dex', style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xxl),
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, _) => TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onCreate(),
                    decoration: InputDecoration(
                      hintText: 'Nome da aventura',
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar nome',
                              icon: const Icon(Icons.close_rounded, color: Ramp.n6),
                              onPressed: controller.clear,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.l),
                  child: Text('Use nomes diferentes para dois saves do mesmo jogo.', style: text.bodySmall),
                ),
                const SizedBox(height: Space.xl),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: nuzlocke,
                  onChanged: onNuzlocke,
                  title: Text('Nuzlocke', style: text.titleMedium),
                  subtitle: Text(
                    'Marca a aventura como Nuzlocke. O registro de encontros e o cemitério chegam numa próxima versão.',
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.s, Space.gutter, Space.l),
            child: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) => SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: value.text.trim().isEmpty || saving ? null : onCreate,
                  child: saving
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Ramp.paper))
                      : const Text('Criar aventura'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
