// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/creator.dart';
import '../logic/cloud_storage.dart';
import '../logic/session.dart';
import '../services/account_service.dart';
import '../services/sound.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'navigation.dart';
import 'player_actions.dart';
import 'title_screen.dart';

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

  Future<void> _confirmDelete(BuildContext context, SessionController session) async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (password == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await session.deleteAccount(password);
      messenger.showSnackBar(const SnackBar(content: Text('Your account and its progress were deleted.')));
      await navigator.pushAndRemoveUntil(gameRoute<void>(const TitleScreen()), (_) => false);
    } on AccountException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.watch(context);
    final session = SessionScope.maybeWatch(context);
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
            if (session != null)
              section(
                'Player',
                ButtonTone.lilac,
                Icons.person_rounded,
                _PlayerSection(session: session, onDelete: () => _confirmDelete(context, session)),
              ),
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
                    subtitle: Text('Stops moving scenes, shakes and confetti. Byte jumps straight to the result.', style: subtitleStyle),
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
                'Guest progress is saved only on this device. With an account, your '
                'progress is saved online and only you can load it: your password is '
                'stored only as a secure hash and your email only as a coded ID. '
                'CodeQuest has no ads and no tracking, and you can delete your account '
                'and all its data at any time. Questions sent to the AI tutor are used '
                'only to answer you and are not stored by CodeQuest.',
                style: TextStyle(height: 1.5),
              ),
            ),
            section(
              'About',
              ButtonTone.gold,
              Icons.info_rounded,
              const Text(
                'CodeQuest was created by $creatorName, $creatorDetails. $copyrightLine',
                style: TextStyle(height: 1.5),
              ),
            ),
            const SizedBox(height: 10),
            const Center(child: CreatorCredit()),
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

class _PlayerSection extends StatelessWidget {
  const _PlayerSection({required this.session, required this.onDelete});

  final SessionController session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final subtitle = TextStyle(color: g.parchmentDim, fontSize: 14, height: 1.4);
    final sync = session.sync;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.isAccount ? 'Playing as ${session.displayName}' : 'Playing as a guest',
          style: displayStyle(20, color: g.ink),
        ),
        const SizedBox(height: 2),
        if (sync != null)
          ValueListenableBuilder<SyncState>(
            valueListenable: sync,
            builder: (context, state, _) => Semantics(
              liveRegion: true,
              child: Text(syncStatusText(state), style: subtitle),
            ),
          )
        else
          Text(
            'Guest progress is saved only on this device. Create an account to keep it '
            'safe online and play on any device.',
            style: subtitle,
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (session.isGuest && session.accountsEnabled)
              GameButton(
                label: 'Create account',
                icon: Icons.person_add_alt_1_rounded,
                tone: ButtonTone.sky,
                size: GameButtonSize.small,
                onPressed: () => Navigator.of(context)
                    .push(gameRoute<void>(const LoginScreen(startWithSignUp: true))),
              ),
            GameButton(
              label: session.isAccount ? 'Log out' : 'Switch player',
              icon: session.isAccount ? Icons.logout_rounded : Icons.switch_account_rounded,
              tone: ButtonTone.parchment,
              size: GameButtonSize.small,
              onPressed: () => confirmSwitchPlayer(context),
            ),
            if (session.isAccount)
              GameButton(
                label: 'Delete my account',
                icon: Icons.delete_forever_rounded,
                tone: ButtonTone.coral,
                size: GameButtonSize.small,
                onPressed: onDelete,
              ),
          ],
        ),
      ],
    );
  }
}

/// Asks for the password before deleting an account, so nobody else using
/// the device can delete it by accident.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This deletes your account and all of its progress for ever. Type your password to confirm.'),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: 'Password'),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_password.text),
          child: const Text('Delete for ever'),
        ),
      ],
    );
  }
}
