import 'dart:math';

import 'quiz_session.dart';

/// How fast and how busy a run is.
class RunConfig {
  const RunConfig({
    required this.startSpeed,
    required this.maxSpeed,
    required this.acceleration,
    required this.maxObstaclesPerStretch,
    required this.allowDoubleBlocks,
  });

  /// Metres per second at the start of the run.
  final double startSpeed;

  /// Top speed, reached by speeding up a little every second.
  final double maxSpeed;

  /// Metres per second gained every second.
  final double acceleration;

  /// Most obstacles between two code gates (the first stretches have fewer).
  final int maxObstaclesPerStretch;

  /// Whether a row can block two lanes at once (harder).
  final bool allowDoubleBlocks;

  static const RunConfig normal = RunConfig(
    startSpeed: 10,
    maxSpeed: 15.5,
    acceleration: 0.09,
    maxObstaclesPerStretch: 4,
    allowDoubleBlocks: true,
  );

  /// The "Relaxed" timer setting: slower and calmer.
  static const RunConfig relaxed = RunConfig(
    startSpeed: 6.5,
    maxSpeed: 9.5,
    acceleration: 0.04,
    maxObstaclesPerStretch: 2,
    allowDoubleBlocks: false,
  );
}

/// Everything that can be on the track.
enum RunItemKind {
  /// Pick it up by running through its lane.
  coin,

  /// Low obstacle (log, wall, lava): jump over it.
  hurdle,

  /// High obstacle (vines, beam, fire bar): slide under it.
  overhead,

  /// Tall obstacle in one lane (statue, crystal, boulder): change lane.
  block,

  /// A row of three answer gates, one per lane.
  gate,

  /// Power-up: removes one wrong gate of the coming question.
  hintOrb,

  /// Power-up: saves you from the next crash.
  shield,

  /// The end of the level.
  finish,
}

class RunItem {
  RunItem(
    this.kind,
    this.pos, {
    this.lane = 1,
    this.lanes = const [],
    this.height = 0,
    this.gate = -1,
  });

  final RunItemKind kind;

  /// Metres from the start of the track.
  final double pos;

  /// Lane (0 = left, 1 = middle, 2 = right) for single-lane items.
  final int lane;

  /// Lanes covered by a hurdle or overhead obstacle.
  final List<int> lanes;

  /// Height above the path (coins in a jump arc float in the air).
  final double height;

  /// Which code gate (0 = first) a gate row belongs to.
  final int gate;

  /// Set once the runner has passed it.
  bool passed = false;

  /// Set when a coin or power-up was picked up.
  bool taken = false;

  bool covers(int l) => lanes.isEmpty ? lane == l : lanes.contains(l);
}

/// Something that happened during a frame, for sounds, effects and the HUD.
sealed class RunEvent {
  const RunEvent();
}

class CoinPicked extends RunEvent {
  const CoinPicked(this.total);
  final int total;
}

class PowerUpPicked extends RunEvent {
  const PowerUpPicked(this.kind, {this.removedLanes = const [], this.bonusCoins = 0});
  final RunItemKind kind;

  /// Gates removed by a hint orb (empty if the coming gate had none to remove).
  final List<int> removedLanes;

  /// Coins given instead when the hint had nothing left to remove.
  final int bonusCoins;
}

class ObstacleHit extends RunEvent {
  const ObstacleHit({required this.kind, required this.shielded, required this.lostHeart});
  final RunItemKind kind;

  /// The shield took the hit: no penalty.
  final bool shielded;

  /// The monster was already close, so this crash cost a heart.
  final bool lostHeart;
}

class GatePassed extends RunEvent {
  const GatePassed(this.result, {required this.bonusCoins});
  final AnswerResult result;
  final int bonusCoins;
}

class RunFinished extends RunEvent {
  const RunFinished();
}

class RunCaught extends RunEvent {
  const RunCaught();
}

