import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/curriculum.dart';
import '../logic/progress.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.outcome, required this.reward});

  final GameOutcome outcome;
  final LevelReward reward;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final level = outcome.level;
    final next = nextLevel(level);
    final reduceMotion = reduceMotionOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(level.title),
        automaticallyImplyLeading: false,
      ),
      body: PageBody(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(child: Emoji(outcome.won ? (level.isBoss ? '🏆' : '🎉') : '💥', size: 72)),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                outcome.won ? (level.isBoss ? 'Boss defeated!' : 'Level complete!') : 'Out of hearts!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              outcome.won
                  ? 'You got ${outcome.correct} of ${outcome.total} right first time.'
                  : 'Every bug you meet makes you a stronger coder. Read the tips below and try again!',
              textAlign: TextAlign.center,
              style: TextStyle(color: g.textDim, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: reduceMotion ? 1 : 0.4, end: 1),
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: StarRow(stars: outcome.stars, size: 56),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                StatPill(
                  icon: Icons.bolt_rounded,
                  value: '+${reward.xp} XP',
                  semanticLabel: 'Plus ${reward.xp} experience points',
                ),
                StatPill(
                  icon: Icons.monetization_on_rounded,
                  value: '+${reward.coins}',
                  semanticLabel: 'Plus ${reward.coins} coins',
                ),
                if (reward.newBest && reward.stars > 0)
                  const StatPill(
                    icon: Icons.emoji_events_rounded,
                    value: 'New best!',
                    semanticLabel: 'New best score',
                  ),
                if (reward.leveledUp)
                  const StatPill(
                    icon: Icons.arrow_circle_up_rounded,
                    value: 'Level up!',
                    semanticLabel: 'You reached a new player level',
                  ),
              ],
            ),
            if (reward.unlockedNext != null) ...[
              const SizedBox(height: 12),
              Text(
                'Unlocked: Level ${reward.unlockedNext!.number} - ${reward.unlockedNext!.title}',
                textAlign: TextAlign.center,
                style: TextStyle(color: g.good, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
            const SizedBox(height: 20),
            if (outcome.won && next != null)
              FilledButton.icon(
                autofocus: true,
                onPressed: () => openLesson(context, next, replace: true),
                icon: const Icon(Icons.skip_next_rounded),
                label: Text('Next: ${next.title}'),
              ),
            if (outcome.won && next == null)
              FilledButton.icon(
                autofocus: true,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.map_rounded),
                label: const Text('World complete! Back to map'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              autofocus: !outcome.won,
              onPressed: () => startGame(context, level),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play again'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.map_rounded),
              label: const Text('World map'),
            ),
            if (outcome.review.isNotEmpty) ...[
              const SizedBox(height: 28),
              Semantics(
                header: true,
                child: Text('Learn from your mistakes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: g.coin)),
              ),
              const SizedBox(height: 10),
              for (final item in outcome.review) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.prompt,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        if (item.code != null) ...[
                          const SizedBox(height: 8),
                          CodeBlock(item.code!, fontSize: 14),
                        ],
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Answer: '),
                            TextSpan(
                              text: item.correctAnswer,
                              style: TextStyle(fontFamily: codeFont, color: g.good, fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Text(item.explanation, style: TextStyle(color: g.textDim, height: 1.4)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => openDoubtBuddy(
                            context,
                            lang: level.lang,
                            question: item.prompt,
                            extraContext: '${item.code ?? ''}\nAnswer: ${item.correctAnswer}. '
                                '${item.explanation}',
                          ),
                          icon: const Icon(Icons.support_agent_rounded),
                          label: const Text('Still confused? Ask Doubt Buddy'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
