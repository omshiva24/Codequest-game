import 'dart:math';

import 'package:codequest/logic/puzzle_session.dart';
import 'package:codequest/logic/quiz_session.dart';
import 'package:codequest/logic/scoring.dart';
import 'package:codequest/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _questions = [
  Question(id: 'a', prompt: 'A?', options: ['right', 'w1', 'w2'], answer: 0, explanation: 'e'),
  Question(id: 'b', prompt: 'B?', options: ['w1', 'right', 'w2'], answer: 1, explanation: 'e'),
  Question(id: 'c', prompt: 'C?', options: ['w1', 'w2', 'right'], answer: 2, explanation: 'e'),
];

int _wrongIndex(PlayQuestion q) => q.correctIndex == 0 ? 1 : 0;

void main() {
  group('QuizSession', () {
    test('shuffling keeps track of the right answer', () {
      for (var seed = 0; seed < 20; seed++) {
        final s = QuizSession(_questions, random: Random(seed));
        while (!s.isOver) {
          expect(s.current!.correctText, 'right');
          expect(s.answer(s.current!.correctIndex).correct, isTrue);
        }
        expect(s.won, isTrue);
        expect(s.firstTryCorrect, 3);
      }
    });

    test('wrong answers cost a heart and are remembered for review', () {
      final s = QuizSession(_questions, random: Random(1));
      final r = s.answer(_wrongIndex(s.current!));
      expect(r.correct, isFalse);
      expect(s.lives, 2);
      expect(s.missed.single.id, 'a');
    });

    test('runner mode: running out of hearts ends the game', () {
      final s = QuizSession(_questions, random: Random(2), maxLives: 2);
      s.answer(_wrongIndex(s.current!));
      s.answer(_wrongIndex(s.current!));
      expect(s.isOver, isTrue);
      expect(s.won, isFalse);
      expect(() => s.answer(0), throwsStateError);
    });

    test('battle mode re-queues missed questions', () {
      final s = QuizSession(_questions, random: Random(3), requeueWrong: true);
      s.answer(_wrongIndex(s.current!)); // miss "a"
      expect(s.remaining, 3);
      while (!s.isOver) {
        s.answer(s.current!.correctIndex);
      }
      expect(s.won, isTrue);
      expect(s.solved, 3);
      expect(s.firstTryCorrect, 2, reason: '"a" was not right first time');
    });

    test('rejects out-of-range choices', () {
      final s = QuizSession(_questions);
      expect(() => s.answer(-1), throwsRangeError);
      expect(() => s.answer(3), throwsRangeError);
    });
  });

  group('PuzzleSession', () {
    const puzzle = PuzzleSpec(
      id: 'p',
      goal: 'g',
      lines: ['one', 'two', 'three', 'four'],
      explanation: 'x',
    );

    test('starts shuffled into a different order', () {
      for (var seed = 0; seed < 20; seed++) {
        final s = PuzzleSession(const [puzzle], random: Random(seed));
        expect(s.pool.map((t) => t.text).toList(), isNot(puzzle.lines));
        expect(s.pool.map((t) => t.text).toSet(), puzzle.lines.toSet());
      }
    });

    test('placing in the right order solves it', () {
      final s = PuzzleSession(const [puzzle], random: Random(4));
      for (final line in puzzle.lines) {
        s.place(s.pool.firstWhere((t) => t.text == line).id);
      }
      expect(s.readyToCheck, isTrue);
      final check = s.check();
      expect(check.solved, isTrue);
      expect(check.lineCorrect, everyElement(isTrue));
      expect(s.won, isTrue);
      expect(puzzleStars(mistakes: s.mistakes, won: s.won), 3);
    });

    test('a wrong order costs a heart and marks the wrong lines', () {
      final s = PuzzleSession(const [puzzle], random: Random(5));
      for (final line in puzzle.lines.reversed) {
        s.place(s.pool.firstWhere((t) => t.text == line).id);
      }
      final check = s.check();
      expect(check.solved, isFalse);
      expect(check.lineCorrect, [false, false, false, false]);
      expect(s.lives, 2);
      expect(s.mistakes, 1);
    });

    test('unplace, clear and hint', () {
      final s = PuzzleSession(const [puzzle], random: Random(6));
      final first = s.pool.first.id;
      s.place(first);
      s.unplace(first);
      expect(s.placed, isEmpty);
      s.place(s.pool.firstWhere((t) => t.text == 'three').id);
      s.hint();
      expect(s.placed.map((t) => t.text), ['one']);
      expect(s.hintsUsed, 1);
      s.clear();
      expect(s.placed, isEmpty);
      expect(s.pool, hasLength(4));
    });

    test('moves to the next puzzle only after solving', () {
      final s = PuzzleSession(const [puzzle, puzzle], random: Random(7));
      s.nextPuzzle();
      expect(s.index, 0);
      for (final line in puzzle.lines) {
        s.place(s.pool.firstWhere((t) => t.text == line).id);
      }
      s.check();
      s.nextPuzzle();
      expect(s.index, 1);
      expect(s.placed, isEmpty);
      expect(s.finished, isFalse);
    });
  });

  group('Scoring', () {
    test('quiz stars', () {
      expect(quizStars(firstTryCorrect: 5, total: 5, won: true), 3);
      expect(quizStars(firstTryCorrect: 4, total: 5, won: true), 2);
      expect(quizStars(firstTryCorrect: 2, total: 5, won: true), 1);
      expect(quizStars(firstTryCorrect: 5, total: 5, won: false), 0);
      expect(quizStars(firstTryCorrect: 0, total: 0, won: true), 0);
    });

    test('puzzle stars', () {
      expect(puzzleStars(mistakes: 0, won: true), 3);
      expect(puzzleStars(mistakes: 2, won: true), 2);
      expect(puzzleStars(mistakes: 5, won: true), 1);
      expect(puzzleStars(mistakes: 0, won: false), 0);
    });

    test('xp, coins and player level', () {
      expect(xpFor(correct: 5, stars: 3, isBoss: false), 80);
      expect(xpFor(correct: 5, stars: 3, isBoss: true), 110);
      expect(xpFor(correct: -4, stars: 9, isBoss: false), 30);
      expect(coinsFor(correct: 2, stars: 1), 15);
      expect(playerLevelFor(0), 1);
      expect(playerLevelFor(150), 2);
      expect(levelProgressFor(75), 0.5);
      expect(rankTitleFor(1), 'Newbie Coder');
      expect(rankTitleFor(12), 'Code Wizard');
    });
  });
}
