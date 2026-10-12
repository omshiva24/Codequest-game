// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'game_ui.dart';

/// Code shown in a small "editor window": title bar, line numbers, monospace.
class CodeBlock extends StatelessWidget {
  const CodeBlock(this.code, {super.key, this.fontSize = 15, this.fileName});

  final String code;
  final double fontSize;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final lines = code.split('\n');
    final style = TextStyle(fontFamily: codeFont, fontSize: fontSize, height: 1.5, color: g.codeText);
    return Semantics(
      label: fileName == null ? 'Code' : 'Code, $fileName',
      container: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: g.codeBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: g.outlineWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Container(
                color: g.codeBar,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  children: [
                    for (final c in const [Color(0xFFFF6B7F), Color(0xFFFFC93C), Color(0xFF3DDC84)])
                      Container(
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                    if (fileName != null) ...[
                      const SizedBox(width: 6),
                      Text(fileName!, style: TextStyle(fontFamily: codeFont, fontSize: 13, color: g.codeDim)),
                    ],
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(10, 10, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      [for (var i = 1; i <= lines.length; i++) '$i'].join('\n'),
                      textAlign: TextAlign.right,
                      style: style.copyWith(color: g.codeDim),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SelectableText(code, style: style),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hearts (lives). Read out as "2 of 3 hearts left".
class HeartsBar extends StatelessWidget {
  const HeartsBar({super.key, required this.lives, required this.max, this.size = 26});

  final int lives;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      label: '$lives of $max hearts left',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < max; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.favorite_rounded, color: g.ink, size: size + 6),
                    Icon(
                      i < lives ? Icons.favorite_rounded : Icons.heart_broken_rounded,
                      color: i < lives ? g.coral : g.disabled,
                      size: size,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 0-3 stars. Read out as "2 of 3 stars".
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 22});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      label: '$stars of 3 stars',
      container: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) GameStar(filled: i < stars, size: size, g: g),
          ],
        ),
      ),
    );
  }
}

/// One outlined star.
class GameStar extends StatelessWidget {
  const GameStar({super.key, required this.filled, required this.size, required this.g});

  final bool filled;
  final double size;
  final GameColors g;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, color: g.ink, size: size * 1.3),
          Icon(Icons.star_rounded, color: filled ? g.gold : g.disabled, size: size),
        ],
      );
}

/// Emoji that screen readers skip (they are decoration).
class Emoji extends StatelessWidget {
  const Emoji(this.emoji, {super.key, this.size = 28});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Text(emoji, style: TextStyle(fontSize: size, height: 1.15)),
      );
}

/// Shows text that may contain ``` code fences as a mix of text and code.
class RichAnswer extends StatelessWidget {
  const RichAnswer(this.text, {super.key});

  final String text;

  static List<({bool isCode, String text})> split(String text) {
    final parts = <({bool isCode, String text})>[];
    final segments = text.split('```');
    for (var i = 0; i < segments.length; i++) {
      var s = segments[i];
      final isCode = i.isOdd;
      if (isCode) {
        // Drop an optional language name on the first line, e.g. ```python
        final nl = s.indexOf('\n');
        if (nl >= 0 && RegExp(r'^[a-zA-Z+#]{0,12}$').hasMatch(s.substring(0, nl).trim())) {
          s = s.substring(nl + 1);
        }
        s = s.trimRight();
      } else {
        s = s.trim();
      }
      if (s.isNotEmpty) parts.add((isCode: isCode, text: s));
    }
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final parts = split(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in parts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: p.isCode
                ? CodeBlock(p.text, fontSize: 14)
                : SelectableText(
                    p.text.replaceAll('**', ''),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
          ),
      ],
    );
  }
}

/// Constrains content width on big screens so lines stay readable.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

/// Panel shown after answering: a coloured result banner, the right answer,
/// a simple explanation and the next step.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    super.key,
    required this.correct,
    required this.headline,
    required this.explanation,
    required this.onContinue,
    this.correctAnswer,
    this.onAskBuddy,
    this.continueLabel = 'Next',
    this.reward,
  });

  final bool correct;
  final String headline;
  final String explanation;
  final String? correctAnswer;
  final VoidCallback onContinue;
  final VoidCallback? onAskBuddy;
  final String continueLabel;

  /// Small extra line, e.g. "+15 coins, combo x3".
  final String? reward;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: ParchmentPanel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: correct ? g.mint : g.coral,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(bottom: BorderSide(color: g.ink, width: g.outlineWidth)),
              ),
              child: Row(
                children: [
                  Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: g.ink, size: 30),
                  const SizedBox(width: 10),
                  Expanded(child: Text(headline, style: displayStyle(26, color: g.ink))),
                  if (reward != null)
                    Text(reward!, style: displayStyle(18, color: g.ink)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (correctAnswer != null) ...[
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Right answer: '),
                        TextSpan(
                          text: correctAnswer,
                          style: const TextStyle(fontFamily: codeFont, fontWeight: FontWeight.w700),
                        ),
                      ]),
                      style: TextStyle(fontSize: 16, color: g.parchmentText),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Emoji('💡', size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(explanation,
                            style: TextStyle(fontSize: 16, height: 1.45, color: g.parchmentText)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      GameButton(
                        autofocus: true,
                        onPressed: onContinue,
                        icon: Icons.arrow_forward_rounded,
                        label: continueLabel,
                      ),
                      if (onAskBuddy != null)
                        GameButton(
                          onPressed: onAskBuddy,
                          tone: ButtonTone.sky,
                          icon: Icons.support_agent_rounded,
                          label: 'Ask Doubt Buddy',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
