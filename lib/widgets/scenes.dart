// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// The painted backgrounds that make every world feel like a place.
enum SceneKind { menu, python, c, cpp, java, victory, defeat }

SceneKind sceneFor(Lang lang) => switch (lang) {
      Lang.python => SceneKind.python,
      Lang.c => SceneKind.c,
      Lang.cpp => SceneKind.cpp,
      Lang.java => SceneKind.java,
    };

/// Colours game screens use to draw on top of a scene (roads, platforms).
@immutable
class ScenePalette {
  const ScenePalette({
    required this.ground,
    required this.groundDark,
    required this.road,
    required this.roadEdge,
    required this.stripe,
    required this.platform,
    required this.platformTop,
    required this.prop,
    required this.propAccent,
  });

  final Color ground;
  final Color groundDark;
  final Color road;
  final Color roadEdge;
  final Color stripe;
  final Color platform;
  final Color platformTop;

  /// Roadside decoration colours (trees, crystals, torches, rocks).
  final Color prop;
  final Color propAccent;

  static const ScenePalette highContrast = ScenePalette(
    ground: Colors.black,
    groundDark: Colors.black,
    road: Colors.black,
    roadEdge: Colors.white,
    stripe: Colors.white,
    platform: Colors.black,
    platformTop: Colors.white,
    prop: Colors.white,
    propAccent: Colors.white,
  );
}

ScenePalette paletteFor(SceneKind kind, {bool highContrast = false}) {
  if (highContrast) return ScenePalette.highContrast;
  return switch (kind) {
    SceneKind.python => const ScenePalette(
        ground: Color(0xFF1F8A5B),
        groundDark: Color(0xFF0E5A3D),
        road: Color(0xFFD4A86E),
        roadEdge: Color(0xFF7A5530),
        stripe: Color(0xFFFFF4D6),
        platform: Color(0xFF1E8A5B),
        platformTop: Color(0xFF6BE0A4),
        prop: Color(0xFF187A50),
        propAccent: Color(0xFF5B3A22),
      ),
    SceneKind.c => const ScenePalette(
        ground: Color(0xFF1A2A5E),
        groundDark: Color(0xFF0B1438),
        road: Color(0xFF3A4C8C),
        roadEdge: Color(0xFF5BE7FF),
        stripe: Color(0xFFCDEBFF),
        platform: Color(0xFF2A3C7A),
        platformTop: Color(0xFF6E8EE6),
        prop: Color(0xFF5BE7FF),
        propAccent: Color(0xFFB98CFF),
      ),
    SceneKind.cpp => const ScenePalette(
        ground: Color(0xFF3A2470),
        groundDark: Color(0xFF1C0E3D),
        road: Color(0xFF7A68A8),
        roadEdge: Color(0xFFC3A0FF),
        stripe: Color(0xFFFFF4D6),
        platform: Color(0xFF5A4590),
        platformTop: Color(0xFFA48FE0),
        prop: Color(0xFF2A1858),
        propAccent: Color(0xFFFFC93C),
      ),
    SceneKind.java => const ScenePalette(
        ground: Color(0xFF3A1410),
        groundDark: Color(0xFF1F0808),
        road: Color(0xFF52241B),
        roadEdge: Color(0xFFFF7A2E),
        stripe: Color(0xFFFFC93C),
        platform: Color(0xFF5A2418),
        platformTop: Color(0xFF9A4A2A),
        prop: Color(0xFF2A0D0A),
        propAccent: Color(0xFFFF8A3D),
      ),
    _ => const ScenePalette(
        ground: Color(0xFF2A1466),
        groundDark: Color(0xFF1B0D40),
        road: Color(0xFF3B2580),
        roadEdge: Color(0xFFFFC93C),
        stripe: Color(0xFFFFF4D6),
        platform: Color(0xFF3B2580),
        platformTop: Color(0xFF6A4BC4),
        prop: Color(0xFF26125E),
        propAccent: Color(0xFFFFC93C),
      ),
  };
}

/// Full-size animated world scene. It is decoration only: hidden from screen
/// readers, and frozen when the player asks for reduced motion.
class SceneBackground extends StatefulWidget {
  const SceneBackground({super.key, required this.kind, this.animate = true});

  final SceneKind kind;

