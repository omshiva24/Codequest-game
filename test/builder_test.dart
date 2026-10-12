import 'dart:ui';

import 'package:codequest/data/builder_levels.dart';
import 'package:codequest/data/curriculum.dart';
import 'package:codequest/logic/builder.dart';
import 'package:codequest/models/models.dart';
import 'package:codequest/widgets/builder_stage.dart';
import 'package:flutter_test/flutter_test.dart';

List<BuildChallenge> get _all => [
      for (final level in allLevels.where((l) => l.kind == LevelKind.builder)) ...builderChallenges(level.id),
    ];

void main() {
  group('World Builder content', () {
    test('levels 1 and 4 of every world are World Builder levels with 4 challenges', () {
      for (final lang in Lang.values) {
        final levels = levelsFor(lang);
        expect(levels[0].kind, LevelKind.builder, reason: lang.label);
        expect(levels[3].kind, LevelKind.builder, reason: lang.label);
      }
      for (final level in allLevels.where((l) => l.kind == LevelKind.builder)) {
        final challenges = builderChallenges(level.id);
        expect(challenges, hasLength(4), reason: level.id);
        expect(challenges.every((c) => c.lang == level.lang), isTrue, reason: level.id);
      }
      expect(builderChallenges('py-2'), isEmpty);
    });

    test('every challenge has exactly one right answer and starts on a wrong one', () {
      final ids = <String>{};
      for (final c in _all) {
        expect(ids.add(c.id), isTrue, reason: 'duplicate ${c.id}');
        expect(c.lines.where((l) => l.contains(blank)), hasLength(1), reason: c.id);
        expect(c.options.toSet(), hasLength(c.options.length), reason: '${c.id} repeats an option');
        final wins = [for (var i = 0; i < c.options.length; i++) if (c.run(i).success) i];
        expect(wins, hasLength(1), reason: '${c.id} must have exactly one right answer, has $wins');
        expect(c.answer, wins.single);
        expect(c.run(c.initial).success, isFalse, reason: '${c.id} must start on a wrong value');
        expect(c.goal, isNotEmpty);
        expect(c.hint, isNotEmpty);
        expect(c.lesson, isNotEmpty);
      }
    });

    test('every run explains itself and only points at real lines', () {
      for (final c in _all) {
        for (var i = 0; i < c.options.length; i++) {
          final run = c.run(i);
          expect(run.steps, isNotEmpty, reason: '${c.id} option $i');
          expect(run.message.length, greaterThan(20), reason: '${c.id} option $i');
          for (final step in run.steps) {
            expect(step.line, inInclusiveRange(0, c.lines.length - 1), reason: '${c.id} option $i');
          }
        }
      }
    });

    test('sizes fit the 14 x 7 tile stage', () {
      for (final c in _all) {
        switch (c.obstacle) {
          case Obstacle.gap:
            expect(c.size, inInclusiveRange(2, 6), reason: c.id);
          case Obstacle.ledge:
            expect(c.size, inInclusiveRange(1, 3), reason: '${c.id}: room for the spiky ceiling');
          case Obstacle.stairs:
            expect(c.size, inInclusiveRange(1, 4), reason: c.id);
          case Obstacle.guard:
            expect(c.password, isNotNull, reason: c.id);
          case Obstacle.toll:
            expect(c.size % 4, 0, reason: '${c.id}: 4 rounds must reach the toll exactly');
        }
      }
    });
  });

  group('Real syntax for each language', () {
    String code(BuildChallenge c) => c.codeWith(c.answer);

    test('loops', () {
      expect(code(builderChallenges('py-4').first), 'for i in range(4):\n    hero.build_block()');
      expect(code(builderChallenges('c-4').first), 'for (int i = 0; i < 5; i++) {\n    build_block();\n}');
      expect(code(builderChallenges('cpp-4').first), 'for (int i = 0; i < 3; i++) {\n    hero.buildBlock();\n}');
      expect(code(builderChallenges('java-4').first), 'for (int i = 0; i < 6; i++) {\n    hero.buildBlock();\n}');
    });

    test('printing a string', () {
      expect(code(builderChallenges('py-1').first), 'print("HELLO")');
      expect(code(builderChallenges('c-1').first), 'printf("OPEN");');
      expect(code(builderChallenges('cpp-1').first), 'cout << "CASTLE";');
      expect(code(builderChallenges('java-1').first), 'System.out.println("LAVA");');
    });

    test('variables: snake_case in Python and C, camelCase in C++ and Java', () {
      expect(code(builderChallenges('py-1')[1]), 'jump_height = 2\nhero.jump(jump_height)');
      expect(code(builderChallenges('c-1')[1]), 'int jump_height = 3;\njump(jump_height);');
      expect(code(builderChallenges('java-1')[1]), 'int jumpHeight = 3;\nhero.jump(jumpHeight);');
      expect(code(builderChallenges('cpp-4')[1]),
          'int steps = 0;\nwhile (steps < 3) {\n    hero.buildStep();\n    steps++;\n}');
    });
  });

  group('Simulation', () {
    test('a counting loop builds one block per round', () {
      final c = loopBridgeChallenge(id: 't', lang: Lang.python, gap: 4, form: LoopForm.count, initial: 0);
      BuildRun runWith(String v) => c.run(c.options.indexOf(v));
      expect(runWith('4').outcome, BuildOutcome.cross);
      expect(runWith('4').steps.where((s) => s.effect == StepEffect.block), hasLength(4));
      expect(runWith('3').outcome, BuildOutcome.fall);
      expect(runWith('3').amount, 3);
      expect(runWith('6').outcome, BuildOutcome.trip);
      expect(runWith('6').message, contains('only 4 wide'));
    });

    test('off by one: range(1, n) and starting at 1 run one round fewer', () {
      final py = loopBridgeChallenge(id: 't', lang: Lang.python, gap: 4, form: LoopForm.fromOne, initial: 0);
      expect(py.run(py.options.indexOf('5')).amount, 4);
      expect(py.run(py.options.indexOf('4')).message, contains('range(1, 4) counts 1 to 3'));
      final c = loopBridgeChallenge(id: 't', lang: Lang.c, gap: 4, form: LoopForm.fromOne, initial: 0);
      expect(c.lines.first, 'for (int i = 1; i < {?}; i++) {');
      expect(c.run(c.options.indexOf('5')).success, isTrue);
    });

    test('< and <= differ by exactly one round, > never runs', () {
      for (final lang in Lang.values) {
        final c = loopBridgeChallenge(id: 't', lang: lang, gap: 5, form: LoopForm.compare, initial: 0);
        BuildRun runWith(String op) => c.run(c.options.indexOf(op));
        expect(runWith('<').amount, 4, reason: lang.label);
        expect(runWith('<=').amount, 5, reason: lang.label);
        expect(runWith('<=').success, isTrue, reason: lang.label);
        expect(runWith('>').amount, 0, reason: lang.label);
        expect(runWith('>').steps.last.note, contains('never runs'));
      }
      // Python writes it as a while loop with a counter.
      final py = loopBridgeChallenge(id: 't', lang: Lang.python, gap: 5, form: LoopForm.compare, initial: 0);
      expect(py.lines, ['i = 0', 'while i {?} 4:', '    hero.build_block()', '    i += 1']);
    });

    test('stairs: a while loop with a counter', () {
      final c = stairsChallenge(id: 't', lang: Lang.java, height: 3, initial: 0);
      expect(c.run(c.options.indexOf('3')).outcome, BuildOutcome.cross);
      expect(c.run(c.options.indexOf('2')).outcome, BuildOutcome.short);
      expect(c.run(c.options.indexOf('5')).outcome, BuildOutcome.trip);
      final steps = c.run(c.options.indexOf('3')).steps;
      expect(steps.first.note, 'steps = 0');
      expect(steps.last.note, '3 < 3 is false, stop');
    });

    test('toll: a running total over 4 rounds', () {
      final c = tollChallenge(id: 't', lang: Lang.c, toll: 12, initial: 0);
      final ok = c.run(c.options.indexOf('3'));
      expect(ok.outcome, BuildOutcome.cross);
      expect([for (final s in ok.steps) if (s.effect == StepEffect.coins) s.value], [3, 6, 9, 12]);
      expect(ok.steps.last.effect, StepEffect.pay);
      expect(c.lines.last, 'pay(coins);');
      final wrong = c.run(c.options.indexOf('2'));
      expect(wrong.outcome, BuildOutcome.blocked);
      expect(wrong.message, contains('= 8 coins, but the toll is 12'));
    });

    test('jump height from a variable, with plus and minus', () {
      final direct = jumpChallenge(id: 't', lang: Lang.cpp, height: 2, form: JumpForm.direct, initial: 0);
      expect(direct.run(direct.options.indexOf('2')).outcome, BuildOutcome.land);
      expect(direct.run(direct.options.indexOf('1')).outcome, BuildOutcome.short);
      expect(direct.run(direct.options.indexOf('4')).outcome, BuildOutcome.bonkCeiling);
      final plus = jumpChallenge(id: 't', lang: Lang.c, height: 3, form: JumpForm.plus, initial: 0);
      expect(plus.run(plus.options.indexOf('2')).steps.first.note, 'jump_height = 1 + 2 = 3');
      final minus = jumpChallenge(id: 't', lang: Lang.python, height: 3, form: JumpForm.minus, initial: 0);
      expect(minus.run(minus.options.indexOf('4')).success, isTrue);
    });

    test('bridge size from arithmetic', () {
      final c = bridgeChallenge(id: 't', lang: Lang.java, gap: 6, form: BridgeForm.times, initial: 0);
      final run = c.run(c.options.indexOf('3'));
      expect(run.success, isTrue);
      expect(run.steps.first.note, 'planks = 3 * 2 = 6');
      expect(c.lines.last, 'hero.buildBridge(planks);');
    });

    test('strings: quotes and exact text', () {
      final py = guardChallenge(
        id: 't',
        lang: Lang.python,
        password: 'HELLO',
        options: const ['HELLO', '"HELLO"', "'HELLO'", '"hello"'],
        initial: 0,
      );
      BuildRun runWith(String o) => py.run(py.options.indexOf(o));
      expect(runWith('"HELLO"').success, isTrue);
      expect(runWith("'HELLO'").success, isTrue, reason: 'Python strings can use single quotes');
      expect(runWith('HELLO').outcome, BuildOutcome.error);
      expect(runWith('HELLO').message, contains("NameError: name 'HELLO' is not defined"));
      expect(runWith('"hello"').outcome, BuildOutcome.blocked);
      expect(runWith('"hello"').message, contains('capital letters count'));

      final java = guardChallenge(
        id: 't',
        lang: Lang.java,
        password: 'LAVA',
        options: const ["'LAVA'", '"LAVA"', 'LAVA'],
        initial: 0,
      );
      final single = java.run(0);
      expect(single.outcome, BuildOutcome.error, reason: 'single quotes are one char in Java');
      expect(single.message, contains('one character'));
      expect(java.run(2).message, contains('cannot find symbol LAVA'));
      expect(java.run(1).said, 'LAVA');
    });
  });

  group('BuilderSession', () {
    test('hearts, retries, first-try count and the review list', () {
      final s = BuilderSession(builderChallenges('py-4'));
      expect(s.choice, s.current.initial);
      final first = s.run();
      expect(first.success, isFalse);
      expect(s.lives, 2);
      expect(s.mistakes, 1);
      expect(s.missed.single.id, 'py-4-loop');
      s.retry();
      expect(s.lastRun, isNull);
      s.select(s.current.answer);
      expect(s.run().success, isTrue);
      expect(s.solvedFirstTry, 0, reason: 'the first challenge needed two tries');
      s.select(0); // ignored once solved
      expect(s.choice, s.current.answer);
      s.next();
      expect(s.index, 1);
      expect(s.choice, s.current.initial);
      while (!s.finished) {
        s.select(s.current.answer);
        s.run();
        s.next();
      }
      expect(s.won, isTrue);
      expect(s.solved, 4);
      expect(s.solvedFirstTry, 3);
      expect(() => s.run(), throwsStateError);
    });

    test('three wrong runs end the level', () {
      final s = BuilderSession(builderChallenges('java-1'));
      for (var i = 0; i < 3; i++) {
        s.run();
        s.retry();
      }
      expect(s.isOver, isTrue);
      expect(s.won, isFalse);
      expect(s.missed, hasLength(1));
    });
  });

  group('Stage animation', () {
    test('Byte has a sensible pose for every outcome at every moment', () {
      final geo = StageGeometry(const Size(700, 350));
      for (final c in _all) {
        for (var i = 0; i < c.options.length; i++) {
          final run = c.run(i);
          for (var a = 0.0; a <= 1.0; a += 0.1) {
            final scene = StageScene(
              lang: c.lang,
              obstacle: c.obstacle,
              size: c.size,
              built: run.amount,
              outcome: run.outcome,
              act: a,
              jump: run.amount,
            );
            final pose = heroPoseFor(scene, geo);
            expect(pose.x.isFinite && pose.y.isFinite, isTrue, reason: '${c.id} option $i at $a');
            expect(pose.y, lessThan(geo.height * 2), reason: '${c.id} option $i at $a');
          }
        }
      }
    });

    test('after a success Byte stays on screen and celebrates', () {
      for (final aspect in [BuilderStage.minAspect, BuilderStage.defaultAspect, BuilderStage.maxAspect]) {
        final geo = StageGeometry(Size(700, 700 / aspect));
        for (final c in _all) {
          final right = c.run(c.answer);
          expect(right.success, isTrue, reason: c.id);
          final scene = StageScene(
            lang: c.lang,
            obstacle: c.obstacle,
            size: c.size,
            built: right.amount,
            outcome: right.outcome,
            act: 1,
            jump: right.amount,
          );
          final pose = heroPoseFor(scene, geo);
          expect(pose.visible, isTrue, reason: c.id);
          expect(pose.x, inExclusiveRange(geo.tile, geo.width - geo.tile), reason: '${c.id} ends off screen');
        }
      }
    });

    test('a correct jump never touches the ceiling spikes', () {
      for (final aspect in [BuilderStage.minAspect, BuilderStage.defaultAspect, BuilderStage.maxAspect]) {
        final geo = StageGeometry(Size(700, 700 / aspect));
        for (final c in _all.where((c) => c.obstacle == Obstacle.ledge)) {
          final right = c.run(c.answer);
          final spikeTips = geo.ceilingBottom(c.size) + geo.tile * 0.32;
          expect(geo.ceilingBottom(c.size), greaterThan(0), reason: '${c.id}: ceiling must be on screen');
          for (var a = 0.0; a <= 1.0; a += 0.02) {
            final pose = heroPoseFor(
              StageScene(
                lang: c.lang,
                obstacle: c.obstacle,
                size: c.size,
                built: right.amount,
                outcome: right.outcome,
                act: a,
                jump: right.amount,
              ),
              geo,
            );
            final headTop = pose.y - geo.tile * StageGeometry.heroHeight;
            expect(headTop, greaterThan(spikeTips), reason: '${c.id} at $a (aspect $aspect)');
          }
        }
      }
    });

    test('walking in, then standing at the start', () {
      final geo = StageGeometry(const Size(700, 350));
      const s = StageScene(lang: Lang.c, obstacle: Obstacle.gap, size: 4, enter: 0.5);
      expect(heroPoseFor(s, geo).action, HeroAction.walk);
      const idle = StageScene(lang: Lang.c, obstacle: Obstacle.gap, size: 4);
      expect(heroPoseFor(idle, geo).x, closeTo(geo.x(2.4), 0.01));
    });
  });
}
