import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';

/// The "lesson scroll" read before a level starts.
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final lesson = level.lesson;
    final color = level.lang.color;

    return Scaffold(
      appBar: AppBar(title: Text('${level.lang.worldName} - Level ${level.number}')),
      body: PageBody(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                Icon(level.kind.icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(level.kind.label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
                if (level.isBoss) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: g.bad,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('BOSS',
                        style: TextStyle(color: g.onAccent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: Text(level.title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Emoji('📜', size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(lesson.title,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(lesson.story, style: const TextStyle(fontSize: 17, height: 1.55)),
                    const SizedBox(height: 14),
                    CodeBlock(lesson.code),
                    const SizedBox(height: 14),
                    Semantics(
                      header: true,
                      child: Text('Remember',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700, color: g.coin)),
                    ),
                    const SizedBox(height: 6),
                    for (final point in lesson.keyPoints)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_rounded, color: g.good, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(point, style: const TextStyle(fontSize: 16, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Emoji('🎮', size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('How to play',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(level.kind.howToPlay, style: const TextStyle(fontSize: 16, height: 1.45)),
                        if (level.enemy != null) ...[
                          const SizedBox(height: 6),
                          Text('Enemy: ${level.enemy!.name} ${level.enemy!.emoji}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              autofocus: true,
              onPressed: () => startGame(context, level),
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text('Start ${level.kind.label}'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => openDoubtBuddy(context, lang: level.lang),
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('I have a doubt'),
            ),
          ],
        ),
      ),
    );
  }
}
