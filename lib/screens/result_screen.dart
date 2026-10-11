import 'package:flutter/material.dart';

import '../data/curriculum.dart';
import '../logic/progress.dart';
import '../services/sound.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'navigation.dart';

/// The celebration (or "try again") screen after a level.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.outcome, required this.reward});

  final GameOutcome outcome;
  final LevelReward reward;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final level = outcome.level;
    final next = nextLevel(level);
    final won = outcome.won;
    final headline = won ? (level.isBoss ? 'Boss defeated!' : 'Level clear!') : 'Out of hearts!';

    return _ResultSounds(
      outcome: outcome,
      reward: reward,
      child: Stack(
        children: [
          Positioned.fill(child: SceneBackground(kind: won ? SceneKind.victory : SceneKind.defeat)),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: PageBody(
                maxWidth: 680,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                  children: [
                    Center(child: PopIn(child: Emoji(won ? (level.isBoss ? '🏆' : '🎉') : '💥', size: 76))),
                    const SizedBox(height: 6),
                    Center(
                      child: Semantics(
                        liveRegion: true,
                        child: OutlinedText(
                          headline,
                          size: 46,
                          header: true,
                          textAlign: TextAlign.center,
                          color: won ? g.gold : g.coral,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.75),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          won
                              ? 'You got ${outcome.correct} of ${outcome.total} right first time.'
                              : 'Every bug makes you a stronger coder. Read the tips below and try again!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: g.onNight, fontSize: 16, height: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Semantics(
                      label: '${outcome.stars} of 3 stars',
                      container: true,
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding: EdgeInsets.only(bottom: i == 1 ? 18 : 0),
                                child: PopIn(
                                  delay: Duration(milliseconds: 350 + i * 300),
                                  child: GameStar(filled: i < outcome.stars, size: i == 1 ? 70 : 56, g: g),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ParchmentPanel(
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 22,
                            runSpacing: 12,
                            children: [
                              _RewardStat(
                                icon: Icon(Icons.bolt_rounded, color: g.ink, size: 30),
                                value: reward.xp,
                                label: 'XP',
                              ),
                              _RewardStat(icon: const CoinIcon(size: 28), value: reward.coins, label: 'coins'),
                              if (outcome.bestCombo >= 2)
                                _RewardStat(
                                  icon: const Emoji('⚡', size: 26),
                                  value: outcome.bestCombo,
                                  label: 'best combo',
                                  prefix: 'x',
                                ),
                            ],
                          ),
                          if (reward.newBest && reward.stars > 0 || reward.leveledUp || reward.unlockedNext != null) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (reward.newBest && reward.stars > 0)
                                  const PanelBanner(text: 'New best!', tone: ButtonTone.gold, icon: Icons.emoji_events_rounded),
                                if (reward.leveledUp)
                                  const PanelBanner(text: 'Level up!', tone: ButtonTone.lilac, icon: Icons.arrow_circle_up_rounded),
                                if (reward.unlockedNext != null)
                                  PanelBanner(
                                    text: 'Unlocked: ${reward.unlockedNext!.title}',
                                    tone: ButtonTone.mint,
                                    icon: Icons.lock_open_rounded,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    for (final (i, badge) in reward.newAchievements.indexed) ...[
                      const SizedBox(height: 8),
                      PopIn(
                        delay: Duration(milliseconds: 1300 + i * 250),
                        child: ParchmentPanel(
                          color: g.gold,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: g.parchment,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: g.ink, width: 3),
                                ),
                                child: Emoji(badge.emoji, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Badge unlocked: ${badge.title}', style: displayStyle(20, color: g.ink)),
                                    Text(badge.description, style: TextStyle(color: g.ink, fontSize: 15)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (won && next != null)
                      GameButton(
                        autofocus: true,
                        expand: true,
                        size: GameButtonSize.large,
                        onPressed: () => openLesson(context, next, replace: true),
                        icon: Icons.skip_next_rounded,
                        label: 'Next: ${next.title}',
                      ),
                    if (won && next == null)
                      GameButton(
                        autofocus: true,
                        expand: true,
                        size: GameButtonSize.large,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icons.map_rounded,
                        label: 'World complete! Back to map',
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: GameButton(
                            autofocus: !won,
                            tone: won ? ButtonTone.sky : ButtonTone.gold,
                            expand: true,
                            onPressed: () => startGame(context, level),
                            icon: Icons.replay_rounded,
                            label: 'Play again',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GameButton(
                            tone: ButtonTone.parchment,
                            expand: true,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icons.map_rounded,
                            label: 'World map',
                          ),
                        ),
                      ],
                    ),
                    if (outcome.review.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const OutlinedText('Learn from your mistakes', size: 28, header: true),
                      const SizedBox(height: 10),
                      for (final item in outcome.review) ...[
                        ParchmentPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.prompt, style: displayStyle(20, color: g.ink, height: 1.25)),
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
                                    style: const TextStyle(fontFamily: codeFont, fontWeight: FontWeight.w700),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 6),
                              Text(item.explanation, style: TextStyle(color: g.parchmentDim, height: 1.45)),
                              const SizedBox(height: 10),
                              GameButton(
                                tone: ButtonTone.sky,
                                size: GameButtonSize.small,
                                onPressed: () => openDoubtBuddy(
                                  context,
                                  lang: level.lang,
                                  question: item.prompt,
                                  extraContext:
                                      '${item.code ?? ''}\nAnswer: ${item.correctAnswer}. ${item.explanation}',
                                ),
                                icon: Icons.support_agent_rounded,
                                label: 'Still confused? Ask Doubt Buddy',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: ConfettiBurst(trigger: won ? 1 : 0)),
        ],
      ),
    );
  }
}

class _RewardStat extends StatelessWidget {
  const _RewardStat({required this.icon, required this.value, required this.label, this.prefix = '+'});

  final Widget icon;
  final int value;
  final String label;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      label: '$prefix$value $label',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(value: value, prefix: prefix, style: displayStyle(30, color: g.ink, height: 1)),
                Text(label, style: TextStyle(color: g.parchmentDim, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Plays the result jingles once: victory (or defeat), a ping for every star
/// as it pops in, then level-up and badge sounds.
class _ResultSounds extends StatefulWidget {
  const _ResultSounds({required this.outcome, required this.reward, required this.child});

  final GameOutcome outcome;
  final LevelReward reward;
  final Widget child;

  @override
  State<_ResultSounds> createState() => _ResultSoundsState();
}

class _ResultSoundsState extends State<_ResultSounds> {
  @override
  void initState() {
    super.initState();
    final won = widget.outcome.won;
    // Timings match the PopIn delays of the stars and badges on this screen.
    final steps = <(Sfx, Duration)>[
      (won ? Sfx.victory : Sfx.defeat, Duration.zero),
      if (won)
        for (var i = 0; i < widget.outcome.stars; i++)
          (Sfx.star, Duration(milliseconds: 650 + i * 300)),
      if (widget.reward.leveledUp) (Sfx.levelUp, const Duration(milliseconds: 1700)),
      if (widget.reward.newAchievements.isNotEmpty)
        (Sfx.badge, Duration(milliseconds: widget.reward.leveledUp ? 2300 : 1600)),
    ];
    SoundFx.playSequence(steps);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
