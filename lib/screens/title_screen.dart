// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'about_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'navigation.dart';

/// The "press start" screen: bouncing logo, Byte the owl and a big Play button.
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Stack(
      children: [
        const Positioned.fill(child: SceneBackground(kind: SceneKind.menu)),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Mascot(),
                      const SizedBox(height: 18),
                      const _BouncingLogo(),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Learn to code by playing. Your code builds bridges, beats '
                          'bugs and opens gates in four worlds.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: g.onNight, fontSize: 17, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final lang in Lang.values) _LangBadge(lang: lang)],
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: 280,
                        child: GameButton(
                          autofocus: true,
                          label: 'Play',
                          icon: Icons.play_arrow_rounded,
                          size: GameButtonSize.large,
                          expand: true,
                          onPressed: () => startPlaying(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _PlayerLine(),
                      const SizedBox(height: 22),
                      const CreatorCredit(showCopyright: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Play: straight into the game for a logged-in player, otherwise
/// "Who's playing?" so every person gets their own progress.
Future<void> startPlaying(BuildContext context) async {
  final session = SessionScope.maybeRead(context);
  await session?.ready;
  if (!context.mounted) return;
  final navigator = Navigator.of(context);
  if (session == null || session.hasPlayer) {
    await navigator.pushReplacement(gameRoute<void>(const HomeScreen()));
  } else {
    await navigator.push(gameRoute<void>(const LoginScreen()));
  }
}

/// Says who is playing (and lets someone else take over).
class _PlayerLine extends StatelessWidget {
  const _PlayerLine();

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final session = SessionScope.maybeWatch(context);
    final style = TextStyle(color: g.onNightDim, fontSize: 15);
    if (session == null || session.isGuest) {
      return Text('Playing as a guest. Progress is saved on this device.', style: style, textAlign: TextAlign.center);
    }
    if (session.restoring) {
      return Text('Checking who is playing...', style: style, textAlign: TextAlign.center);
    }
    if (session.isAccount) {
      return Column(
        children: [
          Text(
            'Welcome back, ${session.displayName}! Your progress is saved to your account.',
            style: style.copyWith(color: g.onNight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          GameButton(
            label: 'Not you? Switch player',
            icon: Icons.switch_account_rounded,
            tone: ButtonTone.parchment,
            size: GameButtonSize.small,
            onPressed: () => session.switchPlayer(),
          ),
        ],
      );
    }
    return Text(
      'Play as a guest, or log in so your progress is yours alone.',
      style: style,
      textAlign: TextAlign.center,
    );
  }
}

class _Mascot extends StatelessWidget {
  const _Mascot();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ByteAvatar(size: 96),
        const SizedBox(width: 6),
        Flexible(
          child: SpeechBubble(
            child: Text(
              "Hoot! I'm Byte. Ready for a coding adventure?",
              style: displayStyle(19, color: GameColors.of(context).ink, height: 1.25),
            ),
          ),
        ),
      ],
    );
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge({required this.lang});

  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
      decoration: BoxDecoration(
        color: g.highContrast ? Colors.black : lang.color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Emoji(lang.emoji, size: 18),
          const SizedBox(width: 6),
          Text(lang.label, style: displayStyle(18, color: g.highContrast ? Colors.white : g.ink)),
        ],
      ),
    );
  }
}

/// "CodeQuest" with each letter riding a gentle wave.
class _BouncingLogo extends StatefulWidget {
  const _BouncingLogo();

  @override
  State<_BouncingLogo> createState() => _BouncingLogoState();
}

class _BouncingLogoState extends State<_BouncingLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final size = width < 420 ? 58.0 : 84.0;
    const word = 'CodeQuest';
    return Semantics(
      header: true,
      label: 'CodeQuest',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < word.length; i++)
                Transform.translate(
                  offset: Offset(0, math.sin((_c.value * 2 * math.pi) - i * 0.6) * size * 0.08),
                  child: OutlinedText(
                    word[i],
                    size: size,
                    color: i < 4 ? g.gold : g.onNight,
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
