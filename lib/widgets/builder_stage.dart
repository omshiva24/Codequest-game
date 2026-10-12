// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/builder.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// One moment of a World Builder challenge, for drawing.
@immutable
class StageScene {
  const StageScene({
    required this.lang,
    required this.obstacle,
    required this.size,
    this.built = 0,
    this.coins = 0,
    this.speech,
    this.speechIsError = false,
    this.outcome,
    this.act = 0,
    this.enter = 1,
    this.clock = 0,
    this.jump = 0,
  });

  final Lang lang;
  final Obstacle obstacle;

  /// Gap width, ledge or stairs height, or toll price.
  final int size;

  /// Blocks or steps placed so far.
  final int built;

  /// Coins counted so far (toll).
  final int coins;

  /// What Byte is saying (printed text), if anything.
  final String? speech;
  final bool speechIsError;

  /// Set once the code has finished running.
  final BuildOutcome? outcome;

  /// 0..1 progress of Byte's attempt after the code ran.
  final double act;

  /// 0..1 progress of Byte walking in at the start of a challenge.
  final double enter;

  /// Seconds, for idle animation (always 0 when motion is reduced).
  final double clock;

  /// Jump height (ledge challenges).
  final int jump;
}

/// The painted side-scrolling world for one challenge, with Byte in it.
class BuilderStage extends StatelessWidget {
  const BuilderStage({
    super.key,
    required this.scene,
    required this.description,
    this.aspect = defaultAspect,
  });

  final StageScene scene;

  /// What a screen reader announces about the picture.
  final String description;

  /// Width divided by height. Smaller = taller stage with more sky.
  final double aspect;

  static const double defaultAspect = 1.7;
  static const double minAspect = 1.45;
  static const double maxAspect = 2.0;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      container: true,
      image: true,
      label: description,
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: g.outlineWidth),
            boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: AspectRatio(
              aspectRatio: aspect,
              child: LayoutBuilder(
                builder: (context, box) {
                  final geo = StageGeometry(box.biggest);
                  final hero = heroPoseFor(scene, geo);
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: StagePainter(
                            scene: scene,
                            hero: hero,
                            ink: g.highContrast ? Colors.white : g.ink,
                            highContrast: g.highContrast,
                          ),
                        ),
                      ),
                      ..._overlays(context, geo, hero, g),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _overlays(BuildContext context, StageGeometry geo, HeroPose hero, GameColors g) {
    final t = geo.tile;
    final small = math.max(12.0, t * 0.34);
    final out = <Widget>[];

    Widget pill(String text) => Container(
          padding: EdgeInsets.symmetric(horizontal: t * 0.18, vertical: t * 0.05),
          decoration: BoxDecoration(
            color: g.highContrast ? Colors.black : g.ink.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Text(text, style: TextStyle(color: Colors.white, fontSize: small, fontWeight: FontWeight.w800)),
        );

    switch (scene.obstacle) {
      case Obstacle.gap:
        out.add(Positioned(
          left: geo.x(5),
          width: geo.x(scene.size),
          top: geo.ground + t * 0.75,
          child: Center(child: pill('${scene.size} wide')),
        ));
      case Obstacle.ledge:
        out.add(Positioned(
          left: geo.x(6.2),
          top: geo.ground - t * scene.size + t * 0.15,
          child: pill('${scene.size} high'),
        ));
      case Obstacle.stairs:
        out.add(Positioned(
          left: geo.x(5.0 + scene.size + 0.2),
          top: geo.ground - t * scene.size + t * 0.15,
          child: pill('${scene.size} high'),
        ));
      case Obstacle.guard:
        out.add(_emoji(geo, _guardEmoji(scene.lang), 9.6));
        if (scene.outcome == null || !scene.outcome!.success) {
          out.add(Positioned(
            left: geo.x(9.0),
            top: geo.ground - t * 2.9,
            child: _bubble('Password?', g, small),
          ));
        }
      case Obstacle.toll:
        out.add(_emoji(geo, '🧌', 9.6));
        out.add(Positioned(
          left: geo.x(8.9),
          top: geo.ground - t * 2.9,
          child: pill('Toll: ${scene.size} coins'),
        ));
    }

    // Byte's speech bubble (printed text) or coin counter.
    final speech = scene.speech;
    final showCoins = scene.obstacle == Obstacle.toll && scene.coins > 0;
    if (hero.visible && (speech != null || showCoins)) {
      final text = speech != null ? (scene.speechIsError ? 'Error!' : speech) : '${scene.coins} coins';
      out.add(Positioned(
        left: math.max(4, hero.x - t * 0.6),
        top: math.max(4, hero.y - t * 2.45),
        child: _bubble(text, g, small, error: scene.speechIsError, code: speech != null && !scene.speechIsError),
      ));
    }
    return out;
  }

  Widget _emoji(StageGeometry geo, String emoji, double col) => Positioned(
        left: geo.x(col) - geo.tile * 0.7,
        top: geo.ground - geo.tile * 1.55,
        child: Text(emoji, style: TextStyle(fontSize: geo.tile * 1.15, height: 1.2)),
      );

  Widget _bubble(String text, GameColors g, double size, {bool error = false, bool code = false}) => Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.6, vertical: size * 0.25),
        decoration: BoxDecoration(
          color: error ? g.coral : g.parchment,
          borderRadius: BorderRadius.circular(size),
          border: Border.all(color: g.highContrast ? Colors.black : g.ink, width: 2),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: code ? codeFont : null,
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: g.ink,
          ),
        ),
      );
}

