// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:codequest/data/curriculum.dart';
import 'package:codequest/data/doubt_kb.dart';
import 'package:codequest/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Curriculum content', () {
    test('every language world has 5 levels numbered 1-5', () {
      for (final lang in Lang.values) {
        final levels = levelsFor(lang);
        expect(levels, hasLength(5), reason: lang.label);
        for (var i = 0; i < levels.length; i++) {
          expect(levels[i].number, i + 1);
          expect(levels[i].lang, lang);
        }
        expect(levels.last.isBoss, isTrue, reason: 'Level 5 of ${lang.label} is a boss');
      }
    });

    test('ids are unique across levels, questions and puzzles', () {
      final ids = <String>{};
      for (final level in allLevels) {
        expect(ids.add(level.id), isTrue, reason: 'duplicate ${level.id}');
        for (final q in level.questions) {
          expect(ids.add(q.id), isTrue, reason: 'duplicate ${q.id}');
        }
        for (final p in level.puzzles) {
          expect(ids.add(p.id), isTrue, reason: 'duplicate ${p.id}');
        }
      }
    });

    test('quiz questions are well formed', () {
      for (final level in allLevels) {
        if (level.kind != LevelKind.battle) {
          expect(level.questions, isEmpty, reason: '${level.id} does not use quiz questions');
          continue;
        }
        expect(level.questions.length, greaterThanOrEqualTo(4), reason: level.id);
        for (final q in level.questions) {
          expect(q.options, hasLength(4), reason: q.id);
          expect(q.options.toSet(), hasLength(q.options.length), reason: '${q.id} has duplicate options');
          expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.id);
          expect(q.prompt.trim(), isNotEmpty);
          expect(q.explanation.trim(), isNotEmpty);
        }
      }
    });

    test('battle levels have an enemy and puzzles have lines', () {
      for (final level in allLevels) {
        if (level.kind == LevelKind.battle) expect(level.enemy, isNotNull, reason: level.id);
        if (level.kind == LevelKind.puzzle) {
          expect(level.puzzles, isNotEmpty, reason: level.id);
          for (final p in level.puzzles) {
            expect(p.lines.length, greaterThanOrEqualTo(3), reason: p.id);
          }
        }
        expect(level.lesson.keyPoints, isNotEmpty);
        expect(level.lesson.code.trim(), isNotEmpty);
      }
    });

    test('levelById and nextLevel', () {
      expect(levelById('py-1')?.title, 'Hello, Python!');
      expect(levelById('nope'), isNull);
      expect(nextLevel(levelById('c-1')!)?.id, 'c-2');
      expect(nextLevel(levelById('java-5')!), isNull);
    });

    test('knowledge base entries are complete and unique', () {
      final ids = doubtKb.map((e) => e.id).toSet();
      expect(ids, hasLength(doubtKb.length));
      for (final e in doubtKb) {
        expect(e.keywords, isNotEmpty, reason: e.id);
        for (final k in e.keywords) {
          expect(k, k.toLowerCase(), reason: 'keywords must be lower case (${e.id})');
        }
        expect(e.answer.length, greaterThan(40), reason: e.id);
      }
    });
  });
}
