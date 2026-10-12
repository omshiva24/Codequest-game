import '../logic/builder.dart';
import '../models/models.dart';

// World Builder content. Level 1 of each world teaches printing, strings,
// variables and maths; level 4 teaches loops. The ideas are the same in every
// world, but the code is written in that world's language and the sizes
// differ, so each world feels new. Every blank starts on a wrong value.

List<BuildChallenge> _hello(
  String levelId,
  Lang lang, {
  required String password,
  required List<String> passwordOptions,
  required int passwordStart,
  required int jumpHeight,
  required int jumpStart,
  required int gap,
  required BridgeForm bridge,
  required int bridgeStart,
  required int mathHeight,
  required JumpForm mathForm,
  required int mathStart,
}) {
  final p = levelId;
  return [
    guardChallenge(
      id: '$p-guard',
      lang: lang,
      password: password,
      options: passwordOptions,
      initial: passwordStart,
    ),
    jumpChallenge(id: '$p-jump', lang: lang, height: jumpHeight, form: JumpForm.direct, initial: jumpStart),
    bridgeChallenge(id: '$p-bridge', lang: lang, gap: gap, form: bridge, initial: bridgeStart),
    jumpChallenge(id: '$p-math', lang: lang, height: mathHeight, form: mathForm, initial: mathStart),
  ];
}

List<BuildChallenge> _loops(
  String levelId,
  Lang lang, {
  required int gap,
  required int gapStart,
  required int stairs,
  required int stairsStart,
  required int toll,
  required int tollStart,
  required int trickyGap,
  required LoopForm trickyForm,
  required int trickyStart,
}) {
  final p = levelId;
  return [
    loopBridgeChallenge(id: '$p-loop', lang: lang, gap: gap, form: LoopForm.count, initial: gapStart),
    stairsChallenge(id: '$p-stairs', lang: lang, height: stairs, initial: stairsStart),
    tollChallenge(id: '$p-toll', lang: lang, toll: toll, initial: tollStart),
    loopBridgeChallenge(id: '$p-tricky', lang: lang, gap: trickyGap, form: trickyForm, initial: trickyStart),
  ];
}

/// The challenges for a World Builder level, or an empty list.
List<BuildChallenge> builderChallenges(String levelId) => switch (levelId) {
      'py-1' => _hello(
          'py-1',
          Lang.python,
          password: 'HELLO',
          passwordOptions: const ['HELLO', '"HELLO"', '"hello"'],
          passwordStart: 0,
          jumpHeight: 2,
          jumpStart: 0,
          gap: 5,
          bridge: BridgeForm.plus,
          bridgeStart: 0,
          mathHeight: 3,
          mathForm: JumpForm.minus,
          mathStart: 1,
        ),
      'c-1' => _hello(
          'c-1',
          Lang.c,
          password: 'OPEN',
          passwordOptions: const ["'OPEN'", 'OPEN', '"OPEN"'],
          passwordStart: 1,
          jumpHeight: 3,
          jumpStart: 0,
          gap: 4,
          bridge: BridgeForm.times,
          bridgeStart: 0,
          mathHeight: 3,
          mathForm: JumpForm.plus,
          mathStart: 0,
        ),
      'cpp-1' => _hello(
          'cpp-1',
          Lang.cpp,
          password: 'CASTLE',
          passwordOptions: const ['"Castle"', 'CASTLE', '"CASTLE"'],
          passwordStart: 1,
          jumpHeight: 2,
          jumpStart: 3,
          gap: 4,
          bridge: BridgeForm.plus,
          bridgeStart: 0,
          mathHeight: 2,
          mathForm: JumpForm.minus,
          mathStart: 0,
        ),
      'java-1' => _hello(
          'java-1',
          Lang.java,
          password: 'LAVA',
          passwordOptions: const ['LAVA', "'LAVA'", '"LAVA"'],
          passwordStart: 1,
          jumpHeight: 3,
          jumpStart: 0,
          gap: 6,
          bridge: BridgeForm.times,
          bridgeStart: 1,
          mathHeight: 3,
          mathForm: JumpForm.minus,
          mathStart: 0,
        ),
      'py-4' => _loops(
          'py-4',
          Lang.python,
          gap: 4,
          gapStart: 1,
          stairs: 3,
          stairsStart: 4,
          toll: 12,
          tollStart: 0,
          trickyGap: 4,
          trickyForm: LoopForm.fromOne,
          trickyStart: 2,
        ),
      'c-4' => _loops(
          'c-4',
          Lang.c,
          gap: 5,
          gapStart: 2,
          stairs: 4,
          stairsStart: 1,
          toll: 8,
          tollStart: 2,
          trickyGap: 5,
          trickyForm: LoopForm.compare,
          trickyStart: 0,
        ),
      'cpp-4' => _loops(
          'cpp-4',
          Lang.cpp,
          gap: 3,
          gapStart: 4,
          stairs: 3,
          stairsStart: 0,
          toll: 16,
          tollStart: 1,
          trickyGap: 4,
          trickyForm: LoopForm.compare,
          trickyStart: 1,
        ),
      'java-4' => _loops(
          'java-4',
          Lang.java,
          gap: 6,
          gapStart: 3,
          stairs: 2,
          stairsStart: 3,
          toll: 20,
          tollStart: 0,
          trickyGap: 5,
          trickyForm: LoopForm.compare,
          trickyStart: 2,
        ),
      _ => const [],
    };
