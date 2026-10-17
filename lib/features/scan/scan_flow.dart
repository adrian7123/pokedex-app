import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/navigation.dart';
import '../../core/data/models.dart';
import '../../core/state/scope.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/sprite.dart';
import 'scan_screen.dart';

/// Resultado de uma leitura gravada, devolvido pela tela de conferência.
class ScanSaved {
  const ScanSaved(this.entry, {required this.updated});
  final DexEntry entry;
  final bool updated;
}

/// "Carimbar por foto": escolhe as fotos do resumo do Switch, lê no aparelho e abre a conferência.
/// Com [speciesId]/[existingId], atualiza aquele exemplar ("Atualizar por foto").
Future<void> openScanFlow(BuildContext context, {int? speciesId, String? existingId}) async {
  final paths = await pickSummaryPhotos(context);
  if (paths.isEmpty || !context.mounted) return;
  final saved = await Navigator.of(context).push<ScanSaved>(
    MaterialPageRoute(
      builder: (_) => ScanScreen(paths: paths, speciesId: speciesId, existingId: existingId),
    ),
  );
  if (saved == null || !context.mounted) return;
  final name = saved.entry.speciesName;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      persist: false,
      content: Text(saved.updated ? '$name atualizado' : '$name carimbado'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Ver',
        onPressed: () {
          if (context.mounted) openDetail(context, saved.entry, initialTab: 4);
        },
      ),
    ),
  );
}

/// Folha "Câmera / Galeria". Devolve os caminhos das fotos (vazio = cancelou).
Future<List<String>> pickSummaryPhotos(BuildContext context, {bool another = false}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => _SourceSheet(another: another),
  );
  if (source == null || !context.mounted) return const [];
  final picker = ImagePicker();
  try {
    if (source == ImageSource.camera) {
      final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 2400, maxHeight: 2400, imageQuality: 92);
      return file == null ? const [] : [file.path];
    }
    final files = await picker.pickMultiImage(maxWidth: 2400, maxHeight: 2400, imageQuality: 92, limit: 4);
    return [for (final f in files) f.path];
  } on PlatformException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          content: Text(
            source == ImageSource.camera
                ? 'Sem acesso à câmera. Libere a permissão nos ajustes do aparelho.'
                : 'Sem acesso às fotos. Libere a permissão nos ajustes do aparelho.',
          ),
        ),
      );
    }
    return const [];
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.another});
  final bool another;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xs),
              child: Text(another ? 'Adicionar outra página' : 'Carimbar por foto', style: text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.m),
              child: Text(
                another
                    ? 'A página Informações traz natureza, item e local de captura.'
                    : 'Abra o resumo do Pokémon em Scarlet/Violet, de preferência em Golpes e Estatísticas. '
                        'Enquadre só a tela do Switch, sem reflexo.',
                style: text.bodyMedium,
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              leading: const Icon(Icons.photo_camera_outlined, color: Ramp.ink),
              title: const Text('Câmera'),
              subtitle: const Text('Fotografar a tela agora'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              leading: const Icon(Icons.photo_library_outlined, color: Ramp.ink),
              title: const Text('Galeria'),
              subtitle: const Text('Uma ou mais fotos do mesmo Pokémon'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

/// Escolha manual da espécie (leitura falhou ou o usuário quer trocar).
Future<DexEntry?> pickSpecies(BuildContext context) => showModalBottomSheet<DexEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SpeciesSheet(),
    );

class _SpeciesSheet extends StatefulWidget {
  const _SpeciesSheet();

  @override
  State<_SpeciesSheet> createState() => _SpeciesSheetState();
}

class _SpeciesSheetState extends State<_SpeciesSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dex = AppScope.read(context).dex;
    final text = Theme.of(context).textTheme;
    final q = DexEntry.normalize(_query.text);
    final number = int.tryParse(q.replaceAll('#', ''));
    final list = [
      for (final e in dex.entries)
        if (!e.isMega && !e.isGmax && !e.isBattleOnly && (q.isEmpty || e.searchKey.contains(q) || e.speciesId == number)) e,
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      maxChildSize: .95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.s),
            child: Row(children: [Expanded(child: Text('Escolher espécie', style: text.titleLarge))]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.s),
            child: TextField(
              controller: _query,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Nome ou número',
                prefixIcon: Icon(Icons.search_rounded, color: Ramp.n6),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: list.length,
              itemExtent: 56,
              itemBuilder: (context, i) {
                final e = list[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  leading: SizedBox.square(dimension: 40, child: PokemonSprite(e, size: 40)),
                  title: Text(e.isDefault ? e.speciesName : e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text('#${e.speciesId.toString().padLeft(4, '0')}', style: text.labelMedium),
                  onTap: () => Navigator.pop(context, e),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
