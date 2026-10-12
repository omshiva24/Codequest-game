import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'navigation.dart';

/// Before each level, Byte explains the idea in a short dialogue.
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.level});

  final Level level;

  /// Splits the story into speech bubbles of about two sentences.
  static List<String> bubbles(String story) {
    final sentences = story.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().isNotEmpty).toList();
    final out = <String>[];
    for (var i = 0; i < sentences.length; i += 2) {
      out.add(sentences.skip(i).take(2).join(' '));
    }
    return out;
  }

  ButtonTone get _kindTone => switch (level.kind) {
        LevelKind.builder => ButtonTone.sky,
        LevelKind.battle => ButtonTone.coral,
        LevelKind.puzzle => ButtonTone.lilac,
      };

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final lesson = level.lesson;
    final parts = bubbles(lesson.story);

    return GameScaffold(
      scene: sceneFor(level.lang),
      title: 'Level ${level.number}: ${level.title}',
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PanelBanner(text: level.kind.label, tone: _kindTone, icon: level.kind.icon),
                if (level.isBoss) const PanelBanner(text: 'Boss level', tone: ButtonTone.coral, icon: Icons.whatshot_rounded),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(top: 4), child: ByteAvatar(size: 64)),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PopIn(
                        child: SpeechBubble(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Today's mission", style: TextStyle(color: g.parchmentDim, fontSize: 14)),
                              Semantics(
                                header: true,
                                child: Text(lesson.title, style: displayStyle(26, color: g.ink)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (var i = 0; i < parts.length; i++) ...[
                        const SizedBox(height: 8),
                        PopIn(
                          delay: Duration(milliseconds: 260 * (i + 1)),
                          child: SpeechBubble(
                            child: Text(parts[i], style: const TextStyle(fontSize: 17, height: 1.5)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ParchmentPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelBanner(text: 'See it in code', tone: ButtonTone.sky, icon: Icons.code_rounded),
                  const SizedBox(height: 12),
                  CodeBlock(lesson.code, fileName: level.lang.fileName),
                  const SizedBox(height: 16),
                  const PanelBanner(text: 'Remember', tone: ButtonTone.mint, icon: Icons.bookmark_rounded),
                  const SizedBox(height: 8),
                  for (final point in lesson.keyPoints)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GameStar(filled: true, size: 18, g: g),
                          const SizedBox(width: 10),
                          Expanded(child: Text(point, style: const TextStyle(fontSize: 16, height: 1.45))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ParchmentPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelBanner(text: 'How to play', tone: ButtonTone.gold, icon: Icons.sports_esports_rounded),
                  const SizedBox(height: 10),
                  Text(level.kind.howToPlay, style: const TextStyle(fontSize: 16, height: 1.5)),
                  if (level.enemy != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Emoji(level.enemy!.emoji, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enemy: ${level.enemy!.name}',
                            style: displayStyle(20, color: g.ink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            GameButton(
              autofocus: true,
              size: GameButtonSize.large,
              expand: true,
              onPressed: () => startGame(context, level),
              icon: Icons.play_arrow_rounded,
              label: 'Start ${level.kind.label}',
            ),
            const SizedBox(height: 6),
            GameButton(
              tone: ButtonTone.sky,
              expand: true,
              onPressed: () => openDoubtBuddy(context, lang: level.lang),
              icon: Icons.support_agent_rounded,
              label: 'I have a doubt',
            ),
          ],
        ),
      ),
    );
  }
}