String _guardEmoji(Lang lang) => switch (lang) {
      Lang.python => '🦜',
      Lang.c => '🤖',
      Lang.cpp => '💂',
      Lang.java => '🐲',
    };

/// The stage is 14 tiles wide and 7 tiles high; the ground is at 5.7 tiles.
class StageGeometry {
  StageGeometry(Size size)
      : tile = size.width / 14,
        width = size.width,
        height = size.height;

  final double tile;
  final double width;
  final double height;

  /// Byte's height from feet to the top of his head, in tiles.
  static const double heroHeight = 1.84;

  /// Free space between the ledge top and the spiky ceiling, in tiles. Byte
  /// (plus a little victory hop) fits under it, but one block more does not.
  static const double ceilingGap = 2.6;

  /// The ground strip is always 1.3 tiles deep; a taller stage adds sky.
  double get ground => height - tile * 1.3;
  double x(num column) => column * tile;
  double above(num blocks) => ground - blocks * tile;

  /// Where the spikes start above a ledge [blocks] high.
  double ceilingBottom(num blocks) => above(blocks + ceilingGap);

  /// Where Byte walks to (and celebrates) after a success. He stays in view.
  double get finishX => x(12.2);

  /// Top of the water, pit or lava in a gap.
  double get hazardSurface => ground + tile * 0.55;

  /// After falling in, Byte bobs with his head and shoulders above the surface.
  double get swimFeet => hazardSurface + tile * 1.1;
}

enum HeroAction { stand, walk, jump, fall, bonk }

/// Where Byte is and what Byte is doing.
@immutable
class HeroPose {
  const HeroPose({
    required this.x,
    required this.y,
    this.action = HeroAction.stand,
    this.rotation = 0,
    this.stride = 0,
    this.stars = false,
    this.splash = 0,
    this.visible = true,
  });

  /// Feet position.
  final double x;
  final double y;
  final HeroAction action;
  final double rotation;

  /// Walk cycle phase (radians).
  final double stride;

  /// Dizzy stars after a bump.
  final bool stars;

  /// 0..1 splash after falling in.
  final double splash;
  final bool visible;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _seg(double t, double start, double end) => ((t - start) / (end - start)).clamp(0.0, 1.0);

/// Walks along a path of points; [t] is 0..1 of the whole path length.
Offset _alongPath(List<Offset> points, double t) {
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += (points[i] - points[i - 1]).distance;
  }
  var remaining = total * t.clamp(0.0, 1.0);
  for (var i = 1; i < points.length; i++) {
    final d = (points[i] - points[i - 1]).distance;
    if (remaining <= d || i == points.length - 1) {
      final f = d == 0 ? 1.0 : (remaining / d).clamp(0.0, 1.0);
      return Offset.lerp(points[i - 1], points[i], f)!;
    }
    remaining -= d;
  }
  return points.last;
}

