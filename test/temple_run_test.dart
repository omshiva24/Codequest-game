// Plays the action Code Runner through the real screen, frame by frame.

import 'dart:math';

import 'package:codequest/app_scope.dart';
import 'package:codequest/data/curriculum.dart';
import 'package:codequest/logic/progress.dart';
import 'package:codequest/logic/run_autopilot.dart';
import 'package:codequest/logic/run_engine.dart';
import 'package:codequest/screens/lesson_screen.dart';
import 'package:codequest/screens/result_screen.dart';
import 'package:codequest/screens/temple_run.dart';
import 'package:codequest/services/doubt_service.dart';
import 'package:codequest/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _frame = Duration(milliseconds: 50);

Future<ProgressController> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1000, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final progress = ProgressController(storage: MemoryProgressStorage());
  await tester.pumpWidget(AppScope(
    controller: progress,
    doubtService: DoubtService(),
    child: MaterialApp(theme: buildTheme(highContrast: false), home: screen),
  ));
  await tester.pump();
  return progress;
}

/// Pumps frames until [done] is true (or [seconds] of game time pass).
Future<void> _play(WidgetTester tester, bool Function() done, {double seconds = 120, void Function()? each}) async {
  for (var t = 0.0; t < seconds && !done(); t += _frame.inMilliseconds / 1000) {
    each?.call();
    await tester.pump(_frame);
  }
}

/// Advances game time in small frames (the game caps each frame at 0.05 s).
Future<void> _frames(WidgetTester tester, double seconds) async {
  for (var t = 0.0; t < seconds; t += _frame.inMilliseconds / 1000) {
    await tester.pump(_frame);
  }
}

void main() {
  testWidgets('a perfect player finishes the action runner with 3 stars and track coins', (tester) async {
    late RunEngine engine;
    final level = levelById('py-1')!;
    final progress = await _pump(
      tester,
      TempleRun(level: level, random: Random(3), onEngineReady: (e) => engine = e),
    );
    expect(find.text('Code gate 1 of 5'), findsOneWidget);

    await _play(tester, () => find.byType(ResultScreen).evaluate().isNotEmpty, each: () => autopilot(engine));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Level clear!'), findsOneWidget);
    expect(progress.starsFor('py-1'), 3);
    expect(engine.coins, greaterThan(10), reason: 'coins on the track were collected');
    expect(progress.coins, greaterThanOrEqualTo(engine.coins));
    expect(progress.isUnlocked(levelById('py-2')!), isTrue);
  });

  testWidgets("Byte's demo run plays itself, saves nothing and returns to the lesson", (tester) async {
    final level = levelById('c-1')!;
    final progress = await _pump(tester, TempleRun(level: level, random: Random(4), demo: true));
    expect(find.text('Demo'), findsOneWidget);

    // Pressing keys during the demo does not break it.
    await _frames(tester, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);

    await _play(tester, () => find.byType(LessonScreen).evaluate().isNotEmpty);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.textContaining("Byte's demo run"), findsOneWidget);
    expect(progress.starsFor('c-1'), 0);
    expect(progress.coins, 0);
    expect(progress.xp, 0);
  });

  testWidgets('keyboard controls: lanes, jump and slide', (tester) async {
    late RunEngine engine;
    await _pump(
      tester,
      TempleRun(level: levelById('java-1')!, random: Random(5), onEngineReady: (e) => engine = e),
    );
    await _frames(tester, 3.3); // countdown

    expect(engine.lane, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(engine.lane, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    expect(engine.lane, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(engine.jumping, isTrue);
    await _frames(tester, 0.8);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(engine.sliding, isTrue);

    // Escape pauses; the menu offers Resume.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    final distance = engine.distance;
    await tester.pump(const Duration(seconds: 1));
    expect(engine.distance, distance, reason: 'nothing moves while paused');
  });

  testWidgets('action runner controls are big enough and labelled', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, TempleRun(level: levelById('py-4')!, random: Random(6)));
    await _frames(tester, 3.3);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
