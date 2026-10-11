import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../logic/progress.dart';
import '../services/sound.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final progress = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text('Stars, XP, coins, badges and streak will be cleared. Settings are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      progress.resetProgress();
      messenger.showSnackBar(const SnackBar(content: Text('Progress reset. Fresh start!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final settings = progress.settings;
    final g = GameColors.of(context);

    Widget section(String title, ButtonTone tone, IconData icon, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ParchmentPanel(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelBanner(text: title, tone: tone, icon: icon),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        );

    final subtitleStyle = TextStyle(color: g.parchmentDim, fontSize: 14);

    return GameScaffold(
      scene: SceneKind.menu,
      title: 'Settings',
      body: PageBody(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            section(
              'Accessibility',
              ButtonTone.sky,
              Icons.accessibility_new_rounded,
              Material(
                type: MaterialType.transparency,
                child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('High contrast', style: displayStyle(20, color: g.ink)),
                    subtitle: Text('Black background, bright colours and thick borders.', style: subtitleStyle),
                    value: settings.highContrast,
                    onChanged: (v) => progress.updateSettings(settings.copyWith(highContrast: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Reduce motion', style: displayStyle(20, color: g.ink)),
                    subtitle: Text('Stops moving scenes, gates, shakes and confetti.', style: subtitleStyle),
                    value: settings.reduceMotion,
                    onChanged: (v) => progress.updateSettings(settings.copyWith(reduceMotion: v)),
                  ),
                ],
              ),
              ),
            ),
            section(
              'Sound',
              ButtonTone.gold,
              Icons.volume_up_rounded,
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Sound effects', style: displayStyle(20, color: g.ink)),
                  subtitle: Text('Retro beeps for coins, hits, stars and wins.', style: subtitleStyle),
                  value: settings.soundOn,
                  onChanged: (v) {
                    progress.updateSettings(settings.copyWith(soundOn: v));
                    // Let the player hear what they just switched on.
                    if (v) {
                      SoundFx.enabled = true;
                      SoundFx.play(Sfx.coin);
                    }
                  },
                ),
              ),
            ),
            section(
              'Text size',
              ButtonTone.lilac,
              Icons.text_fields_rounded,
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 1.0, label: Text('Normal')),
                  ButtonSegment(value: 1.15, label: Text('Large')),
                  ButtonSegment(value: 1.3, label: Text('Larger')),
                ],
                selected: {settings.textScale},
                onSelectionChanged: (s) => progress.updateSettings(settings.copyWith(textScale: s.first)),
              ),
            ),
            section(
              'Runner timer',
              ButtonTone.gold,
              Icons.timer_rounded,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<TimerMode>(
                    segments: [
                      for (final mode in TimerMode.values) ButtonSegment(value: mode, label: Text(mode.label)),
                    ],
                    selected: {settings.timerMode},
                    onSelectionChanged: (s) => progress.updateSettings(settings.copyWith(timerMode: s.first)),
                  ),
                  const SizedBox(height: 8),
                  Text(settings.timerMode.description, style: subtitleStyle),
                ],
              ),
            ),
            section(
              'Keyboard controls',
              ButtonTone.mint,
              Icons.keyboard_rounded,
              const Text(
                'Tab / Shift+Tab: move between buttons\n'
                'Enter or Space: press the focused button\n'
                'World Builder: 1-7 fill the blank, R runs the code\n'
                'Bug Battle: 1-4 pick a move',
                style: TextStyle(height: 1.6),
              ),
            ),
            section(
              'Privacy',
              ButtonTone.parchment,
              Icons.lock_rounded,
              const Text(
                'Your progress is saved only on this device. CodeQuest has no accounts '
                'and collects no personal data. Questions sent to the AI tutor are used '
                'only to answer you and are not stored by CodeQuest.',
                style: TextStyle(height: 1.5),
              ),
            ),
            const SizedBox(height: 18),
            GameButton(
              tone: ButtonTone.coral,
              onPressed: () => _confirmReset(context),
              icon: Icons.restart_alt_rounded,
              label: 'Reset progress',
            ),
          ],
        ),
      ),
    );
  }
}
