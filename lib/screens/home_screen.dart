import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/curriculum.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';
import 'settings_screen.dart';
import 'world_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final g = GameColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('CodeQuest'),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings and accessibility',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(gameRoute<void>(const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDoubtBuddy(context),
        icon: const Icon(Icons.support_agent_rounded),
        label: const Text('Doubt Buddy'),
        tooltip: 'Ask Byte the Doubt Buddy a question',
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            const _HeroCard(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Emoji('🧑‍💻', size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(progress.rankTitle,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              Text('Player level ${progress.playerLevel}',
                                  style: TextStyle(color: g.textDim)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Experience to next level',
                      value: '${(progress.levelProgress * 100).round()} percent',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.levelProgress,
                          minHeight: 12,
                          color: g.coin,
                          backgroundColor: g.cardRaised,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatPill(
                          icon: Icons.bolt_rounded,
                          value: '${progress.xp} XP',
                          semanticLabel: '${progress.xp} experience points',
                        ),
                        StatPill(
                          icon: Icons.monetization_on_rounded,
                          value: '${progress.coins}',
                          semanticLabel: '${progress.coins} coins',
                        ),
                        StatPill(
                          icon: Icons.local_fire_department_rounded,
                          value: '${progress.streak} day streak',
                          semanticLabel: '${progress.streak} day playing streak',
                          color: const Color(0xFFFF9D5C),
                        ),
                        StatPill(
                          icon: Icons.star_rounded,
                          value: '${progress.totalStars} / ${allLevels.length * 3}',
                          semanticLabel: '${progress.totalStars} of ${allLevels.length * 3} stars collected',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text('Choose your world',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 560 ? 2 : 1;
                final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final lang in Lang.values)
                      SizedBox(width: width, child: WorldCard(lang: lang)),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: g.border, width: 2),
        gradient: LinearGradient(
          colors: [g.cardRaised, g.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Emoji('🦉', size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learn to code by playing!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Run through answer gates, battle bug monsters and build programs '
                  'block by block. Python, C, C++ and Java - one level at a time.',
                  style: TextStyle(color: g.textDim, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
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

    return Semantics(
      button: true,
      label: '${lang.worldName}. Learn ${lang.label}. '
          '$done of ${levels.length} levels done, $stars of ${levels.length * 3} stars.',
      excludeSemantics: true,
      onTap: () => Navigator.of(context).push(gameRoute<void>(WorldScreen(lang: lang))),
      child: Material(
        color: g.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lang.color, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(gameRoute<void>(WorldScreen(lang: lang))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: lang.color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: lang.color, width: 2),
                  ),
                  child: Emoji(lang.emoji, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.worldName,
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w700, color: lang.color)),
                      const SizedBox(height: 2),
                      Text(lang.tagline, style: TextStyle(color: g.textDim, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: g.coin, size: 22),
                          const SizedBox(width: 4),
                          Text('$stars/${levels.length * 3}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 14),
                          Icon(Icons.flag_rounded, color: lang.color, size: 20),
                          const SizedBox(width: 4),
                          Text('$done/${levels.length} levels',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
