// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../logic/achievements.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';

/// Trophy room: every badge, earned or still locked (with how to get it).
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final g = GameColors.of(context);
    final unlocked = progress.achievementCount;

    return GameScaffold(
      scene: SceneKind.menu,
      title: 'Trophy room',
      actions: [
        HudPill(
          leading: const Emoji('🏅', size: 20),
          text: '$unlocked/${achievements.length}',
          semanticLabel: '$unlocked of ${achievements.length} badges unlocked',
        ),
      ],
      body: PageBody(
        maxWidth: 900,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            ParchmentPanel(
              child: Row(
                children: [
                  const ByteAvatar(size: 56, bob: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      unlocked == 0
                          ? 'No badges yet. Finish your first level to earn one!'
                          : 'You have $unlocked of ${achievements.length} badges. Keep going!',
                      style: displayStyle(20, color: g.ink, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 440 ? 2 : 1);
                final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (final a in achievements)
                      SizedBox(width: width, child: _Badge(achievement: a, unlocked: progress.hasAchievement(a.id))),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      container: true,
      label: '${achievement.title}: ${unlocked ? 'unlocked' : 'locked'}. ${achievement.description}',
      child: ExcludeSemantics(
        child: ParchmentPanel(
          color: unlocked ? g.parchment : Color.lerp(g.parchment, g.disabled, 0.5),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked ? g.gold : g.disabled,
                  border: Border.all(color: g.ink, width: 3),
                  boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 3))],
                ),
                child: unlocked
                    ? Emoji(achievement.emoji, size: 30)
                    : Icon(Icons.lock_rounded, color: g.ink, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achievement.title, style: displayStyle(20, color: g.ink)),
                    Text(achievement.description, style: TextStyle(color: g.parchmentText, fontSize: 14, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
