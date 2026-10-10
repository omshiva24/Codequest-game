import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/curriculum.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';

/// A Mario-style level path for one language world.
class WorldScreen extends StatelessWidget {
  const WorldScreen({super.key, required this.lang});

  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final g = GameColors.of(context);
    final levels = levelsFor(lang);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(lang.worldName)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatPill(
              icon: Icons.star_rounded,
              value: '${progress.worldStars(lang)}/${levels.length * 3}',
              semanticLabel: '${progress.worldStars(lang)} of ${levels.length * 3} stars in this world',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lang.color.withValues(alpha: 0.16), g.background],
          ),
        ),
        child: PageBody(
          maxWidth: 640,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(
                children: [
                  Emoji(lang.emoji, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(lang.tagline,
                        style: TextStyle(color: g.textDim, fontSize: 16, height: 1.4)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < levels.length; i++) ...[
                if (i > 0) _PathConnector(fromLeft: i.isOdd, color: lang.color),
                Align(
                  alignment: Alignment(i.isEven ? -0.55 : 0.55, 0),
                  child: _LevelNode(level: levels[i]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final g = GameColors.of(context);
    final unlocked = progress.isUnlocked(level);
    final stars = progress.starsFor(level.id);
    final color = level.lang.color;

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

    return Semantics(
      button: true,
      enabled: true,
      label: 'Level ${level.number}: ${level.title}. ${level.kind.label}'
          '${level.isBoss ? ', boss level' : ''}. $status',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 210,
            child: Column(
              children: [
                Container(
                  width: level.isBoss ? 96 : 80,
                  height: level.isBoss ? 96 : 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked ? color : g.cardRaised,
                    border: Border.all(color: unlocked ? Colors.white : g.border, width: 4),
                    boxShadow: unlocked
                        ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16)]
                        : null,
                  ),
                  child: unlocked
                      ? (level.isBoss && level.enemy != null
                          ? Emoji(level.enemy!.emoji, size: 40)
                          : Text('${level.number}',
                              style: TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.w700, color: g.onAccent)))
                      : Icon(Icons.lock_rounded, size: 32, color: g.textDim),
                ),
                const SizedBox(height: 8),
                Text(level.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(level.kind.icon, size: 18, color: g.textDim),
                    const SizedBox(width: 4),
                    Text(level.kind.label, style: TextStyle(color: g.textDim, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                StarRow(stars: stars, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dotted diagonal line joining two level nodes.
class _PathConnector extends StatelessWidget {
  const _PathConnector({required this.fromLeft, required this.color});

  final bool fromLeft;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: CustomPaint(painter: _DotsPainter(fromLeft: fromLeft, color: color)),
        ),
      );
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.fromLeft, required this.color});

  final bool fromLeft;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.8);
    final startX = size.width * (fromLeft ? 0.3 : 0.7);
    final endX = size.width * (fromLeft ? 0.7 : 0.3);
    const dots = 7;
    for (var i = 0; i <= dots; i++) {
      final t = i / dots;
      canvas.drawCircle(Offset(startX + (endX - startX) * t, size.height * t), 4, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.fromLeft != fromLeft || old.color != color;
}
