import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'logic/progress.dart';
import 'screens/title_screen.dart';
import 'services/doubt_service.dart';
import 'services/sound.dart';
import 'theme/app_theme.dart';

class CodeQuestApp extends StatelessWidget {
  const CodeQuestApp({
    super.key,
    required this.controller,
    required this.doubtService,
  });

  final ProgressController controller;
  final DoubtService doubtService;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      doubtService: doubtService,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final settings = controller.settings;
          SoundFx.enabled = settings.soundOn;
          return MaterialApp(
            title: 'CodeQuest - Learn to Code by Playing',
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
    );
  }
}
