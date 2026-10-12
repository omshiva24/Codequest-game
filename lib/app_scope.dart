// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/widgets.dart';

import 'logic/progress.dart';
import 'services/doubt_service.dart';

/// Makes the progress controller and doubt service available to every
/// screen, without extra state-management packages.
class AppScope extends InheritedNotifier<ProgressController> {
  const AppScope({
    super.key,
    required ProgressController controller,
    required this.doubtService,
    required super.child,
  }) : super(notifier: controller);

  final DoubtService doubtService;

  /// Use in build methods: rebuilds the widget when progress changes.
  static ProgressController watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Use in callbacks: reads without subscribing to changes.
  static ProgressController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static DoubtService doubts(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.doubtService;
}

/// True when the player (or their device) asked for less motion.
/// Use `listen: false` inside callbacks.
bool reduceMotionOf(BuildContext context, {bool listen = true}) =>
    MediaQuery.disableAnimationsOf(context) ||
    (listen ? AppScope.watch(context) : AppScope.read(context)).settings.reduceMotion;
