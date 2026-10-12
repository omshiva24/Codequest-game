// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/material.dart';

import '../data/creator.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'navigation.dart';

/// Who made CodeQuest, why, and the copyright notice.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return GameScaffold(
      scene: SceneKind.menu,
      title: 'About CodeQuest',
      body: PageBody(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ---- The creator ----
            ParchmentPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelBanner(text: 'Created by', tone: ButtonTone.gold, icon: Icons.person_rounded),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(creatorName, style: displayStyle(34, color: g.ink, height: 1.1)),
                  ),
                  const SizedBox(height: 4),
                  Text(creatorCourse, style: displayStyle(20, color: g.ink)),
                  Text(creatorUniversity, style: displayStyle(20, color: g.ink)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ---- The message ----
            ParchmentPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelBanner(text: whyTitle, tone: ButtonTone.coral, icon: Icons.favorite_rounded),
                  const SizedBox(height: 12),
                  for (final paragraph in whyMessage) ...[
                    Text(paragraph, style: const TextStyle(fontSize: 18, height: 1.5)),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('- $creatorName', style: displayStyle(22, color: g.ink)),
                        Text(creatorDetails, textAlign: TextAlign.right, style: TextStyle(color: g.parchmentDim)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ---- Copyright ----
            ParchmentPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PanelBanner(text: 'Copyright', tone: ButtonTone.lilac, icon: Icons.copyright_rounded),
                  const SizedBox(height: 12),
                  Text(copyrightLine, style: displayStyle(19, color: g.ink)),
                  const SizedBox(height: 6),
                  const Text(noCopyNotice, style: TextStyle(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Created by P Om Shiva" plus a button to read why. Used on the title
/// screen, the home screen and in Settings.
class CreatorCredit extends StatelessWidget {
  const CreatorCredit({super.key, this.showCopyright = false});

  /// Also show the "© 2026 ... All rights reserved." line.
  final bool showCopyright;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.78),
        borderRadius: BorderRadius.circular(18),
        border: g.highContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            label: 'Created by $creatorName, $creatorDetails',
            child: ExcludeSemantics(
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Created by ', style: TextStyle(color: g.onNight, fontSize: 16)),
                      TextSpan(text: creatorName, style: displayStyle(20, color: g.gold)),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    creatorDetails,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: g.onNightDim, fontSize: 15, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          if (showCopyright) ...[
            const SizedBox(height: 4),
            Text(
              copyrightLine,
              textAlign: TextAlign.center,
              style: TextStyle(color: g.onNightDim, fontSize: 14),
            ),
          ],
          const SizedBox(height: 10),
          GameButton(
            tone: ButtonTone.coral,
            icon: Icons.favorite_rounded,
            label: 'Why I made this',
            semanticLabel: '$whyTitle - a message from $creatorName',
            onPressed: () => Navigator.of(context).push(gameRoute<void>(const AboutScreen())),
          ),
        ],
      ),
    );
  }
}
