import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A dark, monospace code panel that scrolls sideways for long lines.
class CodeBlock extends StatelessWidget {
  const CodeBlock(this.code, {super.key, this.fontSize = 15});

  final String code;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      label: 'Code',
      container: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: g.codeBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: g.border),
        ),
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            code,
            style: TextStyle(
              fontFamily: codeFont,
              fontSize: fontSize,
              height: 1.45,
              color: g.codeText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hearts (lives). Read out as "2 of 3 hearts left".
class HeartsBar extends StatelessWidget {
  const HeartsBar({super.key, required this.lives, required this.max});

  final int lives;
  final int max;

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
                child: Icon(
                  i < lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: i < lives ? g.bad : g.textDim,
                  size: 26,
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
            for (var i = 0; i < 3; i++)
              Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < stars ? g.coin : g.textDim,
                size: size,
              ),
          ],
        ),
      ),
    );
  }
}

/// A small pill showing an icon and a value, e.g. coins or XP.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.semanticLabel,
    this.color,
  });

  final IconData icon;
  final String value;
  final String semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: g.cardRaised,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: g.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color ?? g.coin),
              const SizedBox(width: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Emoji that screen readers skip (they are decoration).
class Emoji extends StatelessWidget {
  const Emoji(this.emoji, {super.key, this.size = 28});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Text(emoji, style: TextStyle(fontSize: size, height: 1.1)),
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
  const PageBody({super.key, required this.child, this.maxWidth = 860});

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

/// Panel shown after answering a question: right/wrong + explanation.
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
  });

  final bool correct;
  final String headline;
  final String explanation;
  final String? correctAnswer;
  final VoidCallback onContinue;
  final VoidCallback? onAskBuddy;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final accent = correct ? g.good : g.bad;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: g.cardRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: accent, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headline,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
                  ),
                ),
              ],
            ),
            if (correctAnswer != null) ...[
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Right answer: '),
                  TextSpan(
                    text: correctAnswer,
                    style: const TextStyle(fontFamily: codeFont, fontWeight: FontWeight.w700),
                  ),
                ]),
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 8),
            Text(explanation, style: TextStyle(fontSize: 16, height: 1.4, color: g.textDim)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  autofocus: true,
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(continueLabel),
                ),
                if (onAskBuddy != null)
                  OutlinedButton.icon(
                    onPressed: onAskBuddy,
                    icon: const Icon(Icons.support_agent_rounded),
                    label: const Text('Ask Doubt Buddy'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
