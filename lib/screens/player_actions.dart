// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../logic/cloud_storage.dart';
import '../logic/session.dart';
import '../theme/app_theme.dart';
import '../widgets/game_ui.dart';
import 'navigation.dart';
import 'title_screen.dart';

/// Asks, then hands the game to the next player: saves, logs out and wipes
/// this player's progress from memory, then shows the title screen.
Future<void> confirmSwitchPlayer(BuildContext context) async {
  final session = SessionScope.maybeRead(context);
  if (session == null) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Switch player?'),
      content: Text(
        session.isAccount
            ? 'You will be logged out. Your progress is saved in your account - '
                'log in again any time to continue.'
            : 'Your guest progress stays on this device. The next player can '
                'start their own game or log in.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(session.isAccount ? 'Log out' : 'Switch'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await session.switchPlayer();
  if (!context.mounted) return;
  await Navigator.of(context).pushAndRemoveUntil(gameRoute<void>(const TitleScreen()), (_) => false);
}

/// Text for the online-save status of an account player.
String syncStatusText(SyncState state) => switch (state) {
      SyncState.saved => 'Progress saved to your account.',
      SyncState.saving => 'Saving your progress...',
      SyncState.failed => 'Not saved yet (no internet?). Trying again soon.',
      SyncState.signedOut => 'Your login ran out. Log in again to keep saving.',
    };

/// Small HUD element: "Saved" cloud for account players, or a button to fix
/// a save problem. Shows nothing for guests.
class SyncPill extends StatelessWidget {
  const SyncPill({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final sync = session.sync;
    if (sync == null) return const SizedBox.shrink();
    final g = GameColors.of(context);
    return ValueListenableBuilder<SyncState>(
      valueListenable: sync,
      builder: (context, state, _) => switch (state) {
        SyncState.saved => HudPill(
            leading: Icon(Icons.cloud_done_rounded, color: g.mint, size: 24),
            text: 'Saved',
            semanticLabel: syncStatusText(state),
          ),
        SyncState.saving => HudPill(
            leading: Icon(Icons.cloud_upload_rounded, color: g.sky, size: 24),
            text: 'Saving',
            semanticLabel: syncStatusText(state),
          ),
        SyncState.failed => GameButton(
            label: 'Retry save',
            icon: Icons.cloud_off_rounded,
            tone: ButtonTone.coral,
            size: GameButtonSize.small,
            semanticLabel: 'Progress not saved yet. Retry save',
            onPressed: session.retrySave,
          ),
        SyncState.signedOut => GameButton(
            label: 'Log in again',
            icon: Icons.login_rounded,
            tone: ButtonTone.coral,
            size: GameButtonSize.small,
            semanticLabel: 'Your login ran out. Log in again to keep saving',
            onPressed: () => confirmSwitchPlayer(context),
          ),
      },
    );
  }
}
