import 'package:flutter/material.dart';

/// The four programming languages, each shown as a game "world".
enum Lang {
  python('Python', 'Python Jungle', '🐍', Color(0xFF2FD38A), 'main.py',
      'A friendly jungle where code reads almost like English.'),
  c('C', 'C Caves', '💎', Color(0xFF5BC0FF), 'main.c',
      'Deep crystal caves where you learn how computers really work.'),
  cpp('C++', 'C++ Castle', '🏰', Color(0xFFB98CFF), 'main.cpp',
      'A starry castle of classes, objects and super-fast code.'),
  java('Java', 'Java Volcano', '🌋', Color(0xFFFF8A4C), 'Main.java',
      'A rumbling volcano powered by classes and methods.');

  const Lang(this.label, this.worldName, this.emoji, this.color, this.fileName, this.tagline);

  final String label;
  final String worldName;
  final String emoji;

  /// Bright accent colour of the world (used for buttons and level nodes).
  final Color color;

  /// File name shown in the puzzle code editor.
  final String fileName;
  final String tagline;
}

/// The three mini-game styles.
enum LevelKind {
  builder(
    'World Builder',
    Icons.construction_rounded,
    'Byte is stuck! Each challenge is a tiny program with one blank. Fill the blank, '
        'press Run code and watch your code change the world: loops build bridges and '
        'stairs, variables set the jump, printing says the password. Wrong code plays out '
        'too, so you can see the bug, fix it and try again. No timer - take your time.',
  ),
  battle(
    'Bug Battle',
    Icons.bug_report_rounded,
    'A bug monster attacks! Pick the right move (keys 1-4) to hit it. Answer '
        'correctly in a row to build a combo. Missed questions come back, so you can still win.',
  ),
  puzzle(
    'Block Builder',
    Icons.extension_rounded,
    'Tap the code blocks in the right order to build the program, then press '
        'Run code to see what it prints.',
  );

  const LevelKind(this.label, this.icon, this.howToPlay);

  final String label;
  final IconData icon;
  final String howToPlay;
}

/// A multiple-choice question used by the battle game.
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
    required this.output,
    this.input,
  });

  final String id;
  final String goal;

  /// The program, line by line, in the correct order.
  final List<String> lines;
  final String explanation;

  /// What the finished program prints - shown in the game console.
  final String output;

  /// What the user types while the program runs, if anything.
  final String? input;
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