/// Works out Byte's pose for this moment of the scene.
HeroPose heroPoseFor(StageScene s, StageGeometry geo) {
  final t = geo.tile;
  final startX = geo.x(2.4);
  final ground = geo.ground;
  final endX = geo.finishX;

  if (s.enter < 1) {
    return HeroPose(
      x: _lerp(-t * 1.5, startX, s.enter),
      y: ground,
      action: HeroAction.walk,
      stride: s.enter * 14,
    );
  }
  final outcome = s.outcome;
  if (outcome == null) {
    final bob = math.sin(s.clock * math.pi * 0.8) * t * 0.03;
    return HeroPose(x: startX, y: ground + bob);
  }
  final a = s.act;

  HeroPose walkTo(double toX, double y, double phase, {double fromX = -1}) => HeroPose(
        x: _lerp(fromX < 0 ? startX : fromX, toX, phase),
        y: y,
        action: phase > 0 && phase < 1 ? HeroAction.walk : HeroAction.stand,
        stride: phase * 16,
      );

  // Success: walk to the far side, then two happy hops (stays on screen).
  HeroPose walkThenCheer(double fromX, double y, double phase) {
    if (phase < 0.75) {
      final u = phase / 0.75;
      return HeroPose(
        x: _lerp(fromX, endX, u),
        y: y,
        action: u > 0 ? HeroAction.walk : HeroAction.stand,
        stride: u * 16,
      );
    }
    final u = _seg(phase, 0.75, 1);
    final hop = math.sin(u * math.pi * 2).abs();
    return HeroPose(
      x: endX,
      y: y - hop * t * 0.3,
      action: u > 0 && u < 1 && hop > 0.05 ? HeroAction.jump : HeroAction.stand,
    );
  }

  HeroPose knockBack(double fromX, double y, double u, {double dropTo = -1}) => HeroPose(
        x: fromX - t * 0.8 * u,
        y: (dropTo < 0 ? y : _lerp(y, dropTo, u)) - math.sin(u * math.pi) * t * 0.5,
        action: HeroAction.bonk,
        rotation: -0.5 * u,
        stars: u > 0.25,
      );

  switch (s.obstacle) {
    case Obstacle.gap:
      final gap = s.size;
      if (outcome == BuildOutcome.cross) {
        return walkThenCheer(startX, ground, a);
      }
      if (outcome == BuildOutcome.trip) {
        final stopX = geo.x(5 + gap) - t * 0.55;
        if (a < 0.5) return walkTo(stopX, ground, a / 0.5);
        return knockBack(stopX, ground, _seg(a, 0.5, 1));
      }
      // fall (or a code error that never builds anything)
      if (outcome == BuildOutcome.error) return _confused(startX, ground, a, t);
      final edge = geo.x(5 + math.min(s.built, gap)) + t * 0.25;
      if (a < 0.45) return walkTo(edge, ground, a / 0.45);
      final u = _seg(a, 0.45, 1);
      final sink = math.min(1.0, u / 0.7);
      final bob = u > 0.7 ? math.sin(s.clock * math.pi * 1.6) * t * 0.06 : 0.0;
      // Stay inside the gap so Byte never overlaps the far bank.
      final inGap = (edge + t * 0.7 * sink).clamp(geo.x(5) + t * 0.6, geo.x(5 + gap) - t * 0.4);
      return HeroPose(
        x: inGap,
        y: _lerp(ground, geo.swimFeet, sink * sink) + bob,
        action: HeroAction.fall,
        rotation: math.sin(sink * math.pi) * 0.9,
        stars: u > 0.75,
        splash: _seg(u, 0.35, 1),
      );

    case Obstacle.ledge:
      final h = s.size;
      final top = geo.above(h);
      if (outcome == BuildOutcome.land) {
        if (a < 0.12) return HeroPose(x: startX, y: ground + t * 0.06);
        if (a < 0.62) {
          final u = _seg(a, 0.12, 0.62);
          return HeroPose(
            x: _lerp(startX, geo.x(7.3), u),
            y: _lerp(ground, top, u) - math.sin(u * math.pi) * t * 0.35,
            action: HeroAction.jump,
          );
        }
        return walkThenCheer(geo.x(7.3), top, _seg(a, 0.62, 1));
      }
      if (outcome == BuildOutcome.error) return _confused(startX, ground, a, t);
      final wallX = geo.x(6) - t * 0.5;
      final peak = outcome == BuildOutcome.bonkCeiling
          ? geo.ceilingBottom(h) + t * StageGeometry.heroHeight // head touches the spikes
          : geo.above(math.max(0, s.jump));
      final peakX = outcome == BuildOutcome.bonkCeiling ? geo.x(4.6) : wallX;
      if (a < 0.5) {
        final u = _seg(a, 0, 0.5);
        return HeroPose(
          x: _lerp(startX, peakX, u),
          y: _lerp(ground, peak, math.sin(u * math.pi / 2)),
          action: HeroAction.jump,
        );
      }
      final u = _seg(a, 0.5, 1);
      return HeroPose(
        x: _lerp(peakX, peakX - t * 1.1, u),
        y: _lerp(peak, ground, u * u),
        action: HeroAction.bonk,
        rotation: -0.4 * u,
        stars: true,
      );

    case Obstacle.stairs:
      final h = s.size;
      final built = s.built;
      final climb = math.min(built, h);
      final path = <Offset>[Offset(startX, ground), Offset(geo.x(5) - t * 0.15, ground)];
      for (var k = 0; k < climb; k++) {
        path.add(Offset(geo.x(5 + k + 0.5), geo.above(k + 1)));
      }
      if (outcome == BuildOutcome.cross) {
        if (a < 0.75) {
          final u = a / 0.75;
          path.add(Offset(endX, geo.above(h)));
          final p = _alongPath(path, u);
          return HeroPose(x: p.dx, y: p.dy, action: HeroAction.walk, stride: u * 22);
        }
        return walkThenCheer(endX, geo.above(h), 0.75 + _seg(a, 0.75, 1) * 0.25);
      }
      if (outcome == BuildOutcome.error) return _confused(startX, ground, a, t);
      if (outcome == BuildOutcome.trip) {
        path.add(Offset(geo.x(5 + h) - t * 0.55, geo.above(h)));
      } else if (climb == 0) {
        path.add(Offset(geo.x(5 + h) - t * 0.55, ground));
      }
      if (a < 0.6) {
        final u = a / 0.6;
        final p = _alongPath(path, u);
        return HeroPose(x: p.dx, y: p.dy, action: HeroAction.walk, stride: u * 18);
      }
      final end = path.last;
      return knockBack(end.dx, end.dy, _seg(a, 0.6, 1));

    case Obstacle.guard:
    case Obstacle.toll:
      if (outcome == BuildOutcome.cross) {
        return walkThenCheer(startX, ground, _seg(a, 0.25, 1));
      }
      if (outcome == BuildOutcome.error) return _confused(startX, ground, a, t);
      final stopX = geo.x(7.45);
      if (a < 0.5) return walkTo(stopX, ground, a / 0.5);
      return knockBack(stopX, ground, _seg(a, 0.5, 1));
  }
}

HeroPose _confused(double x, double y, double a, double t) => HeroPose(
      x: x + math.sin(a * math.pi * 6) * t * 0.08 * (1 - a),
      y: y,
      stars: a > 0.2,
    );

