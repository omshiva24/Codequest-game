// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'logic/progress.dart';
import 'logic/session.dart';
import 'screens/title_screen.dart';
import 'services/doubt_service.dart';
import 'services/sound.dart';
import 'theme/app_theme.dart';

class CodeQuestApp extends StatefulWidget {
  const CodeQuestApp({
    super.key,
    required this.controller,
    required this.doubtService,
    this.session,
  });

  final ProgressController controller;
  final DoubtService doubtService;

  /// Who is playing. Without one, a guest is already playing with
  /// [controller] (handy for tests and demos).
  final SessionController? session;

  @override
  State<CodeQuestApp> createState() => _CodeQuestAppState();
}

class _CodeQuestAppState extends State<CodeQuestApp> {
  late final SessionController _session =
      widget.session ?? SessionController.preloaded(widget.controller);

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    assert(identical(_session.progress, controller), 'session must use the same ProgressController');
    return SessionScope(
      session: _session,
      child: AppScope(
        controller: controller,
        doubtService: widget.doubtService,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final settings = controller.settings;
            SoundFx.enabled = settings.soundOn;
            return MaterialApp(
              title: 'CodeQuest by P Om Shiva - Learn to Code by Playing',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(highContrast: settings.highContrast),
              themeAnimationDuration:
                  settings.reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
              builder: (context, child) {
                final media = MediaQuery.of(context);
                // Combine the device text size with the in-game text size.
                final systemScale = media.textScaler.scale(16) / 16;
                final scale = (systemScale * settings.textScale).clamp(0.8, 2.5);
                return MediaQuery(
                  data: media.copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: media.disableAnimations || settings.reduceMotion,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const TitleScreen(),
            );
          },
        ),
      ),
    );
  }
}
