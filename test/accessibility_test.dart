// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// Checks Flutter's built-in accessibility guidelines on every main screen:
// - tap targets are at least 48x48 (Android) / 44x44 (iOS)
// - every tappable thing has a label for screen readers
// - text has enough colour contrast (WCAG AA)

import 'dart:math';

import 'package:codequest/app.dart';
import 'package:codequest/app_scope.dart';
import 'package:codequest/data/curriculum.dart';
import 'package:codequest/logic/achievements.dart';
import 'package:codequest/logic/progress.dart';
import 'package:codequest/logic/session.dart';
import 'package:codequest/models/models.dart';
import 'package:codequest/screens/about_screen.dart';
import 'package:codequest/screens/achievements_screen.dart';
import 'package:codequest/screens/battle_screen.dart';
import 'package:codequest/screens/builder_screen.dart';
import 'package:codequest/screens/doubt_buddy_screen.dart';
import 'package:codequest/screens/home_screen.dart';
import 'package:codequest/screens/lesson_screen.dart';
import 'package:codequest/screens/login_screen.dart';
import 'package:codequest/screens/navigation.dart';
import 'package:codequest/screens/puzzle_screen.dart';
import 'package:codequest/screens/result_screen.dart';
import 'package:codequest/screens/settings_screen.dart';
import 'package:codequest/screens/title_screen.dart';
import 'package:codequest/screens/world_screen.dart';
import 'package:codequest/services/doubt_service.dart';
import 'package:codequest/theme/app_theme.dart';
import 'package:codequest/widgets/game_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_account_server.dart';

const _calm = AppSettings(reduceMotion: true, timerMode: TimerMode.off);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  bool highContrast = false,
  Future<SessionController> Function(ProgressController progress)? session,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final progress = ProgressController(storage: MemoryProgressStorage())
    ..updateSettings(_calm.copyWith(highContrast: highContrast));
  final players = session == null
      ? SessionController.preloaded(progress)
      : (await tester.runAsync(() => session(progress)))!;
  await tester.pumpWidget(SessionScope(
    session: players,
    child: AppScope(
    controller: progress,
    doubtService: DoubtService(),
    child: MaterialApp(
      theme: buildTheme(highContrast: highContrast),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: home,
    ),
  ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  final screens = <String, Widget Function()>{
    'title': () => const TitleScreen(),
    'home': () => const HomeScreen(),
    'trophy room': () => const AchievementsScreen(),
    'results': () => ResultScreen(
          outcome: GameOutcome(
            level: levelById('py-2')!,
            won: true,
            correct: 4,
            total: 5,
            stars: 2,
            bestCombo: 3,
            review: const [
              ReviewItem(prompt: 'What does this print?', code: 'print(2 + 3)', correctAnswer: '5', explanation: 'Maths first.'),
            ],
          ),
          reward: LevelReward(
            stars: 2,
            xp: 60,
            coins: 30,
            newBest: true,
            leveledUp: false,
            unlockedNext: levelById('py-3'),
            newAchievements: [achievementById('first_steps')!],
          ),
        ),
    'world map': () => const WorldScreen(lang: Lang.python),
    'lesson': () => LessonScreen(level: levelById('c-2')!),
    'world builder': () => BuilderScreen(level: levelById('py-1')!),
    'world builder (loops)': () => BuilderScreen(level: levelById('cpp-4')!),
    'battle': () => BattleScreen(level: levelById('java-2')!, random: Random(1)),
    'puzzle': () => PuzzleScreen(level: levelById('cpp-3')!, random: Random(1)),
    'doubt buddy': () => const DoubtBuddyScreen(),
    'settings': () => const SettingsScreen(),
    'about (creator)': () => const AboutScreen(),
  };

  testWidgets('app start (title screen) meets accessibility guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final progress = ProgressController(storage: MemoryProgressStorage())..updateSettings(_calm);
    await tester.pumpWidget(CodeQuestApp(controller: progress, doubtService: DoubtService()));
    await tester.pumpAndSettle();
    await _expectAccessible(tester);
    handle.dispose();
  });

  for (final highContrast in [false, true]) {
    screens.forEach((name, build) {
      testWidgets('$name meets accessibility guidelines${highContrast ? ' (high contrast)' : ''}',
          (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, build(), highContrast: highContrast);
        await _expectAccessible(tester);
        handle.dispose();
      });
    });
  }

  for (final highContrast in [false, true]) {
    final hc = highContrast ? ' (high contrast)' : '';

    testWidgets("who's playing (sign up form) meets accessibility guidelines$hc", (tester) async {
      final handle = tester.ensureSemantics();
      final server = FakeAccountServer();
      await _pump(
        tester,
        const LoginScreen(startWithSignUp: true),
        highContrast: highContrast,
        session: (p) async => SessionController(
          progress: p,
          accounts: server.service(),
          guestStorage: MemoryProgressStorage('{"xp":90,"stars":{"py-1":3}}'),
        ),
      );
      expect(find.text('Continue guest game'), findsOneWidget);
      await _expectAccessible(tester);
      handle.dispose();
    });

    testWidgets("who's playing (log in, with an error) meets accessibility guidelines$hc", (tester) async {
      final handle = tester.ensureSemantics();
      final server = FakeAccountServer();
      await _pump(
        tester,
        const LoginScreen(),
        highContrast: highContrast,
        session: (p) async => SessionController(progress: p, accounts: server.service(), guestStorage: MemoryProgressStorage()),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'om@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(GameButton, 'Log in'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(find.text('Email or password is wrong.'), findsOneWidget);
      await _expectAccessible(tester);
      handle.dispose();
    });

    testWidgets('settings for a logged-in player meet accessibility guidelines$hc', (tester) async {
      final handle = tester.ensureSemantics();
      final server = FakeAccountServer()..addAccount('om@example.com', 'Om', 'blue-tiger-42');
      await _pump(
        tester,
        const SettingsScreen(),
        highContrast: highContrast,
        session: (p) async {
          final s = SessionController(progress: p, accounts: server.service(), guestStorage: MemoryProgressStorage());
          await s.login(email: 'om@example.com', password: 'blue-tiger-42');
          return s;
        },
      );
      expect(find.text('Playing as Om'), findsOneWidget);
      expect(find.widgetWithText(GameButton, 'Delete my account'), findsOneWidget);
      await _expectAccessible(tester);
      handle.dispose();
    });
  }

  testWidgets('game status is announced to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, BattleScreen(level: levelById('py-5')!, random: Random(2)));
    expect(find.bySemanticsLabel(RegExp(r'^\d of 3 hearts left$')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'health$')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Move 1: ')), findsOneWidget);
    handle.dispose();
  });
}
