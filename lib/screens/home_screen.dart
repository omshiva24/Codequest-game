// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/curriculum.dart';
import '../data/fun_facts.dart';
import '../logic/achievements.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'about_screen.dart';
import 'achievements_screen.dart';
import 'navigation.dart';
import 'settings_screen.dart';
import 'world_screen.dart';

/// The hub: player HUD, the four worlds, a daily fact and the Doubt Buddy.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: SceneBackground(kind: SceneKind.menu)),
        Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: MediaQuery.sizeOf(context).width < 600
              ? GameButton(
                  tone: ButtonTone.sky,
                  circle: true,
                  size: GameButtonSize.large,
                  tooltip: 'Doubt Buddy',
                  semanticLabel: 'Doubt Buddy: ask Byte a question',
                  onPressed: () => openDoubtBuddy(context),
                  child: const Emoji('🦉', size: 32),
                )
              : GameButton(
                  tone: ButtonTone.sky,
                  semanticLabel: 'Doubt Buddy: ask Byte a question',
                  onPressed: () => openDoubtBuddy(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Emoji('🦉', size: 26), SizedBox(width: 8), _FabLabel()],
                  ),
                ),
          body: SafeArea(
            child: PageBody(
              maxWidth: 980,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  const _PlayerHud(),
                  const SizedBox(height: 22),
                  const OutlinedText('Choose your world', size: 32, header: true),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 620 ? 2 : 1;
                      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final lang in Lang.values) SizedBox(width: width, child: WorldCard(lang: lang)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const _FactCard(),
                  const SizedBox(height: 20),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: const CreatorCredit(showCopyright: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FabLabel extends StatelessWidget {
  const _FabLabel();

  @override
  Widget build(BuildContext context) =>
      Text('Doubt Buddy', style: displayStyle(20, color: GameColors.of(context).ink));
}

class _PlayerHud extends StatelessWidget {
  const _PlayerHud();

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final g = GameColors.of(context);
    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: g.lilac,
            border: Border.all(color: g.ink, width: g.outlineWidth),
            boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 4))],
          ),
          child: const Emoji('🧑‍💻', size: 34),
        ),
        Positioned(
          right: -6,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: g.gold,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: g.ink, width: 2.5),
            ),
            child: Text('${progress.playerLevel}', style: displayStyle(16, color: g.ink)),
          ),
        ),
      ],
    );

    final identity = Semantics(
      container: true,
      label: '${progress.rankTitle}, player level ${progress.playerLevel}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedText(progress.rankTitle, size: 22),
                const SizedBox(height: 6),
                SizedBox(width: 150, child: XpBar(progress: progress.levelProgress)),
              ],
            ),
          ],
        ),
      ),
    );

    final pills = Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        HudPill(
          leading: const CoinIcon(),
          text: '${progress.coins}',
          semanticLabel: '${progress.coins} coins',
        ),
        HudPill(
          leading: const Emoji('🔥', size: 20),
          text: '${progress.streak}',
          semanticLabel: '${progress.streak} day streak',
        ),
        HudPill(
          leading: Icon(Icons.star_rounded, color: g.gold, size: 26),
          text: '${progress.totalStars}/${allLevels.length * 3}',
          semanticLabel: '${progress.totalStars} of ${allLevels.length * 3} stars',
        ),
      ],
    );

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconButton(
          icon: Icons.emoji_events_rounded,
          tooltip: 'Trophy room: ${progress.achievementCount} of ${achievements.length} badges',
          tone: ButtonTone.gold,
          onPressed: () => Navigator.of(context).push(gameRoute<void>(const AchievementsScreen())),
        ),
        const SizedBox(width: 10),
        RoundIconButton(
          icon: Icons.settings_rounded,
          tooltip: 'Settings and accessibility',
          onPressed: () => Navigator.of(context).push(gameRoute<void>(const SettingsScreen())),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Expanded(child: identity), buttons]),
              const SizedBox(height: 12),
              pills,
            ],
          );
        }
        return Row(
          children: [
            identity,
            const SizedBox(width: 16),
            Expanded(child: Align(alignment: Alignment.centerRight, child: pills)),
            const SizedBox(width: 16),
            buttons,
          ],
        );
      },
    );
  }
}

class WorldCard extends StatelessWidget {
  const WorldCard({super.key, required this.lang});

  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final g = GameColors.of(context);
    final levels = levelsFor(lang);
    final done = levels.where((l) => progress.starsFor(l.id) > 0).length;
    final stars = progress.worldStars(lang);
    final complete = done == levels.length;

    return Pressable(
      semanticLabel: '${lang.worldName}. Learn ${lang.label}. '
          '$done of ${levels.length} levels done, $stars of ${levels.length * 3} stars.',
      onTap: () => Navigator.of(context).push(gameRoute<void>(WorldScreen(lang: lang))),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: g.outlineWidth),
            boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 6))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: SceneBackground(kind: sceneFor(lang), animate: false)),
              Positioned(
                left: 14,
                top: 12,
                right: 14,
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: g.parchment,
                        border: Border.all(color: g.ink, width: g.outlineWidth),
                      ),
                      child: Emoji(lang.emoji, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: OutlinedText(lang.worldName, size: 32),
                      ),
                    ),
                    if (complete) const Emoji('🏆', size: 30),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: g.parchment,
                    border: Border(top: BorderSide(color: g.ink, width: g.outlineWidth)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang.tagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: g.parchmentDim, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 2,
                              children: [
                                GameStar(filled: true, size: 18, g: g),
                                const SizedBox(width: 4),
                                Text('$stars/${levels.length * 3}', style: displayStyle(18, color: g.ink)),
                                const SizedBox(width: 14),
                                Icon(Icons.flag_rounded, color: g.ink, size: 20),
                                const SizedBox(width: 4),
                                Text('$done/${levels.length} levels', style: displayStyle(18, color: g.ink)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: g.gold,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: g.ink, width: 2.5),
                          boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 3))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: g.ink),
                            Text(done == 0 ? 'Start' : 'Play', style: displayStyle(18, color: g.ink)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard();

  @override
  Widget build(BuildContext context) {
    return ParchmentPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ByteAvatar(size: 56, bob: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelBanner(text: 'Did you know?', tone: ButtonTone.lilac, icon: Icons.lightbulb_rounded),
                const SizedBox(height: 8),
                Text(factOfTheDay(DateTime.now()), style: const TextStyle(fontSize: 16, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
