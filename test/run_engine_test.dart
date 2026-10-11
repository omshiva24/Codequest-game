import 'dart:math';

import 'package:codequest/data/curriculum.dart';
import 'package:codequest/logic/quiz_session.dart';
import 'package:codequest/logic/run_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'run_autopilot.dart';

const _step = 1 / 60;

RunEngine _engine({int seed = 1, RunConfig config = RunConfig.normal, String level = 'py-1'}) {
  final session = QuizSession(levelById(level)!.questions, random: Random(seed));
  return RunEngine(session: session, config: config, random: Random(seed));
}

/// An engine whose track is replaced by [items] (sorted by position).
RunEngine _custom(List<RunItem> items) {
  final e = _engine();
  e.items
    ..clear()
    ..addAll(items..sort((a, b) => a.pos.compareTo(b.pos)));
  return e;
}

/// Runs until [distance] metres (or [seconds]) and returns all events.
List<RunEvent> _runTo(RunEngine e, double distance, {double seconds = 60, void Function(RunEngine)? each}) {
  final events = <RunEvent>[];
  var t = 0.0;
  while (e.distance < distance && t < seconds && !e.over) {
    each?.call(e);
    events.addAll(e.update(_step));
    t += _step;
  }
  return events;
}

void main() {
  group('track building', () {
    for (final config in [RunConfig.normal, RunConfig.relaxed]) {
      test('every track has one gate per question, quiet zones and a way through '
          '(${config == RunConfig.normal ? 'normal' : 'relaxed'})', () {
        for (var seed = 0; seed < 40; seed++) {
          final e = _engine(seed: seed, config: config);
          final gates = e.items.where((i) => i.kind == RunItemKind.gate).toList();
          expect(gates, hasLength(e.session.total));
          expect(gates.first.pos, RunEngine.firstGateAt);
          expect(e.items.last.kind, RunItemKind.finish);
          expect(e.finishPos, greaterThan(gates.last.pos));

          final obstacles = e.items.where((i) =>
              i.kind == RunItemKind.hurdle || i.kind == RunItemKind.overhead || i.kind == RunItemKind.block);
          for (final o in obstacles) {
            expect(o.pos, greaterThan(RunEngine.firstGateAt), reason: 'warm-up must be obstacle-free');
            for (final g in gates) {
              final before = g.pos - o.pos;
              expect(before < 0 || before > RunEngine.clearBeforeGate, isTrue, reason: 'obstacle too close before a gate');
            }
            // Never three blocks in one row.
            final blocks = e.items.where((b) => b.kind == RunItemKind.block && (b.pos - o.pos).abs() < 0.01);
            expect(blocks.length, lessThan(RunEngine.laneCount));
          }
          if (config == RunConfig.relaxed) {
            final rows = obstacles.map((o) => o.pos.toStringAsFixed(2)).toSet();
            expect(rows.length, lessThanOrEqualTo((e.session.total - 1) * config.maxObstaclesPerStretch));
          }
        }
      });
    }

    test('items are sorted by position', () {
      final e = _engine(seed: 3);
      for (var i = 1; i < e.items.length; i++) {
        expect(e.items[i].pos, greaterThanOrEqualTo(e.items[i - 1].pos));
      }
    });
  });

  group('running', () {
    test('moves forward and speeds up, but never past the top speed', () {
      final e = _custom([]);
      e.update(0.04);
      final early = e.speed;
      _runTo(e, 1e9, seconds: 120);
      expect(e.distance, greaterThan(100));
      expect(e.speed, greaterThan(early));
      expect(e.speed, lessThanOrEqualTo(RunConfig.normal.maxSpeed + 1e-9));
    });

    test('a huge frame gap is clamped (no teleporting through obstacles)', () {
      final e = _custom([]);
      e.update(5);
      expect(e.distance, lessThan(1));
    });

    test('coins are collected only in your lane', () {
      final e = _custom([
        RunItem(RunItemKind.coin, 10, lane: 1),
        RunItem(RunItemKind.coin, 12, lane: 0),
        RunItem(RunItemKind.coin, 14, lane: 1),
      ]);
      final events = _runTo(e, 20);
      expect(events.whereType<CoinPicked>(), hasLength(2));
      expect(e.coins, 2);
    });

    test('coins high in the air need a jump', () {
      final e = _custom([RunItem(RunItemKind.coin, 10, lane: 1, height: 1.05)]);
      _runTo(e, 12);
      expect(e.coins, 0);
      final j = _custom([RunItem(RunItemKind.coin, 10, lane: 1, height: 1.05)]);
      _runTo(j, 10 - 0.3 * j.speed);
      j.jump();
      _runTo(j, 12);
      expect(j.coins, 1);
    });

    test('lane changes slide smoothly and stop at the edges', () {
      final e = _custom([]);
      expect(e.move(-1), isTrue);
      expect(e.move(-1), isFalse);
      expect(e.lane, 0);
      e.update(0.03);
      expect(e.laneX, inExclusiveRange(0, 1));
      _runTo(e, 10);
      expect(e.laneX, 0);
      expect(e.goToLane(2), isTrue);
      expect(e.goToLane(5), isFalse);
    });
  });

  group('obstacles', () {
    test('jumping clears a hurdle, standing hits it', () {
      final hit = _custom([RunItem(RunItemKind.hurdle, 20, lanes: const [0, 1, 2])]);
      expect(_runTo(hit, 25).whereType<ObstacleHit>(), hasLength(1));

      final clear = _custom([RunItem(RunItemKind.hurdle, 20, lanes: const [0, 1, 2])]);
      _runTo(clear, 20 - 0.3 * clear.speed);
      expect(clear.jump(), isTrue);
      expect(_runTo(clear, 25).whereType<ObstacleHit>(), isEmpty);
    });

    test('sliding clears an overhead beam', () {
      final e = _custom([RunItem(RunItemKind.overhead, 20, lanes: const [0, 1, 2])]);
      _runTo(e, 20 - 0.3 * e.speed);
      expect(e.slide(), isTrue);
      expect(_runTo(e, 25).whereType<ObstacleHit>(), isEmpty);
    });

    test('a block can only be dodged by changing lane', () {
      final hit = _custom([RunItem(RunItemKind.block, 20, lane: 1)]);
      _runTo(hit, 19);
      hit.jump();
      expect(_runTo(hit, 25).whereType<ObstacleHit>(), hasLength(1));

      final dodge = _custom([RunItem(RunItemKind.block, 20, lane: 1)]);
      _runTo(dodge, 15);
      dodge.move(1);
      expect(_runTo(dodge, 25).whereType<ObstacleHit>(), isEmpty);
    });

    test('first crash brings the Bug Monster; a second crash while it is close costs a heart', () {
      final e = _custom([
        RunItem(RunItemKind.block, 20, lane: 1),
        RunItem(RunItemKind.block, 35, lane: 1),
      ]);
      final lives = e.session.lives;
      final first = _runTo(e, 25).whereType<ObstacleHit>().single;
      expect(first.lostHeart, isFalse);
      expect(e.chase, greaterThan(0.9));
      expect(e.session.lives, lives);
      final second = _runTo(e, 40).whereType<ObstacleHit>().single;
      expect(second.lostHeart, isTrue);
      expect(e.session.lives, lives - 1);
    });

    test('the monster gives up after a while', () {
      final e = _custom([
        RunItem(RunItemKind.block, 20, lane: 1),
        RunItem(RunItemKind.block, 220, lane: 1),
      ]);
      final lives = e.session.lives;
      _runTo(e, 25);
      _runTo(e, 230);
      expect(e.session.lives, lives, reason: 'far-apart crashes do not cost hearts');
    });

    test('a shield absorbs one crash', () {
      final e = _custom([
        RunItem(RunItemKind.shield, 10, lane: 1),
        RunItem(RunItemKind.block, 20, lane: 1),
      ]);
      final events = _runTo(e, 25);
      expect(events.whereType<PowerUpPicked>().single.kind, RunItemKind.shield);
      final hit = events.whereType<ObstacleHit>().single;
      expect(hit.shielded, isTrue);
      expect(e.chase, 0);
      expect(e.shield, isFalse);
    });

    test('running out of hearts ends the run', () {
      final e = _custom([
        for (var k = 0; k < 8; k++) RunItem(RunItemKind.block, 20.0 + k * 12, lane: 1),
      ]);
      final events = _runTo(e, 200);
      expect(events.whereType<RunCaught>(), hasLength(1));
      expect(e.caught, isTrue);
      expect(e.session.lives, 0);
      expect(e.update(_step), isEmpty);
    });
  });

  group('code gates', () {
    test('running through a gate answers with your lane', () {
      final e = _custom([RunItem(RunItemKind.gate, 40, gate: 0), RunItem(RunItemKind.gate, 180, gate: 1)]);
      final q = e.session.current!;
      e.goToLane(q.correctIndex);
      final right = _runTo(e, 45).whereType<GatePassed>().single;
      expect(right.result.correct, isTrue);
      expect(right.bonusCoins, RunEngine.gateCoins);
      expect(e.coins, RunEngine.gateCoins);
      expect(e.boost, greaterThan(0));

      final q2 = e.session.current!;
      e.goToLane((q2.correctIndex + 1) % 3);
      final lives = e.session.lives;
      final wrong = _runTo(e, 185).whereType<GatePassed>().single;
      expect(wrong.result.correct, isFalse);
      expect(e.session.lives, lives - 1);
      expect(e.chase, greaterThan(0.9));
      expect(e.session.missed, hasLength(1));
    });

    test('the run slows down as a gate gets close, giving time to choose', () {
      final e = _custom([RunItem(RunItemKind.gate, 200, gate: 0)]);
      _runTo(e, 150);
      final far = e.speed;
      _runTo(e, 195);
      expect(e.speed, lessThan(far));
    });

    test('a hint orb blocks a wrong gate, and near the gate you are moved out of it', () {
      final e = _custom([
        RunItem(RunItemKind.hintOrb, 10, lane: 1),
        RunItem(RunItemKind.gate, 80, gate: 0),
      ]);
      final picked = _runTo(e, 15).whereType<PowerUpPicked>().single;
      expect(picked.removedLanes, hasLength(1));
      final removed = picked.removedLanes.single;
      expect(removed, isNot(e.session.current!.correctIndex));
      e.goToLane(removed);
      expect(e.lane, removed, reason: 'far from the gate you can still use every lane');
      _runTo(e, 80 - RunEngine.gateLockDistance + 1);
      expect(e.lane, isNot(removed));
      expect(e.goToLane(removed), isFalse);
      final passed = _runTo(e, 85).whereType<GatePassed>().single;
      expect(passed.result.chosenIndex, isNot(removed));
    });

    test('a hint with nothing left to remove gives coins instead', () {
      final e = _custom([
        RunItem(RunItemKind.hintOrb, 10, lane: 1),
        RunItem(RunItemKind.hintOrb, 12, lane: 1),
      ]);
      final events = _runTo(e, 15).whereType<PowerUpPicked>().toList();
      expect(events[0].removedLanes, isNotEmpty);
      expect(events[1].removedLanes, isEmpty);
      expect(events[1].bonusCoins, greaterThan(0));
    });
  });

  group('autopilot', () {
    for (final config in [RunConfig.normal, RunConfig.relaxed]) {
      for (final level in ['py-1', 'c-4', 'java-1']) {
        test('finishes every generated track without crashing '
            '($level, ${config == RunConfig.normal ? 'normal' : 'relaxed'})', () {
          for (var seed = 0; seed < 25; seed++) {
            final e = _engine(seed: seed, config: config, level: level);
            final events = _runTo(e, double.infinity, seconds: 400, each: autopilot);
            expect(events.whereType<ObstacleHit>(), isEmpty, reason: 'seed $seed crashed');
            expect(e.finished, isTrue, reason: 'seed $seed did not finish');
            expect(e.session.won, isTrue);
            expect(e.session.firstTryCorrect, e.session.total);
            expect(e.coins, greaterThan(RunEngine.gateCoins * e.session.total));
          }
        });
      }
    }
  });
}
