import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'logic/progress.dart';
import 'services/doubt_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Flutter web normally waits for the user to switch on accessibility.
    // Turning it on at start means screen readers work straight away.
    SemanticsBinding.instance.ensureSemantics();
  }

  final controller = ProgressController(storage: SharedPrefsProgressStorage());
  await controller.load();

  runApp(
    CodeQuestApp(
      controller: controller,
      doubtService: DoubtService(remote: RemoteTutor.fromEnvironment()),
    ),
  );
}