/// The rules of the Temple-Run style code runner.
///
/// The runner moves forward on its own; the player switches lanes, jumps
/// and slides. Questions come as rows of three gates - run through the gate
/// with the right answer. Crashing makes the Bug Monster catch up; crashing
/// again while it is close costs a heart, as does a wrong gate.
///
/// Pure Dart (no Flutter), so every rule is unit-tested.
class RunEngine {
  RunEngine({required this.session, this.config = RunConfig.normal, Random? random})
      : _random = random ?? Random() {
    speed = config.startSpeed;
    _buildTrack();
  }

  static const int laneCount = 3;

  /// Coins-only warm-up before the first gate (time to read question 1).
  static const double firstGateAt = 90;
  static const double gateSpacing = 140;

  /// No obstacles this close before a gate, so choosing a gate is all you do.
  static const double clearBeforeGate = 30;
  static const double clearAfterGate = 18;
  static const double finishAfterLastGate = 60;

  /// Lanes removed by a hint become walls within this distance of the gate.
  static const double gateLockDistance = 36;

  static const double jumpDuration = 0.62;
  static const double jumpHeight = 1.25;
  static const double slideDuration = 0.72;

  /// Seconds the monster stays close after a crash or a wrong gate.
  static const double chaseSeconds = 6;

  /// How fast the runner slides sideways (lanes per second).
  static const double laneChangeSpeed = 9;

  /// Coins for running through the right gate.
  static const int gateCoins = 5;

  final QuizSession session;
  final RunConfig config;
  final Random _random;

  /// Every track item, sorted by position.
  final List<RunItem> items = [];
  late final List<double> gatePositions;
  late final double finishPos;

  double distance = 0;
  late double speed;
  double elapsed = 0;

  /// The lane the player is heading for.
  int lane = 1;

  /// Where the runner is drawn (slides smoothly towards [lane]).
  double laneX = 1;

  double? _jumpT;
  double? _slideT;

  /// How close the Bug Monster is: 1 = right behind you, 0 = gone.
  double chase = 0;

  /// Seconds of crash slowdown / right-answer speed boost left.
  double stumble = 0;
  double boost = 0;

  bool shield = false;

  /// Coins picked up during this run.
  int coins = 0;

  bool finished = false;
  bool caught = false;

  int _next = 0;

  bool get over => finished || caught;

  /// Height of the runner above the path (jump arc).
  double get height {
    final t = _jumpT;
    if (t == null) return 0;
    final p = t / jumpDuration;
    return 4 * jumpHeight * p * (1 - p);
  }

  bool get jumping => _jumpT != null;
  bool get airborne => height > 0.42;
  bool get sliding => _slideT != null;

  /// 0..1 progress of the slide (for drawing).
  double get slideProgress => (_slideT ?? 0) / slideDuration;

  /// 0..1 along the whole track.
  double get progress => (distance / finishPos).clamp(0.0, 1.0);

  /// The lane the runner is actually in right now.
  int get currentLane => laneX.round().clamp(0, laneCount - 1);

  RunItem? get nextGate {
    for (var i = _next; i < items.length; i++) {
      if (items[i].kind == RunItemKind.gate) return items[i];
    }
    return null;
  }

  /// Metres to the next gate, or null after the last one.
  double? get distanceToGate {
    final g = nextGate;
    return g == null ? null : g.pos - distance;
  }

  /// Near a gate, lanes removed by a hint act as walls.
  bool get gateLocked => (distanceToGate ?? double.infinity) < gateLockDistance;

  bool _blocked(int l) => gateLocked && session.isHidden(l);

  // ------------------------------------------------------------------ input

  /// Moves one lane left (-1) or right (+1). Returns false at the edge.
  bool move(int direction) {
    var target = lane + direction;
    while (target >= 0 && target < laneCount && _blocked(target)) {
      target += direction;
    }
    if (target < 0 || target >= laneCount || target == lane) return false;
    lane = target;
    return true;
  }

  /// Jumps straight to a lane (keys 1-3 or tapping an answer).
  bool goToLane(int target) {
    if (target < 0 || target >= laneCount || target == lane || _blocked(target)) return false;
    lane = target;
    return true;
  }

  bool jump() {
    if (over || _jumpT != null) return false;
    _slideT = null;
    _jumpT = 0;
    return true;
  }

