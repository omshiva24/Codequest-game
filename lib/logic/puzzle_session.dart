import 'dart:math';

import '../models/models.dart';

/// One movable code block. [id] keeps identical lines apart.
class PuzzleToken {
  const PuzzleToken(this.id, this.text);

  final int id;
  final String text;
}

class PuzzleCheck {
  const PuzzleCheck({required this.solved, required this.lineCorrect});

  final bool solved;

  /// For each placed line: is it in the right position?
  final List<bool> lineCorrect;
}

/// Rules for the "Block Builder" puzzle game.
class PuzzleSession {
  PuzzleSession(this.puzzles, {Random? random, this.maxLives = 3})
      : assert(puzzles.isNotEmpty, 'A session needs at least one puzzle'),
        _random = random ?? Random() {
    lives = maxLives;
    _setUp();
  }

  final List<PuzzleSpec> puzzles;
  final int maxLives;
  final Random _random;

  late int lives;
  int index = 0;
  int mistakes = 0;
  int hintsUsed = 0;
  int solvedCount = 0;
  bool currentSolved = false;

  final List<PuzzleToken> pool = [];
  final List<PuzzleToken> placed = [];

  PuzzleSpec get current => puzzles[index.clamp(0, puzzles.length - 1)];
  bool get finished => solvedCount >= puzzles.length;
  bool get won => finished && lives > 0;
  bool get isOver => lives <= 0 || finished;
  bool get readyToCheck => pool.isEmpty && placed.isNotEmpty;

  void _setUp() {
    pool.clear();
    placed.clear();
    currentSolved = false;
    final lines = current.lines;
    final tokens = [
      for (var i = 0; i < lines.length; i++) PuzzleToken(i, lines[i]),
    ];
    // Shuffle until the order is actually different (when that is possible).
    final allSame = lines.toSet().length <= 1;
    for (var attempt = 0; attempt < 20; attempt++) {
      tokens.shuffle(_random);
      if (allSame || !_inCorrectOrder(tokens)) break;
    }
    pool.addAll(tokens);
  }

  bool _inCorrectOrder(List<PuzzleToken> tokens) {
    final lines = current.lines;
    if (tokens.length != lines.length) return false;
    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i].text != lines[i]) return false;
    }
    return true;
  }

  void place(int tokenId) {
    if (currentSolved) return;
    final i = pool.indexWhere((t) => t.id == tokenId);
    if (i < 0) return;
    placed.add(pool.removeAt(i));
  }

  void unplace(int tokenId) {
    if (currentSolved) return;
    final i = placed.indexWhere((t) => t.id == tokenId);
    if (i < 0) return;
    pool.add(placed.removeAt(i));
  }

  void clear() {
    if (currentSolved) return;
    pool.addAll(placed);
    placed.clear();
  }

  /// Checks the placed blocks. A wrong answer costs one heart.
  PuzzleCheck check() {
    if (isOver) throw StateError('The session is already over.');
    final lines = current.lines;
    final lineCorrect = [
      for (var i = 0; i < placed.length; i++)
        i < lines.length && placed[i].text == lines[i],
    ];
    final solved = pool.isEmpty &&
        placed.length == lines.length &&
        lineCorrect.every((ok) => ok);
    if (solved) {
      currentSolved = true;
      solvedCount++;
    } else {
      lives--;
      mistakes++;
    }
    return PuzzleCheck(solved: solved, lineCorrect: lineCorrect);
  }

  /// Fixes the first wrong block and places the next correct one.
  /// Costs no heart, but counts as a mistake for stars.
  void hint() {
    if (currentSolved || isOver) return;
    final lines = current.lines;
    var firstWrong = 0;
    while (firstWrong < placed.length &&
        firstWrong < lines.length &&
        placed[firstWrong].text == lines[firstWrong]) {
      firstWrong++;
    }
    // Send every block after the first wrong one back to the pool.
    while (placed.length > firstWrong) {
      pool.add(placed.removeLast());
    }
    if (firstWrong < lines.length) {
      final want = lines[firstWrong];
      final i = pool.indexWhere((t) => t.text == want);
      if (i >= 0) placed.add(pool.removeAt(i));
    }
    hintsUsed++;
    mistakes++;
  }

  /// Moves on after a solved puzzle.
  void nextPuzzle() {
    if (!currentSolved) return;
    if (index + 1 < puzzles.length) {
      index++;
      _setUp();
    }
  }
}
