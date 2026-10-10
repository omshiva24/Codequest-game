import 'package:flutter/material.dart';

/// The four programming languages, each shown as a game "world".
enum Lang {
  python('Python', 'Python Jungle', '🐍', Color(0xFF2ECC71), 'A friendly jungle where code reads almost like English.'),
  c('C', 'C Caves', '⛏️', Color(0xFF4FA3FF), 'Deep caves where you learn how computers really work.'),
  cpp('C++', 'C++ Castle', '🏰', Color(0xFFC08BFF), 'A castle of classes, objects and super-fast code.'),
  java('Java', 'Java Volcano', '🌋', Color(0xFFFF8A3D), 'A hot volcano powered by classes and methods.');

  const Lang(this.label, this.worldName, this.emoji, this.color, this.tagline);

  final String label;
  final String worldName;
  final String emoji;
  final Color color;
  final String tagline;
}

/// The three mini-game styles.
enum LevelKind {
  runner(
    'Code Runner',
    Icons.directions_run_rounded,
    'Switch lanes and run through the gate with the right answer. '
        'Use the lane buttons, arrow keys, or keys 1-3. Press Space or "Go" to dash early.',
  ),
  battle(
    'Bug Battle',
    Icons.bug_report_rounded,
    'A bug monster attacks! Pick the right move (keys 1-4) to hit it. '
        'Wrong answers come back later so you can try again.',
  ),
  puzzle(
    'Block Builder',
    Icons.extension_rounded,
    'Tap the code blocks in the right order to build a working program, then press Check.',
  );

  const LevelKind(this.label, this.icon, this.howToPlay);

  final String label;
  final IconData icon;
  final String howToPlay;
}

/// A multiple-choice question used by the runner and battle games.
@immutable
class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.answer,
    required this.explanation,
    this.code,
  });

  final String id;
  final String prompt;
  final String? code;
  final List<String> options;

  /// Index into [options] of the correct answer.
  final int answer;

  /// Shown after answering, in simple words.
  final String explanation;

  String get correctText => options[answer];
}

/// A "put the lines in order" challenge used by the puzzle game.
@immutable
class PuzzleSpec {
  const PuzzleSpec({
    required this.id,
    required this.goal,
    required this.lines,
    required this.explanation,
  });

  final String id;
  final String goal;

  /// The program, line by line, in the correct order.
  final List<String> lines;
  final String explanation;
}

/// The short lesson shown before each level.
@immutable
class Lesson {
  const Lesson({
    required this.title,
    required this.story,
    required this.code,
    required this.keyPoints,
  });

  final String title;

  /// Explanation in simple, friendly words.
  final String story;
  final String code;
  final List<String> keyPoints;
}

@immutable
class Enemy {
  const Enemy(this.name, this.emoji);

  final String name;
  final String emoji;
}

@immutable
class Level {
  const Level({
    required this.id,
    required this.lang,
    required this.number,
    required this.title,
    required this.kind,
    required this.lesson,
    this.questions = const [],
    this.puzzles = const [],
    this.enemy,
    this.isBoss = false,
  });

  final String id;
  final Lang lang;

  /// 1-based position inside its world.
  final int number;
  final String title;
  final LevelKind kind;
  final Lesson lesson;
  final List<Question> questions;
  final List<PuzzleSpec> puzzles;
  final Enemy? enemy;
  final bool isBoss;
}
