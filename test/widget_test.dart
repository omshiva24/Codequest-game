import 'dart:math';

import 'package:codequest/app.dart';
import 'package:codequest/app_scope.dart';
import 'package:codequest/data/curriculum.dart';
import 'package:codequest/logic/progress.dart';
import 'package:codequest/screens/achievements_screen.dart';
import 'package:codequest/screens/battle_screen.dart';
import 'package:codequest/screens/home_screen.dart';
import 'package:codequest/screens/puzzle_screen.dart';
import 'package:codequest/screens/runner_screen.dart';
import 'package:codequest/screens/settings_screen.dart';
import 'package:codequest/screens/title_screen.dart';
import 'package:codequest/services/sound.dart';
import 'package:codequest/services/doubt_service.dart';
import 'package:codequest/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _calm = AppSettings(reduceMotion: true, timerMode: TimerMode.off);

Future<ProgressController> pumpApp(WidgetTester tester, {AppSettings settings = _calm}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final progress = ProgressController(storage: MemoryProgressStorage())..updateSettings(settings);
  await tester.pumpWidget(CodeQuestApp(controller: progress, doubtService: DoubtService()));
  await tester.pumpAndSettle();
  // Title screen first: press Play.
  await tester.tap(find.text('Play'));
  await tester.pumpAndSettle();
  return progress;
}

/// Pumps a single game screen with a fixed random seed.
Future<ProgressController> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  AppSettings settings = _calm,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final progress = ProgressController(storage: MemoryProgressStorage())..updateSettings(settings);
  await tester.pumpWidget(AppScope(
    controller: progress,
    doubtService: DoubtService(),
    child: MaterialApp(
      theme: buildTheme(highContrast: false),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: screen,
    ),
  ));
  await tester.pump();
  return progress;
}

Finder semantics(String pattern) => find.bySemanticsLabel(RegExp(pattern));

String esc(String s) => RegExp.escape(s);