// ---------------------------------------------------------------------------
// Painting
// ---------------------------------------------------------------------------

@immutable
class _Look {
  const _Look({
    required this.skyTop,
    required this.skyBottom,
    required this.far,
    required this.ground,
    required this.groundTop,
    required this.groundDark,
    required this.hazard,
    required this.hazardLight,
    required this.block,
    required this.blockLight,
    required this.blockDark,
  });

  final Color skyTop, skyBottom, far, ground, groundTop, groundDark;
  final Color hazard, hazardLight, block, blockLight, blockDark;
}

const _highContrastLook = _Look(
  skyTop: Colors.black,
  skyBottom: Colors.black,
  far: Color(0xFF1A1A1A),
  ground: Colors.black,
  groundTop: Colors.white,
  groundDark: Colors.black,
  hazard: Colors.black,
  hazardLight: Colors.white,
  block: Color(0xFFFFE100),
  blockLight: Colors.white,
  blockDark: Colors.black,
);

_Look _lookFor(Lang lang, bool highContrast) {
  if (highContrast) return _highContrastLook;
  return switch (lang) {
    Lang.python => const _Look(
        skyTop: Color(0xFF7FDDB8),
        skyBottom: Color(0xFFD8FBEA),
        far: Color(0xFF45B983),
        ground: Color(0xFF1E8A5B),
        groundTop: Color(0xFF6BE0A4),
        groundDark: Color(0xFF0E5A3D),
        hazard: Color(0xFF2E9AD6),
        hazardLight: Color(0xFFA6E6FF),
        block: Color(0xFFC98B4E),
        blockLight: Color(0xFFEDB679),
        blockDark: Color(0xFF8A5A2E),
      ),
    Lang.c => const _Look(
        skyTop: Color(0xFF0C1640),
        skyBottom: Color(0xFF2A3C80),
        far: Color(0xFF16245A),
        ground: Color(0xFF2A3C7A),
        groundTop: Color(0xFF6E8EE6),
        groundDark: Color(0xFF0B1438),
        hazard: Color(0xFF060A1E),
        hazardLight: Color(0xFF5BE7FF),
        block: Color(0xFF5BE7FF),
        blockLight: Color(0xFFD2F9FF),
        blockDark: Color(0xFF2386B0),
      ),
    Lang.cpp => const _Look(
        skyTop: Color(0xFF241252),
        skyBottom: Color(0xFF6A4BC4),
        far: Color(0xFF1C0E3D),
        ground: Color(0xFF5A4590),
        groundTop: Color(0xFFA48FE0),
        groundDark: Color(0xFF2A1858),
        hazard: Color(0xFF3550C0),
        hazardLight: Color(0xFF9DB2FF),
        block: Color(0xFFB7A6E6),
        blockLight: Color(0xFFE2D9FF),
        blockDark: Color(0xFF6E5AA8),
      ),
    Lang.java => const _Look(
        skyTop: Color(0xFF4A120A),
        skyBottom: Color(0xFFD0532A),
        far: Color(0xFF2E0A06),
        ground: Color(0xFF5A2418),
        groundTop: Color(0xFF9A4A2A),
        groundDark: Color(0xFF1F0808),
        hazard: Color(0xFFFF5A1F),
        hazardLight: Color(0xFFFFD25A),
        block: Color(0xFF3A2A3A),
        blockLight: Color(0xFF6A5468),
        blockDark: Color(0xFF1A121A),
      ),
  };
}

class StagePainter extends CustomPainter {
  StagePainter({required this.scene, required this.hero, required this.ink, required this.highContrast});

  final StageScene scene;
  final HeroPose hero;
  final Color ink;
  final bool highContrast;

  late final _Look _look = _lookFor(scene.lang, highContrast);

  @override
  void paint(Canvas canvas, Size size) {
    final geo = StageGeometry(size);
    _sky(canvas, size, geo);
    switch (scene.obstacle) {
      case Obstacle.gap:
        _gap(canvas, size, geo);
      case Obstacle.ledge:
        _groundRect(canvas, geo, 0, 14);
        _ledge(canvas, geo, 6, scene.size);
        _ceiling(canvas, geo);
      case Obstacle.stairs:
        _groundRect(canvas, geo, 0, 14);
        _ledge(canvas, geo, 5.0 + scene.size, scene.size);
        _stairs(canvas, geo);
      case Obstacle.guard:
        _groundRect(canvas, geo, 0, 14);
        _gate(canvas, geo);
      case Obstacle.toll:
        _groundRect(canvas, geo, 0, 14);
        _barrier(canvas, geo);
    }
    if (hero.visible && hero.x > -geo.tile * 2 && hero.x < size.width + geo.tile * 2) {
      _hero(canvas, geo);
      if (scene.obstacle == Obstacle.gap && hero.y > geo.hazardSurface) _hazardFront(canvas, size, geo);
    }
  }

