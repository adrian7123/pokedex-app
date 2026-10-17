import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

const _font = 'MPLUSRounded1c';

TextStyle _t(double size, FontWeight weight, {Color color = Ramp.ink, double? height, double spacing = 0}) =>
    TextStyle(
      fontFamily: _font,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// Papéis do Material mapeados para os 5 tamanhos da escala.
final TextTheme appTextTheme = TextTheme(
  displayLarge: _t(TypeSize.monument, FontWeight.w800, color: Ramp.n3, height: 1, spacing: -1.6),
  headlineMedium: _t(TypeSize.headline, FontWeight.w800, height: 1.15, spacing: -.6),
  titleLarge: _t(TypeSize.title, FontWeight.w700, height: 1.25, spacing: -.2),
  titleMedium: _t(TypeSize.body, FontWeight.w700, height: 1.3),
  titleSmall: _t(TypeSize.caption, FontWeight.w700, height: 1.3),
  bodyLarge: _t(TypeSize.body, FontWeight.w400, height: 1.45),
  bodyMedium: _t(TypeSize.body, FontWeight.w400, color: Ramp.n6, height: 1.45),
  bodySmall: _t(TypeSize.caption, FontWeight.w400, color: Ramp.n6, height: 1.35),
  labelLarge: _t(TypeSize.body, FontWeight.w500),
  labelMedium: _t(TypeSize.caption, FontWeight.w500, color: Ramp.n6),
  labelSmall: _t(TypeSize.caption, FontWeight.w500, color: Ramp.n6),
);

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: Ramp.ink,
    onPrimary: Ramp.paper,
    secondary: Ramp.n6,
    onSecondary: Ramp.paper,
    error: Color(0xFFC9401C),
    onError: Ramp.paper,
    surface: Ramp.paper,
    onSurface: Ramp.ink,
    onSurfaceVariant: Ramp.n6,
    surfaceContainerLowest: Ramp.paper,
    surfaceContainerLow: Ramp.n1,
    surfaceContainer: Ramp.n1,
    surfaceContainerHigh: Ramp.n2,
    surfaceContainerHighest: Ramp.n2,
    outline: Ramp.n4,
    outlineVariant: Ramp.n2,
    secondaryContainer: Ramp.n2,
    onSecondaryContainer: Ramp.ink,
    inverseSurface: Ramp.ink,
    onInverseSurface: Ramp.paper,
    scrim: Ramp.ink,
    shadow: Ramp.ink,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _font,
    scaffoldBackgroundColor: Ramp.paper,
    textTheme: appTextTheme,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Ramp.paper,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Ramp.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: appTextTheme.titleLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Ramp.paper,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Ramp.n2,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => _t(
          TypeSize.caption,
          s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Ramp.ink : Ramp.n6,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Ramp.ink : Ramp.n6, size: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Ramp.n1,
      hintStyle: _t(TypeSize.body, FontWeight.w400, color: Ramp.n6),
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.pill), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.pill),
        borderSide: const BorderSide(color: Ramp.ink, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Ramp.paper,
      selectedColor: Ramp.ink,
      secondarySelectedColor: Ramp.ink,
      checkmarkColor: Ramp.paper,
      side: const BorderSide(color: Ramp.n2),
      shape: const StadiumBorder(),
      // M3 usa labelStyle em todos os estados e mescla com os padrões (um WidgetStateTextStyle perde a
      // cor nessa mescla). O chip selecionado passa `secondaryLabelStyle` explicitamente.
      labelStyle: _t(TypeSize.caption, FontWeight.w500, color: Ramp.n6),
      secondaryLabelStyle: _t(TypeSize.caption, FontWeight.w700, color: Ramp.paper),
      padding: const EdgeInsets.symmetric(horizontal: Space.s),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Ramp.ink,
      unselectedLabelColor: Ramp.n6,
      labelStyle: _t(TypeSize.body, FontWeight.w700),
      unselectedLabelStyle: _t(TypeSize.body, FontWeight.w500),
      indicatorColor: Ramp.ink,
      dividerColor: Ramp.n2,
      tabAlignment: TabAlignment.start,
      overlayColor: WidgetStatePropertyAll(Ramp.n1),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Ramp.paper,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Ramp.n3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    ),
    dividerTheme: const DividerThemeData(color: Ramp.n2, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Ramp.ink,
      contentTextStyle: _t(TypeSize.body, FontWeight.w500, color: Ramp.paper),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide(color: Ramp.n2)),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Ramp.ink : Ramp.paper),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Ramp.paper : Ramp.n6),
        textStyle: WidgetStatePropertyAll(_t(TypeSize.caption, FontWeight.w700)),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Ramp.ink,
      selectionColor: Ramp.n3.withValues(alpha: .6),
      selectionHandleColor: Ramp.ink,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