  bool slide() {
    if (over || _slideT != null) return false;
    _jumpT = null; // drop out of a jump straight into the slide
    _slideT = 0;
    return true;
  }

  // --------------------------------------------------------------- the loop

  /// Advances the run by [dt] seconds and reports what happened.
  List<RunEvent> update(double dt) {
    final events = <RunEvent>[];
    if (over) return events;
    final step = dt.clamp(0.0, 0.05);
    elapsed += step;

    final base = min(config.maxSpeed, config.startSpeed + config.acceleration * elapsed);
    var factor = 1.0;
    if (stumble > 0) factor *= 0.55;
    if (boost > 0) factor *= 1.25;
    // Dramatic slow-down while a gate approaches: time to pick the lane.
    final toGate = distanceToGate;
    if (toGate != null && toGate > 0 && toGate < 40) factor *= 0.72 + 0.28 * (toGate / 40);
    speed = base * factor;

    stumble = max(0, stumble - step);
    boost = max(0, boost - step);
    chase = max(0, chase - step / chaseSeconds);

    final jt = _jumpT;
    if (jt != null) _jumpT = jt + step >= jumpDuration ? null : jt + step;
    final st = _slideT;
    if (st != null) _slideT = st + step >= slideDuration ? null : st + step;

    if (_blocked(lane)) lane = _nearestOpenLane(lane);
    final glide = laneChangeSpeed * step;
    final target = lane.toDouble();
    laneX = (laneX - target).abs() <= glide ? target : laneX + glide * (target - laneX).sign;

    distance += speed * step;
    while (_next < items.length && items[_next].pos <= distance) {
      final item = items[_next++]..passed = true;
      _handle(item, events);
      if (over) break;
    }
    return events;
  }

  int _nearestOpenLane(int from) {
    for (final d in const [1, -1, 2, -2]) {
      final l = from + d;
      if (l >= 0 && l < laneCount && !_blocked(l)) return l;
    }
    return from;
  }

  void _handle(RunItem item, List<RunEvent> events) {
    final at = currentLane;
    switch (item.kind) {
      case RunItemKind.coin:
        if (item.lane == at && (height - item.height).abs() < 0.8) {
          item.taken = true;
          coins++;
          events.add(CoinPicked(coins));
        }
      case RunItemKind.hurdle:
        if (item.covers(at) && !airborne) _crash(item, events);
      case RunItemKind.overhead:
        if (item.covers(at) && !sliding) _crash(item, events);
      case RunItemKind.block:
        if (item.lane == at) _crash(item, events);
      case RunItemKind.hintOrb:
        if (item.lane == at) {
          item.taken = true;
          final removed = session.useFiftyFifty();
          final bonus = removed.isEmpty ? 10 : 0;
          coins += bonus;
          events.add(PowerUpPicked(item.kind, removedLanes: removed, bonusCoins: bonus));
        }
      case RunItemKind.shield:
        if (item.lane == at) {
          item.taken = true;
          shield = true;
          events.add(PowerUpPicked(item.kind));
        }
      case RunItemKind.gate:
        _passGate(at, events);
      case RunItemKind.finish:
        finished = true;
        events.add(const RunFinished());
    }
  }

  void _passGate(int at, List<RunEvent> events) {
    if (session.current == null) return;
    final choice = session.isHidden(at) ? _nearestOpenLane(at) : at;
    final result = session.answer(choice);
    var bonus = 0;
    if (result.correct) {
      boost = 1.6;
      chase = 0;
      bonus = gateCoins;
      coins += bonus;
    } else {
      chase = 1;
    }
    events.add(GatePassed(result, bonusCoins: bonus));
    if (session.lives <= 0) {
      caught = true;
      events.add(const RunCaught());
    }
  }

  void _crash(RunItem item, List<RunEvent> events) {
    if (shield) {
      shield = false;
      events.add(ObstacleHit(kind: item.kind, shielded: true, lostHeart: false));
      return;
    }
    final lostHeart = chase > 0;
    if (lostHeart) session.loseLife();
    chase = 1;
    stumble = 0.9;
    events.add(ObstacleHit(kind: item.kind, shielded: false, lostHeart: lostHeart));
    if (session.lives <= 0) {
      caught = true;
      events.add(const RunCaught());
    }
  }