  /// The front of the water (or pit, or lava), drawn over Byte so he looks
  /// like he is in it, not on top of it.
  void _hazardFront(Canvas canvas, Size size, StageGeometry geo) {
    final t = geo.tile;
    final left = geo.x(5);
    final right = geo.x(5 + scene.size);
    final surface = geo.hazardSurface;
    canvas.drawRect(
      Rect.fromLTRB(left, surface, right, size.height),
      Paint()..color = _look.hazard.withValues(alpha: highContrast ? 1 : 0.9),
    );
    final light = Paint()
      ..color = _look.hazardLight
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    if (scene.lang == Lang.c && !highContrast) return; // a dry crystal pit: no ripples
    final shift = (scene.clock * t * 0.64) % (t * 0.8);
    for (var x = left - t + shift; x < right; x += t * 0.8) {
      final y = surface + t * 0.12;
      canvas.drawPath(
        Path()
          ..moveTo(math.max(left, x), y)
          ..quadraticBezierTo(x + t * 0.2, y - t * 0.12, math.min(right, x + t * 0.4), y),
        light,
      );
    }
  }

  Paint get _inkStroke => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeJoin = StrokeJoin.round;

  void _sky(Canvas canvas, Size size, StageGeometry geo) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_look.skyTop, _look.skyBottom],
        ).createShader(rect),
    );
    if (highContrast) return;
    final t = geo.tile;
    final far = Paint()..color = _look.far;
    switch (scene.lang) {
      case Lang.python:
        canvas.drawCircle(Offset(geo.x(11.5), t * 1.2), t * 0.8, Paint()..color = const Color(0xFFFFF1A8));
        for (final (cx, r) in const [(1.5, 3.2), (6.0, 2.6), (11.0, 3.4)]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(geo.x(cx), geo.ground), width: t * r * 2, height: t * r * 1.3), far);
        }
      case Lang.c:
        for (var i = 0; i < 14; i++) {
          final len = t * (0.6 + (i * 37 % 5) * 0.25);
          final path = Path()
            ..moveTo(geo.x(i), 0)
            ..lineTo(geo.x(i + 1), 0)
            ..lineTo(geo.x(i + 0.5), len)
            ..close();
          canvas.drawPath(path, far);
        }
        final glow = Paint()..color = _look.hazardLight.withValues(alpha: 0.5);
        for (final cx in const [2.0, 7.5, 12.0]) {
          canvas.drawCircle(Offset(geo.x(cx), t * (1.8 + cx % 2)), t * 0.07, glow);
        }
      case Lang.cpp:
        canvas.drawCircle(Offset(geo.x(11.8), t * 1.1), t * 0.6, Paint()..color = const Color(0xFFFFF4D6));
        for (final (cx, w, h) in const [(1.0, 1.4, 3.2), (3.4, 1.0, 2.4), (9.0, 1.2, 2.8)]) {
          final r = Rect.fromLTWH(geo.x(cx), geo.ground - t * h, t * w, t * h);
          canvas.drawRect(r, far);
          for (var k = 0; k < 3; k++) {
            canvas.drawRect(Rect.fromLTWH(r.left + k * r.width / 2.5, r.top - t * 0.25, r.width / 5, t * 0.25), far);
          }
        }
      case Lang.java:
        final volcano = Path()
          ..moveTo(geo.x(7), geo.ground)
          ..lineTo(geo.x(9.6), t * 1.8)
          ..lineTo(geo.x(11.0), t * 1.8)
          ..lineTo(geo.x(13.8), geo.ground)
          ..close();
        canvas.drawPath(volcano, far);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(geo.x(10.3), t * 1.8), width: t * 1.4, height: t * 0.35),
          Paint()..color = const Color(0xFFFF8A3D),
        );
        final ember = Paint()..color = const Color(0xFFFFC93C);
        for (var i = 0; i < 6; i++) {
          final rise = (scene.clock * 0.2 + i / 6) % 1.0;
          canvas.drawCircle(Offset(geo.x(9.8 + (i % 3) * 0.4), t * 1.7 - rise * t * 1.4), t * 0.05, ember);
        }
    }
  }

  void _groundRect(Canvas canvas, StageGeometry geo, double fromCol, double toCol, {bool leftEdge = false, bool rightEdge = false}) {
    final t = geo.tile;
    final rect = Rect.fromLTRB(geo.x(fromCol), geo.ground, geo.x(toCol), geo.height + 4);
    canvas.drawRect(rect, Paint()..color = _look.ground);
    canvas.drawRect(Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + t * 0.32), Paint()..color = _look.groundTop);
    final seam = Paint()
      ..color = _look.groundDark.withValues(alpha: highContrast ? 1 : 0.35)
      ..strokeWidth = 1.5;
    for (var c = fromCol.ceil(); c < toCol; c++) {
      canvas.drawLine(Offset(geo.x(c), rect.top + t * 0.45), Offset(geo.x(c), geo.height), seam);
    }
    final edge = _inkStroke;
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.right, rect.top), edge);
    if (leftEdge) canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, geo.height), edge);
    if (rightEdge) canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, geo.height), edge);
  }

  void _block(Canvas canvas, Rect r) {
    final t = r.width;
    final rr = RRect.fromRectAndRadius(r.deflate(1), Radius.circular(t * 0.12));
    canvas.drawRRect(rr, Paint()..color = _look.block);
    canvas.drawRect(Rect.fromLTWH(r.left + t * 0.1, r.top + t * 0.1, r.width - t * 0.2, t * 0.14), Paint()..color = _look.blockLight);
    final grain = Paint()
      ..color = _look.blockDark
      ..strokeWidth = 1.6;
    switch (scene.lang) {
      case Lang.python: // wooden planks
        canvas.drawLine(Offset(r.left + t * 0.1, r.center.dy), Offset(r.right - t * 0.1, r.center.dy), grain);
        canvas.drawLine(Offset(r.left + t * 0.1, r.top + t * 0.75), Offset(r.right - t * 0.1, r.top + t * 0.75), grain);
      case Lang.c: // crystal facets
        canvas.drawLine(Offset(r.left + t * 0.2, r.bottom - t * 0.15), Offset(r.center.dx, r.top + t * 0.3), grain);
        canvas.drawLine(Offset(r.center.dx, r.top + t * 0.3), Offset(r.right - t * 0.2, r.bottom - t * 0.15), grain);
      case Lang.cpp: // stone bricks
        canvas.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), grain);
        canvas.drawLine(Offset(r.center.dx, r.top + t * 0.25), Offset(r.center.dx, r.center.dy), grain);
      case Lang.java: // obsidian with glowing cracks
        final crack = Paint()
          ..color = const Color(0xFFFF8A3D)
          ..strokeWidth = 2;
        canvas.drawLine(Offset(r.left + t * 0.25, r.top + t * 0.35), Offset(r.center.dx, r.center.dy), crack);
        canvas.drawLine(Offset(r.center.dx, r.center.dy), Offset(r.right - t * 0.3, r.bottom - t * 0.25), crack);
    }
    canvas.drawRRect(rr, _inkStroke);
  }

  void _gap(Canvas canvas, Size size, StageGeometry geo) {
    final t = geo.tile;
    final gap = scene.size;
    final left = geo.x(5);
    final right = geo.x(5 + gap);
    // Hazard below.
    final surface = geo.hazardSurface;
    canvas.drawRect(Rect.fromLTRB(left, surface, right, size.height), Paint()..color = _look.hazard);
    final light = Paint()
      ..color = _look.hazardLight
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    if (scene.lang == Lang.c && !highContrast) {
      // Crystal spikes at the bottom of the pit.
      for (var c = 0.0; c < gap; c += 0.5) {
        final x = left + c * t;
        final spike = Path()
          ..moveTo(x, size.height)
          ..lineTo(x + t * 0.25, size.height - t * 0.6)
          ..lineTo(x + t * 0.5, size.height)
          ..close();
        canvas.drawPath(spike, Paint()..color = _look.hazardLight.withValues(alpha: 0.8));
      }
    } else {
      final shift = (scene.clock * t * 0.64) % (t * 0.8);
      for (var row = 0; row < 2; row++) {
        final y = surface + t * (0.25 + row * 0.4);
        for (var x = left - t + shift; x < right; x += t * 0.8) {
          final wave = Path()
            ..moveTo(math.max(left, x), y)
            ..quadraticBezierTo(x + t * 0.2, y - t * 0.12, math.min(right, x + t * 0.4), y);
          canvas.drawPath(wave, light);
        }
      }
    }
    _groundRect(canvas, geo, 0, 5, rightEdge: true);
    _groundRect(canvas, geo, 5.0 + gap, 14, leftEdge: true);

    // The bridge, then any extra blocks piling up at the far end.
    for (var k = 0; k < scene.built; k++) {
      if (k < gap) {
        _block(canvas, Rect.fromLTWH(geo.x(5 + k), geo.ground, t, t));
      } else {
        final level = k - gap + 1;
        _block(canvas, Rect.fromLTWH(geo.x(5 + gap), geo.above(level), t, t));
      }
    }

    // Splash when Byte falls in.
    if (hero.splash > 0) {
      final p = Paint()
        ..color = _look.hazardLight.withValues(alpha: 1 - hero.splash)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final c = Offset(hero.x, surface);
      canvas.drawOval(Rect.fromCenter(center: c, width: t * (0.6 + hero.splash * 1.6), height: t * (0.2 + hero.splash * 0.4)), p);
    }
  }

  void _ledge(Canvas canvas, StageGeometry geo, double fromCol, int height) {
    final t = geo.tile;
    final rect = Rect.fromLTRB(geo.x(fromCol), geo.above(height), geo.width + 4, geo.ground);
    canvas.drawRect(rect, Paint()..color = _look.ground);
    canvas.drawRect(Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + t * 0.32), Paint()..color = _look.groundTop);
    final seam = Paint()
      ..color = _look.groundDark.withValues(alpha: highContrast ? 1 : 0.35)
      ..strokeWidth = 1.5;
    for (var r = 1; r < height; r++) {
      canvas.drawLine(Offset(rect.left + 2, geo.above(r)), Offset(rect.right, geo.above(r)), seam);
    }
    final edge = _inkStroke;
    canvas.drawLine(rect.topLeft, Offset(rect.right, rect.top), edge);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, edge);
  }

  void _ceiling(Canvas canvas, StageGeometry geo) {
    final t = geo.tile;
    final bottom = geo.ceilingBottom(scene.size);
    final rect = Rect.fromLTRB(geo.x(3.2), -4, geo.width + 4, bottom);
    canvas.drawRect(rect, Paint()..color = _look.groundDark);
    final spikes = Path();
    for (var x = rect.left + t * 0.1; x < rect.right; x += t * 0.5) {
      spikes
        ..moveTo(x, bottom)
        ..lineTo(x + t * 0.25, bottom + t * 0.32)
        ..lineTo(x + t * 0.5, bottom)
        ..close();
    }
    canvas.drawPath(spikes, Paint()..color = highContrast ? Colors.white : const Color(0xFFE9E2F5));
    canvas.drawPath(spikes, _inkStroke..strokeWidth = 1.5);
    canvas.drawLine(Offset(rect.left, bottom), Offset(rect.right, bottom), _inkStroke);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left, bottom), _inkStroke);
  }

  void _stairs(Canvas canvas, StageGeometry geo) {
    final t = geo.tile;
    final h = scene.size;
    for (var k = 0; k < scene.built; k++) {
      final x = geo.x(5 + k);
      final base = k < h ? 0 : h;
      for (var level = base; level <= k; level++) {
        _block(canvas, Rect.fromLTWH(x, geo.above(level + 1), t, t));
      }
    }
  }

  double get _openAmount {
    final o = scene.outcome;
    if (o == null || !o.success) return 0;
    return (scene.act / 0.3).clamp(0.0, 1.0);
  }

  void _gate(Canvas canvas, StageGeometry geo) {
    final t = geo.tile;
    final x = geo.x(8);
    final height = t * 2.6;
    final top = geo.ground - height;
    // Stone archway: two pillars and a lintel, so the gate still stands
    // (and Byte walks through it) once the bars have lifted.
    final arch = Paint()..color = highContrast ? Colors.black : _look.groundDark;
    final stones = [
      Rect.fromLTWH(x - t * 0.35, top - t * 0.45, t * 0.15, height + t * 0.45),
      Rect.fromLTWH(x + t * 0.6, top - t * 0.45, t * 0.15, height + t * 0.45),
      Rect.fromLTWH(x - t * 0.35, top - t * 0.45, t * 1.1, t * 0.45),
    ];
    for (final stone in stones) {
      canvas
        ..drawRect(stone, arch)
        ..drawRect(stone, _inkStroke);
    }
    // Portcullis bars, lifting up when the gate opens.
    final lift = _openAmount * height;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(x - t * 0.2, top, t * 0.8, height));
    final bars = Paint()
      ..color = highContrast ? Colors.white : const Color(0xFF3A3346)
      ..strokeWidth = t * 0.12;
    for (var i = 0; i < 3; i++) {
      final bx = x + t * 0.05 + i * t * 0.22;
      canvas.drawLine(Offset(bx, top - lift), Offset(bx, geo.ground - lift), bars);
    }
    for (var j = 1; j < 4; j++) {
      final y = top + j * height / 4 - lift;
      canvas.drawLine(Offset(x - t * 0.05, y), Offset(x + t * 0.55, y), bars..strokeWidth = t * 0.08);
    }
    canvas.restore();
  }

  void _barrier(Canvas canvas, StageGeometry geo) {
    final t = geo.tile;
    final postX = geo.x(8.1);
    final postTop = geo.ground - t * 1.3;
    canvas.drawRect(Rect.fromLTWH(postX, postTop, t * 0.28, t * 1.3), Paint()..color = const Color(0xFF6A4A2A));
    canvas.drawRect(Rect.fromLTWH(postX, postTop, t * 0.28, t * 1.3), _inkStroke);
    // Striped arm pivoting at the post top; lifts up when paid.
    final pivot = Offset(postX + t * 0.14, postTop + t * 0.15);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(_openAmount * math.pi / 2);
    final arm = Rect.fromLTWH(-t * 1.9, -t * 0.12, t * 1.9, t * 0.24);
    canvas.drawRect(arm, Paint()..color = Colors.white);
    final stripe = Paint()..color = highContrast ? Colors.black : const Color(0xFFFF6B7F);
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(arm.left + i * t * 0.48, arm.top, t * 0.24, arm.height), stripe);
    }
    canvas.drawRect(arm, _inkStroke..strokeWidth = 2);
    canvas.restore();
  }

  // Byte, seen from the side and facing right: headband, mint hoodie and a
  // gold backpack with </> on it - the same hero as the rest of the game.
  void _hero(Canvas canvas, StageGeometry geo) {
    final u = geo.tile / 10;
    final ink = Paint()
      ..color = highContrast ? Colors.white : this.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const skin = Color(0xFFF5C9A0);
    const hair = Color(0xFF4A2C1A);
    const pants = Color(0xFF3B2A6B);
    final hoodie = highContrast ? const Color(0xFF00F07A) : const Color(0xFF3DDC84);
    final pack = highContrast ? const Color(0xFFFFE100) : const Color(0xFFFFC93C);

    // Shadow on the ground.
    final onGround = hero.action != HeroAction.fall && hero.action != HeroAction.jump;
    if (onGround) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(hero.x, hero.y + u * 0.6), width: u * 9, height: u * 2),
        Paint()..color = Colors.black.withValues(alpha: 0.22),
      );
    }

    canvas.save();
    canvas.translate(hero.x, hero.y);
    canvas.rotate(hero.rotation);

    final swing = hero.action == HeroAction.walk ? math.sin(hero.stride) : 0.0;
    final tucked = hero.action == HeroAction.jump || hero.action == HeroAction.fall;

    // Legs.
    void leg(double angle, double shade) {
      final hip = Offset(0, -u * 5);
      final foot = tucked
          ? hip + Offset(math.sin(angle) * u * 3 - u * 1.2, u * 3.2)
          : hip + Offset(math.sin(angle) * u * 3.2, math.cos(angle) * u * 5);
      final p = Paint()
        ..color = Color.lerp(pants, Colors.black, shade)!
        ..strokeWidth = u * 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(hip, foot, ink..strokeWidth = u * 3.6);
      canvas.drawLine(hip, foot, p);
      final shoe = Rect.fromCenter(center: foot + Offset(u * 0.7, 0), width: u * 3, height: u * 1.6);
      canvas.drawOval(shoe, Paint()..color = Colors.white);
      canvas.drawOval(shoe, ink..strokeWidth = u * 0.6);
    }

    leg(-swing * 0.5, 0.25);
    leg(swing * 0.5, 0);

    // Backpack, then body.
    final backpack = RRect.fromRectAndRadius(Rect.fromLTRB(-u * 5.4, -u * 10.2, -u * 2.2, -u * 4.8), Radius.circular(u * 1.2));
    canvas.drawRRect(backpack, Paint()..color = pack);
    canvas.drawRRect(backpack, ink..strokeWidth = u * 0.6);
    final glyph = Paint()
      ..color = highContrast ? Colors.black : this.ink
      ..strokeWidth = u * 0.45
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(-u * 3.4, -u * 8.4)
        ..lineTo(-u * 4.3, -u * 7.5)
        ..lineTo(-u * 3.4, -u * 6.6),
      glyph,
    );
    final body = RRect.fromRectAndRadius(Rect.fromLTRB(-u * 3.2, -u * 10.8, u * 3.0, -u * 4.4), Radius.circular(u * 2.4));
    canvas.drawRRect(body, Paint()..color = hoodie);
    canvas.drawRRect(body, ink..strokeWidth = u * 0.6);

    // Arm.
    final shoulder = Offset(u * 0.4, -u * 9.2);
    final armUp = tucked || hero.action == HeroAction.bonk;
    final hand = armUp
        ? shoulder + Offset(u * 2.2, -u * 3.4)
        : shoulder + Offset(math.sin(-swing * 0.6) * u * 2.8 + u * 0.6, u * 3.8);
    canvas.drawLine(shoulder, hand, ink..strokeWidth = u * 3.2);
    canvas.drawLine(
      shoulder,
      hand,
      Paint()
        ..color = hoodie
        ..strokeWidth = u * 2.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(hand, u * 1.0, Paint()..color = skin);
    canvas.drawCircle(hand, u * 1.0, ink..strokeWidth = u * 0.5);

    // Head with hair and the coral headband.
    final head = Offset(u * 0.7, -u * 14.4);
    canvas.drawCircle(head, u * 4, Paint()..color = skin);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: head, radius: u * 4)));
    canvas.drawRect(Rect.fromLTRB(head.dx - u * 5, head.dy - u * 5, head.dx + u * 5, head.dy - u * 1.4), Paint()..color = hair);
    canvas.drawRect(Rect.fromLTRB(head.dx - u * 5, head.dy - u * 5, head.dx - u * 1.6, head.dy + u * 2.2), Paint()..color = hair);
    canvas.drawRect(
      Rect.fromLTRB(head.dx - u * 5, head.dy - u * 1.9, head.dx + u * 5, head.dy - u * 0.8),
      Paint()..color = highContrast ? Colors.white : const Color(0xFFFF6B7F),
    );
    canvas.restore();
    canvas.drawCircle(head, u * 4, ink..strokeWidth = u * 0.7);
    final face = Paint()..color = highContrast ? Colors.black : this.ink;
    if (hero.action == HeroAction.bonk || hero.action == HeroAction.fall) {
      // Dizzy "x" eye.
      final e = head + Offset(u * 2.2, u * 0.4);
      final p = Paint()
        ..color = face.color
        ..strokeWidth = u * 0.5;
      canvas.drawLine(e + Offset(-u * 0.6, -u * 0.6), e + Offset(u * 0.6, u * 0.6), p);
      canvas.drawLine(e + Offset(-u * 0.6, u * 0.6), e + Offset(u * 0.6, -u * 0.6), p);
    } else {
      canvas.drawCircle(head + Offset(u * 2.2, u * 0.3), u * 0.6, face);
      canvas.drawArc(
        Rect.fromCircle(center: head + Offset(u * 2.0, u * 1.6), radius: u * 1.1),
        0.2,
        1.6,
        false,
        Paint()
          ..color = face.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.45,
      );
    }
    canvas.restore();

    if (hero.stars) {
      final star = Paint()..color = const Color(0xFFFFC93C);
      for (var i = 0; i < 3; i++) {
        final angle = scene.act * math.pi * 4 + i * 2.1;
        final c = Offset(hero.x + u * 0.7 + math.cos(angle) * u * 4.5, hero.y - u * 19 + math.sin(angle) * u * 1.2);
        _star(canvas, c, u * 1.3, star);
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, _inkStroke..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(StagePainter old) => true;
}
