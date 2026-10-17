import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Expõe o [AppState] para a árvore. `AppScope.of` reconstrói quando o estado muda;
/// `AppScope.read` só lê (para callbacks).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
