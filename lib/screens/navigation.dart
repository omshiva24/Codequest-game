import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../logic/progress.dart';
import '../models/models.dart';
import 'battle_screen.dart';
import 'doubt_buddy_screen.dart';
import 'lesson_screen.dart';
import 'puzzle_screen.dart';
import 'result_screen.dart';
import 'runner_screen.dart';

/// Something the player got wrong, shown on the results screen.
class ReviewItem {
  const ReviewItem({
    required this.prompt,
    required this.correctAnswer,
    required this.explanation,
    this.code,
  });

  final String prompt;
  final String? code;
  final String correctAnswer;
  final String explanation;
}

class GameOutcome {
  const GameOutcome({
    required this.level,
    required this.won,
    required this.correct,
    required this.total,
    required this.stars,
    this.review = const [],
    this.bestCombo = 0,
    this.bonusCoins = 0,
  });

  final Level level;
  final bool won;
  final int correct;
  final int total;
  final int stars;
  final List<ReviewItem> review;

  /// Most right answers in a row during this play.
  final int bestCombo;

  /// Coins collected along the way (the runner track).
  final int bonusCoins;
}

/// Page change with a quick game-style "zoom in" (a plain cut when motion is
/// reduced).
Route<T> gameRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, _, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
        );
      },
    );

void openLesson(BuildContext context, Level level, {bool replace = false}) {
  final route = gameRoute<void>(LessonScreen(level: level));
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

/// Starts the right mini-game for [level], replacing the current screen.
void startGame(BuildContext context, Level level) {
  final Widget page = switch (level.kind) {
    LevelKind.runner => RunnerScreen(level: level),
    LevelKind.battle => BattleScreen(level: level),
    LevelKind.puzzle => PuzzleScreen(level: level),
  };
  Navigator.of(context).pushReplacement(gameRoute<void>(page));
}

/// Saves the result and shows the results screen.
void finishLevel(BuildContext context, GameOutcome outcome) {
  final LevelReward reward = AppScope.read(context).recordResult(
    outcome.level,
    stars: outcome.stars,
    correct: outcome.correct,
    bestCombo: outcome.bestCombo,
    bonusCoins: outcome.bonusCoins,
  );
  Navigator.of(context).pushReplacement(
    gameRoute<void>(ResultScreen(outcome: outcome, reward: reward)),
  );
}

void openDoubtBuddy(
  BuildContext context, {
  String? question,
  Lang? lang,
  String? extraContext,
}) {
  Navigator.of(context).push(gameRoute<void>(DoubtBuddyScreen(
    initialQuestion: question,
    initialLang: lang,
    extraContext: extraContext,
  )));
}

/// Asks before leaving a game in progress.
Future<bool> confirmQuit(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave this level?'),
      content: const Text('Your run will end and this level\'s progress will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep playing'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Wraps a game screen so Back asks for confirmation first.
class QuitGuard extends StatelessWidget {
  const QuitGuard({super.key, required this.child, this.active = true});

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !active,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await confirmQuit(context)) navigator.pop();
      },
      child: child,
    );
  }
}