void main() {
  testWidgets('title screen leads to the home hub with all four worlds', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final progress = ProgressController(storage: MemoryProgressStorage())..updateSettings(_calm);
    await tester.pumpWidget(CodeQuestApp(controller: progress, doubtService: DoubtService()));
    await tester.pumpAndSettle();
    expect(find.byType(TitleScreen), findsOneWidget);
    expect(find.bySemanticsLabel('CodeQuest'), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    for (final world in ['Python Jungle', 'C Caves', 'C++ Castle', 'Java Volcano']) {
      expect(find.text(world), findsWidgets);
    }
    expect(find.text('Doubt Buddy'), findsOneWidget);
    expect(find.text('Did you know?'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('trophy room lists every badge', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip(RegExp('^Trophy room')));
    await tester.pumpAndSettle();
    expect(find.byType(AchievementsScreen), findsOneWidget);
    expect(find.text('First steps'), findsOneWidget);
    expect(find.textContaining('No badges yet'), findsOneWidget);
  });

  testWidgets('world -> lesson -> runner navigation', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Python Jungle').first);
    await tester.pumpAndSettle();
    expect(find.text('Hello, Python!'), findsOneWidget);

    // Locked levels explain why they are locked.
    await tester.tap(find.text('Variables & Types'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Finish level 1 first'), findsOneWidget);

    await tester.tap(find.text('Hello, Python!'));
    await tester.pumpAndSettle();
    expect(find.text('Talking to the computer'), findsOneWidget);
    await tester.ensureVisible(find.text('Start Code Runner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Code Runner'));
    await tester.pumpAndSettle();
    expect(find.byType(RunnerScreen), findsOneWidget);
  });

  testWidgets('runner: a perfect run gives 3 stars and unlocks level 2', (tester) async {
    final handle = tester.ensureSemantics();
    final level = levelById('py-1')!;
    final progress = await pumpScreen(tester, RunnerScreen(level: level, random: Random(1)));
    for (var i = 0; i < level.questions.length; i++) {
      final answer = level.questions[i].correctText;
      await tester.tap(semantics('^Gate \\d: ${esc(answer)}(, selected)?\$'));
      await tester.pump();
      await tester.tap(find.text('Go!'));
      await tester.pump();
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      await tester.tap(find.text(i == level.questions.length - 1 ? 'See results' : 'Next gate'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Level clear!'), findsWidgets);
    expect(find.text('Badge unlocked: First steps'), findsOneWidget);
    expect(progress.starsFor('py-1'), 3);
    expect(progress.bestCombo, level.questions.length);
    expect(progress.isUnlocked(levelById('py-2')!), isTrue);
    handle.dispose();
  });

  testWidgets('runner: keyboard controls and a wrong gate shows the right answer', (tester) async {
    final level = levelById('c-1')!;
    await pumpScreen(tester, RunnerScreen(level: level, random: Random(2)));
    final q = level.questions.first;
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    // Either cheer or "Oops" - both show the explanation.
    expect(find.text(q.explanation), findsOneWidget);
  });

  testWidgets('runner: timer runs out and resolves the gate automatically', (tester) async {
    final level = levelById('java-1')!;
    await pumpScreen(
      tester,
      RunnerScreen(level: level, random: Random(3)),
      settings: const AppSettings(reduceMotion: true, timerMode: TimerMode.normal),
    );
    expect(find.text(level.questions.first.explanation), findsNothing);
    await tester.pump(const Duration(seconds: 13));
    expect(find.text(level.questions.first.explanation), findsOneWidget);
  });

  testWidgets('battle: wrong answers come back and the monster can still be beaten', (tester) async {
    final handle = tester.ensureSemantics();
    final level = levelById('py-2')!;
    final progress = await pumpScreen(tester, BattleScreen(level: level, random: Random(4)));
    expect(find.textContaining('A wild Type Goblin appeared'), findsOneWidget);

    // First question: pick a wrong move on purpose.
    final first = level.questions.first;
    final wrong = first.options.firstWhere((o) => o != first.correctText);
    await tester.tap(semantics('^Move \\d: ${esc(wrong)}\$'));
    await tester.pump();
    expect(find.text('Missed!'), findsOneWidget);
    expect(find.text('Ask Doubt Buddy'), findsOneWidget);
    await tester.tap(find.text('Next move'));
    await tester.pumpAndSettle();

    // Then answer everything correctly (the missed one comes back last).
    final order = [...level.questions.skip(1), first];
    for (final q in order) {
      await tester.tap(semantics('^Move \\d: ${esc(q.correctText)}\$'));
      await tester.pump();
      expect(find.text('Hit!'), findsOneWidget);
      await tester.tap(find.text(q == first ? 'See results' : 'Next move'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Level clear!'), findsWidgets);
    expect(find.text('Learn from your mistakes'), findsWidgets);
    expect(progress.starsFor('py-2'), 2);
    handle.dispose();
  });

  testWidgets('puzzle: building the program in order solves it', (tester) async {
    final handle = tester.ensureSemantics();
    final level = levelById('py-3')!;
    await pumpScreen(tester, PuzzleScreen(level: level, random: Random(5)));
    for (var p = 0; p < level.puzzles.length; p++) {
      // Block ids are the line positions, so tapping 0, 1, 2... builds the program.
      for (var i = 0; i < level.puzzles[p].lines.length; i++) {
        final block = find.byKey(ValueKey('block-$i'));
        await tester.ensureVisible(block);
        await tester.pump();
        await tester.tap(block);
        await tester.pump();
      }
      await tester.ensureVisible(find.text('Run code'));
      await tester.tap(find.text('Run code'));
      await tester.pump();
      expect(find.text('Program works!'), findsOneWidget);
      // The console shows what the program prints.
      expect(find.text(level.puzzles[p].output), findsOneWidget);
      await tester.tap(find.text(p == level.puzzles.length - 1 ? 'See results' : 'Next puzzle'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Level clear!'), findsWidgets);
    handle.dispose();
  });

  testWidgets('puzzle: a wrong order shows a bug and costs a heart', (tester) async {
    final handle = tester.ensureSemantics();
    final level = levelById('c-3')!;
    await pumpScreen(tester, PuzzleScreen(level: level, random: Random(6)));
    final lines = level.puzzles.first.lines.length;
    for (var i = lines - 1; i >= 0; i--) {
      final block = find.byKey(ValueKey('block-$i'));
      await tester.ensureVisible(block);
      await tester.tap(block);
      await tester.pump();
    }
    await tester.ensureVisible(find.text('Run code'));
    await tester.tap(find.text('Run code'));
    await tester.pump();
    expect(find.textContaining('Bug found'), findsOneWidget);
    expect(find.bySemanticsLabel('2 of 3 hearts left'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('runner: 50/50 spends coins and removes a wrong gate', (tester) async {
    final handle = tester.ensureSemantics();
    final level = levelById('cpp-1')!;
    final progress = await pumpScreen(tester, RunnerScreen(level: level, random: Random(7)));

    // No coins yet: the power-up explains how to earn them.
    await tester.tap(semantics('^Use 50/50'));
    await tester.pump();
    expect(find.textContaining('You need 15 coins'), findsOneWidget);

    progress.recordResult(levelById('py-1')!, stars: 3, correct: 5);
    final before = progress.coins;
    await tester.pump();
    await tester.tap(semantics('^Use 50/50'));
    await tester.pump();
    expect(progress.coins, before - 15);
    expect(semantics('removed by 50/50'), findsOneWidget);
    expect(semantics('^50/50 already used'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Doubt Buddy answers offline with an example', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Doubt Buddy'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'What is a pointer in C?');
    await tester.tap(find.byTooltip('Send question'));
    await tester.pumpAndSettle();
    expect(find.text('Offline buddy answer'), findsOneWidget);
    expect(find.textContaining('Example in C'), findsOneWidget);
  });

  testWidgets('settings switch on high contrast and persist it', (tester) async {
    final progress = await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings and accessibility'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High contrast'));
    await tester.pumpAndSettle();
    expect(progress.settings.highContrast, isTrue);
    final colors = GameColors.of(tester.element(find.byType(SettingsScreen)));
    expect(colors.highContrast, isTrue);
    expect(colors.parchment, GameColors.highContrastColors.parchment);
  });

  testWidgets('settings can switch sound effects off', (tester) async {
    final progress = await pumpApp(tester);
    expect(SoundFx.enabled, isTrue);
    await tester.tap(find.byTooltip('Settings and accessibility'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sound effects'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sound effects'));
    await tester.pumpAndSettle();
    expect(progress.settings.soundOn, isFalse);
    expect(SoundFx.enabled, isFalse);
  });
}
