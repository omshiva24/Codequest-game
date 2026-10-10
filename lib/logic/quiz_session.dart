import 'dart:math';

import '../models/models.dart';

/// A question with its options shuffled for this play-through.
class PlayQuestion {
  PlayQuestion(this.source, this.options, this.correctIndex);

  final Question source;
  final List<String> options;
  final int correctIndex;

  String get correctText => options[correctIndex];
}

class AnswerResult {
  const AnswerResult({
    required this.question,
    required this.chosenIndex,
    required this.correct,
  });

  final PlayQuestion question;
  final int chosenIndex;
  final bool correct;

  String get chosenText => question.options[chosenIndex];
}

/// Game rules shared by the runner and battle mini-games.
///
/// * Each wrong answer costs one heart.
/// * With [requeueWrong] (battle mode) a missed question comes back at the
///   end, so the player can learn from it and still beat the monster.
class QuizSession {
  QuizSession(
    List<Question> questions, {
    Random? random,
    this.maxLives = 3,
    this.requeueWrong = false,
  })  : assert(questions.isNotEmpty, 'A session needs at least one question'),
        _random = random ?? Random(),
        total = questions.length {
    lives = maxLives;
    _queue.addAll(questions.map(_prepare));
  }

  final Random _random;
  final int maxLives;
  final bool requeueWrong;

  /// Number of different questions in this level.
  final int total;

  final List<PlayQuestion> _queue = [];
  final List<Question> _missed = [];
  final List<AnswerResult> history = [];

  late int lives;
  int firstTryCorrect = 0;
  int solved = 0;

  bool get isOver => lives <= 0 || _queue.isEmpty;
  bool get won => _queue.isEmpty && lives > 0;
  PlayQuestion? get current => isOver ? null : _queue.first;

  /// Questions still waiting to be answered correctly.
  int get remaining => _queue.length;

  /// Questions the player got wrong at least once, in order.
  List<Question> get missed => List.unmodifiable(_missed);

  PlayQuestion _prepare(Question q) {
    final order = List<int>.generate(q.options.length, (i) => i)
      ..shuffle(_random);
    return PlayQuestion(
      q,
      [for (final i in order) q.options[i]],
      order.indexOf(q.answer),
    );
  }

  AnswerResult answer(int choice) {
    final q = current;
    if (q == null) throw StateError('The session is already over.');
    if (choice < 0 || choice >= q.options.length) {
      throw RangeError.range(choice, 0, q.options.length - 1, 'choice');
    }
    _queue.removeAt(0);
    final correct = choice == q.correctIndex;
    final alreadyMissed = _missed.any((m) => m.id == q.source.id);
    if (correct) {
      solved++;
      if (!alreadyMissed) firstTryCorrect++;
    } else {
      lives--;
      if (!alreadyMissed) _missed.add(q.source);
      if (requeueWrong) _queue.add(_prepare(q.source));
    }
    final result = AnswerResult(question: q, chosenIndex: choice, correct: correct);
    history.add(result);
    return result;
  }
}