  /// Small preview scenes (like the world cards) stay still to save battery.
  final bool animate;

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 24), value: 0.3);
  late final _FrameLimiter _frames = _FrameLimiter(_c, const Duration(milliseconds: 33));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = !widget.animate ||
        MediaQuery.disableAnimationsOf(context) ||
        GameColors.of(context).highContrast;
    if (still) {
      _c
        ..stop()
        ..value = 0.3;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _frames.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hc = GameColors.of(context).highContrast;
    return RepaintBoundary(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: ScenePainter(widget.kind, _c, highContrast: hc, repaint: _frames),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _P {
  const _P(this.x, this.y, this.r, this.phase, this.speed);

  final double x;
  final double y;
  final double r;
  final double phase;
  final double speed;
}

final Map<int, List<_P>> _particleCache = {};

List<_P> _particles(int seed, int n) => _particleCache.putIfAbsent(seed, () {
      final rnd = math.Random(seed);
      return List.generate(
        n,
        (_) => _P(rnd.nextDouble(), rnd.nextDouble(), rnd.nextDouble(), rnd.nextDouble(),
            0.5 + rnd.nextDouble()),
      );
    });

const _tau = math.pi * 2;

/// Passes on at most one repaint per [interval] - the scenery is ambient
/// motion, so ~30 fps looks smooth and halves the drawing work.
class _FrameLimiter extends ChangeNotifier {
  _FrameLimiter(this.source, this.interval) {
    source.addListener(_tick);
  }

  final Animation<double> source;
  final Duration interval;
  final Stopwatch _clock = Stopwatch()..start();
  Duration _last = Duration.zero;

  void _tick() {
    final now = _clock.elapsed;
    if (now - _last >= interval) {
      _last = now;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    source.removeListener(_tick);
    super.dispose();
  }
}

class ScenePainter extends CustomPainter {
  ScenePainter(this.kind, this.anim, {required this.highContrast, Listenable? repaint})
      : super(repaint: repaint ?? anim);

  final SceneKind kind;
  final Animation<double> anim;
  final bool highContrast;

  double get t => anim.value;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (highContrast) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
      return;
    }
    switch (kind) {
      case SceneKind.menu:
        _menu(canvas, size, victory: false);
      case SceneKind.victory:
        _menu(canvas, size, victory: true);
      case SceneKind.defeat:
        _defeat(canvas, size);
      case SceneKind.python:
        _jungle(canvas, size);
      case SceneKind.c:
        _caves(canvas, size);
      case SceneKind.cpp:
        _castle(canvas, size);
      case SceneKind.java:
        _volcano(canvas, size);
    }
  }

  // ---------------------------------------------------------------- helpers

  void _sky(Canvas canvas, Size size, List<Color> colors, List<double> stops) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
  }

  /// Soft rolling hills along [base] (fraction of height).
  void _hills(Canvas canvas, Size size, double base, double amp, double freq, double phase, Color color) {
    final w = size.width;
    final h = size.height;
    final path = Path()..moveTo(0, h);
    const segments = 8;
    var prev = Offset(0, base * h + math.sin(phase) * amp * h);
    path.lineTo(prev.dx, prev.dy);
    for (var i = 1; i <= segments; i++) {
      final x = i / segments * w;
      final y = base * h + math.sin(i * freq + phase) * amp * h;
      final mid = Offset((prev.dx + x) / 2, (prev.dy + y) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      prev = Offset(x, y);
    }
    path
      ..lineTo(w, prev.dy)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _stars(Canvas canvas, Size size, {double maxY = 0.7, int seed = 7, int count = 60}) {
    final paint = Paint();
    for (final p in _particles(seed, count)) {
      final a = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(_tau * (p.phase + t * p.speed * 6)));
      paint.color = Colors.white.withValues(alpha: a);
      final o = Offset(p.x * size.width, p.y * maxY * size.height);
      final r = 0.6 + p.r * 1.8;
      canvas.drawCircle(o, r, paint);
      if (p.r > 0.85) {
        paint.strokeWidth = 1.2;
        canvas
          ..drawLine(o.translate(-r * 3.5, 0), o.translate(r * 3.5, 0), paint)
          ..drawLine(o.translate(0, -r * 3.5), o.translate(0, r * 3.5), paint);
      }
    }
  }

  void _glow(Canvas canvas, Offset c, double r, Color color, double alpha) {
    final paint = Paint();
    for (var i = 3; i >= 1; i--) {
      paint.color = color.withValues(alpha: alpha * (0.35 / i));
      canvas.drawCircle(c, r * (1 + i * 0.55), paint);
    }
  }

  static final List<TextPainter> _glyphPainters = [
    for (final (i, g) in const ['{ }', '</>', ';', '( )', '#', '==', '++', '[ ]', '=>'].indexed)
      TextPainter(
        text: TextSpan(
          text: g,
          style: TextStyle(
            fontFamily: displayFont,
            fontSize: 22.0 + (i * 7) % 20,
            color: Colors.white.withValues(alpha: 0.13 + (i % 3) * 0.03),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];

  // ------------------------------------------------------------------ menu

  void _menu(Canvas canvas, Size size, {required bool victory}) {
    final w = size.width;
    final h = size.height;
    _sky(canvas, size, const [Color(0xFF5A2DB0), Color(0xFF3A1D80), Color(0xFF1B0D40)], const [0, 0.55, 1]);

    if (victory) {
      final c = Offset(w / 2, h * 0.3);
      final paint = Paint()..color = const Color(0xFFFFC93C).withValues(alpha: 0.10);
      final len = math.max(w, h) * 1.2;
      for (var i = 0; i < 12; i++) {
        final a = _tau * (i / 12 + t * 0.5);
        final path = Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a - 0.11) * len, c.dy + math.sin(a - 0.11) * len)
          ..lineTo(c.dx + math.cos(a + 0.11) * len, c.dy + math.sin(a + 0.11) * len)
          ..close();
        canvas.drawPath(path, paint);
      }
    }

    _stars(canvas, size);

    // Moon
    final moon = Offset(w * 0.84, h * 0.16);
    final mr = 18 + math.min(w, h) * 0.05;
    _glow(canvas, moon, mr, const Color(0xFFFFF1C1), 0.6);
    canvas
      ..drawCircle(moon, mr, Paint()..color = const Color(0xFFFFF1C1))
      ..drawCircle(moon.translate(-mr * 0.3, -mr * 0.2), mr * 0.22, Paint()..color = const Color(0xFFF1DC9A))
      ..drawCircle(moon.translate(mr * 0.35, mr * 0.3), mr * 0.15, Paint()..color = const Color(0xFFF1DC9A));

    // Floating code symbols
    for (final (i, p) in _particles(11, _glyphPainters.length).indexed) {
      final y = ((p.y - t * (0.6 + p.speed * 0.6)) % 1.2) * h - h * 0.1;
      final x = p.x * w * 0.9 + math.sin(_tau * (t * 2 + p.phase)) * 14;
      _glyphPainters[i].paint(canvas, Offset(x, y));
    }

    _hills(canvas, size, 0.80, 0.025, 1.3, 0.4, const Color(0xFF3A1F86));
    _hills(canvas, size, 0.86, 0.03, 1.9, 2.0, const Color(0xFF2A1466));
    _hills(canvas, size, 0.93, 0.02, 1.4, 4.0, const Color(0xFF1B0D40));
  }

  void _defeat(Canvas canvas, Size size) {
    _sky(canvas, size, const [Color(0xFF3E2C66), Color(0xFF231840), Color(0xFF120C22)], const [0, 0.55, 1]);
    _stars(canvas, size, count: 30);
    _hills(canvas, size, 0.84, 0.03, 1.6, 1.0, const Color(0xFF2A1F45));
    _hills(canvas, size, 0.92, 0.02, 1.4, 3.0, const Color(0xFF181030));
  }

  // ---------------------------------------------------------------- jungle

  void _jungle(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _sky(canvas, size, const [Color(0xFF8BEBC8), Color(0xFF3CC08F), Color(0xFF13724F)], const [0, 0.45, 1]);

    // Sun
    final sun = Offset(w * 0.2, h * 0.16);
    _glow(canvas, sun, 36, const Color(0xFFFFF6B0), 0.9);
    canvas.drawCircle(sun, 36, Paint()..color = const Color(0xFFFFF3A0));

    // Far canopy
    final far = Paint()..color = const Color(0xFF2BA875);
    for (var i = 0; i < 15; i++) {
      final cx = i / 14 * w;
      final cy = h * (0.58 + math.sin(i * 1.7) * 0.02);
      canvas.drawCircle(Offset(cx, cy), w * (0.06 + 0.03 * math.sin(i * 2.3).abs()) + 20, far);
    }
    canvas.drawRect(Rect.fromLTRB(0, h * 0.6, w, h), far);

    // Trees
    for (final (x, top) in const [(0.07, 0.40), (0.33, 0.52), (0.71, 0.48), (0.94, 0.38)]) {
      final trunkW = math.max(10.0, w * 0.025);
      canvas.drawRect(
        Rect.fromLTRB(x * w - trunkW / 2, top * h, x * w + trunkW / 2, h),
        Paint()..color = const Color(0xFF5B3A22),
      );
      final leaf = Paint()..color = const Color(0xFF187A50);
      for (final (dx, dy, r) in const [(-0.9, 0.2, 1.0), (0.9, 0.25, 0.9), (0.0, -0.4, 1.1), (0.0, 0.4, 0.8)]) {
        canvas.drawCircle(Offset(x * w + dx * 30, top * h + dy * 30), 32 * r, leaf);
      }
    }

    _hills(canvas, size, 0.78, 0.03, 1.4, 1.0, const Color(0xFF1E8A5E));
    _hills(canvas, size, 0.88, 0.025, 2.1, 0.3, const Color(0xFF106343));

    // Hanging vines
    final vine = Paint()
      ..color = const Color(0xFF146B47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = const Color(0xFF1F9A64);
    for (var i = 0; i < 7; i++) {
      final x = (i + 0.5) / 7 * w;
      final len = h * (0.12 + 0.18 * ((i * 37) % 10) / 10);
      final sway = math.sin(_tau * (t * 2 + i * 0.13)) * w * 0.012;
      final end = Offset(x + sway * 2, len);
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x + sway, len * 0.6, end.dx, end.dy);
      canvas.drawPath(path, vine);
      for (var k = 1; k <= 4; k++) {
        final f = k / 5;
        final p = Offset(x + sway * f * 1.6, len * f);
        canvas.drawOval(
          Rect.fromCenter(center: p.translate(k.isEven ? 7 : -7, 0), width: 14, height: 8),
          leafPaint,
        );
      }
    }

    // Fireflies
    final glow = Paint();
    for (final p in _particles(21, 26)) {
      final x = (p.x + 0.025 * math.sin(_tau * (t * p.speed * 3 + p.phase))) * w;
      final y = (0.3 + p.y * 0.65 + 0.02 * math.cos(_tau * (t * p.speed * 2 + p.phase))) * h;
      final a = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(_tau * (t * 5 * p.speed + p.phase)));
      glow.color = const Color(0xFFFFF27A).withValues(alpha: 0.18 * a);
      canvas.drawCircle(Offset(x, y), 8, glow);
      glow.color = const Color(0xFFFFF27A).withValues(alpha: 0.95 * a);
      canvas.drawCircle(Offset(x, y), 2.4, glow);
    }
  }

  // ----------------------------------------------------------------- caves

  void _spike(Canvas canvas, double x, double base, double width, double len, Paint paint, {bool up = false}) {
    final dir = up ? -1 : 1;
    final path = Path()
      ..moveTo(x - width / 2, base)
      ..lineTo(x + width / 2, base)
      ..quadraticBezierTo(x + width * 0.15, base + dir * len * 0.7, x, base + dir * len)
      ..quadraticBezierTo(x - width * 0.15, base + dir * len * 0.7, x - width / 2, base)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _crystal(Canvas canvas, Offset base, double width, double height, double angle, Color color) {
    canvas
      ..save()
      ..translate(base.dx, base.dy)
      ..rotate(angle);
    final body = Path()
      ..moveTo(0, -height)
      ..lineTo(width / 2, -height * 0.78)
      ..lineTo(width / 2, 0)
      ..lineTo(-width / 2, 0)
      ..lineTo(-width / 2, -height * 0.78)
      ..close();
    final facet = Path()
      ..moveTo(0, -height)
      ..lineTo(0, 0)
      ..lineTo(-width / 2, 0)
      ..lineTo(-width / 2, -height * 0.78)
      ..close();
    canvas
      ..drawPath(body, Paint()..color = color)
      ..drawPath(facet, Paint()..color = Color.lerp(color, Colors.white, 0.35)!)
      ..drawPath(
        body,
        Paint()
          ..color = const Color(0xFF0B1536)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      )
      ..restore();
  }

  void _caves(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _sky(canvas, size, const [Color(0xFF2C428A), Color(0xFF182660), Color(0xFF0A1233)], const [0, 0.5, 1]);

    for (final (x, y, r) in const [(0.25, 0.35, 0.3), (0.75, 0.55, 0.35)]) {
      _glow(canvas, Offset(x * w, y * h), r * w * 0.5, const Color(0xFF5BE7FF), 0.25);
    }

    final back = Paint()..color = const Color(0xFF1E2F66);
    final front = Paint()..color = const Color(0xFF0B1536);
    for (var i = 0; i < 9; i++) {
      final x = (i + 0.3) / 9 * w;
      _spike(canvas, x, 0, w * 0.09, h * (0.14 + 0.12 * ((i * 53) % 7) / 7), back);
    }
    for (var i = 0; i < 6; i++) {
      final x = (i + 0.8) / 6 * w;
      _spike(canvas, x, 0, w * 0.11, h * (0.09 + 0.1 * ((i * 31) % 5) / 5), front);
    }

    // Falling drips from the ceiling
    final drip = Paint()..color = const Color(0xFF9BDCFF);
    for (final p in _particles(31, 10)) {
      final progress = (t * p.speed * 4 + p.phase) % 1;
      drip.color = const Color(0xFF9BDCFF).withValues(alpha: 0.8 * (1 - progress));
      canvas.drawCircle(Offset(p.x * w, h * (0.12 + progress * 0.7)), 2.5, drip);
    }

    _hills(canvas, size, 0.86, 0.02, 1.8, 0.7, const Color(0xFF13214D));
    for (var i = 0; i < 7; i++) {
      final x = (i + 0.5) / 7 * w;
      _spike(canvas, x, h, w * 0.07, h * (0.08 + 0.1 * ((i * 17) % 6) / 6), front, up: true);
    }

    // Glowing crystal clusters
    final pulse = 0.6 + 0.4 * math.sin(_tau * t * 4);
    for (final (cx, cy, s) in const [(0.12, 0.93, 1.0), (0.88, 0.92, 1.15), (0.55, 0.97, 0.8)]) {
      final base = Offset(cx * w, cy * h);
      final scale = s * math.max(0.7, math.min(w, h) / 600);
      _glow(canvas, base.translate(0, -30 * scale), 40 * scale, const Color(0xFF5BE7FF), 0.6 * pulse);
      _crystal(canvas, base.translate(-22 * scale, 0), 24 * scale, 70 * scale, -0.35, const Color(0xFFB98CFF));
      _crystal(canvas, base.translate(20 * scale, 0), 22 * scale, 60 * scale, 0.3, const Color(0xFF7CF2C8));
      _crystal(canvas, base, 30 * scale, 95 * scale, 0, const Color(0xFF5BE7FF));
    }

    // Sparkles
    final sp = Paint();
    for (final p in _particles(33, 22)) {
      final a = 0.5 + 0.5 * math.sin(_tau * (t * 6 * p.speed + p.phase));
      sp.color = const Color(0xFFCDF6FF).withValues(alpha: 0.7 * a);
      canvas.drawCircle(Offset(p.x * w, (0.2 + p.y * 0.6) * h), 1.6, sp);
    }
  }

  // ---------------------------------------------------------------- castle

  void _castle(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _sky(canvas, size, const [Color(0xFF8A5BE0), Color(0xFF4A2A9A), Color(0xFF1C0E3F)], const [0, 0.5, 1]);
    _stars(canvas, size, maxY: 0.6, seed: 41, count: 50);

    // Crescent moon
    final moon = Offset(w * 0.17, h * 0.15);
    const mr = 34.0;
    _glow(canvas, moon, mr, const Color(0xFFFFF1C1), 0.45);
    canvas
      ..saveLayer(Rect.fromCircle(center: moon, radius: mr * 2), Paint())
      ..drawCircle(moon, mr, Paint()..color = const Color(0xFFFFF1C1))
      ..drawCircle(moon.translate(mr * 0.45, -mr * 0.25), mr * 0.85, Paint()..blendMode = BlendMode.clear)
      ..restore();

    // Shooting star
    final s = (t * 3) % 1;
    if (s < 0.12) {
      final k = s / 0.12;
      final head = Offset(w * (0.85 - k * 0.4), h * (0.06 + k * 0.18));
      canvas.drawLine(
        head,
        head.translate(w * 0.08, -h * 0.035),
        Paint()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 1 - k),
      );
    }

    // Mountains
    final mountains = Path()..moveTo(0, h);
    for (var i = 0; i <= 10; i++) {
      final x = i / 10 * w;
      final y = h * (i.isEven ? 0.66 : 0.58 + 0.04 * math.sin(i.toDouble()));
      mountains.lineTo(x, y);
    }
    mountains
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mountains, Paint()..color = const Color(0xFF3A2080));

    // Castle
    final cx = w / 2;
    final by = h * 0.9;
    final cw = math.min(w * 0.62, 460.0);
    final ch = cw * 0.55;
    final stone = Paint()..color = const Color(0xFF24124F);
    final dark = Paint()..color = const Color(0xFF1B0D3D);

    void crenels(double left, double right, double top, double size) {
      for (var x = left; x < right - size * 0.5; x += size * 2) {
        canvas.drawRect(Rect.fromLTWH(x, top - size, size, size), stone);
      }
    }

    // Main wall + keep
    canvas.drawRect(Rect.fromLTRB(cx - cw * 0.36, by - ch * 0.45, cx + cw * 0.36, by), stone);
    crenels(cx - cw * 0.36, cx + cw * 0.36, by - ch * 0.45, cw * 0.035);
    canvas.drawRect(Rect.fromLTRB(cx - cw * 0.11, by - ch * 0.82, cx + cw * 0.11, by), stone);
    crenels(cx - cw * 0.11, cx + cw * 0.11, by - ch * 0.82, cw * 0.035);

    // Side towers with roofs and waving flags
    for (final side in const [-1.0, 1.0]) {
      final tx = cx + side * cw * 0.44;
      final tw = cw * 0.14;
      canvas.drawRect(Rect.fromLTRB(tx - tw / 2, by - ch * 0.66, tx + tw / 2, by), dark);
      final roofTop = by - ch * 1.02;
      canvas.drawPath(
        Path()
          ..moveTo(tx - tw * 0.65, by - ch * 0.66)
          ..lineTo(tx + tw * 0.65, by - ch * 0.66)
          ..lineTo(tx, roofTop)
          ..close(),
        Paint()..color = const Color(0xFF3A1E78),
      );
      canvas.drawLine(
        Offset(tx, roofTop),
        Offset(tx, roofTop - 26),
        Paint()
          ..color = const Color(0xFF1B0D3D)
          ..strokeWidth = 3,
      );
      final wave = math.sin(_tau * (t * 8 + (side > 0 ? 0.3 : 0)));
      canvas.drawPath(
        Path()
          ..moveTo(tx, roofTop - 26)
          ..quadraticBezierTo(tx + 12, roofTop - 30 + wave * 4, tx + 26, roofTop - 24 + wave * 3)
          ..lineTo(tx, roofTop - 14)
          ..close(),
        Paint()..color = side < 0 ? const Color(0xFFFFC93C) : const Color(0xFFFF6B7F),
      );
    }

    // Gate and glowing windows
    canvas.drawPath(
      Path()
        ..moveTo(cx - cw * 0.06, by)
        ..lineTo(cx - cw * 0.06, by - ch * 0.2)
        ..arcToPoint(Offset(cx + cw * 0.06, by - ch * 0.2), radius: Radius.circular(cw * 0.06))
        ..lineTo(cx + cw * 0.06, by)
        ..close(),
      Paint()..color = const Color(0xFF0E0624),
    );
    final win = Paint();
    for (final (i, (dx, dy)) in const [
      (-0.25, 0.3), (0.25, 0.3), (-0.04, 0.6), (0.04, 0.6), (-0.44, 0.45), (0.44, 0.45), (-0.15, 0.3), (0.15, 0.3),
    ].indexed) {
      final flicker = 0.75 + 0.25 * math.sin(_tau * (t * 9 + i * 0.37));
      win.color = const Color(0xFFFFC93C).withValues(alpha: flicker);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + dx * cw, by - dy * ch), width: cw * 0.028, height: cw * 0.05),
          const Radius.circular(4),
        ),
        win,
      );
    }

    _hills(canvas, size, 0.92, 0.015, 1.6, 0.5, const Color(0xFF170A33));
  }

  // --------------------------------------------------------------- volcano

  void _volcano(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _sky(
      canvas,
      size,
      const [Color(0xFFFFC07A), Color(0xFFFF7A45), Color(0xFFA3271E), Color(0xFF2A0B0B)],
      const [0, 0.3, 0.65, 1],
    );

    final crater = Offset(w * 0.5, h * 0.5);

    // Smoke
    final smoke = Paint();
    for (final p in _particles(51, 10)) {
      final k = (t * p.speed * 2 + p.phase) % 1;
      smoke.color = const Color(0xFF5A3A35).withValues(alpha: 0.35 * (1 - k));
      canvas.drawCircle(
        Offset(crater.dx + math.sin(_tau * (k + p.phase)) * w * 0.04 + k * w * 0.12, crater.dy - k * h * 0.42),
        18 + k * 46,
        smoke,
      );
    }

    // Far jagged mountains
    final far = Path()..moveTo(0, h);
    for (var i = 0; i <= 12; i++) {
      far.lineTo(i / 12 * w, h * (i.isEven ? 0.7 : 0.62 + 0.03 * math.cos(i.toDouble())));
    }
    far
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF7A1F18));

    // Volcano cone
    final cone = Path()
      ..moveTo(w * 0.1, h * 0.93)
      ..lineTo(crater.dx - w * 0.07, crater.dy)
      ..quadraticBezierTo(crater.dx, crater.dy + h * 0.025, crater.dx + w * 0.07, crater.dy)
      ..lineTo(w * 0.9, h * 0.93)
      ..close();
    final coneRect = Rect.fromLTRB(w * 0.1, crater.dy, w * 0.9, h * 0.93);
    canvas.drawPath(
      cone,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A1C14), Color(0xFF2A0B08)],
        ).createShader(coneRect),
    );

    // Crater glow and lava
    final pulse = 0.7 + 0.3 * math.sin(_tau * t * 6);
    _glow(canvas, crater, w * 0.06, const Color(0xFFFF8A3D), pulse);
    canvas.drawOval(
      Rect.fromCenter(center: crater.translate(0, 2), width: w * 0.13, height: h * 0.025),
      Paint()..color = const Color(0xFFFFB13B),
    );
    final lavaGlow = Paint()
      ..color = const Color(0xFFFF7A2E).withValues(alpha: 0.25 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final lava = Paint()
      ..color = const Color(0xFFFF7A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final (dx, ex, ey) in const [(-0.03, -0.12, 0.78), (0.02, 0.08, 0.86), (0.05, 0.2, 0.74)]) {
      final path = Path()
        ..moveTo(crater.dx + dx * w, crater.dy + 4)
        ..quadraticBezierTo(
          crater.dx + (dx + ex) * w * 0.5,
          crater.dy + (ey * h - crater.dy) * 0.5,
          crater.dx + ex * w,
          ey * h,
        );
      canvas
        ..drawPath(path, lavaGlow)
        ..drawPath(path, lava);
    }

    // Ground with glowing cracks
    _hills(canvas, size, 0.9, 0.015, 1.7, 0.8, const Color(0xFF1F0808));
    final crack = Paint()
      ..color = const Color(0xFFFF6A2A).withValues(alpha: 0.5 + 0.3 * pulse)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final x = (i + 0.5) / 5 * w;
      canvas.drawPath(
        Path()
          ..moveTo(x, h * 0.93)
          ..lineTo(x + 14, h * 0.955)
          ..lineTo(x + 4, h * 0.98)
          ..lineTo(x + 22, h),
        crack,
      );
    }

    // Rising embers
    final ember = Paint();
    for (final p in _particles(53, 30)) {
      final k = (t * p.speed * 3 + p.phase) % 1;
      final x = (p.x + 0.02 * math.sin(_tau * (k * 2 + p.phase))) * w;
      final y = h * (1 - k);
      ember.color = Color.lerp(const Color(0xFFFFC93C), const Color(0xFFFF5A1F), p.r)!
          .withValues(alpha: 0.9 * (1 - k));
      canvas.drawCircle(Offset(x, y), 1.5 + p.r * 2, ember);
    }
  }

  @override
  bool shouldRepaint(ScenePainter old) => old.kind != kind || old.highContrast != highContrast;
}
