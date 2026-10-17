import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/shell.dart';
import 'core/data/dex_database.dart';
import 'core/data/dex_repository.dart';
import 'core/data/user_database.dart';
import 'core/state/app_state.dart';
import 'core/state/scope.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge: o app desenha atrás das barras do sistema e cada tela
  // trata os insets (SafeArea / MediaQuery.padding).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  runApp(const PokedexApp());
}

Future<AppState> _boot() async {
  final dexDb = await DexDatabase.open();
  final dex = DexRepository(dexDb);
  await dex.load();
  final state = AppState(dex: dex, user: UserDatabase());
  await state.init();
  return state;
}

class PokedexApp extends StatefulWidget {
  const PokedexApp({super.key});

  @override
  State<PokedexApp> createState() => _PokedexAppState();
}

class _PokedexAppState extends State<PokedexApp> {
  final _boot$ = _boot();
  final _theme = buildAppTheme();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: ThemeMode.light,
      theme: _theme,
      home: const Shell(),
      // O AppScope envolve o Navigator inteiro: rotas empilhadas (detalhe) e sheets também enxergam o estado.
      builder: (context, navigator) => FutureBuilder<AppState>(
        future: _boot$,
        builder: (context, snap) {
          if (snap.hasError) return _BootError(error: snap.error!);
          final state = snap.data;
          return AnimatedSwitcher(
            duration: Motion.medium,
            child: state == null ? const _Splash() : AppScope(state: state, child: navigator!),
          );
        },
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Ramp.n4),
          ),
        ),
      );
}

class _BootError extends StatelessWidget {
  const _BootError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Center(
            child: Text(
              'Não foi possível abrir o banco da Pokédex.\nReinstale o app se o erro continuar.\n\n$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
}
