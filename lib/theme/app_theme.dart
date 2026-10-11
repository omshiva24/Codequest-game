import 'package:flutter/material.dart';

/// CodeQuest's "sticker-book arcade" look.
///
/// Everything is a physical toy: thick ink outlines, hard drop "lips" under
/// buttons and parchment panels for reading. Text that people read always sits
/// on parchment (ink text) or on a code panel, so contrast stays high (WCAG AA)
/// even on top of the animated world scenes.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.ink,
    required this.parchment,
    required this.parchmentShade,
    required this.parchmentText,
    required this.parchmentDim,
    required this.nightTop,
    required this.nightBottom,
    required this.onNight,
    required this.onNightDim,
    required this.gold,
    required this.goldLip,
    required this.mint,
    required this.mintLip,
    required this.coral,
    required this.coralLip,
    required this.sky,
    required this.skyLip,
    required this.lilac,
    required this.lilacLip,
    required this.codeBackground,
    required this.codeBar,
    required this.codeText,
    required this.codeDim,
    required this.disabled,
    required this.focus,
    required this.outlineWidth,
    required this.highContrast,
  });

  /// Outline colour and text colour on light surfaces.
  final Color ink;
  final Color parchment;
  final Color parchmentShade;
  final Color parchmentText;
  final Color parchmentDim;
  final Color nightTop;
  final Color nightBottom;
  final Color onNight;
  final Color onNightDim;
  final Color gold;
  final Color goldLip;
  final Color mint;
  final Color mintLip;
  final Color coral;
  final Color coralLip;
  final Color sky;
  final Color skyLip;
  final Color lilac;
  final Color lilacLip;
  final Color codeBackground;
  final Color codeBar;
  final Color codeText;
  final Color codeDim;
  final Color disabled;
  final Color focus;
  final double outlineWidth;
  final bool highContrast;

  // Older names, kept so shared widgets read naturally.
  Color get good => mint;
  Color get bad => coral;
  Color get coin => gold;
  Color get onAccent => ink;

  static const GameColors normal = GameColors(
    ink: Color(0xFF2B1840),
    parchment: Color(0xFFFFF4D6),
    parchmentShade: Color(0xFFE9C98B),
    parchmentText: Color(0xFF2B1840),
    parchmentDim: Color(0xFF5B4470),
    nightTop: Color(0xFF4A2391),
    nightBottom: Color(0xFF1B0D40),
    onNight: Color(0xFFFFFFFF),
    onNightDim: Color(0xFFEADFFF),
    gold: Color(0xFFFFC93C),
    goldLip: Color(0xFFC9781F),
    mint: Color(0xFF3DDC84),
    mintLip: Color(0xFF1E8E52),
    coral: Color(0xFFFF6B7F),
    coralLip: Color(0xFFB8324A),
    sky: Color(0xFF5BC0FF),
    skyLip: Color(0xFF2470B3),
    lilac: Color(0xFFC3A0FF),
    lilacLip: Color(0xFF7448C9),
    codeBackground: Color(0xFF1E1433),
    codeBar: Color(0xFF2E2050),
    codeText: Color(0xFFF6EEFF),
    codeDim: Color(0xFFBBA8DD),
    disabled: Color(0xFFB9AFC7),
    focus: Color(0xFFFFFFFF),
    outlineWidth: 3,
    highContrast: false,
  );

  static const GameColors highContrastColors = GameColors(
    ink: Color(0xFF000000),
    parchment: Color(0xFFFFFFFF),
    parchmentShade: Color(0xFF000000),
    parchmentText: Color(0xFF000000),
    parchmentDim: Color(0xFF000000),
    nightTop: Color(0xFF000000),
    nightBottom: Color(0xFF000000),
    onNight: Color(0xFFFFFFFF),
    onNightDim: Color(0xFFFFFFFF),
    gold: Color(0xFFFFE100),
    goldLip: Color(0xFF000000),
    mint: Color(0xFF00F07A),
    mintLip: Color(0xFF000000),
    coral: Color(0xFFFF8A9A),
    coralLip: Color(0xFF000000),
    sky: Color(0xFF6CD3FF),
    skyLip: Color(0xFF000000),
    lilac: Color(0xFFD9C2FF),
    lilacLip: Color(0xFF000000),
    codeBackground: Color(0xFF000000),
    codeBar: Color(0xFF000000),
    codeText: Color(0xFFFFFFFF),
    codeDim: Color(0xFFFFFFFF),
    disabled: Color(0xFFCCCCCC),
    focus: Color(0xFFFFE100),
    outlineWidth: 3.5,
    highContrast: true,
  );

  static GameColors of(BuildContext context) =>
      Theme.of(context).extension<GameColors>() ?? normal;

  @override
  GameColors copyWith() => this;

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) =>
      (other is GameColors && t >= 0.5) ? other : this;
}

const String codeFont = 'CodeMono';
const String displayFont = 'Lilita';

/// Big chunky title style (Lilita One).
TextStyle displayStyle(double size, {Color? color, double height = 1.1}) => TextStyle(
      fontFamily: displayFont,
      fontSize: size,
      height: height,
      color: color,
      letterSpacing: 0.4,
    );

ThemeData buildTheme({required bool highContrast}) {
  final g = highContrast ? GameColors.highContrastColors : GameColors.normal;
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: g.gold,
    onPrimary: g.ink,
    secondary: g.sky,
    onSecondary: g.ink,
    error: g.coralLip,
    onError: g.parchment,
    surface: g.parchment,
    onSurface: g.parchmentText,
    surfaceContainerHighest: g.parchmentShade,
    outline: g.ink,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: g.nightBottom,
    extensions: [g],
  );

  final inkBorder = BorderSide(color: g.ink, width: g.outlineWidth);

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: g.parchmentText, displayColor: g.parchmentText),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: g.onNight,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: displayStyle(24, color: g.onNight),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: g.parchment,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: inkBorder),
      titleTextStyle: displayStyle(24, color: g.ink),
      contentTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: g.parchmentText),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: g.ink,
        minimumSize: const Size(48, 48),
        textStyle: displayStyle(18),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: g.parchment,
      contentTextStyle: TextStyle(fontFamily: 'Poppins', color: g.parchmentText, fontSize: 15),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: inkBorder),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? g.ink : g.parchment,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? g.mint : g.disabled,
      ),
      trackOutlineColor: WidgetStatePropertyAll(g.ink),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        side: WidgetStatePropertyAll(inkBorder),
        textStyle: WidgetStatePropertyAll(displayStyle(17)),
        foregroundColor: WidgetStatePropertyAll(g.ink),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? g.gold : g.parchment,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: g.parchment,
      selectedColor: g.gold,
      labelStyle: TextStyle(fontFamily: 'Poppins', color: g.ink, fontWeight: FontWeight.w700),
      side: BorderSide(color: g.ink, width: 2),
      checkmarkColor: g.ink,
      shape: const StadiumBorder(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: g.gold),
    focusColor: g.focus.withValues(alpha: 0.35),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: g.parchment,
      labelStyle: TextStyle(color: g.parchmentDim, fontWeight: FontWeight.w700),
      floatingLabelStyle: TextStyle(color: g.ink, fontWeight: FontWeight.w700),
      hintStyle: TextStyle(color: g.parchmentDim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: inkBorder),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: inkBorder),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: g.ink, width: g.outlineWidth + 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: g.ink,
      selectionColor: g.gold.withValues(alpha: 0.6),
    ),
  );
}
