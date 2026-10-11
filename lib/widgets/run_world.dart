import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/run_engine.dart';
import '../theme/app_theme.dart';
import 'scenes.dart';

// The 3D-looking world of the code runner: a temple path that rushes towards
// the camera, with themed scenery, obstacles, coins, answer gates, the runner
// and the Bug Monster. Everything is painted in code - no image files.

/// Colours for one world's run.
@immutable
class RunTheme {
  const RunTheme({
    required this.scene,
    required this.sky,
    required this.far,
    required this.mid,
    required this.glow,
    required this.groundNear,
    required this.groundFar,
    required this.tileA,
    required this.tileB,
    required this.laneLine,
    required this.curbTop,
    required this.curbFace,
    required this.hurdle,
    required this.hurdleDark,
    required this.overhead,
    required this.overheadAccent,
    required this.block,
    required this.blockDark,
    required this.blockAccent,
    required this.prop,
    required this.propDark,
    required this.propAccent,
    required this.ink,
    this.highContrast = false,
  });

  final SceneKind scene;
  final List<Color> sky;
  final Color far;
  final Color mid;
  final Color glow;
  final Color groundNear;
  final Color groundFar;
  final Color tileA;
  final Color tileB;
  final Color laneLine;
  final Color curbTop;
  final Color curbFace;
  final Color hurdle;
  final Color hurdleDark;
  final Color overhead;
  final Color overheadAccent;
  final Color block;
  final Color blockDark;
  final Color blockAccent;
  final Color prop;
  final Color propDark;
  final Color propAccent;
  final Color ink;
  final bool highContrast;
}

RunTheme runThemeFor(SceneKind scene, GameColors g) {
  if (g.highContrast) {
    return RunTheme(
      scene: scene,
      sky: const [Colors.black, Colors.black],
      far: const Color(0xFF2A2A2A),
      mid: const Color(0xFF1A1A1A),
      glow: Colors.white,
      groundNear: Colors.black,
      groundFar: Colors.black,
      tileA: const Color(0xFF1C1C1C),
      tileB: Colors.black,
      laneLine: Colors.white,
      curbTop: Colors.white,
      curbFace: const Color(0xFF8A8A8A),
      hurdle: const Color(0xFFFFFF00),
      hurdleDark: const Color(0xFFB8B800),
      overhead: const Color(0xFF00FFFF),
      overheadAccent: Colors.white,
      block: const Color(0xFFFF5A5A),
      blockDark: const Color(0xFFB02E2E),
      blockAccent: Colors.white,
      prop: const Color(0xFF3A3A3A),
      propDark: const Color(0xFF222222),
      propAccent: Colors.white,
      ink: Colors.white,
      highContrast: true,
    );
  }
  const ink = Color(0xFF2B1840);
  return switch (scene) {
    SceneKind.c => const RunTheme(
        scene: SceneKind.c,
        sky: [Color(0xFF070D26), Color(0xFF22346E)],
        far: Color(0xFF16245A),
        mid: Color(0xFF0C1638),
        glow: Color(0xFF5BE7FF),
        groundNear: Color(0xFF111A40),
        groundFar: Color(0xFF1F2D63),
        tileA: Color(0xFF3D4F90),
        tileB: Color(0xFF33447D),
        laneLine: Color(0xFF8FB0F0),
        curbTop: Color(0xFF5A70BC),
        curbFace: Color(0xFF2A3570),
        hurdle: Color(0xFF7484B4),
        hurdleDark: Color(0xFF414C7A),
        overhead: Color(0xFF8FE9FF),
        overheadAccent: Color(0xFF4A5A90),
        block: Color(0xFF5BE7FF),
        blockDark: Color(0xFF2486B0),
        blockAccent: Color(0xFFB98CFF),
        prop: Color(0xFF5BE7FF),
        propDark: Color(0xFF26346E),
        propAccent: Color(0xFFB98CFF),
        ink: ink,
      ),
    SceneKind.cpp => const RunTheme(
        scene: SceneKind.cpp,
        sky: [Color(0xFF140A33), Color(0xFF5A3FA0)],
        far: Color(0xFF2A1858),
        mid: Color(0xFF1E1048),
        glow: Color(0xFFFFE9A8),
        groundNear: Color(0xFF241650),
        groundFar: Color(0xFF3A2470),
        tileA: Color(0xFF8C7BB8),
        tileB: Color(0xFF7A69A6),
        laneLine: Color(0xFFE2D7FA),
        curbTop: Color(0xFF6A5A96),
        curbFace: Color(0xFF463A6E),
        hurdle: Color(0xFFB0704F),
        hurdleDark: Color(0xFF6E4532),
        overhead: Color(0xFF8B5A2B),
        overheadAccent: Color(0xFFFF6B7F),
        block: Color(0xFFC08A4E),
        blockDark: Color(0xFF7A5228),
        blockAccent: Color(0xFFFFC93C),
        prop: Color(0xFF3A2A60),
        propDark: Color(0xFF241848),
        propAccent: Color(0xFFFFC93C),
        ink: ink,
      ),
    SceneKind.java => const RunTheme(
        scene: SceneKind.java,
        sky: [Color(0xFF2A0605), Color(0xFFE8682A)],
        far: Color(0xFF3E100B),
        mid: Color(0xFF250807),
        glow: Color(0xFFFF9A3D),
        groundNear: Color(0xFF240C08),
        groundFar: Color(0xFF4A1A12),
        tileA: Color(0xFF55291F),
        tileB: Color(0xFF47221B),
        laneLine: Color(0xFFFF8A3D),
        curbTop: Color(0xFF6A3426),
        curbFace: Color(0xFF341511),
        hurdle: Color(0xFFFF7A2E),
        hurdleDark: Color(0xFFC2410C),
        overhead: Color(0xFFFFB347),
        overheadAccent: Color(0xFF3A1A14),
        block: Color(0xFF6A463C),
        blockDark: Color(0xFF3A231D),
        blockAccent: Color(0xFFFF7A2E),
        prop: Color(0xFF3A1A14),
        propDark: Color(0xFF1E0B08),
        propAccent: Color(0xFFFF8A3D),
        ink: ink,
      ),
    _ => const RunTheme(
        scene: SceneKind.python,
        sky: [Color(0xFF63CFAE), Color(0xFFC6F5DF)],
        far: Color(0xFF3BAA78),
        mid: Color(0xFF1F7F55),
        glow: Color(0xFFFFF3A8),
        groundNear: Color(0xFF17704A),
        groundFar: Color(0xFF2E9E6E),
        tileA: Color(0xFFDDB680),
        tileB: Color(0xFFC9A16B),
        laneLine: Color(0xFFF6E3B8),
        curbTop: Color(0xFFA8977A),
        curbFace: Color(0xFF6E5E48),
        hurdle: Color(0xFF9A6036),
        hurdleDark: Color(0xFF5E3519),
        overhead: Color(0xFF34B26A),
        overheadAccent: Color(0xFF6B4423),
        block: Color(0xFFADA593),
        blockDark: Color(0xFF6F685D),
        blockAccent: Color(0xFF3DDC84),
        prop: Color(0xFF1E8A5B),
        propDark: Color(0xFF5B3A22),
        propAccent: Color(0xFFC2B79E),
        ink: ink,
      ),
  };
}

/// Short-lived visual effects drawn on top of the world: sparkles, dust,
/// screen shake and colour flashes. Owned and ticked by the runner screen.
class RunFx {
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(7);
  double shake = 0;
  double flash = 0;
  Color flashColor = Colors.white;