  // ----------------------------------------------------------- track builder

  void _buildTrack() {
    final gates = session.total;
    gatePositions = [for (var i = 0; i < gates; i++) firstGateAt + i * gateSpacing];
    finishPos = gatePositions.last + finishAfterLastGate;

    // Warm-up: just coins, so the first question can be read in peace.
    _coinRow(1, 16, 6);
    _coinRow(_random.nextBool() ? 0 : 2, 42, 5);

    for (var i = 0; i < gates; i++) {
      items.add(RunItem(RunItemKind.gate, gatePositions[i], gate: i));
      final start = gatePositions[i] + clearAfterGate;
      if (i + 1 < gates) {
        _stretch(start, gatePositions[i + 1] - clearBeforeGate, i);
      } else {
        _coinRow(1, start, 8);
      }
    }
    items
      ..add(RunItem(RunItemKind.finish, finishPos))
      ..sort((a, b) => a.pos.compareTo(b.pos));
  }

  void _coinRow(int lane, double from, int count, {double spacing = 2.4}) {
    for (var k = 0; k < count; k++) {
      items.add(RunItem(RunItemKind.coin, from + k * spacing, lane: lane));
    }
  }

  /// Obstacles, coins and power-ups between two gates. Later stretches are
  /// busier. Every row leaves a way through (jump, slide or a free lane).
  void _stretch(double start, double end, int index) {
    final count = min(config.maxObstaclesPerStretch, 1 + index);
    final gap = (end - start) / (count + 1);
    final slots = [for (var k = 1; k <= count; k++) start + gap * k + (_random.nextDouble() - 0.5) * gap * 0.3];

    for (final pos in slots) {
      _obstacleRow(pos, index);
    }

    // Coins in the spaces between obstacles.
    final edges = [start, ...slots, end];
    for (var k = 0; k + 1 < edges.length; k++) {
      final from = edges[k] + 5;
      final room = edges[k + 1] - 5 - from;
      if (room < 6) continue;
      final n = min(6, (room / 2.4).floor());
      _coinRow(_random.nextInt(laneCount), from + (room - (n - 1) * 2.4) / 2, n);
    }

    // One power-up per stretch after the first: hint orbs early, shields later.
    if (index >= 1 && slots.isNotEmpty) {
      final pos = (slots.first + edges.first) / 2;
      final kind = index.isOdd ? RunItemKind.hintOrb : RunItemKind.shield;
      items.add(RunItem(kind, pos, lane: _random.nextInt(laneCount)));
    }
  }

  void _obstacleRow(double pos, int index) {
    const all = [0, 1, 2];
    final options = <String>[
      'block',
      'hurdle',
      'overhead',
      if (index >= 1 && config.allowDoubleBlocks) 'twoBlocks',
      if (index >= 2) 'blockAndHurdles',
    ];
    switch (options[_random.nextInt(options.length)]) {
      case 'block':
        items.add(RunItem(RunItemKind.block, pos, lane: _random.nextInt(laneCount)));
      case 'hurdle':
        items.add(RunItem(RunItemKind.hurdle, pos, lanes: all));
        // A jump arc of coins over the middle of the log.
        for (final (dz, h) in const [(-1.6, 0.7), (0.0, 1.05), (1.6, 0.7)]) {
          items.add(RunItem(RunItemKind.coin, pos + dz, lane: 1, height: h));
        }
      case 'overhead':
        items.add(RunItem(RunItemKind.overhead, pos, lanes: all));
      case 'twoBlocks':
        final free = _random.nextInt(laneCount);
        for (final l in all) {
          if (l != free) items.add(RunItem(RunItemKind.block, pos, lane: l));
        }
      case 'blockAndHurdles':
        final blocked = _random.nextInt(laneCount);
        items
          ..add(RunItem(RunItemKind.block, pos, lane: blocked))
          ..add(RunItem(RunItemKind.hurdle, pos, lanes: [for (final l in all) if (l != blocked) l]));
    }
  }
}
