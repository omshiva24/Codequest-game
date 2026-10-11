import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/curriculum.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'navigation.dart';

/// A winding adventure map. Level 1 is at the bottom; the boss waits at the top.
class WorldScreen extends StatelessWidget {
  const WorldScreen({super.key, required this.lang});

  final Lang lang;

  static const double _spacing = 175;
  static const double _bottomPad = 175;
  static const List<double> _xs = [0.3, 0.7, 0.32, 0.68, 0.5];

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final g = GameColors.of(context);
    final levels = levelsFor(lang);
    final stars = progress.worldStars(lang);

    // The level to play next: first unlocked level without stars.
    final nextIndex = levels.indexWhere((l) => progress.isUnlocked(l) && progress.starsFor(l.id) == 0);

    return GameScaffold(
      scene: sceneFor(lang),
      title: lang.worldName,
      actions: [
        HudPill(
          leading: Icon(Icons.star_rounded, color: g.gold, size: 26),
          text: '$stars/${levels.length * 3}',
          semanticLabel: '$stars of ${levels.length * 3} stars in this world',
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 600.0);
          final height = levels.length * _spacing + _bottomPad;
          Offset nodeCenter(int i) => Offset(
                _xs[i % _xs.length] * width,
                height - _bottomPad + 40 - i * _spacing,
              );
          final points = [for (var i = 0; i < levels.length; i++) nodeCenter(i)];

          return SingleChildScrollView(
            reverse: true,
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _PathPainter(
                            points: points,
                            doneUpTo: nextIndex < 0 ? levels.length - 1 : nextIndex,
                            g: g,
                            road: paletteFor(sceneFor(lang), highContrast: g.highContrast).road,
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < levels.length; i++)
                      Positioned(
                        left: points[i].dx - 105,
                        top: points[i].dy - (levels[i].isBoss ? 62 : 52),
                        width: 210,
                        child: _LevelNode(level: levels[i], isNext: i == nextIndex),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.level, required this.isNext});

  final Level level;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final g = GameColors.of(context);
    final unlocked = progress.isUnlocked(level);
    final stars = progress.starsFor(level.id);
    final size = level.isBoss ? 104.0 : 84.0;

    final status = !unlocked
        ? 'Locked. Finish level ${level.number - 1} to unlock.'
        : stars > 0
            ? '$stars of 3 stars.'
            : 'Not played yet.';

    void onTap() {
      if (unlocked) {
        openLesson(context, level);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Finish level ${level.number - 1} first to unlock "${level.title}".'),
          ));
      }
    }

    final face = unlocked ? level.lang.color : g.disabled;
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: g.highContrast
            ? null
            : RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [Color.lerp(face, Colors.white, 0.45)!, face],
              ),
        color: g.highContrast ? face : null,
        border: Border.all(color: g.ink, width: g.outlineWidth + 1),
        boxShadow: [
          BoxShadow(color: g.ink, offset: const Offset(0, 7)),
          BoxShadow(color: Color.lerp(face, g.ink, 0.45)!, offset: const Offset(0, 5)),
        ],
      ),
      child: !unlocked
          ? Icon(Icons.lock_rounded, size: size * 0.42, color: g.ink)
          : level.isBoss && level.enemy != null
              ? Emoji(level.enemy!.emoji, size: size * 0.5)
              : Text('${level.number}', style: displayStyle(size * 0.5, color: g.ink)),
    );

    return Pressable(
      semanticLabel: 'Level ${level.number}: ${level.title}. ${level.kind.label}'
          '${level.isBoss ? ', boss level' : ''}. $status',
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: size + 12,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (isNext) PulseRing(size: size, color: g.gold),
                circle,
                if (stars == 3)
                  Positioned(
                    right: 40,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: g.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: g.ink, width: 2.5),
                      ),
                      child: Icon(Icons.check_rounded, size: 18, color: g.ink),
                    ),
                  ),
                if (isNext)
                  Positioned(
                    top: -54,
                    child: Bob(
                      amplitude: 7,
                      period: 1200,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: g.gold,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: g.ink, width: 2.5),
                            ),
                            child: Text('Play', style: displayStyle(17, color: g.ink)),
                          ),
                          Icon(Icons.arrow_drop_down_rounded, size: 34, color: g.ink),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
            decoration: BoxDecoration(
              color: g.parchment,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: g.ink, width: 2.5),
              boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 3))],
            ),
            child: Column(
              children: [
                Text(level.title,
                    textAlign: TextAlign.center,
                    style: displayStyle(18, color: g.ink, height: 1.15)),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(level.kind.icon, size: 16, color: g.parchmentDim),
                    const SizedBox(width: 4),
                    Text(level.kind.label, style: TextStyle(color: g.parchmentDim, fontSize: 13)),
                    const SizedBox(width: 6),
                    StarRow(stars: stars, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The road between level nodes: dashed and gold where you have been.
class _PathPainter extends CustomPainter {
  _PathPainter({required this.points, required this.doneUpTo, required this.g, required this.road});

  final List<Offset> points;
  final int doneUpTo;
  final GameColors g;
  final Color road;

  Path _segment(Offset a, Offset b) {
    final midY = (a.dy + b.dy) / 2;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final outline = Paint()
      ..color = g.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44
      ..strokeCap = StrokeCap.round;
    final base = Paint()
      ..color = g.highContrast ? Colors.black : road
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round;
    final done = Paint()
      ..color = g.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round;
    final dash = Paint()
      ..color = g.highContrast ? Colors.white : g.parchment.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawPath(_segment(points[i], points[i + 1]), outline);
    }
    for (var i = 0; i < points.length - 1; i++) {
      final seg = _segment(points[i], points[i + 1]);
      canvas.drawPath(seg, i < doneUpTo ? done : base);
      for (final metric in seg.computeMetrics()) {
        for (var d = 10.0; d < metric.length - 10; d += 26) {
          canvas.drawPath(metric.extractPath(d, d + 12), dash);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.doneUpTo != doneUpTo || old.points != points || old.g != g;
}
