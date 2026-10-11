import 'run_engine.dart';

/// Byte's autopilot: plays the code runner perfectly. It dodges blocks,
/// jumps hurdles, slides under beams and runs through the right gate.
///
/// Used for the "Watch Byte play" demo run, and by tests to prove every
/// generated track can be finished without crashing. Call it once per frame,
/// before [RunEngine.update].
void autopilot(RunEngine e) {
  final q = e.session.current;
  final toGate = e.distanceToGate;
  if (q != null && toGate != null && toGate < RunEngine.clearBeforeGate) {
    e.goToLane(q.correctIndex);
    return;
  }
  for (final item in e.items) {
    if (item.passed) continue;
    final ahead = item.pos - e.distance;
    if (ahead > 12) break;
    if (ahead <= 0) continue;
    switch (item.kind) {
      case RunItemKind.block when item.lane == e.lane:
        final blocked = {
          for (final other in e.items)
            if (other.kind == RunItemKind.block && (other.pos - item.pos).abs() < 0.5) other.lane,
        };
        final free = [for (var l = 0; l < RunEngine.laneCount; l++) if (!blocked.contains(l)) l];
        free.sort((a, b) => (a - e.lane).abs().compareTo((b - e.lane).abs()));
        if (free.isNotEmpty) e.goToLane(free.first);
      case RunItemKind.hurdle when item.covers(e.lane) && ahead < 0.3 * e.speed:
        if (!e.jumping) e.jump();
      case RunItemKind.overhead when ahead < 0.35 * e.speed:
        if (!e.sliding) e.slide();
      default:
        break;
    }
  }
}