  void update(double dt) {
    shake = math.max(0, shake - dt);
    flash = math.max(0, flash - dt * 2.2);
    for (final p in _particles) {
      p
        ..life -= dt
        ..x += p.vx * dt
        ..y += p.vy * dt
        ..vy += p.gravity * dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  /// Gold sparkles where a coin was picked up (screen fractions 0..1).
  void sparkle(Offset at, {Color color = const Color(0xFFFFE066), int count = 8}) {
    for (var i = 0; i < count; i++) {
      final a = _random.nextDouble() * math.pi * 2;
      final v = 0.12 + _random.nextDouble() * 0.25;
      _particles.add(_Particle(at.dx, at.dy, math.cos(a) * v, math.sin(a) * v - 0.15, 0.55, color, 0.008, 0.6));
    }
  }

  /// Dust puff after a crash.
  void dust(Offset at) {
    for (var i = 0; i < 12; i++) {
      final a = math.pi + _random.nextDouble() * math.pi;
      final v = 0.05 + _random.nextDouble() * 0.12;
      _particles.add(
          _Particle(at.dx, at.dy, math.cos(a) * v, math.sin(a) * v * 0.5, 0.7, const Color(0xFFD9CBB0), 0.02, 0.05));
    }
  }

  void hit(Color color) {
    shake = 0.35;
    flash = 1;
    flashColor = color;
  }

  void glow(Color color) {
    flash = 0.6;
    flashColor = color;
  }

  void clear() {
    _particles.clear();
    shake = 0;
    flash = 0;
  }
}

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.size, this.gravity) : maxLife = life;

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final Color color;
  final double size;
  final double gravity;
}

/// Turns 3D track positions into screen positions.
///
/// x is sideways in lanes (-1 left lane, 0 middle, 1 right), y is height and
/// z is metres ahead of the runner. The path bends gently left and right.
class RunCamera {
  RunCamera(Size size, this.curve) {
    w = size.width;
    h = size.height;
    cx = w / 2;
    final tall = h > w;
    horizon = h * (tall ? 0.43 : 0.40);
    playerY = h * (tall ? 0.80 : 0.82);
    s0 = math.min(w, h * 1.05) * 0.29;
    f = s0 * depth;
    camHeight = (playerY - horizon) / s0;
  }

  static const double depth = 3.2;

  final double curve;
  late final double w;
  late final double h;
  late final double cx;
  late final double horizon;
  late final double playerY;

  /// Pixels per lane at the runner's distance.
  late final double s0;
  late final double f;
  late final double camHeight;

  double scale(double z) => f / (math.max(z, -depth + 0.3) + depth);
  double bend(double z) => curve * z * z / 900;

  Offset p(double x, double y, double z) {
    final s = scale(z);
    return Offset(cx + (x + bend(z)) * s, horizon + (camHeight - y) * s);
  }
}

