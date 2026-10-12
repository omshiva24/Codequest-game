// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'logic/progress.dart';
import 'logic/session.dart';
import 'services/account_service.dart';
import 'services/doubt_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Flutter web normally waits for the user to switch on accessibility.
    // Turning it on at start means screen readers work straight away.
    SemanticsBinding.instance.ensureSemantics();
  }

  // Older versions saved one shared game per device; it becomes the guest game.
  await SharedPrefsProgressStorage.migrateLegacy();

  // Nobody's progress is loaded until the player picks who is playing; only
  // this device's accessibility settings are applied straight away.
  final settings = await DeviceSettings.load();
  final controller = ProgressController(
    storage: MemoryProgressStorage(settings == null ? null : jsonEncode({'settings': settings.toJson()})),
  );
  await controller.load();
  DeviceSettings.keepInSync(controller);
  final session = SessionController(
    progress: controller,
    accounts: AccountService.fromEnvironment(),
  );
  // Checks in the background whether someone is still logged in.
  unawaited(session.restore());

  runApp(
    CodeQuestApp(
      controller: controller,
      session: session,
      doubtService: DoubtService(remote: RemoteTutor.fromEnvironment()),
    ),
  );
}
