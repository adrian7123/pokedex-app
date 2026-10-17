import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Dados sob demanda da PokeAPI (flavor text, artwork) com cache em disco.
///
/// A PokeAPI pede que cada cliente guarde localmente o que baixa: o disco é sempre lido
/// primeiro, o JSON só volta à rede depois de [jsonMaxAge] e as imagens nunca expiram.
/// Nada aqui lança: sem rede e sem cache, o resultado é null.
class PokeApiCache {
  PokeApiCache._();

  static final PokeApiCache instance = PokeApiCache._();

  static const _userAgent = 'Pokedex-app/1.0 (Flutter; app pessoal offline)';
  static const jsonMaxAge = Duration(days: 30);
  static const _jsonTimeout = Duration(seconds: 6);
  static const _imageTimeout = Duration(seconds: 10);

  final http.Client _client = http.Client();
  Future<Directory>? _dir;
  final Map<String, Future<Object?>> _inflight = {};

  /// JSON de um recurso. Cache vencido ainda serve quando a rede falha.
  Future<Map<String, dynamic>?> json(String url) => _once(url, () async {
        try {
          final file = await _file(url, '.json');
          Map<String, dynamic>? cached;
          if (await file.exists()) {
            cached = _decode(await file.readAsString());
            final age = DateTime.now().difference(await file.lastModified());
            if (cached != null && age < jsonMaxAge) return cached;
          }
          final body = await _get(url, _jsonTimeout);
          if (body != null) {
            final fresh = _decode(utf8.decode(body, allowMalformed: true));
            if (fresh != null) {
              await _write(file, body);
              return fresh;
            }
          }
          return cached;
        } catch (_) {
          return null;
        }
      });

  /// Arquivo local de uma imagem, baixando na primeira vez.
  Future<File?> image(String url) => _once(url, () async {
        try {
          final ext = p.extension(Uri.parse(url).path);
          final file = await _file(url, ext.isEmpty ? '.bin' : ext);
          if (await file.exists() && await file.length() > 0) return file;
          final body = await _get(url, _imageTimeout);
          if (body == null || body.isEmpty) return null;
          await _write(file, body);
          return file;
        } catch (_) {
          return null;
        }
      });

  /// Uma requisição por URL de cada vez, mesmo com várias telas pedindo.
  Future<T> _once<T>(String key, Future<T> Function() run) {
    final running = _inflight[key];
    if (running != null) return running as Future<T>;
    final future = run();
    _inflight[key] = future;
    future.whenComplete(() => _inflight.remove(key)).ignore();
    return future;
  }

  Future<Directory> _directory() => _dir ??= () async {
        final base = await getApplicationSupportDirectory();
        final dir = Directory(p.join(base.path, 'http_cache'));
        await dir.create(recursive: true);
        return dir;
      }();

  Future<File> _file(String url, String ext) async => File(p.join((await _directory()).path, '${_key(url)}$ext'));

  Future<List<int>?> _get(String url, Duration timeout) async {
    try {
      final res = await _client.get(Uri.parse(url), headers: const {'User-Agent': _userAgent}).timeout(timeout);
      return res.statusCode == 200 ? res.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  /// Grava num temporário e renomeia, para nunca deixar arquivo pela metade.
  Future<void> _write(File file, List<int> bytes) async {
    try {
      final tmp = File('${file.path}.part');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    } catch (_) {}
  }

  static Map<String, dynamic>? _decode(String text) {
    try {
      final value = jsonDecode(text);
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// Nome do arquivo: dois FNV-1a de 32 bits com sementes diferentes (64 bits no total).
  static String _key(String url) {
    var a = 0x811c9dc5;
    var b = 0x050c5d1f;
    for (final c in utf8.encode(url)) {
      a = ((a ^ c) * 0x01000193) & 0xffffffff;
      b = ((b ^ c) * 0x01000193) & 0xffffffff;
    }
    return a.toRadixString(16).padLeft(8, '0') + b.toRadixString(16).padLeft(8, '0');
  }
}
