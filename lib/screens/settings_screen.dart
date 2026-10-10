import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../logic/progress.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final progress = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text('Stars, XP, coins and streak will be cleared. Settings are kept.'),
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

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Semantics(
            header: true,
            child: Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: g.coin)),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            sectionTitle('Accessibility'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('High contrast'),
                    subtitle: const Text('Black background, bright colours and thick borders.'),
                    value: settings.highContrast,
                    onChanged: (v) => progress.updateSettings(settings.copyWith(highContrast: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Reduce motion'),
                    subtitle: const Text('Stops moving gates, shakes and bouncing.'),
                    value: settings.reduceMotion,
                    onChanged: (v) => progress.updateSettings(settings.copyWith(reduceMotion: v)),
                  ),
                ],
              ),
            ),
            sectionTitle('Text size'),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1.0, label: Text('Normal')),
                ButtonSegment(value: 1.15, label: Text('Large')),
                ButtonSegment(value: 1.3, label: Text('Larger')),
              ],
              selected: {settings.textScale},
              onSelectionChanged: (s) => progress.updateSettings(settings.copyWith(textScale: s.first)),
            ),
            sectionTitle('Runner timer'),
            SegmentedButton<TimerMode>(
              segments: [
                for (final mode in TimerMode.values) ButtonSegment(value: mode, label: Text(mode.label)),
              ],
              selected: {settings.timerMode},
              onSelectionChanged: (s) => progress.updateSettings(settings.copyWith(timerMode: s.first)),
            ),
            const SizedBox(height: 8),
            Text(settings.timerMode.description, style: TextStyle(color: g.textDim)),
            sectionTitle('Keyboard controls'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tab / Shift+Tab: move between buttons\n'
                  'Enter or Space: press the focused button\n'
                  'Code Runner: arrow keys or 1-3 change lane, Space dashes\n'
                  'Bug Battle: 1-4 pick a move',
                  style: TextStyle(color: g.textDim, height: 1.6),
                ),
              ),
            ),
            sectionTitle('Privacy'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Your progress is saved only on this device. CodeQuest has no accounts '
                  'and collects no personal data. Questions sent to the AI tutor are used '
                  'only to answer you and are not stored by CodeQuest.',
                  style: TextStyle(color: g.textDim, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _confirmReset(context),
              icon: Icon(Icons.restart_alt_rounded, color: g.bad),
              label: const Text('Reset progress'),
            ),
          ],
        ),
      ),
    );
  }
}
