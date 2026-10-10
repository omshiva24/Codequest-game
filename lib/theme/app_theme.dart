import 'package:flutter/material.dart';

/// Game-specific colours. Every pair used for text was chosen to meet
/// WCAG AA contrast (4.5:1) - and the high-contrast palette goes further.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.background,
    required this.card,
    required this.cardRaised,
    required this.border,
    required this.textDim,
    required this.coin,
    required this.good,
    required this.bad,
    required this.codeBackground,
    required this.codeText,
    required this.onAccent,
  });

  final Color background;
  final Color card;
  final Color cardRaised;
  final Color border;
  final Color textDim;
  final Color coin;
  final Color good;
  final Color bad;
  final Color codeBackground;
  final Color codeText;

  /// Text colour to use on top of bright accent colours.
  final Color onAccent;

  static const GameColors normal = GameColors(
    background: Color(0xFF0E1630),
    card: Color(0xFF18234D),
    cardRaised: Color(0xFF223066),
    border: Color(0xFF34457F),
    textDim: Color(0xFFC9D2F0),
    coin: Color(0xFFFFD447),
    good: Color(0xFF3DDC84),
    bad: Color(0xFFFF7B7B),
    codeBackground: Color(0xFF070B1A),
    codeText: Color(0xFFE6F0FF),
    onAccent: Color(0xFF0B1024),
  );

  static const GameColors highContrast = GameColors(
    background: Color(0xFF000000),
    card: Color(0xFF000000),
    cardRaised: Color(0xFF111111),
    border: Color(0xFFFFFFFF),
    textDim: Color(0xFFFFFFFF),
    coin: Color(0xFFFFFF00),
    good: Color(0xFF00FF66),
    bad: Color(0xFFFF8080),
    codeBackground: Color(0xFF000000),
    codeText: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
  );

  static GameColors of(BuildContext context) =>
      Theme.of(context).extension<GameColors>() ?? normal;

  @override
  GameColors copyWith({
    Color? background,
    Color? card,
    Color? cardRaised,
    Color? border,
    Color? textDim,
    Color? coin,
    Color? good,
    Color? bad,
    Color? codeBackground,
    Color? codeText,
    Color? onAccent,
  }) =>
      GameColors(
        background: background ?? this.background,
        card: card ?? this.card,
        cardRaised: cardRaised ?? this.cardRaised,
        border: border ?? this.border,
        textDim: textDim ?? this.textDim,
        coin: coin ?? this.coin,
        good: good ?? this.good,
        bad: bad ?? this.bad,
        codeBackground: codeBackground ?? this.codeBackground,
        codeText: codeText ?? this.codeText,
        onAccent: onAccent ?? this.onAccent,
      );

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    return GameColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardRaised: Color.lerp(cardRaised, other.cardRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      coin: Color.lerp(coin, other.coin, t)!,
      good: Color.lerp(good, other.good, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      codeText: Color.lerp(codeText, other.codeText, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

const String codeFont = 'CodeMono';

ThemeData buildTheme({required bool highContrast}) {
  final g = highContrast ? GameColors.highContrast : GameColors.normal;
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: g.coin,
    onPrimary: g.onAccent,
    secondary: highContrast ? const Color(0xFF00FFFF) : const Color(0xFF7FE3FF),
    onSecondary: g.onAccent,
    error: g.bad,
    onError: g.onAccent,
    surface: g.card,
    onSurface: Colors.white,
    surfaceContainerHighest: g.cardRaised,
    outline: g.border,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: g.background,
    extensions: [g],
  );

  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: highContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: g.background,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: g.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: g.border, width: highContrast ? 2 : 1),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        foregroundColor: Colors.white,
        side: BorderSide(color: highContrast ? Colors.white : g.border, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: g.coin,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
      ),
    ),
    // A thick, bright focus ring so keyboard users always see where they are.
    focusColor: highContrast ? const Color(0x66FFFF00) : const Color(0x557FE3FF),
    dividerColor: g.border,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: g.cardRaised,
      contentTextStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStatePropertyAll(g.border),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: g.cardRaised,
      hintStyle: TextStyle(color: g.textDim),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: g.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: g.border, width: highContrast ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: g.coin, width: 2),
      ),
    ),
  );
}