class RunWorldPainter extends CustomPainter {
  RunWorldPainter({
    required this.engine,
    required this.theme,
    required this.accent,
    required this.runnerShirt,
    required this.fx,
    required this.time,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final RunEngine engine;
  final RunTheme theme;

  /// The world's colour (gate posts, number badges).
  final Color accent;
  final Color runnerShirt;
  final RunFx fx;

  /// Seconds since the screen opened (for idle animations).
  final ValueGetter<double> time;

  static final Map<String, TextPainter> _textCache = {};

  double get _t => time();
  Color get _ink => theme.ink;
  double get _outline => theme.highContrast ? 3 : 2.4;

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(double width, [Color? c]) => Paint()
    ..color = c ?? _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final curve = theme.highContrast ? 0.0 : 1.1 * math.sin(engine.distance / 110);
    final cam = RunCamera(size, curve);

    canvas.save();
    if (fx.shake > 0) {
      final a = fx.shake * 14;
      canvas.translate(math.sin(_t * 61) * a, math.cos(_t * 47) * a * 0.6);
    }
    _backdrop(canvas, cam, size);
    _ground(canvas, cam, size);
    _road(canvas, cam);
    _curbs(canvas, cam);

    // Everything that stands on the track, drawn far-to-near.
    final drawables = <(double, VoidCallback)>[];
    _addProps(canvas, cam, drawables);
    for (final item in engine.items) {
      final z = item.pos - engine.distance;
      if (z > 95) break;
      if (z < -1.4 || item.taken) continue;
      drawables.add((z, () => _item(canvas, cam, item, z)));
    }
    drawables.add((0.001, () => _runner(canvas, cam)));
    drawables.sort((a, b) => b.$1.compareTo(a.$1));
    for (final d in drawables) {
      d.$2();
    }

    _speedLines(canvas, cam);
    _monster(canvas, cam);
    _particles(canvas, size);
    canvas.restore();

    if (fx.flash > 0) {
      canvas.drawRect(Offset.zero & size, _fill(fx.flashColor.withValues(alpha: 0.32 * fx.flash)));
    }
  }

  // ------------------------------------------------------------- backdrop

  void _backdrop(Canvas canvas, RunCamera cam, Size size) {
    final sky = Rect.fromLTRB(-40, -40, size.width + 40, cam.horizon + 2);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.sky,
        ).createShader(sky),
    );
    if (theme.highContrast) {
      canvas.drawLine(Offset(0, cam.horizon), Offset(size.width, cam.horizon), _stroke(2, Colors.white));
      return;
    }
    final shift = -cam.curve * size.width * 0.06;
    final w = size.width;
    final hz = cam.horizon;
    switch (theme.scene) {
      case SceneKind.c:
        // Crystal glow on the far cave wall, stalactites hanging from the roof.
        _ridge(canvas, w, hz, hz * 0.78, hz * 0.08, 5, shift * 0.5, theme.far);
        for (var i = 0; i < 9; i++) {
          final x = (i / 8) * w + shift * 0.4;
          final y = hz * (0.82 + 0.06 * math.sin(i * 2.1));
          _glowDot(canvas, Offset(x, y), 8 + (i % 3) * 4, theme.glow, 0.5 + 0.3 * math.sin(_t * 2 + i));
          _diamond(canvas, Offset(x, y), 5 + (i % 3) * 2.0, theme.glow);
        }
        final roof = _fill(theme.mid);
        for (var i = 0; i < 14; i++) {
          final x = (i / 13) * w + shift * 0.8;
          final len = hz * (0.18 + 0.14 * ((i * 37) % 5) / 5);
          canvas.drawPath(
            Path()
              ..moveTo(x - 22, -2)
              ..lineTo(x + 22, -2)
              ..lineTo(x, len)
              ..close(),
            roof,
          );
        }
        _ridge(canvas, w, hz, hz * 0.94, hz * 0.04, 9, shift, theme.mid);
      case SceneKind.cpp:
        for (var i = 0; i < 40; i++) {
          final x = ((i * 97) % 100) / 100 * w + shift * 0.2;
          final y = ((i * 53) % 100) / 100 * hz * 0.7;
          final a = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(_t * 2 + i));
          canvas.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.6, _fill(Colors.white.withValues(alpha: a)));
        }
        final moon = Offset(w * 0.78 + shift * 0.3, hz * 0.32);
        _glowDot(canvas, moon, hz * 0.13, theme.glow, 0.5);
        canvas.drawCircle(moon, hz * 0.09, _fill(theme.glow));
        _ridge(canvas, w, hz, hz * 0.86, hz * 0.05, 4, shift * 0.5, theme.far);
        _castle(canvas, Offset(w * 0.32 + shift * 0.7, hz), hz * 0.42);
      case SceneKind.java:
        final top = Offset(w * 0.62 + shift * 0.5, hz * 0.38);
        final cone = Path()
          ..moveTo(top.dx - w * 0.05, top.dy)
          ..lineTo(top.dx + w * 0.05, top.dy)
          ..lineTo(top.dx + w * 0.34, hz)
          ..lineTo(top.dx - w * 0.34, hz)
          ..close();
        canvas.drawPath(cone, _fill(theme.far));
        _glowDot(canvas, top, w * 0.06, theme.glow, 0.7 + 0.2 * math.sin(_t * 3));
        final lava = _stroke(3, const Color(0xFFFF7A2E));
        for (final dx in const [-0.04, 0.02, 0.05]) {
          canvas.drawPath(
            Path()
              ..moveTo(top.dx + w * dx * 0.5, top.dy + 2)
              ..quadraticBezierTo(top.dx + w * dx * 1.5, top.dy + (hz - top.dy) * 0.5, top.dx + w * dx * 3, hz),
            lava,
          );
        }
        for (var i = 0; i < 4; i++) {
          final k = (_t * 0.08 + i / 4) % 1;
          canvas.drawCircle(
            Offset(top.dx + math.sin(i * 1.7 + _t * 0.4) * 20, top.dy - k * hz * 0.4),
            12 + k * 30,
            _fill(const Color(0xFF5A3A36).withValues(alpha: 0.45 * (1 - k))),
          );
        }
        for (var i = 0; i < 18; i++) {
          final k = (_t * 0.15 + i / 18) % 1;
          final x = ((i * 61) % 100) / 100 * w + math.sin(_t + i) * 10;
          canvas.drawCircle(Offset(x, hz - k * hz), 1.5 + (i % 3), _fill(const Color(0xFFFFB347).withValues(alpha: 1 - k)));
        }
        _ridge(canvas, w, hz, hz * 0.93, hz * 0.04, 7, shift, theme.mid);
      default:
        final sun = Offset(w * 0.78 + shift * 0.3, hz * 0.3);
        _glowDot(canvas, sun, hz * 0.16, theme.glow, 0.6);
        canvas.drawCircle(sun, hz * 0.09, _fill(theme.glow));
        _ridge(canvas, w, hz, hz * 0.72, hz * 0.1, 3, shift * 0.4, theme.far);
        _pyramid(canvas, Offset(w * 0.27 + shift * 0.6, hz), hz * 0.42);
        // Jungle canopy right on the horizon.
        final canopy = _fill(theme.mid);
        for (var i = -1; i < 16; i++) {
          final x = i / 14 * w + shift;
          canvas.drawCircle(Offset(x, hz - 4 + math.sin(i * 1.3) * 6), 26 + (i % 3) * 8, canopy);
        }
        final vine = _stroke(3, const Color(0xFF178A55));
        for (var i = 0; i < 7; i++) {
          final x = (i + 0.5) / 7 * w + shift * 1.2;
          final len = hz * (0.2 + 0.15 * ((i * 3) % 4) / 4);
          canvas.drawPath(
            Path()
              ..moveTo(x, -2)
              ..quadraticBezierTo(x + math.sin(_t + i) * 6, len / 2, x, len),
            vine,
          );
          canvas.drawCircle(Offset(x, len), 5, _fill(const Color(0xFF2FBF73)));
        }
    }
  }

  void _ridge(Canvas canvas, double w, double hz, double base, double amp, int bumps, double shift, Color color) {
    final path = Path()..moveTo(-40, hz + 2);
    for (var i = 0; i <= 24; i++) {
      final x = -40 + (w + 80) * i / 24;
      path.lineTo(x, base + math.sin((x - shift) / w * bumps * math.pi) * amp);
    }
    path
      ..lineTo(w + 40, hz + 2)
      ..close();
    canvas.drawPath(path, _fill(color));
  }

  void _glowDot(Canvas canvas, Offset c, double r, Color color, double alpha) {
    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(c, r * (0.6 + i * 0.4), _fill(color.withValues(alpha: (alpha * 0.22 / i).clamp(0.0, 1.0))));
    }
  }

  void _diamond(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r * 1.6)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx, c.dy + r * 0.8)
        ..lineTo(c.dx - r, c.dy)
        ..close(),
      _fill(color),
    );
  }

  void _pyramid(Canvas canvas, Offset base, double height) {
    final paint = _fill(const Color(0xFF2C8A60));
    const steps = 5;
    for (var i = 0; i < steps; i++) {
      final wHalf = height * (1.1 - i * 0.2);
      final y = base.dy - height * i / steps;
      canvas.drawRect(Rect.fromLTRB(base.dx - wHalf, y - height / steps, base.dx + wHalf, y), paint);
    }
    canvas.drawRect(
      Rect.fromCenter(center: Offset(base.dx, base.dy - height * 0.98), width: height * 0.22, height: height * 0.14),
      paint,
    );
  }

  void _castle(Canvas canvas, Offset base, double height) {
    final wall = _fill(theme.mid);
    final light = _fill(theme.propAccent.withValues(alpha: 0.9));
    final w = height * 1.6;
    canvas.drawRect(Rect.fromLTRB(base.dx - w / 2, base.dy - height * 0.45, base.dx + w / 2, base.dy), wall);
    for (final (dx, th) in const [(-0.5, 0.85), (-0.15, 1.0), (0.2, 0.7), (0.5, 0.9)]) {
      final x = base.dx + dx * w;
      final tw = height * 0.2;
      canvas
        ..drawRect(Rect.fromLTRB(x - tw / 2, base.dy - height * th, x + tw / 2, base.dy), wall)
        ..drawPath(
          Path()
            ..moveTo(x - tw * 0.7, base.dy - height * th)
            ..lineTo(x + tw * 0.7, base.dy - height * th)
            ..lineTo(x, base.dy - height * (th + 0.22))
            ..close(),
          wall,
        )
        ..drawRect(Rect.fromCenter(center: Offset(x, base.dy - height * th * 0.7), width: tw * 0.3, height: tw * 0.45), light);
    }
  }

  // --------------------------------------------------------- ground & road

  void _ground(Canvas canvas, RunCamera cam, Size size) {
    final rect = Rect.fromLTRB(-40, cam.horizon, size.width + 40, size.height + 40);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.groundFar, theme.groundNear],
        ).createShader(rect),
    );
  }

  static const double _half = 1.5;
  static const double _tile = 2.0;

  void _road(Canvas canvas, RunCamera cam) {
    final first = (engine.distance / _tile).floor();
    final a = _fill(theme.tileA);
    final b = _fill(theme.tileB);
    // Far end as one piece, then tiles near to the camera.
    canvas.drawPath(_quad(cam, -_half, _half, 0, 90, 400), a);
    for (var k = -2; k < 46; k++) {
      final z1 = math.max((first + k) * _tile - engine.distance, -1.6);
      final z2 = (first + k + 1) * _tile - engine.distance;
      if (z2 <= -1.6) continue;
      canvas.drawPath(_quad(cam, -_half, _half, 0, z1, z2), (first + k).isEven ? a : b);
      // Lava seams glow in the volcano; lane dashes elsewhere.
      if ((first + k).isEven && z2 > 0) {
        final line = _stroke(math.max(1, 0.05 * cam.scale(z1)), theme.laneLine.withValues(alpha: theme.highContrast ? 1 : 0.7));
        for (final x in const [-0.5, 0.5]) {
          canvas.drawLine(cam.p(x, 0, z1 + 0.35), cam.p(x, 0, z2 - 0.35), line);
        }
      }
      if (theme.scene == SceneKind.java && !theme.highContrast && (first + k) % 5 == 0) {
        final crack = _stroke(math.max(1, 0.04 * cam.scale(z1)), const Color(0xFFFF7A2E));
        canvas.drawPath(
          Path()
            ..moveTo(cam.p(-1.2, 0, z1).dx, cam.p(-1.2, 0, z1).dy)
            ..lineTo(cam.p(-0.7, 0, (z1 + z2) / 2).dx, cam.p(-0.7, 0, (z1 + z2) / 2).dy)
            ..lineTo(cam.p(-0.9, 0, z2).dx, cam.p(-0.9, 0, z2).dy),
          crack,
        );
      }
    }
  }

  Path _quad(RunCamera cam, double x0, double x1, double y, double z1, double z2) {
    final p1 = cam.p(x0, y, z1);
    final p2 = cam.p(x1, y, z1);
    final p3 = cam.p(x1, y, z2);
    final p4 = cam.p(x0, y, z2);
    return Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();
  }

  static const List<double> _curbZ = [-1.6, -0.8, 0, 1, 2, 3.5, 5, 7, 9, 12, 15, 19, 24, 30, 37, 45, 55, 66, 80, 95];

  void _curbs(Canvas canvas, RunCamera cam) {
    const h = 0.16;
    for (final side in const [-1.0, 1.0]) {
      final inner = side * _half;
      final outer = side * (_half + 0.24);
      final top = Path();
      final face = Path();
      for (var i = 0; i < _curbZ.length; i++) {
        final pIn = cam.p(inner, h, _curbZ[i]);
        final pGround = cam.p(inner, 0, _curbZ[i]);
        if (i == 0) {
          top.moveTo(pIn.dx, pIn.dy);
          face.moveTo(pGround.dx, pGround.dy);
        } else {
          top.lineTo(pIn.dx, pIn.dy);
          face.lineTo(pGround.dx, pGround.dy);
        }
      }
      for (var i = _curbZ.length - 1; i >= 0; i--) {
        final pOut = cam.p(outer, h, _curbZ[i]);
        final pIn = cam.p(inner, h, _curbZ[i]);
        top.lineTo(pOut.dx, pOut.dy);
        face.lineTo(pIn.dx, pIn.dy);
      }
      top.close();
      face.close();
      canvas
        ..drawPath(face, _fill(theme.curbFace))
        ..drawPath(top, _fill(theme.curbTop));
      final edge = Path();
      for (var i = 0; i < _curbZ.length; i++) {
        final pt = cam.p(inner, h, _curbZ[i]);
        if (i == 0) {
          edge.moveTo(pt.dx, pt.dy);
        } else {
          edge.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(edge, _stroke(_outline, _ink));
    }
  }

  // ------------------------------------------------------------- scenery

  static const double _propSpacing = 9;

  void _addProps(Canvas canvas, RunCamera cam, List<(double, VoidCallback)> out) {
    if (theme.highContrast) return;
    final from = ((engine.distance - 2) / _propSpacing).floor();
    final to = ((engine.distance + 92) / _propSpacing).floor();
    for (var n = from; n <= to; n++) {
      final z = n * _propSpacing - engine.distance;
      if (z < -1.5) continue;
      final hash = (n * 2654435761) & 0x7fffffff;
      for (final side in const [-1.0, 1.0]) {
        final x = side * (2.35 + ((hash >> (side < 0 ? 3 : 7)) % 3) * 0.45);
        final type = (hash >> (side < 0 ? 11 : 13)) % 3;
        out.add((z, () => _prop(canvas, cam, x, z, type)));
      }
    }
  }

  void _prop(Canvas canvas, RunCamera cam, double x, double z, int type) {
    final base = cam.p(x, 0, z);
    final s = cam.scale(z);
    final o = _stroke(math.max(1, _outline * s / cam.s0));
    switch (theme.scene) {
      case SceneKind.c:
        if (type == 1) {
          final spike = Path()
            ..moveTo(base.dx - 0.35 * s, base.dy)
            ..lineTo(base.dx, base.dy - 1.4 * s)
            ..lineTo(base.dx + 0.35 * s, base.dy)
            ..close();
          canvas
            ..drawPath(spike, _fill(theme.propDark))
            ..drawPath(spike, o);
        } else {
          final hgt = (type == 0 ? 1.3 : 0.8) * s;
          final wid = (type == 0 ? 0.42 : 0.3) * s;
          _glowDot(canvas, base.translate(0, -hgt * 0.5), wid * 1.6, theme.prop, 0.5);
          final crystal = Path()
            ..moveTo(base.dx - wid / 2, base.dy)
            ..lineTo(base.dx - wid / 2, base.dy - hgt * 0.75)
            ..lineTo(base.dx, base.dy - hgt)
            ..lineTo(base.dx + wid / 2, base.dy - hgt * 0.75)
            ..lineTo(base.dx + wid / 2, base.dy)
            ..close();
          canvas
            ..drawPath(crystal, _fill(type == 0 ? theme.prop : theme.propAccent))
            ..drawPath(crystal, o);
        }
      case SceneKind.cpp:
        if (type == 2) {
          final r = Rect.fromLTRB(base.dx - 0.4 * s, base.dy - 0.7 * s, base.dx + 0.4 * s, base.dy);
          canvas
            ..drawRect(r, _fill(theme.prop))
            ..drawRect(r, o);
        } else {
          final pole = Rect.fromLTRB(base.dx - 0.06 * s, base.dy - 1.7 * s, base.dx + 0.06 * s, base.dy);
          canvas
            ..drawRect(pole, _fill(theme.propDark))
            ..drawRect(pole, o);
          if (type == 0) {
            final flame = base.translate(0, -1.85 * s);
            _glowDot(canvas, flame, 0.35 * s, theme.propAccent, 0.8);
            canvas.drawOval(
              Rect.fromCenter(center: flame, width: 0.22 * s, height: (0.32 + 0.06 * math.sin(_t * 12 + x)) * s),
              _fill(theme.propAccent),
            );
          } else {
            final wave = math.sin(_t * 4 + z) * 0.08 * s;
            final flag = Path()
              ..moveTo(base.dx, base.dy - 1.65 * s)
              ..lineTo(base.dx + 0.6 * s * (x < 0 ? 1 : -1), base.dy - 1.5 * s + wave)
              ..lineTo(base.dx, base.dy - 1.3 * s)
              ..close();
            canvas
              ..drawPath(flag, _fill(const Color(0xFFFF6B7F)))
              ..drawPath(flag, o);
          }
        }
      case SceneKind.java:
        if (type == 1) {
          _glowDot(canvas, base.translate(0, -0.1 * s), 0.6 * s, theme.propAccent, 0.7);
          canvas.drawOval(Rect.fromCenter(center: base, width: 0.9 * s, height: 0.25 * s), _fill(theme.propAccent));
          final k = (_t * 1.5 + z) % 1;
          canvas.drawCircle(base.translate(0, -k * 1.2 * s), 0.08 * s, _fill(const Color(0xFFFFC93C).withValues(alpha: 1 - k)));
        } else if (type == 2) {
          final trunk = _stroke(0.1 * s, theme.propDark);
          canvas
            ..drawLine(base, base.translate(0, -1.3 * s), trunk)
            ..drawLine(base.translate(0, -0.8 * s), base.translate(-0.4 * s, -1.2 * s), trunk)
            ..drawLine(base.translate(0, -1.0 * s), base.translate(0.35 * s, -1.4 * s), trunk);
        } else {
          final rock = Path()
            ..moveTo(base.dx - 0.5 * s, base.dy)
            ..lineTo(base.dx - 0.35 * s, base.dy - 0.45 * s)
            ..lineTo(base.dx + 0.05 * s, base.dy - 0.65 * s)
            ..lineTo(base.dx + 0.45 * s, base.dy - 0.3 * s)
            ..lineTo(base.dx + 0.5 * s, base.dy)
            ..close();
          canvas
            ..drawPath(rock, _fill(theme.prop))
            ..drawPath(rock, o)
            ..drawLine(base.translate(-0.15 * s, -0.1 * s), base.translate(0.1 * s, -0.4 * s),
                _stroke(math.max(1, 0.04 * s), theme.propAccent));
        }
      default:
        if (type == 1) {
          // Ancient temple pillar.
          final col = Rect.fromLTRB(base.dx - 0.22 * s, base.dy - 1.8 * s, base.dx + 0.22 * s, base.dy);
          final cap = Rect.fromLTRB(base.dx - 0.32 * s, base.dy - 2.0 * s, base.dx + 0.32 * s, base.dy - 1.8 * s);
          canvas
            ..drawRect(col, _fill(theme.propAccent))
            ..drawRect(col, o)
            ..drawRect(cap, _fill(theme.propAccent))
            ..drawRect(cap, o);
          for (final k in const [0.3, 0.9, 1.4]) {
            canvas.drawLine(base.translate(-0.22 * s, -k * s), base.translate(0.22 * s, -k * s), _stroke(math.max(1, 0.03 * s)));
          }
          canvas.drawCircle(base.translate(0.15 * s, -1.75 * s), 0.12 * s, _fill(const Color(0xFF2FBF73)));
        } else if (type == 2) {
          canvas
            ..drawCircle(base.translate(-0.2 * s, -0.25 * s), 0.32 * s, _fill(theme.prop))
            ..drawCircle(base.translate(0.2 * s, -0.3 * s), 0.36 * s, _fill(const Color(0xFF26A06A)));
        } else {
          final trunk = Rect.fromLTRB(base.dx - 0.09 * s, base.dy - 1.2 * s, base.dx + 0.09 * s, base.dy);
          canvas
            ..drawRect(trunk, _fill(theme.propDark))
            ..drawCircle(base.translate(0, -1.5 * s), 0.55 * s, _fill(theme.prop))
            ..drawCircle(base.translate(0, -1.5 * s), 0.55 * s, o)
            ..drawCircle(base.translate(-0.18 * s, -1.65 * s), 0.18 * s, _fill(const Color(0xFF3CC08F)));
        }
    }
  }

  // ---------------------------------------------------------------- items

  void _item(Canvas canvas, RunCamera cam, RunItem item, double z) {
    switch (item.kind) {
      case RunItemKind.coin:
        _coin(canvas, cam, item.lane - 1.0, 0.42 + item.height, z, item.pos);
      case RunItemKind.hurdle:
        _hurdle(canvas, cam, item, z);
      case RunItemKind.overhead:
        _overhead(canvas, cam, z);
      case RunItemKind.block:
        _block(canvas, cam, item.lane - 1.0, z);
      case RunItemKind.gate:
        _gates(canvas, cam, z);
      case RunItemKind.hintOrb:
        _hintOrb(canvas, cam, item.lane - 1.0, z);
      case RunItemKind.shield:
        _shield(canvas, cam, item.lane - 1.0, z);
      case RunItemKind.finish:
        _finish(canvas, cam, z);
    }
  }

  /// Front + top (+ inner side) of a box, outlined in ink.
  void _box(Canvas canvas, RunCamera cam, double x0, double x1, double y0, double y1, double z0, double z1,
      {required Color front, required Color top, Color? side}) {
    final o = _stroke(_outline);
    final sideColor = side ?? Color.lerp(front, Colors.black, 0.25)!;
    final mid = (x0 + x1) / 2;
    if (mid < -0.05 || mid > 0.05) {
      final xs = mid < 0 ? x1 : x0;
      final sidePath = Path()
        ..moveTo(cam.p(xs, y0, z0).dx, cam.p(xs, y0, z0).dy)
        ..lineTo(cam.p(xs, y0, z1).dx, cam.p(xs, y0, z1).dy)
        ..lineTo(cam.p(xs, y1, z1).dx, cam.p(xs, y1, z1).dy)
        ..lineTo(cam.p(xs, y1, z0).dx, cam.p(xs, y1, z0).dy)
        ..close();
      canvas
        ..drawPath(sidePath, _fill(sideColor))
        ..drawPath(sidePath, o);
    }
    final topPath = _quad(cam, x0, x1, y1, z0, z1);
    canvas
      ..drawPath(topPath, _fill(top))
      ..drawPath(topPath, o);
    final r = Rect.fromPoints(cam.p(x0, y1, z0), cam.p(x1, y0, z0));
    canvas
      ..drawRect(r, _fill(front))
      ..drawRect(r, o);
  }

  void _coin(Canvas canvas, RunCamera cam, double x, double y, double z, double seed) {
    final c = cam.p(x, y, z);
    final s = cam.scale(z);
    final r = 0.17 * s;
    if (r < 0.8) return;
    final spin = (math.cos(_t * 5 + seed) * 0.85).abs() + 0.15;
    final rect = Rect.fromCenter(center: c, width: r * 2 * spin, height: r * 2);
    canvas
      ..drawOval(rect, _fill(theme.highContrast ? const Color(0xFFFFFF00) : const Color(0xFFFFC93C)))
      ..drawOval(rect.deflate(r * 0.28), _fill(const Color(0xFFFFE07A)))
      ..drawOval(rect, _stroke(math.max(1, r * 0.18), theme.highContrast ? Colors.white : const Color(0xFFC9781F)));
  }

  void _hurdle(Canvas canvas, RunCamera cam, RunItem item, double z) {
    final lanes = item.lanes.isEmpty ? [item.lane] : item.lanes;
    final x0 = lanes.reduce(math.min) - 1.5;
    final x1 = lanes.reduce(math.max) - 0.5;
    final s = cam.scale(z);
    if (theme.scene == SceneKind.java && !theme.highContrast) {
      // A river of lava across the path: jump it.
      final pool = _quad(cam, x0, x1, 0.01, z - 0.6, z + 0.6);
      canvas
        ..drawPath(pool, _fill(theme.hurdleDark))
        ..drawPath(_quad(cam, x0 + 0.1, x1 - 0.1, 0.02, z - 0.35, z + 0.35), _fill(theme.hurdle))
        ..drawPath(pool, _stroke(_outline));
      for (var i = 0; i < 4; i++) {
        final k = (_t * 1.6 + i * 0.27) % 1;
        final bx = x0 + 0.3 + (x1 - x0 - 0.6) * ((i * 37) % 10) / 10;
        canvas.drawCircle(cam.p(bx, 0.05 + k * 0.25, z), 0.06 * s * (1 - k) + 0.5, _fill(const Color(0xFFFFE07A)));
      }
    } else {
      _box(canvas, cam, x0 + 0.04, x1 - 0.04, 0, 0.44, z, z + 0.42,
          front: theme.hurdle, top: Color.lerp(theme.hurdle, Colors.white, 0.2)!, side: theme.hurdleDark);
      final face = Rect.fromPoints(cam.p(x0, 0.44, z), cam.p(x1, 0, z));
      final detail = _stroke(math.max(1, 0.03 * s), theme.hurdleDark);
      switch (theme.scene) {
        case SceneKind.cpp:
          for (final fy in const [0.33, 0.66]) {
            canvas.drawLine(Offset(face.left, face.top + face.height * fy), Offset(face.right, face.top + face.height * fy), detail);
          }
        case SceneKind.python:
          for (final end in [face.left + face.height * 0.35, face.right - face.height * 0.35]) {
            canvas
              ..drawCircle(Offset(end, face.center.dy), face.height * 0.32, _fill(const Color(0xFFD9A066)))
              ..drawCircle(Offset(end, face.center.dy), face.height * 0.32, detail)
              ..drawCircle(Offset(end, face.center.dy), face.height * 0.14, detail);
          }
        default:
          canvas.drawLine(Offset(face.left, face.center.dy), Offset(face.right, face.center.dy), detail);
      }
    }
    _arrowHint(canvas, cam, (x0 + x1) / 2, 0.85, z, up: true);
  }

  void _overhead(Canvas canvas, RunCamera cam, double z) {
    const x0 = -_half - 0.12;
    const x1 = _half + 0.12;
    final s = cam.scale(z);
    for (final x in const [x0, x1]) {
      _box(canvas, cam, x - 0.08, x + 0.08, 0, 1.3, z, z + 0.16,
          front: theme.overheadAccent, top: theme.overheadAccent, side: Color.lerp(theme.overheadAccent, Colors.black, 0.3));
    }
    if (theme.scene == SceneKind.java && !theme.highContrast) {
      final bar = Rect.fromPoints(cam.p(x0, 1.18, z), cam.p(x1, 0.9, z));
      _glowDot(canvas, bar.center, bar.width * 0.25, theme.overhead, 0.5 + 0.2 * math.sin(_t * 9));
      canvas
        ..drawRRect(RRect.fromRectAndRadius(bar, Radius.circular(bar.height / 2)), _fill(theme.overhead))
        ..drawRRect(RRect.fromRectAndRadius(bar.deflate(bar.height * 0.25), Radius.circular(bar.height / 2)),
            _fill(const Color(0xFFFFF1B8)));
      for (var i = 0; i < 7; i++) {
        final fx = bar.left + bar.width * (i + 0.5) / 7;
        final flick = 0.6 + 0.4 * math.sin(_t * 14 + i * 2);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(fx, bar.bottom + 0.06 * s), width: 0.12 * s, height: 0.22 * s * flick),
          _fill(const Color(0xFFFF7A2E)),
        );
      }
    } else {
      _box(canvas, cam, x0, x1, 0.92, 1.2, z, z + 0.24,
          front: theme.overheadAccent, top: Color.lerp(theme.overheadAccent, Colors.white, 0.15)!);
      final beam = Rect.fromPoints(cam.p(x0, 1.2, z), cam.p(x1, 0.92, z));
      switch (theme.scene) {
        case SceneKind.python:
          final vine = _stroke(math.max(1.5, 0.05 * s), theme.overhead);
          for (var i = 0; i < 9; i++) {
            final vx = beam.left + beam.width * (i + 0.5) / 9;
            final len = (0.2 + 0.12 * ((i * 7) % 3)) * s;
            final sway = math.sin(_t * 3 + i) * 0.04 * s;
            canvas
              ..drawLine(Offset(vx, beam.bottom), Offset(vx + sway, beam.bottom + len), vine)
              ..drawCircle(Offset(vx + sway, beam.bottom + len), 0.06 * s, _fill(theme.overhead));
          }
        case SceneKind.c:
          for (var i = 0; i < 10; i++) {
            final vx = beam.left + beam.width * (i + 0.5) / 10;
            final len = (0.16 + 0.1 * ((i * 5) % 3)) * s;
            final spike = Path()
              ..moveTo(vx - 0.07 * s, beam.bottom)
              ..lineTo(vx + 0.07 * s, beam.bottom)
              ..lineTo(vx, beam.bottom + len)
              ..close();
            canvas
              ..drawPath(spike, _fill(theme.overhead))
              ..drawPath(spike, _stroke(math.max(1, 0.02 * s)));
          }
        case SceneKind.cpp:
          for (var i = 0; i < 6; i++) {
            final vx = beam.left + beam.width * (i + 0.5) / 6;
            final pennant = Path()
              ..moveTo(vx - 0.12 * s, beam.bottom)
              ..lineTo(vx + 0.12 * s, beam.bottom)
              ..lineTo(vx, beam.bottom + 0.22 * s)
              ..close();
            canvas
              ..drawPath(pennant, _fill(i.isEven ? theme.blockAccent : const Color(0xFFFF6B7F)))
              ..drawPath(pennant, _stroke(math.max(1, 0.02 * s)));
          }
        default:
          break;
      }
    }
    _arrowHint(canvas, cam, 0, 0.55, z, up: false);
  }

  /// Small chevrons that tell beginners what to do: jump (up) or slide (down).
  void _arrowHint(Canvas canvas, RunCamera cam, double x, double y, double z, {required bool up}) {
    if (z > 38 || z < 2) return;
    final c = cam.p(x, y, z);
    final s = cam.scale(z) * 0.14;
    final dir = up ? -1.0 : 1.0;
    final paint = _stroke(math.max(2, s * 0.35), theme.highContrast ? Colors.white : const Color(0xFFFFF4D6));
    final wobble = math.sin(_t * 8) * s * 0.2 * dir;
    for (var k = 0; k < 2; k++) {
      final tipY = c.dy + wobble + dir * (k * s * 0.9 + s * 0.5);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - s, tipY - dir * s)
          ..lineTo(c.dx, tipY)
          ..lineTo(c.dx + s, tipY - dir * s),
        paint,
      );
    }
  }

  void _block(Canvas canvas, RunCamera cam, double x, double z) {
    final s = cam.scale(z);
    switch (theme.highContrast ? SceneKind.menu : theme.scene) {
      case SceneKind.c:
        _glowDot(canvas, cam.p(x, 0.6, z), 0.7 * s, theme.block, 0.4);
        for (final (dx, hgt, wid) in const [(-0.22, 1.0, 0.3), (0.2, 0.85, 0.28), (0.0, 1.45, 0.38)]) {
          final b = cam.p(x + dx, 0, z);
          final crystal = Path()
            ..moveTo(b.dx - wid / 2 * s, b.dy)
            ..lineTo(b.dx - wid / 2 * s, b.dy - hgt * 0.75 * s)
            ..lineTo(b.dx, b.dy - hgt * s)
            ..lineTo(b.dx + wid / 2 * s, b.dy - hgt * 0.75 * s)
            ..lineTo(b.dx + wid / 2 * s, b.dy)
            ..close();
          canvas
            ..drawPath(crystal, _fill(dx == 0 ? theme.block : theme.blockAccent))
            ..drawPath(crystal, _stroke(_outline))
            ..drawLine(Offset(b.dx, b.dy - hgt * s), Offset(b.dx, b.dy), _stroke(math.max(1, 0.03 * s), Colors.white54));
        }
      case SceneKind.java:
        final c = cam.p(x, 0.55, z);
        final r = 0.55 * s;
        final rock = Path();
        for (var i = 0; i <= 9; i++) {
          final a = math.pi * 2 * i / 9;
          final rr = r * (0.85 + 0.15 * math.sin(i * 2.7));
          final pt = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr * 0.95);
          if (i == 0) {
            rock.moveTo(pt.dx, pt.dy);
          } else {
            rock.lineTo(pt.dx, pt.dy);
          }
        }
        rock.close();
        canvas
          ..drawPath(rock, _fill(theme.block))
          ..drawPath(rock, _stroke(_outline))
          ..drawPath(
            Path()
              ..moveTo(c.dx - r * 0.5, c.dy - r * 0.2)
              ..lineTo(c.dx - r * 0.1, c.dy + r * 0.1)
              ..lineTo(c.dx + r * 0.3, c.dy - r * 0.3)
              ..moveTo(c.dx - r * 0.1, c.dy + r * 0.1)
              ..lineTo(c.dx, c.dy + r * 0.6),
            _stroke(math.max(1.5, 0.05 * s), theme.blockAccent),
          );
      case SceneKind.cpp:
        for (final (y0, y1, dx) in const [(0.0, 0.7, 0.0), (0.7, 1.35, 0.06)]) {
          _box(canvas, cam, x - 0.38 + dx, x + 0.38 + dx, y0, y1, z, z + 0.6,
              front: theme.block, top: Color.lerp(theme.block, Colors.white, 0.2)!, side: theme.blockDark);
          final f = Rect.fromPoints(cam.p(x - 0.38 + dx, y1, z), cam.p(x + 0.38 + dx, y0, z));
          final plank = _stroke(math.max(1, 0.03 * s), theme.blockDark);
          canvas
            ..drawLine(f.topLeft, f.bottomRight, plank)
            ..drawLine(f.topRight, f.bottomLeft, plank);
        }
      case SceneKind.python:
        _box(canvas, cam, x - 0.4, x + 0.4, 0, 1.35, z, z + 0.55,
            front: theme.block, top: theme.blockAccent, side: theme.blockDark);
        final f = Rect.fromPoints(cam.p(x - 0.4, 1.35, z), cam.p(x + 0.4, 0, z));
        final eye = _fill(_ink);
        canvas
          ..drawRect(Rect.fromLTWH(f.left + f.width * 0.2, f.top + f.height * 0.3, f.width * 0.18, f.height * 0.1), eye)
          ..drawRect(Rect.fromLTWH(f.right - f.width * 0.38, f.top + f.height * 0.3, f.width * 0.18, f.height * 0.1), eye)
          ..drawRect(Rect.fromLTWH(f.left + f.width * 0.3, f.top + f.height * 0.58, f.width * 0.4, f.height * 0.06), eye)
          ..drawRect(Rect.fromLTWH(f.left, f.top, f.width, f.height * 0.08), _fill(theme.blockAccent));
      default:
        _box(canvas, cam, x - 0.4, x + 0.4, 0, 1.35, z, z + 0.55,
            front: theme.block, top: theme.blockDark, side: theme.blockDark);
        final f = Rect.fromPoints(cam.p(x - 0.4, 1.35, z), cam.p(x + 0.4, 0, z));
        canvas
          ..drawLine(f.topLeft, f.bottomRight, _stroke(math.max(2, 0.06 * s), Colors.white))
          ..drawLine(f.topRight, f.bottomLeft, _stroke(math.max(2, 0.06 * s), Colors.white));
    }
  }

  void _hintOrb(Canvas canvas, RunCamera cam, double x, double z) {
    final s = cam.scale(z);
    final c = cam.p(x, 0.8 + math.sin(_t * 3) * 0.08, z);
    final r = 0.22 * s;
    if (r < 1) return;
    _glowDot(canvas, c, r * 1.6, const Color(0xFFFFE066), 0.9);
    canvas
      ..drawRect(Rect.fromCenter(center: c.translate(0, r * 1.05), width: r * 0.9, height: r * 0.5), _fill(const Color(0xFFB8BED0)))
      ..drawCircle(c, r, _fill(const Color(0xFFFFE066)))
      ..drawCircle(c, r, _stroke(math.max(1, r * 0.15)))
      ..drawCircle(c.translate(-r * 0.3, -r * 0.3), r * 0.25, _fill(Colors.white.withValues(alpha: 0.8)));
  }

  void _shield(Canvas canvas, RunCamera cam, double x, double z) {
    final s = cam.scale(z);
    final c = cam.p(x, 0.85 + math.sin(_t * 3 + 1) * 0.08, z);
    final r = 0.26 * s;
    if (r < 1) return;
    _glowDot(canvas, c, r * 1.6, const Color(0xFF5BC0FF), 0.9);
    final crest = Path()
      ..moveTo(c.dx - r, c.dy - r * 0.8)
      ..quadraticBezierTo(c.dx, c.dy - r * 1.2, c.dx + r, c.dy - r * 0.8)
      ..quadraticBezierTo(c.dx + r * 0.95, c.dy + r * 0.5, c.dx, c.dy + r * 1.1)
      ..quadraticBezierTo(c.dx - r * 0.95, c.dy + r * 0.5, c.dx - r, c.dy - r * 0.8)
      ..close();
    canvas
      ..drawPath(crest, _fill(const Color(0xFF5BC0FF)))
      ..drawPath(crest, _stroke(math.max(1, r * 0.14)))
      ..drawLine(c.translate(0, -r * 0.6), c.translate(0, r * 0.6), _stroke(math.max(1, r * 0.16), Colors.white))
      ..drawLine(c.translate(-r * 0.5, -r * 0.1), c.translate(r * 0.5, -r * 0.1), _stroke(math.max(1, r * 0.16), Colors.white));
  }

  void _gates(Canvas canvas, RunCamera cam, double z) {
    final q = engine.session.current;
    if (q == null) return;
    final close = z < 34;
    final s = cam.scale(z);
    for (var i = 0; i < q.options.length && i < RunEngine.laneCount; i++) {
      final cx = i - 1.0;
      final hidden = engine.session.isHidden(i);
      final selected = engine.lane == i && !hidden;
      for (final dx in const [-0.46, 0.46]) {
        _box(canvas, cam, cx + dx - 0.05, cx + dx + 0.05, 0, 1.64, z, z + 0.1,
            front: hidden ? const Color(0xFF6B6478) : accent, top: hidden ? const Color(0xFF8A8396) : accent);
      }
      final sign = Rect.fromPoints(cam.p(cx - 0.5, 1.64, z), cam.p(cx + 0.5, 1.16, z));
      final rr = RRect.fromRectAndRadius(sign, Radius.circular(sign.height * 0.22));
      if (selected && close) _glowDot(canvas, sign.center, sign.width * 0.6, const Color(0xFFFFC93C), 0.9);
      final face = hidden
          ? const Color(0xFF4A4458)
          : selected && close
              ? const Color(0xFFFFC93C)
              : const Color(0xFFFFF4D6);
      canvas
        ..drawRRect(rr.shift(Offset(0, sign.height * 0.08)), _fill(theme.highContrast ? Colors.white : const Color(0xFF2B1840)))
        ..drawRRect(rr, _fill(face))
        ..drawRRect(rr, _stroke(math.max(1.5, 0.035 * s), theme.highContrast ? Colors.white : const Color(0xFF2B1840)));
      // Number badge.
      final badgeC = Offset(sign.left + sign.height * 0.42, sign.center.dy);
      final badgeR = sign.height * 0.27;
      canvas
        ..drawCircle(badgeC, badgeR, _fill(hidden ? const Color(0xFF8A8396) : accent))
        ..drawCircle(badgeC, badgeR, _stroke(math.max(1, 0.025 * s), const Color(0xFF2B1840)));
      _text(canvas, '${i + 1}', Rect.fromCircle(center: badgeC, radius: badgeR * 0.8), display: true);
      final textBox = Rect.fromLTRB(badgeC.dx + badgeR * 1.3, sign.top + sign.height * 0.18, sign.right - sign.height * 0.2,
          sign.bottom - sign.height * 0.18);
      _text(canvas, hidden ? '×' : q.options[i], textBox,
          color: hidden ? const Color(0xFFD9D2E6) : const Color(0xFF2B1840));
      if (hidden) {
        // Striped barrier: this answer was removed by the hint.
        final bar = Rect.fromPoints(cam.p(cx - 0.42, 0.62, z), cam.p(cx + 0.42, 0.34, z));
        canvas
          ..drawRect(bar, _fill(Colors.white))
          ..save()
          ..clipRect(bar);
        final stripe = _fill(const Color(0xFFFF6B7F));
        for (var k = -2; k < 8; k++) {
          final x0 = bar.left + k * bar.height * 1.2;
          canvas.drawPath(
            Path()
              ..moveTo(x0, bar.bottom)
              ..lineTo(x0 + bar.height * 0.6, bar.bottom)
              ..lineTo(x0 + bar.height * 1.2, bar.top)
              ..lineTo(x0 + bar.height * 0.6, bar.top)
              ..close(),
            stripe,
          );
        }
        canvas
          ..restore()
          ..drawRect(bar, _stroke(math.max(1, 0.03 * s)));
      }
    }
  }

  void _finish(Canvas canvas, RunCamera cam, double z) {
    final s = cam.scale(z);
    for (final x in const [-1.85, 1.85]) {
      _box(canvas, cam, x - 0.14, x + 0.14, 0, 2.6, z, z + 0.28, front: accent, top: accent);
    }
    final banner = Rect.fromPoints(cam.p(-1.85, 2.6, z), cam.p(1.85, 2.05, z));
    canvas
      ..drawRect(banner, _fill(Colors.white))
      ..save()
      ..clipRect(banner);
    final sq = banner.height / 2;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col * sq < banner.width; col++) {
        if ((row + col).isEven) {
          canvas.drawRect(Rect.fromLTWH(banner.left + col * sq, banner.top + row * sq, sq, sq), _fill(const Color(0xFF2B1840)));
        }
      }
    }
    canvas.restore();
    final label = Rect.fromCenter(center: banner.center, width: banner.width * 0.5, height: banner.height * 0.9);
    canvas
      ..drawRRect(RRect.fromRectAndRadius(label, Radius.circular(label.height * 0.25)), _fill(const Color(0xFFFFC93C)))
      ..drawRect(banner, _stroke(math.max(1.5, 0.04 * s)));
    _text(canvas, 'FINISH', label.deflate(label.height * 0.12), display: true);
  }

  void _text(Canvas canvas, String text, Rect box, {bool display = false, Color color = const Color(0xFF2B1840)}) {
    if (box.height < 4 || box.width < 4) return;
    final key = '$display|${color.toARGB32()}|$text';
    final tp = _textCache.putIfAbsent(key, () {
      if (_textCache.length > 200) _textCache.clear();
      return TextPainter(
        text: TextSpan(
          text: text,
          style: display
              ? TextStyle(fontFamily: displayFont, fontSize: 40, color: color)
              : TextStyle(fontFamily: codeFont, fontSize: 40, fontWeight: FontWeight.w700, color: color),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
    });
    final scale = math.min(box.width / tp.width, box.height / tp.height);
    canvas
      ..save()
      ..translate(box.center.dx - tp.width * scale / 2, box.center.dy - tp.height * scale / 2)
      ..scale(scale);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  // ---------------------------------------------------------- the runner

  void _runner(Canvas canvas, RunCamera cam) {
    final x = engine.laneX - 1;
    final feet = cam.p(x, engine.height, 0);
    final ground = cam.p(x, 0, 0);
    final k = cam.s0 / 118;
    final shadowW = 0.55 * cam.s0 * (1 - engine.height / 3);
    canvas.drawOval(
      Rect.fromCenter(center: ground, width: shadowW, height: shadowW * 0.24),
      _fill(Colors.black.withValues(alpha: 0.28)),
    );
    canvas
      ..save()
      ..translate(feet.dx, feet.dy)
      ..scale(k);
    if (engine.stumble > 0) canvas.rotate(math.sin(_t * 30) * 0.12);
    if (engine.sliding) {
      final squash = 0.55 + 0.45 * (engine.slideProgress < 0.15 ? 1 - engine.slideProgress / 0.15 : 0);
      canvas.scale(1.12, squash);
    }
    _figure(canvas);
    canvas.restore();
    if (engine.shield) {
      final c = cam.p(x, engine.height + 0.45, 0);
      canvas
        ..drawCircle(c, 0.5 * cam.s0, _fill(const Color(0xFF5BC0FF).withValues(alpha: 0.18)))
        ..drawCircle(c, 0.5 * cam.s0, _stroke(3, const Color(0xFF5BC0FF).withValues(alpha: 0.8)));
    }
  }

  /// The runner from behind, feet at (0, 0), about 92 units tall.
  void _figure(Canvas canvas) {
    final phase = engine.distance * 1.7;
    final air = engine.jumping;
    final outline = _stroke(3, theme.highContrast ? Colors.white : const Color(0xFF2B1840));
    final legLift = air ? (8.0, 8.0) : (math.max(0.0, math.sin(phase)) * 10, math.max(0.0, -math.sin(phase)) * 10);
    for (final (dx, lift) in [(-9.0, legLift.$1), (9.0, legLift.$2)]) {
      final leg = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(dx, -16 - lift), width: 11, height: 26),
        const Radius.circular(5),
      );
      final shoe = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(dx, -4 - lift), width: 14, height: 8),
        const Radius.circular(4),
      );
      canvas
        ..drawRRect(leg, _fill(const Color(0xFF3B2A5E)))
        ..drawRRect(leg, outline)
        ..drawRRect(shoe, _fill(const Color(0xFFFFF4D6)))
        ..drawRRect(shoe, outline);
    }
    final bob = air ? 0.0 : math.sin(phase * 2).abs() * 3;
    final top = -66 - bob;
    final swing = air ? -14.0 : math.sin(phase) * 12;
    final skin = Paint()
      ..color = const Color(0xFFFFCFA3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final armOutline = Paint()
      ..color = theme.highContrast ? Colors.white : const Color(0xFF2B1840)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    for (final (side, s) in [(-1.0, swing), (1.0, air ? swing : -swing)]) {
      final from = Offset(side * 18, top + 12);
      final to = Offset(side * (air ? 30 : 26), top + (air ? 0 : 32) + s * 0.6);
      canvas
        ..drawLine(from, to, armOutline)
        ..drawLine(from, to, skin);
    }
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(-20, top + 4, 40, 40), const Radius.circular(13));
    canvas
      ..drawRRect(body, _fill(runnerShirt))
      ..drawRRect(body, outline);
    final pack = RRect.fromRectAndRadius(Rect.fromLTWH(-13, top + 10, 26, 26), const Radius.circular(7));
    canvas
      ..drawRRect(pack, _fill(const Color(0xFFFFC93C)))
      ..drawRRect(pack, outline);
    _text(canvas, '</>', Rect.fromLTWH(-10, top + 15, 20, 14), display: true);
    final head = Offset(0, top - 8);
    canvas
      ..drawCircle(head, 15, _fill(const Color(0xFF4A2C1A)))
      ..drawCircle(head, 15, outline)
      ..drawLine(head.translate(-14, 2), head.translate(14, 2), Paint()
        ..color = const Color(0xFFFF6B7F)
        ..strokeWidth = 5);
  }

  // ---------------------------------------------------------- the monster

  void _monster(Canvas canvas, RunCamera cam) {
    final chase = engine.chase;
    if (chase <= 0.01) return;
    final eased = Curves.easeOutBack.transform(chase.clamp(0.0, 1.0));
    final size = cam.s0 * 1.45;
    final x = cam.cx + (engine.laneX - 1) * cam.s0 * 0.45 + math.sin(_t * 7) * 6;
    final y = cam.h + size * 0.3 - eased * size * 0.62;
    canvas
      ..save()
      ..translate(x, y)
      ..scale(size / 100);
    final ink = _stroke(4, theme.highContrast ? Colors.white : const Color(0xFF2B1840));
    // Legs scuttling.
    final leg = _stroke(7, theme.highContrast ? Colors.white : const Color(0xFF2B1840));
    for (var i = 0; i < 3; i++) {
      final wig = math.sin(_t * 18 + i * 2) * 6;
      canvas
        ..drawLine(Offset(-30, 10.0 + i * 12), Offset(-58, 18.0 + i * 14 + wig), leg)
        ..drawLine(Offset(30, 10.0 + i * 12), Offset(58, 18.0 + i * 14 - wig), leg);
    }
    final body = Rect.fromCenter(center: const Offset(0, 20), width: 96, height: 80);
    canvas
      ..drawOval(body, _fill(theme.highContrast ? const Color(0xFFB000FF) : const Color(0xFF6A2FA0)))
      ..drawOval(Rect.fromCenter(center: const Offset(0, 34), width: 60, height: 40), _fill(const Color(0xFF9B6BD6)))
      ..drawOval(body, ink);
    // Antennae with glowing tips.
    for (final side in const [-1.0, 1.0]) {
      final tip = Offset(side * 30 + math.sin(_t * 6 + side) * 4, -44);
      canvas
        ..drawPath(Path()
          ..moveTo(side * 14, -14)
          ..quadraticBezierTo(side * 18, -36, tip.dx, tip.dy), _stroke(4, const Color(0xFF2B1840)))
        ..drawCircle(tip, 6, _fill(const Color(0xFFFFC93C)));
    }
    // Angry eyes looking up at the runner.
    for (final side in const [-1.0, 1.0]) {
      final eye = Offset(side * 20, 4);
      canvas
        ..drawCircle(eye, 14, _fill(Colors.white))
        ..drawCircle(eye, 14, ink)
        ..drawCircle(eye.translate(0, -4), 6, _fill(const Color(0xFF2B1840)))
        ..drawLine(eye.translate(-side * 14, -18), eye.translate(side * 10, -10), _stroke(6, const Color(0xFF2B1840)));
    }
    // Snapping jaws.
    final snap = math.sin(_t * 12).abs() * 6;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(side * 8, 40)
          ..quadraticBezierTo(side * (18 + snap), 52, side * 4, 60)
          ..close(),
        _fill(const Color(0xFFFFF4D6)),
      );
    }
    canvas.restore();
  }

  // ------------------------------------------------------------- effects

  void _speedLines(Canvas canvas, RunCamera cam) {
    if (engine.boost <= 0 || theme.highContrast) return;
    final a = (engine.boost / 1.6).clamp(0.0, 1.0);
    final paint = _stroke(3, Colors.white.withValues(alpha: 0.55 * a));
    final vp = Offset(cam.cx, cam.horizon);
    for (var i = 0; i < 16; i++) {
      final ang = (i / 16) * math.pi * 2 + 0.2;
      final k = (_t * 2.5 + i * 0.37) % 1;
      final r1 = cam.w * (0.35 + k * 0.5);
      final r2 = r1 + cam.w * 0.12;
      final dir = Offset(math.cos(ang), math.sin(ang) * 0.6);
      canvas.drawLine(vp + dir * r1, vp + dir * r2, paint);
    }
  }

  void _particles(Canvas canvas, Size size) {
    for (final p in fx._particles) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * size.shortestSide * (0.5 + a * 0.5),
        _fill(p.color.withValues(alpha: a)),
      );
    }
  }

  @override
  bool shouldRepaint(RunWorldPainter old) => true;
}
